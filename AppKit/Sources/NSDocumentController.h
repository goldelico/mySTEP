/* 
   NSDocumentController.h

   The document controller class

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Carl Lindberg <Carl.Lindberg@hbo.com>
   Date: 1999

   Author: H. N. Schaller <hns@computer.org>
   Date: Sept 2005 - adapted to 10.4 API

   Author: Fabian Spillner
   Date: 23. October

   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	7. November 2007 - aligned with 10.5
 
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

#ifndef _GNUstep_H_NSDocumentController
#define _GNUstep_H_NSDocumentController

#import <Foundation/Foundation.h>
#import <AppKit/NSNibDeclarations.h>
#import <AppKit/NSUserInterfaceValidation.h>

@class NSArray, NSMutableArray;
@class NSURL;
@class NSMenuItem, NSOpenPanel, NSWindow;
@class NSDocument;
@class NSError;

@interface NSDocumentController : NSObject
{
  @private
    NSMutableArray 	*_documents;
    NSMutableArray 	*_recentDocuments;
    struct __controllerFlags {
        unsigned int shouldCreateUI:1;
        unsigned int RESERVED:31;
    } _controllerFlags;
    NSArray		*_types;		// from info.plist with key NSTypes
	NSTimeInterval _autosavingDelay;
}

// new 10.4 interface

+ (id) sharedDocumentController;

- (void) addDocument:(NSDocument *) document;
- (NSTimeInterval) autosavingDelay;
- (IBAction) clearRecentDocuments:(id) sender;
- (void) closeAllDocumentsWithDelegate:(id) delegate
				   didCloseAllSelector:(SEL) sel
						   contextInfo:(void *) context;
- (NSString *) currentDirectory;
- (id) currentDocument;
- (NSString *) defaultType;
- (NSString *) displayNameForType:(NSString *) type;
- (Class) documentClassForType:(NSString *) name;
- (NSArray *) documentClassNames;
- (id) documentForURL:(NSURL *) url;
- (id) documentForWindow:(NSWindow *) window;
- (NSArray *) documents;
- (NSArray *) fileExtensionsFromType:(NSString *) type;
- (BOOL) hasEditedDocuments;
- (id) init;
- (id) makeDocumentForURL:(NSURL *) url
		withContentsOfURL:(NSURL *) contents
				   ofType:(NSString *) type
					error:(NSError **) err;	// most generic call
- (id) makeDocumentWithContentsOfURL:(NSURL *) url ofType:(NSString *) type error:(NSError **) err;
- (id) makeUntitledDocumentOfType:(NSString *) type error:(NSError **) err;
- (NSUInteger) maximumRecentDocumentCount;
- (IBAction) newDocument:(id) sender;
- (void) noteNewRecentDocument:(NSDocument *) doc;
- (void) noteNewRecentDocumentURL:(NSURL *) url;
- (IBAction) openDocument:(id) sender;
- (id) openDocumentWithContentsOfURL:(NSURL *) url
							 display:(BOOL) flag
							   error:(NSError **) err;
- (id) openUntitledDocumentAndDisplay:(BOOL) flag error:(NSError **) err;
- (BOOL) presentError:(NSError *) err;
- (void) presentError:(NSError *) err
	   modalForWindow:(NSWindow *) win
			 delegate:(id) delegate 
   didPresentSelector:(SEL) sel
		  contextInfo:(void *) context;
- (NSArray *) recentDocumentURLs;
- (void) removeDocument:(NSDocument *) document;
- (BOOL) reopenDocumentForURL:(NSURL *) url
			withContentsOfURL:(NSURL *) contents
						error:(NSError **) err;
- (void) reviewUnsavedDocumentsWithAlertTitle:(NSString *) title
								  cancellable:(BOOL) flag delegate:(id) delegate
						 didReviewAllSelector:(SEL) sel contextInfo:(void *) context;
- (NSInteger) runModalOpenPanel:(NSOpenPanel *) panel forTypes:(NSArray *) types;
- (IBAction) saveAllDocuments:(id) sender;
- (void) setAutosavingDelay:(NSTimeInterval) autosavingDelay;
- (NSString *) typeFromFileExtension:(NSString *) ext;
- (NSString *) typeForContentsOfURL:(NSURL *) url error:(NSError **) err;
- (NSArray *) URLsFromRunningOpenPanel;
- (BOOL) validateMenuItem:(NSMenuItem *) item;
- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>) item;
- (NSError *) willPresentError:(NSError *) err;

@end

@interface NSObject (NSDocumentController)

- (void) documentController:(NSDocumentController *) ctrl didCloseAll:(BOOL) flag contextInfo:(void *) context;
- (void) didPresentErrorWithRecovery:(BOOL) flag contextInfo:(void *) context;
- (void) documentController:(NSDocumentController *) ctrl didReviewAll:(BOOL) flag contextInfo:(void *) context;

@end

@interface NSDocumentController (Deprecated)

- (BOOL) closeAllDocuments;
- (id) documentForFileName: (NSString *) file;
- (NSArray *) fileNamesFromRunningOpenPanel;
- (id) makeDocumentWithContentsOfFile:(NSString *) file ofType:(NSString *) type;
- (id) makeDocumentWithContentsOfURL:(NSURL *) url ofType:(NSString *) type;
- (id) makeUntitledDocumentOfType:(NSString *) type;
- (id) openDocumentWithContentsOfFile:(NSString *) file display:(BOOL) flag;
- (id) openDocumentWithContentsOfURL:(NSURL *) url display:(BOOL) flag;
- (id) openUntitledDocumentOfType:(NSString *) type display:(BOOL) flag;
- (BOOL) reviewUnsavedDocumentsWithAlertTitle:(NSString *) title cancellable:(BOOL) flag;
- (void) setShouldCreateUI:(BOOL) flag;
- (BOOL) shouldCreateUI;

@end

#endif // _GNUstep_H_NSDocumentController

