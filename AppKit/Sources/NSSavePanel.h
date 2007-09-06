/*
   NSSavePanel.h

   Standard save panel for saving files

   Copyright (C) 1996, 1997 Free Software Foundation, Inc.

   Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998
   Integration by Felipe A. Rodriguez <far@ix.netcom.com> 

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
    IBOutlet NSBrowser *browser;		// file browser
		IBOutlet NSTextField *fileName;		// file name
    IBOutlet NSButton *homeButton;		// Home button
    IBOutlet NSButton *mountButton;		// Mount/Disk button
    IBOutlet NSButton *unmountButton;	// Unmount/Eject button
    IBOutlet NSButton *newFolderButton;	// New Folder
    IBOutlet NSButton *okButton;		// Ok button - with prompt
    IBOutlet NSButton *cancelButton;	// Cancel button
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

+ (NSSavePanel *) savePanel;			// Returns an instance of NSSavePanel, 
										// creating one if necessary.

- (void) setAccessoryView:(NSView *)aView;
- (NSView *) accessoryView;
					// Sets the title of the NSSavePanel to title. By default, 
					// "Save" is the title string. If you adapt the NSSavePanel 
					// for other uses, its title should reflect the user action 
					// that brings it to the screen.
- (void) setTitle:(NSString *)title;
- (NSString *) title;
					// Returns the title of the Ok button
					// the current pathname or file name. By default this 
					// prompt is Save or Open
- (NSString *)prompt;
- (void) setPrompt:(NSString *)prompt;
					// Sets the current path name in the Save panel's browser. 
					// The path argument must be an absolute path name.
- (void) setDirectory:(NSString *)path;
				// Specifies the type, a file name extension to be appended to 
				// any selected files that don't already have that extension;
				// The argument type should not include the period that begins 
				// the extension.  Invoke this method each time the Save panel 
				// is used for another file type within the application.
- (void) setRequiredFileType:(NSString *)type;
- (NSString *) requiredFileType;
				// Sets the NSSavePanel's behavior for displaying file packages 
				// (for example, MyApp.app) to the user.  If flag is YES, the 
				// user is shown files and subdirectories within a file 
				// package.  If NO, the NSSavePanel shows each file package as 
				// a file, thereby giving no indication that it is a directory.
- (void) setTreatsFilePackagesAsDirectories:(BOOL)flag;
- (BOOL) treatsFilePackagesAsDirectories;
				// Validates and possibly reloads the browser columns visible 
				// in the Save panel by causing the delegate method 
				// panel:shouldShowFilename: to be invoked. One situation in 
				// which this method would find use is whey you want the 
				// browser show only files with certain extensions based on the 
				// selection made in an accessory-view pop-up list.  When the 
				// user changes the selection, you would invoke this method to
				// revalidate the visible columns. 

- (BOOL) canCreateDirectories;
- (void) setCanCreateDirectories:(BOOL) flag;

- (NSString *) nameFieldLabel;
- (NSString *) message;
- (void) setNameFieldLabel:(NSString *) label;
- (void) setMessage:(NSString *) message;

- (BOOL) allowsOtherFileTypes;
- (void) setAllowsOtherFileTypes:(BOOL) flag;
- (BOOL) canSelectHiddenExtension;
- (void) setCanSelectHiddenExtension:(BOOL) flag;
- (NSArray *) allowedFileTypes;
- (void) setAllowedFileTypes:(NSArray *)types;

- (void) validateVisibleColumns;

				// Initializes the panel to the directory specified by path 
				// and, optionally, the file specified by filename, then 
				// displays it and begins its modal event loop; path and 
				// filename can be empty strings, but cannot be nil.  The 
				// method invokes Application's runModalForWindow: method with 
				// self as the argument.  Returns NSOKButton (if the user 
				// clicks the OK button) or NSCancelButton (if the user clicks 
				// the Cancel button).  Do not invoke filename or directory 
				// within a modal loop because the information that these 
				// methods fetch is updated only upon return.

- (int) runModalForDirectory:(NSString *)path file:(NSString *)filename;
- (int) runModal;
				// Returns the absolute pathname of the directory currently 
				// shown in the panel.  Do not invoke this method within a 
				// modal session (runModal or runModalForDirectory:file:)
				// because the directory information is only updated just 
				// before the modal session ends.

- (NSString *)directory;
- (NSString *)filename;
- (NSURL *) URL;

- (IBAction) ok:(id)sender;									// Target / Action
- (IBAction) cancel:(id)sender;

@end

													// Implemented by Delegate 
@interface NSObject (NSSavePanelDelegate)
				// The NSSavePanel sends this message just before the end of a 
				// modal session for each file name displayed or selected 
				// (including file names in multiple selections).  The delegate 
				// determines whether it wants the file identified by filename; 
				// it returns YES if the file name is valid, or NO if the 
				// NSSavePanel should stay in its modal loop and wait for the 
				// user to type in or select a different file name or names. If 
				// the delegate refuses a file name in a multiple selection, 
				// none of the file names in the selection are accepted.
- (BOOL) panel:(id)sender isValidFilename:(NSString*)filename;
- (NSComparisonResult) panel:(id)sender
					   compareFilename:(NSString *)filename1
					   with:(NSString *)filename2
					   caseSensitive:(BOOL)caseSensitive;	 
- (BOOL) panel:(id)sender shouldShowFilename:(NSString *)filename;

@end

#endif /* _mySTEP_H_NSSavePanel */
