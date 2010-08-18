# Copyright 2010 Kevin Ryde

# This file is part of Image-Base-Gtk2.
#
# Image-Base-Gtk2 is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Gtk2 is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Gtk2.  If not, see <http://www.gnu.org/licenses/>.


package Image::Base::Gtk2::Gdk::Pixbuf;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;
use base 'Image::Base';

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 3;

sub new {
  my ($class, %params) = @_;
  ### Gdk-Pixbuf new: \%params

  my $self;
  my $filename = delete $params{'-file'};

  # $obj->new(...) means make a copy, with some extra settings
  if (ref $class) {
    $self = bless { %$class }, ref $class;
    if (defined $filename) {
      $self->load ($filename);
    } elsif (! defined $params{'-pixbuf'}) {
      $self->{'-pixbuf'} = $self->{'-pixbuf'}->copy;
    }

  } else {
    if (! defined $filename) {
      if (! $params{'-pixbuf'}) {
        ### create new GdkPixbuf

        my $pixbuf = $params{'-pixbuf'} = Gtk2::Gdk::Pixbuf->new
          (delete $params{'-colorspace'} || 'rgb',
           delete $params{'-has_alpha'},
           delete $params{'-bits_per_sample'} || 8,
           delete $params{'-width'},
           delete $params{'-height'});
        $pixbuf->fill (0xFF000000);
      }
    }
    $self = bless {}, $class;
    if (defined $filename) {
      $self->load ($filename);
    }
    $self->set (%params);
  }

  return $self;
}

my %attr_to_get_method = (-has_alpha  => 'get_has_alpha',
                          -colorspace => 'get_colorspace',
                          -width      => 'get_width',
                          -height     => 'get_height',
                         );
sub _get {
  my ($self, $key) = @_;
  if (my $method = $attr_to_get_method{$key}) {
    return $self->{'-pixbuf'}->$method;
  }
  return $self->SUPER::_get($key);
}

sub set {
  my ($self, %params) = @_;
  ### Image-Base-Pixbuf set(): \%params

  if (my $pixbuf = $params{'-pixbuf'}) {
    $pixbuf->get_bits_per_sample == 8
      or croak "Only pixbufs of 8 bits per sample supported";
    $pixbuf->get_colorspace eq 'rgb'
      or croak "Only pixbufs of 'rgb' colorspace supported";

    if (! exists $params{'-hotx'}) {
      $params{'-hotx'} = $pixbuf->get_option('x_hot');
    }
    if (! exists $params{'-hoty'}) {
      $params{'-hoty'} = $pixbuf->get_option('y_hot');
    }
  }

  foreach my $key (keys %params) {
    if (my $method = $attr_to_get_method{$key}) {
      croak "$key is read-only";
    }
  }

  %$self = (%$self, %params);
  ### set leaves: $self
}

sub load {
  my ($self, $filename) = @_;
  if (@_ == 1) {
    $filename = $self->get('-file');
  } else {
    $self->set('-file', $filename);
  }
  ### load: $filename

  # Gtk2::Gdk::Pixbuf->new_from_file doesn't seem to give back the format
  # used to load, so go to PixbufLoader in load_fh()
  open my $fh, '<', $filename or croak "Cannot open $filename: $!";
  binmode ($fh) or die "Oops, cannot set binmode: $!";
  $self->load_fh ($fh);
  close $fh or croak "Error closing $filename: $!";
}

sub load_fh {
  my ($self, $fh, $filename) = @_;
  ### load_fh()
  my $loader = Gtk2::Gdk::PixbufLoader->new;
  for (;;) {
    my $buf;
    my $len = read ($fh, $buf, 8192);
    if (! defined $len) {
      croak "Error reading file",
        (defined $filename ? (' ',$filename) : ()),
          ": $!";
    }
    if ($len == 0) {
      last;
    }
    $loader->write ($buf);
  }
  $loader->close;
  $self->set (-pixbuf      => $loader->get_pixbuf,
              -file_format => $loader->get_format->{'name'});
  ### loaded format: $self->{'-file_format'}
}

sub load_string {
  my ($self, $str) = @_;
  ### load_string()
  my $loader = Gtk2::Gdk::PixbufLoader->new;
  $loader->write ($str);
  $loader->close;
  $self->set (-pixbuf      => $loader->get_pixbuf,
              -file_format => $loader->get_format->{'name'});
  ### loaded format: $self->{'-file_format'}
}

sub save {
  my ($self, $filename) = @_;
  ### Image-Base-Pixbuf save(): @_
  if (@_ == 2) {
    $self->set('-file', $filename);
  } else {
    $filename = $self->get('-file');
  }
  ### $filename

  my $file_format = $self->get('-file_format');
  if (! defined $file_format) {
    $file_format = _filename_to_format($filename);
    if (! defined $file_format) {
      croak 'No -file_format set';
    }
  }

  my @options;
  $file_format = lc($file_format);
  if ($file_format eq 'png') {
    if (Gtk2->check_version(2,8,0)
        && defined (my $zlib_compression = $self->get('-zlib_compression'))) {
      @options = (compress => $zlib_compression)
    }
  } elsif ($file_format eq 'ico') {
    if (defined (my $x_hot = $self->get('-hotx'))) {
      @options = (x_hot => $x_hot);
    }
    if (defined (my $y_hot = $self->get('-hoty'))) {
      push @options, y_hot => $y_hot;
    }
  }
  ### @options
  $self->{'-pixbuf'}->save ($filename, $file_format, @options);
}

sub _filename_to_format {
  my ($filename) = @_;
  $filename =~ /\.([a-z]+)$/i or return undef;
  my $ext = lc($1);
  foreach my $format (Gtk2::Gdk::Pixbuf->get_formats) {
    foreach my $fext (@{$format->{'extensions'}}) {
      if ($ext eq $fext) {
        return $format->{'name'};
      }
    }    
  }
}

sub xy {
  my ($self, $x, $y, $colour) = @_;

  my $pixbuf = $self->{'-pixbuf'};
  if (@_ >= 4) {
    ### Image-GdkPixbuf xy: "$x, $y, $colour"
    my $data;
    my $has_alpha = $pixbuf->get_has_alpha;
    if (lc($colour) eq 'none') {
      if (! $has_alpha) {
        croak "pixbuf has no alpha channel for colour None";
      }
      $data = "\0\0\0\0";
    } else {
      my $colorobj = $self->colour_to_colorobj($colour);
      $data = pack ('CCC',
                       $colorobj->red >> 8,
                       $colorobj->blue >> 8,
                       $colorobj->green >> 8)
        . "\xFF"; # alpha
    }
    ### $data
    my $src_pixbuf = Gtk2::Gdk::Pixbuf->new_from_data
      ($data,
       'rgb',
       $has_alpha,
       8,     # bits per sample
       1,1,   # width,height
       4);    # rowstride
    $src_pixbuf->copy_area (0,0, # src x,y
                            1,1, # src width,height
                            $pixbuf, # dest
                            $x,$y);  # dest x,y
    ### leaves: $pixbuf->get_pixels

  } else {
    my $n_channels = $pixbuf->get_n_channels;
    my $rgba = substr ($pixbuf->get_pixels,
                       $y*$pixbuf->get_rowstride() + $x*$n_channels,
                       $n_channels);
    ### Image-GdkPixbuf xy fetch: "$x, $y"
    ### $n_channels
    ### has_alpha: $pixbuf->get_has_alpha
    ### $rgba
    if (substr($rgba,3,1) eq "\0") {
      return 'None';
    }
    return sprintf '#%02X%02X%02X', unpack 'CCC', $rgba;
  }
}

sub line {
  my ($self, $x1,$y1, $x2,$y2, $colour) = @_;
  if ($x1 == $x2 || $y1 == $y2) {
    # solid horizontal or vertical
    shift->rectangle (@_, 1);
  } else {
    shift->SUPER::line (@_);
  }
}

sub rectangle {
  my ($self, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  ### rectangle(): "$x1,$y1, $x2,$y2, $colour, ".($fill||0)

  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1) };  # swap
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1) };  # swap

  my $w = $x2 - $x1 + 1;
  my $h = $y2 - $y1 + 1;
  if ($fill || $w == 1 || $h == 1) {
    # solid block
    my $pixbuf = $self->{'-pixbuf'};
    my $has_alpha = $pixbuf->get_has_alpha;
    my $pixel;
    if (lc($colour) eq 'none') {
      if (! $has_alpha) {
        croak "pixbuf has no alpha channel for colour None";
      }
      $pixel = 0;
    } else {
      my $colorobj = $self->colour_to_colorobj($colour);
      $pixel = ((  ($colorobj->red  & 0xFF00) << 16)
                + (($colorobj->blue & 0xFF00) << 8)
                + ($colorobj->green & 0xFF00)
                + 0xFF);
    }
    my $src_pixbuf = Gtk2::Gdk::Pixbuf->new
      ('rgb',
       $has_alpha,
       8,      # bits per sample
       $w,$h); # width,height
    $src_pixbuf->fill ($pixel);

    $src_pixbuf->copy_area (0,0,   # src x,y
                            $w,$h, # src width,height
                            $pixbuf,  # dest
                            $x1,$y1); # dest x,y
  } else {
    shift->SUPER::rectangle(@_);
  }
}

my %colorobj = (set   => Gtk2::Gdk::Color->new (0xFF,0xFF,0xFF, 1),
                clear => Gtk2::Gdk::Color->new (0,0,0, 0));
# not documented ...
sub colour_to_colorobj {
  my ($self, $colour) = @_;
  if (my $colorobj = $colorobj{lc($colour)}) {
    return $colorobj;
  }
  my $colorobj = Gtk2::Gdk::Color->parse ($colour)
    || croak "Cannot parse colour: $colour";
  return $colorobj;
}

1;
__END__

=for stopwords undef Ryde Gdk Images pixbuf colormap ie toplevel

=head1 NAME

Image::Base::Gtk2::Gdk::Pixbuf -- draw image files using Gtk2::Gdk::Pixbuf

=head1 SYNOPSIS

 use Image::Base::Gtk2::Gdk::Pixbuf;
 my $image = Image::Base::Gtk2::Gdk::Pixbuf->new
                 (-width => 100,
                  -height => 100);
 $image->line (0,0, 99,99, '#FF00FF');
 $image->rectangle (10,10, 20,15, 'white');

=head1 CLASS HIERARCHY

C<Image::Base::Gtk2::Gdk::Pixbuf> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::Gtk2::Gdk::Pixbuf

=head1 DESCRIPTION

C<Image::Base::Gtk2::Gdk::Pixbuf> extends C<Image::Base> to create and
update image files using GdkPixbuf.  PNG and JPEG can be read and written,
and in recent Gtk also TIFF, ICO and BMP.  Many further formats can be read
but not written, including XPM, GIF, XBM and PCX.

Pixbufs are held in client-side memory and don't require an X server or
C<< Gtk2->init >> so can be used for general-purpose file manipulations.

The current drawing code is not very fast, but if you've got some pixel
twiddling in C<Image::Base> style then this is a handy way to have it read
or write various file formats.

Colour names are anything recognised by C<< Gtk2::Gdk::Color->parse >>,
which means various names like "pink" plus hex #RRGGBB or #RRRRGGGGBBB.  As
of Gtk 2.20 the names are the Pango compiled-in copy of the X11 F<rgb.txt>.
Special colour "None" means a transparent pixel for a pixbuf with an "alpha"
channel.

Only 8-bit RGB or RGBA pixbufs are supported by this module currently, which
is all that Gtk 2.20 itself supports.

=head1 FUNCTIONS

=over 4

=item C<< $image = Image::Base::Gtk2::Gdk::Pixbuf->new (key=>value,...) >>

Create and return a new GdkPixbuf image object.  It can be pointed at an
existing pixbuf,

    $image = Image::Base::Gtk2::Gdk::Pixbuf->new
                 (-pixbuf => $gdkimage);

Or a file can be read,

    $image = Image::Base::Gtk2::Gdk::Pixbuf->new
                 (-file => '/my/file/name.jpeg');

Or a new GdkPixbuf created with width and height,

    $image = Image::Base::Gtk2::Gdk::Pixbuf->new
                 (-width  => 10,
                  -height => 10);

When creating a pixbuf an alpha channel (transparency) can be requested with
C<-has_alpha>,

    $image = Image::Base::Gtk2::Gdk::Pixbuf->new
                 (-width     => 10,
                  -height    => 10,
                  -has_alpha => 1);

=item C<< $image->load >>

=item C<< $image->load ($filename) >>

Read the C<-file>, or set C<-file> to C<$filename> and then read.  This
creates and sets a new underlying C<-pixbuf> since it's not possible to read
into an existing pixbuf object, only create a new one.  C<-file_format> is
set from the loaded file's format.

=item C<< $image->save >>

=item C<< $image->save ($filename) >>

Write the C<-file>, or set C<-file> to C<$filename> and then write.
C<-file_format> is the saved format.

If C<-file_format> is not set there's a secret experimental feature which
matches the C<-file> extension against the available pixbuf formats.  Is
that a good idea, or would just say C<png> fallback be better?

Some formats can be loaded but not saved.  C<png> and C<jpeg> can be saved
always, and then C<ico> in Gtk 2.4 up, C<bmp> in Gtk 2.8 up and C<tiff> in
Gtk 2.10 up.

=back

=head1 ATTRIBUTES

=over

=item C<-pixbuf> (C<Gtk2::Gdk::Pixbuf> object)

The target C<Gtk2::Gdk::Pixbuf> object.

=item C<-file_format> (string, default undef)

The file format from the last C<load> and to use in C<save>.  This is one of
the GdkPixbuf format names such as "png" or "jpeg", in upper or lower case.

=item C<-width> (integer, read-only)

=item C<-height> (integer, read-only)

The size of a pixbuf cannot be changed once created.

=item C<-has_alpha> (boolean)

Whether the underlying pixbuf has a alpha channel, meaning a transparency
mask (or partial transparency).

=item C<-zlib_compression> (integer, no default)

The Zlib compression level to use when saving.  This is used when applicable
and where possible, which currently means "png" format in Gtk 2.8.0 and
higher.

=item C<-hotx> (integer or undef, default undef)

=item C<-hoty> (integer or undef, default undef)

The cursor hotspot in C<xpm> and C<ico> images (as per C<Image::Xpm>).

These are loaded in Gtk 2.2 up, and are saved to C<ico> in Gtk 2.4 and
higher (C<ico> saving is new in Gtk 2.4).  There's no C<xpm> saving at all
as of Gtk 2.20.

=cut

# 2.4.0 ico saving support per:
# http://git.gnome.org/browse/gdk-pixbuf/tree/gdk-pixbuf/io-ico.c?id=GTK_2_4_0

=back

=head1 SEE ALSO

L<Image::Base>,
L<Gtk2::Gdk::Pixbuf>,
L<Image::Xpm>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/image-base-gtk2/index.html>

=head1 LICENSE

Copyright 2010 Kevin Ryde

Image-Base-Gtk2 is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Image-Base-Gtk2 is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Image-Base-Gtk2.  If not, see L<http://www.gnu.org/licenses/>.

=cut
