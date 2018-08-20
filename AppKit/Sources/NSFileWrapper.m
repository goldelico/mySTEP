/** <title>NSFileWrapper</title>

	<abstract>Hold a file's contents in dynamic memory.</abstract>

	Copyright (C) 1996 Free Software Foundation, Inc.

	Author: Felipe A. Rodriguez <far@ix.netcom.com>
	Date: Sept 1998
	Author: Jonathan Gapen <jagapen@whitewater.chem.wisc.edu>
	Date: Dec 1999

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

#import <AppKit/NSFileWrapper.h>
#import <AppKit/NSWorkspace.h>
#import "NSAppKitPrivate.h"

@interface _AppKitFileWrapper : NSFileWrapper
{
	NSImage *_iconImage;
}
@end

@implementation _AppKitFileWrapper

- (void) dealloc
{
	[_iconImage release];
	[super dealloc];
}

- (void) setIcon: (NSImage*)icon
{
	ASSIGN(_iconImage, icon);
}

- (NSImage*) icon
{
	if (!_iconImage)
		{
		return [[NSWorkspace sharedWorkspace] iconForFile: [self filename]];
		}
	else
		{
		return _iconImage;
		}
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject: _iconImage];
}

- (id) initWithCoder:(NSCoder*)aDecoder
{
	NSImage *iconImage;
	if((self=[super initWithCoder:aDecoder]))
		{
		// FIXME:
		if([aDecoder allowsKeyedCoding])
			return self;

		iconImage = [aDecoder decodeObject];
		if (iconImage != nil)
			{
			[self setIcon: iconImage];
			}
		}
	return self;
}

@end

@implementation NSFileWrapper (AppKitAdditions)

+ (id) allocWithZone:(NSZone *) zone;
{
	return [_AppKitFileWrapper allocWithZone:zone];
}

@end
