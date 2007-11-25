//
//  Authorization.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Tue Nov 25 2007.
//  Copyright (c) 2007 DSITRI. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Security/Authorization.h>

OSStatus AuthorizationExecuteWithPrivileges(AuthorizationRef authorization,
											 const char *pathToTool,
											 AuthorizationFlags options,
											 char * const *arguments,
											 FILE **communicationsPipe
											)
{
	// run as root (or suid of the tool) in a subprocess
	
	// How can we make this open source without compromizing integrity?

	// can we use sudo or do we need to use a special executor tool that is part of this framework (use [NSBundle bundleForClass:[SFAuthorization class]] to find the executable)
	return -60031;
}

/* EOF */
