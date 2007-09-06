/* 
   NSOpenPanel.h

   Standard open panel for opening files

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998
   Integration by Felipe A. Rodriguez <far@ix.netcom.com> 
   
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

- (BOOL) allowsMultipleSelection;						// Filtering Files
- (void) setAllowsMultipleSelection:(BOOL)flag;
- (BOOL) canChooseDirectories;
- (void) setCanChooseDirectories:(BOOL)flag;
- (BOOL) canChooseFiles;
- (void) setCanChooseFiles:(BOOL)flag;
							// Returns an array of the selected files and 
							// directories as absolute paths. Array ontains a  
- (NSArray *) filenames;	// single path if multiple selection is not allowed
- (NSArray *) URLs;

- (int) runModalForTypes:(NSArray *)fileTypes;			// Run the NSOpenPanel
- (int) runModalForDirectory:(NSString *)path
						file:(NSString *)name
						types:(NSArray *)fileTypes;
@end

#endif /* _mySTEP_H_NSOpenPanel */
