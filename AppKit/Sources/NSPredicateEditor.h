//
//  NSPredicateEditor.h
//  AppKit
//
//  Created by Fabian Spillner on 03.12.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSRuleEditor.h"

@interface NSPredicateEditor : NSRuleEditor {

}

- (NSArray *) rowTemplates; 
- (void) setRowTemplates:(NSArray *) templates; 

@end
