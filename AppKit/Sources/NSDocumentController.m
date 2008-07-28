/** <title>NSDocumentController</title>

<abstract>The document controller class</abstract>

Copyright (C) 1999 Free Software Foundation, Inc.

Author: Carl Lindberg <Carl.Lindberg@hbo.com>
Date: 1999
Modifications: Fred Kiefer <FredKiefer@gmx.de>
Date: June 2000
Modifications: H. N. Schaller <hns@computer.org>
Date: Sept 2005 - adapted to 10.4 API

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

#import <AppKit/NSDocumentController.h>
#import <AppKit/NSDocument.h>
#import <AppKit/NSOpenPanel.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSWorkspace.h>
#import <AppKit/NSWindowController.h>
#import <Foundation/Foundation.h>

// #define OPENSTEP_ONLY   // include application:openFile: etc.

#import "NSAppKitPrivate.h"

// changed to conform to MacOS X 10.4 Info.plist

static NSString *NSTypesKey             = @"CFBundleDocumentTypes";
static NSString *NSNameKey              = @"CFBundleTypeName";
static NSString *NSRoleKey              = @"CFBundleTypeRole";
static NSString *NSEditorRole			= @"Editor";
static NSString *NSViewerRole			= @"Viewer";
static NSString *NSNoRole				= @"None";
static NSString *NSShellRole			= @"Shell";
static NSString *NSHumanReadableNameKey = @"NSHumanReadableName";
static NSString *NSUnixExtensionsKey    = @"CFBundleTypeExtensions";
static NSString *NSDOSExtensionsKey     = @"CFBundleTypeDOSExtensions";	// not standard by MacOS X
																		//static NSString *NSMacOSTypesKey        = @"CFBundleTypeOSTypes";
																		//static NSString *NSMIMETypesKey         = @"CFBundleTypeMIMETypes";
static NSString *NSDocumentClassKey     = @"NSDocumentClass";

static NSString *NSRecentDocuments      = @"NSRecentDocumentRecords";			// key into UserDefaults
static NSString *NSDefaultOpenDirectory = @"NSDefaultOpenDirectory";

static NSDocumentController *sharedController = nil;

#define TYPE_INFO(name) TypeInfoForName(_types, name)

static NSDictionary *TypeInfoForName(NSArray *types, NSString *typeName)
{
	NSEnumerator *e=[types objectEnumerator];
	NSDictionary *dict;
#if 0
	NSLog(@"TypeInfoForName %@", typeName);
#endif
	if(!typeName)
		return nil;
	while((dict = [e nextObject]))
		{
		if([[dict objectForKey:NSNameKey] isEqualToString:typeName])
			return dict;
		}
#if 0
	NSLog(@"not found in %@", types);
#endif
	return nil;
}

/** <p>
NSDocumentController is a class that controls a set of NSDocuments
for an application. As an application delegate, it responds to the
typical File Menu commands for opening and creating new documents,
and making sure all documents have been saved when an application
quits. It also registers itself for the
NSWorkspaceWillPowerOffNotification.  Note that
NSDocumentController isn't truly the application delegate, but it
works in a similar way. You can still have your own application
delegate - but beware, if it responds to the same methods as
NSDocumentController, your delegate methods will get called, not
the NSDocumentController's.
</p>
<p>
NSDocumentController also manages document types and the related
NSDocument subclasses that handle them. This information comes
from the custom info property list ({ApplicationName}Info.plist)
loaded when NSDocumentController is initialized. The property list
contains an array of dictionarys with the key NSTypes. Each
dictionary contains a set of keys:
</p>
<list>
<item>NSDocumentClass - The name of the subclass</item>
<item>NSName - Short name of the document type</item>
<item>NSHumanReadableName - Longer document type name</item> 
<item>NSUnixExtensions - Array of strings</item> 
<item>NSDOSExtensions - Array of strings</item>
<item>NSIcon - Icon name for these documents</item>
<item>NSRole - Viewer or Editor</item>
</list>
<p>
You can use NSDocumentController to get a list of all open
documents, the current document (The one whose window is Key) and
other information about these documents. It also remembers the most 
recently opened documents (through the user default key
						   NSRecentDocuments). .
</p>
<p>
You can subclass NSDocumentController to customize the behavior of
certain aspects of the class, but it is very rare that you would
need to do this.
</p>
*/
@implementation NSDocumentController

/** Returns the shared instance of the document controller class. You
should always use this method to get the NSDocumentController. */

+ (id) sharedDocumentController
{
	if (sharedController == nil)
		sharedController = [[self alloc] init];
	return sharedController;
}

- (BOOL) _isDocumentBased;
{ // application is document based if there is at least one type
	return [_types count] > 0;
}

- (void) _setOpenRecentMenu:(NSMenu *) menu;
{
	NSLog(@"should _setOpenRecentMenu from NIB file: %@", menu);
}

- (BOOL) _application:(in NSApplication *) app openURLs:(in bycopy NSArray *) urls withOptions:(in bycopy NSWorkspaceLaunchOptions) opts;	// handle open
{ // process application open requests
	NSEnumerator *e=[urls objectEnumerator];
	NSURL *url;
	BOOL any=NO;
#if 0
	NSLog(@"NSDocumentController openURLs: %@", urls);
#endif
	if(![self _isDocumentBased])
		{
#if 1
		NSLog(@"NSDocumentController: Application is not document based");
#endif
		return NO;
		}
	// FIXME: if there is already a window open, ignore (!)
	// and, call [[NSApp delegate] applicationShouldOpenUntitledFile:NSApp] if it is implemented
	if([urls count] == 0)
		{ // if we have no objects but at least one type for editing, open an untitled document
		NSString *type=[self defaultType];
		if(type)
			return [self openUntitledDocumentOfType:type display:YES] != nil;
		}
	while((url=[e nextObject]))
		{
		id doc;
		// handle untitled, make depending on launch options
		// handle display/noUI
		// display if not print
		// if there is no default type or we can't handle the type, return NO;
			// [self openUntitledDocumentOfType: [self _defaultType] display:YES]
		if([url isFileURL])
			doc=[self openDocumentWithContentsOfFile:[url path] display:YES];
		else			
			doc=[self openDocumentWithContentsOfURL:url display:YES];
		if(doc)
			any=YES;
		if(opts&NSWorkspaceLaunchAndPrint)
			[doc printDocument:nil];	// trigger printing
		}
	return any;
}

- (BOOL) _applicationShouldTerminate: (NSApplication *)sender
{
	if(![self _isDocumentBased])
		return YES;	// agree with anybody else
	return [self reviewUnsavedDocumentsWithAlertTitle: @"Quit" cancellable: YES];
}

// to disable this menu: don't use the openDocument: action for Open... menu item or connect to AppController
// should be handled by making us the delegate of the recent's menu

- (void) _updateOpenRecentMenu;
{ // update MainMenu
	NSMenu *recentMenu;
	NSMenu *fileMenu;
	int openMenu;
	int i;
	if(![self _isDocumentBased])
		return;	// no menu to update
	if([[NSApp mainMenu] numberOfItems] < 2)
		{ // this may be called if the menu has not yet been connected
#if 0
		NSLog(@"_updateOpenRecentMenu: invalid mainMenu %@ (has lesss than 2 items)", [[NSApp mainMenu] _longDescription]);
#endif
		return;
		}
	fileMenu=[[[NSApp mainMenu] itemAtIndex:1] submenu];	// extract the 'File' menu
	openMenu=[fileMenu indexOfItemWithTarget:nil andAction:@selector(openDocument:)];	// should be connected to FirstResponder
#if 0
	NSLog(@"openMenu = %d in %@", openMenu, fileMenu);
#endif
	if(openMenu < 0)
		{ // this may be called if the menu has not yet been connected
#if 0
		NSLog(@"no Open... menu item found in %@", fileMenu);
#endif
		return;	// there is no Open... menu item
		}
	recentMenu=[[fileMenu itemAtIndex:openMenu+1] submenu];	// get next item behind Open
	if(!recentMenu)
		{ // create a fresh Open Recent submenu
		NSMenuItem *newItem=[[[NSMenuItem alloc] initWithTitle:@"Open Recent" action:NULL keyEquivalent:nil] autorelease];	// might copy keyword "Open" from openMenu item
		recentMenu=[[[NSMenu alloc] initWithTitle:@"Open Recent"] autorelease];		// create fresh submenu
		[newItem setSubmenu:recentMenu];
		[fileMenu insertItem:newItem atIndex:openMenu+1];	// insert behind Open menu item
		}
	[recentMenu setAutoenablesItems:NO];	// don't update (so to keep Clear List status consistent)
	[recentMenu setMenuChangedMessagesEnabled:NO];
	while([recentMenu numberOfItems] > 0)
		[recentMenu removeItemAtIndex:0];	// remove them all
	for(i=[_recentDocuments count]; --i >= -2; )
		{ // add all items incl. a Clear List item if needed
		NSMenuItem *item;
		if(i == -1)
			{
			if([_recentDocuments count] == 0)
				continue;	// skip if menu is empty
			item=(NSMenuItem *) [NSMenuItem separatorItem];
			[item retain];	// will release...
			}
		else if(i == -2)
			{
			item=[[NSMenuItem alloc] initWithTitle:@"Clear List" action:@selector(clearRecentDocuments:) keyEquivalent:nil];
			[item setEnabled:[_recentDocuments count] > 0];	// disable for empty list
			}
		else
			{ // standard item
			NSURL *u=[_recentDocuments objectAtIndex:i];	// get URL
			if([u isFileURL])
				item=[[NSMenuItem alloc] initWithTitle:[[u path] lastPathComponent] action:@selector(_openRecentDocument:) keyEquivalent:nil];
			else
				item=[[NSMenuItem alloc] initWithTitle:[u relativeString] action:@selector(_openRecentDocument:) keyEquivalent:nil];
			[item setTag:i];
			}
		[item setTarget:self];
		[recentMenu addItem:item];
		[item release];
		}
	[recentMenu setMenuChangedMessagesEnabled:YES];
}

- (IBAction) _openRecentDocument:(id) Sender;
{ // action to open recent document by tag index
	int idx=[Sender tag];
	NSURL *doc;
	if(idx < 0 || idx >= [_recentDocuments count])
		{ // something went wrong
		[self _updateOpenRecentMenu];
		return;	// but ignore
		}
	doc=[_recentDocuments objectAtIndex:idx];
	NSLog(@"open %@", doc);
	[NSApp _application:NSApp openURLs:[NSArray arrayWithObject:doc] withOptions:0];
}

/** </init>Initializes the document controller class. The first
instance of a document controller class that gets initialized
becomes the shared instance.
*/

- (id) init
{
	NSDictionary *customDict = [[NSBundle mainBundle] infoDictionary];
	
	if((self=[super init]))
		{
		ASSIGN (_types, [customDict objectForKey: NSTypesKey]);
#if 0
		NSLog(@"types=%@", _types);
#endif
		// FIXME: check for valid types: 'Editor', 'Viewer', 'None', or 'Shell'
		_documents = [[NSMutableArray alloc] init];
		_controllerFlags.shouldCreateUI = YES;
		
		/* Get list of recent documents */
		_recentDocuments = [[NSUserDefaults standardUserDefaults] objectForKey: NSRecentDocuments];
		if (_recentDocuments)
			{
			int i, count;
			_recentDocuments = [_recentDocuments mutableCopy];
			count = [_recentDocuments count];
			for (i = 0; i < count; i++)
				{ // make NSURL from strings stored in the NSUserDefaults
				NSURL *url;
				url = [NSURL URLWithString: [_recentDocuments objectAtIndex: i]];
				[_recentDocuments replaceObjectAtIndex: i withObject: url];
				}
			}
		else
			_recentDocuments = [[NSMutableArray alloc] init];
		
		[[[NSWorkspace sharedWorkspace] notificationCenter]
				 addObserver: self
					selector: @selector(_workspaceWillPowerOff:)
						name: NSWorkspaceWillPowerOffNotification
					  object: nil];
		
		// FIXME: register for applicationWillTerminate

		NSLog(@"[NSDocumentController init] => %@", self);
		}
	return self;
}

- (void) dealloc
{
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self];
	[_documents release];
	[_recentDocuments release];
	[_types release];
	[super dealloc];
}

- (BOOL) shouldCreateUI
{
	DEPRECATED;
	return _controllerFlags.shouldCreateUI;
}

- (void) setShouldCreateUI:(BOOL) flag
{
	DEPRECATED;
	_controllerFlags.shouldCreateUI = flag;
}

- (id) makeUntitledDocumentOfType: (NSString *)type
{
	Class documentClass = [self documentClassForType:type];
	DEPRECATED;
	return [[[documentClass alloc] init] autorelease];
}

- (id) makeDocumentWithContentsOfFile:(NSString *) fileName 
							   ofType:(NSString *) type
{
	Class documentClass = [self documentClassForType:type];
	DEPRECATED;
#if 0
	if(!documentClass) NSLog(@"no document class defined for type %@", type);
#endif
	return [[[documentClass alloc] initWithContentsOfFile:fileName ofType:type] autorelease];
}

- (id) makeDocumentWithContentsOfURL: (NSURL *)url ofType: (NSString *)type
{
	Class documentClass = [self documentClassForType:type];
	DEPRECATED;
#if 0
	if(!documentClass) NSLog(@"no document class defined for type %@", type);
#endif
	return [[[documentClass alloc] initWithContentsOfURL:url ofType:type] autorelease];
}

- (NSString *) defaultType
{ // return first type of role "Editor" - if any
	int i, count = [_types count];
	for (i = 0; i < count; i++)
		{
		NSDictionary *typeInfo = [_types objectAtIndex: i];		
		if([[typeInfo objectForKey: NSRoleKey] isEqual: NSEditorRole])
			return [typeInfo objectForKey: NSNameKey];	// first one that is found
		}
	return nil;	// none found
}

- (void) addDocument: (NSDocument *)document
{
	[_documents addObject: document];
}

- (void) removeDocument: (NSDocument *)document
{
	[_documents removeObject: document];
}

- (id) openUntitledDocumentOfType: (NSString*)type  display: (BOOL)display
{
	NSDocument *document = [self makeUntitledDocumentOfType: type];
	DEPRECATED;
	
	if (document == nil) 
		{
		return nil;
		}
	
	[self addDocument:document];
	if ([self shouldCreateUI])
		{
		[document makeWindowControllers];
		if(display)
			[document showWindows];
		}
	
	return document;
}

- (id) openDocumentWithContentsOfFile: (NSString *)fileName 
							  display: (BOOL)display
{
	NSDocument *document = [self documentForFileName: fileName];
	DEPRECATED;
	
	if (document == nil)
		{
		NSString *type = [self typeFromFileExtension: [fileName pathExtension]];
		
		if ((document = [self makeDocumentWithContentsOfFile: fileName 
													  ofType: type]))
			{
			[self addDocument: document];
			}
		
		if ([self shouldCreateUI])
			{
			[document makeWindowControllers];
			}
		}
	
	// remember this document as opened
	[self noteNewRecentDocument: document];
	
	if (display && [self shouldCreateUI])
		{
		[document showWindows];
		}
	
	return document;
}

- (id) openDocumentWithContentsOfURL: (NSURL *)url  display: (BOOL)display
{
	NSDocument *document = [self documentForURL:url];
	DEPRECATED;
	
	if (document == nil)
		{
		NSError *err;
		NSString *type = [self typeForContentsOfURL:url error:&err];
		
		document = [self makeDocumentWithContentsOfURL: url ofType: type];
		
		if (document == nil)
			{
			return nil;
			}
		
		[self addDocument: document];
		
		if ([self shouldCreateUI])
			{
			[document makeWindowControllers];
			}
		}
	
	// remember this document as opened
	[self noteNewRecentDocumentURL: url];
	
	if (display && [self shouldCreateUI])
		{
		[document showWindows];
		}
	
	return document;
}

- (NSOpenPanel *) _setupOpenPanel
{
	NSOpenPanel *_openPanel = [NSOpenPanel openPanel];
	[_openPanel setDirectory: [self currentDirectory]];
	[_openPanel setAllowsMultipleSelection: YES];
	return _openPanel;
}

/** Invokes [NSOpenPanel -runModalForTypes:] with the NSOpenPanel
object openPanel, and passes the openableFileExtensions file types 
*/
- (int) runModalOpenPanel: (NSOpenPanel *)openPanel 
				 forTypes: (NSArray *)openableFileExtensions
{
	return [openPanel runModalForTypes:openableFileExtensions];
}

- (NSArray *) _openableFileExtensions
{
	int i, count = [_types count];
	NSMutableArray *array = [NSMutableArray arrayWithCapacity: count];
	
	for (i = 0; i < count; i++)
		{
		NSDictionary *typeInfo = [_types objectAtIndex: i];
		[array addObjectsFromArray: [typeInfo objectForKey: NSUnixExtensionsKey]];
		[array addObjectsFromArray: [typeInfo objectForKey: NSDOSExtensionsKey]];
		}
	
	return array;
}

/** Uses -runModalOpenPanel:forTypes: to allow the user to select
files to open (after initializing the NSOpenPanel). Returns the
list of files that the user has selected.
*/
- (NSArray *) fileNamesFromRunningOpenPanel
{
	NSArray *types = [self _openableFileExtensions];
	NSOpenPanel *openPanel = [self _setupOpenPanel];
	DEPRECATED;
	
	if ([self runModalOpenPanel: openPanel  forTypes: types])
		{
		return [openPanel filenames];
		}
	
	return nil;
}

/** Uses -runModalOpenPanel:forTypes: to allow the user to select
files to open (after initializing the NSOpenPanel). Returns the
list of files as URLs that the user has selected.
*/
- (NSArray *) URLsFromRunningOpenPanel
{
	NSArray *types = [self _openableFileExtensions];
	NSOpenPanel *openPanel = [self _setupOpenPanel];
	
	if ([self runModalOpenPanel: openPanel  forTypes: types])
		{
		return [openPanel URLs];
		}
	
	return nil;
}


- (IBAction) saveAllDocuments: (id)sender
{
	NSDocument *document;
	NSEnumerator *docEnum = [_documents objectEnumerator];
	
	while ((document = [docEnum nextObject]))
		{
		if ([document isDocumentEdited])  //maybe we should save regardless...
			{
			[document saveDocument: sender];
			}
		}
}


- (IBAction) openDocument: (id)sender
{
	NSEnumerator *fileEnum;
	NSString *filename;
	
	fileEnum = [[self fileNamesFromRunningOpenPanel] objectEnumerator];
	
	while ((filename = [fileEnum nextObject]))
		{
		[self openDocumentWithContentsOfFile: filename  display: YES];
		}
}

- (IBAction) newDocument: (id)sender
{
	[self openUntitledDocumentOfType: [self defaultType]  display: YES];
}


/** Iterates through all the open documents and asks each one in turn
if it can close using [NSDocument -canCloseDocument]. If the
document returns YES, then it is closed.
*/
- (BOOL) closeAllDocuments
{
	int count;
	DEPRECATED;
	count = [_documents count];
	if (count > 0)
		{
		NSDocument *array[count];
		[_documents getObjects: array];
		while (count-- > 0)
			{
			NSDocument *document = array[count];
			if (![document canCloseDocument]) 
				{
				return NO;
				}
			[document close];
			}
		}
	
	return YES;
}

- (void)closeAllDocumentsWithDelegate:(id)delegate 
				  didCloseAllSelector:(SEL)didAllCloseSelector 
						  contextInfo:(void *)contextInfo
{
	NIMP
	//FIXME
}

/** If there are any unsaved documents, this method displays an alert
panel asking if the user wants to review the unsaved documents. If
the user agrees to review the documents, this method calls
-closeAllDocuments to close each document (prompting to save a
										   document if it is dirty). If cancellable is YES, then the user is
    not allowed to cancel this request, otherwise this method will
    return NO if the user presses the Cancel button. Otherwise returns
    YES after all documents have been closed (or if there are no
											  unsaved documents.)
	*/
- (BOOL) reviewUnsavedDocumentsWithAlertTitle: (NSString *)title 
								  cancellable: (BOOL)cancellable
{
	NSString *cancelString = (cancellable)? @"Cancel" : nil;
	int      result;
	DEPRECATED;
	
	/* Probably as good a place as any to do this */
	[[NSUserDefaults standardUserDefaults] 
    setObject: [self currentDirectory] forKey: NSDefaultOpenDirectory];
	
	if (![self hasEditedDocuments]) 
		{
		return YES;
		}
	
	result = NSRunAlertPanel(title, @"You have unsaved documents",
							 @"Review Unsaved", 
							 cancelString, 
							 @"Quit Anyways");
	
#define ReviewUnsaved NSAlertDefaultReturn
#define Cancel        NSAlertAlternateReturn
#define QuitAnyways   NSAlertOtherReturn
	
	switch (result)
		{
		case ReviewUnsaved:	return [self closeAllDocuments];
		case QuitAnyways:	return YES;
		case Cancel:
		default:		return NO;
		}
}

- (void)reviewUnsavedDocumentsWithAlertTitle:(NSString *)title 
								 cancellable:(BOOL)cancellable 
									delegate:(id)delegate
						didReviewAllSelector:(SEL)didReviewAllSelector 
								 contextInfo:(void *)contextInfo
{
	// FIXME
	NIMP;
}

- (void) _workspaceWillPowerOff: (NSNotification *)notification
{
	[self reviewUnsavedDocumentsWithAlertTitle: @"Power Off" cancellable: NO];
}


/** Returns an array of all open documents */
- (NSArray *) documents
{
	return _documents;
}

/** Returns YES if any documents are "dirty", e.g. changes have been
made to the document that have not been saved to the disk 
*/
- (BOOL) hasEditedDocuments
{
	int i, count = [_documents count];
	
	for (i = 0; i < count; i++)
		{
		if ([[_documents objectAtIndex: i] isDocumentEdited])
			{
			return YES;
			}
		}
	
	return NO;
}

/** Returns the document whose window is the main window */
- (id) currentDocument
{
	return [self documentForWindow: 
		[[NSApplication sharedApplication] mainWindow]];
}

/** Returns the current directory. This method first checks if there
is a current document using the -currentDocument method. If this
returns a document and the document has a filename, this method
returns the directory this file is located in. Otherwise it
returns the directory of the most recently opened document or
the user's home directory if no document has been opened before.
*/
- (NSString *) currentDirectory
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSDocument *document = [self currentDocument];
	NSString *directory;
	BOOL isDir = NO;
	
	if (document == nil)
		document = [[self documents] lastObject];
	directory = [[document fileName] stringByDeletingLastPathComponent];
	if (directory == nil)
		directory = [[NSUserDefaults standardUserDefaults] 
		  objectForKey: NSDefaultOpenDirectory];
	if (directory == nil
		|| [manager fileExistsAtPath: directory  isDirectory: &isDir] == NO
		|| isDir == NO)
		{
		directory = NSHomeDirectory ();
		}
	return directory;
}

/** Returns the NSDocument class that controls window */
- (id) documentForWindow: (NSWindow *)window
{
	id document;
	
	if (window == nil)
		{
		return nil;
		}
	
	if (![[window windowController] isKindOfClass: [NSWindowController class]])
		{
		return nil;
		}
	
	document = [[window windowController] document];
	
	if (![document isKindOfClass:[NSDocument class]])
		{
		return nil;
		}
	
	return document;
}

/*
 * Returns the NSDocument class that controls the document with the name fileName.
 */

- (id) documentForURL: (NSURL *) url
{
	int i, count = [_documents count];
	for (i = 0; i < count; i++)
		{
		NSDocument *document = [_documents objectAtIndex: i];
		if ([[document fileURL] isEqual: url])
			return document;
		}
	return nil;
}

- (id) documentForFileName: (NSString *)fileName
{
	int i, count = [_documents count];
	DEPRECATED;
	for (i = 0; i < count; i++)
		{
		NSDocument *document = [_documents objectAtIndex: i];		
		if ([[document fileName] isEqualToString: fileName])
			{
			return document;
			}
		}
	return nil;
}

- (BOOL) validateMenuItem: (NSMenuItem *)anItem
{ // objc does not allow to == compare SEL with @selector()
	if ([NSStringFromSelector([anItem action]) isEqualToString:@"saveAllDocuments:"])
		{
		return [self hasEditedDocuments];
		}
	return YES;
}

- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	// FIXME
	return YES;
}

- (NSString *) displayNameForType: (NSString *)type
{
	NSString *name = [TYPE_INFO(type) objectForKey: NSHumanReadableNameKey];
	
	return name? name : type;
}

- (NSString *) typeFromFileExtension:(NSString *) fileExtension
{
	int i, count = [_types count];
#if 0
	NSLog(@"typeFromFileExtension:%@", fileExtension);
#endif
	for(i = 0; i < count; i++)
		{ // check for specific
		NSDictionary *typeInfo = [_types objectAtIndex:i];
		if([[typeInfo objectForKey:NSUnixExtensionsKey] containsObject:fileExtension] ||
		   [[typeInfo objectForKey:NSDOSExtensionsKey] containsObject:fileExtension])
			return [typeInfo objectForKey:NSNameKey];
		}
	for(i = 0; i < count; i++)
		{ // check for any
		NSDictionary *typeInfo = [_types objectAtIndex:i];
		if([[typeInfo objectForKey:NSUnixExtensionsKey] containsObject:@"*"])
			return [typeInfo objectForKey:NSNameKey];
		}
	return nil;
}

- (NSString *) typeForContentsOfURL:(NSURL *) url error:(NSError **) error;
{
	// open connection and get response
	// to determine mine/type
	return [self typeFromFileExtension:[[url path] pathExtension]];
}

- (NSArray *) fileExtensionsFromType: (NSString *)type
{
	NSDictionary *typeInfo = TYPE_INFO(type);
	NSArray *unixExtensions = [typeInfo objectForKey: NSUnixExtensionsKey];
	NSArray *dosExtensions  = [typeInfo objectForKey: NSDOSExtensionsKey];
	
	if (!dosExtensions)  return unixExtensions;
	if (!unixExtensions) return dosExtensions;
	return [unixExtensions arrayByAddingObjectsFromArray: dosExtensions];
}

- (Class) documentClassForType: (NSString *)type
{
	NSString *className = [TYPE_INFO(type) objectForKey:NSDocumentClassKey];
	return className?NSClassFromString(className) : Nil;
}

- (IBAction) clearRecentDocuments: (id)sender
{
	[_recentDocuments removeAllObjects];
	[[NSUserDefaults standardUserDefaults] setObject: _recentDocuments forKey: NSRecentDocuments];
	[self _updateOpenRecentMenu];
}

- (void) noteNewRecentDocument: (NSDocument *)aDocument
{
	NSString *fileName = [aDocument fileName];
	NSURL *anURL = [NSURL fileURLWithPath: fileName];
	NSLog(@"noteNewRecentDocument:%@", fileName);
	
	if (anURL != nil)
		[self noteNewRecentDocumentURL: anURL];
}

- (void) noteNewRecentDocumentURL: (NSURL *)anURL
{
	unsigned index = [_recentDocuments indexOfObject: anURL];
	NSMutableArray *a;
	NSLog(@"noteNewRecentDocumentURL:%@", anURL);
	if (index != NSNotFound)
		[_recentDocuments removeObjectAtIndex:index];	// Always keep the current object at the end of the list
	else if ([_recentDocuments count] > [self maximumRecentDocumentCount])
		[_recentDocuments removeObjectAtIndex:0];
	[_recentDocuments addObject: anURL];
	a=[_recentDocuments mutableCopy];
	index = [a count];
	while(index-- > 0)
		{
		[a replaceObjectAtIndex:index withObject:
			[[a objectAtIndex:index] absoluteString]];
		}
	[[NSUserDefaults standardUserDefaults] setObject:a forKey:NSRecentDocuments];	// save
	[a release];
	[self _updateOpenRecentMenu];
}

- (NSArray *) recentDocumentURLs
{
	return _recentDocuments;
}

- (unsigned int) maximumRecentDocumentCount;
{
	return 10;	// default
}

- (NSTimeInterval) autosavingDelay; { return _autosavingDelay; }

- (void) setAutosavingDelay:(NSTimeInterval) delay;
{
	_autosavingDelay=delay;
}

- (IBAction ) print:(id) sender
{
	[[self currentDocument] printDocument:sender];	// forward to the current document (main window)
}

/* new methods

- (NSError *) willPresentError:(NSError *) err;
- (BOOL) reopenDocumentForURL:(NSURL *) url
			withContentsOfURL:(NSURL *) contents
						error:(NSError **) err;
- (void) presentError:(NSError *) err
	   modalForWindow:(NSWindow *) win
			 delegate:(id) delegate 
   didPresentSelector:(SEL) sel
		  contextInfo:(void *) context;
- (BOOL) presentError:(NSError *) err;
- (id) openUntitledDocumentAndDisplay:(BOOL) flag error:(NSError **) err;
- (id) openDocumentWithContentsOfURL:(NSURL *) url
							 display:(BOOL) flag
							   error:(NSError **) err;
- (id) makeUntitledDocumentOfType:(NSString *) type error:(NSError **) err;
- (id) makeDocumentWithContentsOfURL:(NSURL *) url ofType:(NSString *) type error:(NSError **) err;
- (id) makeDocumentForURL:(NSURL *) url
		withContentsOfURL:(NSURL *) contents
				   ofType:(NSString *) type
					error:(NSError **) err;	// most generic call
- (NSArray *) documentClassNames;

*/

@end

@implementation NSDocumentController (Private)

- (NSArray *) _editorAndViewerTypesForClass: (Class)documentClass
{
	int i, count = [_types count];
	NSMutableArray *types = [NSMutableArray arrayWithCapacity: count];
	NSString *docClassName = NSStringFromClass (documentClass);
	
	for (i = 0; i < count; i++)
		{
		NSDictionary *typeInfo = [_types objectAtIndex: i];
		NSString     *className = [typeInfo objectForKey: NSDocumentClassKey];
		NSString     *role      = [typeInfo objectForKey: NSRoleKey];
		
		if ([docClassName isEqualToString: className] 
			&& (role == nil 
				|| [role isEqual: NSEditorRole] 
				|| [role isEqual: NSViewerRole]))
			{
			[types addObject: [typeInfo objectForKey: NSNameKey]];
			}
		}
	
	return types;
}

- (NSArray *) _editorTypesForClass: (Class)documentClass
{
	int i, count = [_types count];
	NSMutableArray *types = [NSMutableArray arrayWithCapacity: count];
	NSString *docClassName = NSStringFromClass (documentClass);
	
	for (i = 0; i < count; i++)
		{
		NSDictionary *typeInfo = [_types objectAtIndex: i];
		NSString     *className = [typeInfo objectForKey: NSDocumentClassKey];
		NSString     *role      = [typeInfo objectForKey: NSRoleKey];
		
		if ([docClassName isEqualToString: className] &&
			(role == nil || [role isEqual: NSEditorRole]))
			{
			[types addObject: [typeInfo objectForKey: NSNameKey]];
			}
		}
	
	return types;
}

- (NSArray *) _exportableTypesForClass: (Class)documentClass
{
	// Dunno what this method is for; maybe looks for filter types
	return [self _editorTypesForClass: documentClass];
}

@end