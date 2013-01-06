/*$Id: Shikenjo.h,v 1.1.1.1 2000/01/27 11:05:13 marco Exp $*/

// Copyright (c) 1997, 1998, 1999, Sen:te Ltd.  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import <AppKit/AppKit.h>
@class SenTestSuite;

@interface Shikenjo : NSObject
{
    IBOutlet NSTextField *errorsField;
    IBOutlet NSTextField *failuresField;
    IBOutlet NSTextField *casesField;
    IBOutlet NSTextField *messageField;
    IBOutlet NSWindow *window;

    IBOutlet NSTableView *failureTableView;
    IBOutlet NSProgressIndicator *progressView;
    IBOutlet NSButton *runButton;

    NSString *testedUnitPath;
    NSTask *testingTask;
    
    NSMutableArray *failures;
    NSCalendarDate *startTime;
    NSCalendarDate *stopTime;

    int startedSuiteCount;
}

- (IBAction) run:(id)sender;
- (IBAction) stop:(id)sender;
- (IBAction) chooseUnit:(id)sender;
@end
