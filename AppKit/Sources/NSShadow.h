/*
	NSShadow.h
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	05. December 2007 - aligned with 10.5   
 
	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSShadow
#define _mySTEP_H_NSShadow

#import "AppKit/NSController.h"

@interface NSShadow : NSObject <NSCoding>
{
}

- (void) set; 
- (void) setShadowBlurRadius:(CGFloat) rad; 
- (void) setShadowColor:(NSColor *) col; 
- (void) setShadowOffset:(NSSize) off; 
- (CGFloat) shadowBlurRadius; 
- (NSColor *) shadowColor; 
- (NSSize) shadowOffset; 

@end

#endif /* _mySTEP_H_NSShadow */
