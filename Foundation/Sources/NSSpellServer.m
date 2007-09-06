//
//  NSSpellServer.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <Foundation/NSSpellServer.h>


@implementation NSSpellServer

- (id) delegate; { return _delegate; }
- (BOOL) isWordInUserDictionaries:(NSString *) word caseSensitive:(BOOL) flag; { return NO; }
- (BOOL) registerLanguage:(NSString *) language byVendor:(NSString *) vendor; { return NO; }
- (void) run; { return; }
- (void) setDelegate:(id) delegate; { _delegate=delegate; }

@end
