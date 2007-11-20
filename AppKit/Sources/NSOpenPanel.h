/* 
	NSOpenPanel.h

	Standard open panel for opening files

	Copyright (C) 1996 Free Software Foundation, Inc.

	Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>	
	Date: August 1998
	Integration by Felipe A. Rodriguez <far@ix.netcom.com> 
   
	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	14. November 2007 - aligned with 10.5 
 
	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSOpenPanel
#define _mySTEP_H_NSOpenPanel

#import <AppKit/NSSavePanel.h>

@class NSString;
@class NSArray;
@class NSMutableArray;

@interface NSOpenPanel : NSSavePanel
{
	struct __OpenPanelFlags {
		unsigned int canChooseDirectories:1;
		unsigned int canChooseFiles:1;
		unsigned int allowsMultipleSelect:1;
		unsigned int reserved:5;
		} _op;
}

+ (NSOpenPanel *) openPanel;

- (BOOL) allowsMultipleSelection;
- (void) beginForDirectory:(NSString *) absolutePath 
					  file:(NSString *) file 
					 types:(NSArray *) types 
		  modelessDelegate:(id) delegate 
			didEndSelector:(SEL) sel 
			   contextInfo:(void *) context;
- (void) beginSheetForDirectory:(NSString *) absolutePath 
						   file:(NSString *) file 
						  types:(NSArray *) types 
				 modalForWindow:(NSWindow *) window 
				  modalDelegate:(id) delegate 
				 didEndSelector:(SEL) sel 
					contextInfo:(void *) context;
- (BOOL) canChooseDirectories;
- (BOOL) canChooseFiles;
- (NSArray *) filenames;
- (BOOL) resolvesAliases; 
- (NSInteger) runModalForDirectory:(NSString *) path
							  file:(NSString *) name
							 types:(NSArray *) fileTypes;
- (NSInteger) runModalForTypes:(NSArray *) fileTypes;
- (void) setAllowsMultipleSelection:(BOOL) flag;
- (void) setCanChooseDirectories:(BOOL) flag;
- (void) setCanChooseFiles:(BOOL) flag;
- (void) setResolvesAliases:(BOOL) flag; 
- (NSArray *) URLs;

@end

#endif /* _mySTEP_H_NSOpenPanel */
