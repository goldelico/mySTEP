/* 
   NSSecureTextField.h

   Secure Text field control class for data entry

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: Dec 1999
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	05. December 2007 - aligned with 10.5   
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSSecureTextField
#define _mySTEP_H_NSSecureTextField

#import <AppKit/NSTextField.h>
#import <AppKit/NSTextFieldCell.h>


@interface NSSecureTextField : NSTextField
@end


@interface NSSecureTextFieldCell : NSTextFieldCell {
	
}

- (BOOL) echosBullets; 
- (void) setEchosBullets:(BOOL) flag; 

@end

#endif /* _mySTEP_H_NSSecureTextField */
