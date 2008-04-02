//
//  UIView.h
//  UIKit
//
//  Created by H. Nikolaus Schaller on 06.03.08.
//  Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//
//  based on http://www.cocoadev.com/index.pl?UIKit
//

#import <Cocoa/Cocoa.h>
#import <UIKit/UIResponder.h>

@interface UIView : UIResponder {
}

- (id) initWithFrame:(CGRect) rect;
- (void) addSubview:(UIView *) view;
- (void) drawRect:(CGRect) rect;
CGContextRef UICurrentContext();
- (void) setNeedsDisplay;
- (void) setNeedsDisplayInRect:(CGRect) rect;
- (CGRect) frame;
- (CGRect) bounds;
- (void) setTapDelegate:(id) delegate;

typedef enum
{
	kUIViewSwipeUp = 1,
	kUIViewSwipeDown = 2,
	kUIViewSwipeLeft = 4,
	kUIViewSwipeRight = 8
} UIViewSwipeDirection;

- (BOOL) canHandleSwipes;

- (int) swipe:(UIViewSwipeDirection) num withEvent:(GSEvent *) event;

- (void) drawLayer:(id) inLayer inContext:(CGContextRef) inContext;

@end

@interface NSObject (TapDelegateMethods)

#if FIXME
view:handleTapWithCount:event:
view:handleTapWithCount:event:fingerCount:
viewHandleTouchPause:isDown:
viewDoubleTapDelay:
viewRejectAsTapThrehold:
viewTouchPauseThreshold:
#endif

@end
