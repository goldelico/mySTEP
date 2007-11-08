/*
  NSHelpManager.h
  mySTEP

  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
  Copyright (c) 2005 DSITRI.

  Author:	Fabian Spillner <fabian.spillner@gmail.com>
  Date:	8. November 2007 - aligned with 10.5  
 
  This file is part of the mySTEP Library and is provided
  under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSHelpManager
#define _mySTEP_H_NSHelpManager

#import "Foundation/Foundation.h"

extern NSString *NSContextHelpModeDidActivateNotification; 
extern NSString *NSContextHelpModeDidDeactivateNotification; 

@interface NSHelpManager : NSObject <NSCoding>
{
}

+ (BOOL) isContextHelpModeActive;
+ (void) setContextHelpModeActive:(BOOL) contextHelpActive;
+ (NSHelpManager *) sharedHelpManager;

- (NSAttributedString *) contextHelpForObject:(id) obj;
- (void) findString:(NSString *) findString inBook:(NSString *) helpBook;
- (void) openHelpAnchor:(NSString *) helpAnchor inBook:(NSString *) helpBook;
- (void) removeContextHelpForObject:(id) obj;
- (void) setContextHelp:(NSAttributedString *) attrStr forObject:(id) obj;
- (BOOL) showContextHelpForObject:(id) obj locationHint:(NSPoint) pt;

@end

#endif /* _mySTEP_H_NSHelpManager */
