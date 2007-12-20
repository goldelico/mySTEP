/* 
   NSSpellProtocol.h

   Protocols for spell checking

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: 1997
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	12. December 2007 - aligned with 10.5 
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSSpellProtocol
#define _mySTEP_H_NSSpellProtocol

@protocol NSChangeSpelling

- (void) changeSpelling:(id) sender;

@end


@protocol NSIgnoreMisspelledWords

- (void) ignoreSpelling:(id) sender;

@end

#endif /* _mySTEP_H_NSSpellProtocol */
