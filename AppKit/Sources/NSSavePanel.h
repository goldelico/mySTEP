/*
   NSSavePanel.h

   Standard save panel for saving files

   Copyright (C) 1996, 1997 Free Software Foundation, Inc.

   Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998
   Integration by Felipe A. Rodriguez <far@ix.netcom.com> 
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	05. December 2007 - aligned with 10.5   

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSSavePanel
#define _mySTEP_H_NSSavePanel

#import <Foundation/NSCoder.h>
#import <Foundation/NSSet.h>

#import <AppKit/NSPanel.h>
#import <AppKit/NSBrowser.h>
#import <AppKit/NSForm.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSSearchField.h>
#import <AppKit/NSBox.h>
#import <AppKit/NSImageView.h>
#import <AppKit/NSButton.h>

@class NSString;
@class NSView;
@class NSURL;

enum {
	NSFileHandlingPanelCancelButton,
	NSFileHandlingPanelOKButton,
#if DEPRECATED
	NSFileHandlingPanelImageButton,
	NSFileHandlingPanelTitleField,
	NSFileHandlingPanelBrowser,
	NSFileHandlingPanelForm,
	NSFileHandlingPanelHomeButton,
	NSFileHandlingPanelDiskButton,
	NSFileHandlingPanelDiskEjectButton
#endif
};

@interface NSSavePanel : NSPanel
{
    IBOutlet NSBrowser *browser;
	IBOutlet NSTextField *fileName;
    IBOutlet NSButton *homeButton;
    IBOutlet NSButton *mountButton;
    IBOutlet NSButton *unmountButton;
    IBOutlet NSButton *newFolderButton;
    IBOutlet NSButton *okButton;
    IBOutlet NSButton *cancelButton;
	IBOutlet NSSearchField *searchField;

    IBOutlet NSImageView *iconView;	// ?
    
	IBOutlet NSBox *separator;	// not used

	NSString *directory;
    NSString *lastValidPath;
    NSArray *requiredTypes;
    NSSet *typeTable;
    NSView *_accessoryView;
	BOOL treatsFilePackagesAsDirectories;
	BOOL includeNewFolderButton;
	BOOL allowsOtherFileTypes;
	BOOL canSelectHiddenExtension;
}

+ (NSSavePanel *) savePanel;			

- (NSView *) accessoryView;
- (NSArray *) allowedFileTypes;
- (BOOL) allowsOtherFileTypes;
- (void) beginSheetForDirectory:(NSString *) path 
						   file:(NSString *) name 
				 modalForWindow:(NSWindow *) window 
				  modalDelegate:(id) delegate 
				 didEndSelector:(SEL) sel 
					contextInfo:(void *) context;
- (IBAction) cancel:(id) sender;
- (BOOL) canCreateDirectories;
- (BOOL) canSelectHiddenExtension;
- (id) delegate; 
- (NSString *) directory;
- (NSString *) filename;
- (BOOL) isExpanded; 
- (BOOL) isExtensionHidden; 
- (NSString *) message;
- (NSString *) nameFieldLabel;
- (IBAction) ok:(id) sender;	
- (NSString *) prompt;
- (NSString *) requiredFileType;
- (NSInteger) runModal;
- (NSInteger) runModalForDirectory:(NSString *) path file:(NSString *) filename;
- (void) setAccessoryView:(NSView *) aView;
- (void) setAllowedFileTypes:(NSArray *) types;
- (void) setAllowsOtherFileTypes:(BOOL) flag;
- (void) setCanCreateDirectories:(BOOL) flag;
- (void) setCanSelectHiddenExtension:(BOOL) flag;
- (void) setDelegate:(id) delegate;
- (void) setDirectory:(NSString *) path;
- (void) setExtensionHidden:(BOOL) flag; 
- (void) setMessage:(NSString *) message;
- (void) setNameFieldLabel:(NSString *) label;
- (void) setPrompt:(NSString *) prompt;
- (void) setRequiredFileType:(NSString *) type;
- (void) setTitle:(NSString *) title;
- (void) setTreatsFilePackagesAsDirectories:(BOOL) flag;
- (NSString *) title;
- (BOOL) treatsFilePackagesAsDirectories;
- (NSURL *) URL;
- (void) validateVisibleColumns;

@end

@interface NSObject (NSSavePanelDelegate)

- (NSComparisonResult) panel:(id) sender
			 compareFilename:(NSString *) filename1
					    with:(NSString *) filename2
			   caseSensitive:(BOOL) caseSensitive;	
- (void) panel:(id) sender directoryDidChange:(NSString *) path; 
- (BOOL) panel:(id) sender isValidFilename:(NSString *) filename;
- (BOOL) panel:(id) sender shouldShowFilename:(NSString *) filename;
- (NSString *) panel:(id) sender 
 userEnteredFilename:(NSString *) filename 
		   confirmed:(BOOL) flag;
- (void) panel:(id) sender willExpand:(BOOL)flag;
- (void) panelSelectionDidChange:(id) sender; 

@end

#endif /* _mySTEP_H_NSSavePanel */
