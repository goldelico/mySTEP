/* 
   NSWorkspace.h

   Interface for workspace.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:	Scott Christley <scottc@net-community.com>
   Date:	1996
 
   Author:    Fabian Spillner <fabian.spillner@gmail.com>
   Date:      20. December 2007 - aligned with 10.5 
   
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

typedef NSUInteger NSWorkspaceLaunchOptions;

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

enum {
	NSExcludeQuickDrawElementsIconCreationOption    = 1 << 1,
	NSExclude10_4ElementsIconCreationOption        = 1 << 2
};

typedef NSUInteger NSWorkspaceIconCreationOptions;

@interface NSWorkspace : NSObject

+ (NSWorkspace *) sharedWorkspace;

- (NSString *) absolutePathForAppBundleWithIdentifier:(NSString *) bundleIdentifier;
- (NSDictionary *) activeApplication;
- (void) checkForRemovableMedia;
- (NSInteger) extendPowerOffBy:(NSInteger) requested;
- (BOOL) filenameExtension:(NSString *) extension isValidForType:(NSString *) type;
- (BOOL) fileSystemChanged;
- (void) findApplications;
- (NSString *) fullPathForApplication:(NSString *) appName;
- (BOOL) getFileSystemInfoForPath:(NSString *) fullPath
					  isRemovable:(BOOL *) removableFlag
					   isWritable:(BOOL *) writableFlag
					isUnmountable:(BOOL *) unmountableFlag
					  description:(NSString **) description
							 type:(NSString **) fileSystemType;
- (BOOL) getInfoForFile:(NSString *) fullPath
			application:(NSString **) appName
				   type:(NSString **) type;
- (void) hideOtherApplications;
- (NSImage *) iconForFile:(NSString *) fullPath;
- (NSImage *) iconForFiles:(NSArray *) pathArray;
- (NSImage *) iconForFileType:(NSString *) fileType;
- (BOOL) isFilePackageAtPath:(NSString *) fullPath;
- (BOOL) launchApplication:(NSString *) appName;
- (BOOL) launchApplication:(NSString *) appName
				  showIcon:(BOOL) showIcon
				autolaunch:(BOOL) autolaunch;
- (BOOL) launchAppWithBundleIdentifier:(NSString *) identOrApp
							   options:(NSWorkspaceLaunchOptions) options
		additionalEventParamDescriptor:(id) ignored
					  launchIdentifier:(NSNumber **) identifiers;
- (NSArray *) launchedApplications;
- (NSString *) localizedDescriptionForType:(NSString *) type; 
- (NSArray *) mountedLocalVolumePaths; 
- (NSArray *) mountedRemovableMedia;
- (NSArray *) mountNewRemovableMedia;
- (void) noteFileSystemChanged;
- (void) noteFileSystemChanged:(NSString *) path;
- (void) noteUserDefaultsChanged;
- (NSNotificationCenter *) notificationCenter;
- (BOOL) openFile:(NSString *) fullPath;
- (BOOL) openFile:(NSString *) fullPath
		fromImage:(NSImage *) anImage
			   at:(NSPoint) point
		   inView:(NSView *) aView;
- (BOOL) openFile:(NSString *) fullPath withApplication:(NSString *) appName;
- (BOOL) openFile:(NSString *) fullPath
		 withApplication:(NSString *) appName
		 andDeactivate:(BOOL) flag;
- (BOOL) openTempFile:(NSString *) fullPath;
- (BOOL) openURL:(NSURL *) url;
- (BOOL) openURLs:(NSArray *) list
		 withAppBundleIdentifier:(NSString *) ident
		 options:(NSWorkspaceLaunchOptions) options
		 additionalEventParamDescriptor:(id) ignored
		 launchIdentifiers:(NSArray **) identifiers;
- (BOOL) performFileOperation:(NSString *) operation
					   source:(NSString *) source
				  destination:(NSString *) destination
						files:(NSArray *) files
						  tag:(NSInteger *) tag;
- (NSString *) preferredFilenameExtensionForType:(NSString *) type;
- (NSArray *) runningApplications;	// modern interface
- (BOOL) selectFile:(NSString *) fullPath inFileViewerRootedAtPath:(NSString *) rootFullpath;
- (BOOL) setIcon:(NSImage *) img forFile:(NSString *) path options:(NSWorkspaceIconCreationOptions) opts; 
- (void) slideImage:(NSImage *) image
			   from:(NSPoint) fromPoint
				 to:(NSPoint) toPoint;
- (BOOL) type:(NSString *) firstType conformsToType:(NSString *) secondType; 
- (NSString *) typeOfFile:(NSString *) path error:(NSError **) error; 
- (BOOL) unmountAndEjectDeviceAtPath:(NSString *) path;
- (BOOL) userDefaultsChanged;

@end

extern NSString *NSWorkspaceDidMountNotification;
extern NSString *NSWorkspaceDidLaunchApplicationNotification;	
extern NSString *NSWorkspaceDidPerformFileOperationNotification;
extern NSString *NSWorkspaceDidTerminateApplicationNotification;
extern NSString *NSWorkspaceDidUnmountNotification;
extern NSString *NSWorkspaceWillLaunchApplicationNotification;
extern NSString *NSWorkspaceWillPowerOffNotification;
extern NSString *NSWorkspaceWillUnmountNotification;

extern NSString *NSPlainFileType;
extern NSString *NSDirectoryFileType;
extern NSString *NSApplicationFileType;
extern NSString *NSFilesystemFileType;
extern NSString *NSShellCommandFileType;

extern NSString *NSApplicationIcon;
extern NSString *NSApplicationPath;
extern NSString *NSApplicationName;
extern NSString *NSApplicationBundleIdentifier;
extern NSString *NSApplicationProcessIdentifier;

extern NSString *NSWorkspaceCompressOperation;
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
