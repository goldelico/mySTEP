/*
    NSGeometryAdditions.h

    Additional functions for manipulating geometric structures.

    Copyright (C) 2005  Saso Kiselkov

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#import <Foundation/NSGeometry.h>

/**
 * Adjusts `r' so that it's size and height are positive, shifting
 * around it's origin as necessary.
 */
static inline NSRect
PositiveRect(NSRect r)
{
  if (r.size.width < 0)
    {
      r.size.width = -r.size.width;
      r.origin.x -= r.size.width;
    }
  if (r.size.height < 0)
    {
      r.size.height = -r.size.height;
      r.origin.y -= r.size.height;
    }

  return r;
}

/**
 * Increments `r' to be `increment' larger in each direction.
 */
static inline NSRect
IncrementedRect(NSRect r, float increment)
{
  r.origin.x -= increment;
  r.origin.y -= increment;
  r.size.width += 2*increment;
  r.size.height += 2*increment;

  return r;
}
