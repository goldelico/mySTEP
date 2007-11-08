/*
	NSController.h
	mySTEP
 
	Created by Dr. H. Nikolaus Schaller on Mon Mar 21 2005.
	Copyright (c) 2005 DSITRI.
 
	Author:	Fabian Spillner
	Date:	22. October 2007
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	7. November 2007 - aligned with 10.5
 
	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSController
#define _mySTEP_H_NSController

#import "Foundation/NSObject.h"
@class NSString;
@class NSCoder;

@interface NSController : NSObject <NSCoding>

// abstract class -- all methods defined in subclasses

- (BOOL) commitEditing;
- (void) commitEditingWithDelegate:(id) delegate didCommitSelector:(SEL) sel contextInfo:(void *) context;
- (void) discardEditing;
- (BOOL) isEditing;
- (void) objectDidBeginEditing:(id) editor;
- (void) objectDidEndEditing:(id) editor;

@end

#endif /* _mySTEP_H_NSController */
