/* 
   NSPortCoder.m

   Implementation of NSPortCoder object for remote messaging

   Complete rewrite:
   Dr. H. Nikolaus Schaller <hns@computer.org>
   Date: Jan 2006-Oct 2009
   Some implementation expertise comes from Crashlogs found on the Internet: Google e.g. for "NSPortCoder sendBeforeTime:"

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <sys/socket.h>

#import <Foundation/NSPortCoder.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDistantObject.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSRunLoop.h>

#import "NSPrivate.h"

/*
 this is how an Apple Cocoa request for [connection rootProxy] arrives in the first component of a NSPortMessage (with msgid=0)
 
 04									4 byte integer follows
 edfe1f 0e					0e1ffeed - appears to be some Byte-Order-mark and flags
 01 01							sequence number 1
 01 01							some unknown value 1
 01									1 byte integer follows
 0d									string len (incl. 00)
 4e53496e766f636174696f6e00			"NSInvocation"		class	- this payload encodes an NSInvocation
 00									value 00 (nil?)
 01 01							Integer 1
 01									1 byte integer follows
 10									string len (incl. 00)
 4e5344697374616e744f626a65637400	"NSDistantObject"	self	- appears to be the 'target' component
 00
 00
 0101
 0101
 0201
 01									1 byte length follows
 0b									string len (incl. 00)
 726f6f744f626a65637400				"rootObject			_cmd	- appears to be the 'selector' component
 01
 01									1 byte length follows
 04									len (incl. 00)
 40403a00							"@@:"				signature (return type=id, self=id, _cmd=SEL)
 0140								@
 0100
 00									?
 
 The encoding is not exactly clear
 
 You should set a breakpoint on -[NSPort sendBeforeDate:msgid:components:from:reserved:] to see what is going on
*/

@implementation NSPortCoder

+ (NSPortCoder *) portCoderWithReceivePort:(NSPort *) recv
								  sendPort:(NSPort *) send
								components:(NSArray *) cmp;
{
	return [[[self alloc] initWithReceivePort:recv sendPort:send components:cmp] autorelease];
}

- (void) sendBeforeTime:(NSTimeInterval) time sendReplyPort:(BOOL) flag;
{ // this method is not documented but exists (or at least did exist)!
	NSPortMessage *pm=[[NSPortMessage alloc] initWithSendPort:_send
												  receivePort:_recv
												   components:_components];
	NSDate *due=[NSDate dateWithTimeIntervalSinceReferenceDate:time];
	BOOL r;
//	[pm setMsgid:0];
	if(flag)
			[self encodePortObject:_recv];	// send our reply port
#if 0
	NSLog(@"sendBeforeTime %@ msgid=%d replyPort:%d _send:%@ _recv:%@", due, _msgid, flag, _send, _recv);
#endif
	r=[pm sendBeforeDate:due];
	[pm release];
	if(!r)
		[NSException raise:NSPortTimeoutException format:@"could not send request (within %.0lf seconds)", time];
}

- (void) dispatch;
{ // handle components either passed during initialization or received while sending
	NS_DURING
		[[self connection] handlePortCoder:self];	// locate real connection and forward
	NS_HANDLER
		NSLog(@"-[NSPortCoder dispatch]: %@", localException);
	NS_ENDHANDLER
}

- (NSConnection *) connection;
{
	if(!_connection)
		_connection=[NSConnection connectionWithReceivePort:_recv sendPort:_send];	// get our connection object
	return _connection;
}

- (id) initWithReceivePort:(NSPort *) recv sendPort:(NSPort *) send components:(NSArray *) cmp;
{
	if((self=[super init]))
		{
			NSData *first;
			_recv=[recv retain];
			_send=[send retain];
			if(!cmp)
				cmp=[NSMutableArray arrayWithObject:[NSMutableData dataWithCapacity:50]];	// allocate a single component for encoding
			_components=[cmp retain];
			first=[_components objectAtIndex:0];
			_pointer=[first bytes];	// set read pointer
			_eod=[first bytes] + [first length];
		}
	return self;
}

- (void) dealloc;
{
	[self invalidate];
	[super dealloc];
}

- (BOOL) isBycopy; { return _isBycopy; }
- (BOOL) isByref; { return _isByref; }

// core encoding

// FIXME: _encodeIntegerAt:addr size:

- (void) _encodeInteger:(long long) val
{
	NSMutableData *data=[_components objectAtIndex:0];
	union
		{
			long long val;
			unsigned char data[8];
		} d;
	char len=8;
	d.val=NSSwapHostLongLongToLittle(val);
	if(val < 0)
			{
				while(len > 0 && d.data[len-1] == 0xff)
					len--;	// get first non-0xff byte which determines length
				len=-len;	// encode by negative length
			}
	else
			{
				while(len > 0 && d.data[len-1] == 0)
					len--;	// get first non-0 byte which determines length
			}
	[data appendBytes:&len length:1];	// encode length of int
	[data appendBytes:&d.data length:len];	// encode integer
}

- (void) encodePortObject:(NSPort *) port;
{
	if(![port isKindOfClass:[NSPort class]])
		[NSException raise:NSInvalidArgumentException format:@"NSPort expected"];
	[(NSMutableArray *) _components addObject:port];
}

- (void) encodeArrayOfObjCType:(const char*)type
						 count:(unsigned int)count
							at:(const void*)array
{ // try to encode as a single component
#if 0
	NSLog(@"encodeArrayOfObjCType %s count %d", type, count);
#endif
	switch(*type)
		{
		case _C_ID:
		case _C_CLASS:
		case _C_SEL:
		case _C_PTR:
		case _C_ATOM:
		case _C_CHARPTR:
		case _C_ARY_B:
		case _C_STRUCT_B:
		case _C_UNION_B:
			[super encodeArrayOfObjCType:type count:count at:array];	// default implementation
			return;
		}
	[self encodeBytes:array length:count*objc_sizeof_type(type)];
}

- (void) encodeObject:(id) obj
{
	Class class=[obj class];
#if 0
	NSLog(@"NSPortCoder encodeObject%@%@ %p", _isBycopy?@" bycopy":@"", _isByref?@" byref":@"", obj);
	NSLog(@"  obj %@", obj);
#endif
	[self _encodeInteger:1];	// always
	if(class == [NSInvocation class])
			{
				[self encodeValueOfObjCType:@encode(Class) at:&class];
				[self encodeInvocation:obj];
			}
	else
		// special handling for NSData or NSPort needed?
			{
				obj=[obj replacementObjectForPortCoder:self];	// substitute by a proxy if required
#if 0
				NSLog(@"  replacement %@", obj);
#endif
				if(!obj)
					[self _encodeInteger:0]; // encode as 0x00 byte
				else
						{
							class=[obj classForPortCoder];
							// FIXME: should also look up in class translation table!
#if 0
							NSLog(@"  classForPortCoder %@", NSStringFromClass(class));
#endif
							[self encodeValueOfObjCType:@encode(Class) at:&class];
							[obj encodeWithCoder:self];	// translate and encode
						}
			}
	_isBycopy=_isByref=NO;	// reset flags for next encoder call
	[self _encodeInteger:0];	// always
}

- (void) encodeBycopyObject:(id) obj
{
	_isBycopy=YES;
	[self encodeObject:obj];
}

- (void) encodeByrefObject:(id) obj
{
	_isByref=YES;
	[self encodeObject:obj];
}

- (void) encodeBytes:(const void *) address length:(unsigned) numBytes;
{
	[self _encodeInteger:numBytes];
	[[_components objectAtIndex:0] appendBytes:address length:numBytes];	// encode data
}

- (void) encodeDataObject:(NSData *) data
{ // called by NSData encodeWithCoder
	[self encodeBytes:[data bytes] length:[data length]];
}

- (void) encodeValueOfObjCType:(const char *)type at:(const void *)address
{ // must encode in network byte order (i.e. bigendian)
#if 0
	NSLog(@"NSPortCoder encodeValueOfObjCType:%s", type);
#endif
	switch(*type)
		{
		default:
			NSLog(@"%@ can't encodeValueOfObjCType:%s", self, type);
			return;
		case _C_ID:
			{
				[self encodeObject:*((id *)address)];
				break;
			}
		case _C_CLASS:
			{
				Class c=*((Class *)address);
				char *class=c?[NSStringFromClass(c) UTF8String]:"Nil";
				[self encodeBytes:class length:strlen(class)+1];	// include terminating 0 byte
				break;
			}
		case _C_SEL:
			{
				SEL s=*((SEL *) address);
				char *sel=[NSStringFromSelector(s) UTF8String];
				[self encodeBytes:sel length:strlen(sel)+1];	// include terminating 0 byte
				break;
			}
		case _C_CHR:
		case _C_UCHR:
			{
				[data appendBytes:address length:1];	// encode character as it is
				break;
			}
		case _C_SHT:
		case _C_USHT:
			{
				[self _encodeInteger:*((short *) address)];
				break;
			}
		case _C_INT:
		case _C_UINT:
			{
				[self _encodeInteger:*((int *) address)];
				break;
			}
		case _C_LNG:
		case _C_ULNG:
			{
				[self _encodeInteger:*((long *) address)];
				break;
			}
		case _C_LNG_LNG:
		case _C_ULNG_LNG:
			{
				[self _encodeInteger:*((long long *) address)];
				break;
			}
#if FIXME
		case _C_FLT:
			{
				float val=NSSwapHostFloatToBig(*(float *)address);
				[self encodeBytes:&val length:sizeof(val)];
				break;
			}
		case _C_DBL:
			{
				double val=NSSwapHostDoubleToBig(*(double *)address);
				[self encodeBytes:&val length:sizeof(val)];
				break;
			}
#endif
		case _C_PTR:
			{
				// hm...
				void *val=(*(void **)address);
				[self encodeBytes:&val length:sizeof(val)];
				break;
			}
		case _C_ATOM:
		case _C_CHARPTR:
			{
				char *str=*((char **)address);
				if(!str)
					NSLog(@"can't encode NULL");
				else
					[self encodeBytes:str length:strlen(str)+1];	// include 0-byte
				break;
			}
		case _C_ARY_B:
		case _C_STRUCT_B:
		case _C_UNION_B:
			{
				int len=objc_sizeof_type(type);
				// should recursively encode components?!
#if 1
				NSLog(@"encode struct/array/union of size %d %s", len, type);
#endif
				[self encodeBytes:address length:len];
				break;
			}
		case _C_VOID:
			break;
		}
#if 1
	NSLog(@"encoded: %@", [_components objectAtIndex:0]);
#endif
}

// core decoding

- (long long) _decodeInteger
{
	union
		{
			long long val;
			unsigned char data[8];
		} d;
	int len;
	if(_pointer >= _eod)
		[NSException raise:NSPortReceiveException format:@"no more data to decode"];
	len=*_pointer++;
	if(len < 0)
			{ // fill with 1 bits
				len=-len;
				d.val=-1;	// initialize
			}
	else
		d.val=0;
	if(len > 8)
		[NSException raise:NSPortReceiveException format:@"invalid integer length to decode"];
	if(_pointer+len >= _eod)
		[NSException raise:NSPortReceiveException format:@"not enough data to decode integer"];
	memcpy(d.data, _pointer, len);
	_pointer+=len;
	return NSSwapLittleLongLongToHost(d.val);
}

- (NSPort *) decodePortObject;
{
	return NIMP;
}

- (void) decodeArrayOfObjCType:(const char*)type
						 count:(unsigned)count
							at:(void*)address
{ // try to decode as a single component
	unsigned size;
	char *bytes;
#if 0
	NSLog(@"decodeArrayOfObjCType %s count %d", type, count);
#endif
	switch(*type)
		{
		case _C_ID:
		case _C_CLASS:
		case _C_SEL:
		case _C_PTR:
		case _C_ATOM:
		case _C_CHARPTR:
		case _C_ARY_B:
		case _C_STRUCT_B:
		case _C_UNION_B:
			[super decodeArrayOfObjCType:type count:count at:address];	// default implementation
			return;
		}
	bytes=[self decodeBytesWithReturnedLength:&size];
	if(size != count*objc_sizeof_type(type))
		{
		NSLog(@"NSPortCoder decodeArrayOfObjCType size error (found=%u expected=%u)", size, count*objc_sizeof_type(type));
		return;	// error
		}
	memcpy(address, bytes, size);
}

- (id) decodeObject
{
	return [[self decodeRetainedObject] autorelease];
}

- (void *) decodeBytesWithReturnedLength:(unsigned *) numBytes;
{
	NSData *d=[self decodeDataObject];	// will be autoreleased
	if(numBytes)
		*numBytes=[d length];
	return (void *) [d bytes];
}

- (NSData *) decodeDataObject;
{ // get next object as it is
	unsigned long len=[self _decodeInteger];
	NSData *d;
	if(_pointer+len >= _eod)
		[NSException raise:NSPortReceiveException format:@"not enough data to decode data"];
	d=[NSData dataWithBytes:_pointer length:len];	// retained copy...
	_pointer+=len;
	return d;
}

- (void) decodeValueOfObjCType:(const char *) type at:(void *) address
{ // must encode in network byte order (i.e. bigendian)
#if 0
	NSLog(@"NSPortCoder decodeValueOfObjCType:%s", type);
#endif
	switch(*type)
		{
		default:
				NSLog(@"%@ can't decodeValueOfObjCType:%s", self, type);
				[NSException raise:NSPortReceiveException format:@"can't decodeValueOfObjCType:%s", type];
				return;
		case _C_ID:
			{
				*((id *)address)=[self decodeObject];
				return;
			}
		case _C_CLASS:
			{
				// FIXME: contains 0-termination character
				NSString *class=[[NSString alloc] initWithData:[self decodeDataObject] encoding:NSUTF8StringEncoding];
				if(!class)
					{
						NSLog(@"could not decode Class");
							{
								[NSException raise:NSPortReceiveException format:@"class %@ not loaded", class];
								return;
								}
						*((Class *)address)=Nil;
					}
				else
					{
					if([class isEqualToString:@"Nil"])
						*((Class *)address)=Nil;		// Nil class was encoded
					else
						*((Class *)address)=NSClassFromString(class);		// decode class by name
									// raise exception if unknown
					[class release];
					}
				return;
			}
		case _C_SEL:
			{
				// FIXME: contains 0-termination character
				NSString *selector=[[NSString alloc] initWithData:[self decodeDataObject] encoding:NSUTF8StringEncoding];
				if(!selector)
					{
						[NSException raise:NSPortReceiveException format:@"could not decode SEL"];
						*((SEL *)address)=NULL;
					}
				else
					{
					if([selector isEqualToString:@"NULL"])
						*((SEL *)address)=NULL;	// NULL selector (e.g. an [target action])
					else
						*((SEL *)address)=NSSelectorFromString(selector);		// decode selector by name
					[selector release];
					}
				return;
			}
		case _C_CHR:
		case _C_UCHR:
			{
				if(_pointer+len >= _eod)
					[NSException raise:NSPortReceiveException format:@"not enough data to decode data"];
				*((char *) address) = *_pointer++;	// single byte
				break;
			}
		case _C_SHT:
		case _C_USHT:
			{
				*((short *) address) = [self _decodeInteger];
				break;
			}
		case _C_INT:
		case _C_UINT:
			{
				*((int *) address) = [self _decodeInteger];
				break;
			}
		case _C_LNG:
		case _C_ULNG:
			{
				*((long *) address) = [self _decodeInteger];
				break;
			}
		case _C_LNG_LNG:
		case _C_ULNG_LNG:
			{
				*((long long *) address) = [self _decodeInteger];
				break;
			}
#if FIXME
		case _C_FLT:
			{
				unsigned numBytes;
				void *addr=[self decodeBytesWithReturnedLength:&numBytes];
				// FIXME: should be exception
				NSAssert(numBytes == sizeof(float), @"bad byte count for float");
				*((float *) address) = NSSwapBigFloatToHost(*(float *) addr);
				break;
			}
		case _C_DBL:
			{
				unsigned numBytes;
				void *addr=[self decodeBytesWithReturnedLength:&numBytes];
				// FIXME: should be exception
				NSAssert(numBytes == sizeof(double), @"bad byte count for double");
				*((double *) address) = NSSwapBigShortToHost(*(double *) addr);
				break;
			}
#endif
		case _C_PTR:
			{
				unsigned numBytes;
				void **addr=[self decodeBytesWithReturnedLength:&numBytes];
				// check for numBytes == sizeof(void *)
				*((void **) address) = (*(void **) addr);
				break;
			}
		case _C_ATOM:
		case _C_CHARPTR:
			{
				unsigned numBytes;
				void *addr=[self decodeBytesWithReturnedLength:&numBytes];
#if 0
				NSLog(@"decoded %u bytes atomar string", numBytes);
#endif
				*((char **) address) = addr;	// store address (storage object is an autoreleased NSData!)
				break;
			}
#if 1
		case _C_ARY_B:
		case _C_STRUCT_B:
		case _C_UNION_B:
			{
				int len=objc_sizeof_type(type);
				unsigned numBytes;
				void *addr=[self decodeBytesWithReturnedLength:&numBytes];
				if(numBytes != len)
					NSLog(@"length error");
#if 1
				NSLog(@"decoded %u bytes (%d expected) string %p", numBytes, len, addr);
#endif
				*((char **) address) = addr;	// store address (storage object is an autoreleased NSData!)
				break;
			}
#endif
		case _C_VOID:
			break;
		}
}

@end

@implementation NSPortCoder (NSConcretePortCoder)

- (void) invalidate
{ // release internal data and references to _send and _recv ports
	[_recv release];
	_recv=nil;
	[_send release];
	_send=nil;
	[_components release];
	_components=nil;
	[_imports release];
	_imports=nil;
}

- (NSArray *) components
{
	return _components;
}

- (void) encodeReturnValue:(NSInvocation *) i
{
	NSMethodSignature *sig=[i methodSignature];
	void *buffer=objc_malloc([sig methodReturnLength]);	// allocate a buffer
	[i getReturnValue:buffer];	// get value
	[self encodeValueOfObjCType:[sig methodReturnType] at:buffer];
	objc_free(buffer);
}

- (NSInvocation *) decodeReturnValue;
{
	NSInvocation *i=nil;	// where to get this from???
	NSMethodSignature *sig=[i methodSignature];
	void *buffer=objc_malloc([sig methodReturnLength]);	// allocate a buffer
	[self decodeValueOfObjCType:[sig methodReturnType] at:buffer];
	[i setReturnValue:buffer];	// set value
	objc_free(buffer);
}

- (void) encodeInvocation:(NSInvocation *) i
{
	NSMethodSignature *sig=[i methodSignature];
	void *buffer=objc_malloc([sig frameLength]);	// allocate a buffer
	int cnt=[sig numberOfArguments];	// encode arguments
	int j;
	char *str="@@:";	// we should collect the type arguments while we process them...
//	NSLog(@"sig=%@", [sig _typeString]);	// private getter - returns NSString
	for(j=0; j<cnt; j++)
			{ // encode arguments
				[i getArgument:buffer atIndex:j];	// get value
				[self encodeValueOfObjCType:[sig getArgumentTypeAtIndex:j] at:buffer];
			}
	[self encodeValueOfObjCType:@encode(char *) at:&str];
	// arginfo array (?)
	objc_free(buffer);
}

- (NSInvocation *) decodeInvocation;
{
	char *types;	// UTF8 string
	// decode retained objects
	// decode method signature string
	NSInvocation *i=[[NSInvocation alloc] initWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:types]];	// official method since 10.5
	// set arguments
	// adds something to arrays
	return [i autorelease];
}

- (id) importedObjects; { return _imports; }

- (void) importObject:(id) obj;
{
	if(!_imports)
		_imports=[[NSMutableArray alloc] initWithCapacity:5];
	[_imports addObject:obj];
}

- (id) decodeRetainedObject;
{
	NSString *name;
	Class class;
	[self decodeValueOfObjCType:@encode(Class) at:&class];
	if(!class)
		return nil;
	if(class == [NSInvocation class])
		return [[self decodeInvocation] retain];	// special handling
	return [[class alloc] initWithCoder:self];	// allocate and load new instance
#if OLDPIXMAPSTRUCT
	Class class;
	id obj;
	[self decodeValueOfObjCType:@encode(Class) at:&class];
#if 0
	NSLog(@"NSPortCoder decodeObject of class %@", NSStringFromClass(class));
#endif
	if(class == Nil)
		return nil;	// was a nil object
	// should also look up in class translation table!
	obj=[[class alloc] initWithCoder:self];	// decode
#if 0
	NSLog(@"NSPortCoder decodeRetainedObject(%@) -> %@", NSStringFromClass(class), obj);
#endif
	return obj;
#endif
}

- (void) encodeObject:(id) obj isBycopy:(BOOL) isBycopy isByref:(BOOL) isByref;
{
	_isBycopy=isBycopy;
	_isByref=isByref;
	[self encodeObject:obj];
}

- (void) authenticateWithDelegate:(id) delegate;
{
	if(delegate)
			{
				NSData *data=[delegate authenticationDataForComponents:[self components]];
				if(!data)
					[NSException raise:NSGenericException format:@"authenticationDataForComponents did return nil"];
				[(NSMutableArray *) _components addObject:data];	// append
			}
}

- (BOOL) verifyWithDelegate:(id) delegate;
{
	// check if we have processed the full request
	if(delegate)
			{
				NSArray *components=[self components];
				unsigned int len=[components count];
				if(len >= 2)
						{
							NSArray *subarray=[components subarrayWithRange:NSMakeRange(0, len-1)];
							NSData *data=[components objectAtIndex:len-1];	// split
							return [delegate authenticateComponents:components withData:data];
						}
				[NSException raise:NSFailedAuthenticationException format:@"did receive message without authentication"];
			}
	return YES;
}

@end

#if 0
@implementation NSObject (NSPortCoder)

- (Class) classForPortCoder				{ return [self classForCoder]; }

- (id) replacementObjectForPortCoder:(NSPortCoder*)coder
{ // default is to encode a local proxy
	id rep=[self replacementObjectForCoder:coder];
	if(rep)
		rep=[NSDistantObject proxyWithLocal:rep connection:[coder connection]];	// this will be encoded and decoded into a remote proxy
	return rep;
}

@end
#endif

@implementation NSPortMessage

/*
	Mach defines:
	port_t				NSPort object	type=2
	MSG_TYPE_BYTE		NSData object	type=1
	MSG_TYPE_CHAR	
	MSG_TYPE_INTEGER_32	

	According to experiments and descriptios in Amit Singhs book, a message appears to look like this:
	
	msgid=17, components=([NSData dataWithBytes:"1" length:1], [NSData data], [NSData dataWithBytes:"1" length:1]) result on a Mac in:
	d0cf50c0 0000003a 00000011 02010610 100211c7 00000000 00000000 00000000 00000001 00000001 31000000 01000000 00000000 01000000 0132
    msgid=12, components=([NSData dataWithBytes:"123" length:3], [NSData data], [NSData dataWithBytes:"987654321" length:9]) result on a Mac in:
	d0cf50c0 00000044 0000000c 02010610 100211c7 00000000 00000000 00000000 00000001 00000003 31323300 00000100 00000000 00000100 00000939 38373635 34333231
	h_bits   size     msgid    response expected on this sockadr            |type=1? |len=3   |"123"|type?   |len=0     |type=1? |len=9    |"987654321
    msgid=12, components=([NSData dataWithBytes:"123" length:3], <some NSSocketPort>) result on a Mac in:
    d0cf50c0 00000047 0000000c 02010610 100211c7 00000000 00000000 00000000 00000001 00000003 31323300 00000200 00001402 01061010 0211c700 00000000 00000000 000000
	h_bits   size     msgid    response expected on this sockadr            |type=1? |len=3   |"123"|type=2? |len=14  |AF_INET socket PF=2, type=1, AF=6, ?:<101002>, port=4551 (11c7) addr=0.0.0.0
    magic                      PF=2, type=1, AF=6, addrlen=10??
    i.e. the "receive port" is always encoded into the message
 
	h_bits might look constant but may be the two local&remote status bit short-ints. I.e. d0cf and 50c0 are flags which indicate if a receive or send port itself is part of the Mach message.
 
 */

struct MachHeader {
	unsigned long magic;	// well, some header bits
	unsigned long len;		// total packet length
	unsigned long msgid;
};

struct PortFlags {
	unsigned char family;
	unsigned char type;
	unsigned char protocol;
	unsigned char len;
};

+ (NSData *) _machMessageWithId:(unsigned) msgid forSendPort:(NSPort *)sendPort receivePort:(NSPort *)receivePort components:(NSArray *)components
{ // encode components as a binary message
	struct PortFlags port;
	NSMutableData *d=[NSMutableData dataWithCapacity:64+16*[components count]];	// some reasonable initial allocation
	NSEnumerator *e=[components objectEnumerator];
	id c;
	unsigned long value;
	value=NSSwapHostLongToBig(0xd0cf50c0);
	[d appendBytes:&value length:sizeof(value)];	// header flags
	[d appendBytes:&value length:sizeof(value)];	// we insert real length later on
	value=NSSwapHostLongToBig(msgid);
	[d appendBytes:&value length:sizeof(value)];	// message ID
	if(1 /* encode the receive port address */)
		{
		NSData *saddr=[(NSSocketPort *) receivePort address];
		port.protocol=[(NSSocketPort *) receivePort protocol];
		port.type=[(NSSocketPort *) receivePort socketType];
		port.family=[(NSSocketPort *) receivePort protocolFamily];
		port.len=[saddr length];
		[d appendBytes:&port length:sizeof(port)];	// write socket flags
		[d appendData:saddr];
		}
	while((c=[e nextObject]))
		{ // serialize objects
		if([c isKindOfClass:[NSData class]])
			{
			value=NSSwapHostLongToBig(1);	// MSG_TYPE_BYTE
			[d appendBytes:&value length:sizeof(value)];	// record type
			value=NSSwapHostLongToBig([c length]);
			[d appendBytes:&value length:sizeof(value)];	// total record length
			[d appendData:c];								// the data or port address
			}
		else
			{ // serialize an NSPort
			NSData *saddr=[(NSSocketPort *) c address];
			value=NSSwapHostLongToBig(2);	// port_t
			[d appendBytes:&value length:sizeof(value)];	// record type
			value=NSSwapHostLongToBig([saddr length]+sizeof(port));
			[d appendBytes:&value length:sizeof(value)];	// total record length
			port.protocol=[(NSSocketPort *) c protocol];
			port.type=[(NSSocketPort *) c socketType];
			port.family=[(NSSocketPort *) c protocolFamily];
			port.len=[saddr length];
			[d appendBytes:&port length:sizeof(port)];	// write socket flags
			[d appendData:saddr];
			}
		}
	value=NSSwapHostLongToBig([d length]);
	[d replaceBytesInRange:NSMakeRange(sizeof(value), sizeof(value)) withBytes:&value];	// insert total record length
#if 0
	NSLog(@"machmessage=%@", d);
#endif
	return d;
}

/*
 FIXME:
 because we receive from untrustworthy sources here, we must protect against malformed headers trying to create buffer overflows and Denial of Service.
 This might also be some very lage constant for record length which wraps around the 32bit address limit (e.g. a negative record length). This would
 end up in infinite loops blocking the application or service.
 */
 
- (id) initWithMachMessage:(void *) buffer;
{ // decode a binary encoded message - for some details see e.g. http://objc.toodarkpark.net/Foundation/Classes/NSPortMessage.htm
	if((self=[super init]))
		{
		struct MachHeader header;
		struct PortFlags port;
		char *bp, *end;
		NSData *addr;
		memcpy(&header, buffer, sizeof(header));
		if(header.magic != NSSwapHostLongToBig(0xd0cf50c0))
			{
#if 1
			NSLog(@"-initWithMachMessage: bad magic");
#endif
			[self release];
			return nil;
			}
		header.len=NSSwapBigLongToHost(header.len);
		if(header.len > 0x80000000)
			{
#if 1
			NSLog(@"-initWithMachMessage: unreasonable length");
#endif
			[self release];
			return nil;
			}
		_msgid=NSSwapBigLongToHost(header.msgid);
		end=(char *) buffer+header.len;	// total length
		bp=(char *) buffer+sizeof(header);						// start reading behind header
#if 0
		NSLog(@"msgid=%d len=%u", _msgid, end-(char *) buffer);
#endif
		if(1 /* send port */)
			{ // decode our send port that has been supplied by the sender as sendbeforeDate:from:
			memcpy(&port, bp, sizeof(port));
			if(bp+sizeof(port)+port.len > end)
				{ // goes beyond total length
				[self release];
				return nil;
				}
			addr=[NSData dataWithBytesNoCopy:bp+sizeof(port) length:port.len freeWhenDone:NO];	// we don't need to copy since we know that initRemoteWithProtocolFamily makes its own private copy
#if 0
			NSLog(@"decoded _send addr %@ %p", addr, addr);
#endif
			_send=[[NSPort _allocForProtocolFamily:port.family] initRemoteWithProtocolFamily:port.family socketType:port.type protocol:port.protocol address:addr];
#if 0
			NSLog(@"decoded _send %@", _send);
#endif
			bp+=sizeof(port)+port.len;
			}
		if(0 /* recv port */)
			{ // decode receive port that has been part of the message
			memcpy(&port, bp, sizeof(port));
			if(bp+sizeof(port)+port.len > end)
				{ // goes beyond total length
				[self release];
				return nil;
				}
			addr=[NSData dataWithBytesNoCopy:bp+sizeof(port) length:port.len freeWhenDone:NO];
#if 0
			NSLog(@"decoded _recv addr %@ %p", addr, addr);
#endif
			_recv=[[NSPort _allocForProtocolFamily:port.family] initRemoteWithProtocolFamily:port.family socketType:port.type protocol:port.protocol address:addr];
#if 0
			NSLog(@"decoded _recv %@", _recv);
#endif
			bp+=sizeof(port)+port.len;
			}
		_components=[[NSMutableArray alloc] initWithCapacity:5];
		while(bp < end)
			{ // more component records to come
			struct MachComponentHeader {
				unsigned long type;
				unsigned long len;
			} record;
			memcpy(&record, bp, sizeof(record));
#if 0
			NSLog(@"  pos=%u type=%u len=%u", bp-(char *) buffer, record.type, record.len);	// before byte swapping
#endif
			record.type=NSSwapBigLongToHost(record.type);
			record.len=NSSwapBigLongToHost(record.len);
#if 0
			NSLog(@"  pos=%u type=%u len=%u", bp-(char *) buffer, record.type, record.len);
#endif
			bp+=sizeof(record);
			if(record.len > end-bp)
				{ // goes beyond available data
#if 0
				NSLog(@"length error: pos=%u len=%u remaining=%u", bp-(char *) buffer, record.len, end-bp);
#endif
				[self release];
				return nil;
				}
			switch(record.type)
				{
				case 1:
					{ // NSData
#if 0
						NSLog(@"decode component with length %u", record.len); 
#endif
						[_components addObject:[NSData dataWithBytes:bp length:record.len]];	// cut out and save a copy of the data fragment
						break;
					}
				case 2:
					{ // decode NSPort
						NSData *addr;
						NSPort *p=nil;
						memcpy(&port, bp, sizeof(port));
						if(bp+sizeof(port)+port.len > end)
							{ // goes beyond total length
							[self release];
							return nil;
							}
						addr=[NSData dataWithBytesNoCopy:bp+sizeof(port) length:port.len freeWhenDone:NO];
#if 0
						NSLog(@"decode NSPort family=%u addr=%@ %p", port.family, addr, addr);
#endif
						p=[[NSPort _allocForProtocolFamily:port.family] initRemoteWithProtocolFamily:port.family socketType:port.type protocol:port.protocol address:addr];
						[_components addObject:p];
						[p release];
						break;
					}
				default:
					{
#if 0
						NSLog(@"unecpected record type %u at pos=%u", record.type, bp-(char *) buffer);
#endif
						[self release];
						return nil;
					}
				}
			bp+=record.len;	// go to next record
#if 0
			NSLog(@"pos=%u", bp-(char *) buffer);
#endif
			}
		if(bp != end)
			{
#if 0
			NSLog(@"length error bp=%p end=%p", bp, end);
#endif
			[self release];
			return nil;
			}
		}
	return self;
}

- (id) initWithSendPort:(NSPort *) aPort
			receivePort:(NSPort *) anotherPort
			 components:(NSArray *) items;
{
	if((self=[super init]))
		{
		_recv=[anotherPort retain];
		_send=[aPort retain];
		_components=[items retain];
		}
	return self;
}

- (void) dealloc;
{
#if 0
	NSLog(@"pm dealloc");
#endif
	[_recv release];
	[_send release];
	[_components release];
	[super dealloc];
}

- (NSArray*) components; { return _components; }
- (unsigned) msgid; { return _msgid; }
- (NSPort *) receivePort; { return _recv; }
// CHEKCME: do we need the private setters?
- (void) _setReceivePort:(NSPort *) p; { ASSIGN(_recv, p); }
- (NSPort *) sendPort; { return _send; }
- (void) _setSendPort:(NSPort *) p; { ASSIGN(_send, p); }
- (void) setMsgid: (unsigned)anId; { _msgid=anId; }

- (BOOL) sendBeforeDate:(NSDate*) when;
{
	if(!_send)
		[NSException raise:NSInvalidSendPortException format:@"no send port for message %@", self];
	if(!_recv)
		[NSException raise:NSInvalidReceivePortException format:@"no send port for message %@", self];
#if 0
	NSLog(@"send NSPortMessage: %@ on %@", _components, _send);
#endif
	return [_send sendBeforeDate:when msgid:_msgid components:_components from:_recv reserved:[_send reservedSpaceLength]];
}

@end
