/*
	NSShadow.m
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Sat Jul 30 2009.
	Copyright (c) 2009 DSITRI.
 
	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#import "AppKit/NSShadow.h"

#import "NSAppKitPrivate.h"
#import "NSBackendPrivate.h"

@implementation NSShadow

- (void) set; { BACKEND; }
- (void) setShadowBlurRadius:(CGFloat) rad; { _shadowBlurRadius = rad; }
- (void) setShadowColor:(NSColor *) col; { ASSIGN(_shadowColor, col); }
- (void) setShadowOffset:(NSSize) off; { _shadowOffset = off; }
- (CGFloat) shadowBlurRadius; { return _shadowBlurRadius; }
- (NSColor *) shadowColor; { return _shadowColor; }
- (NSSize) shadowOffset; { return _shadowOffset; }

- (void)encodeWithCoder:(NSCoder *) encoder
{
}

- (id) initWithCoder:(NSCoder *) decoder
{
	return self;
}

@end

