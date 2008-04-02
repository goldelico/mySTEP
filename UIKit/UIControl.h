//
//  UIControl.h
//  UIKit
//
//  Created by H. Nikolaus Schaller on 06.03.08.
//  Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//
//  based on http://www.cocoadev.com/index.pl?UIKit
//

#import <Cocoa/Cocoa.h>
#import <UIKit/UIView.h>

@interface UIControl : UIView {

}

#define UIMouseDown              (1<<0)
#define UIMouseDragged           (1<<2)		//within active area of control
#define UIMouseExitedDragged     (1<<3)		//move outside active area 
#define UIMouseEntered           (1<<4)		//move crossed into active area
#define UIMouseExited            (1<<5)		//move crossed out of active area
#define UIMouseUp                (1<<6)		//up within the active area
#define UIMouseExitedUp          (1<<7)		//up outside active area

- (void) addTarget:(id) target action:(SEL) action forEvents:(int) eventMask;

@end
