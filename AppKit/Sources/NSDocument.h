/* 
   NSDocument.h

   The abstract document class

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Carl Lindberg <Carl.Lindberg@hbo.com>
   Date: 1999
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Mar 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	22. October 2007
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	7. October 2007 - aligned with 10.5
 
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#ifndef _GNUstep_H_NSDocument
#define _GNUstep_H_NSDocument

#import <Foundation/NSObject.h>
#import <AppKit/NSNibDeclarations.h>
#import <AppKit/NSUserInterfaceValidation.h>


/* Foundation classes */
@class NSString;
@class NSDictionary;
@class NSArray;
@class NSMutableArray;
@class NSData;
@class NSFileManager;
@class NSURL;
@class NSUndoManager;

/* AppKit classes */
@class NSWindow;
@class NSView;
@class NSSavePanel;
@class NSMenuItem;
@class NSPageLayout;
@class NSPrintInfo;
@class NSPrintOperation;
@class NSPopUpButton;
@class NSFileWrapper;
@class NSDocumentController;
@class NSWindowController;


typedef enum _NSDocumentChangeType {
    NSChangeDone				= 0,
    NSChangeUndone				= 1,
    NSChangeCleared				= 2,
	NSChangeReadOtherContents	= 3,
	NSChangeAutosaved			= 4
} NSDocumentChangeType;

typedef enum _NSSaveOperationType {
	NSSaveOperation				= 0,
	NSSaveAsOperation			= 1,
	NSSaveToOperation			= 2,
	NSAutosaveOperation			= 3
} NSSaveOperationType;


@interface NSDocument : NSObject
{
  @private
    NSWindow		*_window;		// Outlet for the single window case - has a private setter setWindow
    NSMutableArray 	*_windowControllers;	// WindowControllers for this document
    NSString		*_fileName;		// Save location
    NSString 		*_fileType;		// file/document type
    NSPrintInfo 	*_printInfo;		// print info record
    NSView 		*savePanelAccessory;	// outlet for the accessory save-panel view
    NSPopUpButton	*spaButton;     	// outlet for "the File Format:" button in the save panel.
    NSUndoManager 	*_undoManager;		// Undo manager for this document
    long		_changeCount;		// number of time the document has been changed
    int			_documentIndex;		// Untitled index
    struct __docFlags
		{
        unsigned int inClose:1;
        unsigned int hasUndoManager:1;
        unsigned int RESERVED:30;
    } _docFlags;
}

+ (BOOL) isNativeType:(NSString *) type;
+ (NSArray *) readableTypes;
+ (NSArray *) writableTypes;

- (void) addWindowController:(NSWindowController *) windowController;
- (NSURL *) autosavedContentsFileURL;
- (void) autosaveDocumentWithDelegate:(id) delegate
				  didAutosaveSelector:(SEL) didAutosaveSelector
				   		  contextInfo:(void *) context;
- (NSString *) autosavingFileType;
- (void) canCloseDocumentWithDelegate:(id) delegate 
				  shouldCloseSelector:(SEL) shouldCloseSelector 
						  contextInfo:(void *) context;
- (void) close;
- (NSData *) dataOfType:(NSString *) type
				  error:(NSError **) error;
- (NSString *) displayName;
- (NSDictionary *) fileAttributesToWriteToURL:(NSURL *) url
									   ofType:(NSString *) type
							 forSaveOperation:(NSSaveOperationType) op
						  originalContentsURL:(NSURL *) original
									    error:(NSError **) error;
- (NSDate *) fileModificationDate;
- (NSString *) fileNameExtensionForType:(NSString *) type saveOperation:(NSSaveOperationType) savOp;
- (BOOL) fileNameExtensionWasHiddenInLastRunSavePanel;
- (NSString *) fileType;
- (NSString *) fileTypeFromLastRunSavePanel;
- (NSURL *) fileURL;
- (NSFileWrapper *) fileWrapperOfType:(NSString *) type
							    error:(NSError **) error;
- (BOOL) hasUnautosavedChanges;
- (BOOL) hasUndoManager;
- (id) init;
- (id) initForURL:(NSURL *) forUrl
withContentsOfURL:(NSURL *) url
		   ofType:(NSString *) type
		    error:(NSError **) error;
- (id) initWithContentsOfURL:(NSURL *) url
					  ofType:(NSString *) type
					   error:(NSError **) error;
- (id) initWithType:(NSString *) type
			  error:(NSError **) error;
- (BOOL) isDocumentEdited;
- (BOOL) keepBackupFile;
- (NSString *) lastComponentOfFileName;
- (void) makeWindowControllers;  // Manual creation
- (BOOL) preparePageLayout:(NSPageLayout *) pageLayout;
- (BOOL) prepareSavePanel:(NSSavePanel *) savePanel;
- (BOOL) presentError:(NSError *) error;
- (void) presentError:(NSError *) error
	   modalForWindow:(NSWindow *) window
			 delegate:(id) delegate
   didPresentSelector:(SEL) sel
		  contextInfo:(void *) context;
- (IBAction) printDocument:(id) sender;
- (void) printDocumentWithSettings:(NSDictionary *) settings
				    showPrintPanel:(BOOL) flag
						  delegate:(id) delegate
				  didPrintSelector:(SEL) sel
					   contextInfo:(void *) context;
- (NSPrintInfo *) printInfo;
- (NSPrintOperation *) printOperationWithSettings:(NSDictionary *) settings
										    error:(NSError **) error;
- (void) printShowingPrintPanel:(BOOL) flag;
- (BOOL) readFromData:(NSData *) data
			   ofType:(NSString *) type
			    error:(NSError **) error;
- (BOOL) readFromFileWrapper:(NSFileWrapper *) wrapper
					  ofType:(NSString *) type
					   error:(NSError **) error;
- (BOOL) readFromURL:(NSURL *) url
			  ofType:(NSString *) type
			   error:(NSError **) error;
- (void) removeWindowController:(NSWindowController *) windowController;
- (IBAction) revertDocumentToSaved:(id) sender;
- (BOOL) revertToContentsOfURL:(NSURL *) url
					    ofType:(NSString *) type
						 error:(NSError **) error;
- (void) runModalPageLayoutWithPrintInfo:(NSPrintInfo *) info
							    delegate:(id) delegate
						  didRunSelector:(SEL) sel
							 contextInfo:(void *) context;
- (void) runModalPrintOperation:(NSPrintOperation *) op
					   delegate:(id) delegate
				 didRunSelector:(SEL) sel
				    contextInfo:(void *) context;
- (void) runModalSavePanelForSaveOperation:(NSSaveOperationType) op 
								  delegate:(id) delegate
						   didSaveSelector:(SEL) sel 
							   contextInfo:(void *) context;
- (IBAction) runPageLayout:(id) sender;
- (IBAction) saveDocument:(id) sender;
- (IBAction) saveDocumentAs:(id) sender;
- (IBAction) saveDocumentTo:(id) sender;
- (void) saveDocumentWithDelegate:(id) delegate 
				  didSaveSelector:(SEL) sel 
					  contextInfo:(void *) context;
- (void) saveToURL:(NSURL *) url 
		    ofType:(NSString *) type
	 saveOperation:(NSSaveOperationType) op 
		  delegate:(id) delegate
   didSaveSelector:(SEL) sel 
	   contextInfo:(void *) context;
- (BOOL) saveToURL:(NSURL *) url
		    ofType:(NSString *) type
  forSaveOperation:(NSSaveOperationType) op
			 error:(NSError **) error;
- (void) setAutosavedContentsFileURL:(NSURL *) url;
- (void) setFileModificationDate:(NSDate *) date;
- (void) setFileType:(NSString *) type;
- (void) setFileURL:(NSURL *) url;
- (void) setHasUndoManager:(BOOL) flag;
- (void) setLastComponentOfFileName:(NSString *) str;
- (void) setPrintInfo:(NSPrintInfo *) printInfo;
- (void) setUndoManager:(NSUndoManager *) undoManager;
- (void) setWindow:(NSWindow *) aWindow;	// called when connecting the 'window' outlet to the window
- (BOOL) shouldChangePrintInfo:(NSPrintInfo *) newPrintInfo;
- (void) shouldCloseWindowController:(NSWindowController *) windowController 
						    delegate:(id) delegate 
				 shouldCloseSelector:(SEL) sel
						 contextInfo:(void *) context;
- (BOOL) shouldRunSavePanelWithAccessoryView;
- (void) showWindows;
- (NSUndoManager *) undoManager;
- (void) updateChangeCount:(NSDocumentChangeType) change;
- (BOOL) validateMenuItem:(NSMenuItem *) anItem;
- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>) anItem;
- (NSError *) willPresentError:(NSError *) error;
- (void) windowControllerDidLoadNib:(NSWindowController *) windowController;
- (NSArray *) windowControllers;
- (void) windowControllerWillLoadNib:(NSWindowController *) windowController;
- (NSWindow *) windowForSheet;
- (NSString *) windowNibName;    // Automatic creation (Document will be the nib owner)
- (NSArray *) writableTypesForSaveOperation:(NSSaveOperationType) op;
- (BOOL) writeSafelyToURL:(NSURL *) url
				   ofType:(NSString *) type
		 forSaveOperation:(NSSaveOperationType) op
				    error:(NSError **) error;
- (BOOL ) writeToURL:(NSURL *) url 
		 	  ofType:(NSString *) type 
			   error:(NSError **) error;
- (BOOL) writeToURL:(NSURL *) url
			 ofType:(NSString *) type
   forSaveOperation:(NSSaveOperationType) op
originalContentsURL:(NSURL *) orig
			  error:(NSError **) error;
- (BOOL)writeWithBackupToFile:(NSString *)fullPath 
					   ofType:(NSString *)type 
				saveOperation:(NSSaveOperationType)opType;

@end

@interface NSDocument (Deprecated)

- (BOOL) canCloseDocument;
- (NSData *) dataRepresentationOfType:(NSString *) type;
- (NSDictionary *) fileAttributesToWriteToFile: (NSString *) fullDocumentPath 
									    ofType: (NSString *) docType 
								 saveOperation: (NSSaveOperationType) saveOperationType;
- (NSString *) fileName;
- (NSString *) fileNameFromRunningSavePanelForSaveOperation:(NSSaveOperationType) saveOperation;
- (NSFileWrapper *) fileWrapperRepresentationOfType:(NSString *) type;
- (id) initWithContentsOfFile:(NSString *) fileName ofType:(NSString *) fileType;
- (id) initWithContentsOfURL:(NSURL *) url ofType:(NSString *) fileType;
- (BOOL) loadDataRepresentation:(NSData *) data ofType:(NSString *) type;
- (BOOL) loadFileWrapperRepresentation:(NSFileWrapper *) wrapper 
							    ofType:(NSString *) type;
- (BOOL) readFromFile:(NSString *) fileName ofType:(NSString *) type;
- (BOOL) readFromURL:(NSURL *) url ofType:(NSString *) type;
- (BOOL) revertToSavedFromFile:(NSString *) fileName ofType:(NSString *) type;
- (BOOL) revertToSavedFromURL:(NSURL *) url ofType:(NSString *) type;
- (int) runModalPageLayoutWithPrintInfo:(NSPrintInfo *) printInfo;
- (int) runModalSavePanel:(NSSavePanel *) savePanel withAccessoryView:(NSView *) accessoryView;
- (void) saveToFile:(NSString *) path 
      saveOperation:(NSSaveOperationType) op 
		   delegate:(id) delegate
    didSaveSelector:(SEL) sel 
        contextInfo:(void *) context;
- (void) setFileName:(NSString *) fileName;
- (BOOL) shouldCloseWindowController:(NSWindowController *) windowController;
- (BOOL) writeToFile:(NSString *) fileName ofType:(NSString *) type;
- (BOOL) writeToFile:(NSString *) path 
			  ofType:(NSString *) type 
        originalFile:(NSString *) orig
       saveOperation:(NSSaveOperationType) op;
- (BOOL) writeToURL:(NSURL *) url ofType:(NSString *) type;
- (BOOL) writeWithBackupToFile:(NSString *) fileName 
					    ofType:(NSString *) fileType 
				 saveOperation:(NSSaveOperationType) saveOp;

@end

#endif // _GNUstep_H_NSDocument
