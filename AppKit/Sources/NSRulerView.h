/*
   NSRulerView.h

   Copyright (C) 1996 Free Software Foundation, Inc.

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

- (id) initWithScrollView:(NSScrollView *)aScrollView
			  orientation:(NSRulerOrientation)orientation; 


+ (void)registerUnitWithName:(NSString *)unitName
				abbreviation:(NSString *)abbreviation
				unitToPointsConversionFactor:(float)conversionFactor
				stepUpCycle:(NSArray *)stepUpCycle
				stepDownCycle:(NSArray *)stepDownCycle;

- (void)setMeasurementUnits:(NSString *)unitName; 
- (NSString *)measurementUnits; 

- (void)setClientView:(NSView *)aView; 
- (NSView *)clientView; 

- (void)setAccessoryView:(NSView *)aView; 
- (NSView *)accessoryView; 

- (void)setOriginOffset:(float)offset; 
- (float)originOffset; 

- (void)setMarkers:(NSArray *)markers; 
- (NSArray *)markers;
- (void)addMarker:(NSRulerMarker *)aMarker; 
- (void)removeMarker:(NSRulerMarker *)aMarker; 
- (BOOL)trackMarker:(NSRulerMarker *)aMarker 
	 withMouseEvent:(NSEvent *)event; 

- (void)moveRulerlineFromLocation:(float)oldLoc toLocation:(float)newLoc; 

- (void)drawHashMarksAndLabelsInRect:(NSRect)aRect; 
- (void)drawMarkersInRect:(NSRect)aRect; 
- (void)invalidateHashMarks; 

- (void)setScrollView:(NSScrollView *)scrollView;
- (NSScrollView *)scrollView; 

- (void)setOrientation:(NSRulerOrientation)orientation; 
- (NSRulerOrientation)orientation; 
- (void)setReservedThicknessForAccessoryView:(float)thickness; 
- (float)reservedThicknessForAccessoryView; 
- (void)setReservedThicknessForMarkers:(float)thickness; 
- (float)reservedThicknessForMarkers; 
- (void)setRuleThickness:(float)thickness; 
- (float)ruleThickness; 
- (float)requiredThickness;
- (float)baselineLocation; 
- (BOOL)isFlipped; 

- (void)rulerView:(NSRulerView *)aRulerView
		didAddMarker:(NSRulerMarker *)aMarker;
- (void)rulerView:(NSRulerView *)aRulerView 
		didMoveMarker:(NSRulerMarker *)aMarker; 
- (void)rulerView:(NSRulerView *)aRulerView 
		didRemoveMarker:(NSRulerMarker *)aMarker; 
- (void)rulerView:(NSRulerView *)aRulerView 
		handleMouseDown:(NSEvent *)event; 
- (BOOL)rulerView:(NSRulerView *)aRulerView 
		shouldAddMarker:(NSRulerMarker *)aMarker; 
- (BOOL)rulerView:(NSRulerView *)aRulerView
		shouldMoveMarker:(NSRulerMarker *)aMarker; 
- (BOOL)rulerView:(NSRulerView *)aRulerView 
		shouldRemoveMarker: (NSRulerMarker *)aMarker;
- (float)rulerView:(NSRulerView *)aRulerView
		 willAddMarker:(NSRulerMarker *)aMarker
		 atLocation:(float)location; 
- (float)rulerView:(NSRulerView *)aRulerView
		 willMoveMarker:(NSRulerMarker *)aMarker
		 toLocation:(float)location; 
- (void)rulerView:(NSRulerView *)aRulerView
		willSetClientView:(NSView *)newClient; 
@end

#endif /* _mySTEP_H_NSRulerView */
