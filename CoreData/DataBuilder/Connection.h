/*
    Connection.h

    Interface declaration of the Connection class for the DataBuilder
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

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

@class NSView, NSString, NSColor, NSTextFieldCell;

typedef enum {
  NoArrowStyle,
  SingleArrowStyle,
  DoubleArrowStyle
} ArrowStyle;

/**
 * A connection object draws a ``connection'' line between the two views.
 * This is used in relationship and inheritance views to draw the
 * relations between objects.
 */
@interface Connection : NSObject
{
  NSView * view1, * view2;

  NSColor * lineColor;
  ArrowStyle view1ArrowStyle, view2ArrowStyle;
  NSTextFieldCell * view1TitleCell, * view2TitleCell;
}

- (void) setView1: (NSView *) aView;
- (NSView *) view1;

- (void) setView2: (NSView *) aView;
- (NSView *) view2;

- (void) setView1ArrowStyle: (ArrowStyle) aStyle;
- (ArrowStyle) view1ArrowStyle;

- (void) setView2ArrowStyle: (ArrowStyle) aStyle;
- (ArrowStyle) view2ArrowStyle;

/**
 * Sets the color with which the line is drawn.
 */
- (void) setLineColor: (NSColor *) aColor;
- (NSColor *) lineColor;

/**
 * Instructs the arrow to draw itself.
 */
- (void) draw;

/**
 * Returns the rect occupied by the line
 */
- (NSRect) drawingRect;

@end
