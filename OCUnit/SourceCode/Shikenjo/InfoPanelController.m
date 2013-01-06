/*$Id: InfoPanelController.m,v 1.5 2001/11/10 16:16:25 phink Exp $*/

// Copyright (c) 1997, 1998, 1999, Sen:te Ltd.  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "InfoPanelController.h"
#import <SenFoundation/SenFoundation.h>

@implementation InfoPanelController

- (id) init
{
    return [super initWithWindowNibName:@"InfoPanel"];
}


- (IBAction) showWindow:(id)sender
{
    [[self window] center];
    [super showWindow:sender];
}
@end
