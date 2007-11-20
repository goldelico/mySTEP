/*
	NSNibOutletConnector.h
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.

	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	14. November 2007 - aligned with 10.5 
 
	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSNibOutletConnector
#define _mySTEP_H_NSNibOutletConnector

#import <AppKit/NSNibConnector.h>

@interface NSNibOutletConnector : NSNibConnector

- (void) establishConnection;

@end

#endif /* _mySTEP_H_NSNibOutletConnector */
