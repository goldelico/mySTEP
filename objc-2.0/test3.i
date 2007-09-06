





























































typedef __signed char		__int8_t;
typedef unsigned char		__uint8_t;
typedef	short			__int16_t;
typedef	unsigned short		__uint16_t;
typedef int			__int32_t;
typedef unsigned int		__uint32_t;
typedef long long		__int64_t;
typedef unsigned long long	__uint64_t;

typedef long			__darwin_intptr_t;
typedef unsigned int		__darwin_natural_t;



typedef int			__darwin_ct_rune_t;	


typedef union {
	char		__mbstate8[128];
	long long	_mbstateL;			
} __mbstate_t;

typedef __mbstate_t		__darwin_mbstate_t;	

typedef int	__darwin_ptrdiff_t;	

typedef long unsigned int		__darwin_size_t;	


typedef __builtin_va_list	__darwin_va_list;	





typedef int		__darwin_wchar_t;	




typedef __darwin_wchar_t	__darwin_rune_t;	


typedef int		__darwin_wint_t;	




typedef unsigned long		__darwin_clock_t;	
typedef __uint32_t		__darwin_socklen_t;	
typedef long			__darwin_ssize_t;	
typedef long			__darwin_time_t;	




struct mcontext;
struct mcontext64;



struct __darwin_pthread_handler_rec
{
	void           (*__routine)(void *);	
	void           *__arg;			
	struct __darwin_pthread_handler_rec *__next;
};
struct _opaque_pthread_attr_t { long __sig; char __opaque[36]; };
struct _opaque_pthread_cond_t { long __sig; char __opaque[24]; };
struct _opaque_pthread_condattr_t { long __sig; char __opaque[4]; };
struct _opaque_pthread_mutex_t { long __sig; char __opaque[40]; };
struct _opaque_pthread_mutexattr_t { long __sig; char __opaque[8]; };
struct _opaque_pthread_once_t { long __sig; char __opaque[4]; };
struct _opaque_pthread_rwlock_t { long __sig; char __opaque[124]; };
struct _opaque_pthread_rwlockattr_t { long __sig; char __opaque[12]; };
struct _opaque_pthread_t { long __sig; struct __darwin_pthread_handler_rec  *__cleanup_stack; char __opaque[596]; };




typedef	__int64_t	__darwin_blkcnt_t;	
typedef	__int32_t	__darwin_blksize_t;	
typedef __int32_t	__darwin_dev_t;		
typedef unsigned int	__darwin_fsblkcnt_t;	
typedef unsigned int	__darwin_fsfilcnt_t;	
typedef __uint32_t	__darwin_gid_t;		
typedef __uint32_t	__darwin_id_t;		
typedef __uint32_t	__darwin_ino_t;		
typedef __darwin_natural_t __darwin_mach_port_name_t; 
typedef __darwin_mach_port_name_t __darwin_mach_port_t; 
typedef struct mcontext *__darwin_mcontext_t;	
typedef struct mcontext64 *__darwin_mcontext64_t; 
typedef __uint16_t	__darwin_mode_t;	
typedef __int64_t	__darwin_off_t;		
typedef __int32_t	__darwin_pid_t;		
typedef struct _opaque_pthread_attr_t
			__darwin_pthread_attr_t; 
typedef struct _opaque_pthread_cond_t
			__darwin_pthread_cond_t; 
typedef struct _opaque_pthread_condattr_t
			__darwin_pthread_condattr_t; 
typedef unsigned long	__darwin_pthread_key_t;	
typedef struct _opaque_pthread_mutex_t
			__darwin_pthread_mutex_t; 
typedef struct _opaque_pthread_mutexattr_t
			__darwin_pthread_mutexattr_t; 
typedef struct _opaque_pthread_once_t
			__darwin_pthread_once_t; 
typedef struct _opaque_pthread_rwlock_t
			__darwin_pthread_rwlock_t; 
typedef struct _opaque_pthread_rwlockattr_t
			__darwin_pthread_rwlockattr_t; 
typedef struct _opaque_pthread_t
			*__darwin_pthread_t;	
typedef __uint32_t	__darwin_sigset_t;	
typedef __int32_t	__darwin_suseconds_t;	
typedef __uint32_t	__darwin_uid_t;		
typedef __uint32_t	__darwin_useconds_t;	
typedef	unsigned char	__darwin_uuid_t[16];


struct	sigaltstack
{
	void	*ss_sp;			
	__darwin_size_t ss_size;	
	int	ss_flags;		
};
typedef struct sigaltstack __darwin_stack_t;	


struct ucontext
{
	int		uc_onstack;
	__darwin_sigset_t	uc_sigmask;	
	__darwin_stack_t 	uc_stack;	
	struct ucontext	*uc_link;		
	__darwin_size_t	uc_mcsize;		
	__darwin_mcontext_t	uc_mcontext;	
};
typedef struct ucontext __darwin_ucontext_t;	

struct ucontext64 {
	int		uc_onstack;
	__darwin_sigset_t	uc_sigmask;	
	__darwin_stack_t 	uc_stack;	
	struct ucontext64 *uc_link;		
	__darwin_size_t	uc_mcsize;		
	__darwin_mcontext64_t uc_mcontext64;	
};
typedef struct ucontext64 __darwin_ucontext64_t; 


typedef	int		__darwin_nl_item;
typedef	int		__darwin_wctrans_t;
typedef	unsigned long	__darwin_wctype_t;




typedef	__darwin_size_t		size_t;

typedef __darwin_ssize_t	ssize_t;




void	*memchr(__const void *, int, size_t);
int	 memcmp(__const void *, __const void *, size_t);
void	*memcpy(void *, __const void *, size_t);
void	*memmove(void *, __const void *, size_t);
void	*memset(void *, int, size_t);
char	*stpcpy(char *, __const char *);
char	*strcasestr(__const char *, __const char *);
char	*strcat(char *, __const char *);
char	*strchr(__const char *, int);
int	 strcmp(__const char *, __const char *);
int	 strcoll(__const char *, __const char *);
char	*strcpy(char *, __const char *);
size_t	 strcspn(__const char *, __const char *);
char	*strerror(int);
int	 strerror_r(int, char *, size_t);
size_t	 strlen(__const char *);
char	*strncat(char *, __const char *, size_t);
int	 strncmp(__const char *, __const char *, size_t);
char	*strncpy(char *, __const char *, size_t);
char	*strnstr(__const char *, __const char *, size_t);
char	*strpbrk(__const char *, __const char *);
char	*strrchr(__const char *, int);
size_t	 strspn(__const char *, __const char *);
char	*strstr(__const char *, __const char *);
char	*strtok(char *, __const char *);
size_t	 strxfrm(char *, __const char *, size_t);


void	*memccpy(void *, __const void *, int, size_t);
char	*strtok_r(char *, __const char *, char **);
char	*strdup(__const char *);
int	 bcmp(__const void *, __const void *, size_t);
void	 bcopy(__const void *, void *, size_t);
void	 bzero(void *, size_t);
int	 ffs(int);
char	*index(__const char *, int);
char	*rindex(__const char *, int);
int	 strcasecmp(__const char *, __const char *);
size_t	 strlcat(char *, __const char *, size_t);
size_t	 strlcpy(char *, __const char *, size_t);
void	 strmode(int, char *);
int	 strncasecmp(__const char *, __const char *, size_t);
char	*strsep(char **, __const char *);
char	*strsignal(int sig);
void	 swab(__const void * , void * , ssize_t);








































































































    #define FOUNDATION_EXPORT extern

    #define FOUNDATION_IMPORT extern








// Copyright 1988-1996 NeXT Software, Inc.






typedef struct objc_class *Class;

typedef struct objc_object {
	Class isa;
} *id;

typedef struct objc_selector 	*SEL;    
typedef id 			(*IMP)(id, SEL, ...); 
typedef __signed char		BOOL; 
// BOOL is explicitly __signed so @encode(BOOL) == "c" rather than "C" 
// even if -funsigned-char is used.







typedef char *STR;

extern BOOL sel_isMapped(SEL sel);
extern __const char *sel_getName(SEL sel);
extern SEL sel_getUid(__const char *str);
extern SEL sel_registerName(__const char *str);
extern __const char *object_getClassName(id obj);
extern void *object_getIndexedIvars(id obj);


    typedef int arith_t;
    typedef unsigned uarith_t;











typedef __builtin_va_list __gnuc_va_list;















typedef __gnuc_va_list va_list;










typedef __signed char           int8_t;

typedef short                int16_t;

typedef int                  int32_t;

typedef long long            int64_t;

typedef unsigned char         uint8_t;

typedef unsigned short       uint16_t;

typedef unsigned int         uint32_t;

typedef unsigned long long   uint64_t;


typedef int8_t           int_least8_t;
typedef int16_t         int_least16_t;
typedef int32_t         int_least32_t;
typedef int64_t         int_least64_t;
typedef uint8_t         uint_least8_t;
typedef uint16_t       uint_least16_t;
typedef uint32_t       uint_least32_t;
typedef uint64_t       uint_least64_t;



typedef int8_t            int_fast8_t;
typedef int16_t          int_fast16_t;
typedef int32_t          int_fast32_t;
typedef int64_t          int_fast64_t;
typedef uint8_t          uint_fast8_t;
typedef uint16_t        uint_fast16_t;
typedef uint32_t        uint_fast32_t;
typedef uint64_t        uint_fast64_t;




typedef long   intptr_t;

typedef unsigned long   uintptr_t;



typedef long long int             intmax_t;

typedef long long unsigned int             uintmax_t;









   












                             















 













    #ifdef __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__
        #define MAC_OS_X_VERSION_MIN_REQUIRED __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__
    #else
        #if __ppc64__ || 1 || __x86_64__
            #define MAC_OS_X_VERSION_MIN_REQUIRED 1040
        #else
            #define MAC_OS_X_VERSION_MIN_REQUIRED 1010
        #endif
    #endif


    #if MAC_OS_X_VERSION_MIN_REQUIRED > 1040
        #define MAC_OS_X_VERSION_MAX_ALLOWED MAC_OS_X_VERSION_MIN_REQUIRED
    #else
        #define MAC_OS_X_VERSION_MAX_ALLOWED 1040
    #endif


    #error MAC_OS_X_VERSION_MIN_REQUIRED must be >= 1000


    #define WEAK_IMPORT_ATTRIBUTE


    #define DEPRECATED_ATTRIBUTE __attribute__((deprecated))


    #define UNAVAILABLE_ATTRIBUTE __attribute__((unavailable))















    #define AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER     UNAVAILABLE_ATTRIBUTE


    #define AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED    AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER


    #define AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_1    


    #define DEPRECATED_IN_MAC_OS_X_VERSION_10_1_AND_LATER








    #define AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER     UNAVAILABLE_ATTRIBUTE


    #define AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED    AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER


    #define AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_2    


    #define AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_2    AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER


    #define DEPRECATED_IN_MAC_OS_X_VERSION_10_2_AND_LATER






    #define AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER     UNAVAILABLE_ATTRIBUTE


    #define AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED    AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER


    #define AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_3    


    #define AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_3    AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER


    #define AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_3    AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER


    #define DEPRECATED_IN_MAC_OS_X_VERSION_10_3_AND_LATER







    #define AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER     UNAVAILABLE_ATTRIBUTE


    #define AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED    AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER


    #define AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_4    


    #define AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_4    AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER


    #define AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_4    AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER


    #define AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_4    AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER


    #define DEPRECATED_IN_MAC_OS_X_VERSION_10_4_AND_LATER




FOUNDATION_EXPORT double NSFoundationVersionNumber;


@class NSString;

FOUNDATION_EXPORT NSString *NSStringFromSelector(SEL aSelector);
FOUNDATION_EXPORT SEL NSSelectorFromString(NSString *aSelectorName);
FOUNDATION_EXPORT Class NSClassFromString(NSString *aClassName);
FOUNDATION_EXPORT NSString *NSStringFromClass(Class aClass);
FOUNDATION_EXPORT __const char *NSGetSizeAndAlignment(__const char *typePtr, unsigned int *sizep, unsigned int *alignp);

FOUNDATION_EXPORT void NSLog(NSString *format, ...);
FOUNDATION_EXPORT void NSLogv(NSString *format, va_list args);

typedef enum _NSComparisonResult {NSOrderedAscending = -1, NSOrderedSame, NSOrderedDescending} NSComparisonResult;

enum {NSNotFound = 0x7fffffff};






    #define MIN(A,B)	({ __typeof__(A) __a = (A); __typeof__(B) __b = (B); __a < __b ? __a : __b; })

    #define MAX(A,B)	({ __typeof__(A) __a = (A); __typeof__(B) __b = (B); __a < __b ? __b : __a; })

    #define ABS(A)	({ __typeof__(A) __a = (A); __a < 0 ? -__a : __a; })





@class NSString;

typedef struct _NSZone NSZone;


FOUNDATION_EXPORT NSZone *NSDefaultMallocZone(void);
FOUNDATION_EXPORT NSZone *NSCreateZone(unsigned startSize, unsigned granularity, BOOL canFree);
FOUNDATION_EXPORT void NSRecycleZone(NSZone *zone);
FOUNDATION_EXPORT void NSSetZoneName(NSZone *zone, NSString *name);
FOUNDATION_EXPORT NSString *NSZoneName(NSZone *zone);
FOUNDATION_EXPORT NSZone *NSZoneFromPointer(void *ptr);

FOUNDATION_EXPORT void *NSZoneMalloc(NSZone *zone, unsigned size);
FOUNDATION_EXPORT void *NSZoneCalloc(NSZone *zone, unsigned numElems, unsigned byteSize);
FOUNDATION_EXPORT void *NSZoneRealloc(NSZone *zone, void *ptr, unsigned size);
FOUNDATION_EXPORT void NSZoneFree(NSZone *zone, void *ptr);

enum {
    NSScannedOption = (1<<0)
};

FOUNDATION_EXPORT void *NSAllocateCollectable(unsigned long size, unsigned long options) AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;
FOUNDATION_EXPORT void *NSReallocateCollectable(void *ptr, unsigned long size, unsigned long options) AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;

FOUNDATION_EXPORT unsigned NSPageSize(void);
FOUNDATION_EXPORT unsigned NSLogPageSize(void);
FOUNDATION_EXPORT unsigned NSRoundUpToMultipleOfPageSize(unsigned bytes);
FOUNDATION_EXPORT unsigned NSRoundDownToMultipleOfPageSize(unsigned bytes);
FOUNDATION_EXPORT void *NSAllocateMemoryPages(unsigned bytes);
FOUNDATION_EXPORT void NSDeallocateMemoryPages(void *ptr, unsigned bytes);
FOUNDATION_EXPORT void NSCopyMemoryPages(__const void *source, void *dest, unsigned bytes);
FOUNDATION_EXPORT unsigned NSRealMemoryAvailable(void);


@class NSInvocation, NSMethodSignature, NSCoder, NSString, NSEnumerator;
@class Protocol;



@protocol NSObject

- (BOOL)isEqual:(id)object;
- (unsigned)hash;

- (Class)superclass;
- (Class)class;
- (id)self;
- (NSZone *)zone;

- (id)performSelector:(SEL)aSelector;
- (id)performSelector:(SEL)aSelector withObject:(id)object;
- (id)performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2;

- (BOOL)isProxy;

- (BOOL)isKindOfClass:(Class)aClass;
- (BOOL)isMemberOfClass:(Class)aClass;
- (BOOL)conformsToProtocol:(Protocol *)aProtocol;

- (BOOL)respondsToSelector:(SEL)aSelector;

- (id)retain;
- (oneway void)release;
- (id)autorelease;
- (unsigned)retainCount;

- (NSString *)description;

@end

@protocol NSCopying

- (id)copyWithZone:(NSZone *)zone;

@end

@protocol NSMutableCopying

- (id)mutableCopyWithZone:(NSZone *)zone;

@end

@protocol NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end



@interface NSObject <NSObject> {
    Class	isa;
}

+ (void)load;

+ (void)initialize;
- (id)init;

+ (id)new;
+ (id)allocWithZone:(NSZone *)zone;
+ (id)alloc;
- (void)dealloc;


- (id)copy;
- (id)mutableCopy;

+ (id)copyWithZone:(NSZone *)zone;
+ (id)mutableCopyWithZone:(NSZone *)zone;

+ (Class)superclass;
+ (Class)class;
+ (void)poseAsClass:(Class)aClass;
+ (BOOL)instancesRespondToSelector:(SEL)aSelector;
+ (BOOL)conformsToProtocol:(Protocol *)protocol;
- (IMP)methodForSelector:(SEL)aSelector;
+ (IMP)instanceMethodForSelector:(SEL)aSelector;
+ (int)version;
+ (void)setVersion:(int)aVersion;
- (void)doesNotRecognizeSelector:(SEL)aSelector;
- (void)forwardInvocation:(NSInvocation *)anInvocation;
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector;

+ (NSMethodSignature *)instanceMethodSignatureForSelector:(SEL)aSelector;


+ (NSString *)description;

- (Class)classForCoder;
- (id)replacementObjectForCoder:(NSCoder *)aCoder;
- (id)awakeAfterUsingCoder:(NSCoder *)aDecoder;

@end


    
FOUNDATION_EXPORT id <NSObject> NSAllocateObject(Class aClass, unsigned extraBytes, NSZone *zone);

FOUNDATION_EXPORT void NSDeallocateObject(id <NSObject>object);

FOUNDATION_EXPORT id <NSObject> NSCopyObject(id <NSObject>object, unsigned extraBytes, NSZone *zone);

FOUNDATION_EXPORT BOOL NSShouldRetainWithZone(id <NSObject> anObject, NSZone *requestedZone);

FOUNDATION_EXPORT void NSIncrementExtraRefCount(id object);

FOUNDATION_EXPORT BOOL NSDecrementExtraRefCountWasZero(id object);

FOUNDATION_EXPORT unsigned NSExtraRefCount(id object);







@class NSString, NSDictionary;

@interface NSValue : NSObject <NSCopying, NSCoding>

- (void)getValue:(void *)value;
- (__const char *)objCType;

@end

@interface NSValue (NSValueCreation)

- (id)initWithBytes:(__const void *)value objCType:(__const char *)type;
+ (NSValue *)valueWithBytes:(__const void *)value objCType:(__const char *)type;
+ (NSValue *)value:(__const void *)value withObjCType:(__const char *)type;

@end

@interface NSValue (NSValueExtensionMethods)

+ (NSValue *)valueWithNonretainedObject:(id)anObject;
- (id)nonretainedObjectValue;

+ (NSValue *)valueWithPointer:(__const void *)pointer;
- (void *)pointerValue;

- (BOOL)isEqualToValue:(NSValue *)value;

@end

@interface NSNumber : NSValue

- (char)charValue;
- (unsigned char)unsignedCharValue;
- (short)shortValue;
- (unsigned short)unsignedShortValue;
- (int)intValue;
- (unsigned int)unsignedIntValue;
- (long)longValue;
- (unsigned long)unsignedLongValue;
- (long long)longLongValue;
- (unsigned long long)unsignedLongLongValue;
- (float)floatValue;
- (double)doubleValue;
- (BOOL)boolValue;
- (NSString *)stringValue;

- (NSComparisonResult)compare:(NSNumber *)otherNumber;

- (BOOL)isEqualToNumber:(NSNumber *)number;

- (NSString *)descriptionWithLocale:(NSDictionary *)locale;

@end

@interface NSNumber (NSNumberCreation)

- (id)initWithChar:(char)value;
- (id)initWithUnsignedChar:(unsigned char)value;
- (id)initWithShort:(short)value;
- (id)initWithUnsignedShort:(unsigned short)value;
- (id)initWithInt:(int)value;
- (id)initWithUnsignedInt:(unsigned int)value;
- (id)initWithLong:(long)value;
- (id)initWithUnsignedLong:(unsigned long)value;
- (id)initWithLongLong:(long long)value;
- (id)initWithUnsignedLongLong:(unsigned long long)value;
- (id)initWithFloat:(float)value;
- (id)initWithDouble:(double)value;
- (id)initWithBool:(BOOL)value;

+ (NSNumber *)numberWithChar:(char)value;
+ (NSNumber *)numberWithUnsignedChar:(unsigned char)value;
+ (NSNumber *)numberWithShort:(short)value;
+ (NSNumber *)numberWithUnsignedShort:(unsigned short)value;
+ (NSNumber *)numberWithInt:(int)value;
+ (NSNumber *)numberWithUnsignedInt:(unsigned int)value;
+ (NSNumber *)numberWithLong:(long)value;
+ (NSNumber *)numberWithUnsignedLong:(unsigned long)value;
+ (NSNumber *)numberWithLongLong:(long long)value;
+ (NSNumber *)numberWithUnsignedLongLong:(unsigned long long)value;
+ (NSNumber *)numberWithFloat:(float)value;
+ (NSNumber *)numberWithDouble:(double)value;
+ (NSNumber *)numberWithBool:(BOOL)value;

@end


@class NSString;

typedef struct _NSRange {
    unsigned int location;
    unsigned int length;
} NSRange;

typedef NSRange *NSRangePointer;

static __inline__ __attribute__((always_inline)) NSRange NSMakeRange(unsigned int loc, unsigned int len) {
    NSRange r;
    r.location = loc;
    r.length = len;
    return r;
}

static __inline__ __attribute__((always_inline)) unsigned int NSMaxRange(NSRange range) {
    return (range.location + range.length);
}

static __inline__ __attribute__((always_inline)) BOOL NSLocationInRange(unsigned int loc, NSRange range) {
    return (loc - range.location < range.length);
}

static __inline__ __attribute__((always_inline)) BOOL NSEqualRanges(NSRange range1, NSRange range2) {
    return (range1.location == range2.location && range1.length == range2.length);
}

FOUNDATION_EXPORT NSRange NSUnionRange(NSRange range1, NSRange range2);
FOUNDATION_EXPORT NSRange NSIntersectionRange(NSRange range1, NSRange range2);
FOUNDATION_EXPORT NSString *NSStringFromRange(NSRange range);
FOUNDATION_EXPORT NSRange NSRangeFromString(NSString *aString);

@interface NSValue (NSValueRangeExtensions)

+ (NSValue *)valueWithRange:(NSRange)range;
- (NSRange)rangeValue;

@end


@class NSData, NSDictionary, NSEnumerator, NSIndexSet, NSString, NSURL;



@interface NSArray : NSObject <NSCopying, NSMutableCopying, NSCoding>

- (unsigned)count;
- (id)objectAtIndex:(unsigned)index;
    
@end

@interface NSArray (NSExtendedArray)

- (NSArray *)arrayByAddingObject:(id)anObject;
- (NSArray *)arrayByAddingObjectsFromArray:(NSArray *)otherArray;
- (NSString *)componentsJoinedByString:(NSString *)separator;
- (BOOL)containsObject:(id)anObject;
- (NSString *)description;
- (NSString *)descriptionWithLocale:(NSDictionary *)locale;
- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(unsigned)level;
- (id)firstObjectCommonWithArray:(NSArray *)otherArray;
- (void)getObjects:(id *)objects;
- (void)getObjects:(id *)objects range:(NSRange)range;
- (unsigned)indexOfObject:(id)anObject;
- (unsigned)indexOfObject:(id)anObject inRange:(NSRange)range;
- (unsigned)indexOfObjectIdenticalTo:(id)anObject;
- (unsigned)indexOfObjectIdenticalTo:(id)anObject inRange:(NSRange)range;
- (BOOL)isEqualToArray:(NSArray *)otherArray;
- (id)lastObject;
- (NSEnumerator *)objectEnumerator;
- (NSEnumerator *)reverseObjectEnumerator;
- (NSData *)sortedArrayHint;
- (NSArray *)sortedArrayUsingFunction:(int (*)(id, id, void *))comparator context:(void *)context;
- (NSArray *)sortedArrayUsingFunction:(int (*)(id, id, void *))comparator context:(void *)context hint:(NSData *)hint;
- (NSArray *)sortedArrayUsingSelector:(SEL)comparator;
- (NSArray *)subarrayWithRange:(NSRange)range;
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile;
- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)atomically;

- (void)makeObjectsPerformSelector:(SEL)aSelector;
- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)argument;


@end

@interface NSArray (NSArrayCreation)

+ (id)array;
+ (id)arrayWithContentsOfFile:(NSString *)path;
+ (id)arrayWithContentsOfURL:(NSURL *)url;
+ (id)arrayWithObject:(id)anObject;
+ (id)arrayWithObjects:(id)firstObj, ...;
- (id)initWithArray:(NSArray *)array;
- (id)initWithContentsOfFile:(NSString *)path;
- (id)initWithContentsOfURL:(NSURL *)url;
- (id)initWithObjects:(id *)objects count:(unsigned)count;
- (id)initWithObjects:(id)firstObj, ...;

+ (id)arrayWithArray:(NSArray *)array;
+ (id)arrayWithObjects:(id *)objs count:(unsigned)cnt;

@end



@interface NSMutableArray : NSArray

- (void)addObject:(id)anObject;
- (void)insertObject:(id)anObject atIndex:(unsigned)index;
- (void)removeLastObject;
- (void)removeObjectAtIndex:(unsigned)index;
- (void)replaceObjectAtIndex:(unsigned)index withObject:(id)anObject;

@end

@interface NSMutableArray (NSExtendedMutableArray)
    
- (void)addObjectsFromArray:(NSArray *)otherArray;
- (void)exchangeObjectAtIndex:(unsigned)idx1 withObjectAtIndex:(unsigned)idx2;
- (void)removeAllObjects;
- (void)removeObject:(id)anObject inRange:(NSRange)range;
- (void)removeObject:(id)anObject;
- (void)removeObjectIdenticalTo:(id)anObject inRange:(NSRange)range;
- (void)removeObjectIdenticalTo:(id)anObject;
- (void)removeObjectsFromIndices:(unsigned *)indices numIndices:(unsigned)count;
- (void)removeObjectsInArray:(NSArray *)otherArray;
- (void)removeObjectsInRange:(NSRange)range;
- (void)replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray *)otherArray range:(NSRange)otherRange;
- (void)replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray *)otherArray;
- (void)setArray:(NSArray *)otherArray;
- (void)sortUsingFunction:(int (*)(id, id, void *))compare context:(void *)context;
- (void)sortUsingSelector:(SEL)comparator;


@end

@interface NSMutableArray (NSMutableArrayCreation)

+ (id)arrayWithCapacity:(unsigned)numItems;
- (id)initWithCapacity:(unsigned)numItems;

@end




@class NSString, NSData;

@interface NSCoder : NSObject

- (void)encodeValueOfObjCType:(__const char *)type at:(__const void *)addr;
- (void)encodeDataObject:(NSData *)data;
- (void)decodeValueOfObjCType:(__const char *)type at:(void *)data;
- (NSData *)decodeDataObject;
- (unsigned)versionForClassName:(NSString *)className;

@end

@interface NSCoder (NSExtendedCoder)
    
- (void)encodeObject:(id)object;
- (void)encodePropertyList:(id)aPropertyList;
- (void)encodeRootObject:(id)rootObject;
- (void)encodeBycopyObject:(id)anObject;
- (void)encodeByrefObject:(id)anObject;
- (void)encodeConditionalObject:(id)object;
- (void)encodeValuesOfObjCTypes:(__const char *)types, ...;
- (void)encodeArrayOfObjCType:(__const char *)type count:(unsigned)count at:(__const void *)array;
- (void)encodeBytes:(__const void *)byteaddr length:(unsigned)length;

- (id)decodeObject;
- (id)decodePropertyList;
- (void)decodeValuesOfObjCTypes:(__const char *)types, ...;
- (void)decodeArrayOfObjCType:(__const char *)itemType count:(unsigned)count at:(void *)array;
- (void *)decodeBytesWithReturnedLength:(unsigned *)lengthp;

- (void)setObjectZone:(NSZone *)zone;
- (NSZone *)objectZone;

- (unsigned)systemVersion;


@end

FOUNDATION_EXPORT NSObject *NXReadNSObjectFromCoder(NSCoder *decoder);


@interface NSCoder (NSTypedstreamCompatibility)

- (void)encodeNXObject:(id)object;

    
- (id)decodeNXObject;


@end



typedef unsigned short unichar;


@class NSData, NSArray, NSDictionary, NSCharacterSet, NSData, NSURL, NSError;

FOUNDATION_EXPORT NSString * __const NSParseErrorException; // raised by -propertyList



enum {
    NSCaseInsensitiveSearch = 1,
    NSLiteralSearch = 2,		
    NSBackwardsSearch = 4,		
    NSAnchoredSearch = 8,		
    NSNumericSearch = 64		
};


typedef unsigned NSStringEncoding;

enum {
    NSASCIIStringEncoding = 1,		
    NSNEXTSTEPStringEncoding = 2,
    NSJapaneseEUCStringEncoding = 3,
    NSUTF8StringEncoding = 4,
    NSISOLatin1StringEncoding = 5,
    NSSymbolStringEncoding = 6,
    NSNonLossyASCIIStringEncoding = 7,
    NSShiftJISStringEncoding = 8,
    NSISOLatin2StringEncoding = 9,
    NSUnicodeStringEncoding = 10,
    NSWindowsCP1251StringEncoding = 11,    
    NSWindowsCP1252StringEncoding = 12,    
    NSWindowsCP1253StringEncoding = 13,    
    NSWindowsCP1254StringEncoding = 14,    
    NSWindowsCP1250StringEncoding = 15,    
    NSISO2022JPStringEncoding = 21,         
    NSMacOSRomanStringEncoding = 30,

    NSProprietaryStringEncoding = 65536    
};

FOUNDATION_EXPORT NSString * __const NSCharacterConversionException;

@interface NSString : NSObject <NSCopying, NSMutableCopying, NSCoding>


- (unsigned int)length;			
- (unichar)characterAtIndex:(unsigned)index;

@end

@interface NSString (NSStringExtensionMethods)

- (void)getCharacters:(unichar *)buffer;
- (void)getCharacters:(unichar *)buffer range:(NSRange)aRange;

- (NSString *)substringFromIndex:(unsigned)from;
- (NSString *)substringToIndex:(unsigned)to;
- (NSString *)substringWithRange:(NSRange)range;

- (NSComparisonResult)compare:(NSString *)string;
- (NSComparisonResult)compare:(NSString *)string options:(unsigned)mask;
- (NSComparisonResult)compare:(NSString *)string options:(unsigned)mask range:(NSRange)compareRange;
- (NSComparisonResult)compare:(NSString *)string options:(unsigned)mask range:(NSRange)compareRange locale:(NSDictionary *)dict;
- (NSComparisonResult)caseInsensitiveCompare:(NSString *)string;
- (NSComparisonResult)localizedCompare:(NSString *)string;
- (NSComparisonResult)localizedCaseInsensitiveCompare:(NSString *)string;

- (BOOL)isEqualToString:(NSString *)aString;

- (BOOL)hasPrefix:(NSString *)aString;
- (BOOL)hasSuffix:(NSString *)aString;


- (NSRange)rangeOfString:(NSString *)aString;
- (NSRange)rangeOfString:(NSString *)aString options:(unsigned)mask;
- (NSRange)rangeOfString:(NSString *)aString options:(unsigned)mask range:(NSRange)searchRange;


- (NSRange)rangeOfCharacterFromSet:(NSCharacterSet *)aSet;
- (NSRange)rangeOfCharacterFromSet:(NSCharacterSet *)aSet options:(unsigned int)mask;
- (NSRange)rangeOfCharacterFromSet:(NSCharacterSet *)aSet options:(unsigned int)mask range:(NSRange)searchRange;

- (NSRange)rangeOfComposedCharacterSequenceAtIndex:(unsigned)index;

- (NSString *)stringByAppendingString:(NSString *)aString;
- (NSString *)stringByAppendingFormat:(NSString *)format, ...;

- (double)doubleValue;
- (float)floatValue;
- (int)intValue;

- (NSArray *)componentsSeparatedByString:(NSString *)separator;

- (NSString *)commonPrefixWithString:(NSString *)aString options:(unsigned)mask;

- (NSString *)uppercaseString;
- (NSString *)lowercaseString;
- (NSString *)capitalizedString;


- (void)getLineStart:(unsigned *)startPtr end:(unsigned *)lineEndPtr contentsEnd:(unsigned *)contentsEndPtr forRange:(NSRange)range;
- (NSRange)lineRangeForRange:(NSRange)range;


- (NSString *)description;

- (unsigned)hash;



- (NSStringEncoding)fastestEncoding;    	// Result in O(1) time; a rough estimate
- (NSStringEncoding)smallestEncoding;   	// Result in O(n) time; the encoding in which the string is most compact

- (NSData *)dataUsingEncoding:(NSStringEncoding)encoding allowLossyConversion:(BOOL)lossy;
- (NSData *)dataUsingEncoding:(NSStringEncoding)encoding;

- (BOOL)canBeConvertedToEncoding:(NSStringEncoding)encoding;



- (__const char *)UTF8String;	// Convenience to return null-terminated UTF8 representation


+ (NSStringEncoding)defaultCStringEncoding;	// Should be rarely used

+ (__const NSStringEncoding *)availableStringEncodings;
+ (NSString *)localizedNameOfStringEncoding:(NSStringEncoding)encoding;




- (id)init;
- (id)initWithCharactersNoCopy:(unichar *)characters length:(unsigned)length freeWhenDone:(BOOL)freeBuffer;	
- (id)initWithCharacters:(__const unichar *)characters length:(unsigned)length;
- (id)initWithUTF8String:(__const char *)nullTerminatedCString;
- (id)initWithString:(NSString *)aString;
- (id)initWithFormat:(NSString *)format, ...;
- (id)initWithFormat:(NSString *)format arguments:(va_list)argList;
- (id)initWithFormat:(NSString *)format locale:(NSDictionary *)dict, ...;
- (id)initWithFormat:(NSString *)format locale:(NSDictionary *)dict arguments:(va_list)argList;
- (id)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding;
- (id)initWithBytes:(__const void *)bytes length:(unsigned)len encoding:(NSStringEncoding)encoding;

+ (id)string;
+ (id)stringWithString:(NSString *)string;
+ (id)stringWithCharacters:(__const unichar *)characters length:(unsigned)length;
+ (id)stringWithUTF8String:(__const char *)nullTerminatedCString;
+ (id)stringWithFormat:(NSString *)format, ...;
+ (id)localizedStringWithFormat:(NSString *)format, ...;



@end


@interface NSMutableString : NSString


- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)aString;

@end

@interface NSMutableString (NSMutableStringExtensionMethods)

- (void)insertString:(NSString *)aString atIndex:(unsigned)loc;
- (void)deleteCharactersInRange:(NSRange)range;
- (void)appendString:(NSString *)aString;
- (void)appendFormat:(NSString *)format, ...;
- (void)setString:(NSString *)aString;


- (id)initWithCapacity:(unsigned)capacity;
+ (id)stringWithCapacity:(unsigned)capacity;


@end



@interface NSString (NSExtendedStringPropertyListParsing)
    
- (id)propertyList;
- (NSDictionary *)propertyListFromStringsFileFormat;

@end



@interface NSString (NSStringDeprecated)


- (__const char *)cString;
- (__const char *)lossyCString;
- (unsigned)cStringLength;
- (void)getCString:(char *)bytes;
- (void)getCString:(char *)bytes maxLength:(unsigned)maxLength;	
- (void)getCString:(char *)bytes maxLength:(unsigned)maxLength range:(NSRange)aRange remainingRange:(NSRangePointer)leftoverRange;

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile;
- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)atomically;

- (id)initWithContentsOfFile:(NSString *)path;
- (id)initWithContentsOfURL:(NSURL *)url;
+ (id)stringWithContentsOfFile:(NSString *)path;
+ (id)stringWithContentsOfURL:(NSURL *)url;

- (id)initWithCStringNoCopy:(char *)bytes length:(unsigned)length freeWhenDone:(BOOL)freeBuffer;
- (id)initWithCString:(__const char *)bytes length:(unsigned)length;
- (id)initWithCString:(__const char *)bytes;	
+ (id)stringWithCString:(__const char *)bytes length:(unsigned)length;
+ (id)stringWithCString:(__const char *)bytes;

@end






@interface NSSimpleCString : NSString {
@protected
    char *bytes;
    unsigned int numBytes;
}
@end

@interface NSConstantString : NSSimpleCString
@end

extern void *_NSConstantStringClassReference;




@class NSArray;



@interface NSEnumerator : NSObject

- (id)nextObject;

@end

@interface NSEnumerator (NSExtendedEnumerator)

- (NSArray *)allObjects;

@end




















typedef int sig_atomic_t; 


















struct	sigcontext {
    int			sc_onstack;	
    int			sc_mask;	
    unsigned int	sc_eax;
    unsigned int	sc_ebx;
    unsigned int	sc_ecx;
    unsigned int	sc_edx;
    unsigned int	sc_edi;
    unsigned int	sc_esi;
    unsigned int	sc_ebp;
    unsigned int	sc_esp;
    unsigned int	sc_ss;
    unsigned int	sc_eflags;
    unsigned int	sc_eip;
    unsigned int	sc_cs;
    unsigned int	sc_ds;
    unsigned int	sc_es;
    unsigned int	sc_fs;
    unsigned int	sc_gs;
};










typedef int jmp_buf[(18)];
typedef int sigjmp_buf[(18) + 1];



extern int setjmp(jmp_buf env);
extern void longjmp(jmp_buf env, int val);

int	_setjmp(jmp_buf env);
void	_longjmp(jmp_buf, int val);
int sigsetjmp(sigjmp_buf env, int val);
void siglongjmp(sigjmp_buf env, int val);

void	longjmperror(void);





@class NSString, NSDictionary;



FOUNDATION_EXPORT NSString * __const NSGenericException;
FOUNDATION_EXPORT NSString * __const NSRangeException;
FOUNDATION_EXPORT NSString * __const NSInvalidArgumentException;
FOUNDATION_EXPORT NSString * __const NSInternalInconsistencyException;

FOUNDATION_EXPORT NSString * __const NSMallocException;

FOUNDATION_EXPORT NSString * __const NSObjectInaccessibleException;
FOUNDATION_EXPORT NSString * __const NSObjectNotAvailableException;
FOUNDATION_EXPORT NSString * __const NSDestinationInvalidException;
    
FOUNDATION_EXPORT NSString * __const NSPortTimeoutException;
FOUNDATION_EXPORT NSString * __const NSInvalidSendPortException;
FOUNDATION_EXPORT NSString * __const NSInvalidReceivePortException;
FOUNDATION_EXPORT NSString * __const NSPortSendException;
FOUNDATION_EXPORT NSString * __const NSPortReceiveException;

FOUNDATION_EXPORT NSString * __const NSOldStyleException;



@interface NSException : NSObject <NSCopying, NSCoding> {
    @private
    NSString		*name;
    NSString		*reason;
    NSDictionary	*userInfo;
    void		*reserved;
}

+ (NSException *)exceptionWithName:(NSString *)name reason:(NSString *)reason userInfo:(NSDictionary *)userInfo;
- (id)initWithName:(NSString *)aName reason:(NSString *)aReason userInfo:(NSDictionary *)aUserInfo;

- (NSString *)name;
- (NSString *)reason;
- (NSDictionary *)userInfo;

- (void)raise;

@end

@interface NSException (NSExceptionRaisingConveniences)

+ (void)raise:(NSString *)name format:(NSString *)format, ...;
+ (void)raise:(NSString *)name format:(NSString *)format arguments:(va_list)argList;

@end


typedef struct _NSHandler NSHandler;	

typedef struct _NSHandler2 {	
    jmp_buf _state;
    NSException *_exception;
    void *_others;
    void *_thread;
    void *_reserved1;
} NSHandler2;


FOUNDATION_EXPORT void _NSAddHandler2(NSHandler2 *handler);
FOUNDATION_EXPORT void _NSRemoveHandler2(NSHandler2 *handler);
FOUNDATION_EXPORT NSException *_NSExceptionObjectFromHandler2(NSHandler2 *handler);







typedef void NSUncaughtExceptionHandler(NSException *exception);

FOUNDATION_EXPORT NSUncaughtExceptionHandler *NSGetUncaughtExceptionHandler(void);
FOUNDATION_EXPORT void NSSetUncaughtExceptionHandler(NSUncaughtExceptionHandler *);

@class NSAssertionHandler;





 







 









@interface NSAssertionHandler : NSObject {
    @private
    void *_reserved;
}

+ (NSAssertionHandler *)currentHandler;

- (void)handleFailureInMethod:(SEL)selector object:(id)object file:(NSString *)fileName lineNumber:(int)line description:(NSString *)format,...;

- (void)handleFailureInFunction:(NSString *)functionName file:(NSString *)fileName lineNumber:(int)line description:(NSString *)format,...;

@end



@interface NSAutoreleasePool : NSObject {
@private
    void	*_token;
    void	*_reserved3;
    void	*_reserved2;
    void	*_reserved;
}

+ (void)addObject:(id)anObject;

- (void)addObject:(id)anObject;


@end

























    #if defined(__CF_USE_FRAMEWORK_INCLUDES__) || (defined(1) && !defined(__MWERKS__)) 
	#include <CoreServices/../Frameworks/CarbonCore.framework/Headers/MacTypes.h>
    #elif defined(__MWERKS__)
	#include <MacTypes.h>
    #endif

    typedef unsigned char           Boolean;
    typedef unsigned char           UInt8;
    typedef __signed char             SInt8;
    typedef unsigned short          UInt16;
    typedef __signed short            SInt16;
    typedef unsigned long           UInt32;
    typedef __signed long             SInt32;
    typedef uint64_t		    UInt64;
    typedef int64_t		    SInt64;
    typedef float                   Float32;
    typedef double                  Float64;
    typedef unsigned short          UniChar;
    typedef unsigned char *         StringPtr;
    typedef __const unsigned char *   ConstStringPtr;
    typedef unsigned char           Str255[256];
    typedef __const unsigned char *   ConstStr255Param;
    typedef SInt16                  OSErr;
    typedef SInt32                  OSStatus;
    typedef UInt32                  UTF32Char;
    typedef UInt16                  UTF16Char;
    typedef UInt8                   UTF8Char;




    #define TRUE	1

    #define FALSE	0


    #define CF_EXPORT extern

    #if defined(4) && (4 == 4) && !defined(DEBUG)
	#define CF_INLINE static __inline__ __attribute__((always_inline))
    #elif defined(4)
    #define CF_INLINE static __inline__
    #elif defined(__MWERKS__) || defined(__cplusplus)
	#define CF_INLINE static __inline
    #elif defined(_MSC_VER)
        #define CF_INLINE static __inline
    #elif defined(__WIN32__)
	#define CF_INLINE static __inline__
    #endif


CF_EXPORT double kCFCoreFoundationVersionNumber;



typedef UInt32 CFTypeID;
typedef UInt32 CFOptionFlags;
typedef UInt32 CFHashCode;
typedef SInt32 CFIndex;


typedef __const void * CFTypeRef;

typedef __const struct __CFString * CFStringRef;
typedef struct __CFString * CFMutableStringRef;


typedef CFTypeRef CFPropertyListRef;


typedef enum {
    kCFCompareLessThan = -1,
    kCFCompareEqualTo = 0,
    kCFCompareGreaterThan = 1
} CFComparisonResult;


typedef CFComparisonResult (*CFComparatorFunction)(__const void *val1, __const void *val2, void *context);



enum {
    kCFNotFound = -1
};



typedef struct {
    CFIndex location;
    CFIndex length;
} CFRange;



CF_EXPORT
CFRange __CFRangeMake(CFIndex loc, CFIndex len);





typedef __const struct __CFAllocator * CFAllocatorRef;


CF_EXPORT
__const CFAllocatorRef kCFAllocatorDefault;


CF_EXPORT
__const CFAllocatorRef kCFAllocatorSystemDefault;


CF_EXPORT
__const CFAllocatorRef kCFAllocatorMalloc;


CF_EXPORT
__const CFAllocatorRef kCFAllocatorMallocZone AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;


CF_EXPORT
__const CFAllocatorRef kCFAllocatorNull;


CF_EXPORT
__const CFAllocatorRef kCFAllocatorUseContext;

typedef __const void *	(*CFAllocatorRetainCallBack)(__const void *info);
typedef void		(*CFAllocatorReleaseCallBack)(__const void *info);
typedef CFStringRef	(*CFAllocatorCopyDescriptionCallBack)(__const void *info);
typedef void *		(*CFAllocatorAllocateCallBack)(CFIndex allocSize, CFOptionFlags hint, void *info);
typedef void *		(*CFAllocatorReallocateCallBack)(void *ptr, CFIndex newsize, CFOptionFlags hint, void *info);
typedef void		(*CFAllocatorDeallocateCallBack)(void *ptr, void *info);
typedef CFIndex		(*CFAllocatorPreferredSizeCallBack)(CFIndex size, CFOptionFlags hint, void *info);
typedef struct {
    CFIndex				version;
    void *				info;
    CFAllocatorRetainCallBack		retain;
    CFAllocatorReleaseCallBack		release;        
    CFAllocatorCopyDescriptionCallBack	copyDescription;
    CFAllocatorAllocateCallBack		allocate;
    CFAllocatorReallocateCallBack	reallocate;
    CFAllocatorDeallocateCallBack	deallocate;
    CFAllocatorPreferredSizeCallBack	preferredSize;
} CFAllocatorContext;

CF_EXPORT
CFTypeID	CFAllocatorGetTypeID(void);


CF_EXPORT
void CFAllocatorSetDefault(CFAllocatorRef allocator);

CF_EXPORT
CFAllocatorRef CFAllocatorGetDefault(void);

CF_EXPORT
CFAllocatorRef CFAllocatorCreate(CFAllocatorRef allocator, CFAllocatorContext *context);

CF_EXPORT
void *CFAllocatorAllocate(CFAllocatorRef allocator, CFIndex size, CFOptionFlags hint);

CF_EXPORT
void *CFAllocatorReallocate(CFAllocatorRef allocator, void *ptr, CFIndex newsize, CFOptionFlags hint);

CF_EXPORT
void CFAllocatorDeallocate(CFAllocatorRef allocator, void *ptr);

CF_EXPORT
CFIndex CFAllocatorGetPreferredSizeForSize(CFAllocatorRef allocator, CFIndex size, CFOptionFlags hint);

CF_EXPORT
void CFAllocatorGetContext(CFAllocatorRef allocator, CFAllocatorContext *context);




CF_EXPORT
CFTypeID CFGetTypeID(CFTypeRef cf);

CF_EXPORT
CFStringRef CFCopyTypeIDDescription(CFTypeID type_id);

CF_EXPORT
CFTypeRef CFRetain(CFTypeRef cf);

CF_EXPORT
void CFRelease(CFTypeRef cf);

CF_EXPORT
CFIndex CFGetRetainCount(CFTypeRef cf);

CF_EXPORT
CFTypeRef CFMakeCollectable(CFTypeRef cf) AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;

CF_EXPORT
Boolean CFEqual(CFTypeRef cf1, CFTypeRef cf2);

CF_EXPORT
CFHashCode CFHash(CFTypeRef cf);

CF_EXPORT
CFStringRef CFCopyDescription(CFTypeRef cf);

CF_EXPORT
CFAllocatorRef CFGetAllocator(CFTypeRef cf);







    
typedef __const struct __CFData * CFDataRef;
typedef struct __CFData * CFMutableDataRef;

CF_EXPORT
CFTypeID CFDataGetTypeID(void);

CF_EXPORT
CFDataRef CFDataCreate(CFAllocatorRef allocator, __const UInt8 *bytes, CFIndex length);

CF_EXPORT
CFDataRef CFDataCreateWithBytesNoCopy(CFAllocatorRef allocator, __const UInt8 *bytes, CFIndex length, CFAllocatorRef bytesDeallocator);
    

CF_EXPORT
CFDataRef CFDataCreateCopy(CFAllocatorRef allocator, CFDataRef theData);

CF_EXPORT
CFMutableDataRef CFDataCreateMutable(CFAllocatorRef allocator, CFIndex capacity);

CF_EXPORT
CFMutableDataRef CFDataCreateMutableCopy(CFAllocatorRef allocator, CFIndex capacity, CFDataRef theData);

CF_EXPORT
CFIndex CFDataGetLength(CFDataRef theData);

CF_EXPORT
__const UInt8 *CFDataGetBytePtr(CFDataRef theData);

CF_EXPORT
UInt8 *CFDataGetMutableBytePtr(CFMutableDataRef theData);

CF_EXPORT
void CFDataGetBytes(CFDataRef theData, CFRange range, UInt8 *buffer); 

CF_EXPORT
void CFDataSetLength(CFMutableDataRef theData, CFIndex length);

CF_EXPORT
void CFDataIncreaseLength(CFMutableDataRef theData, CFIndex extraLength);

CF_EXPORT
void CFDataAppendBytes(CFMutableDataRef theData, __const UInt8 *bytes, CFIndex length);

CF_EXPORT
void CFDataReplaceBytes(CFMutableDataRef theData, CFRange range, __const UInt8 *newBytes, CFIndex newLength);

CF_EXPORT
void CFDataDeleteBytes(CFMutableDataRef theData, CFRange range);














typedef __const void *	(*CFArrayRetainCallBack)(CFAllocatorRef allocator, __const void *value);
typedef void		(*CFArrayReleaseCallBack)(CFAllocatorRef allocator, __const void *value);
typedef CFStringRef	(*CFArrayCopyDescriptionCallBack)(__const void *value);
typedef Boolean		(*CFArrayEqualCallBack)(__const void *value1, __const void *value2);
typedef struct {
    CFIndex				version;
    CFArrayRetainCallBack		retain;
    CFArrayReleaseCallBack		release;
    CFArrayCopyDescriptionCallBack	copyDescription;
    CFArrayEqualCallBack		equal;
} CFArrayCallBacks;


CF_EXPORT
__const CFArrayCallBacks kCFTypeArrayCallBacks;


typedef void (*CFArrayApplierFunction)(__const void *value, void *context);


typedef __const struct __CFArray * CFArrayRef;


typedef struct __CFArray * CFMutableArrayRef;


CF_EXPORT
CFTypeID CFArrayGetTypeID(void);


CF_EXPORT
CFArrayRef CFArrayCreate(CFAllocatorRef allocator, __const void **values, CFIndex numValues, __const CFArrayCallBacks *callBacks);


CF_EXPORT
CFArrayRef CFArrayCreateCopy(CFAllocatorRef allocator, CFArrayRef theArray);


CF_EXPORT
CFMutableArrayRef CFArrayCreateMutable(CFAllocatorRef allocator, CFIndex capacity, __const CFArrayCallBacks *callBacks);


CF_EXPORT
CFMutableArrayRef CFArrayCreateMutableCopy(CFAllocatorRef allocator, CFIndex capacity, CFArrayRef theArray);


CF_EXPORT
CFIndex CFArrayGetCount(CFArrayRef theArray);


CF_EXPORT
CFIndex CFArrayGetCountOfValue(CFArrayRef theArray, CFRange range, __const void *value);


CF_EXPORT
Boolean CFArrayContainsValue(CFArrayRef theArray, CFRange range, __const void *value);


CF_EXPORT
__const void *CFArrayGetValueAtIndex(CFArrayRef theArray, CFIndex idx);


CF_EXPORT
void CFArrayGetValues(CFArrayRef theArray, CFRange range, __const void **values);


CF_EXPORT
void CFArrayApplyFunction(CFArrayRef theArray, CFRange range, CFArrayApplierFunction applier, void *context);


CF_EXPORT
CFIndex CFArrayGetFirstIndexOfValue(CFArrayRef theArray, CFRange range, __const void *value);


CF_EXPORT
CFIndex CFArrayGetLastIndexOfValue(CFArrayRef theArray, CFRange range, __const void *value);


CF_EXPORT
CFIndex CFArrayBSearchValues(CFArrayRef theArray, CFRange range, __const void *value, CFComparatorFunction comparator, void *context);


CF_EXPORT
void CFArrayAppendValue(CFMutableArrayRef theArray, __const void *value);


CF_EXPORT
void CFArrayInsertValueAtIndex(CFMutableArrayRef theArray, CFIndex idx, __const void *value);


CF_EXPORT
void CFArraySetValueAtIndex(CFMutableArrayRef theArray, CFIndex idx, __const void *value);


CF_EXPORT
void CFArrayRemoveValueAtIndex(CFMutableArrayRef theArray, CFIndex idx);


CF_EXPORT
void CFArrayRemoveAllValues(CFMutableArrayRef theArray);


CF_EXPORT
void CFArrayReplaceValues(CFMutableArrayRef theArray, CFRange range, __const void **newValues, CFIndex newCount);


CF_EXPORT
void CFArrayExchangeValuesAtIndices(CFMutableArrayRef theArray, CFIndex idx1, CFIndex idx2);


CF_EXPORT
void CFArraySortValues(CFMutableArrayRef theArray, CFRange range, CFComparatorFunction comparator, void *context);


CF_EXPORT
void CFArrayAppendArray(CFMutableArrayRef theArray, CFArrayRef otherArray, CFRange otherRange);











typedef __const void *	(*CFDictionaryRetainCallBack)(CFAllocatorRef allocator, __const void *value);
typedef void		(*CFDictionaryReleaseCallBack)(CFAllocatorRef allocator, __const void *value);
typedef CFStringRef	(*CFDictionaryCopyDescriptionCallBack)(__const void *value);
typedef Boolean		(*CFDictionaryEqualCallBack)(__const void *value1, __const void *value2);
typedef CFHashCode	(*CFDictionaryHashCallBack)(__const void *value);
typedef struct {
    CFIndex				version;
    CFDictionaryRetainCallBack		retain;
    CFDictionaryReleaseCallBack		release;
    CFDictionaryCopyDescriptionCallBack	copyDescription;
    CFDictionaryEqualCallBack		equal;
    CFDictionaryHashCallBack		hash;
} CFDictionaryKeyCallBacks;


CF_EXPORT
__const CFDictionaryKeyCallBacks kCFTypeDictionaryKeyCallBacks;


CF_EXPORT
__const CFDictionaryKeyCallBacks kCFCopyStringDictionaryKeyCallBacks;


typedef struct {
    CFIndex				version;
    CFDictionaryRetainCallBack		retain;
    CFDictionaryReleaseCallBack		release;
    CFDictionaryCopyDescriptionCallBack	copyDescription;
    CFDictionaryEqualCallBack		equal;
} CFDictionaryValueCallBacks;


CF_EXPORT
__const CFDictionaryValueCallBacks kCFTypeDictionaryValueCallBacks;


typedef void (*CFDictionaryApplierFunction)(__const void *key, __const void *value, void *context);


typedef __const struct __CFDictionary * CFDictionaryRef;


typedef struct __CFDictionary * CFMutableDictionaryRef;


CF_EXPORT
CFTypeID CFDictionaryGetTypeID(void);


CF_EXPORT
CFDictionaryRef CFDictionaryCreate(CFAllocatorRef allocator, __const void **keys, __const void **values, CFIndex numValues, __const CFDictionaryKeyCallBacks *keyCallBacks, __const CFDictionaryValueCallBacks *valueCallBacks);


CF_EXPORT
CFDictionaryRef CFDictionaryCreateCopy(CFAllocatorRef allocator, CFDictionaryRef theDict);


CF_EXPORT
CFMutableDictionaryRef CFDictionaryCreateMutable(CFAllocatorRef allocator, CFIndex capacity, __const CFDictionaryKeyCallBacks *keyCallBacks, __const CFDictionaryValueCallBacks *valueCallBacks);


CF_EXPORT
CFMutableDictionaryRef CFDictionaryCreateMutableCopy(CFAllocatorRef allocator, CFIndex capacity, CFDictionaryRef theDict);


CF_EXPORT
CFIndex CFDictionaryGetCount(CFDictionaryRef theDict);


CF_EXPORT
CFIndex CFDictionaryGetCountOfKey(CFDictionaryRef theDict, __const void *key);


CF_EXPORT
CFIndex CFDictionaryGetCountOfValue(CFDictionaryRef theDict, __const void *value);


CF_EXPORT
Boolean CFDictionaryContainsKey(CFDictionaryRef theDict, __const void *key);


CF_EXPORT
Boolean CFDictionaryContainsValue(CFDictionaryRef theDict, __const void *value);


CF_EXPORT
__const void *CFDictionaryGetValue(CFDictionaryRef theDict, __const void *key);


CF_EXPORT
Boolean CFDictionaryGetValueIfPresent(CFDictionaryRef theDict, __const void *key, __const void **value);


CF_EXPORT
void CFDictionaryGetKeysAndValues(CFDictionaryRef theDict, __const void **keys, __const void **values);


CF_EXPORT
void CFDictionaryApplyFunction(CFDictionaryRef theDict, CFDictionaryApplierFunction applier, void *context);


CF_EXPORT
void CFDictionaryAddValue(CFMutableDictionaryRef theDict, __const void *key, __const void *value);


CF_EXPORT
void CFDictionarySetValue(CFMutableDictionaryRef theDict, __const void *key, __const void *value);


CF_EXPORT
void CFDictionaryReplaceValue(CFMutableDictionaryRef theDict, __const void *key, __const void *value);


CF_EXPORT
void CFDictionaryRemoveValue(CFMutableDictionaryRef theDict, __const void *key);


CF_EXPORT
void CFDictionaryRemoveAllValues(CFMutableDictionaryRef theDict);











typedef __const struct __CFCharacterSet * CFCharacterSetRef;


typedef struct __CFCharacterSet * CFMutableCharacterSetRef;


typedef enum {
    kCFCharacterSetControl = 1, 
    kCFCharacterSetWhitespace, 
    kCFCharacterSetWhitespaceAndNewline,  
    kCFCharacterSetDecimalDigit, 
    kCFCharacterSetLetter, 
    kCFCharacterSetLowercaseLetter, 
    kCFCharacterSetUppercaseLetter, 
    kCFCharacterSetNonBase, 
    kCFCharacterSetDecomposable, 
    kCFCharacterSetAlphaNumeric, 
    kCFCharacterSetPunctuation, 
    kCFCharacterSetIllegal 
} CFCharacterSetPredefinedSet;


CF_EXPORT
CFTypeID CFCharacterSetGetTypeID(void);


CF_EXPORT
CFCharacterSetRef CFCharacterSetGetPredefined(CFCharacterSetPredefinedSet theSetIdentifier);


CF_EXPORT
CFCharacterSetRef CFCharacterSetCreateWithCharactersInRange(CFAllocatorRef alloc, CFRange theRange);


CF_EXPORT
CFCharacterSetRef CFCharacterSetCreateWithCharactersInString(CFAllocatorRef alloc, CFStringRef theString);


CF_EXPORT
CFCharacterSetRef CFCharacterSetCreateWithBitmapRepresentation(CFAllocatorRef alloc, CFDataRef theData);



CF_EXPORT
CFMutableCharacterSetRef CFCharacterSetCreateMutable(CFAllocatorRef alloc);



CF_EXPORT
CFMutableCharacterSetRef CFCharacterSetCreateMutableCopy(CFAllocatorRef alloc, CFCharacterSetRef theSet);


CF_EXPORT
Boolean CFCharacterSetIsCharacterMember(CFCharacterSetRef theSet, UniChar theChar);



CF_EXPORT
CFDataRef CFCharacterSetCreateBitmapRepresentation(CFAllocatorRef alloc, CFCharacterSetRef theSet);


CF_EXPORT
void CFCharacterSetAddCharactersInRange(CFMutableCharacterSetRef theSet, CFRange theRange);


CF_EXPORT
void CFCharacterSetRemoveCharactersInRange(CFMutableCharacterSetRef theSet, CFRange theRange);


CF_EXPORT
void CFCharacterSetAddCharactersInString(CFMutableCharacterSetRef theSet,  CFStringRef theString);


CF_EXPORT
void CFCharacterSetRemoveCharactersInString(CFMutableCharacterSetRef theSet, CFStringRef theString);


CF_EXPORT
void CFCharacterSetUnion(CFMutableCharacterSetRef theSet, CFCharacterSetRef theOtherSet);


CF_EXPORT
void CFCharacterSetIntersect(CFMutableCharacterSetRef theSet, CFCharacterSetRef theOtherSet);


CF_EXPORT
void CFCharacterSetInvert(CFMutableCharacterSetRef theSet);














typedef UInt32 CFStringEncoding;


typedef enum {
    kCFStringEncodingMacRoman = 0,
    kCFStringEncodingWindowsLatin1 = 0x0500, 
    kCFStringEncodingISOLatin1 = 0x0201, 
    kCFStringEncodingNextStepLatin = 0x0B01, 
    kCFStringEncodingASCII = 0x0600, 
    kCFStringEncodingUnicode = 0x0100, 
    kCFStringEncodingUTF8 = 0x08000100, 
    kCFStringEncodingNonLossyASCII = 0x0BFF 
} CFStringBuiltInEncodings;


CF_EXPORT
CFTypeID CFStringGetTypeID(void);








CF_EXPORT
CFStringRef CFStringCreateWithPascalString(CFAllocatorRef alloc, ConstStr255Param pStr, CFStringEncoding encoding);

CF_EXPORT
CFStringRef CFStringCreateWithCString(CFAllocatorRef alloc, __const char *cStr, CFStringEncoding encoding);

CF_EXPORT
CFStringRef CFStringCreateWithCharacters(CFAllocatorRef alloc, __const UniChar *chars, CFIndex numChars);


CF_EXPORT
CFStringRef CFStringCreateWithPascalStringNoCopy(CFAllocatorRef alloc, ConstStr255Param pStr, CFStringEncoding encoding, CFAllocatorRef contentsDeallocator);

CF_EXPORT
CFStringRef CFStringCreateWithCStringNoCopy(CFAllocatorRef alloc, __const char *cStr, CFStringEncoding encoding, CFAllocatorRef contentsDeallocator);

CF_EXPORT
CFStringRef CFStringCreateWithCharactersNoCopy(CFAllocatorRef alloc, __const UniChar *chars, CFIndex numChars, CFAllocatorRef contentsDeallocator);


CF_EXPORT
CFStringRef CFStringCreateWithSubstring(CFAllocatorRef alloc, CFStringRef str, CFRange range);

CF_EXPORT
CFStringRef CFStringCreateCopy(CFAllocatorRef alloc, CFStringRef theString);


CF_EXPORT
CFStringRef CFStringCreateWithFormat(CFAllocatorRef alloc, CFDictionaryRef formatOptions, CFStringRef format, ...);

CF_EXPORT
CFStringRef CFStringCreateWithFormatAndArguments(CFAllocatorRef alloc, CFDictionaryRef formatOptions, CFStringRef format, va_list arguments);


CF_EXPORT
CFMutableStringRef CFStringCreateMutable(CFAllocatorRef alloc, CFIndex maxLength);

CF_EXPORT
CFMutableStringRef CFStringCreateMutableCopy(CFAllocatorRef alloc, CFIndex maxLength, CFStringRef theString);


CF_EXPORT
CFMutableStringRef CFStringCreateMutableWithExternalCharactersNoCopy(CFAllocatorRef alloc, UniChar *chars, CFIndex numChars, CFIndex capacity, CFAllocatorRef externalCharactersAllocator);




CF_EXPORT
CFIndex CFStringGetLength(CFStringRef theString);


CF_EXPORT
UniChar CFStringGetCharacterAtIndex(CFStringRef theString, CFIndex idx);

CF_EXPORT
void CFStringGetCharacters(CFStringRef theString, CFRange range, UniChar *buffer);





CF_EXPORT
Boolean CFStringGetPascalString(CFStringRef theString, StringPtr buffer, CFIndex bufferSize, CFStringEncoding encoding);

CF_EXPORT
Boolean CFStringGetCString(CFStringRef theString, char *buffer, CFIndex bufferSize, CFStringEncoding encoding);


CF_EXPORT
ConstStringPtr CFStringGetPascalStringPtr(CFStringRef theString, CFStringEncoding encoding);	

CF_EXPORT
__const char *CFStringGetCStringPtr(CFStringRef theString, CFStringEncoding encoding);		

CF_EXPORT
__const UniChar *CFStringGetCharactersPtr(CFStringRef theString);					


CF_EXPORT
CFIndex CFStringGetBytes(CFStringRef theString, CFRange range, CFStringEncoding encoding, UInt8 lossByte, Boolean isExternalRepresentation, UInt8 *buffer, CFIndex maxBufLen, CFIndex *usedBufLen);


CF_EXPORT
CFStringRef CFStringCreateWithBytes(CFAllocatorRef alloc, __const UInt8 *bytes, CFIndex numBytes, CFStringEncoding encoding, Boolean isExternalRepresentation);


CF_EXPORT
CFStringRef CFStringCreateFromExternalRepresentation(CFAllocatorRef alloc, CFDataRef data, CFStringEncoding encoding);	

CF_EXPORT
CFDataRef CFStringCreateExternalRepresentation(CFAllocatorRef alloc, CFStringRef theString, CFStringEncoding encoding, UInt8 lossByte);		


CF_EXPORT
CFStringEncoding CFStringGetSmallestEncoding(CFStringRef theString);	

CF_EXPORT
CFStringEncoding CFStringGetFastestEncoding(CFStringRef theString);	


CF_EXPORT
CFStringEncoding CFStringGetSystemEncoding(void);		

CF_EXPORT
CFIndex CFStringGetMaximumSizeForEncoding(CFIndex length, CFStringEncoding encoding);	





CF_EXPORT
Boolean CFStringGetFileSystemRepresentation(CFStringRef string, char *buffer, CFIndex maxBufLen) AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;


CF_EXPORT
CFIndex CFStringGetMaximumSizeOfFileSystemRepresentation(CFStringRef string) AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;


CF_EXPORT
CFStringRef CFStringCreateWithFileSystemRepresentation(CFAllocatorRef alloc, __const char *buffer) AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;





typedef enum {	
    kCFCompareCaseInsensitive = 1,	
    kCFCompareBackwards = 4,		
    kCFCompareAnchored = 8,		
    kCFCompareNonliteral = 16,		
    kCFCompareLocalized = 32,		
    kCFCompareNumerically = 64		
} CFStringCompareFlags;	


CF_EXPORT
CFComparisonResult CFStringCompareWithOptions(CFStringRef theString1, CFStringRef theString2, CFRange rangeToCompare, CFOptionFlags compareOptions);


CF_EXPORT
CFComparisonResult CFStringCompare(CFStringRef theString1, CFStringRef theString2, CFOptionFlags compareOptions);


CF_EXPORT
Boolean CFStringFindWithOptions(CFStringRef theString, CFStringRef stringToFind, CFRange rangeToSearch, CFOptionFlags searchOptions, CFRange *result);


CF_EXPORT
CFArrayRef CFStringCreateArrayWithFindResults(CFAllocatorRef alloc, CFStringRef theString, CFStringRef stringToFind, CFRange rangeToSearch, CFOptionFlags compareOptions);


CF_EXPORT
CFRange CFStringFind(CFStringRef theString, CFStringRef stringToFind, CFOptionFlags compareOptions);

CF_EXPORT
Boolean CFStringHasPrefix(CFStringRef theString, CFStringRef prefix);

CF_EXPORT
Boolean CFStringHasSuffix(CFStringRef theString, CFStringRef suffix);



CF_EXPORT
void CFStringGetLineBounds(CFStringRef theString, CFRange range, CFIndex *lineBeginIndex, CFIndex *lineEndIndex, CFIndex *contentsEndIndex); 




CF_EXPORT
CFStringRef CFStringCreateByCombiningStrings(CFAllocatorRef alloc, CFArrayRef theArray, CFStringRef separatorString);	

CF_EXPORT
CFArrayRef CFStringCreateArrayBySeparatingStrings(CFAllocatorRef alloc, CFStringRef theString, CFStringRef separatorString);	




CF_EXPORT
SInt32 CFStringGetIntValue(CFStringRef str);		

CF_EXPORT
double CFStringGetDoubleValue(CFStringRef str);	





CF_EXPORT
void CFStringAppend(CFMutableStringRef theString, CFStringRef appendedString);

CF_EXPORT
void CFStringAppendCharacters(CFMutableStringRef theString, __const UniChar *chars, CFIndex numChars);

CF_EXPORT
void CFStringAppendPascalString(CFMutableStringRef theString, ConstStr255Param pStr, CFStringEncoding encoding);

CF_EXPORT
void CFStringAppendCString(CFMutableStringRef theString, __const char *cStr, CFStringEncoding encoding);

CF_EXPORT
void CFStringAppendFormat(CFMutableStringRef theString, CFDictionaryRef formatOptions, CFStringRef format, ...);

CF_EXPORT
void CFStringAppendFormatAndArguments(CFMutableStringRef theString, CFDictionaryRef formatOptions, CFStringRef format, va_list arguments);

CF_EXPORT
void CFStringInsert(CFMutableStringRef str, CFIndex idx, CFStringRef insertedStr);

CF_EXPORT
void CFStringDelete(CFMutableStringRef theString, CFRange range);

CF_EXPORT
void CFStringReplace(CFMutableStringRef theString, CFRange range, CFStringRef replacement);

CF_EXPORT
void CFStringReplaceAll(CFMutableStringRef theString, CFStringRef replacement);	



CF_EXPORT
void CFStringSetExternalCharactersNoCopy(CFMutableStringRef theString, UniChar *chars, CFIndex length, CFIndex capacity);	


CF_EXPORT
void CFStringPad(CFMutableStringRef theString, CFStringRef padString, CFIndex length, CFIndex indexIntoPad);

CF_EXPORT
void CFStringTrim(CFMutableStringRef theString, CFStringRef trimString);

CF_EXPORT
void CFStringTrimWhitespace(CFMutableStringRef theString);

CF_EXPORT
void CFStringLowercase(CFMutableStringRef theString, __const void *localeTBD); // localeTBD must be ((void *)0) on pre-10.3

CF_EXPORT
void CFStringUppercase(CFMutableStringRef theString, __const void *localeTBD); // localeTBD must be ((void *)0) on pre-10.3

CF_EXPORT
void CFStringCapitalize(CFMutableStringRef theString, __const void *localeTBD); // localeTBD must be ((void *)0) on pre-10.3



Boolean CFStringTransform(CFMutableStringRef string, CFRange *range, CFStringRef transform, Boolean reverse) AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;


CF_EXPORT __const CFStringRef kCFStringTransformStripCombiningMarks AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;
CF_EXPORT __const CFStringRef kCFStringTransformToLatin AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;
CF_EXPORT __const CFStringRef kCFStringTransformFullwidthHalfwidth AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;
CF_EXPORT __const CFStringRef kCFStringTransformLatinKatakana AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;
CF_EXPORT __const CFStringRef kCFStringTransformLatinHiragana AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;
CF_EXPORT __const CFStringRef kCFStringTransformHiraganaKatakana AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;
CF_EXPORT __const CFStringRef kCFStringTransformMandarinLatin AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;
CF_EXPORT __const CFStringRef kCFStringTransformLatinHangul AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;
CF_EXPORT __const CFStringRef kCFStringTransformLatinArabic AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;
CF_EXPORT __const CFStringRef kCFStringTransformLatinHebrew AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;
CF_EXPORT __const CFStringRef kCFStringTransformLatinThai AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;
CF_EXPORT __const CFStringRef kCFStringTransformLatinCyrillic AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;
CF_EXPORT __const CFStringRef kCFStringTransformLatinGreek AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;
CF_EXPORT __const CFStringRef kCFStringTransformToXMLHex AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;
CF_EXPORT __const CFStringRef kCFStringTransformToUnicodeName AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;





CF_EXPORT
Boolean CFStringIsEncodingAvailable(CFStringEncoding encoding);


CF_EXPORT
__const CFStringEncoding *CFStringGetListOfAvailableEncodings(void);


CF_EXPORT
CFStringRef CFStringGetNameOfEncoding(CFStringEncoding encoding);


CF_EXPORT
UInt32 CFStringConvertEncodingToNSStringEncoding(CFStringEncoding encoding);

CF_EXPORT
CFStringEncoding CFStringConvertNSStringEncodingToEncoding(UInt32 encoding);


CF_EXPORT
UInt32 CFStringConvertEncodingToWindowsCodepage(CFStringEncoding encoding);

CF_EXPORT
CFStringEncoding CFStringConvertWindowsCodepageToEncoding(UInt32 codepage);


CF_EXPORT
CFStringEncoding CFStringConvertIANACharSetNameToEncoding(CFStringRef theString);

CF_EXPORT
CFStringRef  CFStringConvertEncodingToIANACharSetName(CFStringEncoding encoding);





CF_EXPORT
CFStringEncoding CFStringGetMostCompatibleMacStringEncoding(CFStringEncoding encoding);




typedef struct {
    UniChar buffer[64];
    CFStringRef theString;
    __const UniChar *directBuffer;
    CFRange rangeToBuffer;		
    CFIndex bufferedRangeStart;		
    CFIndex bufferedRangeEnd;		
} CFStringInlineBuffer;











CF_EXPORT
void CFShow(CFTypeRef obj);

CF_EXPORT
void CFShowStr(CFStringRef str);


CF_EXPORT
CFStringRef  __CFStringMakeConstantString(__const char *cStr);	











typedef enum {
    kCFURLPOSIXPathStyle = 0,
    kCFURLHFSPathStyle,
    kCFURLWindowsPathStyle
} CFURLPathStyle;
    
typedef __const struct __CFURL * CFURLRef;















CF_EXPORT
CFTypeID CFURLGetTypeID(void);



CF_EXPORT
CFURLRef CFURLCreateWithBytes(CFAllocatorRef allocator, __const UInt8 *URLBytes, CFIndex length, CFStringEncoding encoding, CFURLRef baseURL);





CF_EXPORT
CFDataRef CFURLCreateData(CFAllocatorRef allocator, CFURLRef url, CFStringEncoding encoding, Boolean escapeWhitespace);


CF_EXPORT
CFURLRef CFURLCreateWithString(CFAllocatorRef allocator, CFStringRef URLString, CFURLRef baseURL);








CF_EXPORT
CFURLRef CFURLCreateWithFileSystemPath(CFAllocatorRef allocator, CFStringRef filePath, CFURLPathStyle pathStyle, Boolean isDirectory);

CF_EXPORT
CFURLRef CFURLCreateFromFileSystemRepresentation(CFAllocatorRef allocator, __const UInt8 *buffer, CFIndex bufLen, Boolean isDirectory);

CF_EXPORT
CFURLRef CFURLCreateWithFileSystemPathRelativeToBase(CFAllocatorRef allocator, CFStringRef filePath, CFURLPathStyle pathStyle, Boolean isDirectory, CFURLRef baseURL); 

CF_EXPORT
CFURLRef CFURLCreateFromFileSystemRepresentationRelativeToBase(CFAllocatorRef allocator, __const UInt8 *buffer, CFIndex bufLen, Boolean isDirectory, CFURLRef baseURL);
                                                                         







CF_EXPORT
Boolean CFURLGetFileSystemRepresentation(CFURLRef url, Boolean resolveAgainstBase, UInt8 *buffer, CFIndex maxBufLen);


CF_EXPORT
CFURLRef CFURLCopyAbsoluteURL(CFURLRef relativeURL);


CF_EXPORT
CFStringRef CFURLGetString(CFURLRef anURL);


CF_EXPORT
CFURLRef CFURLGetBaseURL(CFURLRef anURL);




CF_EXPORT
Boolean CFURLCanBeDecomposed(CFURLRef anURL); 



CF_EXPORT
CFStringRef CFURLCopyScheme(CFURLRef anURL);


CF_EXPORT
CFStringRef CFURLCopyNetLocation(CFURLRef anURL); 












CF_EXPORT
CFStringRef CFURLCopyPath(CFURLRef anURL);

CF_EXPORT
CFStringRef CFURLCopyStrictPath(CFURLRef anURL, Boolean *isAbsolute);

CF_EXPORT
CFStringRef CFURLCopyFileSystemPath(CFURLRef anURL, CFURLPathStyle pathStyle);



CF_EXPORT
Boolean CFURLHasDirectoryPath(CFURLRef anURL);



CF_EXPORT
CFStringRef CFURLCopyResourceSpecifier(CFURLRef anURL); 

CF_EXPORT
CFStringRef CFURLCopyHostName(CFURLRef anURL);

CF_EXPORT
SInt32 CFURLGetPortNumber(CFURLRef anURL); 

CF_EXPORT
CFStringRef CFURLCopyUserName(CFURLRef anURL);

CF_EXPORT
CFStringRef CFURLCopyPassword(CFURLRef anURL);






CF_EXPORT
CFStringRef CFURLCopyParameterString(CFURLRef anURL, CFStringRef charactersToLeaveEscaped);

CF_EXPORT
CFStringRef CFURLCopyQueryString(CFURLRef anURL, CFStringRef charactersToLeaveEscaped);

CF_EXPORT
CFStringRef CFURLCopyFragment(CFURLRef anURL, CFStringRef charactersToLeaveEscaped);

CF_EXPORT
CFStringRef CFURLCopyLastPathComponent(CFURLRef url);

CF_EXPORT
CFStringRef CFURLCopyPathExtension(CFURLRef url);





CF_EXPORT
CFURLRef CFURLCreateCopyAppendingPathComponent(CFAllocatorRef allocator, CFURLRef url, CFStringRef pathComponent, Boolean isDirectory);

CF_EXPORT
CFURLRef CFURLCreateCopyDeletingLastPathComponent(CFAllocatorRef allocator, CFURLRef url);

CF_EXPORT
CFURLRef CFURLCreateCopyAppendingPathExtension(CFAllocatorRef allocator, CFURLRef url, CFStringRef extension);

CF_EXPORT
CFURLRef CFURLCreateCopyDeletingPathExtension(CFAllocatorRef allocator, CFURLRef url);









CF_EXPORT
CFStringRef CFURLCreateStringByReplacingPercentEscapes(CFAllocatorRef allocator, CFStringRef originalString, CFStringRef charactersToLeaveEscaped);















CF_EXPORT
CFStringRef CFURLCreateStringByAddingPercentEscapes(CFAllocatorRef allocator, CFStringRef originalString, CFStringRef charactersToLeaveUnescaped, CFStringRef legalURLCharactersToBeEscaped, CFStringEncoding encoding);


struct FSRef;

CF_EXPORT
CFURLRef CFURLCreateFromFSRef(CFAllocatorRef allocator, __const struct FSRef *fsRef);

CF_EXPORT
Boolean CFURLGetFSRef(CFURLRef url, struct FSRef *fsRef);














typedef double CFTimeInterval;
typedef CFTimeInterval CFAbsoluteTime;



CF_EXPORT
CFAbsoluteTime CFAbsoluteTimeGetCurrent(void);

CF_EXPORT
__const CFTimeInterval kCFAbsoluteTimeIntervalSince1970;
CF_EXPORT
__const CFTimeInterval kCFAbsoluteTimeIntervalSince1904;

typedef __const struct __CFDate * CFDateRef;

CF_EXPORT
CFTypeID CFDateGetTypeID(void);

CF_EXPORT
CFDateRef CFDateCreate(CFAllocatorRef allocator, CFAbsoluteTime at);

CF_EXPORT
CFAbsoluteTime CFDateGetAbsoluteTime(CFDateRef theDate);

CF_EXPORT
CFTimeInterval CFDateGetTimeIntervalSinceDate(CFDateRef theDate, CFDateRef otherDate);

CF_EXPORT
CFComparisonResult CFDateCompare(CFDateRef theDate, CFDateRef otherDate, void *context);

typedef __const struct __CFTimeZone * CFTimeZoneRef;

typedef struct {
    SInt32 year;
    SInt8 month;
    SInt8 day;
    SInt8 hour;
    SInt8 minute;
    double second;
} CFGregorianDate;

typedef struct {
    SInt32 years;
    SInt32 months;
    SInt32 days;
    SInt32 hours;
    SInt32 minutes;
    double seconds;
} CFGregorianUnits;

typedef enum {
    kCFGregorianUnitsYears = (1 << 0),
    kCFGregorianUnitsMonths = (1 << 1),
    kCFGregorianUnitsDays = (1 << 2),
    kCFGregorianUnitsHours = (1 << 3),
    kCFGregorianUnitsMinutes = (1 << 4),
    kCFGregorianUnitsSeconds = (1 << 5),
    kCFGregorianAllUnits = 0x00FFFFFF
} CFGregorianUnitFlags;

CF_EXPORT
Boolean CFGregorianDateIsValid(CFGregorianDate gdate, CFOptionFlags unitFlags);

CF_EXPORT
CFAbsoluteTime CFGregorianDateGetAbsoluteTime(CFGregorianDate gdate, CFTimeZoneRef tz);

CF_EXPORT
CFGregorianDate CFAbsoluteTimeGetGregorianDate(CFAbsoluteTime at, CFTimeZoneRef tz);

CF_EXPORT
CFAbsoluteTime CFAbsoluteTimeAddGregorianUnits(CFAbsoluteTime at, CFTimeZoneRef tz, CFGregorianUnits units);

CF_EXPORT
CFGregorianUnits CFAbsoluteTimeGetDifferenceAsGregorianUnits(CFAbsoluteTime at1, CFAbsoluteTime at2, CFTimeZoneRef tz, CFOptionFlags unitFlags);

CF_EXPORT
SInt32 CFAbsoluteTimeGetDayOfWeek(CFAbsoluteTime at, CFTimeZoneRef tz);

CF_EXPORT
SInt32 CFAbsoluteTimeGetDayOfYear(CFAbsoluteTime at, CFTimeZoneRef tz);

CF_EXPORT
SInt32 CFAbsoluteTimeGetWeekOfYear(CFAbsoluteTime at, CFTimeZoneRef tz);



    #include <mach/port.h>



typedef struct __CFRunLoop * CFRunLoopRef;


typedef struct __CFRunLoopSource * CFRunLoopSourceRef;


typedef struct __CFRunLoopObserver * CFRunLoopObserverRef;


typedef struct __CFRunLoopTimer * CFRunLoopTimerRef;


enum {
    kCFRunLoopRunFinished = 1,
    kCFRunLoopRunStopped = 2,
    kCFRunLoopRunTimedOut = 3,
    kCFRunLoopRunHandledSource = 4
};


typedef enum {
    kCFRunLoopEntry = (1 << 0),
    kCFRunLoopBeforeTimers = (1 << 1),
    kCFRunLoopBeforeSources = (1 << 2),
    kCFRunLoopBeforeWaiting = (1 << 5),
    kCFRunLoopAfterWaiting = (1 << 6),
    kCFRunLoopExit = (1 << 7),
    kCFRunLoopAllActivities = 0x0FFFFFFFU
} CFRunLoopActivity;

CF_EXPORT __const CFStringRef kCFRunLoopDefaultMode;
CF_EXPORT __const CFStringRef kCFRunLoopCommonModes;


CF_EXPORT CFTypeID CFRunLoopGetTypeID(void);


CF_EXPORT CFRunLoopRef CFRunLoopGetCurrent(void);


CF_EXPORT CFStringRef CFRunLoopCopyCurrentMode(CFRunLoopRef rl);


CF_EXPORT CFArrayRef CFRunLoopCopyAllModes(CFRunLoopRef rl);


CF_EXPORT void CFRunLoopAddCommonMode(CFRunLoopRef rl, CFStringRef mode);


CF_EXPORT CFAbsoluteTime CFRunLoopGetNextTimerFireDate(CFRunLoopRef rl, CFStringRef mode);





CF_EXPORT void CFRunLoopRun(void);
CF_EXPORT SInt32 CFRunLoopRunInMode(CFStringRef mode, CFTimeInterval seconds, Boolean returnAfterSourceHandled);
CF_EXPORT Boolean CFRunLoopIsWaiting(CFRunLoopRef rl);
CF_EXPORT void CFRunLoopWakeUp(CFRunLoopRef rl);
CF_EXPORT void CFRunLoopStop(CFRunLoopRef rl);

CF_EXPORT Boolean CFRunLoopContainsSource(CFRunLoopRef rl, CFRunLoopSourceRef source, CFStringRef mode);
CF_EXPORT void CFRunLoopAddSource(CFRunLoopRef rl, CFRunLoopSourceRef source, CFStringRef mode);
CF_EXPORT void CFRunLoopRemoveSource(CFRunLoopRef rl, CFRunLoopSourceRef source, CFStringRef mode);

CF_EXPORT Boolean CFRunLoopContainsObserver(CFRunLoopRef rl, CFRunLoopObserverRef observer, CFStringRef mode);
CF_EXPORT void CFRunLoopAddObserver(CFRunLoopRef rl, CFRunLoopObserverRef observer, CFStringRef mode);
CF_EXPORT void CFRunLoopRemoveObserver(CFRunLoopRef rl, CFRunLoopObserverRef observer, CFStringRef mode);

CF_EXPORT Boolean CFRunLoopContainsTimer(CFRunLoopRef rl, CFRunLoopTimerRef timer, CFStringRef mode);
CF_EXPORT void CFRunLoopAddTimer(CFRunLoopRef rl, CFRunLoopTimerRef timer, CFStringRef mode);
CF_EXPORT void CFRunLoopRemoveTimer(CFRunLoopRef rl, CFRunLoopTimerRef timer, CFStringRef mode);


typedef struct {
    CFIndex	version;
    void *	info;
    __const void *(*retain)(__const void *info);
    void	(*release)(__const void *info);
    CFStringRef	(*copyDescription)(__const void *info);
    Boolean	(*equal)(__const void *info1, __const void *info2);
    CFHashCode	(*hash)(__const void *info);
    void	(*schedule)(void *info, CFRunLoopRef rl, CFStringRef mode);
    void	(*cancel)(void *info, CFRunLoopRef rl, CFStringRef mode);
    void	(*perform)(void *info);
} CFRunLoopSourceContext;

typedef struct {
    CFIndex	version;
    void *	info;
    __const void *(*retain)(__const void *info);
    void	(*release)(__const void *info);
    CFStringRef	(*copyDescription)(__const void *info);
    Boolean	(*equal)(__const void *info1, __const void *info2);
    CFHashCode	(*hash)(__const void *info);
    mach_port_t	(*getPort)(void *info);
    void *	(*perform)(void *msg, CFIndex size, CFAllocatorRef allocator, void *info);
} CFRunLoopSourceContext1;


CF_EXPORT CFTypeID CFRunLoopSourceGetTypeID(void);


CF_EXPORT CFRunLoopSourceRef CFRunLoopSourceCreate(CFAllocatorRef allocator, CFIndex order, CFRunLoopSourceContext *context);


CF_EXPORT CFIndex CFRunLoopSourceGetOrder(CFRunLoopSourceRef source);


CF_EXPORT void CFRunLoopSourceInvalidate(CFRunLoopSourceRef source);


CF_EXPORT Boolean CFRunLoopSourceIsValid(CFRunLoopSourceRef source);


CF_EXPORT void CFRunLoopSourceGetContext(CFRunLoopSourceRef source, CFRunLoopSourceContext *context);


CF_EXPORT void CFRunLoopSourceSignal(CFRunLoopSourceRef source);

typedef struct {
    CFIndex	version;
    void *	info;
    __const void *(*retain)(__const void *info);
    void	(*release)(__const void *info);
    CFStringRef	(*copyDescription)(__const void *info);
} CFRunLoopObserverContext;

typedef void (*CFRunLoopObserverCallBack)(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info);


CF_EXPORT CFTypeID CFRunLoopObserverGetTypeID(void);

CF_EXPORT CFRunLoopObserverRef CFRunLoopObserverCreate(CFAllocatorRef allocator, CFOptionFlags activities, Boolean repeats, CFIndex order, CFRunLoopObserverCallBack callout, CFRunLoopObserverContext *context);

CF_EXPORT CFOptionFlags CFRunLoopObserverGetActivities(CFRunLoopObserverRef observer);
CF_EXPORT Boolean CFRunLoopObserverDoesRepeat(CFRunLoopObserverRef observer);
CF_EXPORT CFIndex CFRunLoopObserverGetOrder(CFRunLoopObserverRef observer);
CF_EXPORT void CFRunLoopObserverInvalidate(CFRunLoopObserverRef observer);
CF_EXPORT Boolean CFRunLoopObserverIsValid(CFRunLoopObserverRef observer);
CF_EXPORT void CFRunLoopObserverGetContext(CFRunLoopObserverRef observer, CFRunLoopObserverContext *context);

typedef struct {
    CFIndex	version;
    void *	info;
    __const void *(*retain)(__const void *info);
    void	(*release)(__const void *info);
    CFStringRef	(*copyDescription)(__const void *info);
} CFRunLoopTimerContext;

typedef void (*CFRunLoopTimerCallBack)(CFRunLoopTimerRef timer, void *info);


CF_EXPORT CFTypeID CFRunLoopTimerGetTypeID(void);

CF_EXPORT CFRunLoopTimerRef CFRunLoopTimerCreate(CFAllocatorRef allocator, CFAbsoluteTime fireDate, CFTimeInterval interval, CFOptionFlags flags, CFIndex order, CFRunLoopTimerCallBack callout, CFRunLoopTimerContext *context);
CF_EXPORT CFAbsoluteTime CFRunLoopTimerGetNextFireDate(CFRunLoopTimerRef timer);
CF_EXPORT void CFRunLoopTimerSetNextFireDate(CFRunLoopTimerRef timer, CFAbsoluteTime fireDate);
CF_EXPORT CFTimeInterval CFRunLoopTimerGetInterval(CFRunLoopTimerRef timer);
CF_EXPORT Boolean CFRunLoopTimerDoesRepeat(CFRunLoopTimerRef timer);
CF_EXPORT CFIndex CFRunLoopTimerGetOrder(CFRunLoopTimerRef timer);
CF_EXPORT void CFRunLoopTimerInvalidate(CFRunLoopTimerRef timer);
CF_EXPORT Boolean CFRunLoopTimerIsValid(CFRunLoopTimerRef timer);
CF_EXPORT void CFRunLoopTimerGetContext(CFRunLoopTimerRef timer, CFRunLoopTimerContext *context);






typedef int CFSocketNativeHandle;



typedef struct __CFSocket * CFSocketRef;



typedef enum {
    kCFSocketSuccess = 0,
    kCFSocketError = -1,
    kCFSocketTimeout = -2
} CFSocketError;

typedef struct {
    SInt32	protocolFamily;
    SInt32	socketType;
    SInt32	protocol;
    CFDataRef	address;
} CFSocketSignature;

typedef enum {
    kCFSocketNoCallBack = 0,
    kCFSocketReadCallBack = 1,
    kCFSocketAcceptCallBack = 2,
    kCFSocketDataCallBack = 3,
    kCFSocketConnectCallBack = 4
} CFSocketCallBackType;


typedef void (*CFSocketCallBack)(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, __const void *data, void *info);


typedef struct {
    CFIndex	version;
    void *	info;
    __const void *(*retain)(__const void *info);
    void	(*release)(__const void *info);
    CFStringRef	(*copyDescription)(__const void *info);
} CFSocketContext;

CF_EXPORT CFTypeID	CFSocketGetTypeID(void);

CF_EXPORT CFSocketRef	CFSocketCreate(CFAllocatorRef allocator, SInt32 protocolFamily, SInt32 socketType, SInt32 protocol, CFOptionFlags callBackTypes, CFSocketCallBack callout, __const CFSocketContext *context);
CF_EXPORT CFSocketRef	CFSocketCreateWithNative(CFAllocatorRef allocator, CFSocketNativeHandle sock, CFOptionFlags callBackTypes, CFSocketCallBack callout, __const CFSocketContext *context);
CF_EXPORT CFSocketRef	CFSocketCreateWithSocketSignature(CFAllocatorRef allocator, __const CFSocketSignature *signature, CFOptionFlags callBackTypes, CFSocketCallBack callout, __const CFSocketContext *context);
CF_EXPORT CFSocketRef	CFSocketCreateConnectedToSocketSignature(CFAllocatorRef allocator, __const CFSocketSignature *signature, CFOptionFlags callBackTypes, CFSocketCallBack callout, __const CFSocketContext *context, CFTimeInterval timeout);


CF_EXPORT CFSocketError	CFSocketSetAddress(CFSocketRef s, CFDataRef address);
CF_EXPORT CFSocketError	CFSocketConnectToAddress(CFSocketRef s, CFDataRef address, CFTimeInterval timeout);
CF_EXPORT void		CFSocketInvalidate(CFSocketRef s);

CF_EXPORT Boolean	CFSocketIsValid(CFSocketRef s);
CF_EXPORT CFDataRef	CFSocketCopyAddress(CFSocketRef s);
CF_EXPORT CFDataRef	CFSocketCopyPeerAddress(CFSocketRef s);
CF_EXPORT void		CFSocketGetContext(CFSocketRef s, CFSocketContext *context);
CF_EXPORT CFSocketNativeHandle	CFSocketGetNative(CFSocketRef s);

CF_EXPORT CFRunLoopSourceRef	CFSocketCreateRunLoopSource(CFAllocatorRef allocator, CFSocketRef s, CFIndex order);



CF_EXPORT CFSocketError	CFSocketSendData(CFSocketRef s, CFDataRef address, CFDataRef data, CFTimeInterval timeout);



CF_EXPORT CFSocketError	CFSocketRegisterValue(__const CFSocketSignature *nameServerSignature, CFTimeInterval timeout, CFStringRef name, CFPropertyListRef value);
CF_EXPORT CFSocketError	CFSocketCopyRegisteredValue(__const CFSocketSignature *nameServerSignature, CFTimeInterval timeout, CFStringRef name, CFPropertyListRef *value, CFDataRef *nameServerAddress);

CF_EXPORT CFSocketError	CFSocketRegisterSocketSignature(__const CFSocketSignature *nameServerSignature, CFTimeInterval timeout, CFStringRef name, __const CFSocketSignature *signature);
CF_EXPORT CFSocketError	CFSocketCopyRegisteredSocketSignature(__const CFSocketSignature *nameServerSignature, CFTimeInterval timeout, CFStringRef name, CFSocketSignature *signature, CFDataRef *nameServerAddress);

CF_EXPORT CFSocketError	CFSocketUnregister(__const CFSocketSignature *nameServerSignature, CFTimeInterval timeout, CFStringRef name);

CF_EXPORT void		CFSocketSetDefaultNameRegistryPortNumber(UInt16 port);
CF_EXPORT UInt16	CFSocketGetDefaultNameRegistryPortNumber(void);


CF_EXPORT __const CFStringRef kCFSocketCommandKey;
CF_EXPORT __const CFStringRef kCFSocketNameKey;
CF_EXPORT __const CFStringRef kCFSocketValueKey;
CF_EXPORT __const CFStringRef kCFSocketResultKey;
CF_EXPORT __const CFStringRef kCFSocketErrorKey;
CF_EXPORT __const CFStringRef kCFSocketRegisterCommand;
CF_EXPORT __const CFStringRef kCFSocketRetrieveCommand;





typedef enum {
    kCFStreamStatusNotOpen = 0,
    kCFStreamStatusOpening,  
    kCFStreamStatusOpen,
    kCFStreamStatusReading,
    kCFStreamStatusWriting,
    kCFStreamStatusAtEnd,    
    kCFStreamStatusClosed,
    kCFStreamStatusError
} CFStreamStatus;

typedef enum {
    kCFStreamErrorDomainCustom = -1,      
    kCFStreamErrorDomainPOSIX = 1,        
    kCFStreamErrorDomainMacOSStatus      
} CFStreamErrorDomain;

typedef struct {
    CFStreamErrorDomain domain;
    SInt32 error;
} CFStreamError;

typedef enum {
    kCFStreamEventNone = 0,
    kCFStreamEventOpenCompleted = 1,
    kCFStreamEventHasBytesAvailable = 2,
    kCFStreamEventCanAcceptBytes = 4, 
    kCFStreamEventErrorOccurred = 8,
    kCFStreamEventEndEncountered = 16
} CFStreamEventType;

typedef struct {
    CFIndex version;
    void *info;
    void *(*retain)(void *info);
    void (*release)(void *info);
    CFStringRef (*copyDescription)(void *info);
} CFStreamClientContext;

typedef struct __CFReadStream * CFReadStreamRef;
typedef struct __CFWriteStream * CFWriteStreamRef;

typedef void (*CFReadStreamClientCallBack)(CFReadStreamRef stream, CFStreamEventType type, void *clientCallBackInfo);
typedef void (*CFWriteStreamClientCallBack)(CFWriteStreamRef stream, CFStreamEventType type, void *clientCallBackInfo);

CF_EXPORT
CFTypeID CFReadStreamGetTypeID(void);
CF_EXPORT
CFTypeID CFWriteStreamGetTypeID(void);




CF_EXPORT
__const CFStringRef kCFStreamPropertyDataWritten;


CF_EXPORT
CFReadStreamRef CFReadStreamCreateWithBytesNoCopy(CFAllocatorRef alloc, __const UInt8 *bytes, CFIndex length, CFAllocatorRef bytesDeallocator);


CF_EXPORT
CFWriteStreamRef CFWriteStreamCreateWithBuffer(CFAllocatorRef alloc, UInt8 *buffer, CFIndex bufferCapacity);


CF_EXPORT
CFWriteStreamRef CFWriteStreamCreateWithAllocatedBuffers(CFAllocatorRef alloc, CFAllocatorRef bufferAllocator);


CF_EXPORT
CFReadStreamRef CFReadStreamCreateWithFile(CFAllocatorRef alloc, CFURLRef fileURL);
CF_EXPORT
CFWriteStreamRef CFWriteStreamCreateWithFile(CFAllocatorRef alloc, CFURLRef fileURL);






CF_EXPORT
__const CFStringRef kCFStreamPropertySocketNativeHandle;


CF_EXPORT
__const CFStringRef kCFStreamPropertySocketRemoteHostName;


CF_EXPORT
__const CFStringRef kCFStreamPropertySocketRemotePortNumber;


CF_EXPORT
void CFStreamCreatePairWithSocket(CFAllocatorRef alloc, CFSocketNativeHandle sock, CFReadStreamRef *readStream, CFWriteStreamRef *writeStream);
CF_EXPORT
void CFStreamCreatePairWithSocketToHost(CFAllocatorRef alloc, CFStringRef host, UInt32 port, CFReadStreamRef *readStream, CFWriteStreamRef *writeStream);



CF_EXPORT
CFStreamStatus CFReadStreamGetStatus(CFReadStreamRef stream);
CF_EXPORT
CFStreamStatus CFWriteStreamGetStatus(CFWriteStreamRef stream);


CF_EXPORT
CFStreamError CFReadStreamGetError(CFReadStreamRef stream);
CF_EXPORT
CFStreamError CFWriteStreamGetError(CFWriteStreamRef stream);


CF_EXPORT
Boolean CFReadStreamOpen(CFReadStreamRef stream);
CF_EXPORT
Boolean CFWriteStreamOpen(CFWriteStreamRef stream);


CF_EXPORT
void CFReadStreamClose(CFReadStreamRef stream);
CF_EXPORT
void CFWriteStreamClose(CFWriteStreamRef stream);


CF_EXPORT
Boolean CFReadStreamHasBytesAvailable(CFReadStreamRef stream);


CF_EXPORT
CFIndex CFReadStreamRead(CFReadStreamRef stream, UInt8 *buffer, CFIndex bufferLength);


CF_EXPORT
__const UInt8 *CFReadStreamGetBuffer(CFReadStreamRef stream, CFIndex maxBytesToRead, CFIndex *numBytesRead);


CF_EXPORT
Boolean CFWriteStreamCanAcceptBytes(CFWriteStreamRef stream);


CF_EXPORT
CFIndex CFWriteStreamWrite(CFWriteStreamRef stream, __const UInt8 *buffer, CFIndex bufferLength);


CF_EXPORT
CFTypeRef CFReadStreamCopyProperty(CFReadStreamRef stream, CFStringRef propertyName);
CF_EXPORT
CFTypeRef CFWriteStreamCopyProperty(CFWriteStreamRef stream, CFStringRef propertyName);




CF_EXPORT
Boolean CFReadStreamSetClient(CFReadStreamRef stream, CFOptionFlags streamEvents, CFReadStreamClientCallBack clientCB, CFStreamClientContext *clientContext);
CF_EXPORT
Boolean CFWriteStreamSetClient(CFWriteStreamRef stream, CFOptionFlags streamEvents, CFWriteStreamClientCallBack clientCB, CFStreamClientContext *clientContext);

CF_EXPORT
void CFReadStreamScheduleWithRunLoop(CFReadStreamRef stream, CFRunLoopRef runLoop, CFStringRef runLoopMode);
CF_EXPORT
void CFWriteStreamScheduleWithRunLoop(CFWriteStreamRef stream, CFRunLoopRef runLoop, CFStringRef runLoopMode);

CF_EXPORT
void CFReadStreamUnscheduleFromRunLoop(CFReadStreamRef stream, CFRunLoopRef runLoop, CFStringRef runLoopMode);
CF_EXPORT
void CFWriteStreamUnscheduleFromRunLoop(CFWriteStreamRef stream, CFRunLoopRef runLoop, CFStringRef runLoopMode);




typedef enum {
    kCFPropertyListImmutable = 0,
    kCFPropertyListMutableContainers,
    kCFPropertyListMutableContainersAndLeaves
} CFPropertyListMutabilityOptions;
    

CF_EXPORT
CFPropertyListRef CFPropertyListCreateFromXMLData(CFAllocatorRef allocator, CFDataRef xmlData, CFOptionFlags mutabilityOption, CFStringRef *errorString);


CF_EXPORT
CFDataRef CFPropertyListCreateXMLData(CFAllocatorRef allocator, CFPropertyListRef propertyList);


CF_EXPORT
CFPropertyListRef CFPropertyListCreateDeepCopy(CFAllocatorRef allocator, CFPropertyListRef propertyList, CFOptionFlags mutabilityOption);









@class NSString, NSURL, NSError;




enum {	// Options for NSData reading methods
    NSMappedRead = 1,	    // Hint to map the file in if possible
    NSUncachedRead = 2	    // Hint to get the file not to be cached in the kernel
};

enum {	// Options for NSData writing methods
    NSAtomicWrite = 1	    // Hint to use auxiliary file when saving; equivalent to atomically:(BOOL)1
};





@interface NSData : NSObject <NSCopying, NSMutableCopying, NSCoding>

- (unsigned)length;
- (__const void *)bytes;

@end

@interface NSData (NSExtendedData)

- (NSString *)description;
- (void)getBytes:(void *)buffer;
- (void)getBytes:(void *)buffer length:(unsigned)length;
- (void)getBytes:(void *)buffer range:(NSRange)range;
- (BOOL)isEqualToData:(NSData *)other;
- (NSData *)subdataWithRange:(NSRange)range;
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile;
- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)atomically; // the atomically flag is ignored if the url is not of a type the supports atomic writes

@end

@interface NSData (NSDataCreation)

+ (id)data;
+ (id)dataWithBytes:(__const void *)bytes length:(unsigned)length;
+ (id)dataWithBytesNoCopy:(void *)bytes length:(unsigned)length;
+ (id)dataWithContentsOfFile:(NSString *)path;
+ (id)dataWithContentsOfURL:(NSURL *)url;
+ (id)dataWithContentsOfMappedFile:(NSString *)path;
- (id)initWithBytes:(__const void *)bytes length:(unsigned)length;
- (id)initWithBytesNoCopy:(void *)bytes length:(unsigned)length;
- (id)initWithContentsOfFile:(NSString *)path;
- (id)initWithContentsOfURL:(NSURL *)url;
- (id)initWithContentsOfMappedFile:(NSString *)path;
- (id)initWithData:(NSData *)data;
+ (id)dataWithData:(NSData *)data;

@end



@interface NSMutableData : NSData

- (void *)mutableBytes;
- (void)setLength:(unsigned)length;

@end

@interface NSMutableData (NSExtendedMutableData)

- (void)appendBytes:(__const void *)bytes length:(unsigned)length;
- (void)appendData:(NSData *)other;
- (void)increaseLengthBy:(unsigned)extraLength;
- (void)replaceBytesInRange:(NSRange)range withBytes:(__const void *)bytes;
- (void)resetBytesInRange:(NSRange)range;
- (void)setData:(NSData *)data;

@end

@interface NSMutableData (NSMutableDataCreation)

+ (id)dataWithCapacity:(unsigned)aNumItems;
+ (id)dataWithLength:(unsigned)length;
- (id)initWithCapacity:(unsigned)capacity;
- (id)initWithLength:(unsigned)length;

@end














@class NSString;

typedef double NSTimeInterval;


@interface NSDate : NSObject <NSCopying, NSCoding>

- (NSTimeInterval)timeIntervalSinceReferenceDate;

@end

@interface NSDate (NSExtendedDate)

- (NSTimeInterval)timeIntervalSinceDate:(NSDate *)anotherDate;
- (NSTimeInterval)timeIntervalSinceNow;
- (NSTimeInterval)timeIntervalSince1970;

- (id)addTimeInterval:(NSTimeInterval)seconds;

- (NSDate *)earlierDate:(NSDate *)anotherDate;
- (NSDate *)laterDate:(NSDate *)anotherDate;
- (NSComparisonResult)compare:(NSDate *)other;

- (NSString *)description;
- (BOOL)isEqualToDate:(NSDate *)otherDate;

+ (NSTimeInterval)timeIntervalSinceReferenceDate;
    
@end

@interface NSDate (NSDateCreation)

+ (id)date;
    
+ (id)dateWithTimeIntervalSinceNow:(NSTimeInterval)secs;    
+ (id)dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)secs;
+ (id)dateWithTimeIntervalSince1970:(NSTimeInterval)secs;

+ (id)distantFuture;
+ (id)distantPast;

- (id)init;
- (id)initWithTimeIntervalSinceReferenceDate:(NSTimeInterval)secsToBeAdded;
- (id)initWithTimeInterval:(NSTimeInterval)secsToBeAdded sinceDate:(NSDate *)anotherDate;
- (id)initWithTimeIntervalSinceNow:(NSTimeInterval)secsToBeAddedToNow;

@end


@class NSMutableData, NSDistantObject, NSException, NSData;
@class NSPort, NSRunLoop, NSPortNameServer, NSDictionary, NSArray;

@interface NSConnection : NSObject {
    @private
    id		receivePort;
    id		sendPort;
    id          delegate;
    int32_t	busy;
    char	slack[12];
    id		statistics;
    unsigned char isDead;
    unsigned char isValid;
    unsigned char wantsInvalid;
    unsigned char authGen:1;
    unsigned char authCheck:1;
    unsigned char encryptFlag:1;
    unsigned char decryptFlag:1;
    unsigned char doRequest:1;
    unsigned char isQueueing:1;
    unsigned char isMulti:1;
    unsigned char invalidateRP:1;
    id          localProxies;
    id          remoteProxies;
    id          runLoops;
    id		requestModes;
    id          rootObject;
    void *	registerInfo;
    id		replMode;
    id          classInfoImported;
    id		releasedProxies;
    void *	reserved;
}

- (NSDictionary *)statistics;

+ (NSArray *)allConnections;

+ (NSConnection *)defaultConnection;

+ (NSConnection *)connectionWithRegisteredName:(NSString *)name host:(NSString *)hostName;
+ (NSConnection *)connectionWithRegisteredName:(NSString *)name host:(NSString *)hostName usingNameServer:(NSPortNameServer *)server;
+ (NSDistantObject *)rootProxyForConnectionWithRegisteredName:(NSString *)name host:(NSString *)hostName;
+ (NSDistantObject *)rootProxyForConnectionWithRegisteredName:(NSString *)name host:(NSString *)hostName usingNameServer:(NSPortNameServer *)server;

- (void)setRequestTimeout:(NSTimeInterval)ti;
- (NSTimeInterval)requestTimeout;
- (void)setReplyTimeout:(NSTimeInterval)ti;
- (NSTimeInterval)replyTimeout;

- (void)setRootObject:(id)anObject;
- (id)rootObject;

- (NSDistantObject *)rootProxy;
  
- (void)setDelegate:(id)anObject;
- (id)delegate;

- (void)setIndependentConversationQueueing:(BOOL)yorn;
- (BOOL)independentConversationQueueing;

- (BOOL)isValid;

- (void)invalidate;

- (void)addRequestMode:(NSString *)rmode;
- (void)removeRequestMode:(NSString *)rmode;
- (NSArray *)requestModes;

- (BOOL)registerName:(NSString *) name;
- (BOOL)registerName:(NSString *) name withNameServer:(NSPortNameServer *)server;

+ (NSConnection *)connectionWithReceivePort:(NSPort *)receivePort sendPort:(NSPort *)sendPort;

+ (id)currentConversation;

- (id)initWithReceivePort:(NSPort *)receivePort sendPort:(NSPort *)sendPort;
- (NSPort *)sendPort;
- (NSPort *)receivePort;

- (void)enableMultipleThreads;
- (BOOL)multipleThreadsEnabled;

- (void)addRunLoop:(NSRunLoop *)runloop;
- (void)removeRunLoop:(NSRunLoop *)runloop;

- (void)runInNewThread;

- (NSArray *)remoteObjects;
- (NSArray *)localObjects;

@end

FOUNDATION_EXPORT NSString * __const NSConnectionReplyMode;

FOUNDATION_EXPORT NSString * __const NSConnectionDidDieNotification;


@interface NSObject (NSConnectionDelegateMethods)

// Use the NSConnectionDidInitializeNotification notification instead
// of this delegate method if possible.
- (BOOL)makeNewConnection:(NSConnection *)conn sender:(NSConnection *)ancestor;

// Use the NSConnectionDidInitializeNotification notification instead
// of this delegate method if possible.
- (BOOL)connection:(NSConnection *)ancestor shouldMakeNewConnection:(NSConnection *)conn;

- (NSData *)authenticationDataForComponents:(NSArray *)components;
- (BOOL)authenticateComponents:(NSArray *)components withData:(NSData *)signature;

- (id)createConversationForConnection:(NSConnection *)conn;

@end

FOUNDATION_EXPORT NSString * __const NSFailedAuthenticationException;

FOUNDATION_EXPORT NSString * __const NSConnectionDidInitializeNotification;

@interface NSDistantObjectRequest : NSObject

- (NSInvocation *)invocation;
- (NSConnection *)connection;
- (id)conversation;
- (void)replyWithException:(NSException *)exception;

@end

@interface NSObject (NSDistantObjectRequestMethods)

- (BOOL)connection:(NSConnection *)connection handleRequest:(NSDistantObjectRequest *)doreq;

@end




@class NSDictionary;



// Rounding policies :
// Original
//    value 1.2  1.21  1.25  1.35  1.27
// Plain    1.2  1.2   1.3   1.4   1.3
// Down     1.2  1.2   1.2   1.3   1.2
// Up       1.2  1.3   1.3   1.4   1.3
// Bankers  1.2  1.2   1.2   1.4   1.3

typedef enum {
    NSRoundPlain,   // Round up on a tie
    NSRoundDown,    // Always down == truncate
    NSRoundUp,      // Always up
    NSRoundBankers  // on a tie round so last digit is even
} NSRoundingMode;

typedef enum {
    NSCalculationNoError = 0,
    NSCalculationLossOfPrecision, // Result lost precision
    NSCalculationUnderflow,       // Result became 0
    NSCalculationOverflow,        // Result exceeds possible representation
    NSCalculationDivideByZero
} NSCalculationError;

    // Give a precision of at least 38 decimal digits, 128 binary positions.


typedef struct {
    __signed   int _exponent:8;
    unsigned int _length:4;     // length == 0 && isNegative -> NaN
    unsigned int _isNegative:1;
    unsigned int _isCompact:1;
    unsigned int _reserved:18;
    unsigned short _mantissa[(8)];
} NSDecimal;

static __inline__ __attribute__((always_inline)) BOOL NSDecimalIsNotANumber(__const NSDecimal *dcm)
  { return ((dcm->_length == 0) && dcm->_isNegative); }



FOUNDATION_EXPORT void NSDecimalCopy(NSDecimal *destination, __const NSDecimal *source);

FOUNDATION_EXPORT void NSDecimalCompact(NSDecimal *number);

FOUNDATION_EXPORT NSComparisonResult NSDecimalCompare(__const NSDecimal *leftOperand, __const NSDecimal *rightOperand);
    // NSDecimalCompare:Compares leftOperand and rightOperand.

FOUNDATION_EXPORT void NSDecimalRound(NSDecimal *result, __const NSDecimal *number, int scale, NSRoundingMode roundingMode);
    // Rounds num to the given scale using the given mode.
    // result may be a pointer to same space as num.
    // scale indicates number of significant digits after the decimal point

FOUNDATION_EXPORT NSCalculationError NSDecimalNormalize(NSDecimal *number1, NSDecimal *number2, NSRoundingMode roundingMode);

FOUNDATION_EXPORT NSCalculationError NSDecimalAdd(NSDecimal *result, __const NSDecimal *leftOperand, __const NSDecimal *rightOperand, NSRoundingMode roundingMode);
    // Exact operations. result may be a pointer to same space as leftOperand or rightOperand

FOUNDATION_EXPORT NSCalculationError NSDecimalSubtract(NSDecimal *result, __const NSDecimal *leftOperand, __const NSDecimal *rightOperand, NSRoundingMode roundingMode);
    // Exact operations. result may be a pointer to same space as leftOperand or rightOperand

FOUNDATION_EXPORT NSCalculationError NSDecimalMultiply(NSDecimal *result, __const NSDecimal *leftOperand, __const NSDecimal *rightOperand, NSRoundingMode roundingMode);
    // Exact operations. result may be a pointer to same space as leftOperand or rightOperand

FOUNDATION_EXPORT NSCalculationError NSDecimalDivide(NSDecimal *result, __const NSDecimal *leftOperand, __const NSDecimal *rightOperand, NSRoundingMode roundingMode);
    // Division could be silently inexact;
    // Exact operations. result may be a pointer to same space as leftOperand or rightOperand
    
FOUNDATION_EXPORT NSCalculationError NSDecimalPower(NSDecimal *result, __const NSDecimal *number, unsigned power, NSRoundingMode roundingMode);

FOUNDATION_EXPORT NSCalculationError NSDecimalMultiplyByPowerOf10(NSDecimal *result, __const NSDecimal *number, short power, NSRoundingMode roundingMode);

FOUNDATION_EXPORT NSString *NSDecimalString(__const NSDecimal *dcm, NSDictionary *locale);






@class NSString, NSData;

@interface NSFileHandle : NSObject

- (NSData *)availableData;

- (NSData *)readDataToEndOfFile;
- (NSData *)readDataOfLength:(unsigned int)length;

- (void)writeData:(NSData *)data;

- (unsigned long long)offsetInFile;
- (unsigned long long)seekToEndOfFile;
- (void)seekToFileOffset:(unsigned long long)offset;

- (void)truncateFileAtOffset:(unsigned long long)offset;
- (void)synchronizeFile;
- (void)closeFile;

@end

@interface NSFileHandle (NSFileHandleCreation)

+ (id)fileHandleWithStandardInput;
+ (id)fileHandleWithStandardOutput;
+ (id)fileHandleWithStandardError;
+ (id)fileHandleWithNullDevice;

+ (id)fileHandleForReadingAtPath:(NSString *)path;
+ (id)fileHandleForWritingAtPath:(NSString *)path;
+ (id)fileHandleForUpdatingAtPath:(NSString *)path;

@end

FOUNDATION_EXPORT NSString * __const NSFileHandleOperationException;

FOUNDATION_EXPORT NSString * __const NSFileHandleReadCompletionNotification;
FOUNDATION_EXPORT NSString * __const NSFileHandleReadToEndOfFileCompletionNotification;
FOUNDATION_EXPORT NSString * __const NSFileHandleConnectionAcceptedNotification;
FOUNDATION_EXPORT NSString * __const NSFileHandleDataAvailableNotification;

FOUNDATION_EXPORT NSString * __const NSFileHandleNotificationDataItem;
FOUNDATION_EXPORT NSString * __const NSFileHandleNotificationFileHandleItem;
FOUNDATION_EXPORT NSString * __const NSFileHandleNotificationMonitorModes;

@interface NSFileHandle (NSFileHandleAsynchronousAccess)

- (void)readInBackgroundAndNotifyForModes:(NSArray *)modes;
- (void)readInBackgroundAndNotify;

- (void)readToEndOfFileInBackgroundAndNotifyForModes:(NSArray *)modes;
- (void)readToEndOfFileInBackgroundAndNotify;

- (void)acceptConnectionInBackgroundAndNotifyForModes:(NSArray *)modes;
- (void)acceptConnectionInBackgroundAndNotify;

- (void)waitForDataInBackgroundAndNotifyForModes:(NSArray *)modes;
- (void)waitForDataInBackgroundAndNotify;

@end

@interface NSFileHandle (NSFileHandlePlatformSpecific)


- (id)initWithFileDescriptor:(int)fd closeOnDealloc:(BOOL)closeopt;
- (id)initWithFileDescriptor:(int)fd;
- (int)fileDescriptor;

@end

@interface NSPipe : NSObject

- (NSFileHandle *)fileHandleForReading;
- (NSFileHandle *)fileHandleForWriting;

- (id)init;
+ (id)pipe;

@end






typedef struct _NSHashTable NSHashTable;

typedef struct {
    unsigned	(*hash)(NSHashTable *table, __const void *);
    BOOL	(*isEqual)(NSHashTable *table, __const void *, __const void *);
    void	(*retain)(NSHashTable *table, __const void *);
    void	(*release)(NSHashTable *table, void *);
    NSString 	*(*describe)(NSHashTable *table, __const void *);
} NSHashTableCallBacks;
    
typedef struct {unsigned _pi; unsigned _si; void *_bs;} NSHashEnumerator;



FOUNDATION_EXPORT NSHashTable *NSCreateHashTableWithZone(NSHashTableCallBacks callBacks, unsigned capacity, NSZone *zone);
FOUNDATION_EXPORT NSHashTable *NSCreateHashTable(NSHashTableCallBacks callBacks, unsigned capacity);
FOUNDATION_EXPORT void NSFreeHashTable(NSHashTable *table);
FOUNDATION_EXPORT void NSResetHashTable(NSHashTable *table);
FOUNDATION_EXPORT BOOL NSCompareHashTables(NSHashTable *table1, NSHashTable *table2);
FOUNDATION_EXPORT NSHashTable *NSCopyHashTableWithZone(NSHashTable *table, NSZone *zone);
FOUNDATION_EXPORT void *NSHashGet(NSHashTable *table, __const void *pointer);
FOUNDATION_EXPORT void NSHashInsert(NSHashTable *table, __const void *pointer);
FOUNDATION_EXPORT void NSHashInsertKnownAbsent(NSHashTable *table, __const void *pointer);
FOUNDATION_EXPORT void *NSHashInsertIfAbsent(NSHashTable *table, __const void *pointer);
FOUNDATION_EXPORT void NSHashRemove(NSHashTable *table, __const void *pointer);
FOUNDATION_EXPORT NSHashEnumerator NSEnumerateHashTable(NSHashTable *table);
FOUNDATION_EXPORT void *NSNextHashEnumeratorItem(NSHashEnumerator *enumerator);
FOUNDATION_EXPORT void NSEndHashTableEnumeration(NSHashEnumerator *enumerator);
FOUNDATION_EXPORT unsigned NSCountHashTable(NSHashTable *table);
FOUNDATION_EXPORT NSString *NSStringFromHashTable(NSHashTable *table);
FOUNDATION_EXPORT NSArray *NSAllHashTableObjects(NSHashTable *table);



FOUNDATION_EXPORT __const NSHashTableCallBacks NSIntHashCallBacks;
FOUNDATION_EXPORT __const NSHashTableCallBacks NSNonOwnedPointerHashCallBacks;
FOUNDATION_EXPORT __const NSHashTableCallBacks NSNonRetainedObjectHashCallBacks;
FOUNDATION_EXPORT __const NSHashTableCallBacks NSObjectHashCallBacks;
FOUNDATION_EXPORT __const NSHashTableCallBacks NSOwnedObjectIdentityHashCallBacks;
FOUNDATION_EXPORT __const NSHashTableCallBacks NSOwnedPointerHashCallBacks;
FOUNDATION_EXPORT __const NSHashTableCallBacks NSPointerToStructHashCallBacks;











typedef struct _NSMapTable NSMapTable;

typedef struct {
    unsigned	(*hash)(NSMapTable *table, __const void *);
    BOOL	(*isEqual)(NSMapTable *table, __const void *, __const void *);
    void	(*retain)(NSMapTable *table, __const void *);
    void	(*release)(NSMapTable *table, void *);
    NSString 	*(*describe)(NSMapTable *table, __const void *);
    __const void	*notAKeyMarker;
} NSMapTableKeyCallBacks;
    

typedef struct {
    void	(*retain)(NSMapTable *table, __const void *);
    void	(*release)(NSMapTable *table, void *);
    NSString 	*(*describe)(NSMapTable *table, __const void *);
} NSMapTableValueCallBacks;
    
typedef struct {unsigned _pi; unsigned _si; void *_bs;} NSMapEnumerator;



FOUNDATION_EXPORT NSMapTable *NSCreateMapTableWithZone(NSMapTableKeyCallBacks keyCallBacks, NSMapTableValueCallBacks valueCallBacks, unsigned capacity, NSZone *zone);
FOUNDATION_EXPORT NSMapTable *NSCreateMapTable(NSMapTableKeyCallBacks keyCallBacks, NSMapTableValueCallBacks valueCallBacks, unsigned capacity);
FOUNDATION_EXPORT void NSFreeMapTable(NSMapTable *table);
FOUNDATION_EXPORT void NSResetMapTable(NSMapTable *table);
FOUNDATION_EXPORT BOOL NSCompareMapTables(NSMapTable *table1, NSMapTable *table2);
FOUNDATION_EXPORT NSMapTable *NSCopyMapTableWithZone(NSMapTable *table, NSZone *zone);
FOUNDATION_EXPORT BOOL NSMapMember(NSMapTable *table, __const void *key, void **originalKey, void **value);
FOUNDATION_EXPORT void *NSMapGet(NSMapTable *table, __const void *key);
FOUNDATION_EXPORT void NSMapInsert(NSMapTable *table, __const void *key, __const void *value);
FOUNDATION_EXPORT void NSMapInsertKnownAbsent(NSMapTable *table, __const void *key, __const void *value);
FOUNDATION_EXPORT void *NSMapInsertIfAbsent(NSMapTable *table, __const void *key, __const void *value);
FOUNDATION_EXPORT void NSMapRemove(NSMapTable *table, __const void *key);
FOUNDATION_EXPORT NSMapEnumerator NSEnumerateMapTable(NSMapTable *table);
FOUNDATION_EXPORT BOOL NSNextMapEnumeratorPair(NSMapEnumerator *enumerator, void **key, void **value);
FOUNDATION_EXPORT void NSEndMapTableEnumeration(NSMapEnumerator *enumerator);
FOUNDATION_EXPORT unsigned NSCountMapTable(NSMapTable *table);
FOUNDATION_EXPORT NSString *NSStringFromMapTable(NSMapTable *table);
FOUNDATION_EXPORT NSArray *NSAllMapTableKeys(NSMapTable *table);
FOUNDATION_EXPORT NSArray *NSAllMapTableValues(NSMapTable *table);



FOUNDATION_EXPORT __const NSMapTableKeyCallBacks NSIntMapKeyCallBacks;
FOUNDATION_EXPORT __const NSMapTableKeyCallBacks NSNonOwnedPointerMapKeyCallBacks;
FOUNDATION_EXPORT __const NSMapTableKeyCallBacks NSNonOwnedPointerOrNullMapKeyCallBacks;
FOUNDATION_EXPORT __const NSMapTableKeyCallBacks NSNonRetainedObjectMapKeyCallBacks;
FOUNDATION_EXPORT __const NSMapTableKeyCallBacks NSObjectMapKeyCallBacks;
FOUNDATION_EXPORT __const NSMapTableKeyCallBacks NSOwnedPointerMapKeyCallBacks;



FOUNDATION_EXPORT __const NSMapTableValueCallBacks NSIntMapValueCallBacks;
FOUNDATION_EXPORT __const NSMapTableValueCallBacks NSNonOwnedPointerMapValueCallBacks;
FOUNDATION_EXPORT __const NSMapTableValueCallBacks NSObjectMapValueCallBacks;
FOUNDATION_EXPORT __const NSMapTableValueCallBacks NSNonRetainedObjectMapValueCallBacks;
FOUNDATION_EXPORT __const NSMapTableValueCallBacks NSOwnedPointerMapValueCallBacks;




@interface NSMethodSignature : NSObject {
    @private
    __const char	*_types;
    int		_nargs;
    unsigned	_sizeofParams;
    unsigned	_returnValueLength;
    void	*_parmInfoP;
    int		*_fixup;
    void	*_reserved;
}

- (unsigned)numberOfArguments;
- (__const char *)getArgumentTypeAtIndex:(unsigned)index;

- (unsigned)frameLength;

- (BOOL)isOneway;

- (__const char *)methodReturnType;
- (unsigned)methodReturnLength;

@end



@class NSString, NSDictionary;



@interface NSNotification : NSObject <NSCopying, NSCoding>

- (NSString *)name;
- (id)object;
- (NSDictionary *)userInfo;

@end

@interface NSNotification (NSNotificationCreation)

+ (id)notificationWithName:(NSString *)aName object:(id)anObject;
+ (id)notificationWithName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo;

@end



@interface NSNotificationCenter : NSObject {
    @protected
    void *_impl;
    uintptr_t _counter;
    void *_pad[11];
}

+ (id)defaultCenter;
    
- (void)addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject;

- (void)postNotification:(NSNotification *)notification;
- (void)postNotificationName:(NSString *)aName object:(id)anObject;
- (void)postNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo;

- (void)removeObserver:(id)observer;
- (void)removeObserver:(id)observer name:(NSString *)aName object:(id)anObject;

@end




@class NSNotification, NSNotificationCenter, NSArray;

typedef enum {
    NSPostWhenIdle = 1,
    NSPostASAP = 2,
    NSPostNow = 3
} NSPostingStyle;

typedef enum {
    NSNotificationNoCoalescing = 0,
    NSNotificationCoalescingOnName = 1,
    NSNotificationCoalescingOnSender = 2
} NSNotificationCoalescing;

@interface NSNotificationQueue : NSObject {
@private
    id		_notificationCenter;
    id		_asapQueue;
    id		_asapObs;
    id		_idleQueue;
    id		_idleObs;
}

+ (NSNotificationQueue *)defaultQueue;

- (id)initWithNotificationCenter:(NSNotificationCenter *)notificationCenter;

- (void)enqueueNotification:(NSNotification *)notification postingStyle:(NSPostingStyle)postingStyle;
- (void)enqueueNotification:(NSNotification *)notification postingStyle:(NSPostingStyle)postingStyle coalesceMask:(unsigned)coalesceMask forModes:(NSArray *)modes;

- (void)dequeueNotificationsMatching:(NSNotification *)notification coalesceMask:(unsigned)coalesceMask;

@end



    typedef int NSSocketNativeHandle;

@class NSRunLoop, NSMutableArray, NSDate;
@class NSConnection, NSPortMessage;
@class NSData;

FOUNDATION_EXPORT NSString * __const NSPortDidBecomeInvalidNotification;

@interface NSPort : NSObject <NSCopying, NSCoding>

// For backwards compatibility on Mach, +allocWithZone: returns
// an instance of the NSMachPort class when sent to the NSPort
// class.  Otherwise, it returns an instance of a concrete
// subclass which can be used for messaging between threads
// or processes on the local machine.
+ (id)allocWithZone:(NSZone *)zone;

+ (NSPort *)port;

- (void)invalidate;
- (BOOL)isValid;

- (void)setDelegate:(id)anId;
- (id)delegate;

// These two methods should be implemented by subclasses
// to setup monitoring of the port when added to a run loop,
// and stop monitoring if needed when removed;
// These methods should not be called directly!
- (void)scheduleInRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode;
- (void)removeFromRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode;

// DO Transport API; subclassers should implement these methods
- (unsigned)reservedSpaceLength;	// default is 0
- (BOOL)sendBeforeDate:(NSDate *)limitDate components:(NSMutableArray *)components from:(NSPort *) receivePort reserved:(unsigned)headerSpaceReserved;
- (BOOL)sendBeforeDate:(NSDate *)limitDate msgid:(unsigned)msgID components:(NSMutableArray *)components from:(NSPort *)receivePort reserved:(unsigned)headerSpaceReserved;
	// The components array consists of a series of instances
	// of some subclass of NSData, and instances of some
	// subclass of NSPort; since one subclass of NSPort does
	// not necessarily know how to transport an instance of
	// another subclass of NSPort (or could do it even if it
	// knew about the other subclass), all of the instances
	// of NSPort in the components array and the 'receivePort'
	// argument MUST be of the same subclass of NSPort that
	// receives this message.  If multiple DO transports are
	// being used in the same program, this requires some care.

- (void)addConnection:(NSConnection *)conn toRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode;
- (void)removeConnection:(NSConnection *)conn fromRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode;
	// The default implementation of these two methods is to
	// simply add the receiving port to the run loop in the
	// given mode.  Subclassers need not override these methods,
	// but can if they need to do extra work.

@end

@interface NSObject (NSPortDelegateMethods)

- (void)handlePortMessage:(NSPortMessage *)message;
	// This is the delegate method that subclasses should send
	// to their delegates, unless the subclass has something
	// more specific that it wants to try to send first
@end


@interface NSMachPort : NSPort {
    @private
    id _delegate;
    void *_tickler;
    int _machPort;
    unsigned _reserved;
}

+ (NSPort *)portWithMachPort:(int)machPort;

- (id)initWithMachPort:(int)machPort;	// designated initializer
- (int)machPort;

- (void)scheduleInRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode;
- (void)removeFromRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode;
	// If you subclass NSMachPort, you have to override these 2
	// methods from NSPort; since this is complicated, subclassing
	// NSMachPort is not recommended

@end

@interface NSObject (NSMachPortDelegateMethods)

// Delegates are sent this if they respond, otherwise they
// are sent handlePortMessage:; argument is the raw Mach message
- (void)handleMachMessage:(void *)msg;

@end


// A subclass of NSPort which can be used for local
// message sending on all platforms.
@interface NSMessagePort : NSPort {
    @private
    void *_port;
    id _delegate;
}

@end

// A subclass of NSPort which can be used for remote
// message sending on all platforms.

@interface NSSocketPort : NSPort {
    @private
    void *_receiver;
    void *_connectors;
    void *_loops;
    void *_data;
    id _signature;
    id _delegate;
    id _lock;
    unsigned _maxSize;
    unsigned _maxSockets;
    unsigned _reserved;
}

- (id)init;
- (id)initWithTCPPort:(unsigned short)port;
- (id)initWithProtocolFamily:(int)family socketType:(int)type protocol:(int)protocol address:(NSData *)address;
- (id)initWithProtocolFamily:(int)family socketType:(int)type protocol:(int)protocol socket:(NSSocketNativeHandle)sock;
- (id)initRemoteWithTCPPort:(unsigned short)port host:(NSString *)hostName;
- (id)initRemoteWithProtocolFamily:(int)family socketType:(int)type protocol:(int)protocol address:(NSData *)address;
- (int)protocolFamily;
- (int)socketType;
- (int)protocol;
- (NSData *)address;
- (NSSocketNativeHandle)socket;

@end




@class NSConnection, NSPort, NSArray;

@interface NSPortCoder : NSCoder

- (BOOL)isBycopy;
- (BOOL)isByref;
- (NSConnection *)connection;
- (void)encodePortObject:(NSPort *)aport;
- (NSPort *)decodePortObject;

// Transport
+ portCoderWithReceivePort:(NSPort *)rcvPort sendPort:(NSPort *)sndPort components:(NSArray *)comps;
- (id)initWithReceivePort:(NSPort *)rcvPort sendPort:(NSPort *)sndPort components:(NSArray *)comps;
- (void)dispatch;

@end

@interface NSObject (NSDistributedObjects)

- (Class)classForPortCoder;

- (id)replacementObjectForPortCoder:(NSPortCoder *)coder;

@end



@class NSPort, NSDate, NSArray, NSMutableArray;

@interface NSPortMessage : NSObject {
    @private
    NSPort 		*localPort;
    NSPort 		*remotePort;
    NSMutableArray 	*components;
    unsigned		msgid;
    void		*reserved2;
    void		*reserved;
}

- (id)initWithSendPort:(NSPort *)sendPort receivePort:(NSPort *)replyPort components:(NSArray *)components;

- (NSArray *)components;
- (NSPort *)receivePort;
- (NSPort *)sendPort;
- (BOOL)sendBeforeDate:(NSDate *)date;

- (unsigned)msgid;
- (void)setMsgid:(unsigned)msgid;
@end



@class NSString, NSPort;

@interface NSPortNameServer : NSObject

+ (NSPortNameServer *)systemDefaultPortNameServer;

- (NSPort *)portForName:(NSString *)name;
- (NSPort *)portForName:(NSString *)name host:(NSString *)host;

- (BOOL)registerPort:(NSPort *)port name:(NSString *)name;

- (BOOL)removePortForName:(NSString *)name;

@end


@interface NSMachBootstrapServer : NSPortNameServer
	// This port name server actually takes and
	// returns instances of NSMachPort

+ (id)sharedInstance;

- (NSPort *)portForName:(NSString *)name;
- (NSPort *)portForName:(NSString *)name host:(NSString *)host;
	// the bootstrap server is a local-only server;
	// host parameter must be emptry string or 0

- (BOOL)registerPort:(NSPort *)port name:(NSString *)name;

// removePortForName: functionality is not supported in
// the bootstrap server; if you want to cancel a service,
// you have to destroy the port (invalidate the NSMachPort
// given to registerPort:name:).

@end


@interface NSMessagePortNameServer : NSPortNameServer
	// This port name server actually takes and
	// returns instances of NSMessagePort

+ (id)sharedInstance;

- (NSPort *)portForName:(NSString *)name;
- (NSPort *)portForName:(NSString *)name host:(NSString *)host;
	// this name server is a local-only server;
	// host parameter must be emptry string or 0

// removePortForName: functionality is not supported in
// this name server; if you want to cancel a service,
// you have to destroy the port (invalidate the
// NSMessagePort given to registerPort:name:).

@end

@interface NSSocketPortNameServer : NSPortNameServer
	// This port name server actually takes and
	// returns instances of NSSocketPort

+ (id)sharedInstance;

- (NSPort *)portForName:(NSString *)name;
- (NSPort *)portForName:(NSString *)name host:(NSString *)host;
    // this name server supports remote lookup
- (BOOL)registerPort:(NSPort *)port name:(NSString *)name;

- (BOOL)removePortForName:(NSString *)name;
     // removePortForName: is supported, and should be used

// the following may be used in the future, but for now nameServerPortNumber arguments are ignored
- (NSPort *)portForName:(NSString *)name host:(NSString *)host nameServerPortNumber:(unsigned short)portNumber;
- (BOOL)registerPort:(NSPort *)port name:(NSString *)name nameServerPortNumber:(unsigned short)portNumber;
- (void)setDefaultNameServerPortNumber:(unsigned short)portNumber;
- (unsigned short)defaultNameServerPortNumber;

@end







@class NSTimer, NSPort, NSArray;

FOUNDATION_EXPORT NSString * __const NSDefaultRunLoopMode;

@interface NSRunLoop : NSObject {
@private
    id          _rl;
    id          _dperf;
    id          _perft;
    void	*_reserved[8];
}

+ (NSRunLoop *)currentRunLoop;
- (NSString *)currentMode;
- (CFRunLoopRef)getCFRunLoop;

- (void)addTimer:(NSTimer *)timer forMode:(NSString *)mode;

- (void)addPort:(NSPort *)aPort forMode:(NSString *)mode;
- (void)removePort:(NSPort *)aPort forMode:(NSString *)mode;

- (NSDate *)limitDateForMode:(NSString *)mode;
- (void)acceptInputForMode:(NSString *)mode beforeDate:(NSDate *)limitDate;

@end

@interface NSRunLoop (NSRunLoopConveniences)

- (void)run; 
- (void)runUntilDate:(NSDate *)limitDate;
- (BOOL)runMode:(NSString *)mode beforeDate:(NSDate *)limitDate;

- (void)configureAsServer;

@end



@interface NSObject (NSDelayedPerforming)

- (void)performSelector:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay inModes:(NSArray *)modes;
- (void)performSelector:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay;
+ (void)cancelPreviousPerformRequestsWithTarget:(id)aTarget selector:(SEL)aSelector object:(id)anArgument;

@end

@interface NSRunLoop (NSOrderedPerform)

- (void)performSelector:(SEL)aSelector target:(id)target argument:(id)arg order:(unsigned)order modes:(NSArray *)modes;
- (void)cancelPerformSelector:(SEL)aSelector target:(id)target argument:(id)arg;

@end




@class NSArray, NSDictionary, NSEnumerator, NSString;



@interface NSSet : NSObject <NSCopying, NSMutableCopying, NSCoding>

- (unsigned)count;
- (id)member:(id)object;
- (NSEnumerator *)objectEnumerator;

@end

@interface NSSet (NSExtendedSet)

- (NSArray *)allObjects;
- (id)anyObject;
- (BOOL)containsObject:(id)anObject;
- (NSString *)description;
- (NSString *)descriptionWithLocale:(NSDictionary *)locale;
- (BOOL)intersectsSet:(NSSet *)otherSet;
- (BOOL)isEqualToSet:(NSSet *)otherSet;
- (BOOL)isSubsetOfSet:(NSSet *)otherSet;

- (void)makeObjectsPerformSelector:(SEL)aSelector;
- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)argument;

@end

@interface NSSet (NSSetCreation)

+ (id)set;
+ (id)setWithArray:(NSArray *)array;
+ (id)setWithObject:(id)object;
+ (id)setWithObjects:(id)firstObj, ...;
- (id)initWithArray:(NSArray *)array;
- (id)initWithObjects:(id *)objects count:(unsigned)count;
- (id)initWithObjects:(id)firstObj, ...;
- (id)initWithSet:(NSSet *)set;
- (id)initWithSet:(NSSet *)set copyItems:(BOOL)flag;

+ (id)setWithSet:(NSSet *)set;
+ (id)setWithObjects:(id *)objs count:(unsigned)cnt;

@end



@interface NSMutableSet : NSSet

- (void)addObject:(id)object;
- (void)removeObject:(id)object;

@end

@interface NSMutableSet (NSExtendedMutableSet)

- (void)addObjectsFromArray:(NSArray *)array;
- (void)intersectSet:(NSSet *)otherSet;
- (void)minusSet:(NSSet *)otherSet;
- (void)removeAllObjects;
- (void)unionSet:(NSSet *)otherSet;

- (void)setSet:(NSSet *)otherSet;

@end

@interface NSMutableSet (NSMutableSetCreation)

+ (id)setWithCapacity:(unsigned)numItems;
- (id)initWithCapacity:(unsigned)numItems;
    
@end



@interface NSCountedSet : NSMutableSet {
    @private
    void *_table;
    void *_reserved;
}

- (id)initWithCapacity:(unsigned)numItems; // designated initializer

- (id)initWithArray:(NSArray *)array;
- (id)initWithSet:(NSSet *)set;

- (unsigned)countForObject:(id)object;

- (NSEnumerator *)objectEnumerator;
- (void)addObject:(id)object;
- (void)removeObject:(id)object;

@end




@class NSString, NSCharacterSet, NSDictionary;

@interface NSScanner : NSObject <NSCopying>

- (NSString *)string;
- (unsigned)scanLocation;
- (void)setScanLocation:(unsigned)pos;
- (void)setCharactersToBeSkipped:(NSCharacterSet *)set;
- (void)setCaseSensitive:(BOOL)flag;
- (void)setLocale:(NSDictionary *)dict;

@end

@interface NSScanner (NSExtendedScanner)

- (NSCharacterSet *)charactersToBeSkipped;
- (BOOL)caseSensitive;
- (NSDictionary *)locale;

- (BOOL)scanInt:(int *)value;
- (BOOL)scanHexInt:(unsigned *)value;		
- (BOOL)scanLongLong:(long long *)value;
- (BOOL)scanFloat:(float *)value;
- (BOOL)scanDouble:(double *)value;
- (BOOL)scanString:(NSString *)string intoString:(NSString **)value;
- (BOOL)scanCharactersFromSet:(NSCharacterSet *)set intoString:(NSString **)value;

- (BOOL)scanUpToString:(NSString *)string intoString:(NSString **)value;
- (BOOL)scanUpToCharactersFromSet:(NSCharacterSet *)set intoString:(NSString **)value;

- (BOOL)isAtEnd;

- (id)initWithString:(NSString *)string;
+ (id)scannerWithString:(NSString *)string;
+ (id)localizedScannerWithString:(NSString *)string;

@end







@class NSString, NSArray, NSDictionary, NSDate, NSData;

@interface NSTimeZone : NSObject <NSCopying, NSCoding>

- (NSString *)name;
- (NSData *)data;

- (int)secondsFromGMTForDate:(NSDate *)aDate;
- (NSString *)abbreviationForDate:(NSDate *)aDate;
- (BOOL)isDaylightSavingTimeForDate:(NSDate *)aDate;

@end

@interface NSTimeZone (NSExtendedTimeZone)

+ (NSTimeZone *)systemTimeZone;
+ (void)resetSystemTimeZone;

+ (NSTimeZone *)defaultTimeZone;
+ (void)setDefaultTimeZone:(NSTimeZone *)aTimeZone;

+ (NSTimeZone *)localTimeZone;

+ (NSArray *)knownTimeZoneNames;

+ (NSDictionary *)abbreviationDictionary;

- (int)secondsFromGMT;
- (NSString *)abbreviation;
- (BOOL)isDaylightSavingTime;

- (NSString *)description;

- (BOOL)isEqualToTimeZone:(NSTimeZone *)aTimeZone;

@end

@interface NSTimeZone (NSTimeZoneCreation)

// Primary creation method is +timeZoneWithName:; the
// data-taking variants should rarely be used directly

+ (id)timeZoneWithName:(NSString *)tzName;
+ (id)timeZoneWithName:(NSString *)tzName data:(NSData *)aData;

- (id)initWithName:(NSString *)tzName;
- (id)initWithName:(NSString *)tzName data:(NSData *)aData;

// Time zones created with this never have daylight savings and the
// offset is constant no matter the date; the name and abbreviation
// do NOT follow the POSIX convention (of minutes-west).
+ (id)timeZoneForSecondsFromGMT:(int)seconds;

+ (id)timeZoneWithAbbreviation:(NSString *)abbreviation;

@end



// Note: To use the APIs described in these headers, you must perform
// a runtime check for Foundation-462.1 or later.



@class NSArray, NSData, NSDictionary, NSMutableDictionary, NSString;

FOUNDATION_EXPORT NSString * __const NSGlobalDomain;
FOUNDATION_EXPORT NSString * __const NSArgumentDomain;
FOUNDATION_EXPORT NSString * __const NSRegistrationDomain;

@interface NSUserDefaults : NSObject {
@private
    void *_preferences;
    NSMutableDictionary *_temp;
    NSString *_reserved;
    void *_reserved2;
    void *_reserved3;
}

+ (NSUserDefaults *)standardUserDefaults;
+ (void)resetStandardUserDefaults;

- (id)init;
- (id)initWithUser:(NSString *)username;

- (id)objectForKey:(NSString *)defaultName;
- (void)setObject:(id)value forKey:(NSString *)defaultName;
- (void)removeObjectForKey:(NSString *)defaultName;

- (NSString *)stringForKey:(NSString *)defaultName;
- (NSArray *)arrayForKey:(NSString *)defaultName;
- (NSDictionary *)dictionaryForKey:(NSString *)defaultName;
- (NSData *)dataForKey:(NSString *)defaultName;
- (NSArray *)stringArrayForKey:(NSString *)defaultName;
- (int)integerForKey:(NSString *)defaultName; 
- (float)floatForKey:(NSString *)defaultName; 
- (BOOL)boolForKey:(NSString *)defaultName;  

- (void)setInteger:(int)value forKey:(NSString *)defaultName;
- (void)setFloat:(float)value forKey:(NSString *)defaultName;
- (void)setBool:(BOOL)value forKey:(NSString *)defaultName;

- (void)registerDefaults:(NSDictionary *)registrationDictionary;

- (void)addSuiteNamed:(NSString *)suiteName;
- (void)removeSuiteNamed:(NSString *)suiteName;

- (NSDictionary *)dictionaryRepresentation;

- (NSArray *)volatileDomainNames;
- (NSDictionary *)volatileDomainForName:(NSString *)domainName;
- (void)setVolatileDomain:(NSDictionary *)domain forName:(NSString *)domainName;
- (void)removeVolatileDomainForName:(NSString *)domainName;

- (NSArray *)persistentDomainNames;
- (NSDictionary *)persistentDomainForName:(NSString *)domainName;
- (void)setPersistentDomain:(NSDictionary *)domain forName:(NSString *)domainName;
- (void)removePersistentDomainForName:(NSString *)domainName;

- (BOOL)synchronize;



@end

FOUNDATION_EXPORT NSString * __const NSUserDefaultsDidChangeNotification;

FOUNDATION_EXPORT NSString * __const NSWeekDayNameArray;
FOUNDATION_EXPORT NSString * __const NSShortWeekDayNameArray;
FOUNDATION_EXPORT NSString * __const NSMonthNameArray;
FOUNDATION_EXPORT NSString * __const NSShortMonthNameArray;
FOUNDATION_EXPORT NSString * __const NSTimeFormatString;
FOUNDATION_EXPORT NSString * __const NSDateFormatString;
FOUNDATION_EXPORT NSString * __const NSTimeDateFormatString;
FOUNDATION_EXPORT NSString * __const NSShortTimeDateFormatString;
FOUNDATION_EXPORT NSString * __const NSCurrencySymbol;
FOUNDATION_EXPORT NSString * __const NSDecimalSeparator;
FOUNDATION_EXPORT NSString * __const NSThousandsSeparator;
FOUNDATION_EXPORT NSString * __const NSDecimalDigits;
FOUNDATION_EXPORT NSString * __const NSAMPMDesignation;
FOUNDATION_EXPORT NSString * __const NSHourNameDesignations;
FOUNDATION_EXPORT NSString * __const NSYearMonthWeekDesignations;
FOUNDATION_EXPORT NSString * __const NSEarlierTimeDesignations;
FOUNDATION_EXPORT NSString * __const NSLaterTimeDesignations;
FOUNDATION_EXPORT NSString * __const NSThisDayDesignations;
FOUNDATION_EXPORT NSString * __const NSNextDayDesignations;
FOUNDATION_EXPORT NSString * __const NSNextNextDayDesignations;
FOUNDATION_EXPORT NSString * __const NSPriorDayDesignations;
FOUNDATION_EXPORT NSString * __const NSDateTimeOrdering;
FOUNDATION_EXPORT NSString * __const NSInternationalCurrencyString;
FOUNDATION_EXPORT NSString * __const NSShortDateFormatString;
FOUNDATION_EXPORT NSString * __const NSPositiveCurrencyFormatString;
FOUNDATION_EXPORT NSString * __const NSNegativeCurrencyFormatString;





















				











struct accessx_descriptor {
	unsigned ad_name_offset;
	int ad_flags;
	int ad_pad[2];
};







typedef __darwin_gid_t		gid_t;


typedef __darwin_off_t		off_t;

typedef __darwin_pid_t		pid_t;



typedef __darwin_uid_t		uid_t;	

typedef __darwin_useconds_t	useconds_t;

typedef __darwin_uuid_t		uuid_t;






















void	 _exit(int) __attribute__((__noreturn__));
int	 access(__const char *, int);
unsigned int
	 alarm(unsigned int);
int	 chdir(__const char *);
int	 chown(__const char *, uid_t, gid_t);
int	 close(int);
size_t	 confstr(int, char *, size_t);
char	*crypt(__const char *, __const char *);
char	*ctermid(char *);
int	 dup(int);
int	 dup2(int, int);
int	 execl(__const char *, __const char *, ...);
int	 execle(__const char *, __const char *, ...);
int	 execlp(__const char *, __const char *, ...);
int	 execv(__const char *, char * __const *);
int	 execve(__const char *, char * __const *, char * __const *);
int	 execvp(__const char *, char * __const *);
int	 fchown(int, uid_t, gid_t);
int	 fchdir(int);
pid_t	 fork(void);
long	 fpathconf(int, int);
int	 ftruncate(int, off_t);
char	*getcwd(char *, size_t);
gid_t	 getegid(void);
uid_t	 geteuid(void);
gid_t	 getgid(void);
int	 getgroups(int, gid_t []);
long	 gethostid(void);
int	 gethostname(char *, size_t);
char	*getlogin(void);
int	 getlogin_r(char *, size_t);
int	 getopt(int, char * __const [], __const char *);
pid_t	 getpgid(pid_t);
pid_t	 getpgrp(void);
pid_t	 getpid(void);
pid_t	 getppid(void);
pid_t	 getsid(pid_t);
uid_t	 getuid(void);
char	*getwd(char *);			
int	 isatty(int);
int	 lchown(__const char *, uid_t, gid_t) ;
int	 link(__const char *, __const char *);
int	 lockf(int, int, off_t);
off_t	 lseek(int, off_t, int);
int	 nice(int);
long	 pathconf(__const char *, int);
int	 pause(void);
int	 pipe(int [2]);
ssize_t	 pread(int, void *, size_t, off_t);
ssize_t	 pwrite(int, __const void *, size_t, off_t);
ssize_t	 read(int, void *, size_t);
ssize_t  readlink(__const char * , char * , size_t);
int	 rmdir(__const char *);
int	 setegid(gid_t);
int	 seteuid(uid_t);
int	 setgid(gid_t);
int	 setpgid(pid_t, pid_t);
int	 setpgrp(pid_t pid, pid_t pgrp);	
int	 setregid(gid_t, gid_t);
int	 setreuid(uid_t, uid_t);
pid_t	 setsid(void);
int	 setuid(uid_t);
unsigned int
	 sleep(unsigned int);
void     swab(__const void * , void * , ssize_t);
int	 symlink(__const char *, __const char *);
void	 sync(void);
long	 sysconf(int);
pid_t	 tcgetpgrp(int);
int	 tcsetpgrp(int, pid_t);
int	 truncate(__const char *, off_t);
char	*ttyname(int);
char	*ttyname_r(int, char *, size_t);
useconds_t
	 ualarm(useconds_t, useconds_t);
int	 unlink(__const char *);
int	 usleep(useconds_t);
pid_t	 vfork(void);
ssize_t	 write(int, __const void *, size_t);

extern char *optarg;			
extern int optind, opterr, optopt;







typedef	__darwin_time_t		time_t;

typedef __darwin_suseconds_t	suseconds_t;

typedef __darwin_sigset_t	sigset_t;

struct timespec {
	time_t	tv_sec;
	long	tv_nsec;
};






typedef	struct fd_set {
	__int32_t	fds_bits[(((1024) + (( (sizeof(__int32_t) * 8)) - 1)) / ( (sizeof(__int32_t) * 8)))];
} fd_set;
























typedef	unsigned char		u_int8_t;
typedef	unsigned short		u_int16_t;
typedef	unsigned int		u_int32_t;
typedef	unsigned long long	u_int64_t;

typedef int32_t			register_t;



// LP64todo - typedef mach_vm_address_t	user_addr_t;	 
// LP64todo - typedef mach_vm_size_t		user_size_t;	
typedef u_int64_t		user_addr_t;	
typedef u_int64_t		user_size_t;	
typedef int64_t			user_ssize_t;
typedef int64_t			user_long_t;
typedef u_int64_t		user_ulong_t;
typedef int64_t			user_time_t;


typedef u_int64_t		syscall_arg_t;


















































static __inline__
uint16_t
_OSSwapInt16(
    uint16_t        data
)
{
    return ((data << 8) | (data >> 8));
}

static __inline__
uint32_t
_OSSwapInt32(
    uint32_t        data
)
{
    __asm__ ("bswap   %0" : "+r" (data));
    return data;
}

static __inline__
uint64_t
_OSSwapInt64(
    uint64_t        data
)
{
    __asm__ ("bswap   %%eax\n\t"
             "bswap   %%edx\n\t" 
             "xchgl   %%eax, %%edx"
             : "+A" (data));
    return data;
}



static __inline__
uint16_t
OSReadSwapInt16(
    __const __volatile void   * base,
    uintptr_t       byteOffset
)
{
    uint16_t result;

    result = *(__volatile uint16_t *)((uintptr_t)base + byteOffset);
    return _OSSwapInt16(result);
}

static __inline__
uint32_t
OSReadSwapInt32(
    __const __volatile void   * base,
    uintptr_t       byteOffset
)
{
    uint32_t result;

    result = *(__volatile uint32_t *)((uintptr_t)base + byteOffset);
    return _OSSwapInt32(result);
}

static __inline__
uint64_t
OSReadSwapInt64(
    __const __volatile void   * base,
    uintptr_t       byteOffset
)
{
    uint64_t result;

    result = *(__volatile uint64_t *)((uintptr_t)base + byteOffset);
    return _OSSwapInt64(result);
}



static __inline__
void
OSWriteSwapInt16(
    __volatile void   * base,
    uintptr_t       byteOffset,
    uint16_t        data
)
{
    *(__volatile uint16_t *)((uintptr_t)base + byteOffset) = _OSSwapInt16(data);
}

static __inline__
void
OSWriteSwapInt32(
    __volatile void   * base,
    uintptr_t       byteOffset,
    uint32_t        data
)
{
    *(__volatile uint32_t *)((uintptr_t)base + byteOffset) = _OSSwapInt32(data);
}

static __inline__
void
OSWriteSwapInt64(
    __volatile void    * base,
    uintptr_t        byteOffset,
    uint64_t         data
)
{
    *(__volatile uint64_t *)((uintptr_t)base + byteOffset) = _OSSwapInt64(data);
}






enum {
    OSUnknownByteOrder,
    OSLittleEndian,
    OSBigEndian
};

static __inline__
int32_t
OSHostByteOrder(void) {
    return OSLittleEndian;
}




static __inline__
uint16_t
_OSReadInt16(
    __const __volatile void               * base,
    uintptr_t                     byteOffset
)
{
    return *(__volatile uint16_t *)((uintptr_t)base + byteOffset);
}

static __inline__
uint32_t
_OSReadInt32(
    __const __volatile void               * base,
    uintptr_t                     byteOffset
)
{
    return *(__volatile uint32_t *)((uintptr_t)base + byteOffset);
}

static __inline__
uint64_t
_OSReadInt64(
    __const __volatile void               * base,
    uintptr_t                     byteOffset
)
{
    return *(__volatile uint64_t *)((uintptr_t)base + byteOffset);
}



static __inline__
void
_OSWriteInt16(
    __volatile void               * base,
    uintptr_t                     byteOffset,
    uint16_t                      data
)
{
    *(__volatile uint16_t *)((uintptr_t)base + byteOffset) = data;
}

static __inline__
void
_OSWriteInt32(
    __volatile void               * base,
    uintptr_t                     byteOffset,
    uint32_t                      data
)
{
    *(__volatile uint32_t *)((uintptr_t)base + byteOffset) = data;
}

static __inline__
void
_OSWriteInt64(
    __volatile void               * base,
    uintptr_t                     byteOffset,
    uint64_t                      data
)
{
    *(__volatile uint64_t *)((uintptr_t)base + byteOffset) = data;
}









































 

uint16_t	ntohs(uint16_t);
uint16_t	htons(uint16_t);
uint32_t	ntohl(uint32_t);
uint32_t	htonl(uint32_t);








typedef	unsigned char		u_char;
typedef	unsigned short		u_short;
typedef	unsigned int		u_int;
typedef	unsigned long		u_long;
typedef	unsigned short		ushort;		
typedef	unsigned int		uint;		

typedef	u_int64_t		u_quad_t;	
typedef	int64_t			quad_t;
typedef	quad_t *		qaddr_t;

typedef	char *			caddr_t;	
typedef	int32_t			daddr_t;	

typedef	__darwin_dev_t		dev_t;		

typedef	u_int32_t		fixpt_t;	

typedef	__darwin_blkcnt_t	blkcnt_t;

typedef	__darwin_blksize_t	blksize_t;


typedef	__uint32_t		in_addr_t;	

typedef	__uint16_t		in_port_t;

typedef	__darwin_ino_t		ino_t;		

typedef	__int32_t		key_t;		

typedef	__darwin_mode_t		mode_t;

typedef	__uint16_t		nlink_t;	

typedef __darwin_id_t		id_t;		



typedef	int32_t			segsz_t;	
typedef	int32_t			swblk_t;	





typedef	__darwin_clock_t	clock_t;







typedef __int32_t	fd_mask;








typedef __darwin_pthread_attr_t		pthread_attr_t;
typedef __darwin_pthread_cond_t		pthread_cond_t;
typedef __darwin_pthread_condattr_t	pthread_condattr_t;
typedef __darwin_pthread_mutex_t	pthread_mutex_t;
typedef __darwin_pthread_mutexattr_t	pthread_mutexattr_t;
typedef __darwin_pthread_once_t		pthread_once_t;
typedef __darwin_pthread_rwlock_t	pthread_rwlock_t;
typedef __darwin_pthread_rwlockattr_t	pthread_rwlockattr_t;
typedef __darwin_pthread_t		pthread_t;


typedef __darwin_pthread_key_t		pthread_key_t;


typedef __darwin_fsblkcnt_t		fsblkcnt_t;

typedef __darwin_fsfilcnt_t		fsfilcnt_t;

















typedef __darwin_mcontext_t		mcontext_t;

typedef __darwin_mcontext64_t		mcontext64_t;





typedef __darwin_ucontext_t		ucontext_t;

typedef __darwin_ucontext64_t		ucontext64_t;


union sigval {
	
	int	sival_int;
	void	*sival_ptr;
};


struct sigevent {
	int				sigev_notify;				
	int				sigev_signo;				
	union sigval	sigev_value;				
	void			(*sigev_notify_function)(union sigval);	  
	pthread_attr_t	*sigev_notify_attributes;	
};

// LP64todo - should this move?

typedef struct __siginfo {
	int	si_signo;		
	int	si_errno;		
	int	si_code;		
	pid_t	si_pid;			
	uid_t	si_uid;			
	int	si_status;		
	void	*si_addr;		
	union sigval si_value;		
	long	si_band;		
	unsigned long	pad[7];		
} siginfo_t;





















union __sigaction_u {
	void    (*__sa_handler)(int);
	void    (*__sa_sigaction)(int, struct __siginfo *,
		       void *);
};


struct	__sigaction {
	union __sigaction_u __sigaction_u;  
	void    (*sa_tramp)(void *, int, int, siginfo_t *, void *);
	sigset_t sa_mask;		
	int	sa_flags;		
};


struct	sigaction {
	union __sigaction_u __sigaction_u;  
	sigset_t sa_mask;		
	int	sa_flags;		
};











typedef	void (*sig_t)(int);	



typedef __darwin_stack_t stack_t;



struct	sigvec {
	void	(*sv_handler)(int);	
	int	sv_mask;		
	int	sv_flags;		
};




struct	sigstack {
	char	*ss_sp;			
	int	ss_onstack;		
};








void	(*signal(int, void (*)(int)))(int);



extern __const char *__const sys_signame[32];
extern __const char *__const sys_siglist[32];


int	raise(int);



void	(*bsd_signal(int, void (*)(int)))(int);
int	kill(pid_t, int);
int	killpg(pid_t, int);
int	pthread_kill(pthread_t, int);
int	pthread_sigmask(int, __const sigset_t *, sigset_t *);
int	sigaction(int, __const struct sigaction * ,
	    struct sigaction * );
int	sigaddset(sigset_t *, int);
int	sigaltstack(__const stack_t * , stack_t * );
int	sigdelset(sigset_t *, int);
int	sigemptyset(sigset_t *);
int	sigfillset(sigset_t *);
int	sighold(int);
int	sigignore(int);
int	siginterrupt(int, int);
int	sigismember(__const sigset_t *, int);
int	sigpause(int);
int	sigpending(sigset_t *);
int	sigprocmask(int, __const sigset_t * , sigset_t * );
int	sigrelse(int);
void    (*sigset(int, void (*)(int)))(int); 
int	sigsuspend(__const sigset_t *);
int	sigwait(__const sigset_t * , int * );
void	psignal(unsigned int, __const char *);
int	sigblock(int);
int	sigreturn(struct sigcontext *);
int	sigsetmask(int);
int	sigvec(int, struct sigvec *, struct sigvec *);














struct timeval {
	time_t		tv_sec;		
	suseconds_t	tv_usec;	
};


struct	itimerval {
	struct	timeval it_interval;	
	struct	timeval it_value;	
};













struct timezone {
	int	tz_minuteswest;	
	int	tz_dsttime;	
};





struct clockinfo {
	int	hz;		
	int	tick;		
	int	tickadj;	
	int	stathz;		
	int	profhz;		
};















struct tm {
	int	tm_sec;		
	int	tm_min;		
	int	tm_hour;	
	int	tm_mday;	
	int	tm_mon;		
	int	tm_year;	
	int	tm_wday;	
	int	tm_yday;	
	int	tm_isdst;	
	long	tm_gmtoff;	
	char	*tm_zone;	
};







extern char *tzname[];

extern int getdate_err;
extern int daylight;


char *asctime(__const struct tm *);
clock_t clock(void);
char *ctime(__const time_t *);
double difftime(time_t, time_t);
struct tm *getdate(__const char *);
struct tm *gmtime(__const time_t *);
struct tm *localtime(__const time_t *);
time_t mktime(struct tm *);
size_t strftime(char * , size_t, __const char * , __const struct tm * ) ;
char *strptime(__const char * , __const char * , struct tm * );
time_t time(time_t *);

void tzset(void);

char *asctime_r(__const struct tm *, char *);
char *ctime_r(__const time_t *, char *);
struct tm *gmtime_r(__const time_t *, struct tm *);
struct tm *localtime_r(__const time_t *, struct tm *);
time_t posix2time(time_t);
char *timezone(int, int);
void tzsetwall(void);
time_t time2posix(time_t);
time_t timelocal(struct tm * __const);
time_t timegm(struct tm * __const);

int nanosleep(__const struct timespec *, struct timespec *) ;




int	adjtime(__const struct timeval *, struct timeval *);
int	futimes(int, __const struct timeval *);
int	settimeofday(__const struct timeval *, __const struct timezone *);

int	getitimer(int, struct itimerval *);
int	gettimeofday(struct timeval * , struct timezone * );
int	select(int, fd_set * , fd_set * ,
		fd_set * , struct timeval * );
int	setitimer(int, __const struct itimerval * ,
		struct itimerval * );
int	utimes(__const char *, __const struct timeval *);






int	 pselect(int, fd_set * , fd_set * ,
		fd_set * , __const struct timespec * ,
		__const sigset_t * );
int	 select(int, fd_set * , fd_set * ,
		fd_set * , struct timeval * );



void	 _Exit(int) __attribute__((__noreturn__));
int	 accessx_np(__const struct accessx_descriptor *, size_t, int *, uid_t);
int	 acct(__const char *);
int	 add_profil(char *, size_t, unsigned long, unsigned int);
int	 async_daemon(void);
void	*brk(__const void *);
int	 chroot(__const char *);
int	 encrypt(char *, int);
void	 endusershell(void);
int	 execvP(__const char *, __const char *, char * __const *);
char	*fflagstostr(unsigned long);
int	 fsync(int);
int	 getdtablesize(void);
int	 getdomainname(char *, int);
int	 getgrouplist(__const char *, int, int *, int *);
mode_t	 getmode(__const void *, mode_t);
int	 getpagesize(void) __attribute__((__const__));
char	*getpass(__const char *);
int	 getpeereid(int, uid_t *, gid_t *);
int	 getpgid(pid_t _pid);
int	 getsgroups_np(int *, uuid_t);
int	 getsid(pid_t _pid);
char	*getusershell(void);
int	 getwgroups_np(int *, uuid_t);
int	 initgroups(__const char *, int);
int	 iruserok(unsigned long, int, __const char *, __const char *);
int	 issetugid(void);
char	*mkdtemp(char *);
int	 mknod(__const char *, mode_t, dev_t);
int	 mkstemp(char *);
int	 mkstemps(char *, int);
char	*mktemp(char *);
int	 nfssvc(int, void *);
int	 profil(char *, size_t, unsigned long, unsigned int);
int	 pthread_setugid_np(uid_t, gid_t);
int	 pthread_getugid_np( uid_t *, gid_t *);
int	 rcmd(char **, int, __const char *, __const char *, __const char *, int *);
int	 reboot(int);
int	 revoke(__const char *);
int	 rresvport(int *);
int	 rresvport_af(int *, int);
int	 ruserok(__const char *, int, __const char *, __const char *);
void	*sbrk(int);
int	 setdomainname(__const char *, int);
int	 setgroups(int, __const gid_t *);
void	 sethostid(long);
int	 sethostname(__const char *, int);
int	 setkey(__const char *);
int	 setlogin(__const char *);
void	*setmode(__const char *);
int	 setrgid(gid_t);
int	 setruid(uid_t);
int	 setsgroups_np(int, __const uuid_t);
void	 setusershell(void);
int	 setwgroups_np(int, __const uuid_t);
int	 strtofflags(char **, unsigned long *, unsigned long *);
int	 swapon(__const char *);
int	 syscall(int, ...);
int	 ttyslot(void);
int	 undelete(__const char *);
int	 unwhiteout(__const char *);
void	*valloc(size_t);			

extern char *suboptarg;			
int	 getsubopt(char **, char * __const *, char **);


int	getattrlist(__const char*,void*,void*,size_t,unsigned long) ;
int	setattrlist(__const char*,void*,void*,size_t,unsigned long) ;
int exchangedata(__const char*,__const char*,unsigned long);
int	checkuseraccess(__const char*,uid_t,gid_t*,int,int,unsigned long);
int	getdirentriesattr(int,void*,void*,size_t,unsigned long*,unsigned long*,unsigned long*,unsigned long);
int	searchfs(__const char*,void*,void*,unsigned long,unsigned long,void*);

int fsctl(__const char *,unsigned long,void*,unsigned long);		

extern int optreset;




// #define SIGNATURE_FORMAT_STRING  @"%s (%d.%s) [%s %d]\n"



extern id GSError (id errObject, NSString *format, ...);

extern NSString * __const GSHTTPPropertyMethodKey;
extern NSString * __const GSHTTPPropertyProxyHostKey;
extern NSString * __const GSHTTPPropertyProxyPortKey;

@interface Protocol (NSPrivate)

- (NSMethodSignature *) _methodSignatureForInstanceMethod:(SEL)aSel;
- (NSMethodSignature *) _methodSignatureForClassMethod:(SEL)aSel;

@end

@interface NSBundle (NSPrivate)
- (NSEnumerator *) _resourcePathEnumeratorFor:(NSString*) path subPath:(NSString *) subpath localization:(NSString *)locale;
@end

@interface NSXMLParser (NSPrivate)

- (BOOL) _parseData:(NSData *) data;	// parse next junk for incremental parsing (use 0 to denote EOF)
- (NSArray *) _tagPath;	// use [[parser _tagPath] componentsJoinedByString:@"."] to get a string like @"plist.dictionary.array.string"
- (BOOL) _acceptsHTML;
// - (void) _setAcceptHTML:(BOOL) flag;	// automatically detected
- (NSStringEncoding) _encoding;
- (void) _setEncoding:(NSStringEncoding) enc;
- (void) _stall:(BOOL) flag;	// stall - i.e. queue up calls to delegate methods
- (BOOL) _isStalled;

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
+ (NSString *) _stringWithUTF8String:(__const char *) bytes length:(unsigned) len;
+ (id) _initWithUTF8String:(__const char *) bytes length:(unsigned) len;
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

- (NSString*)descriptionWithLocale:(NSDictionary*)locale
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
- (int) _readFileDescriptor;			// the fd to watch (-1 to ignore)
- (int) _writeFileDescriptor;			// the fd to watch
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
+ (id) dataWithSharedBytes:(__const void*)sbytes length:(unsigned) length;
+ (id) dataWithStaticBytes:(__const void*)sbytes length:(unsigned) length;

- (void *) _autoFreeBytesWith0:(BOOL) flag;		// return a "autofreed" copy - optionally with a trailing 0

- (unsigned char) _deserializeTypeTagAtCursor:(unsigned*)cursor;
- (unsigned) _deserializeCrossRefAtCursor:(unsigned*)cursor;

@end


@interface NSMutableData (NSPrivate)

// Capacity management - mySTEP gives you control over the size of
// the data buffer as well as the 'length' of valid data in it.
- (unsigned int) capacity;
- (id) setCapacity: (unsigned int)newCapacity;

- (int) shmID;	

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


// FIXME: move to NSMethodSignature private implementation

typedef struct NSArgumentInfo
{ // Info about layout of arguments. Extended from the original OpenStep version
	int offset;
	unsigned size;					// let us know if the arg is passed in 
	__const char *type;				// registers or on the stack.  OS 4.0 only
	unsigned align;					// alignment
	unsigned qual;					// qualifier (oneway, byref, bycopy, in, inout, out)
	unsigned index;					// argument index (to decode return=0, self=1, and _cmd=2)
	BOOL isReg;						// is passed in a register (+)
	BOOL byRef;						// argument is not passed by value but by pointer (i.e. structs)
	BOOL floatAsDouble;				// its a float value that is passed as double
} NSArgumentInfo;

@interface NSMethodSignature (NSPrivate)

+ (NSMethodSignature*) signatureWithObjCTypes:(__const char*)types;	// create from @encode() - exists undocumented in Cocoa with this name

- (unsigned) _getArgumentLengthAtIndex:(int)index;
- (unsigned) _getArgumentQualifierAtIndex:(int)index;
- (__const char *) _getArgument:(void *) buffer fromFrame:(arglist_t) _argframe atIndex:(int) index;
- (void) _setArgument:(void *) buffer forFrame:(arglist_t) _argframe atIndex:(int) index;
- (void) _prepareFrameForCall:(arglist_t) _argframe;
- (id) _initWithObjCTypes:(__const char*) t;
- (NSArgumentInfo *) _methodInfo;	// method info array - FIXME: remove
- (__const char *) _methodType;		// total method type

@end

@interface NSInvocation (NSPrivate)

- (id) initWithMethodSignature:(NSMethodSignature*) aSignature;		// this one exists undocumented in Cocoa

- (id) _initWithMethodSignature:(NSMethodSignature*) aSignature andArgFrame:(arglist_t) argFrame;
// - (id) _initWithSelector:(SEL) aSelector andArgFrame:(arglist_t) argFrame;
- (retval_t) _returnValue;

@end

@interface NSObject (NSObjCRuntime)					// special
- (retval_t) forward:(SEL)aSel :(arglist_t)argFrame;	// private method called by runtime
@end

@interface NSProxy (NSPrivate)
+ (void) load;
- (NSString*) descriptionWithLocale:(NSDictionary*)locale indent:(unsigned int)indent;
- (NSString*) descriptionWithLocale:(NSDictionary*)locale;
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
@end

@interface NSDistantObjectRequest (NSPrivate)
- (id) _initWithPortCoder:(NSPortCoder *) coder;
- (NSPortCoder *) _portCoder;
@end

@interface NSDistantObject (NSPrivate)
- (id) _localObject;
@end

@interface NSConnection (NSPrivate)

// these methods exist in Cocoa but are not documented

- (void) dispatchInvocation:(NSInvocation *) i;
- (void) handlePortCoder:(NSPortCoder *) coder;
- (void) handlePortMessage:(NSPortMessage *) message;
- (void) handleRequest:(NSDistantObjectRequest *) req sequence:(int) seq;
- (void) sendInvocation:(NSInvocation *) i;

// really private methods
- (void) _addAuthentication:(NSMutableArray *) components;
- (NSDistantObject *) _getLocal:(id) ref;
- (void) _mapLocal:(NSDistantObject *) obj forRef:(id) ref;
- (NSDistantObject *) _getRemote:(id) ref;
- (void) _mapRemote:(NSDistantObject *) obj forRef:(id) ref;
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
	unsigned __const char *_buffer;
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

@interface _NSSocketInputStream : NSInputStream
@end

@interface _NSSocketOutputStream : NSOutputStream
{
	NSHost *_host;
	int _port;
	// socks level and proxy config
	// security level
}
- (void) _setHost:(NSHost *) host andPort:(int) port;
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


//
// Class variables
//
static Class __mutableArrayClass = 0;
static Class __arrayClass = 0;
static Class __stringClass = 0;


/


@interface NSArrayEnumerator : NSArrayEnumeratorReverse
{
	int _count;
}
@end

@implementation NSArrayEnumerator

- (id) initWithArray:(NSArray*)anArray and:(id*)contents
{
	_contents = contents;
	_array = [anArray retain];
	_count = [_array count];

	return [self autorelease];
}

- (id) nextObject
{
	return (_index >= _count) ? 0 : _contents[_index++];
}

- (id) previousObject
{
	return (_index < 0) ? 0 : _contents[_index--];
}

@end 

/

/








 





typedef enum {
	P_ALL,
	P_PID,
	P_PGID
} idtype_t;


















typedef __int64_t	rlim_t;















struct	rusage {
	struct timeval ru_utime;	
	struct timeval ru_stime;	
	
	long	ru_maxrss;		
	long	ru_ixrss;		
	long	ru_idrss;		
	long	ru_isrss;		
	long	ru_minflt;		
	long	ru_majflt;		
	long	ru_nswap;		
	long	ru_inblock;		
	long	ru_oublock;		
	long	ru_msgsnd;		
	long	ru_msgrcv;		
	long	ru_nsignals;		
	long	ru_nvcsw;		
	long	ru_nivcsw;		
};



// LP64todo - should this move?









struct rlimit {
	rlim_t	rlim_cur;		
	rlim_t	rlim_max;		
};




int	getpriority(int, id_t);
int	getrlimit(int, struct rlimit *);
int	getrusage(int, struct rusage *);
int	setpriority(int, id_t, int);
int	setrlimit(int, __const struct rlimit *);























union wait {
	int	w_status;		
	
	struct {
		unsigned int	w_Termsig:7,	
				w_Coredump:1,	
				w_Retcode:8,	
				w_Filler:16;	
	} w_T;
	
	struct {
		unsigned int	w_Stopval:8,	
				w_Stopsig:8,	
				w_Filler:16;	
	} w_S;
};




pid_t	wait(int *);
pid_t	waitpid(pid_t, int *, int);
int	waitid(idtype_t, id_t, siginfo_t *, int);
pid_t	wait3(int *, int, struct rusage *);
pid_t	wait4(pid_t, int *, int, struct rusage *);







void	*alloca(size_t);		






typedef	__darwin_ct_rune_t	ct_rune_t;

typedef __darwin_rune_t   	rune_t;

typedef	__darwin_wchar_t	wchar_t;

typedef struct {
	int quot;		
	int rem;		
} div_t;

typedef struct {
	long quot;		
	long rem;		
} ldiv_t;

typedef struct {
	long long quot;
	long long rem;
} lldiv_t;





extern int __mb_cur_max;



void	 abort(void) __attribute__((__noreturn__));
int	 abs(int) __attribute__((__const__));
int	 atexit(void (*)(void));
double	 atof(__const char *);
int	 atoi(__const char *);
long	 atol(__const char *);
long long
	 atoll(__const char *);
void	*bsearch(__const void *, __const void *, size_t,
	    size_t, int (*)(__const void *, __const void *));
void	*calloc(size_t, size_t);
div_t	 div(int, int) __attribute__((__const__));
void	 exit(int) __attribute__((__noreturn__));
void	 free(void *);
char	*getenv(__const char *);
long	 labs(long) __attribute__((__const__));
ldiv_t	 ldiv(long, long) __attribute__((__const__));
long long
	 llabs(long long);
lldiv_t	 lldiv(long long, long long);
void	*malloc(size_t);
int	 mblen(__const char *, size_t);
size_t	 mbstowcs(wchar_t *  , __const char * , size_t);
int	 mbtowc(wchar_t * , __const char * , size_t);
void	 qsort(void *, size_t, size_t,
	    int (*)(__const void *, __const void *));
int	 rand(void);
void	*realloc(void *, size_t);
void	 srand(unsigned);
double	 strtod(__const char *, char **);
float	 strtof(__const char *, char **);
long	 strtol(__const char *, char **, int);
long double
	 strtold(__const char *, char **) ;
long long 
	 strtoll(__const char *, char **, int);
unsigned long
	 strtoul(__const char *, char **, int);
unsigned long long
	 strtoull(__const char *, char **, int);
int	 system(__const char *);
size_t	 wcstombs(char * , __const wchar_t * , size_t);
int	 wctomb(char *, wchar_t);

void	_Exit(int) __attribute__((__noreturn__));
long	 a64l(__const char *);
double	 drand48(void);
char	*ecvt(double, int, int *, int *); 
double	 erand48(unsigned short[3]); 
char	*fcvt(double, int, int *, int *); 
char	*gcvt(double, int, char *); 
int	 getsubopt(char **, char * __const *, char **);
int	 grantpt(int);
char	*initstate(unsigned long, char *, long);
long	 jrand48(unsigned short[3]);
char	*l64a(long);
void	 lcong48(unsigned short[7]);
long	 lrand48(void);
char	*mktemp(char *);
int	 mkstemp(char *);
long	 mrand48(void); 
long	 nrand48(unsigned short[3]);
int	 posix_openpt(int);
char	*ptsname(int);
int	 putenv(char *) ;
long	 random(void);
char	*realpath(__const char *, char *resolved_path);
unsigned short
	*seed48(unsigned short[3]);
int	 setenv(__const char *, __const char *, int) ;
int	 setkey(__const char *);
char	*setstate(__const char *);
void	 srand48(long);
void	 srandom(unsigned long);
int	 unlockpt(int);
void	 unsetenv(__const char *);




u_int32_t
	 arc4random(void);
void	 arc4random_addrandom(unsigned char *dat, int datlen);
void	 arc4random_stir(void);

	 
char	*cgetcap(char *, __const char *, int);
int	 cgetclose(void);
int	 cgetent(char **, char **, __const char *);
int	 cgetfirst(char **, char **);
int	 cgetmatch(__const char *, __const char *);
int	 cgetnext(char **, char **);
int	 cgetnum(char *, __const char *, long *);
int	 cgetset(__const char *);
int	 cgetstr(char *, __const char *, char **);
int	 cgetustr(char *, __const char *, char **);

int	 daemon(int, int);
char	*devname(dev_t, mode_t);
char	*devname_r(dev_t, mode_t, char *buf, int len);
char	*getbsize(int *, long *);
int	 getloadavg(double [], int);
__const char
	*getprogname(void);

int	 heapsort(void *, size_t, size_t,
	    int (*)(__const void *, __const void *));
int	 mergesort(void *, size_t, size_t,
	    int (*)(__const void *, __const void *));
void	 qsort_r(void *, size_t, size_t, void *,
	    int (*)(void *, __const void *, __const void *));
int	 radixsort(__const unsigned char **, int, __const unsigned char *,
	    unsigned);
void	 setprogname(__const char *);
int	 sradixsort(__const unsigned char **, int, __const unsigned char *,
	    unsigned);
void	 sranddev(void);
void	 srandomdev(void);
int	 rand_r(unsigned *);
void	*reallocf(void *, size_t);
long long
	 strtoq(__const char *, char **, int);
unsigned long long
	 strtouq(__const char *, char **, int);
extern char *suboptarg;		
void	*valloc(size_t);










typedef struct
{
    char *lo;
    char *hi;
} stack_node;






void qsort3(void *__const pbase, size_t total_elems, size_t size, int (*cmp)(id, id, void *), void *context)
{
	register char *base_ptr = (char *) pbase;
	
	
	char *pivot_buffer = (char *) __builtin_alloca(size);
	__const size_t max_thresh = 4 * size;
	
	if (total_elems == 0)
		
		return;
	
	if (total_elems > 4)
		{
		char *lo = base_ptr;
		char *hi = &lo[size * (total_elems - 1)];
		
		stack_node stack[(8 * sizeof(unsigned long int))];
		stack_node *top = stack + 1;
		
		while ((stack < top))
			{
			char *left_ptr;
			char *right_ptr;
			
			char *pivot = pivot_buffer;
			
			
			
			char *mid = lo + size * ((hi - lo) / size >> 1);
			
			if ((*cmp) (*(id *) mid, *(id *) lo, context) < 0)
				do									      {									      	register size_t __size = ( size);					      		register char *__a = (mid), *__b = ( lo);				      			do								      				{								      					char __tmp = *__a;						      						*__a++ = *__b;						      							*__b++ = __tmp;						      				} while (--__size > 0);						      } while (0);
			if ((*cmp) (*(id *) hi, *(id *) mid, context) < 0)
				do									      {									      	register size_t __size = ( size);					      		register char *__a = (mid), *__b = ( hi);				      			do								      				{								      					char __tmp = *__a;						      						*__a++ = *__b;						      							*__b++ = __tmp;						      				} while (--__size > 0);						      } while (0);
			else
				goto jump_over;
			if ((*cmp) (*(id *) mid, *(id *) lo, context) < 0)
				do									      {									      	register size_t __size = ( size);					      		register char *__a = (mid), *__b = ( lo);				      			do								      				{								      					char __tmp = *__a;						      						*__a++ = *__b;						      							*__b++ = __tmp;						      				} while (--__size > 0);						      } while (0);
jump_over:;
			memcpy (pivot, mid, size);
			pivot = pivot_buffer;
			
			left_ptr  = lo + size;
			right_ptr = hi - size;
			
			
			do
				{
					while ((*cmp) (*(id *) left_ptr, *(id *) pivot, context) < 0)
						left_ptr += size;
					
					while ((*cmp) (*(id *) pivot, *(id *) right_ptr, context) < 0)
						right_ptr -= size;
					
					if (left_ptr < right_ptr)
						{
						do									      {									      	register size_t __size = ( size);					      		register char *__a = (left_ptr), *__b = ( right_ptr);				      			do								      				{								      					char __tmp = *__a;						      						*__a++ = *__b;						      							*__b++ = __tmp;						      				} while (--__size > 0);						      } while (0);
						left_ptr += size;
						right_ptr -= size;
						}
					else if (left_ptr == right_ptr)
						{
						left_ptr += size;
						right_ptr -= size;
						break;
						}
				}
			while (left_ptr <= right_ptr);
			
			
			
			if ((size_t) (right_ptr - lo) <= max_thresh)
				{
				if ((size_t) (hi - left_ptr) <= max_thresh)
					
					((void) (--top, (lo = top->lo), ( hi = top->hi)));
				else
					
					lo = left_ptr;
				}
			else if ((size_t) (hi - left_ptr) <= max_thresh)
				
				hi = right_ptr;
			else if ((right_ptr - lo) > (hi - left_ptr))
				{
				
				((void) ((top->lo = (lo)), (top->hi = ( right_ptr)), ++top));
				lo = left_ptr;
				}
			else
				{
				
				((void) ((top->lo = (left_ptr)), (top->hi = ( hi)), ++top));
				hi = right_ptr;
				}
			}
		}
	
	
	
	
	{
		char *__const end_ptr = &base_ptr[size * (total_elems - 1)];
		char *tmp_ptr = base_ptr;
		char *thresh = ((end_ptr) < ( base_ptr + max_thresh) ? (end_ptr) : ( base_ptr + max_thresh));
		register char *run_ptr;
		
		
		
		for (run_ptr = tmp_ptr + size; run_ptr <= thresh; run_ptr += size)
			if ((*cmp) (*(id *) run_ptr, *(id *) tmp_ptr, context) < 0)
				tmp_ptr = run_ptr;
		
		if (tmp_ptr != base_ptr)
			do									      {									      	register size_t __size = ( size);					      		register char *__a = (tmp_ptr), *__b = ( base_ptr);				      			do								      				{								      					char __tmp = *__a;						      						*__a++ = *__b;						      							*__b++ = __tmp;						      				} while (--__size > 0);						      } while (0);
		
		
		
		run_ptr = base_ptr + size;
		while ((run_ptr += size) <= end_ptr)
			{
			tmp_ptr = run_ptr - size;
			while ((*cmp) (*(id *) run_ptr, *(id *) tmp_ptr, context) < 0)
				tmp_ptr -= size;
			
			tmp_ptr += size;
			if (tmp_ptr != run_ptr)
				{
				char *trav;
				
				trav = run_ptr + size;
				while (--trav >= run_ptr)
					{
					char c = *trav;
					char *hi, *lo;
					
					for (hi = lo = trav; (lo -= size) >= tmp_ptr; hi = lo)
						*hi = *lo;
					*hi = c;
					}
				}
			}
	}
}

							// good value for stride factor is not well

- (void) sortUsingFunction:(int(*)(id,id,void*))compare context:(void*)context
{
	unsigned c, d, stride = 1;							// Shell sort algorithm 
													// from SortingInAction, a
	if(_count > 20) 
		{ // use quick sort instead 
		qsort3(_contents, _count, sizeof(_contents[0]), compare, context); 
		return; 
		}
	while (stride <= _count)						// NeXT example
		stride = stride * 3		// understood 3 is a fairly good choice (Sedgewick) + 1;

	while(stride > (3		// understood 3 is a fairly good choice (Sedgewick) - 1)) 			// loop to sort for each 
		{											// value of stride
		stride = stride / 3		// understood 3 is a fairly good choice (Sedgewick);
		for (c = stride; c < _count; c++) 
			{
			BOOL found = (BOOL)0;

			if (stride > c)
				break;
			d = c - stride;
			while (!found) 							// move to left until the 
				{									// correct place is found
				id a = _contents[d + stride];
				id b = _contents[d];

				if ((*compare)(a, b, context) == NSOrderedAscending) 
					{
					_contents[d + stride] = b;
					_contents[d] = a;
					if (stride > d)
						break;
					d -= stride;					// jump by stride factor
					}
				else 
					found = (BOOL)1;
		}	}	}
}

static int selector_compare(id elem1, id elem2, void* comparator)
{
    return (int)(long)[elem1 performSelector:(SEL)comparator withObject:elem2];
}

- (void) sortUsingSelector:(SEL)comparator
{
    [self sortUsingFunction:selector_compare context:(void*)comparator];
}

@end 
