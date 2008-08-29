/* 
   NSPrivate.h

   Private Interfaces and definitions

   Copyright (C) 1997 Free Software Foundation, Inc.

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSPrivate
#define _mySTEP_H_NSPrivate

#import <Foundation/NSCoder.h>
#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSCompoundPredicate.h>
#import <Foundation/NSConnection.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDecimal.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSFileHandle.h>
#import <Foundation/NSHashTable.h>
#import <Foundation/NSIndexSet.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSNotificationQueue.h>
#import <Foundation/NSPort.h>
#import <Foundation/NSPortCoder.h>
#import <Foundation/NSPortMessage.h>
#import <Foundation/NSPortNameServer.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSPropertyList.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSScanner.h>
#import <Foundation/NSStream.h>
#import <Foundation/NSString.h>
#import <Foundation/NSTimeZone.h>
#import <Foundation/NSURLResponse.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSXMLParser.h>

#include <unistd.h>

/* Because openssl uses `id' as variable name sometime, while it is an Objective-C reserved keyword. */

#define id id_x_
#include <openssl/ssl.h>
#include <openssl/rand.h>
#include <openssl/err.h>
#undef id

// #define SIGNATURE_FORMAT_STRING  @"%s (%d.%s) [%s %d]\n"
#define SIGNATURE_FORMAT_STRING  @"%s (%d.%d) [%s %d]\n"	// minor version is also an integer and not a string!!!
#define PACKAGE_NAME "mySTEP"

#define SIGNATURE_ARGS	PACKAGE_NAME, \
						mySTEP_MAJOR_VERSION, \
						mySTEP_MINOR_VERSION, \
						[self defaultDecoderClassname], \
						format_version

#define PORT_CODER_FORMAT_VERSION (((mySTEP_MAJOR_VERSION * 100) + \
	mySTEP_MINOR_VERSION) * 100)

extern id GSError (id errObject, NSString *format, ...);

extern NSString * const GSHTTPPropertyMethodKey;
extern NSString * const GSHTTPPropertyProxyHostKey;
extern NSString * const GSHTTPPropertyProxyPortKey;

@interface Protocol (NSPrivate)

- (NSMethodSignature *) _methodSignatureForInstanceMethod:(SEL)aSel;
- (NSMethodSignature *) _methodSignatureForClassMethod:(SEL)aSel;

@end

@interface NSBundle (NSPrivate)
- (NSEnumerator *) _resourcePathEnumeratorFor:(NSString*) path subPath:(NSString *) subpath localization:(NSString *)locale;
@end

@interface NSXMLParser (NSPrivate)

- (void) _parseData:(NSData *) data;	// parse next junk for incremental parsing (use nil to denote EOF)
- (NSArray *) _tagPath;	// use [[parser _tagPath] componentsJoinedByString:@"."] to get a string like @"plist.dictionary.array.string"
- (BOOL) _acceptsHTML;
// - (void) _setAcceptHTML:(BOOL) flag;	// automatically detected
- (NSStringEncoding) _encoding;
- (void) _setEncoding:(NSStringEncoding) enc;
- (void) _stall:(BOOL) flag;	// stall - i.e. queue up calls to delegate methods
- (BOOL) _isStalled;
- (_NSXMLParserReadMode) _readMode;
- (void) _setReadMode:(_NSXMLParserReadMode) mode;

@end

@interface NSValue (NSPrivate)

+ (id) valueFromString:(NSString *)string;					// not OS spec

@end

@interface NSUserDefaults (NSPrivate)

+ (NSArray *) userLanguages;	// should this be replaced by NSLocale -availableLocaleIdentifiers?

@end

@interface NSTimeZone (NSPrivate)

- (id) _timeZoneDetailForDate:(NSDate *)date;

@end


@interface NSString (NSPrivate)

// + (NSString *) _stringWithFormat:(NSString*)format arguments:(va_list)args;
+ (NSString *) _string:(void *) bytes withEncoding:(NSStringEncoding) encoding length:(int) len;
+ (NSString *) _stringWithUTF8String:(const char *) bytes length:(unsigned) len;
+ (id) _initWithUTF8String:(const char *) bytes length:(unsigned) len;
- (int) _baseLength;			// methods for working with decomposed strings
- (NSString *) _stringByExpandingXMLEntities;

@end

@interface GSCString : GSBaseCString
{
	BOOL _freeWhenDone;
	unsigned _hash;
}
@end


@interface GSMutableCString : GSCString
{
	int _capacity;
}
@end


@interface GSString : NSString 
{
	unichar *_uniChars;
	BOOL _freeWhenDone;
	unsigned _hash;
}
@end


@interface GSMutableString : GSString
{
	int _capacity;
}
@end

extern NSStringEncoding GSDefaultCStringEncoding();	// determine default c string encoding based on mySTEP_STRING_ENCODING environment variable

extern NSString *GSGetEncodingName(NSStringEncoding encoding);

@interface NSSet (NSPrivate)

- (NSString*)descriptionWithLocale:(id)locale
							indent:(unsigned int)level;
- (id)initWithObject:(id)firstObj arglist:(va_list)arglist;

@end

@interface NSCountedSet (NSPrivate)

- (void)__setObjectEnumerator:(void*)en;

@end

@interface NSConcreteSet : NSSet
{
    NSHashTable *table;
}

- (id)init;
- (id)initWithObjects:(id*)objects count:(unsigned int)count;
- (id)initWithSet:(NSSet *)set copyItems:(BOOL)flag;

	// Accessing keys and values
- (unsigned int)count;
- (id)member:(id)anObject;
- (NSEnumerator *)objectEnumerator;

	// Private methods
- (void)__setObjectEnumerator:(void*)en;

@end


@interface NSConcreteMutableSet : NSMutableSet
{
    NSHashTable *table;
}

- (id)init;
- (id)initWithObjects:(id*)objects count:(unsigned int)count;
- (id)initWithSet:(NSSet *)set copyItems:(BOOL)flag;

	// Accessing keys and values
- (unsigned int)count;
- (id)member:(id)anObject;
- (NSEnumerator *)objectEnumerator;

	// Add and remove entries
- (void)addObject:(id)object;
- (void)removeObject:(id)object;
- (void)removeAllObjects;

	// Private methods
- (void)__setObjectEnumerator:(void*)en;

@end

@interface NSScanner (NSPrivate)

//
// used for NSText
//
- (BOOL) scanRadixUnsignedInt:(unsigned int *)value;
+ (id) _scannerWithString:(NSString*)aString 
					  set:(NSCharacterSet*)aSet 
			  invertedSet:(NSCharacterSet*)anInvSet;
- (NSRange) _scanCharactersInverted:(BOOL) inverted;
- (NSRange) _scanSetCharacters;
- (NSRange) _scanNonSetCharacters;
- (BOOL) _isAtEnd;
- (void) _setScanLocation:(unsigned) aLoc;

@end

@interface _NSPredicateScanner : NSScanner
{
	NSEnumerator *_args;
	va_list _vargs;
}

+ (_NSPredicateScanner *) _scannerWithString:(NSString *) format args:(NSEnumerator *) args vargs:(va_list) vargs;
- (id) _initWithString:(NSString *) format args:(NSEnumerator *) args vargs:(va_list) vargs;
- (NSEnumerator *) _args;
- (va_list) _vargs;
- (BOOL) _scanPredicateKeyword:(NSString *) key;

@end

@interface NSNotificationQueue (NSPrivate)

+ (void) _runLoopIdle;
+ (BOOL) _runLoopMore;
+ (void) _runLoopASAP;

@end

@interface NSRunLoop (NSPrivate)

- (void) _addInputWatcher:(id) watcher forMode:(NSString *) mode;
- (void) _removeInputWatcher:(id) watcher forMode:(NSString *) mode;
- (void) _addOutputWatcher:(id) watcher forMode:(NSString *) mode;
- (void) _removeOutputWatcher:(id) watcher forMode:(NSString *) mode;
- (void) _removeWatcher:(id) watcher;

@end

@interface NSObject (NSRunLoopWatcher)
- (int) _readFileDescriptor;			// return fd to watch for read/listen
- (int) _writeFileDescriptor;			// the fd to watch for write (or connect)
- (void) _readFileDescriptorReady;		// callback
- (void) _writeFileDescriptorReady;		// callback
@end

@interface NSCFType : NSObject
{ // used to read CF$UID values from (binary) keyedarchived property list
	unsigned value;
}

+ (id) CFUIDwithValue:(unsigned) val;
- (unsigned) uid;

@end

@interface NSCoder (NSPrivate)
- (id) _dereference:(unsigned int) idx;
// - (NSArray *) _decodeArrayOfObjectsForKey:(NSString *) name;
- (id) _decodeObjectForRepresentation:(id) obj;
@end

@interface NSPropertyListSerialization (NSPrivate)

// used internally for speed reasons in e.g. [NSString propertyList] where we already have a NSString

+ (id) _propertyListFromString:(NSString *) string
			  mutabilityOption:(NSPropertyListMutabilityOptions) opt
						format:(NSPropertyListFormat *) format
			  errorDescription:(NSString **) errorString;
+ (NSString *) _stringFromPropertyList:(id) plist
								format:(NSPropertyListFormat) format
					  errorDescription:(NSString **) errorString;

@end

@interface NSFileHandle (NSPrivate)

- (void) _setReadMode:(int) mode inModes:(NSArray *) modes;

@end

@interface NSPort (NSPrivate)

+ (id) _allocForProtocolFamily:(int) family;

- (BOOL) _connect;
- (BOOL) _bindAndListen;
- (void) _readFileDescriptorReady;
- (void) _writeFileDescriptorReady;
- (id) _substituteFromCache;

- (int) protocol;
- (int) socketType;

@end

@interface NSMessagePort (NSPrivate)

+ (NSString *) _portSocketDirectory;
- (void) _setName:(NSString *) name;
- (BOOL) _unlink;
- (id) _initRemoteWithName:(NSString *) name;

// other private messages found in a core dump:
// - sendBeforeTime:streamData:components:from:msgid:;
// + sendBeforeTime:streamData:components:from:msgid:;

@end

@interface NSPortMessage (NSPrivate)

+ (NSData *) _machMessageWithId:(unsigned)msgid forSendPort:(NSPort *)sendPort receivePort:(NSPort *)receivePort components:(NSArray *)components;
- (id) initWithMachMessage:(void *) buffer;
- (void) _setReceivePort:(NSPort *) p;
- (void) _setSendPort:(NSPort *) p;

@end

@interface NSData (NSPrivate)

- (id) _initWithBase64String:(NSString *) str;

// mySTEP Extensions

+ (id) dataWithShmID:(int)anID length:(unsigned) length;
+ (id) dataWithSharedBytes:(const void*)sbytes length:(unsigned) length;
+ (id) dataWithStaticBytes:(const void*)sbytes length:(unsigned) length;

- (void *) _autoFreeBytesWith0:(BOOL) flag;		// return a "autofreed" copy - optionally with a trailing 0

- (unsigned char) _deserializeTypeTagAtCursor:(unsigned*)cursor;
- (unsigned) _deserializeCrossRefAtCursor:(unsigned*)cursor;

@end


@interface NSMutableData (NSPrivate)

// Capacity management - mySTEP gives you control over the size of
// the data buffer as well as the 'length' of valid data in it.
- (unsigned int) capacity;
- (id) setCapacity: (unsigned int)newCapacity;

- (int) shmID;	/* Shared memory ID for data buffer (if any)	*/

		//	-serializeTypeTag:
		//	-serializeCrossRef:
		//	These methods are provided in order to give the mySTEP 
		//	version of NSArchiver maximum possible performance.
- (void) serializeTypeTag: (unsigned char)tag;
- (void) serializeCrossRef: (unsigned)xref;

@end


// GNUstep extensions to make the implementation of NSDecimalNumber totaly 
// independent for NSDecimals internal representation


// Give back the biggest NSDecimal
void NSDecimalMax(NSDecimal *result);
// Give back the smallest NSDecimal
void NSDecimalMin(NSDecimal *result);
// Give back the value of a NSDecimal as a double
double NSDecimalDouble(NSDecimal *number);
// Create a NSDecimal with a mantissa, exponent and a negative flag
void NSDecimalFromComponents(NSDecimal *result, unsigned long long mantissa, 
							 short exponent, BOOL negative);
// Create a NSDecimal from a string using the local
void NSDecimalFromString(NSDecimal *result, NSString *numberValue, 
						 NSDictionary *locale);

@interface NSMethodSignature (NSPrivate)

- (unsigned) _getArgumentLengthAtIndex:(int)index;
- (unsigned) _getArgumentQualifierAtIndex:(int)index;
- (const char *) _getArgument:(void *) buffer fromFrame:(arglist_t) _argframe atIndex:(int) index;
- (void) _setArgument:(void *) buffer forFrame:(arglist_t) _argframe atIndex:(int) index;
- (arglist_t) _allocArgFrame:(arglist_t) frame;
- (BOOL) _call:(void *) imp frame:(arglist_t) _argframe retbuf:(void *) buffer;
- (id) _initWithObjCTypes:(const char*) t;
- (const char *) _methodType;		// total method type
- (void) _makeOneWay;

@end

@interface NSInvocation (NSPrivate)

- (id) initWithMethodSignature:(NSMethodSignature*) aSignature;		// this one exists undocumented in Cocoa

- (id) _initWithMethodSignature:(NSMethodSignature*) aSignature andArgFrame:(arglist_t) argFrame;
// - (id) _initWithSelector:(SEL) aSelector andArgFrame:(arglist_t) argFrame;
- (retval_t) _returnValue;
- (void) _releaseArguments;
- (void) _releaseReturnValue;			// no longer needed so that we can reuse an invocation

@end

@interface NSObject (NSObjCRuntime)					// special
- (retval_t) forward:(SEL)aSel :(arglist_t)argFrame;	// private method called by runtime
@end

@interface NSProxy (NSPrivate)
+ (void) load;
- (NSString*) descriptionWithLocale:(id)locale indent:(unsigned int)indent;
- (NSString*) descriptionWithLocale:(id)locale;
- (id) notImplemented:(SEL)aSel;
@end

@interface NSProxy (NSObjCRuntime)					// special
- (retval_t) forward:(SEL)aSel :(arglist_t)argFrame;	// private method called by runtime
@end

@interface NSPortCoder (NSPrivate)
- (void) sendBeforeTime:(NSTimeInterval) time sendReplyPort:(NSPort *) port;
- (unsigned) _msgid;
- (void) _setMsgid:(unsigned) msgid;	// msgid to use when sending a NSPortMessage
- (void) _setConnection:(NSConnection *) connection;
- (NSArray *) _components;
- (NSPort *) _receivePort;
- (NSPort *) _sendPort;
@end

@interface NSDistantObjectRequest (NSPrivate)
- (id) _initWithPortCoder:(NSPortCoder *) coder;
- (NSPortCoder *) _portCoder;
@end

@interface NSDistantObject (NSPrivate)
- (oneway void) __;	// remote release request - keep name short to save some bytes to be sent around
@end

@interface NSConnection (NSPrivate)

// these methods exist in Cocoa but are not documented

- (void) dispatchInvocation:(NSInvocation *) i;
- (void) handlePortCoder:(NSPortCoder *) coder;
- (void) handlePortMessage:(NSPortMessage *) message;
- (void) handleRequest:(NSDistantObjectRequest *) req sequence:(int) seq;
- (void) sendInvocation:(NSInvocation *) i;

// really private methods
+ (NSConnection *) _connectionWithReceivePort:(NSPort *)receivePort
																		 sendPort:(NSPort *)sendPort;
- (void) _portDidBecomeInvalid:(NSNotification *) n;
- (void) _executeInNewThread;
- (void) _addAuthentication:(NSMutableArray *) components;
- (void) _addRemote:(NSDistantObject *) obj forTarget:(id) target;;	// add to list of remote objects
- (void) _removeRemote:(id) target; // remove from list of remote objects
- (NSDistantObject *) _getRemote:(id) target;	// get remote object for target
@end

@interface NSStream (NSPrivate)

- (void) _sendEvent:(NSStreamEvent) event;
- (void) _sendError:(NSError *) err;
- (void) _sendErrorWithDomain:(NSString *)domain code:(int)code;
- (void) _sendErrorWithDomain:(NSString *)domain code:(int)code userInfo:(NSDictionary *) dict;

@end

@interface NSInputStream (NSPrivate)

- (id) _initWithFileDescriptor:(int) fd;

@end

@interface NSOutputStream (NSPrivate)

- (id) _initWithFileDescriptor:(int) fd;
- (id) _initWithFileDescriptor:(int) fd append:(BOOL) flag;

@end


@interface _NSMemoryInputStream : NSInputStream
{
	unsigned const char *_buffer;
	unsigned long _position;
	unsigned long _capacity;
}
@end

@interface _NSMemoryOutputStream : NSOutputStream
{
	unsigned char *_buffer;
	unsigned long _position;
	unsigned long _currentCapacity;	// current buffer capacity
	unsigned long _capacityLimit;
}
@end

@interface _NSSocketOutputStream : NSOutputStream
{
	NSHost *_host;
	int _port;
	NSString *_securityLevel;
	// socks level and proxy config
@public
	SSL_CTX	*ctx;
	SSL		*ssl;
}
- (void) _setHost:(NSHost *) host andPort:(int) port;
@end

@interface _NSSocketInputStream : NSInputStream
{
	@public
	_NSSocketOutputStream *_output;	// we share the SSL data stuctures of the output stream
}
@end

@interface NSPredicate (NSPrivate)
+ (id) _parseWithScanner:(_NSPredicateScanner *) sc;
@end

@interface NSCompoundPredicate (NSPrivate)
+ (id) _parseNotWithScanner:(_NSPredicateScanner *) sc;
+ (id) _parseOrWithScanner:(_NSPredicateScanner *) sc;
+ (id) _parseAndWithScanner:(_NSPredicateScanner *) sc;
@end

@interface NSComparisonPredicate (NSPrivate)
+ (id) _parseComparisonWithScanner:(_NSPredicateScanner *) sc;
@end

@interface NSExpression (NSPrivate)
+ (id) _parseExpressionWithScanner:(_NSPredicateScanner *) sc;
+ (id) _parseFunctionalExpressionWithScanner:(_NSPredicateScanner *) sc;
+ (id) _parsePowerExpressionWithScanner:(_NSPredicateScanner *) sc;
+ (id) _parseMultiplicationExpressionWithScanner:(_NSPredicateScanner *) sc;
+ (id) _parseAdditionExpressionWithScanner:(_NSPredicateScanner *) sc;
+ (id) _parseBinaryExpressionWithScanner:(_NSPredicateScanner *) sc;
- (NSExpression *) _expressionWithSubstitutionVariables:(NSDictionary *)variables;
@end

@interface NSIndexSet (NSPrivate)
- (NSRange) _availableRangeWithRange:(NSRangePointer) range;
@end

@interface NSHTTPURLResponse (NSPrivate)
- (id) _initWithURL:(NSURL *) url headerFields:(NSDictionary *) headers andStatusCode:(int) code;
@end

#endif /* _mySTEP_H_NSPrivate */
