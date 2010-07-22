#!/usr/bin/perl -w

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

use 5.010;
use strict;
use warnings;
use Gtk2 '-init';

use Smart::Comments;

{
  require Gtk2;
  Gtk2->init;
  my $bitmap = Gtk2::Gdk::Pixmap->new (undef, 256,256, 1);
  my $image = $bitmap->get_image (0,0, 129,128);
  say $image->bpp;
  say $image->bpl;
  say $image->bits_per_pixel;
  exit 0;
}




