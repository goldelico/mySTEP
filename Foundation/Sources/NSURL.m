/** NSUrl.m - Class NSURL
 Copyright (C) 1999 Free Software Foundation, Inc.
 
 Written by: 	Manuel Guesdon <mguesdon@sbuilders.com>
 Date: 	Jan 1999
 
 Rewrite by: 	Richard Frith-Macdonald <rfm@gnu.org>
 Date: 	Jun 2002
 
 This file is part of the GNUstep Library.
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Library General Public
 License as published by the Free Software Foundation; either
 version 2 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful, 
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Library General Public License for more details.
 
 You should have received a copy of the GNU Library General Public
 License along with this library; if not, write to the Free
 Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
 
 <title>NSURL class reference</title>
 $Date: 2003/01/16 15:09:18 $ $Revision: 1.30 $
 */

/*
 Note from Manuel Guesdon: 
 * I've made some test to compare apple NSURL results 
 and GNUstep NSURL results but as there this class is not very documented, some
 function may be incorrect
 * I've put 2 functions to make tests. You can add your own tests
 * Some functions are not implemented
 */

#import <Foundation/NSObject.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSURLHandle.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSValue.h>

NSString *NSURLFileScheme = @"file";

/*
 * Structure describing a URL.
 * All the char* fields may be NULL pointers, except path, which
 * is *always* non-null (though it may be an empty string).
 */

// FIXME - what is the character encoding??? UTF-8???
// why not keep it as NSStrings and encode only if needed?

typedef struct {
	NSString *absolute;		// Cache absolute string or nil
	char	*scheme;		// scheme or NULL
	char	*user;			// user or NULL
	char	*password;		// password or NULL
	char	*host;			// host or NULL
	char	*port;			// port or NULL
	char	*path;			// does not include leading / (because we need the buffer to delimit the host:port) - may be NULL (e.g. for data:)
	char	*parameters;	// parameters or NULL
	char	*query;			// query or NULL
	char	*fragment;		// fragment
	BOOL	pathIsAbsolute;	// path starts with / (which has not been stored!)
	BOOL	isFile;			// is file: URL
} parsedURL;

#define	myData ((parsedURL*)(self->_data))

// FIXME: this is seen as a problem by Clang since it may derefence baseData->something as NULL->something

#define	baseData ((self->_baseURL)?((parsedURL*)(self->_baseURL->_data)):NULL)

static NSLock	*clientsLock = nil;

/*
 * Local utility functions.
 */
static char *buildURL(parsedURL *base, parsedURL *rel, BOOL standardize, BOOL pathonly);
static id clientForHandle(void *data, NSURLHandle *hdl);
static char *findUp(char *str);
static NSString *unescape(const char *from);

/**
 * Build an absolute URL as a C string
 */
static char *buildURL(parsedURL *base, parsedURL *rel, BOOL standardize, BOOL pathonly)
{
	char		*buf;
	char		*ptr;
	char		*tmp;
	unsigned int	len = 1;
	
	if(!rel->path)
		return NULL;	// has no path
	if(!pathonly)
		{
		if (rel->scheme)
			len += strlen(rel->scheme) + 3;	// scheme://
		else if(base && base->scheme)
			len += strlen(base->scheme) + 3;	// scheme://
		
		if (rel->user)
			len += strlen(rel->user) + 1;	// user...@
		else if(base && base->user)
			len += strlen(base->user) + 1;	// user...@
		
		if (rel->password)
			len += strlen(rel->password) + 1;	// :password
		else if(base && base->password)
			len += strlen(base->password) + 1;	// :password
		
		if (rel->host)
			len += strlen(rel->host) + 1;	// host.../
		else if(base && base->host)
			len += strlen(base->host) + 1;	// host.../
		
		if (rel->port)
			len += strlen(rel->port) + 1;	// :port
		else if(base && base->port)
			len += strlen(base->port) + 1;	// :port		
		
		if (rel->parameters)
			len += strlen(rel->parameters) + 1;	// ;parameters
		
		if (rel->query)
			len += strlen(rel->query) + 1;		// ?query
		
		if (rel->fragment)
			len += strlen(rel->fragment) + 1;		// #fragment
		}
	
	if (rel->path)
		len += strlen(rel->path) + 1;	// /path
	if (base && base->path)
		len += strlen(base->path) + 1;	// /path
	
	ptr = buf = (char*)objc_malloc(len);
	
	if(!pathonly)
		{
		if (rel->scheme)
			{
			strcpy(ptr, rel->scheme);
			ptr = &ptr[strlen(ptr)];
			*ptr++ = ':';
			}
		else if(base && base->scheme)
			{
			strcpy(ptr, base->scheme);
			ptr = &ptr[strlen(ptr)];
			*ptr++ = ':';
			}
		
		if (rel->user != NULL || rel->password != NULL || rel->host != NULL || rel->port != NULL)
			{
			*ptr++ = '/';
			*ptr++ = '/';
			if (rel->user != NULL || rel->password != NULL)
				{
				if (rel->user != NULL)
					{
					strcpy(ptr, rel->user);
					ptr = &ptr[strlen(ptr)];
					}
				if (rel->password != NULL)
					{
					*ptr++ = ':';
					strcpy(ptr, rel->password);
					ptr = &ptr[strlen(ptr)];
					}
				if (rel->host != NULL || rel->port != NULL)
					*ptr++ = '@';
				}
			if (rel->host != NULL)
				{
				strcpy(ptr, rel->host);
				ptr = &ptr[strlen(ptr)];
				}
			if (rel->port != NULL)
				{
				*ptr++ = ':';
				strcpy(ptr, rel->port);
				ptr = &ptr[strlen(ptr)];
				}
			}
		else if (base && (base->user != NULL || base->password != NULL || base->host != NULL || base->port != NULL))
			{
			*ptr++ = '/';
			*ptr++ = '/';
			if (base->user != NULL || base->password != NULL)
				{
				if (base->user != NULL)
					{
					strcpy(ptr, base->user);
					ptr = &ptr[strlen(ptr)];
					}
				if (base->password != NULL)
					{
					*ptr++ = ':';
					strcpy(ptr, base->password);
					ptr = &ptr[strlen(ptr)];
					}
				if (base->host != NULL || base->port != NULL)
					{
					*ptr++ = '@';
					}
				}
			if (base->host != NULL)
				{
				strcpy(ptr, base->host);
				ptr = &ptr[strlen(ptr)];
				}
			if (base->port != NULL)
				{
				*ptr++ = ':';
				strcpy(ptr, base->port);
				ptr = &ptr[strlen(ptr)];
				}
			}		
		}
	
	/*
	 * Now build path by merging rel and base as needed
	 * (path string must exist)
	 */
	
	tmp = ptr;
	if(!base || rel->pathIsAbsolute)
		{ // overwrite base path by new one
			if (rel->pathIsAbsolute)
				*tmp++ = '/';
			strcpy(tmp, rel->path);
		}
	else if (rel->path[0] == 0)
		{ // there is no new path
			if (base->pathIsAbsolute)
				*tmp++ = '/';
			strcpy(tmp, base->path);
		}
	else
		{ // strip off last component of base path and append relative path
			char	*start = base->path;
			char	*end = strrchr(start, '/');
			if(!base->scheme)
				return NULL;	// can merge only if scheme exists or absolute path
			if (end != NULL)
				{
				*tmp++ = '/';
				strncpy(tmp, start, end - start);
				tmp += (end - start);
				}
			*tmp++ = '/';
			strcpy(tmp, rel->path);
		}
	
	if (standardize)
		{
		/*
		 * Compact '/./'  to '/' and strip any trailing '/.'
		 */
		tmp = ptr;
		while (*tmp != '\0')
			{
			if (tmp[0] == '/' && tmp[1] == '.'
				&& (tmp[2] == '/' || tmp[2] == '\0'))
				{
				/*
				 * Ensure we don't remove the leading '/'
				 */
				if (tmp == ptr && tmp[2] == '\0')
					tmp[1] = '\0';
				else
					strcpy(tmp, &tmp[2]);
				}
			else
				tmp++;
			}
		/*
		 * Reduce any sequence of '/' characters to a single '/'
		 */
		tmp = ptr;
		while (*tmp != '\0')
			{
			if (tmp[0] == '/' && tmp[1] == '/')
				strcpy(tmp, &tmp[1]);
			else
				tmp++;
			}
		/*
		 * Reduce any '/something/../' sequence to '/' and a trailing
		 * "/something/.." to ""
		 */ 
		tmp = ptr;
		while ((tmp = findUp(tmp)) != 0)
			{
			char	*next = &tmp[3];
			
			while (tmp > ptr)
				{
				if (*--tmp == '/')
					break;
				}
			/*
			 * Ensure we don't remove the leading '/'
			 */
			if (tmp == ptr && *next == '\0')
				tmp[1] = '\0';
			else
				strcpy(tmp, next);
			}
		/*
		 * if we have an empty path, we standardize to a single slash.
		 */
		tmp = ptr;
		if (*tmp == '\0')
			{
			strcpy(tmp, "/");
			}
		}
	ptr = &ptr[strlen(ptr)];
	
	if(!pathonly)
		{
		if (rel->parameters != NULL)
			{
			*ptr++ = ';';
			strcpy(ptr, rel->parameters);
			ptr = &ptr[strlen(ptr)];
			}
		if (rel->query != NULL)
			{
			*ptr++ = '?';
			strcpy(ptr, rel->query);
			ptr = &ptr[strlen(ptr)];
			}
		if (rel->fragment != NULL)
			{
			*ptr++ = '#';
			strcpy(ptr, rel->fragment);
			ptr = &ptr[strlen(ptr)];	// last fragment
			}
		
		}
#if 1
	//	if(!(ptr-buf <= len))
	fprintf(stderr, "len=%u used=%u, str=%s\n", len, ptr-buf, buf);
#endif
	NSCAssert(ptr-buf <= len, @"buffer overflow");
	
	return buf;
}

static id clientForHandle(void *data, NSURLHandle *hdl)
{
	id	client = nil;
	
	if (data != 0)
		{
#if 0
		NSLog(@"NSURL: clientsLock lock");
#endif
		[clientsLock lock];
		client = (id)NSMapGet((NSMapTable*)data, hdl);
		[clientsLock unlock];
		}
	return client;
}

/**
 * Locate a '/../ or trailing '/..' 
 */
static char *findUp(char *str)
{
	while (*str != '\0')
		{
		if (str[0] == '/' && str[1] == '.' && str[2] == '.'
			&& (str[3] == '/' || str[3] == '\0'))
			{
			return str;
			}
		str++;
		}
	return 0;
}

/*
 * Check a string to see if it contains only legal data characters
 * which are
 *   alphanum
 *   mark
 *   or percent escape sequences.
 */
static BOOL legal(const char *str, const char *extras)
{
	const char	*mark = "-_.!~*'()";
	if (str)
		{
		while (*str != 0)
			{
			if (*str == '%' && isxdigit(str[1]) && isxdigit(str[2]))
				str += 3;
			else if (isalnum(*str))
				str++;
			else if (strchr(mark, *str) != 0)
				str++;
			else if (extras && strchr(extras, *str) != 0)
				str++;
			else
				{
#if 1
				NSLog(@"illegal char: %c (%02x) -_.!~*'()%s", *str, *str, extras?extras:"");
#endif
				return NO;				
				}
			}
		}
	return YES;
}

static NSString *nounescape(const char *from)
{ // don't unescape
	if(!from)
		return nil;	// nothing to convert
	return [NSString stringWithUTF8String:from];
}

/*
 * Convert percent escape sequences to individual characters.
 * FIXME: what about UTF-8 character???
 */

static NSString *unescape(const char *from)
{
	NSString *result;
	int len;
	char *to, *bfr;
	if(!from)
		return nil;	// nothing to unescape...
	len=strlen(from)+1;
	to = bfr = objc_malloc(len);	// result will not become longer by unescaping
	while (*from)
		{
		if (*from == '%')
			{ // process 2 hex digits
				unsigned char c=0;
				int d;
				from++;
				for(d=0; d<2; d++)
					{ // collect 2 digits
						c <<= 4;
						if (isxdigit(*from))
							{
							if (*from <= '9')
								c |= *from - '0';
							else if (*from <= 'F')
								c |= *from - 'A' + 10;
							else
								c |= *from - 'a' + 10;
							from++;
							}
						else
							{
							NSLog(@"Bad percent escape sequence in URL string");
							// raise exception or simply ignore???
							//			[NSException raise: NSGenericException
							//					format: @"Bad percent escape sequence in URL string"];
							objc_free(bfr);
							return nil;
							}					
					}
#if 0
				NSLog(@"c=%02x", c);
#endif
				*to++ = c;	// store
			}
		else
			{ // unchanged
				*to++ = *from++;
			}
		}
	*to = '\0';
	result=[NSString stringWithUTF8String: bfr];
	NSCAssert(to-bfr < len, @"buffer overflow");
#if 1
	NSLog(@"unescaped = %@ [%u]", result, [result length]);
#endif
	objc_free(bfr);
	return result;
}



/**
 * This class permits manipulation of URLs and the resources to which they
 * refer.  They can be used to represent absolute URLs or relative URLs
 * which are based upon an absolute URL.  The relevant RFCs describing
 * how a URL is formatted, and what is legal in a URL are -
 * 1808, 1738, and 2396.<br />
 * Handling of the underlying resources is carried out by NSURLHandle
 * objects, but NSURL provides a simoplified API wrapping these objects.
 */
@implementation NSURL

- (NSString *) _URLescape:(NSString *) aPath
{ // internal method to %escape a string if needed
	const char *path=[aPath UTF8String];
	if(*path)
		{ // not empty - create %escaped version
			char *buf=NULL;
			unsigned int i=0;
			unsigned int capacity=0;
			while(*path)
				{ // %escape characters not allowed in URL path (e.g. unicode)
					if(capacity-i < 3)
						buf=objc_realloc(buf, (capacity+=strlen(path)+4));	// increase capacity for at least one more %xx plus \0
					if(isalnum(*path) || strchr(":@/$-_.+!*'(),", *path))
						buf[i++]=*path;	// allowed character
					else
						sprintf(&buf[i], "%%%02X", *path), i+=3;	// %escape (upper case HEX)
					path++;
				}
			buf[i]=0;	// 0-terminate
			aPath=[[[NSString alloc] initWithCStringNoCopy:buf length:i freeWhenDone: YES] autorelease];
		}
	return aPath;
}

/**
 * Create and return a file URL with the supplied path.<br />
 * The value of aPath must be a valid filesystem path.<br />
 * Calls -initFileURLWithPath:
 */
+ (id) fileURLWithPath: (NSString*)aPath
{
	return AUTORELEASE([[NSURL alloc] initFileURLWithPath: aPath]);
}

+ (id) fileURLWithPath: (NSString*)aPath isDirectory:(BOOL) flag
{
	return AUTORELEASE([[NSURL alloc] initFileURLWithPath: aPath isDirectory:flag]);
}

+ (void) initialize
{
	if (clientsLock == nil)
		{
		clientsLock = [NSLock new];
		}
}

/**
 * Create and return a URL with the supplied string, which should
 * be a string (containing percent escape codes where necessary)
 * conforming to the description (in RFC2396) of an absolute URL.<br />
 * Calls -initWithString:
 */
+ (id) URLWithString: (NSString*)aUrlString
{
	return AUTORELEASE([[NSURL alloc] initWithString: aUrlString]);
}

/**
 * Create and return a URL with the supplied string, which should
 * be a string (containing percent escape codes where necessary)
 * conforming to the description (in RFC2396) of a relative URL.<br />
 * Calls -initWithString:relativeToURL:
 */
+ (id) URLWithString: (NSString*)aUrlString
       relativeToURL: (NSURL*)aBaseUrl
{
	return AUTORELEASE([[NSURL alloc] initWithString: aUrlString
									   relativeToURL: aBaseUrl]);
}

/**
 * Initialise by building a URL string from the supplied parameters
 * and calling -initWithString:relativeToURL:
 */
- (id) initWithScheme: (NSString*)aScheme
				 host: (NSString*)aHost
				 path: (NSString*)aPath
{
	NSString	*aUrlString = [NSString alloc];
#if 1
	NSLog(@"initWithScheme:%@ host:%@ path:%@", aScheme, aHost, aPath);
#endif
	if ([aHost length] > 0)
		{
		if ([aPath length] > 0)
			{
			/*
			 * For MacOS-X compatibility, assume a path component with
			 * a leading slash is intended to have that slash separating
			 * the host from the path as specified in the RFC1738
			 */
			if ([aPath hasPrefix: @"/"])
				{ // absolute path
					aUrlString = [aUrlString initWithFormat: @"%@://%@%@", aScheme, aHost, aPath];
				}
			else
				{ // relative path
					aUrlString = [aUrlString initWithFormat: @"%@://%@/%@", aScheme, aHost, aPath];
				}
			}
		else
			{ // no path
				aUrlString = [aUrlString initWithFormat: @"%@://%@/", aScheme, aHost];
			}
		}
	else
		{ // no host
			if ([aPath length] > 0)
				aUrlString = [aUrlString initWithFormat: @"%@:%@", aScheme, aPath];
			else
				{ // no host and no path
					aUrlString = [aUrlString initWithFormat: @"%@:", aScheme];
				}
		}
	self = [self initWithString: aUrlString relativeToURL: nil];
#if 0
	NSLog(@"aUrlString=%@", aUrlString);
#endif
	RELEASE(aUrlString);
	return self;
}

/**
 * Initialise as a file URL with the specified path (which must
 * be a valid path on the local filesystem).<br />
 * Converts relative paths to absolute ones.<br />
 * Appends a trailing slash to the path when necessary if it
 * specifies a directory. Or the file does not exist.<br />
 * Calls -initWithScheme:host:path:
 */

- (id) initFileURLWithPath: (NSString*)aPath
{
	BOOL isDir=NO;
	[[NSFileManager defaultManager] fileExistsAtPath: aPath isDirectory: &isDir];
	return [self initFileURLWithPath:aPath isDirectory:isDir];
}

- (id) initFileURLWithPath: (NSString*)aPath isDirectory:(BOOL) isDir
{
#if 1
	NSLog(@"initFileURLWithPath %@", aPath);
#endif
	NSAssert([aPath isAbsolutePath], @"fileURL must be absolute path");
	if(isDir && ![aPath hasSuffix: @"/"])
		aPath = [aPath stringByAppendingString: @"/"];	// add directory suffix if it is missing
#if 1
	NSLog(@"  -> %@", aPath);
#endif
	return [self initWithScheme: NSURLFileScheme
						   host: @"localhost"
						   path: [self _URLescape:aPath]];
}

/**
 * Initialise as an absolute URL.<br />
 * Calls -initWithString:relativeToURL:
 */
- (id) initWithString: (NSString*)aUrlString
{
	return [self initWithString:aUrlString relativeToURL:nil];
}

/** <init />
 * Initialised using aUrlString and aBaseUrl.  The value of aBaseUrl
 * may be nil, but aUrlString must be non-nil.<br />
 * If the string cannot be parsed the method returns nil.
 */

- (id) initWithString: (NSString*)aUrlString
		relativeToURL: (NSURL*)aBaseUrl
{
#if 1
	NSLog(@"initWithString: %@ relativeToURL: %@", aUrlString, [aBaseUrl description]);
#endif
	if (aUrlString == nil)
		{
		[NSException raise: NSInvalidArgumentException
					format: @"[%@ %@] nil string parameter",
		 NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
		return nil;
		}
	_urlString=[aUrlString copy];	// keep a copy
	ASSIGN(_baseURL, [aBaseUrl absoluteURL]);	// make base absolute before storing or we would get chains of relative URLs
	NS_DURING {
		parsedURL	*buf;
		unsigned	size = [_urlString cStringLength];
		char	*end;
		char	*start;
		char	*ptr;
		BOOL	usesFragments = YES;
		BOOL	usesParameters = YES;
		BOOL	usesQueries = YES;
		BOOL	usesPath = YES;
		BOOL	canBeGeneric = YES;
		
		size = (sizeof(parsedURL) + __alignof__(parsedURL)) + (size+1);
		
		buf = _data = (parsedURL *) objc_malloc(size);	// allocate space for parsedURL header plus the cString
		memset(buf, '\0', size);
		start = end = (char*)&buf[1];
		[_urlString getCString:start];			// get the cString and store behind the parsedURL header
#if 0
		NSLog(@"NSURL initWithString");
		NSLog(@"NSURL [length]=%d len=%d size=%d buf=%p", [_urlString length], [_urlString cStringLength], size, buf);
		NSLog(@"NSURL aUrlString: %@ %@", NSStringFromClass([aUrlString class]), aUrlString);
		NSLog(@"NSURL _urlString: %@ %@", NSStringFromClass([_urlString class]), _urlString);
		NSLog(@"NSURL getCString result: %d %s", strlen(start), start);
#endif		
		/*
		 * Parse the scheme if possible.
		 */
		ptr = start;
		if (isalpha(*ptr))
			{
			ptr++;
			while (isalnum(*ptr) || *ptr == '+' || *ptr == '-' || *ptr == '.')
				ptr++;
			if (*ptr == ':')
				{
				buf->scheme = start;		// Got a valid scheme.
				*ptr = '\0';			// Terminate it.
				end = &ptr[1];
				/*
				 * Standardise uppercase to lower.
				 */
				while (--ptr > start)
					{
					if (isupper(*ptr))
						*ptr = tolower(*ptr);
					}
				}
			}
		start = end;
		
		/*
		 * Set up scheme specific parsing options.
		 */
		if (buf->scheme != 0)
			{
			if (strcmp(buf->scheme, "file") == 0)
				{
				buf->isFile = YES;
				}
			else if (strcmp(buf->scheme, "mailto") == 0)
				{ // http://en.wikipedia.org/wiki/Mailto
					usesFragments = NO;
					usesParameters = NO;
					canBeGeneric = NO;
				}
			else if (strcmp(buf->scheme, "data") == 0)
				{ // http://en.wikipedia.org/wiki/Data_URI_scheme
					usesFragments = NO;
					usesQueries = NO;
					usesPath = NO;
					canBeGeneric = NO;
				}
			}
		
		if (canBeGeneric)
			{
			/*
			 * Parse the 'authority'
			 * //user:password@host:port
			 */
			if (start[0] == '/' && start[1] == '/')
				{
				start += 2;
				
				/*
				 * Set 'end' to point to the start of the path, or just past
				 * the 'authority' if there is no path.
				 */
				end = strchr(start, '/');
				if(end != start)
					{ // is not "scheme:///path"
						if (!end)
							{ // "scheme://something" will lead to non-absolute but empty path
								end = &start[strlen(start)];
							}
						else
							{ // "scheme://something/path"
							buf->pathIsAbsolute = YES;
							*end++ = '\0';
							}
						/*
						 * Parse username:password part
						 */
						ptr = strchr(start, '@');
						if (ptr != NULL)
							{
							buf->user = start;
							*ptr++ = '\0';
							if (!legal(buf->user, ";:&=+$,"))
								[NSException raise: NSGenericException format:@"illegal character in user part"];
							start = ptr;
							ptr = strchr(buf->user, ':');
							if (ptr != 0)
								{
								*ptr++ = '\0';
								buf->password = ptr;
								}
							}
						
						/*
						 * Parse host:port part
						 */
						buf->host = start;
						ptr = strchr(buf->host, ':');
						if (ptr != NULL)
							{ // strip off port part
							*ptr++ = '\0';
							buf->port = ptr;	// is not checked to be valid here or we can't reconstruct
							}
						if (!legal(buf->host, NULL))
							[NSException raise: NSGenericException format:@"illegal character in hostname part"];

						start = end;
					}
				else
					{ // "scheme://"+absolute path
#if 1
					NSLog(@"scheme:/// found: %s", start);
#endif
					buf->pathIsAbsolute = YES;
					start++;	// but don't store the /
					}
				}
			else if (*start == '/')
				{
				buf->pathIsAbsolute = YES;
				start++;	// but don't store the /
				}
			
			if (!legal(start, "/:@&=+$,;?#"))
				 [NSException raise: NSGenericException format:@"illegal character in resource"];
			if (usesFragments)
				{
				/*
				 * Strip fragment string from end of url.
				 */
				ptr = strchr(start, '#');
				if (ptr != 0)
					{
					*ptr++ = '\0';
					if (*ptr != 0)
						buf->fragment = ptr;
					}
				}
			
			if (usesQueries)
				{
				/*
				 * Strip query string from end of url.
				 */
				ptr = strchr(start, '?');
				if (ptr != 0)
					{
					*ptr++ = '\0';
					if (*ptr != 0)
						buf->query = ptr;
					}
				}
			
			if (usesParameters)
				{
				/*
				 * Strip parameters string from end of url.
				 */
				ptr = strchr(start, ';');
				if (ptr != 0)
					{
					*ptr++ = '\0';
					if (*ptr != 0)
						buf->parameters = ptr;
					}
				}		
			}
		/*
		 * Store the path.
		 */
		if(usesPath)
			buf->path = start;
	}
	NS_HANDLER {
		NSLog(@"%@", localException);
		[self release];
		self=nil;
	}
	NS_ENDHANDLER
#if 0
	NSLog(@"url=%@", self);
#endif
	return self;
}

- (void) dealloc
{
	if (_clients != 0)
		{
		NSFreeMapTable(_clients);
		_clients = 0;
		}
	if (_data != 0)
		{
		[myData->absolute release];
		objc_free(_data);
		_data = 0;
		}
	[_urlString release];
	[_baseURL release];
	[super dealloc];
}

- (id) copyWithZone: (NSZone*) zone
{
	return [self retain];	// URL is not mutable
}

- (NSString *) description
{
	if (_baseURL)
		return [_urlString stringByAppendingFormat: @" -- %@", _baseURL];
	return _urlString;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
	[aCoder encodeObject: _urlString];
	[aCoder encodeObject: _baseURL];
}

- (unsigned int) hash
{
	return [[self absoluteString] hash];
}

- (id) initWithCoder: (NSCoder*)aCoder
{
	NSURL		*base;
	NSString	*rel;
	
	[aCoder decodeValueOfObjCType: @encode(id) at: &rel];
	[aCoder decodeValueOfObjCType: @encode(id) at: &base];
	self = [self initWithString: rel relativeToURL: base];
	RELEASE(rel);	// client is responsible for releasing
	RELEASE(base);
	return self;
}

- (BOOL) isEqual: (id)other
{
	if (other == nil || ![other isKindOfClass: [NSURL class]])
		return NO;
	return [[self absoluteString] isEqualToString: [other absoluteString]];
}

/**
 * Returns the full string describing the receiver resolved against its base.
 * does not expand % escapes
 * does not standardize the path
 */
- (NSString*) absoluteString
{
#if 0
	NSLog(@"absoluteString: %@", self);
#endif
	if(!_baseURL)
		return _urlString;	// we are already absolute - nothing to resolve
	if (!myData->absolute)
		{ // cache absolute URL string
			char	*url = buildURL(baseData, myData, NO, NO);
			unsigned	len;
			if(!url)
				{ // wasn't able to build the URL from path
					if(!myData->path)
						return _urlString;
					return nil;			
				}
			len = strlen(url);
			myData->absolute = [[NSString alloc] initWithCStringNoCopy: url length: len freeWhenDone: YES];
		}
	return myData->absolute;
}

/**
 * If the receiver is an absolute URL, returns self.  Otherwise returns an
 * absolute URL referring to the same resource as the receiver.
 */
- (NSURL*) absoluteURL
{
	if (_baseURL)
		return [NSURL URLWithString: [self absoluteString]];
	return self;
}

/**
 * If the receiver is a relative URL, returns its base URL.<br />
 * Otherwise, returns nil.
 */
- (NSURL*) baseURL
{
	return _baseURL;
}

/**
 * Returns the fragment portion of the receiver or nil if there is no
 * fragment supplied in the URL.<br />
 * The fragment is everything in the original URL string after a '#'<br />
 * File URLs do not have fragments.
 */
- (NSString*) fragment
{
	return nounescape(myData->fragment);
}

/**
 * Returns the host portion of the receiver or nil if there is no
 * host supplied in the URL.<br />
 * Percent escape sequences in the user string are translated and the string
 * treated as UTF8.<br />
 */
- (NSString*) host
{
	if(!myData->host) return [_baseURL host];	// inherit
	return unescape(myData->host);
}

/**
 * Returns YES if the recevier is a file URL, NO otherwise.
 */
- (BOOL) isFileURL
{
	return myData->isFile;
}

/**
 * Loads resource data for the specified client.
 * <p>
 *   If shouldUseCache is YES then an attempt
 *   will be made to locate a cached NSURLHandle to provide the
 *   resource data, otherwise a new handle will be created and
 *   cached.
 * </p>
 * <p>
 *   If the handle does not have the data available, it will be
 *   asked to load the data in the background by calling its
 *   loadInBackground  method.
 * </p>
 * <p>
 *   The specified client (if non-nil) will be set up to receive
 *   notifications of the progress of the background load process.
 * </p>
 */
- (void) loadResourceDataNotifyingClient: (id)client usingCache: (BOOL)shouldUseCache
{
	NSURLHandle	*handle = [self URLHandleUsingCache: shouldUseCache];
	NSRunLoop	*loop;
	NSDate	*future;
	
	if (client != nil)
		{
#if 0
		NSLog(@"NSURL: clientsLock lock");
#endif
		[clientsLock lock];
		if (_clients == 0)
			{
			_clients = NSCreateMapTable (NSNonRetainedObjectMapKeyCallBacks,
										 NSNonRetainedObjectMapValueCallBacks, 0);
			}
		NSMapInsert((NSMapTable*)_clients, (void*)handle, (void*)client);
		[clientsLock unlock];
		[handle addClient: self];
		}
	
	/*
	 * Kick off the load process.
	 */
	[handle loadInBackground];
	
	/*
	 * Keep the runloop going until the load has completed (or failed).
	 */
	loop = [NSRunLoop currentRunLoop];
	future = [NSDate distantFuture];
	while ([handle status] == NSURLHandleLoadInProgress)
		{
		[loop runMode: NSDefaultRunLoopMode beforeDate: future];
		}
	
	if (client != nil)
		{
		[handle removeClient: self];
#if 0
		NSLog(@"NSURL: clientsLock lock");
#endif
		[clientsLock lock];
		NSMapRemove((NSMapTable*)_clients, (void*)handle);
		[clientsLock unlock];
		}
}

/**
 * Returns the parameter portion of the receiver or nil if there is no
 * parameter supplied in the URL.<br />
 * The parameters are everything in the original URL string after a ';'
 * but before the query.<br />
 * File URLs do not have parameters.
 */
- (NSString*) parameterString
{
	return nounescape(myData->parameters);
}

/**
 * Returns the password portion of the receiver or nil if there is no
 * password supplied in the URL.<br />
 * NB. because of its security implications it is recommended that you
 * do not use URLs with users and passwords unless necessary.
 */
- (NSString*) password
{
	if(!myData->password) return [_baseURL password];	// inherit
	return nounescape(myData->password);
}

/**
 * Returns the path portion of the receiver.<br />
 * Replaces percent escapes with unescaped values, interpreting non-ascii
 * character sequences as UTF8.<br />
 */
- (NSString*) path
{
	char *url = buildURL(baseData, myData, YES, YES);
	NSString *path=unescape(url);
	if(url)
		objc_free(url);
	return path;
}

/**
 * Returns the port portion of the receiver or nil if there is no
 * port supplied in the URL.<br />
 * Percent escape sequences in the user string are translated in GNUstep
 * but this appears to be broken in MacOS-X.
 */

- (NSNumber*) port
{
	char *ptr;
	if(!myData->port) return [_baseURL port];	// inherit
	ptr=myData->port;
	while(*ptr)
		if(!isdigit(*ptr++))
			return nil;	// invalid port
	return [NSNumber numberWithUnsignedShort:atoi(myData->port)];
}

/**
 * Asks a URL handle to return the property for the specified key and
 * returns the result.
 */
- (id) propertyForKey: (NSString*)propertyKey
{
	NSURLHandle	*handle = [self URLHandleUsingCache: YES];
	return [handle propertyForKey: propertyKey];
}

/**
 * Returns the query portion of the receiver or nil if there is no
 * query supplied in the URL.<br />
 * The query is everything in the original URL string after a '?'
 * but before the fragment.<br />
 * File URLs do not have queries.
 */
- (NSString*) query
{
	return nounescape(myData->query);
}

/**
 * Returns the path of the receiver, without taking any base URL into account.
 * If the receiver is an absolute URL, -relativePath is the same as -path.<br />
 * Returns nil if there is no path specified for the URL.
 */
- (NSString*) relativePath
{
	NSString *str=unescape(myData->path);
	if(myData->pathIsAbsolute)
		return [@"/" stringByAppendingString:str];	// prefix by / (which is not stored)
	return str;
}

/**
 * Returns the relative portion of the URL string.  If the receiver is not
 * a relative URL, this returns the same as absoluteString.
 */
- (NSString *) relativeString
{
	return _urlString;
}

/**
 * Loads the resource data for the represented URL and returns the result.
 * The shoulduseCache flag determines whether an existing cached NSURLHandle
 * can be used to provide the data.
 */
- (NSData*) resourceDataUsingCache: (BOOL)shouldUseCache
{
	NSURLHandle	*handle = [self URLHandleUsingCache: shouldUseCache];
	NSData	*data;
	
	if (!shouldUseCache || [handle status] != NSURLHandleLoadSucceeded)
		{
		[self loadResourceDataNotifyingClient: self usingCache: shouldUseCache];
		}
	data = [handle resourceData];
	return data;
}

/**
 * Returns the resource specifier of the URL ... the part which lies
 * after the scheme.
 */
- (NSString*) resourceSpecifier
{
	NSRange	range;
	range = [_urlString rangeOfString: @":///"];	
	if (range.length > 0)
		return [_urlString substringFromIndex: NSMaxRange(range)-1];	// everything after the third /

	range = [_urlString rangeOfString: @"://"];	
	if (range.length > 0)
		return [_urlString substringFromIndex: range.location+1];	// include the //
	range = [_urlString rangeOfString: @":"];
	if (range.length > 0)
		return [_urlString substringFromIndex: NSMaxRange(range)];	// everything behind the :
	else
		return _urlString;	// has no scheme
}

/**
 * Returns the scheme of the receiver.
 */
- (NSString*) scheme
{
	if(!myData->scheme) return [_baseURL scheme];	// inherit
	return nounescape(myData->scheme);
}

/**
 * Calls -[NSURLHandle writeProperty:forKey:] to set the named property.
 */
- (BOOL) setProperty: (id)property
			  forKey: (NSString*)propertyKey
{
	NSURLHandle	*handle = [self URLHandleUsingCache: YES];
	return [handle writeProperty: property forKey: propertyKey];
}

/**
 * Calls -[NSURLHandle writeData:] to write the specified data object
 * to the resource identified by the receiver URL.<br />
 * Returns the result.
 */
- (BOOL) setResourceData: (NSData*)data
{
	NSURLHandle	*handle = [self URLHandleUsingCache: YES];
	
	if (handle == nil)
		return NO;
	if (![handle writeData: data])
		return NO;
	[self loadResourceDataNotifyingClient: self
							   usingCache: YES];
	if ([handle resourceData] == nil)
		return NO;
	return YES;
}

/**
 * Returns a URL with '/./' and '/../' sequences resolved etc.
 * copies base path, just "our" path
 */

- (NSURL*) standardizedURL
{
	char		*url = buildURL(NULL, myData, YES, NO);
	unsigned	len = strlen(url);
	NSString	*str;
	NSURL		*tmp=self;
	
	if(url)
		{
		str = [[NSString alloc] initWithCStringNoCopy: url
											   length: len
										 freeWhenDone: YES];
		tmp = [NSURL URLWithString: str relativeToURL:_baseURL];
		RELEASE(str);
		}
	return tmp;
}

/**
 * Returns an NSURLHandle instance which may be used to write data to the
 * resource represented by the receiver URL, or read data from it.<br />
 * The shouldUseCache flag indicates whether a cached handle may be returned
 * or a new one should be created.
 */
- (NSURLHandle*) URLHandleUsingCache: (BOOL)shouldUseCache
{
	NSURLHandle	*handle = nil;
	
	if (shouldUseCache)
		{
		handle = [NSURLHandle cachedHandleForURL: self];
		}
	if (handle == nil)
		{
		Class	c = [NSURLHandle URLHandleClassForURL: self];
		
		if (c != 0)
			{
			handle = [[c alloc] initWithURL: self cached: shouldUseCache];
			AUTORELEASE(handle);
			}
		}
	return handle;
}

/**
 * Returns the user portion of the receiver or nil if there is no
 * user supplied in the URL.<br />
 * Percent escape sequences in the user string are translated and
 * the whole is treated as UTF8 data.<br />
 * NB. because of its security implications it is recommended that you
 * do not use URLs with users and passwords unless necessary.
 */
- (NSString *) user
{
	if(!myData->user) return [_baseURL user];	// inherit
	return unescape(myData->user);
}

- (void) URLHandle: (NSURLHandle*)sender
resourceDataDidBecomeAvailable: (NSData*)newData
{
	[clientForHandle(_clients, sender) URL: self
			resourceDataDidBecomeAvailable: newData];
}
- (void) URLHandle: (NSURLHandle*)sender
resourceDidFailLoadingWithReason: (NSString*)reason
{
	[clientForHandle(_clients, sender) URL: self
		  resourceDidFailLoadingWithReason: reason];
}

- (void) URLHandleResourceDidBeginLoading: (NSURLHandle*)sender
{
}

- (void) URLHandleResourceDidCancelLoading: (NSURLHandle*)sender
{
	[clientForHandle(_clients, sender) URLResourceDidCancelLoading: self];
}

- (void) URLHandleResourceDidFinishLoading: (NSURLHandle*)sender
{
	[clientForHandle(_clients, sender) URLResourceDidFinishLoading: self];
}


@end



/**
 * An informal protocol to which clients may conform if they wish to be
 * notified of the progress in loading a URL for them.  The default
 * implementations of these methods do nothing.
 */
@implementation NSObject (NSURLClient)

- (void) URL: (NSURL*)sender
resourceDataDidBecomeAvailable: (NSData*)newBytes
{
	return;
}

- (void) URL: (NSURL*)sender
resourceDidFailLoadingWithReason: (NSString*)reason
{
	return;
}

- (void) URLResourceDidCancelLoading: (NSURL*)sender
{
	return;
}

- (void) URLResourceDidFinishLoading: (NSURL*)sender
{
	return;
}

@end
