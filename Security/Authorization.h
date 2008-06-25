//
//  Authorization.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Tue Nov 25 2007.
//  Copyright (c) 2007 DSITRI. All rights reserved.
//

typedef const struct AuthorizationOpaqueRef *AuthorizationRef;	// define before we import Foundation

#import <Foundation/Foundation.h>

// FIXME: split to AuthorizationDB.h and AuthorizationTags.h

#ifndef __APPLE__
typedef int OSStatus;
#endif

enum 
{
	kAuthorizationFlagDefaults				= 0,
	kAuthorizationFlagInteractionAllowed	= (1 << 0),
	kAuthorizationFlagExtendRights			= (1 << 1),
	kAuthorizationFlagPartialRights			= (1 << 2),
	kAuthorizationFlagDestroyRights			= (1 << 3),
	kAuthorizationFlagPreAuthorize			= (1 << 4),
	kAuthorizationFlagNoData				= (1 << 20)
};

enum
{
	kAuthorizationFlagCanNotPreAuthorize	= (1 << 0)
};

#define kAuthorizationEmptyEnvironment NULL

enum
{
	kAuthorizationExternalFormLength = 32
};

#define errAuthorizationSuccess						0	
#define errAuthorizationInvalidSet					-60001	
#define errAuthorizationInvalidRef					-60002	
#define errAuthorizationInvalidTag					-60003	
#define errAuthorizationInvalidPointer				-60004	
#define errAuthorizationDenied						-60005	
#define errAuthorizationCanceled					-60006	
#define errAuthorizationInteractionNotAllowed		-60007	
#define errAuthorizationInternal					-60008	
#define errAuthorizationExternalizeNotAllowed		-60009	
#define errAuthorizationInternalizeNotAllowed		-60010	
#define errAuthorizationInvalidFlags				-60011	
#define errAuthorizationToolExecuteFailure			-60031	
#define errAuthorizationToolEnvironmentError		-60032	

typedef UInt32 AuthorizationFlags;
typedef const char *AuthorizationString;

typedef struct
{
	AuthorizationString name;
	UInt32 valueLength;
	void *value;
	UInt32 flags;
} AuthorizationItem;

typedef struct
{
	UInt32 count;
	AuthorizationItem *items;
} AuthorizationItemSet;

typedef AuthorizationItemSet AuthorizationEnvironment;
typedef AuthorizationItemSet AuthorizationRights;

struct AuthorizationExternalForm
{
	char bytes[kAuthorizationExternalFormLength];
};

OSStatus AuthorizationExecuteWithPrivileges(AuthorizationRef authorization,
											 const char *pathToTool,
											 AuthorizationFlags options,
											 char * const *arguments,
											 FILE **communicationsPipe
											);

// EOF
