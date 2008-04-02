//
//  IKImageView.h
//  ImageKit
//
//  Created by H. Nikolaus Schaller on 16.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LKLayer;
@class CIFilter;
@class CGImage;

typedef CGImage *CGImageRef;

@interface IKImageView : NSView
{
	CGImageRef _image;
	NSColor *_backgroundColor;
	NSString *-currentToolMode;
	id _delegate;
	CIFilter *_imageCorrection;
	CGFloat _rotationAngle;
	CGFloat _zoomFactor;	
	BOOL _autohidesScrollers;
	BOOL _autoresizes;
	BOOL -doubleClickOpensImageEditPanel;
	BOOL _editable;
	BOOL _hasHorizontalScroller;
	BOOL _hasVerticalScroller;
	BOOL _supportsDragAndDrop;
}

- (BOOL) autohidesScrollers;
- (BOOL) autoresizes;
- (NSColor *) backgroundColor;
- (NSString *) currentToolMode;
- (id) delegate;
- (BOOL) doubleClickOpensImageEditPanel;
- (BOOL) editable;
- (BOOL) hasHorizontalScroller;
- (BOOL) hasVerticalScroller;
- (CIFilter *) imageCorrection;
- (CGFloat) rotationAngle;
- (BOOL) supportsDragAndDrop;
- (CGFloat) zoomFactor;

- (void) setAutohidesScrollers:(BOOL) flag;
- (void) setAutoresizes:(BOOL) flag;
- (void) setBackgroundColor:(NSColor *) color;
- (void) setCurrentToolMode:(NSString *) mode;
- (void) setDelegate:(id) delegate;
- (void) setDoubleClickOpensImageEditPanel:(BOOL) flag;
- (void) setEditable:(BOOL) flag;
- (void) setHasHorizontalScroller:(BOOL) flag;
- (void) setHasVerticalScroller:(BOOL) flag;
- (void) setImageCorrection:(CIFilter *) filter;
- (void) setRotationAngle:(CGFloat) angle;
- (void) setSupportsDragAndDrop:(BOOL) flag;
- (void) setZoomFactor:(CGFloat) zoom;

- (NSPoint) convertImagePointToViewPoint:(NSPoint) pnt;
- (NSRect) convertImageRectToViewRect:(NSRect) pnt;
- (NSPoint) convertViewPointToImagePoint:(NSPoint) pnt;
- (NSRect) convertViewRectToImageRect:(NSRect) pnt;
- (void) flipImageHorizontal:(id) sender;
- (void) flipImageVertical:(id) sender;
- (CGImageRef) image;
- (NSDictionary *) imageProperties;
- (NSSize) imageSize;
- (LKLayer *) overlayForType:(NSString *) type;
- (void) scrollToPoint:(NSPoint) pnt;
- (void) scrollToRect:(NSRect) rect;
- (void) setImage:(CGImageRef) image imageProperties:(NSDictionary *) meta;
- (void) setImageWithURL:(NSURL *) url;
- (void) setImageZoomFactor:(CGFloat) zoom centerPoint:(NSPoint) center;
- (void) setOverlay:(LKLayer *) layer forType:(NSString *) type;
- (void) setRotationAngle:(CGFloat) angle centerPoint:(NSPoint) center;
- (void) zoomImageToActualSize:(id) sender;
- (void) zoomImageToFit:(id) sender;
- (void) zoomImageToRect:(NSRect) rect;

@end

extern NSString *IKToolModeMove;
extern NSString *IKToolModeSelect;
extern NSString *IKToolModeCrop;
extern NSString *IKToolModeRotate;
extern NSString *IKToolModeAnnotate;
