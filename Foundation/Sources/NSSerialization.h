/* 
   NSSerialization.h

   Protocol for NSSerialization
   - is deprecated since 10.2!
   - removed in 10.5
 
   Copyright (C) 1995 Free Software Foundation, Inc.

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSSerialization
#define _mySTEP_H_NSSerialization

#import <Foundation/NSData.h>

@protocol NSObjCTypeSerializationCallBack

- (void) deserializeObjectAt:(id*)object
				  ofObjCType:(const char *)type
					fromData:(NSData*)data
					atCursor:(unsigned*)cursor;
- (void) serializeObjectAt:(id*)object
				ofObjCType:(const char *)type
				  intoData:(NSMutableData*)data;
@end

@interface NSData (NSSerialization)

- (unsigned int) deserializeAlignedBytesLengthAtCursor:(unsigned int*)cursor;
- (void) deserializeBytes:(void*)buffer
				   length:(unsigned int)bytes
				 atCursor:(unsigned int*)cursor;
- (void) deserializeDataAt:(void*)data
				ofObjCType:(const char*)type
				  atCursor:(unsigned int*)cursor
				   context:(id <NSObjCTypeSerializationCallBack>)callback;
- (int) deserializeIntAtCursor:(unsigned int*)cursor;
- (int) deserializeIntAtIndex:(unsigned int)location;
- (void) deserializeInts:(int*)intBuffer
				   count:(unsigned int)numInts
				atCursor:(unsigned int*)cursor;
- (void) deserializeInts:(int*)intBuffer
				   count:(unsigned int)numInts
				 atIndex:(unsigned int)index;

@end

@interface NSMutableData (NSSerialization)

/* deprecated in Mac OS X v10.2 */

- (void) serializeAlignedBytesLength:(unsigned int)aLength;
- (void) serializeDataAt:(const void*)data
			  ofObjCType:(const char*)type
				 context:(id <NSObjCTypeSerializationCallBack>)callback;
- (void) serializeInt:(int)value;
- (void) serializeInt:(int)value atIndex:(unsigned int)location;
- (void) serializeInts:(int*)intBuffer count:(unsigned int)numInts;
- (void) serializeInts:(int*)intBuffer
				 count:(unsigned int)numInts
			   atIndex:(unsigned int)location;

@end

@interface NSSerializer : NSObject

+ (NSData*) serializePropertyList:(id)propertyList;
+ (void) serializePropertyList:(id)propertyList
					  intoData:(NSMutableData*)d;
@end

/* Note: NSDeserializer has been deprecated in 10.2! Instead use NSPropertyListSerialization! */

@interface NSDeserializer : NSObject

+ (id) deserializePropertyListFromData:(NSData *) data
							  atCursor:(unsigned int *) cursor
							  mutableContainers:(BOOL) flag;
+ (id) deserializePropertyListFromData:(NSData *) data
					 mutableContainers:(BOOL) flag;
+ (id) deserializePropertyListLazilyFromData:(NSData *) data
									atCursor:(unsigned *) cursor
									length:(unsigned) length
									mutableContainers:(BOOL) flag;
@end

#endif /* _mySTEP_H_NSSerialization */
