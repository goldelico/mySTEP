/*
    NSFontAdditions.m

    Implementations of the additions to the NSFont class for the DataBuilder
    application.

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

#import "NSFontAdditions.h"

#import <Foundation/NSString.h>

@implementation NSFont (Additions)

+ (NSFont *) italicSystemFontOfSize: (float) aSize
{
  NSFont * font;

  // try 'Italic'
  font = [NSFont fontWithName: [[[NSFont boldSystemFontOfSize: 0]
    fontName] stringByReplacingString: @"Bold" withString: @"Italic"]
                         size: aSize];
  if (font != nil)
    {
      return font;
    }

  // try 'Oblique'
  font = [NSFont fontWithName: [[[NSFont boldSystemFontOfSize: 0]
    fontName] stringByReplacingString: @"Bold" withString: @"Oblique"]
                         size: aSize];
  if (font != nil)
    {
      return font;
    }

  return font;
}

@end
