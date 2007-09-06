/* 
   NSWorkspace.h

   Interface for workspace.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:	Scott Christley <scottc@net-community.com>
   Date:	1996
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSWorkspace
#define _mySTEP_H_NSWorkspace

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

@class NSString;
@class NSArray;
@class NSDictionary;
@class NSNotificationCenter;
@class NSImage;
@class NSView;
@class NSURL;
@class NSNumber;

typedef unsigned int NSWorkspaceLaunchOptions;
enum {
	NSWorkspaceLaunchAndPrint = 0x0001,
	NSWorkspaceLaunchInhibitingBackgroundOnly=0x0002,
	NSWorkspaceLaunchWithoutAddingToRecents=0x0004,
	NSWorkspaceLaunchWithoutActivation=0x0008,
	NSWorkspaceLaunchAsync=0x0010,
	NSWorkspaceLaunchAllowingClassicStartup=0x0020,	// ignored
	NSWorkspaceLaunchPreferringClassic=0x0040,	// ignored
	NSWorkspaceLaunchNewInstance=0x0080,
	NSWorkspaceLaunchAndHide=0x0100,
	NSWorkspaceLaunchAndHideOthers=0x0200,
	NSWorkspaceLaunchDefault=NSWorkspaceLaunchAsync | NSWorkspaceLaunchAllowingClassicStartup
};

@interface NSWorkspace : NSObject

+ (NSWorkspace *) sharedWorkspace;

- (BOOL) openFile:(NSString *)fullPath;						// Open files
- (BOOL) openFile:(NSString *)fullPath withApplication:(NSString *)appName;
- (BOOL) openFile:(NSString *)fullPath
		 withApplication:(NSString *)appName
		 andDeactivate:(BOOL)flag;
- (BOOL) openTempFile:(NSString *)fullPath;
- (BOOL) openURL:(NSURL *)url;								// Open url
- (BOOL) openURLs:(NSArray *) list							// Open multiple files or URLs - this is the main function
		 withAppBundleIdentifier:(NSString *) ident
		 options:(NSWorkspaceLaunchOptions) options
		 additionalEventParamDescriptor:(id) ignored
		 launchIdentifiers:(NSArray **) identifiers;

- (BOOL) openFile:(NSString *)fullPath
		fromImage:(NSImage *)anImage
			   at:(NSPoint)point
		   inView:(NSView *)aView;		// open in Finder
- (BOOL) selectFile:(NSString *)fullPath
		 inFileViewerRootedAtPath:(NSString *)rootFullpath;

- (BOOL) performFileOperation:(NSString *)operation			// Manipulate files
					   source:(NSString *)source
					   destination:(NSString *)destination
					   files:(NSArray *)files
					   tag:(int *)tag;

- (BOOL) getFileSystemInfoForPath:(NSString *)fullPath		// File information
					  isRemovable:(BOOL *)removableFlag
					  isWritable:(BOOL *)writableFlag
					  isUnmountable:(BOOL *)unmountableFlag
					  description:(NSString **)description
					  type:(NSString **)fileSystemType;
- (BOOL) getInfoForFile:(NSString *)fullPath
			application:(NSString **)appName
			type:(NSString **)type;
- (NSString *) absolutePathForAppBundleWithIdentifier:(NSString *)bundleIdentifier;
- (NSString *) fullPathForApplication:(NSString *)appName;
- (BOOL) isFilePackageAtPath:(NSString *)fullPath;
- (NSImage *) iconForFile:(NSString *)fullPath;
- (NSImage *) iconForFiles:(NSArray *)pathArray;
- (NSImage *) iconForFileType:(NSString *)fileType;

- (BOOL) fileSystemChanged;									// Track Changes
- (void) noteFileSystemChanged;

- (void) findApplications;									// Find all Apps

- (BOOL) launchApplication:(NSString *)appName;				// Launch Apps
- (BOOL) launchApplication:(NSString *)appName
				 showIcon:(BOOL)showIcon
				 autolaunch:(BOOL)autolaunch;
- (BOOL) launchAppWithBundleIdentifier:(NSString *) identOrApp
							   options:(NSWorkspaceLaunchOptions) options
		additionalEventParamDescriptor:(id) ignored
					  launchIdentifier:(NSNumber **) identifiers;

- (NSArray *) mountNewRemovableMedia;						// Mount devices
- (NSArray *) mountedRemovableMedia;
- (BOOL) unmountAndEjectDeviceAtPath:(NSString *)path;
- (void) checkForRemovableMedia;

- (void) noteUserDefaultsChanged;							// Track ddb change
- (BOOL) userDefaultsChanged;

- (NSNotificationCenter *) notificationCenter;

- (NSDictionary *) activeApplication;
- (NSArray *) launchedApplications;
- (void) hideOtherApplications;

- (void) slideImage:(NSImage *)image
			   from:(NSPoint)fromPoint
			   to:(NSPoint)toPoint;
- (int) extendPowerOffBy:(int)requested;
- (BOOL) isFilePackageAtPath:(NSString *) fullPath;

@end

extern NSString *NSWorkspaceDidMountNotification;			// Notifications
extern NSString *NSWorkspaceDidLaunchApplicationNotification;	
extern NSString *NSWorkspaceDidPerformFileOperationNotification;
extern NSString *NSWorkspaceDidTerminateApplicationNotification;
extern NSString *NSWorkspaceDidUnmountNotification;
extern NSString *NSWorkspaceWillLaunchApplicationNotification;
extern NSString *NSWorkspaceWillPowerOffNotification;
extern NSString *NSWorkspaceWillUnmountNotification;

extern NSString *NSPlainFileType;					// File Type Globals
extern NSString *NSDirectoryFileType;
extern NSString *NSApplicationFileType;
extern NSString *NSFilesystemFileType;
extern NSString *NSShellCommandFileType;

extern NSString *NSApplicationIcon;
extern NSString *NSApplicationPath;
extern NSString *NSApplicationName;
extern NSString *NSApplicationProcessIdentifier;

extern NSString *NSWorkspaceCompressOperation;		// File Operation Globals
extern NSString *NSWorkspaceCopyOperation;
extern NSString *NSWorkspaceDecompressOperation;
extern NSString *NSWorkspaceDecryptOperation;
extern NSString *NSWorkspaceDestroyOperation;
extern NSString *NSWorkspaceDuplicateOperation;
extern NSString *NSWorkspaceEncryptOperation;
extern NSString *NSWorkspaceLinkOperation;
extern NSString *NSWorkspaceMoveOperation;
extern NSString *NSWorkspaceRecycleOperation;

#endif /* _mySTEP_H_NSWorkspace */
