/*
   NSRulerView.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	04. December 2007 - aligned with 10.5  
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSRulerView
#define _mySTEP_H_NSRulerView

#import <AppKit/NSView.h>
#import <AppKit/NSRulerMarker.h>
#import <AppKit/NSScrollView.h>

typedef enum {
	NSHorizontalRuler,
	NSVerticalRuler
} NSRulerOrientation;

@interface NSRulerView : NSView  <NSObject, NSCoding>

+ (void) registerUnitWithName:(NSString *) unitName
				 abbreviation:(NSString *) abbreviation
 unitToPointsConversionFactor:(CGFloat) conversionFactor
				  stepUpCycle:(NSArray *) stepUpCycle
				stepDownCycle:(NSArray *) stepDownCycle;

- (NSView *) accessoryView; 
- (void) addMarker:(NSRulerMarker *) aMarker; 
- (CGFloat) baselineLocation; 
- (NSView *) clientView; 
- (void) drawHashMarksAndLabelsInRect:(NSRect) aRect; 
- (void) drawMarkersInRect:(NSRect) aRect; 
- (id) initWithScrollView:(NSScrollView *) aScrollView orientation:(NSRulerOrientation) orientation; 
- (void) invalidateHashMarks; 
- (BOOL) isFlipped; 
- (NSArray *) markers;
- (NSString *) measurementUnits; 
- (void) moveRulerlineFromLocation:(CGFloat) oldLoc toLocation:(CGFloat) newLoc; 
- (NSRulerOrientation) orientation; 
- (CGFloat) originOffset; 
- (void) removeMarker:(NSRulerMarker *) aMarker; 
- (CGFloat) requiredThickness;
- (CGFloat) reservedThicknessForAccessoryView; 
- (CGFloat) reservedThicknessForMarkers; 
- (CGFloat) ruleThickness; 
- (NSScrollView *) scrollView; 
- (void) setAccessoryView:(NSView *) aView; 
- (void) setClientView:(NSView *) aView; 
- (void) setMarkers:(NSArray *) markers; 
- (void) setMeasurementUnits:(NSString *) unitName; 
- (void) setOrientation:(NSRulerOrientation) orientation; 
- (void) setOriginOffset:(CGFloat) offset; 
- (void) setReservedThicknessForAccessoryView:(CGFloat) thickness; 
- (void) setReservedThicknessForMarkers:(CGFloat) thickness; 
- (void) setRuleThickness:(CGFloat) thickness; 
- (void) setScrollView:(NSScrollView *) scrollView;
- (BOOL) trackMarker:(NSRulerMarker *) aMarker 
	  withMouseEvent:(NSEvent *) event; 

@end

@interface NSRulerView (Delegate)

- (void) rulerView:(NSRulerView *) aRulerView
	  didAddMarker:(NSRulerMarker *) aMarker;
- (void) rulerView:(NSRulerView *) aRulerView 
	 didMoveMarker:(NSRulerMarker *) aMarker; 
- (void) rulerView:(NSRulerView *) aRulerView 
   didRemoveMarker:(NSRulerMarker *) aMarker; 
- (void) rulerView:(NSRulerView *) aRulerView 
   handleMouseDown:(NSEvent *) event; 
- (BOOL) rulerView:(NSRulerView *) aRulerView 
   shouldAddMarker:(NSRulerMarker *) aMarker; 
- (BOOL) rulerView:(NSRulerView *) aRulerView
  shouldMoveMarker:(NSRulerMarker *) aMarker; 
- (BOOL) rulerView:(NSRulerView *) aRulerView 
shouldRemoveMarker:(NSRulerMarker *) aMarker;
- (CGFloat) rulerView:(NSRulerView *) aRulerView
	  willAddMarker:(NSRulerMarker *) aMarker
		 atLocation:(CGFloat) location; 
- (CGFloat) rulerView:(NSRulerView *) aRulerView
	 willMoveMarker:(NSRulerMarker *) aMarker
		 toLocation:(CGFloat) location; 
- (void) rulerView:(NSRulerView *) aRulerView
 willSetClientView:(NSView *) newClient; 

@end

#endif /* _mySTEP_H_NSRulerView */
