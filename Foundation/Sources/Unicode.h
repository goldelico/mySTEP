/* 
   Unicode.h

   Support functions for Unicode implementation

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:	Stevo Crvenkovski <stevo@btinternet.com>
   Date:	March 1997

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_Unicode
#define _mySTEP_H_Unicode

#define NSSwappedUnicodeStringEncoding (-NSUnicodeStringEncoding)

typedef int (*uniencoder)(UTF32Char, unsigned char **);	// an encoder function pointer - converts UTF32Char and stores through char **. Returns 1 if ok, 0 if not
typedef UTF32Char (*unidecoder)(unsigned char **);		// a decoder function pointer - fetches from char **

const NSStringEncoding *_availableEncodings(void);

uniencoder encodeuni(NSStringEncoding enc);				// get appropriate encoder function
unidecoder decodeuni(NSStringEncoding enc);				// get appropriate decoder function

int uslen (unichar *u);
unichar uni_tolower(unichar ch);
unichar uni_toupper(unichar ch);
unsigned char uni_cop(unichar u);
BOOL uni_isnonsp(unichar u);
unichar *uni_is_decomp(unichar u);

#endif /* _mySTEP_H_Unicode */
