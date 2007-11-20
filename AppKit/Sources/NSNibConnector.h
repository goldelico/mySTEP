/*
	NSNibConnector.h
	mySTEP
 
	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.

	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	14. November 2007 - aligned with 10.5 
 
	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSNibConnector
#define _mySTEP_H_NSNibConnector

#import <Foundation/Foundation.h>

@interface NSNibConnector : NSObject <NSCoding>
{
	id _destination;
	id _source;
	NSString *_label;
}

- (id) destination;
- (void) establishConnection;
- (NSString *) label;
- (void) replaceObject:(id) old withObject:(id) new;
- (void) setDestination:(id) dest;
- (void) setLabel:(NSString *) label;
- (void) setSource:(id) source;
- (id) source;

@end

#endif /* _mySTEP_H_NSNibConnector */
