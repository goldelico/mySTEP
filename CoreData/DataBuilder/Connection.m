/*
    Connection.m

    Implementation of the Connection class for the DataBuilder application.

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

#import "Private.h"

#import "Connection.h"

#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>

#import <AppKit/NSView.h>
#import <AppKit/NSTextFieldCell.h>
#import <AppKit/NSColor.h>
#if USE_PS
#import <AppKit/PSOperators.h>
#else
#import <AppKit/NSBezierPath.h>
#endif

#import "NSGeometryAdditions.h"

typedef enum {
  UpwardDirection,
  DownwardDirection,
  LeftDirection,
  RightDirection
} ArrowDirection;

static const float ArrowWidth = 4,
                   ArrowLength = 6,
                   SecondArrowOffset = 4;

static void
DrawArrow(NSPoint p, ArrowDirection direction, ArrowStyle style)
{
  if (style != NoArrowStyle)
    {
      switch (direction)
        {
        case UpwardDirection:
#if USE_PS
          PSmoveto(p.x - ArrowWidth, p.y - ArrowLength);
          PSlineto(p.x, p.y);
          PSlineto(p.x + ArrowWidth, p.y - ArrowLength);
          PSstroke();
          if (style == DoubleArrowStyle)
            {
              PSmoveto(p.x - ArrowWidth,
                       p.y - ArrowLength - SecondArrowOffset);
              PSlineto(p.x, p.y - SecondArrowOffset);
              PSlineto(p.x + ArrowWidth,
                       p.y - ArrowLength - SecondArrowOffset);
              PSstroke();
            }
#else
			  {
				  NSBezierPath *path=[NSBezierPath new];
			[path moveToPoint:NSMakePoint(p.x - ArrowWidth, p.y - ArrowLength)];
			[path lineToPoint:NSMakePoint(p.x, p.y)];
			[path lineToPoint:NSMakePoint(p.x + ArrowWidth, p.y - ArrowLength)];
			[path stroke];
			if (style == DoubleArrowStyle)
				{
				[path removeAllPoints];
				[path moveToPoint:NSMakePoint(p.x - ArrowWidth, p.y - ArrowLength - SecondArrowOffset)];
				[path lineToPoint:NSMakePoint(p.x, p.y - SecondArrowOffset)];
				[path lineToPoint:NSMakePoint(p.x + ArrowWidth, p.y - ArrowLength - SecondArrowOffset)];
				[path stroke];
				}
			  }
#endif
          break;
        case DownwardDirection:
#if USE_PS
          PSmoveto(p.x - ArrowWidth, p.y + ArrowLength);
          PSlineto(p.x, p.y);
          PSlineto(p.x + ArrowWidth, p.y + ArrowLength);
          PSstroke();
          if (style == DoubleArrowStyle)
            {
              PSmoveto(p.x - ArrowWidth,
                       p.y + ArrowLength + SecondArrowOffset);
              PSlineto(p.x, p.y + SecondArrowOffset);
              PSlineto(p.x + ArrowWidth,
                       p.y + ArrowLength + SecondArrowOffset);
              PSstroke();
            }
#else
			  {
			  NSBezierPath *path=[NSBezierPath new];
			[path moveToPoint:NSMakePoint(p.x - ArrowWidth, p.y + ArrowLength)];
			[path lineToPoint:NSMakePoint(p.x, p.y)];
			[path lineToPoint:NSMakePoint(p.x + ArrowWidth, p.y + ArrowLength)];
			[path stroke];
			if (style == DoubleArrowStyle)
				{
				[path removeAllPoints];
				[path moveToPoint:NSMakePoint(p.x - ArrowWidth, p.y + ArrowLength + SecondArrowOffset)];
				[path lineToPoint:NSMakePoint(p.x, p.y + SecondArrowOffset)];
				[path lineToPoint:NSMakePoint(p.x + ArrowWidth, p.y + ArrowLength + SecondArrowOffset)];
				[path stroke];
				}
			  }
#endif
				break;
        case LeftDirection:
#if USE_PS
          PSmoveto(p.x + ArrowLength, p.y + ArrowWidth);
          PSlineto(p.x, p.y);
          PSlineto(p.x + ArrowLength, p.y - ArrowWidth);
          PSstroke();
          if (style == DoubleArrowStyle)
            {
              PSmoveto(p.x + ArrowLength + SecondArrowOffset,
                       p.y + ArrowWidth);
              PSlineto(p.x + SecondArrowOffset, p.y);
              PSlineto(p.x + ArrowLength + SecondArrowOffset,
                       p.y - ArrowWidth);
              PSstroke();
            }
#else
			  {
			  NSBezierPath *path=[NSBezierPath new];
			[path moveToPoint:NSMakePoint(p.x + ArrowLength, p.y + ArrowWidth)];
			[path lineToPoint:NSMakePoint(p.x, p.y)];
			[path lineToPoint:NSMakePoint(p.x + ArrowLength, p.y - ArrowWidth)];
			[path stroke];
			if (style == DoubleArrowStyle)
				{
				[path removeAllPoints];
				[path moveToPoint:NSMakePoint(p.x + ArrowLength + SecondArrowOffset, p.y + ArrowWidth)];
				[path lineToPoint:NSMakePoint(p.x + SecondArrowOffset, p.y)];
				[path lineToPoint:NSMakePoint(p.x + ArrowLength + SecondArrowOffset, p.y - ArrowWidth)];
				[path stroke];
				}
			  }
#endif
				break;
        case RightDirection:
#if USE_PS
          PSmoveto(p.x - ArrowLength, p.y + ArrowWidth);
          PSlineto(p.x, p.y);
          PSlineto(p.x - ArrowLength, p.y - ArrowWidth);
          PSstroke();
          if (style == DoubleArrowStyle)
            {
              PSmoveto(p.x - ArrowLength - SecondArrowOffset,
                       p.y + ArrowWidth);
              PSlineto(p.x - SecondArrowOffset, p.y);
              PSlineto(p.x - ArrowLength - SecondArrowOffset,
                       p.y - ArrowWidth);
              PSstroke();
            }
#else
			  {
			  NSBezierPath *path=[NSBezierPath new];
			[path moveToPoint:NSMakePoint(p.x - ArrowLength, p.y + ArrowWidth)];
			[path lineToPoint:NSMakePoint(p.x, p.y)];
			[path lineToPoint:NSMakePoint(p.x - ArrowLength, p.y - ArrowWidth)];
			[path stroke];
			if (style == DoubleArrowStyle)
				{
				[path removeAllPoints];
				[path moveToPoint:NSMakePoint(p.x - ArrowLength + SecondArrowOffset, p.y + ArrowWidth)];
				[path lineToPoint:NSMakePoint(p.x - SecondArrowOffset, p.y)];
				[path lineToPoint:NSMakePoint(p.x - ArrowLength + SecondArrowOffset, p.y - ArrowWidth)];
				[path stroke];
				}
			  }
#endif
				break;
        }
    }
}

static NSColor * defaultLineColor = nil;

@implementation Connection

+ (void) initialize
{
  if (defaultLineColor == nil)
    {
      ASSIGN(defaultLineColor, [NSColor colorWithCalibratedRed: 0.54
                                                         green: 0.375
                                                          blue: 0.8
                                                         alpha: 1.0]);
    }
}

- (void) dealloc
{
  TEST_RELEASE(view1);
  TEST_RELEASE(view2);

  TEST_RELEASE(lineColor);

  TEST_RELEASE(view1TitleCell);
  TEST_RELEASE(view2TitleCell);

  [super dealloc];
}

- init
{
  if ([super init])
    {
      view1TitleCell = [NSTextFieldCell new];
      [view1TitleCell setDrawsBackground: NO];
      [view1TitleCell setBordered: NO];

      view2TitleCell = [NSTextFieldCell new];
      [view2TitleCell setDrawsBackground: NO];
      [view2TitleCell setBordered: NO];

      ASSIGN(lineColor, defaultLineColor);

      return self;
    }
  else
    {
      return nil;
    }
}

- (void) setView1: (NSView *) aView
{
  ASSIGN(view1, aView);
}

- (NSView *) view1
{
  return view1;
}

- (void) setView2: (NSView *) aView
{
  ASSIGN(view2, aView);
}

- (NSView *) view2
{
  return view2;
}

- (void) setView1ArrowStyle: (ArrowStyle) aStyle
{
  view1ArrowStyle = aStyle;
}

- (ArrowStyle) view1ArrowStyle
{
  return view1ArrowStyle;
}

- (void) setView2ArrowStyle: (ArrowStyle) aStyle
{
  view2ArrowStyle = aStyle;
}

- (ArrowStyle) view2ArrowStyle
{
  return view2ArrowStyle;
}

- (void) setLineColor: (NSColor *) aColor
{
  if (aColor != nil)
    {
      ASSIGN(lineColor, aColor);
    }
  else
    {
      ASSIGN(lineColor, defaultLineColor);
    }
}

- (NSColor *) lineColor
{
  return lineColor;
}

- (void) draw
{
  float curveRange = 15;
  NSRect frame1, frame2;
  /*
   * These points correspond to describing a line like this:
   *
   * s         p1 p2
   * +---------+--+
   *              |
   *              +p3
   *              |
   *            p4+
   *              |  p6          e
   *            p5+--+-----------+
   */
  NSPoint s, p1, p2, p3, p4, p5, p6, e;
  ArrowDirection startArrowDirection, endArrowDirection;

  if (view1 == nil || view2 == nil)
    {
      NSLog(_(@"Attempt to draw an incomplete Connection object: view "
        @"specification incomplete."));
      return;
    }

  frame1 = [view1 frame];
  frame2 = [view2 frame];

  [lineColor set];

  if (NSMinY(frame2) - NSMaxY(frame1) > 2*curveRange)
    {
      s = NSMakePoint(NSMidX(frame1), NSMaxY(frame1));
      e = NSMakePoint(NSMidX(frame2), NSMinY(frame2));

      {
        float diff = e.x - s.x;

        if (diff < 0)
          {
            diff = -diff;
          }

        if (diff <= 2*curveRange)
          {
            curveRange = diff / 2;
          }
      }

      p1 = NSMakePoint(s.x, (s.y + e.y) / 2 - curveRange);
      p2 = NSMakePoint(s.x, (s.y + e.y) / 2);

      if (e.x > s.x)
        {
          p3 = NSMakePoint(s.x + curveRange, p2.y);
          p4 = NSMakePoint(e.x - curveRange, p3.y);
        }
      else if (e.x < s.x)
        {
          p3 = NSMakePoint(s.x - curveRange, p2.y);
          p4 = NSMakePoint(e.x + curveRange, p3.y);
        }
      else
        {
          p3 = NSMakePoint(s.x, p2.y + curveRange);
          p4 = p3;
        }

      p5 = NSMakePoint(e.x, (s.y + e.y) / 2);
      p6 = NSMakePoint(e.x, p5.y + curveRange);

      startArrowDirection = DownwardDirection;
      endArrowDirection = UpwardDirection;
    }
  else if (NSMinY(frame1) - NSMaxY(frame2) > 2*curveRange)
    {
      s = NSMakePoint(NSMidX(frame1), NSMinY(frame1));
      e = NSMakePoint(NSMidX(frame2), NSMaxY(frame2));

      {
        float diff = e.x - s.x;

        if (diff < 0)
          {
            diff = -diff;
          }

        if (diff <= 2*curveRange)
          {
            curveRange = diff / 2;
          }
      }

      p1 = NSMakePoint(s.x, (s.y + e.y) / 2 + curveRange);
      p2 = NSMakePoint(s.x, (s.y + e.y) / 2);

      if (e.x > s.x)
        {
          p3 = NSMakePoint(s.x + curveRange, p2.y);
          p4 = NSMakePoint(e.x - curveRange, p3.y);
        }
      else if (e.x < s.x)
        {
          p3 = NSMakePoint(s.x - curveRange, p2.y);
          p4 = NSMakePoint(e.x + curveRange, p3.y);
        }
      else
        {
          p3 = NSMakePoint(s.x, p2.y - curveRange);
          p4 = p3;
        }

      p5 = NSMakePoint(e.x, (s.y + e.y) / 2);
      p6 = NSMakePoint(e.x, p5.y - curveRange);

      startArrowDirection = UpwardDirection;
      endArrowDirection = DownwardDirection;
    }
  else if (NSMinX(frame2) - NSMaxX(frame1) > 2*curveRange)
    {
      s = NSMakePoint(NSMaxX(frame1), NSMidY(frame1));
      e = NSMakePoint(NSMinX(frame2), NSMidY(frame2));

      {
        float diff = e.y - s.y;

        if (diff < 0)
          {
            diff = -diff;
          }

        if (diff <= 2*curveRange)
          {
            curveRange = diff / 2;
          }
      }

      p1 = NSMakePoint((s.x + e.x) / 2 - curveRange, s.y);
      p2 = NSMakePoint((s.x + e.x) / 2, s.y);

      if (e.y > s.y)
        {
          p3 = NSMakePoint(p2.x, s.y + curveRange);
          p4 = NSMakePoint(p3.x, e.y - curveRange);
        }
      else if (e.y < s.y)
        {
          p3 = NSMakePoint(p2.x, s.y - curveRange);
          p4 = NSMakePoint(p3.x, e.y + curveRange);
        }
      else
        {
          p3 = NSMakePoint(p2.x - curveRange, s.y);
          p4 = p3;
        }

      p5 = NSMakePoint((s.x + e.x) / 2, e.y);
      p6 = NSMakePoint(p5.x + curveRange, e.y);

      startArrowDirection = LeftDirection;
      endArrowDirection = RightDirection;
    }
  else if (NSMinX(frame1) - NSMaxX(frame2) > 2*curveRange)
    {
      s = NSMakePoint(NSMinX(frame1), NSMidY(frame1));
      e = NSMakePoint(NSMaxX(frame2), NSMidY(frame2));

      {
        float diff = e.y - s.y;

        if (diff < 0)
          {
            diff = -diff;
          }

        if (diff <= 2*curveRange)
          {
            curveRange = diff / 2;
          }
      }

      p1 = NSMakePoint(((s.x + e.x) / 2) + curveRange, s.y);
      p2 = NSMakePoint((s.x + e.x) / 2, s.y);

      if (e.y > s.y)
        {
          p3 = NSMakePoint(p2.x, s.y + curveRange);
          p4 = NSMakePoint(p3.x, e.y - curveRange);
        }
      else if (e.y < s.y)
        {
          p3 = NSMakePoint(p2.x, s.y - curveRange);
          p4 = NSMakePoint(p3.x, e.y + curveRange);
        }
      else
        {
          p3 = NSMakePoint(p2.x + curveRange, s.y);
          p4 = p3;
        }

      p5 = NSMakePoint((s.x + e.x) / 2, e.y);
      p6 = NSMakePoint(p5.x - curveRange, e.y);

      startArrowDirection = RightDirection;
      endArrowDirection = LeftDirection;
    }
  else
    {
      return;
    }
#if USE_PS
  PSsetdash(NULL, 0, 0.0);
  PSmoveto(s.x, s.y);
  PSlineto(p1.x, p1.y);
  PScurveto(p2.x, p2.y, p2.x, p2.y, p3.x, p3.y);
  PSlineto(p4.x, p4.y);
  PScurveto(p5.x, p5.y, p5.x, p5.y, p6.x, p6.y);
  PSlineto(e.x, e.y);
  PSstroke();
#else
  {
	  NSBezierPath *path=[NSBezierPath new];
	  [path moveToPoint:NSMakePoint(s.x, s.y)];
	  [path lineToPoint:NSMakePoint(p1.x, p1.y)];
	  [path curveToPoint:NSMakePoint(p2.x, p2.y) controlPoint1:NSMakePoint(p2.x, p2.y) controlPoint2:NSMakePoint(p3.x, p3.y)];
	  [path lineToPoint:NSMakePoint(p4.x, p4.y)];
	  [path curveToPoint:NSMakePoint(p5.x, p5.y) controlPoint1:NSMakePoint(p5.x, p5.y) controlPoint2:NSMakePoint(p6.x, p6.y)];
	  [path lineToPoint:NSMakePoint(e.x, e.y)];
	  [path stroke];
  }
#endif
  DrawArrow(s, startArrowDirection, view1ArrowStyle);
  DrawArrow(e, endArrowDirection, view2ArrowStyle);
}

/*
 * FIXME: this method is just a quick approximation of the algorithm.
 * Instead of returning the real rect occupied by the drawing, it
 * returns a rect which starts at the mid X&Y coordinates of view1
 * and ends at mid X&Y coordinates of view2, plus it increments the
 * area in all directions by 5 points to cover possible arrows. The
 * perfomance difference shouldn't be any big. In case it is for you,
 * please bug me about it.
 */
- (NSRect) drawingRect
{
  NSRect frame1 = [view1 frame], frame2 = [view2 frame];
  NSRect r;

  r = PositiveRect(NSMakeRect(NSMidX(frame1), NSMidY(frame1),
    NSMidX(frame2) - NSMidX(frame1), NSMidY(frame2) - NSMidY(frame1)));

  // increase the size to cover the arrows as well
  r = IncrementedRect(r, 5);

  return r;
}

@end
