//
//  SFAuthorizationView.m
//  mySTEP
//
//  shows lock/unlock icon
//  asks for user/password to authorize
//  shows a message near the icon
//
//  Created by Dr. H. Nikolaus Schaller on Tue Mar 22 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import <SecurityInterface/SFAuthorizationView.h>

@implementation SFAuthorizationView

- (id) initWithFrame:(NSRect) frame
{
	if((self=[super initWithFrame:frame]))
			{
				if(![NSBundle loadNibNamed:@"AuthorizationView" owner:self])
					[NSException raise: NSInternalInconsistencyException format:@"Unable to open authorization model file."];
				[self addSubview:box];	// make the box our subview
			}
	return self;
}

- (void) dealloc
{
	[_autoupdate invalidate];
	[super dealloc];
}

- (SFAuthorization *) authorization; { return _authorization; }
- (AuthorizationRights *) authorizationRights; { return _authorizationRights; }
- (SFAuthorizationViewState) authorizationState; { return _authorizationState; }

- (BOOL) authorize: (id) Sender;
{
	if(_authorizationState != SFAuthorizationViewUnlockedState)
			{
				// show popup to ask for user/password
				// ...
			}
	return [self updateStatus:Sender];
}

- (BOOL) deauthorize:(id) Sender;
{
	// ...
	[self updateStatus:Sender];
	return _authorizationState == SFAuthorizationViewLockedState;	// successfull
}

- (id) delegate; { return _delegate; }

- (BOOL) isEnabled; { return _isEnabled; }

- (void) setAuthorizationRights:(AuthorizationRights *) authorizationRights; { _authorizationRights = authorizationRights; }

- (void) setAutoupdate:(BOOL) flag interval:(NSTimeInterval) interval;
{
	[_autoupdate invalidate];
	_autoupdate=nil;
	if(flag)
		_autoupdate=[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(updateStatus:) userInfo:nil repeats:YES];
}

- (void) setAutoupdate:(BOOL) flag; { [self setAutoupdate:flag interval:10.0]; }

- (void) setDelegate:(id) delegate; { _delegate = delegate; }

- (void) setEnabled:(BOOL) enabled; { _isEnabled = enabled; }

- (void) setFlags:(AuthorizationFlags) flags; 
{
	// set in authorizationRights?
	// or is this a separate iVar that becomes initialized through setAuthorizationRights?
}

- (void) setString:(AuthorizationString) string; // a 0-terminated UTF-8 string
{
	/* general idea:
	static AuthorizationItem defaultItem = {
		string,
		0,
		NULL
		kAuthorizationFlagDefaults
	};
	static AuthorizationItemSet items = {
		1,
		&defaultItem;
	};
	[self setAuthorizationRights:&items];
	 */
}

- (BOOL) updateStatus:(id) Sender;
{
	// update
	// show list of authorizationRights
	// show status
	return _authorizationState == SFAuthorizationViewUnlockedState;
}

@end

