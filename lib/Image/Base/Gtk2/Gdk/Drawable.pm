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


package Image::Base::Gtk2::Gdk::Drawable;
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
  my $self = bless { _gc_colour => '',
                     _gc_colour_pixel => -1,
                   }, $class;
  ### Image-Base-Gtk2-Gdk-Drawable new: $self
  $self->set (%params);
  return $self;
}

my %attr_to_get_method = (-colormap => 'get_colormap',
                          -depth    => 'get_depth',
                          -screen   => 'get_screen');
sub _get {
  my ($self, $key) = @_;

  if (my $method = $attr_to_get_method{$key}) {
    return $self->{'-drawable'}->$method;
  }
  if ($key eq '-width') {   # no get_width method or property, just get_size
    return ($self->{'-drawable'}->get_size)[0];
  }
  if ($key eq '-height') {  # no get_height method or property, just get_size
    return ($self->{'-drawable'}->get_size)[1];
  }

  if ($key eq '-pixmap' || $key eq '-window') {  # aliasing
    $key = '-drawable';
  }
  return $self->SUPER::_get($key);
}

sub set {
  my ($self, %params) = @_;
  ### Image-Base-Gtk2-Gdk-Drawable set: \%params

  foreach my $key ('-depth', '-screen') {
    if (exists $params{$key}) {
      croak "Attribute $key is read-only";
    }
  }

  if (exists $params{'-gc'}) {
    # when setting -gc no longer assume the current foreground pixel
    $params{'_gc_colour'} = '';
    $params{'_gc_pixel'} = -1;
  }

  # aliasing
  if (exists $params{'-pixmap'}) {
    $params{'-drawable'} = delete $params{'-pixmap'};
  }
  if (exists $params{'-window'}) {
    $params{'-drawable'} = delete $params{'-window'};
  }

  # set -drawable now so as to apply -colormap and size to possible new one
  if (exists $params{'-drawable'}) {
    $self->{'-drawable'} = delete $params{'-drawable'};
  }

  if (exists $params{'-colormap'}) {
    $self->{'-drawable'}->set_colormap (delete $params{'-colormap'});
  }

  my $width  = delete $params{'-width'};
  my $height = delete $params{'-height'};
  if (defined $width || defined $height) {
    if (! defined $width)  { $width  = ($self->{'-drawable'}->get_size)[0]; }
    if (! defined $height) { $height = ($self->{'-drawable'}->get_size)[1]; }
    $self->{'-drawable'}->resize ($width, $height);
  }

  %$self = (%$self, %params);
  ### set leaves: $self
}

sub xy {
  my ($self, $x, $y, $colour) = @_;
  if (@_ >= 4) {
    ### Image-Gtk2GdkDrawable xy: "$x, $y, $colour"
    $self->{'-drawable'}->draw_point ($self->gc_for_colour($colour), $x, $y);
  } else {
    my $pixbuf = Gtk2::Gdk::Pixbuf->new ('rgb',
                                         0,   # has alpha
                                         8,   # bits per sample
                                         1,1);
    my $drawable = $self->{'-drawable'};
    $pixbuf->get_from_drawable ($self->{'-drawable'}, undef, $x,$y, 0,0, 1,1);
    ### pixbuf get_pixels: length($pixbuf->get_pixels), $pixbuf->get_pixels
    my @rgb = unpack('CCC', $pixbuf->get_pixels);
    ### @rgb
    if ($drawable->isa('Gtk2::Gdk::Pixmap')
        && $drawable->get_depth == 1
        && ! $drawable->get_colormap) {
      return ($rgb[0]||$rgb[1]||$rgb[2] ? 1 : 0);
    } else {
      return sprintf '#%02X%02X%02X', @rgb
    }
  }
}

# Crib note: no limit on how many points passed to draw_points().  The
# underlying XDrawPoints() automatically splits into multiple PolyPoint
# requests as necessary.
#
sub Image_Base_Other_xy_points {
  my $self = shift;
  my $colour = shift;
  ### Image_Base_Other_xy_points $colour
  ### len: scalar(@_)
  @_ or return;

  ### drawable: $self->{'-drawable'}
  ### gc: $self->gc_for_colour($colour)
  unshift @_, $self->{'-drawable'}, $self->gc_for_colour($colour);
  ### len: scalar(@_)
  ### $_[0]
  ### $_[1]

  # shift/unshift changes the first two args from self,colour to drawable,gc
  # does that save stack copying?
  my $code = $self->{'-drawable'}->can('draw_points');
  goto &$code;

  # the plain equivalent ...
  # $self->{'-drawable'}->draw_points ($self->gc_for_colour($colour), @_);
}

sub line {
  my ($self, $x1,$y1, $x2,$y2, $colour) = @_;
  ### Image-Gtk2GdkDrawable line()
  $self->{'-drawable'}->draw_line ($self->gc_for_colour($colour),
                                   $x1,$y1, $x2,$y2);
}

# $x1==$x2 and $y1==$y2 on $fill==false may or may not draw that x,y point
# outline with gc line_width==0
    # or alternately $drawable->draw_point ($gc, $x1,$y1);
#
sub rectangle {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  # ### Image-Gtk2GdkDrawable rectangle: "$x1, $y1, $x2, $y2, $colour, $fill"
  $fill = !! $fill;
  $fill ||= ($x1 == $x2 || $y1 == $y2);
  $self->{'-drawable'}->draw_rectangle ($self->gc_for_colour($colour), $fill,
                                        $x1, $y1,
                                        $x2-$x1+$fill, $y2-$y1+$fill);
}

sub ellipse {
  my ($self, $x1, $y1, $x2, $y2, $colour) = @_;
  ### Image-Gtk2GdkDrawable ellipse: "$x1, $y1, $x2, $y2, $colour"
  my $drawable = $self->{'-drawable'};
  my $gc = $self->gc_for_colour($colour);
  if ($x1 == $x2 && $y1 == $y2) {
    $drawable->draw_point ($gc, $x1,$y1);
  } else {
    $drawable->draw_arc ($gc,
                         0, # unfilled
                         $x1, $y1,
                         $x2-$x1, $y2-$y1,
                         0, 360*64);  # angles in 64ths of a 360 degrees
  }
}

# return '-gc' with its foreground set to $colour
# -gc is created if not already set
# the colour set is recorded to save work if the next drawing is the same
#
sub gc_for_colour {
  my ($self, $colour) = @_;
  my $gc = $self->{'-gc'};
  if ($colour ne $self->{'_gc_colour'}) {
    ### gc_for_colour change: $colour

    my $colorobj = $self->colour_to_colorobj($colour);
    ### pixel: sprintf("%#X",$colorobj->pixel)

    $self->{'_gc_colour'} = $colour;
    if ($colorobj->pixel ne $self->{'_gc_colour_pixel'}) {
      $self->{'_gc_colour_pixel'} = $colorobj->pixel;
      if (! $gc) {
        return ($self->{'-gc'}
                = Gtk2::Gdk::GC->new ($self->{'-drawable'},
                                      { foreground => $colorobj }));
      }
      $gc->set_foreground ($colorobj);
    }
  }
  return $gc;
}

sub colour_to_colorobj {
  my ($self, $colour) = @_;
  if ($colour =~ /^\d+$/) {
    return Gtk2::Gdk::Color->new (0,0,0, $colour);
  }
  if ($colour eq 'set') {
    return Gtk2::Gdk::Color->new (0,0,0, 1);
  }
  if ($colour eq 'clear') {
    return Gtk2::Gdk::Color->new (0,0,0, 0);
  }

  my $drawable = $self->{'-drawable'};
  my $colormap = $drawable->get_colormap;
  if (! $colormap) {
    if ($drawable->get_depth == 1) {
      if ($colour eq '#000000' || $colour eq '#000000000000') {
        return Gtk2::Gdk::Color->new (0,0,0, 0);
      } elsif ($colour eq '#FFFFFF' || $colour eq '#FFFFFFFFFFFF') {
        return Gtk2::Gdk::Color->new (0,0,0, 1);
      }
    }
    croak "No colormap to interpret colour: $colour";
  }

  # think parse and rgb_find are client-side operations, no no need to cache
  # the results
  #
  my $colorobj = Gtk2::Gdk::Color->parse ($colour)
    || croak "Cannot parse colour: $colour";
  $colormap->rgb_find_color ($colorobj);
  return $colorobj;
}

1;
__END__

=for stopwords resized filename Ryde Gdk bitmap pixmap

=head1 NAME

Image::Base::Gtk2::Gdk::Drawable -- draw into a Gdk window or pixmap

=for test_synopsis my $win_or_pixmap

=head1 SYNOPSIS

 use Image::Base::Gtk2::Gdk::Drawable;
 my $image = Image::Base::Gtk2::Gdk::Drawable->new
                 (-drawable => $win_or_pixmap);
 $image->line (0,0, 99,99, '#FF00FF');
 $image->rectangle (10,10, 20,15, 'white');

=head1 CLASS HIERARCHY

C<Image::Base::Gtk2::Gdk::Drawable> is a subclass of
C<Image::Base>,

    Image::Base
      Image::Base::Gtk2::Gdk::Drawable

=head1 DESCRIPTION

C<Image::Base::Gtk2::Gdk::Drawable> extends C<Image::Base> to draw into a
Gdk drawable, meaning either a window or a pixmap.

Colour names are anything recognised by C<< Gtk2::Gdk::Color->parse >>,
which means various names like "pink" plus hex #RRGGBB or #RRRRGGGGBBB.  For
X the names are generally found in F</etc/X11/rgb.txt>.  Special names "set"
and "clear" mean pixel values 1 and 0 for use with bitmaps.

The C<Image::Base::Gtk2::Gdk::Pixmap> subclass has some specifics for
creating pixmaps, but this base Drawable is enough to draw into an existing
one.

=head1 FUNCTIONS

=over 4

=item C<$image = Image::Base::Gtk2::Gdk::Drawable-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  A C<-drawable> parameter must be
given,

    $image = Image::Base::Gtk2::Gdk::Drawable->new
                 (-drawable => $win_or_pixmap);

Further parameters are applied per C<set> (see L</ATTRIBUTES> below).

=item C<$image-E<gt>xy ($x, $y, $colour)>

Get or set the pixel at C<$x>,C<$y>.

In the current code colours are returned in #RRGGBB form and require a
colormap.  Perhaps in the future it will be #RRRRGGGGBBBB form since under X
there's 16-bit resolution.  Generally a colormap is required, though bitmaps
without a colormap give 0 and 1.  The intention is probably to have pixmaps
without colormaps give back raw pixel values.  Maybe bitmaps could give back
"set" and "clear" as an option.

Fetching a pixel is an X server round-trip and reading out a big region will
be slow.  The server can give a region or the entire drawable in one go, so
some function for that would be better if much fetching is needed.

=back

=head1 ATTRIBUTES

=over

=item C<-drawable> (C<Gtk2::Gdk::Drawable> object)

The target drawable.

=item C<-width> (integer)

=item C<-height> (integer)

The size of the drawable per C<< $drawable->get_size >>.

=item C<-colormap> (C<Gtk2::Gdk::Colormap>, or C<undef>)

The colormap in the underlying C<-drawable> per
C<< $drawable->get_colormap >>.  Windows always have a colormap, but pixmaps
may or may not.

=item C<-depth> (integer, read-only)

The number of bits per pixel in the drawable, from
C<< $drawable->get_depth >>.

=item C<-screen> (C<Gtk2::Gdk::Screen>, read-only)

The screen of the underlying drawable (C<< $drawable->get_screen >>).

=back

=head1 SEE ALSO

L<Image::Base>,
L<Image::Base::Gtk2::Gdk::Pixmap>,
L<Image::Base::Gtk2::Gdk::Window>,
L<Gtk2::Gdk::Drawable>

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
