//
//  myView.h
//  myTest
//
//  Created by Dr. H. Nikolaus Schaller on Mon Jan 05 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface myView : NSView
{
	float angle;	// rotation angle
	IBOutlet NSView  *boundsRotationView;
	IBOutlet NSView  *frameRotationView;
	IBOutlet NSView  *boundsChangeView;
}
@end

@interface myViewFlipped : myView

@end

// for class swapper test

@interface CalcButton : NSButton
@end

@interface SilverBox : NSBox
@end

@interface myTextView : NSTextView
{
	
}

@end

