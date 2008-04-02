//
//  NSViewController.h
//  AppKit
//
//  Created by Fabian Spillner on 20.12.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <AppKit/NSResponder.h>

@class NSBundle; 
@class NSString; 
@class NSView;

@interface NSViewController : NSResponder {

}

- (BOOL) commitEditing; 
- (void) commitEditingWithDelegate:(id) obj didCommitSelector:(SEL) sel contextInfo:(void *) info; 
- (void) discardEditing; 
- (id) initWithNibName:(NSString *) name bundle:(NSBundle *) bundle; 
- (void) loadView; 
- (NSBundle *) nibBundle; 
- (NSString *) nibName; 
- (id) representedObject; 
- (void) setRepresentedObject:(id) repObject; 
- (void) setTitle:(NSString *) str; 
- (void) setView:(NSView *) view; 
- (NSString *) title; 
- (NSView *) view; 

@end
