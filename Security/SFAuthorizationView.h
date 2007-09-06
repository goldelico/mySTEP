//
//  SFAuthorizationView.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Tue Mar 22 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Security/SFAuthorization.h>

typedef enum 
{ 
    SFAuthorizationStartupState, 
    SFAuthorizationViewLockedState, 
    SFAuthorizationViewInProgressState, 
    SFAuthorizationViewUnlockedState 
} SFAuthorizationViewState; 

@interface SFAuthorizationView : NSView

- (SFAuthorization *) authorization; 
- (AuthorizationRights *) authorizationRights; 
- (SFAuthorizationViewState) authorizationState; 
- (BOOL) authorize: (id) Sender; 
- (BOOL) deauthorize:(id) Sender; 
- (id) delegate; 
- (BOOL) isEnabled; 
- (void) setAuthorizationRights:(AuthorizationRights *) authorizationRights;
- (void) setAutoupdate:(BOOL) flag interval:(NSTimeInterval) interval;
- (void) setAutoupdate:(BOOL) flag; 
- (void) setDelegate:(id) delegate; 
- (void) setEnabled:(BOOL) enabled; 
- (void) setFlags:(AuthorizationFlags) flags; 
- (void) setString:(AuthorizationString) string; 
- (BOOL) updateStatus:(id) Sender; 

@end

@interface NSObject (SFAuthorizationViewDelegate)
- (void) authorizationViewCreatedAuthorization:(SFAuthorizationView *) view;
- (void) authorizationViewDidAuthorize:(SFAuthorizationView *) view;
- (void) authorizationViewDidDeauthorize:(SFAuthorizationView *) view;
- (void) authorizationViewReleasedAuthorization:(SFAuthorizationView *) view;
- (BOOL) authorizationViewShouldDeauthorize:(SFAuthorizationView *) view;
@end


