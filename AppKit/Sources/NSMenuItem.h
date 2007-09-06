/* 
   NSMenuItem.h

   Menu cell protocol and cell class.

   Modified:  H. Nikolaus Schaller <hns@computer.org>
   Date:    2003-2006
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSMenuItem
#define _mySTEP_H_NSMenuItem

#import <AppKit/NSMenu.h>

// this is the official interface
// internally, NSMenuItem is implemented as a subclass of NSButtonCell

@interface NSMenuItem : NSObject  <NSMenuItem>
{
	// officially no instance variables
}

@end

#endif /* _mySTEP_H_NSMenuItem */
