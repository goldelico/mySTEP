//
//  NSPredicateEditor.h
//  AppKit
//
//  Created by Fabian Spillner on 03.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NSRuleEditor; 

@interface NSPredicateEditor : NSRuleEditor {

}

- (NSArray *) rowTemplates; 
- (void) setRowTemplates:(NSArray *) templates; 

@end
