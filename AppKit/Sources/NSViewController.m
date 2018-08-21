//
//  NSViewController.m
//  AppKit
//
//  Created by Fabian Spillner on 20.12.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSViewController.h"
#import "NSAppKitPrivate.h"


@implementation NSViewController

- (BOOL) commitEditing; { NIMP; return NO; }
- (void) commitEditingWithDelegate:(id) obj didCommitSelector:(SEL) sel contextInfo:(void *) info; { NIMP; }
- (void) discardEditing; { NIMP; }
- (id) initWithNibName:(NSString *) name bundle:(NSBundle *) bundle; { return NIMP; }
- (void) loadView; { NIMP; }
- (NSBundle *) nibBundle; { return NIMP; }
- (NSString *) nibName; { return NIMP; }
- (id) representedObject; { return NIMP; }
- (void) setRepresentedObject:(id) repObject; { NIMP; }
- (void) setTitle:(NSString *) str; { NIMP; }
- (void) setView:(NSView *) view; { NIMP; }
- (NSString *) title; { return NIMP; }
- (NSView *) view; { return NIMP; }

@end
