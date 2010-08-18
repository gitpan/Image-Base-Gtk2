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


package Image::Base::Gtk2::Gdk::Image;
use 5.008;
use strict;
use warnings;
use Carp;
use base 'Image::Base';

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 0;

sub new {
  my ($class, %params) = @_;
  ### Image-GdkImage new: \%params

  # $obj->new(...) means make a copy, with some extra settings
  if (ref $class) {
    croak "Cannot clone a GdkImage yet";
  }

  if (! exists $params{'-gdkimage'}) {
    ### create new GdkImage

    my $imagetype = delete $params{'-imagetype'} || 'fastest';
    my $visual = delete $params{'-visual'}
      || ($params{'-colormap'} && $params{'-colormap'}->get_visual)
        || Gtk2::Gdk::Visual->get_system;
    $params{'-colormap'} ||= $visual->colormap;

    $params{'-gdkimage'} = Gtk2::Gdk::Image->new ($imagetype,
                                                  $visual,
                                                  delete $params{'-width'},
                                                  delete $params{'-height'});
  }

  my $self = bless {}, $class;
  $self->set (%params);
  return $self;
}

my %attr_to_get_method = (-imagetype => 'type',
                          -colormap  => 'get_colormap',
                          -visual    => 'visual',
                          -width     => 'width',
                          -height    => 'height',
                          -depth     => 'depth');
sub _get {
  my ($self, $key) = @_;

  if (my $method = $attr_to_get_method{$key}) {
    return $self->{'-gdkimage'}->$method;
  }
  return $self->SUPER::_get($key);
}

sub set {
  my ($self, %params) = @_;
  ### Image-GdkImage set(): \%params

  %$self = (%$self, %params);
  
  if (defined (my $colormap = delete $self->{'-colormap'})) {
    $gdkimage->set_colormap ($colormap);
  }
  ### set leaves: $self
}

sub xy {
  my ($self, $x, $y, $colour) = @_;
  if (@_ >= 4) {
    ### Image-GdkImage xy: "$x, $y, $colour"
    $self->{'-gdkimage'}->put_pixel ($x,$y, $self->colour_to_pixel($colour));
  } else {
    return $self->pixel_to_colour($self->{'-gdkimage'}->get_pixel ($x,$y))
  }
}

sub colour_to_pixel {
  my ($self, $colour) = @_;
  if (defined (my $pixel = $self->{'-colour_to_pixel'})) {
    return $pixel;
  }
  return $self->Image::Base::Gtk2::Gdk::Drawable::colour_to_colorobj($colour)
    ->pixel;
}

sub pixel_to_colour {
  my ($self, $pixel) = @_;
  my $colorobj = $self->{'-colormap'}->query_color($pixel);
  return sprintf '%04X%04X%04X',
    $colorobj->red, $colorobj->green, $colorobj->blue;
}

1;
__END__

=for stopwords undef Ryde Gdk Images GdkImage colormap ie toplevel

=head1 NAME

Image::Base::Gtk2::Gdk::Image -- draw into a GdkImage

=head1 SYNOPSIS

 use Image::Base::Gtk2::Gdk::Image;
 my $image = Image::Base::Gtk2::Gdk::Image->new
                 (-width => 10,
                  -height => 10);
 $image->line (0,0, 99,99, '#FF00FF');
 $image->rectangle (10,10, 20,15, 'white');

=head1 CLASS HIERARCHY

C<Image::Base::Gtk2::Gdk::Image> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::Gtk2::Gdk::Image

=head1 DESCRIPTION

C<Image::Base::Gtk2::Gdk::Image> extends C<Image::Base> to create and draw
into GdkImage objects.  A GdkImage is pixels in client-side memory.  There's
no file load or save, just drawing operations.

=head1 FUNCTIONS

=over 4

=item C<$image = Image::Base::Gtk2::Gdk::Image-E<gt>new (key=E<gt>value,...)>

Create and return a new GdkImage image object.  It can be pointed at an
existing C<Gtk2::Gdk::Image>,

    $image = Image::Base::Gtk2::Gdk::Image->new
                 (-gdkimage => $gdkimage);

Or a new C<Gtk2::Gdk::Image> created,

    $image = Image::Base::Gtk2::Gdk::Image->new
                 (-width    => 10,
                  -height   => 10);

A GdkImage requires a size and visual and perhaps a private colormap for
allocating colours.  The default is the Gtk "system" visual and its default
colormap, or desired settings can be applied with

    -visual   =>  Gtk2::Gdk::Visual object
    -colormap =>  Gtk2::Gdk::Colormap object or undef

If just C<-colormap> is given then its visual is used.

=back

=head1 ATTRIBUTES

=over

=item C<-width> (integer, read-only)

=item C<-height> (integer, read-only)

The size of a GdkImage cannot be changed once created.

=item C<-gdkimage> (C<Gtk2::Gdk::Image> object)

The target C<Gtk2::Gdk::Image> object.

=back

=head1 SEE ALSO

L<Image::Base>,
L<Gtk2::Gdk::Image>

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
