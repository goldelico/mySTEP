/* 
   NSFileWrapper.h

   NSFileWrapper objects hold a file's contents in dynamic memory.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: Sept 1998
 
   Author:	Fabian Spillner
   Date:	23. October 2007
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	8. November 2007 - aligned with 10.5 

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#ifndef _GNUstep_H_NSFileWrapper_Additions
#define _GNUstep_H_NSFileWrapper_Additions

#import <Foundation/NSFileWrapper.h>
#import <AppKit/NSImage.h>

@interface NSFileWrapper (NSFileWrapperAdditions)
- (NSImage *) icon;
- (void) setIcon:(NSImage *) icon;
@end

#endif // _GNUstep_H_NSFileWrapper_Additions
