/*
    NSFontAdditions.h

    Declarations of the additions to the NSFont class for the DataBuilder
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

#import <AppKit/NSFont.h>

@interface NSFont (Additions)

/**
 * Attempts to find an italic font and return it.
 *
 * The lookup is done by taking the result of boldSystemFontOfSize:,
 * and looking for a font with the same name, but 'Bold' substituted
 * for 'Italic' or 'Oblique'.
 *
 * @return The font if it is found, or `nil' if not.
 */
+ (NSFont *) italicSystemFontOfSize: (float) aSize;

@end
