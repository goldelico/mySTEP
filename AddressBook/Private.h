//
//  ABAddressBook.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Aug 18 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#define AB_DIRECTORY	@"~/Library/Application Support/AddressBook/"
#define AB_IMAGES		[AB_DIRECTORY@"Images" stringByExpandingTildeInPath]
#define AB_FILE			[AB_DIRECTORY@"AddressBook.data" stringByExpandingTildeInPath]
#define AB_GROUPS		[AB_DIRECTORY@"AddressBook.groups" stringByExpandingTildeInPath]
#define AB_PERSONS		[AB_DIRECTORY@"AddressBook.persons" stringByExpandingTildeInPath]

// addressbook is an NSDictioanry

#define AB_KEY_PROPERTIES   @"properties"
#define AB_KEY_ME			@"ich"
#define AB_KEY_PERSONS		@"ABPerson"	// must match class name
#define AB_KEY_GROUPS		@"ABGroup"

@interface ABAddressBook (private)
- (void) _touch;
- (NSMutableDictionary *) _properties;
@end

@interface ABRecord (private)
// generic
- (void) _touch;
- (NSMutableDictionary *) _properties;
+ (NSMutableDictionary *) _properties;

- (NSDictionary *) _parseLine:(NSScanner *) sc;

	// tag representation
- (NSString *) _vCardTag;
- (NSDictionary *) _propertiesToEncode;

	// decoder
- (BOOL) _decodeWithVCardScanner:(NSScanner *) sc firstLine:(NSDictionary *) first; 
- (BOOL) _decodeLine:(NSDictionary *) line;
- (BOOL) _decodeProperty:(NSString *) property as:(NSString *) vCalProperty from:(NSDictionary *) line;

	// encoder
- (void) _encodeProperty:(NSString *) property as:(NSString *) vCalProperty to:(NSMutableString *) dest;
- (void) _encodeTag:(NSString *) tag attributes:(NSDictionary *) attribs value:(id) val to:(NSMutableString *) dest;
- (void) _encodeLine:(NSString *) s to:(NSMutableString *) dest;
- (void) _encodeVCard:(NSMutableString *) dest;
@end

@interface ABGroup (private)
- (void) _addToParentGroup:(ABGroup *) grp;
- (void) _removeFromParentGroup:(ABGroup *) grp;
@end


