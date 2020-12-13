//
//  NSScaleRotateFlipView.h
//  ElectroniCAD
//
//  Created by H. Nikolaus Schaller on 07.12.19.
//  Copyright 2019 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSScaleRotateFlipView : NSView
{
	float _scale;
	int _rotationAngle;
	BOOL _isHorizontallyFlipped;
	BOOL _isVerticallyFlipped;
	BOOL _boundsAreFlipped;
	BOOL _autoMagnifyOnResize;
}

- (NSView *) contentView;
- (void) setContentView:(NSView *) object;
- (NSRect) contentFrame;	// frame or activeFrame of contentView
- (NSPoint) center;	// get center
- (void) setCenter:(NSPoint) center;	// set center
- (float) scale;
- (void) setScale:(float) scale;
- (void) setScaleForRect:(NSRect) area;
- (BOOL) isHorizontallyFlipped;
- (BOOL) isFlipped;
- (void) setFlipped:(BOOL) flag;
- (int) rotationAngle;
- (void) setRotationAngle:(int) angle;

/* menu actions */

- (IBAction) center:(id) sender;	// center contentFrame
- (IBAction) zoomIn:(id) sender;
- (IBAction) zoomOut:(id) sender;
- (IBAction) zoomFit:(id) sender;	// zoom to fit contentFrame
- (IBAction) zoomUnity:(id) sender;
- (IBAction) flipHorizontal:(id) sender;
- (IBAction) flipVertical:(id) sender;
- (IBAction) unflip:(id) sender;
- (IBAction) rotateImageLeft:(id) sender;
- (IBAction) rotateImageRight:(id) sender;
- (IBAction) rotateImageLeft90:(id) sender;
- (IBAction) rotateImageRight90:(id) sender;
- (IBAction) rotateImageUpright:(id) sender;

@end

@interface NSView (NSScaleRotateFlipContentView)
- (NSRect) activeFrame;
@end
