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

#import <sys/socket.h>	// needed for handling MachMessages on TCP/IP

#import <Foundation/NSPortCoder.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDistantObject.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSRunLoop.h>

#ifdef __APPLE__
// make us work on Apple objc-runtime

const char *objc_skip_typespec (const char *type);

int objc_alignof_type(const char *type)
{
	if(*type == _C_CHR)
		return 1;
	else
		return 4;
}

int objc_sizeof_type(const char *type)
{
	switch(*type) {
		case _C_ID:	return sizeof(id);
		case _C_CLASS:	return sizeof(Class);
		case _C_SEL:	return sizeof(SEL);
		case _C_PTR:	return sizeof(void *);
		case _C_ATOM:
		case _C_CHARPTR:	return sizeof(char *);
		case _C_ARY_B: {
			int cnt=0;
			type++;
			while(isdigit(*type))
				cnt=10*cnt+(*type++)-'0';
			return cnt*objc_sizeof_type(type);
		}
		case _C_UNION_B:
			// should get maximum size of all components
		case _C_STRUCT_B: {
			int cnt=0;
			while(*type != 0 && *type != '=')
				type++;
			while(*type != 0 && *type != _C_STRUCT_E)
				{
				int objc_aligned_size(const char *type);
				cnt+=objc_aligned_size(type);
				type=(char *) objc_skip_typespec(type);
				}
			return cnt;
		}
		case _C_VOID:	return 0;
		case _C_CHR:
		case _C_UCHR:	return sizeof(char);
		case _C_SHT:
		case _C_USHT:	return sizeof(short);
		case _C_INT:
		case _C_UINT:	return sizeof(int);
		case _C_LNG:
		case _C_ULNG:	return sizeof(long);
		case _C_LNG_LNG:
		case _C_ULNG_LNG:	return sizeof(long long);
		case _C_FLT:	return sizeof(float);
		case _C_DBL:	return sizeof(double);
		default:
			NSLog(@"can't determine size of %s", type);
			return 0;
	}
}

int objc_aligned_size(const char *type)
{
	int sz=objc_sizeof_type(type);
	if(sz%4 != 0)
		sz+=4-(sz%4);
	return sz;
}

const char *objc_skip_offset (const char *type)
{
	while(isdigit(*type))
		type++;
	return type;
}

const char *objc_skip_typespec (const char *type)
{
	switch(*type) {
		case _C_PTR:	// *type
			return objc_skip_typespec(type+1);
		case _C_ARY_B:	// [size type]
			type=objc_skip_offset(type+1);
			type=objc_skip_typespec(type);
			if(*type == _C_ARY_E)
				type++;
			return type;
		case _C_STRUCT_B:	// {name=type type}
			while(*type != 0 && *type != '=')
				type++;
			while(*type != 0 && *type != _C_STRUCT_E)
				type=objc_skip_typespec(type);
			if(*type != 0)
				type++;
			return type;
		default:
			return type+1;
	}
}

#endif

#import "NSPrivate.h"

/*
 this is how an Apple Cocoa request for [connection rootProxy] arrives in the first component of a NSPortMessage (with msgid=0)
 
 04									4 byte integer follows
 edfe1f 0e					0e1ffeed - appears to be some Byte-Order-mark and flags
 01 01							sequence number 1
 01									flag that value is not nil
 01									more classes follow
 01									1 byte integer follows
 0d									string len (incl. 00)
 4e53496e766f636174696f6e00			"NSInvocation"		class	- this payload encodes an NSInvocation
 00									flag that we don't encode version information
 01 01							Integer 1
 01									1 byte integer follows
 10									string len (incl. 00)
 4e5344697374616e744f626a65637400	"NSDistantObject"	self	- represents the 'target' component
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
 00									end of record
 
 You can set a breakpoint on -[NSPort sendBeforeDate:msgid:components:from:reserved:] to see what is going on
 */

@interface NSObject (NSPortCoding) 	// allows to define specific port-coding without changing the standard encoding (keyed/non-keyed)

+ (int) _versionForPortCoder;	// return version to be provided during encoding - defaults to 0
- (void) _encodeWithPortCoder:(NSCoder *) coder;
- (id) _initWithPortCoder:(NSCoder *) coder;

@end

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
	int _msgid=0;
#if 1
	NSLog(@"sendBeforeTime %@ msgid=%d replyPort:%d _send:%@ _recv:%@", due, _msgid, flag, _send, _recv);
#endif
	[pm setMsgid:_msgid];
	if(flag)
		[self encodePortObject:_recv];	// send where we expect the reply
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
		NSAssert(recv, @"receive port");
		NSAssert(send, @"send port");
		if(!cmp)
			cmp=[NSMutableArray arrayWithObject:[NSMutableData dataWithCapacity:200]];	// provide a default object for encoding
		NSAssert(cmp, @"components");
		_recv=[recv retain];
		_send=[send retain];
		_components=[cmp retain];
		first=[_components objectAtIndex:0];
		_pointer=[first bytes];	// set read pointer
		_eod=(unsigned char *) [first bytes] + [first length];	// only relevant for decoding
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

// should know about expected length
// raise exception: more significant bytes (%d) than room to hold them (%d)

- (void) _encodeInteger:(long long) val
{
	NSMutableData *data=[_components objectAtIndex:0];
	union
	{
	long long val;
	unsigned char data[8];
	} d;
	char len=8;
#if 0
	NSLog(@"encode %lld", val);
#endif
	d.val=NSSwapHostLongLongToLittle(val);	// NOTE: this has been unit-tested to be correct on big and little endian machines
	if(val < 0)
		{
		while(len > 1 && d.data[len-1] == (unsigned char) 0xff)
			len--;	// get first non-0xff byte which determines length
		len=-len;	// encode by negative length
		}
	else
		{
		while(len > 0 && d.data[len-1] == 0)
			len--;	// get first non-0 byte which determines length
		}
	[data appendBytes:&len length:1];	// encode length of int
	[data appendBytes:&d.data length:len<0?-len:len];	// encode integer with absolute length
}

- (void) encodePortObject:(NSPort *) port;
{
	if(![port isKindOfClass:[NSPort class]])
		{
		NSLog(@"encodePortObject: %@", port);
		[NSException raise:NSInvalidArgumentException format:@"NSPort expected"];
		}
	[(NSMutableArray *) _components addObject:port];
}

- (void) encodeArrayOfObjCType:(const char*) type
						 count:(unsigned int) count
							at:(const void*) array
{
	int size=objc_sizeof_type(type);
#if 1
	NSLog(@"encodeArrayOfObjCType %s count %d size %d", type, count, size);
#endif
	if(size == 1)
		{
		[[_components objectAtIndex:0] appendBytes:array length:count];	// encode bytes directly
		return;
		}
	while(count-- > 0)
		{
		[self encodeValueOfObjCType:type at:array];
		array=size + (char *) array;
		}
}

- (void) encodeObject:(id) obj
{
	Class class;
	id robj;
	BOOL flag;
#if 0
	NSLog(@"NSPortCoder encodeObject%@%@ %p", _isBycopy?@" bycopy":@"", _isByref?@" byref":@"", obj);
	NSLog(@"  obj %@", obj);
#endif
	robj=[obj replacementObjectForPortCoder:self];	// substitute by a proxy if required
	flag=(robj != nil);
	if(![robj isProxy])
		class=[robj classForPortCoder];	// only available for NSObject but not for NSProxy
	else
		class=[robj class];
#if 1
	if(robj != obj)
		NSLog(@"different replacement object for: %@", robj);
	NSLog(@"obj.class=%@", NSStringFromClass([obj class]));
	if(![obj isProxy])
		NSLog(@"obj.class.version=%u", [[obj class] version]);
	if(![obj isProxy])
		NSLog(@"obj.classForCoder=%@", NSStringFromClass([obj classForCoder]));
	if(![obj isProxy])
		NSLog(@"obj.classForPortCoder=%@", NSStringFromClass([obj classForPortCoder]));
	NSLog(@"obj.superclass=%@", NSStringFromClass([obj superclass]));
	NSLog(@"repobj.class=%@", NSStringFromClass([robj class]));
	if(![robj isProxy])
		NSLog(@"repobj.class.version=%u", [[robj class] version]);
	if(![robj isProxy])
		NSLog(@"repobj.classForCoder=%@", NSStringFromClass([robj classForCoder]));
	if(![robj isProxy])
		NSLog(@"repobj.classForPortCoder=%@", NSStringFromClass([robj classForPortCoder]));
	NSLog(@"repobj.superclass=%@", NSStringFromClass([robj superclass]));
	if(![robj isProxy])
		NSLog(@"repobj.classForPortCoder.superclass=%@", NSStringFromClass([[robj classForPortCoder] superclass]));
#endif
	[self encodeValueOfObjCType:@encode(BOOL) at:&flag];	// the first byte is the non-nil/nil flag
	if(flag)
		{ // encode class and version info
			int version;
			Class superclass;
			[self encodeValueOfObjCType:@encode(Class) at:&class];
			if(![robj isProxy])	// for some reason we can't call +version on NSProxy...
				{
				flag=(version=[class _versionForPortCoder]) != 0;
				if(flag)
					{ // main class is not version 0
						[self encodeValueOfObjCType:@encode(BOOL) at:&flag];	// version is not 0
						[self encodeValueOfObjCType:@encode(int) at:&version];
					}
				superclass=[class superclass];
				while(superclass != Nil)
					{ // check
						version=[superclass _versionForPortCoder];
						flag=(version != 0);
						if(flag)
							{ // receiver must be notified about version != 0
								[self encodeValueOfObjCType:@encode(BOOL) at:&flag];	// version is not 0
								[self encodeValueOfObjCType:@encode(Class) at:&superclass];
								[self encodeValueOfObjCType:@encode(int) at:&version];
							}
						superclass=[superclass superclass];	// go up one level
					}
				}
			flag=NO;
			[self encodeValueOfObjCType:@encode(BOOL) at:&flag];	// no more class version info follows
			if(class == [NSInvocation class])
				[self encodeInvocation:robj];
			else if(![robj isProxy] && [class instancesRespondToSelector:@selector(_encodeWithPortCoder:)])
				[robj _encodeWithPortCoder:self];	// this allows to define different encoding
			else
				[robj encodeWithCoder:self];	// translate and encode
			flag=YES;	// It appears as if this is always YES
			[self encodeValueOfObjCType:@encode(BOOL) at:&flag];
		}
#if 1
	NSLog(@"encodeObject -> %@", _components);
#endif
	_isBycopy=_isByref=NO;	// reset flags for next encoder call
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
	BOOL flag=NO;
	[self encodeValueOfObjCType:@encode(BOOL) at:&flag];
	[self encodeBytes:[data bytes] length:[data length]];
}

- (void) encodeValueOfObjCType:(const char *)type at:(const void *)address
{ // must encode in network byte order (i.e. bigendian)
#if 0
	NSLog(@"NSPortCoder encodeValueOfObjCType:'%s' at:%p", type, address);
#endif
	switch(*type) {
		case _C_VOID:
		case _C_UNION_B:
		default:
			NSLog(@"%@ can't encodeValueOfObjCType:%s", self, type);
			return;
		case _C_ID:	{
			[self encodeObject:*((id *)address)];
			break;
		}
		case _C_CLASS: {
			Class c=*((Class *)address);
			BOOL flag=YES;
			const char *class=c?[NSStringFromClass(c) UTF8String]:"nil";
#if 1
			NSLog(@"encoding class %s", class);
#endif
#if 0	// for debugging
			if(strcmp(class, "MYDistantObject") == 0)
				class="NSDistantObject";
#endif
			[self encodeValueOfObjCType:@encode(BOOL) at:&flag];
			if(class)
				[self encodeBytes:class length:strlen(class)+1];	// include terminating 0 byte
			break;
		}
		case _C_SEL: {
			SEL s=*((SEL *) address);
			BOOL flag=(s != NULL);
			const char *sel=[NSStringFromSelector(s) UTF8String];
			[self encodeValueOfObjCType:@encode(BOOL) at:&flag];
			if(sel)
				[self encodeBytes:sel length:strlen(sel)+1];	// include terminating 0 byte
			break;
		}
		case _C_CHR:
		case _C_UCHR: {
			[[_components objectAtIndex:0] appendBytes:address length:1];	// encode character as it is
			break;
		}
		case _C_SHT:
		case _C_USHT: {
			[self _encodeInteger:*((short *) address)];
			break;
		}
		case _C_INT:
		case _C_UINT: {
			[self _encodeInteger:*((int *) address)];
			break;
		}
		case _C_LNG:
		case _C_ULNG: {
			[self _encodeInteger:*((long *) address)];
			break;
		}
		case _C_LNG_LNG:
		case _C_ULNG_LNG: {
			[self _encodeInteger:*((long long *) address)];
			break;
		}
		case _C_FLT: {
			NSMutableData *data=[_components objectAtIndex:0];
			NSSwappedFloat val=NSSwapHostFloatToLittle(*(float *)address);	// test on PowerPC if we really swap or if we swap only when we decode from a different architecture
			char len=sizeof(float);
			[data appendBytes:&len length:1];
			[data appendBytes:&val length:len];
			break;
		}
		case _C_DBL: {
			NSMutableData *data=[_components objectAtIndex:0];
			NSSwappedDouble val=NSSwapHostDoubleToLittle(*(double *)address);
			char len=sizeof(double);
			[data appendBytes:&len length:1];
			[data appendBytes:&val length:len];
			break;
		}
		case _C_ATOM:
		case _C_CHARPTR: {
			char *str=*((char **)address);
			BOOL flag=(str != NULL);
			[self encodeValueOfObjCType:@encode(BOOL) at:&flag];
			if(flag)
				[self encodeBytes:str length:strlen(str)+1];	// include final 0-byte
			break;
		}
		case _C_PTR: { // generic pointer
			void *ptr=*((void **) address);
			BOOL flag=(ptr != NULL);
			[self encodeValueOfObjCType:@encode(BOOL) at:&flag];
			if(flag)
				[self encodeArrayOfObjCType:type+1 count:1 at:ptr];	// dereference pointer
			break;
		}
		case _C_ARY_B: { // get number of entries from type encoding
			int cnt=0;
			type++;
			while(*type >= '0' && *type <= '9')
				cnt=10*cnt+(*type++)-'0';
			[self encodeArrayOfObjCType:type count:cnt at:address];
			break;
		}
		case _C_STRUCT_B: { // recursively encode components! type is e.g. "{testStruct=c*}"
#if 1
			NSLog(@"encodeValueOfObjCType %s", type);
#endif
			while(*type != 0 && *type != '=')
				type++;
			if(*type++ == 0)
				break;	// invalid
			while(*type != 0 && *type != '}')
				{
#if 1
				NSLog(@"addr %p struct component %s", address, type);
#endif
				[self encodeValueOfObjCType:type at:address];
				address=objc_aligned_size(type) + (char *)address;
				type=objc_skip_typespec(type);	// next
				}
#if 1
			NSLog(@"did encode struct/array/union of type %s", type);
#endif
			break;
		}
	}
#if 0
	NSLog(@"encoded: %@", [_components objectAtIndex:0]);
#endif
}

// core decoding

- (NSString *) _location;
{ // show current decoding location
	NSData *first=[_components objectAtIndex:0];
	const unsigned char *f=[first bytes];	// initial read pointer
	return [NSString stringWithFormat:@"%@ * %@", [first subdataWithRange:NSMakeRange(0, _pointer-f)], [first subdataWithRange:NSMakeRange(_pointer-f, _eod-_pointer)]];
}

- (long long) _decodeInteger
{
	union
	{
	long long val;
	unsigned char data[8];
	} d;
	int len;
	if(_pointer >= _eod)
		[NSException raise:NSPortReceiveException format:@"no more data to decode (%@)", [self _location]];
	len=*_pointer++;
	if(len < 0)
		{ // fill with 1 bits
			len=-len;
			d.val=-1;	// initialize
		}
	else
		d.val=0;
	if(len > 8)
		[NSException raise:NSPortReceiveException format:@"invalid integer length (%d) to decode (%@)", len, [self _location]];
	if(_pointer+len > _eod)
		[NSException raise:NSPortReceiveException format:@"not enough data to decode integer with length %d (%@)", len, [self _location]];
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
							at:(void*)array
{
	int size=objc_sizeof_type(type);
#if 1
	NSLog(@"decodeArrayOfObjCType %s count %d size %d", type, count, size);
#endif
	if(size == 1)
		{
		if(_pointer+count >= _eod)
			[NSException raise:NSPortReceiveException format:@"not enough data to decode byte array"];
		memcpy(array, _pointer, count);
		_pointer+=count;
		return;
		}
	while(count-- > 0)
		{
		[self decodeValueOfObjCType:type at:array];
		array=size + (char *) array;
		}
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
	if(_pointer+len > _eod)
		[NSException raise:NSPortReceiveException format:@"not enough data to decode data (length=%ul): %@", len, [self _location]];
	d=[NSData dataWithBytes:_pointer length:len];	// retained copy...
	_pointer+=len;
	return d;
}

- (void) decodeValueOfObjCType:(const char *) type at:(void *) address
{ // must encode in network byte order (i.e. bigendian)
#if 0
	NSLog(@"NSPortCoder decodeValueOfObjCType:%s at:%p", type, address);
#endif
	switch(*type) {
		case _C_VOID:
		case _C_UNION_B:
		default:
			NSLog(@"%@ can't decodeValueOfObjCType:%s", self, type);
			[NSException raise:NSPortReceiveException format:@"can't decodeValueOfObjCType:%s", type];
			return;
		case _C_ID: {
			*((id *)address)=[self decodeObject];
			return;
		}
		case _C_CLASS: {
			BOOL flag;
			Class class=nil;
			[self decodeValueOfObjCType:@encode(BOOL) at:&flag];
			if(flag)
				{
				unsigned int len;
				char *str=[self decodeBytesWithReturnedLength:&len];	// include terminating 0 byte
				// check if last byte is 00
				NSString *s=[NSString stringWithUTF8String:str];
				if(![s isEqualToString:@"Nil"])	// may not really be needed unless someone defines a class named "Nil"
					class=NSClassFromString(s);
				}
			*((Class *)address)=class;
			return;
		}
		case _C_SEL: {
			BOOL flag;
			SEL sel=NULL;
			[self decodeValueOfObjCType:@encode(BOOL) at:&flag];
			if(flag)
				{
				unsigned int len;
				char *str=[self decodeBytesWithReturnedLength:&len];	// include terminating 0 byte
				// check if last byte is 00
				NSString *s=[NSString stringWithUTF8String:str];
				sel=NSSelectorFromString(s);
				}
			*((SEL *)address)=sel;
			return;
		}
		case _C_CHR:
		case _C_UCHR: {
			if(_pointer >= _eod)
				[NSException raise:NSPortReceiveException format:@"not enough data to decode char: %@", [self _location]];
			*((char *) address) = *_pointer++;	// single byte
			break;
		}
		case _C_SHT:
		case _C_USHT: {
			*((short *) address) = [self _decodeInteger];
			break;
		}
		case _C_INT:
		case _C_UINT: {
			*((int *) address) = [self _decodeInteger];
			break;
		}
		case _C_LNG:
		case _C_ULNG: {
			*((long *) address) = [self _decodeInteger];
			break;
		}
		case _C_LNG_LNG:
		case _C_ULNG_LNG: {
			*((long long *) address) = [self _decodeInteger];
			break;
		}
		case _C_FLT: {
			NSSwappedFloat val;
			if(_pointer+sizeof(float) >= _eod)
				[NSException raise:NSPortReceiveException format:@"not enough data to decode float"];
			if(*_pointer != sizeof(float))
				[NSException raise:NSPortReceiveException format:@"invalid length to decode float"];
			memcpy(&val, ++_pointer, sizeof(float));
			_pointer+=sizeof(float);
			*((float *) address) = NSSwapLittleFloatToHost(val);	
			break;
		}
		case _C_DBL: {
			NSSwappedDouble val;
			if(_pointer+sizeof(double) >= _eod)
				[NSException raise:NSPortReceiveException format:@"not enough data to decode double"];
			if(*_pointer != sizeof(double))
				[NSException raise:NSPortReceiveException format:@"invalid length to decode double"];
			memcpy(&val, ++_pointer, sizeof(double));
			_pointer+=sizeof(double);
			*((double *) address) = NSSwapLittleDoubleToHost(val);	
			break;
		}
		case _C_ATOM:
		case _C_CHARPTR: {
			BOOL flag;
			unsigned numBytes;
			void *addr;
			[self decodeValueOfObjCType:@encode(BOOL) at:&flag];
			if(flag)
				{
				addr=[self decodeBytesWithReturnedLength:&numBytes];
#if 0
				NSLog(@"decoded %u bytes atomar string", numBytes);
#endif
				// should check if the last byte is 00
				}
			else
				addr=NULL;
			*((char **) address) = addr;	// store address (storage object is an autoreleased NSData!)
			break;
		}
		case _C_PTR: {
			BOOL flag;
			// unsigned numBytes;
			void *addr;
			[self decodeValueOfObjCType:@encode(BOOL) at:&flag];
			if(flag)
				[self decodeArrayOfObjCType:type+1 count:1 at:&addr];
			else
				addr=NULL;	// FIXME - what does this mean???
			*((void **) address) = (*(void **) addr);
			break;
		}
		case _C_ARY_B: { // get number of entries from type encoding
			int cnt=0;
			type++;
			while(*type >= '0' && *type <= '9')
				cnt=10*cnt+(*type++)-'0';
			[self decodeArrayOfObjCType:type count:cnt at:address];
			break;
		}
		case _C_STRUCT_B: { // recursively decode components! type is e.g. "{testStruct=c*}"
			while(*type != 0 && *type != '=')
				type++;
			if(*type++ == 0)
				break;	// invalid
			while(*type != 0 && *type != '}')
				{
#if 1
				NSLog(@"addr %p struct component %s", address, type);
#endif
				[self decodeValueOfObjCType:type at:address];
				address=objc_aligned_size(type) + (char *)address;
				type=objc_skip_typespec(type);	// next
				}
			break;
		}
	}
}

- (int) versionForClassName:(NSString *) className
{ // can be called within initWithCoder to find out which version(s) to decode
	Class class;
	NSNumber *version;
#if 0
	NSLog(@"versionForClassName: %@", className);
#endif
	version=[_classVersions objectForKey:className];
	if(version)
		return [version intValue];	// defined by sender
	class=NSClassFromString(className);
	if(!class)
		return NSNotFound;	// unknown class
	return [class version];
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

/*  */

- (void) encodeReturnValue:(NSInvocation *) i
{ // encode the return value as an object with correct type
	NSMethodSignature *sig=[i methodSignature];
	void *buffer=objc_malloc([sig methodReturnLength]);	// allocate a buffer
	NS_DURING
		[i getReturnValue:buffer];	// get value
		[self encodeValueOfObjCType:[sig methodReturnType] at:buffer];
	NS_HANDLER
		NSLog(@"encodeReturnValue has no return value");	// e.g. if [i invoke] did result in an exception!
	NS_ENDHANDLER
	objc_free(buffer);
}

- (void) decodeReturnValue:(NSInvocation *) i
{ // decode object as return value into existing invocation so that we can finish a forwardInvocation:
	NSMethodSignature *sig=[i methodSignature];
	void *buffer=objc_malloc([sig methodReturnLength]);	// allocate a buffer
	[self decodeValueOfObjCType:[sig methodReturnType] at:buffer];
	[i setReturnValue:buffer];	// set value
	objc_free(buffer);
}

// this should be implemented in NSInvocation to have direct access to the iVars
// i.e. call some private [i _encodeWithPortCoder:self]
// this would also eliminate the detection of the Class during encodeObject/decodeObject

- (void) encodeInvocation:(NSInvocation *) i
{
	NSMethodSignature *sig=[i methodSignature];
	unsigned char len=[sig methodReturnLength];	// this should be the lenght really allocated
	void *buffer=objc_malloc(MAX([sig frameLength], len));	// allocate a buffer
	int cnt=[sig numberOfArguments];	// encode arguments (incl. target&selector)
	// if we move this to NSInvocation we don't even need the private methods
	const char *type=[[sig _typeString] UTF8String];	// private method (of Cocoa???) to get the type string
//	const char *type=[sig _methodType];	// would be a little faster
	id target=[i target];
	SEL selector=[i selector];
	int j;
#if 0
	NSLog(@"encodeInvocation1 comp=%@", _components);
#endif
	[self encodeValueOfObjCType:@encode(id) at:&target];
	[self encodeValueOfObjCType:@encode(int) at:&cnt];	// argument count
	[self encodeValueOfObjCType:@encode(SEL) at:&selector];
	[self encodeValueOfObjCType:@encode(char *) at:&type];	// method type
	[self encodeValueOfObjCType:@encode(unsigned char) at:&len];
#if 0
	NSLog(@"encodeInvocation2 comp=%@", _components);
#endif
	NS_DURING
		[i getReturnValue:buffer];	// get value
	NS_HANDLER	// not needed if we implement encoding in NSInvocation
		NSLog(@"encodeInvocation has no return value");	// e.g. if [i invoke] did result in an exception!
		len=1;
		*(char *) buffer=0x40;
	NS_ENDHANDLER
	[self encodeArrayOfObjCType:@encode(char) count:len at:buffer];	// encode the bytes of the return value (not the object/type which can be done by encodeReturnValue)
	for(j=2; j<cnt; j++)
		{ // encode arguments
			// set byRef & byCopy flags here
			[i getArgument:buffer atIndex:j];	// get value
			[self encodeValueOfObjCType:[sig getArgumentTypeAtIndex:j] at:buffer];
		}
#if 0
	NSLog(@"encodeInvocation3 comp=%@", _components);
#endif
	objc_free(buffer);
}

- (NSInvocation *) decodeInvocation;
{
	NSInvocation *i;
	NSMethodSignature *sig;
	void *buffer;
	char *type;
	int cnt;	// number of arguments (incl. target&selector)
	unsigned char len;
	id target;
	SEL selector;
	int j;
	[self decodeValueOfObjCType:@encode(id) at:&target];
	[self decodeValueOfObjCType:@encode(int) at:&cnt];
	[self decodeValueOfObjCType:@encode(SEL) at:&selector];
	[self decodeValueOfObjCType:@encode(char *) at:&type];
	[self decodeValueOfObjCType:@encode(unsigned char) at:&len];	// should set the buffer size internal to the NSInvocation
	// FIXME: we should we translate network signatures here or should all foundation classes be compatible with OpenSTEP?
	sig=[NSMethodSignature signatureWithObjCTypes:type];
	buffer=objc_malloc(MAX([sig frameLength], len));	// allocate a buffer
	i=[NSInvocation invocationWithMethodSignature:sig];
	[self decodeArrayOfObjCType:@encode(char) count:len at:buffer];	// decode byte pattern
	[i setReturnValue:buffer];	// set value
	for(j=2; j<cnt; j++)
		{ // decode arguments
		[self decodeValueOfObjCType:[sig getArgumentTypeAtIndex:j] at:buffer];
		[i setArgument:buffer atIndex:j];	// set value
		}
	[i setTarget:target];
	[i setSelector:selector];
	objc_free(buffer);
	return i;
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
	Class class;
	id obj;
	BOOL flag;
	NSMutableDictionary *savedClassVersions;
	int version;
#if 1
	NSLog(@"decodeRetainedObject: %@", [self _location]);
#endif
	[self decodeValueOfObjCType:@encode(BOOL) at:&flag];	// the first byte is the non-nil/nil flag
	if(!flag)
		return nil;
	[self decodeValueOfObjCType:@encode(Class) at:&class];
#if 1
	NSLog(@"decoded class=%@", NSStringFromClass(class));
#endif
	if(!class)
		return nil;	// unknown - should have raised?
	savedClassVersions=_classVersions;
	if(_classVersions)
		_classVersions=[_classVersions mutableCopy];
	else
		_classVersions=[[NSMutableDictionary alloc] initWithCapacity:5];
	[self decodeValueOfObjCType:@encode(BOOL) at:&flag];	// version flag
	if(flag)
		{ // main class version is not 0
			[self decodeValueOfObjCType:@encode(int) at:&version];
#if 0
			NSLog(@"versionForClass: %@ -> %d", NSStringFromClass(class), version);
#endif
			[_classVersions setObject:[NSNumber numberWithInt:version] forKey:NSStringFromClass(class)];	// save class version
			while(YES)
				{ // decode versionForClass info
					Class otherClass;
					[self decodeValueOfObjCType:@encode(BOOL) at:&flag];	// more-class flag
					if(!flag)
						break;
					[self decodeValueOfObjCType:@encode(Class) at:&otherClass];	// another class folows
					[self decodeValueOfObjCType:@encode(int) at:&version];
#if 0
					NSLog(@"versionForClass: %@ -> %d", NSStringFromClass(otherClass), version);
#endif
					[_classVersions setObject:[NSNumber numberWithInt:version] forKey:NSStringFromClass(otherClass)];	// save class version
				}
		}
#if 1	// Testing
	if(class == NSClassFromString(@"NSDistantObject"))
		obj=[[NSDistantObject alloc] initWithCoder:self];
	else
#endif
	if(class == [NSInvocation class])
		obj=[[self decodeInvocation] retain];	// special handling
	else if([class instancesRespondToSelector:@selector(_initWithPortCoder:)])
		obj=[[class alloc] _initWithPortCoder:self];	// this allows to define different encoding
	else
		obj=[[class alloc] initWithCoder:self];	// allocate and load new instance
	[self decodeValueOfObjCType:@encode(BOOL) at:&flag];	// always 0x01 (?) - appears to be 0x00 for a reply; and there may be another object if flag == 0x01
#if 1
	// almost always 1 - only seen as 0 in some NSInvocation and then the invocation has less data
	NSLog(@"flag3=%d %@", flag, [self _location]);
#endif
	[_classVersions release];
	_classVersions=savedClassVersions;
	if(!obj)
		[NSException raise:NSGenericException format:@"decodeRetainedObject: class %@ not instantiated %@", NSStringFromClass(class), [self _location]];
	return obj;
}

- (void) encodeObject:(id) obj isBycopy:(BOOL) isBycopy isByref:(BOOL) isByref;
{
	_isBycopy=isBycopy;
	_isByref=isByref;
	[self encodeObject:obj];
}

- (void) authenticateWithDelegate:(id) delegate;
{
	if(delegate && [delegate respondsToSelector:@selector(authenticationDataForComponents:)])
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
			// FIXME: what do we do with the other components?
			NSData *data=[components objectAtIndex:len-1];	// split
			return [delegate authenticateComponents:components withData:data];
			}
		NSLog(@"no authentication data received");
		// [NSException raise:NSFailedAuthenticationException format:@"did receive message without authentication"];
		}
	return YES;
}

@end

#ifndef __APPLE__	// must be disabled if we try to run on Cocoa Foundation because calling proxyWithLocal does not work well...
@implementation NSObject (NSPortCoder)

+ (int) _versionForPortCoder; { return 0; }	// default version

- (Class) classForPortCoder { return [self classForCoder]; }

- (id) replacementObjectForPortCoder:(NSPortCoder*)coder
{ // default is to encode a local proxy
	id rep=[self replacementObjectForCoder:coder];
	if(rep)
		{
		rep=[NSDistantObject proxyWithLocal:rep connection:[coder connection]];	// this will be encoded and decoded into a remote proxy
#if 1
		NSLog(@"wrapped as NSDistantObject: %@", rep);
#endif
		}
	return rep;
}

@end
#endif

@implementation NSTimeZone (NSPortCoding) 

+ (int) _versionForPortCoder; { return 1; }

@end

@implementation NSString (NSPortCoding) 

+ (int) _versionForPortCoder; { return 1; }	// we use the encoding version #1 as UTF8-String (with length but without trailing 0!)

- (void) _encodeWithPortCoder:(NSCoder *) coder;
{
	const char *str=[self UTF8String];
	unsigned int len=strlen(str);
	[coder encodeValueOfObjCType:@encode(unsigned int) at:&len];
	[coder encodeArrayOfObjCType:@encode(char) count:len at:str];
}

- (id) _initWithPortCoder:(NSCoder *) coder;
{
	char *str;
	unsigned int len;
	if([coder versionForClassName:@"NSString"] != 1)
		[NSException raise:NSInvalidArgumentException format:@"Can't decode version %d of NSString", [coder versionForClassName:@"NSString"]];
	[coder decodeValueOfObjCType:@encode(unsigned int) at:&len];
#if 0
	NSLog(@"NSString initWithCoder len=%d", len);
#endif
	str=objc_malloc(len+1);
	[coder decodeArrayOfObjCType:@encode(char) count:len at:str];
	str[len]=0;
#if 0
	NSLog(@"UTF8=%s", str);
#endif
	self=[self initWithUTF8String:str];
	objc_free(str);
	return self;
}

@end

@implementation NSMethodSignature (NSPortCoding)

- (id) replacementObjectForPortCoder:(NSPortCoder*)coder { return self; }	// don't replace by another proxy, i.e. encode invocations bycopy

@end

@implementation NSInvocation (NSPortCoding)

- (id) replacementObjectForPortCoder:(NSPortCoder*)coder { return self; }	// don't replace by another proxy, i.e. encode invocations bycopy

@end

@implementation NSPortMessage

/*
 Mach defines:
 port_t				NSPort object	type=2
 MSG_TYPE_BYTE		NSData object	type=1
 MSG_TYPE_CHAR	
 MSG_TYPE_INTEGER_32	
 
 According to experiments and descriptions in Amit Singh´s book, a message appears to look like this:
 
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
 FIXME/CHECKME:
 because we receive from untrustworthy sources here, we must protect against malformed headers trying to create buffer overflows and Denial of Service.
 This might also be some very large constant for record length which wraps around the 32bit address limit (e.g. a negative record length). This would
 end up in infinite loops blocking or crashing the application or service.
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
#if 1
				NSLog(@"decoded _send addr %@ %p", addr, addr);
#endif
				_send=[[NSPort _allocForProtocolFamily:port.family] initRemoteWithProtocolFamily:port.family socketType:port.type protocol:port.protocol address:addr];
#if 1
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
#if 1
				NSLog(@"decoded _recv addr %@ %p", addr, addr);
#endif
				_recv=[[NSPort _allocForProtocolFamily:port.family] initRemoteWithProtocolFamily:port.family socketType:port.type protocol:port.protocol address:addr];
#if 1
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
#if 1
						NSLog(@"length error: pos=%u len=%u remaining=%u", bp-(char *) buffer, record.len, end-bp);
#endif
						[self release];
						return nil;
					}
				switch(record.type) {
					case 1: { // NSData
#if 0
						NSLog(@"decode component with length %u", record.len); 
#endif
						[_components addObject:[NSData dataWithBytes:bp length:record.len]];	// cut out and save a copy of the data fragment
						break;
					}
					case 2: { // decode NSPort
						NSData *addr;
						NSPort *p=nil;
						memcpy(&port, bp, sizeof(port));
						if(bp+sizeof(port)+port.len > end)
							{ // goes beyond total length
								[self release];
								return nil;
							}
						addr=[NSData dataWithBytesNoCopy:bp+sizeof(port) length:port.len freeWhenDone:NO];
#if 1
						NSLog(@"decode NSPort family=%u addr=%@ %p", port.family, addr, addr);
#endif
						p=[[NSPort _allocForProtocolFamily:port.family] initRemoteWithProtocolFamily:port.family socketType:port.type protocol:port.protocol address:addr];
						[_components addObject:p];
						[p release];
						break;
					}
					default: {
#if 1
						NSLog(@"unexpected record type %u at pos=%u", record.type, bp-(char *) buffer);
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
#if 1
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
		[NSException raise:NSInvalidReceivePortException format:@"no receive port for message %@", self];
#if 0
	NSLog(@"send NSPortMessage: %@ on %@", _components, _send);
#endif
	return [_send sendBeforeDate:when msgid:_msgid components:_components from:_recv reserved:[_send reservedSpaceLength]];
}

@end
