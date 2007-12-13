//
//  NSDictionaryController.h
//  AppKit
//
//  Created by Fabian Spillner on 07.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/NSArrayController.h>


@interface NSDictionaryController : NSArrayController {

}

- (id) arrangedObjects; 
- (NSArray *) excludedKeys; 
- (NSArray *) includedKeys; 
- (NSString *) initialKey; 
- (id) initialValue; 
- (NSDictionary *) localizedKeyDictionary; 
- (NSString *) localizedKeyTable; 
- (id) newObject; 
- (void) setExcludedKeys:(NSArray *) exKeys; 
- (void) setIncludedKeys:(NSArray *) inKeys; 
- (void) setInitialKey:(NSString *) intKey; 
- (void) setInitialValue:(id) val; 
- (void) setLocalizedKeyDictionary:(NSDictionary *) dict; 
- (void) setLocalizedKeyTable:(NSString *) strs; 


@end

extern NSString *NSContentDictionaryBinding;
extern NSString *NSIncludedKeysBinding;
extern NSString *NSExcludedKeysBinding;
extern NSString *NSLocalizedKeyDictionaryBinding;
extern NSString *NSInitialKeyBinding;
extern NSString *NSInitialValueBinding;