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
use base 'Image::Base';

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 1;

sub new {
  my ($class, %params) = @_;
  ### Gdk-Pixbuf new: \%params

  # $obj->new(...) means make a copy, with some extra settings
  if (ref $class) {
    croak "Cannot clone a GdkPixbuf yet";
  }

  if (! exists $params{'-pixbuf'}) {
    ### create new GdkPixbuf
    $params{'-pixbuf'} = Gtk2::Gdk::Pixbuf->new
      (delete $params{'-colorspace'} || 'rgb',
       delete $params{'-has_alpha'},
       delete $params{'-bits_per_sample'} || 8,
       delete $params{'-width'},
       delete $params{'-height'});
  }

  my $pixbuf = $params{'-pixbuf'};
  $pixbuf->get_bits_per_sample == 8
    or croak "Only pixbufs of 8 bits per sample supported";
  $pixbuf->get_colorspace == 'rgb'
    or croak "Only pixbufs of 'rgb' colorspace supported";

  return $class->SUPER::new (%params);
}

my %attr_to_get_method = (-has_alpha  => 'get_has_alpha',
                          -colorspace => 'get_colorspace',
                          -width      => 'get_width',
                          -height     => 'get_height');
sub _get {
  my ($self, $key) = @_;
  if (my $method = $attr_to_get_method{$key}) {
    return $self->{'-pixbuf'}->$method;
  }
  return $self->SUPER::_get($key);
}

sub set {
  my ($self, %params) = @_;
  ### Image-Base-Gtk2-Gdk-Pixbuf set(): \%params
  foreach my $key (keys %params) {
    if (my $method = $attr_to_get_method{$key}) {
      croak "$key is read-only";
    }
  }
  %$self = (%$self, %params);
  ### set leaves: $self
}

sub xy {
  my ($self, $x, $y, $colour) = @_;
  if (@_ >= 4) {
    ### Image-GdkPixbuf xy: "$x, $y, $colour"
    my $colorobj = $self->Image::Base::Gtk2::Gdk::Drawable::colour_to_colorobj($colour);
    die ("plonk bytes into get_pixels memory ...",
         $colorobj->red >> 8,
         $colorobj->blue >> 8,
         $colorobj->green >> 8);

  } else {
    my $pixbuf = $self->{'-pixbuf'};
    my $has_alpha = $pixbuf->has_alpha;
    my $rgba = substr
      ($pixbuf->get_pixels,
       $y*$pixbuf->get_rowstride() + $x*$pixbuf->get_n_channels);
    if (substr($rgba,3,1) == "\xFF") {
      return 'None';
    }
    return sprintf '%02X%02X%02X', unpack 'CCC', $rgba;
  }
}

1;
__END__

=for stopwords undef Ryde Gdk Images pixbuf colormap ie toplevel

=head1 NAME

Image::Base::Gtk2::Gdk::Pixbuf -- draw into a Gdk pixbuf

=head1 SYNOPSIS

 use Image::Base::Gtk2::Gdk::Pixbuf;
 my $image = Image::Base::Gtk2::Gdk::Pixbuf->new
                 (-width => 10,
                  -height => 10);
 $image->line (0,0, 99,99, '#FF00FF');
 $image->rectangle (10,10, 20,15, 'white');

=head1 CLASS HIERARCHY

C<Image::Base::Gtk2::Gdk::Pixbuf> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::Gtk2::Gdk::Pixbuf

=head1 DESCRIPTION

C<Image::Base::Gtk2::Gdk::Pixbuf> extends C<Image::Base> to create and draw
into GdkImage objects.  GdkImages are pixel arrays in client-side memory, or
possibly shared-memory with the X server.  There's no file load or save,
just drawing operations.

Only 8-bit RGB pixbufs of are supported by this module (with or without an
alpha channel).  8-bit RGB is the only format available from GdkPixbuf
itself, as of Gtk 2.20.

=head1 FUNCTIONS

=over 4

=item C<$image = Image::Base::Gtk2::Gdk::Pixbuf-E<gt>new (key=E<gt>value,...)>

Create and return a new GdkImage image object.  It can be pointed at an
existing pixbuf,

    $image = Image::Base::Gtk2::Gdk::Pixbuf->new
                 (-pixbuf => $gdkimage);

Or a new GdkImage created,

    $image = Image::Base::Gtk2::Gdk::Pixbuf->new
                 (-width    => 10,
                  -height   => 10);

A pixbuf requires a size, and  optionally a "has alpha" flag.

    -has_alpha  =>  boolean

=back

=head1 ATTRIBUTES

=over

=item C<-width> (integer, read-only)

=item C<-height> (integer, read-only)

The size of a pixbuf cannot be changed once created.

=item C<-pixbuf> (C<Gtk2::Gdk::Pixbuf> object)

The target C<Gtk2::Gdk::Pixbuf> object.

=item C<-has_alpha> (boolean)

Whether the underlying pixbuf has a alpha channel, meaning a transparency or
partial transparency mask.

=back

=head1 SEE ALSO

L<Image::Base>,
L<Gtk2::Gdk::Pixbuf>

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
