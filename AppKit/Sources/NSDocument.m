/** <title>NSDocument</title>

<abstract>The abstract document class</abstract>

Copyright (C) 1999 Free Software Foundation, Inc.

Author: Carl Lindberg <Carl.Lindberg@hbo.com>
Date: 1999
Modifications: Fred Kiefer <FredKiefer@gmx.de>
Date: June 2000

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

#import <Foundation/Foundation.h>

#import <AppKit/NSDocument.h>
#import <AppKit/NSDocumentController.h>
#import <AppKit/NSWindowController.h>
#import <AppKit/NSFileWrapper.h>
#import <AppKit/NSSavePanel.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSPageLayout.h>
#import <AppKit/NSView.h>
#import <AppKit/NSPopUpButton.h>

#import "NSAppKitPrivate.h"

@implementation NSDocument

+ (NSArray *) readableTypes
{
	return [[NSDocumentController sharedDocumentController]
	   _editorAndViewerTypesForClass:self];
}

+ (NSArray *) writableTypes
{
	return [[NSDocumentController sharedDocumentController] _editorTypesForClass:self];
}

+ (BOOL) isNativeType:(NSString *)type
{
	return ([[self readableTypes] containsObject:type] &&
			[[self writableTypes] containsObject:type]);
}

- (id) init
{
	if((self=[super init]))
		{
		NSArray *wt;
		_windowControllers = [[NSMutableArray alloc] init];
		wt=[[self class] writableTypes];
		if([wt count])
			[self setFileType:[wt objectAtIndex: 0]];	// Set our default type
		}
	return self;
}

- (id) initWithContentsOfFile:(NSString *)fileName ofType:(NSString *)fileType
{
	DEPRECATED;
	return [self initWithContentsOfURL:[NSURL fileURLWithPath:fileName] ofType:fileType];
}

- (id) initWithContentsOfURL:(NSURL *)url ofType:(NSString *)fileType
{
	NSError *error;
#if 0
	NSLog(@"initWithContentsOfURL: %@", url);
#endif
	self=[self init];
	if([self readFromURL:url ofType:fileType error:&error])
		{
		[self setFileType:fileType];
		[self setFileName:[url path]];
		}
	else
		{
		NSRunAlertPanel(@"Load failed",
						@"Could not load %@.",
						nil, nil, nil, [url absoluteString]);
		[self release];
		return nil;
		}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_undoManager release];
	[_fileName release];
	[_fileType release];
	[_windowControllers release];
//	[_window release];
	[_printInfo release];
	[savePanelAccessory release];
	[spaButton release];
	[super dealloc];
}

- (NSString *) fileName
{
	return _fileName;
}

- (NSURL *) fileURL
{
	return NIMP;
}

- (void) setFileName:(NSString *)fileName
{
	ASSIGN(_fileName, fileName);
	
	[_windowControllers makeObjectsPerformSelector:
		@selector(synchronizeWindowTitleWithDocumentName)];
}

- (NSString *) fileType
{
	return _fileType;
}

- (void) setFileType:(NSString *)type
{
	ASSIGN(_fileType, type);
}

- (NSArray *) windowControllers
{
	return _windowControllers;
}

- (void) addWindowController:(NSWindowController *)windowController
{
#if 0
	NSLog(@"%@ addWindowController:%@ window=%@", self, windowController, _window);
#endif
	[_windowControllers addObject:windowController];
	if ([windowController document] != self)
		[windowController setDocument:self];
}

- (void) removeWindowController:(NSWindowController *)windowController
{
	if ([_windowControllers containsObject:windowController])
		{
		[windowController setDocument:nil];
		[_windowControllers removeObject:windowController];
		}
}

- (NSString *) windowNibName
{
	return nil;
}

- (void) setWindow:(NSWindow *)aWindow
{ // we do not retain the window, since it should already have a retain from the nib.
#if 0
	NSLog(@"%@ setWindow %@", self, aWindow);
#endif
	_window = aWindow;
}

- (void) makeWindowControllers
{
	NSString *name = [self windowNibName];
	
	if (name != nil && [name length] > 0)
		{
		NSWindowController *controller;
		controller = [[NSWindowController alloc] initWithWindowNibName:name owner:self];
		[self addWindowController:controller];
		[controller release];
		}
	else
		{
		[NSException raise:NSInternalInconsistencyException
					format:@"%@ must override either -windowNibName or -makeWindowControllers",
			NSStringFromClass([self class])];
		}
}

- (void) showWindows
{
#if 0
	NSLog(@"%@ showWindows", self);
#endif
	[_windowControllers makeObjectsPerformSelector:@selector(showWindow:) withObject:self];
}

- (BOOL) isDocumentEdited
{
	return _changeCount != 0;
}

- (void) updateChangeCount:(NSDocumentChangeType)change
{
	int i, count = [_windowControllers count];
	BOOL isEdited;
	
	switch (change)
		{
		case NSChangeDone:		_changeCount++; break;
		case NSChangeUndone:	_changeCount--; break;
		case NSChangeCleared:	_changeCount = 0; break;
		case NSChangeReadOtherContents:
		case NSChangeAutosaved:
			break;
		}
	
    /*
     * NOTE: Apple's implementation seems to not call -isDocumentEdited
     * here but directly checks to see if _changeCount == 0.  It seems it
     * would be better to call the method in case it's overridden by a
     * subclass, but we may want to keep Apple's behavior.
     */
	isEdited = [self isDocumentEdited];
	
	for (i=0; i<count; i++)
		{
		[[_windowControllers objectAtIndex: i] setDocumentEdited: isEdited];
		}
}

- (BOOL) canCloseDocument
{
	int result;
	
	if (![self isDocumentEdited])
		return YES;
	
	result = NSRunAlertPanel (@"Close", 
							  @"%@ has changed.  Save?",
							  @"Save", @"Cancel", @"Don't Save", 
							  [self displayName]);
	
#define Save     NSAlertDefaultReturn
#define Cancel   NSAlertAlternateReturn
#define DontSave NSAlertOtherReturn
	
	switch (result)
		{
		// return NO if save failed
		case Save:
			{
				[self saveDocument:nil]; 
				return ![self isDocumentEdited];
			}
		case DontSave:	return YES;
		case Cancel:
		default:		return NO;
		}
}

- (void) canCloseDocumentWithDelegate:(id)delegate 
				 shouldCloseSelector:(SEL)shouldCloseSelector 
						 contextInfo:(void *)contextInfo
{
	BOOL result = [self canCloseDocument];
	
	if (delegate != nil && shouldCloseSelector != NULL)
		{
		void (*meth)(id, SEL, id, BOOL, void*);
		meth = (void (*)(id, SEL, id, BOOL, void*))[delegate methodForSelector:shouldCloseSelector];
		if (meth)
			meth(delegate, shouldCloseSelector, self, result, contextInfo);
		}
}

- (BOOL) shouldCloseWindowController:(NSWindowController *)windowController
{
	if (![_windowControllers containsObject:windowController]) return YES;
	
	/* If it's the last window controller, pop up a warning */
	/* maybe we should count only loaded window controllers (or visible windows). */
	if ([windowController shouldCloseDocument]
		|| [_windowControllers count] == 1)
		{
		return [self canCloseDocument];
		}
	
	return YES;
}

- (void) shouldCloseWindowController:(NSWindowController *)windowController 
						   delegate:(id)delegate 
				shouldCloseSelector:(SEL)callback
						contextInfo:(void *)contextInfo
{
	BOOL result = [self shouldCloseWindowController: windowController];
	
	if (delegate != nil && callback != NULL)
		{
		void (*meth)(id, SEL, id, BOOL, void*);
		meth = (void (*)(id, SEL, id, BOOL, void*))[delegate methodForSelector:callback];
		if(meth)
			meth(delegate, callback, self, result, contextInfo);
		}
}

- (NSString *) displayName
{
	static unsigned int untitledCount = 1;
	if ([self fileName] != nil)
		return [[[self fileName] lastPathComponent] stringByDeletingPathExtension];
	if(!_documentIndex)
		_documentIndex = untitledCount++;	// assign a new number
	return [NSString stringWithFormat:@"Untitled-%u", _documentIndex];
}

- (BOOL) keepBackupFile
{
	return NO;
}

/* default implementations - all of them can be overridden */
// FIXME: make this a private category to group this low-level-file interface

- (BOOL) loadDataRepresentation:(NSData *)data ofType:(NSString *)type
{
	[NSException raise:NSInternalInconsistencyException format:@"%@ must implement %@",
	 NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
	return NO;
}

- (BOOL) loadFileWrapperRepresentation:(NSFileWrapper *)wrapper ofType:(NSString *)type
{
	if ([wrapper isRegularFile])
		return [self loadDataRepresentation:[wrapper regularFileContents] ofType:type];
	
    /*
     * This even happens on a symlink.  May want to use
     * -stringByResolvingAllSymlinksInPath somewhere, but Apple doesn't.
     */
	NSLog(@"Warning: %@ must be overridden if your document deals with file packages.", NSStringFromSelector(_cmd));
	return NO;
}

- (BOOL) readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **) error;
{
	return NO;
}

- (BOOL) readFromFile:(NSString *)fileName ofType:(NSString *)typeName error:(NSError **) error;
{ // default load - can/should be overwritten
	// FIXME: we loose error information that the readFromFileWrapper: could have provided
	if([self readFromFile:fileName ofType:typeName])
	   return YES;
	if(error)
		*error=[NSError errorWithDomain:@"NSDocument" code:0 userInfo:nil];
	return NO;
}

- (BOOL) readFromFile:(NSString *)fileName ofType:(NSString *)typeName
{ // default load - can/should be overwritten
	NSFileWrapper *wrapper;
	DEPRECATED;
	wrapper=[[[NSFileWrapper alloc] initWithPath:fileName] autorelease];
	if(!wrapper) return nil;	// outError has been set
	return [self readFromFileWrapper:wrapper ofType:typeName error:NULL];
}

#define isoverridden(A) YES

- (BOOL) readFromFileWrapper:(NSFileWrapper *) wrapper ofType:(NSString *) type error:(NSError **) error;
{
	if(isoverridden(@selector(loadFileWrapperRepresentation:ofType:)))
		return [self loadFileWrapperRepresentation:wrapper ofType:type];
	return [self readFromData:[wrapper regularFileContents] ofType:type error:error];
}

- (BOOL) readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{ // default load - can/should be overwritten
	NSFileWrapper *wrapper;
	if([absoluteURL isFileURL])
		return [self readFromFile:[absoluteURL path] ofType:typeName error:outError];
	wrapper=[[[NSFileWrapper alloc] initWithURL:absoluteURL options:0 error:outError] autorelease];
	if(!wrapper)
		return NO;	// outError has been set
	return [self readFromFileWrapper:wrapper ofType:typeName error:outError];		
}

- (BOOL) readFromURL:(NSURL *)absoluteURL ofType:(NSString *)type
{
	DEPRECATED;
	if(![absoluteURL isFileURL])
		return NO;	// supports file: URLs only
	return [self readFromFile:[absoluteURL path] ofType:type];
}

/* same for writing */

- (NSData *) dataRepresentationOfType:(NSString *)type
{
	[NSException raise:NSInternalInconsistencyException format:@"%@ must implement %@",
	 NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
	return nil;
}

- (NSFileWrapper *) fileWrapperRepresentationOfType:(NSString *)type
{
	NSData *data = [self dataRepresentationOfType:type];
	
	if (data == nil) 
		return nil;
	
	return [[[NSFileWrapper alloc] initRegularFileWithContents:data] autorelease];
}

- (BOOL) writeToFile:(NSString *)fileName ofType:(NSString *)type
{
	DEPRECATED;
	return [[self fileWrapperRepresentationOfType:type]
			writeToFile:fileName atomically:YES updateFilenames:YES];
}

- (BOOL) writeToURL:(NSURL *)url ofType:(NSString *)type
{
	NSData *data = [self dataRepresentationOfType:type];
	
	if (data == nil) 
		return NO;
	
	return [url setResourceData: data];
}

/* use the basic layer for reading/writing files */

- (BOOL) revertToSavedFromFile:(NSString *)fileName ofType:(NSString *)type
{
	return [self readFromFile:fileName ofType:type];
}

- (BOOL) revertToSavedFromURL:(NSURL *)url ofType:(NSString *)type
{
	return [self readFromURL: url ofType: type];
}

- (IBAction) changeSaveType:(id)sender
{ 
	//FIXME if we have accessory -- store the desired save type somewhere.
}

- (int) runModalSavePanel:(NSSavePanel *)savePanel 
       withAccessoryView:(NSView *)accessoryView
{
	[savePanel setAccessoryView:accessoryView];
	return [savePanel runModal];
}

- (BOOL) shouldRunSavePanelWithAccessoryView
{
	return YES;
}

#if 1	// do we really need that???

- (void) _loadPanelAccessoryNib
{
	// FIXME.  We need to load the pop-up button
}

- (void) _addItemsToSpaButtonFromArray:(NSArray *)types
{
	// FIXME.  Add types to popup.
}

#endif

- (NSString *) fileNameFromRunningSavePanelForSaveOperation:(NSSaveOperationType)saveOperation
{
	NSView *accessory = nil;
	NSString *title;
	NSString *directory;
	NSArray *extensions;
	NSDocumentController *controller;
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	
	controller = [NSDocumentController sharedDocumentController];
	extensions = [controller fileExtensionsFromType:[self fileType]];
	
	if ([self shouldRunSavePanelWithAccessoryView])
		{
		if (savePanelAccessory == nil)
			[self _loadPanelAccessoryNib];
		
		[self _addItemsToSpaButtonFromArray:extensions];
		
		accessory = savePanelAccessory;
		}
	
	if ([extensions count] > 0)
		[savePanel setRequiredFileType:[extensions objectAtIndex:0]];
	
	switch (saveOperation)
		{
		case NSSaveAsOperation: title = @"Save As"; break;
		case NSSaveToOperation: title = @"Save To"; break; 
		case NSSaveOperation: 
		default:
			title = @"Save";    
			break;
		}
	
	[savePanel setTitle:title];
	
	
	if ([self fileName])
		directory = [[self fileName] stringByDeletingLastPathComponent];
	else
		directory = [controller currentDirectory];
	[savePanel setDirectory: directory];
	
	if ([self runModalSavePanel:savePanel withAccessoryView:accessory])
		{
		return [savePanel filename];
		}
	
	return nil;
}

- (BOOL) shouldChangePrintInfo:(NSPrintInfo *)newPrintInfo
{
	return YES;
}

- (NSPrintInfo *) printInfo
{
	return _printInfo? _printInfo : [NSPrintInfo sharedPrintInfo];
}

- (void) setPrintInfo:(NSPrintInfo *)printInfo
{
	ASSIGN(_printInfo, printInfo);
}


// Page layout panel (Page Setup)

- (int) runModalPageLayoutWithPrintInfo:(NSPrintInfo *)printInfo
{
	return [[NSPageLayout pageLayout] runModalWithPrintInfo:printInfo];
}

- (IBAction) runPageLayout:(id)sender
{
	NSPrintInfo *printInfo = [self printInfo];
	
	if ([self runModalPageLayoutWithPrintInfo:printInfo]
		&& [self shouldChangePrintInfo:printInfo])
		{
		[self setPrintInfo:printInfo];
		[self updateChangeCount:NSChangeDone];
		}
}

/* This is overridden by subclassers; the default implementation does nothing. */
- (void)printShowingPrintPanel:(BOOL)flag
{
}

- (IBAction) printDocument:(id)sender
{
	[self printShowingPrintPanel:YES];
}

- (BOOL) validateMenuItem:(NSMenuItem *)anItem
{
	if ([anItem action] == @selector(revertDocumentToSaved:))
		return ([self fileName] != nil && [self isDocumentEdited]);
	
	// FIXME should validate spa popup items; return YES if it's a native type.
    
	return YES;
}

- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	if ([anItem action] == @selector(revertDocumentToSaved:))
		return ([self fileName] != nil);
	
	return YES;
}

- (NSString *) fileTypeFromLastRunSavePanel
{
	// FIXME this should return type picked on save accessory
	// return [spaPopupButton title];
	return [self fileType];
}

- (NSDictionary *) fileAttributesToWriteToFile: (NSString *)fullDocumentPath 
									   ofType: (NSString *)docType 
								saveOperation: (NSSaveOperationType)saveOperationType
{
	// FIXME: Implement.
	return [NSDictionary dictionary];
}

- (BOOL) writeToFile:(NSString *)fileName 
			 ofType:(NSString *)type 
       originalFile:(NSString *)origFileName
      saveOperation:(NSSaveOperationType)saveOp
{
	return [self writeToFile: fileName ofType: type];
}

- (BOOL) writeWithBackupToFile:(NSString *)fileName 
					   ofType:(NSString *)fileType 
				saveOperation:(NSSaveOperationType)saveOp
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *backupFilename = nil;
	
	if (fileName)
		{
		if ([fileManager fileExistsAtPath:fileName])
			{
			NSString *extension  = [fileName pathExtension];
			
			backupFilename = [fileName stringByDeletingPathExtension];
			backupFilename = [backupFilename stringByAppendingString:@"~"];
			backupFilename = [backupFilename stringByAppendingPathExtension:extension];
			
			/* Save panel has already asked if the user wants to replace it */
			
			/* NSFileManager movePath: will fail if destination exists */
			if ([fileManager fileExistsAtPath:backupFilename])
				[fileManager removeFileAtPath:backupFilename handler:nil];
			
			// Move or copy?
			if (![fileManager movePath:fileName toPath:backupFilename handler:nil] &&
				[self keepBackupFile])
				{
				int result = NSRunAlertPanel(@"File Error",
											 @"Can't create backup file.  Save anyways?",
											 @"Save", @"Cancel", nil);
				
				if (result != NSAlertDefaultReturn) return NO;
				}
			}
		if ([self writeToFile: fileName 
					   ofType: fileType
				 originalFile: backupFilename
				saveOperation: saveOp])
			{
			if (saveOp != NSSaveToOperation)
				{
				[self setFileName:fileName];
				[self setFileType: fileType];
				[self updateChangeCount:NSChangeCleared];
				}
			
			if (backupFilename && ![self keepBackupFile])
				{
				[fileManager removeFileAtPath:backupFilename handler:nil];
				}
			
			return YES;
			}
		}
	
	return NO;
}

- (IBAction) saveDocument:(id)sender
{
	NSString *filename = [self fileName];
	
	if (filename == nil)
		{
		[self saveDocumentAs: sender];
		return;
		}
	
	[self writeWithBackupToFile: filename 
						 ofType: [self fileType]
				  saveOperation: NSSaveOperation];
}

- (IBAction) saveDocumentAs:(id)sender
{
	NSString *filename = 
	[self fileNameFromRunningSavePanelForSaveOperation: 
		NSSaveAsOperation];
	
	[self writeWithBackupToFile: filename 
						 ofType: [self fileTypeFromLastRunSavePanel]
				  saveOperation: NSSaveAsOperation];
}

- (IBAction) saveDocumentTo:(id)sender
{
	NSString *filename = 
	[self fileNameFromRunningSavePanelForSaveOperation: 
		NSSaveToOperation];
	
	[self writeWithBackupToFile: filename 
						 ofType: [self fileTypeFromLastRunSavePanel]
				  saveOperation: NSSaveToOperation];
}

- (void) saveDocumentWithDelegate:(id)delegate 
				 didSaveSelector:(SEL)didSaveSelector 
					 contextInfo:(void *)contextInfo
{
	// FIXME
	NIMP;
}

- (void) saveToFile:(NSString *)fileName 
     saveOperation:(NSSaveOperationType)saveOperation 
		  delegate:(id)delegate
   didSaveSelector:(SEL)didSaveSelector 
       contextInfo:(void *)contextInfo
{
	// FIXME
	NIMP;
}

- (BOOL) prepareSavePanel:(NSSavePanel *)savePanel
{
	return YES;
}

- (void) runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation 
								 delegate:(id)delegate
						  didSaveSelector:(SEL)didSaveSelector 
							  contextInfo:(void *)contextInfo
{
	// FIXME
	NIMP;
}

- (IBAction) revertDocumentToSaved:(id)sender
{
	int result;
	
	result = NSRunAlertPanel 
		(@"Revert",
		 @"%@ has been edited.  Are you sure you want to undo changes?",
		 @"Revert", @"Cancel", nil, 
		 [self displayName]);
	
	if (result == NSAlertDefaultReturn &&
		[self revertToSavedFromFile:[self fileName] ofType:[self fileType]])
		{
		[self updateChangeCount:NSChangeCleared];
		}
}

/** Closes all the windows owned by the document, then removes itself
from the list of documents known by the NSDocumentController. This
method does not ask the user if they want to save the document before
closing. It is closed without saving any information.
*/
- (void) close
{
	if (_docFlags.inClose == NO)
		{
		int count = [_windowControllers count];
		/* Closing a windowController will also send us a close, so make
		sure we don't go recursive */
		_docFlags.inClose = YES;
		
		if (count > 0)
			{
			NSWindowController *array[count];
			[_windowControllers getObjects: array];
			while (count-- > 0)
				[array[count] close];
			}
		[[NSDocumentController sharedDocumentController] removeDocument:self];
		}
}

- (void) windowControllerWillLoadNib:(NSWindowController *)windowController { return; }
- (void) windowControllerDidLoadNib:(NSWindowController *)windowController  { return; }

- (NSUndoManager *) undoManager
{
	if (_undoManager == nil && [self hasUndoManager])
		{
		[self setUndoManager: [[[NSUndoManager alloc] init] autorelease]];
		}
	
	return _undoManager;
}

- (void) setUndoManager:(NSUndoManager *)undoManager
{
	if (undoManager != _undoManager)
		{
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		
		if (_undoManager)
			{
			[center removeObserver:self
							  name:NSUndoManagerWillCloseUndoGroupNotification
							object:_undoManager];
			[center removeObserver:self
							  name:NSUndoManagerDidUndoChangeNotification
							object:_undoManager];
			[center removeObserver:self
							  name:NSUndoManagerDidRedoChangeNotification
							object:_undoManager];
			}
		
		ASSIGN(_undoManager, undoManager);
		
		if (_undoManager == nil)
			{
			[self setHasUndoManager:NO];
			}
		else
			{
			[center addObserver:self
					   selector:@selector(_changeWasDone:)
						   name:NSUndoManagerWillCloseUndoGroupNotification
						 object:_undoManager];
			[center addObserver:self
					   selector:@selector(_changeWasUndone:)
						   name:NSUndoManagerDidUndoChangeNotification
						 object:_undoManager];
			[[NSNotificationCenter defaultCenter]
	    addObserver:self
		   selector:@selector(_changeWasRedone:)
			   name:NSUndoManagerDidRedoChangeNotification
			 object:_undoManager];
			}
		}
}

- (BOOL) hasUndoManager
{
	return _docFlags.hasUndoManager;
}

- (void) setHasUndoManager:(BOOL)flag
{
	if (_undoManager && !flag)
		[self setUndoManager:nil];
	
	_docFlags.hasUndoManager = flag;
}
@end

@implementation NSDocument (NSPrivate)

- (NSWindow *) _window;
{
	return _window;
}

- (void) _removeWindowController:(NSWindowController *)windowController
{
	if ([_windowControllers containsObject:windowController])
		{
		BOOL autoClose = [windowController shouldCloseDocument];
		
		[windowController setDocument:nil];
		[_windowControllers removeObject:windowController];
		
		if (autoClose || [_windowControllers count] == 0)
			{
			[self close];
			}
		}
}

- (void) _changeWasDone:(NSNotification *)notification
{
	[self updateChangeCount:NSChangeDone];
}

- (void) _changeWasUndone:(NSNotification *)notification
{
	[self updateChangeCount:NSChangeUndone];
}

- (void) _changeWasRedone:(NSNotification *)notification
{
	[self updateChangeCount:NSChangeDone];
}

@end
