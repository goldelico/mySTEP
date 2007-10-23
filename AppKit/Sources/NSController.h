/*
	NSController.h
	mySTEP
 
	Created by Dr. H. Nikolaus Schaller on Mon Mar 21 2005.
	Copyright (c) 2005 DSITRI.
 
	Author:	Fabian Spillner
	Date:	22. October 2007
 
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
- (void) discardEditing;
- (BOOL) isEditing;
- (void) objectDidBeginEditing:(id) editor;
- (void) objectDidEndEditing:(id) editor;

@end

#endif /* _mySTEP_H_NSController */
