//
//  CFString.h
//  CoreFoundation
//
//  Created by H. Nikolaus Schaller on 03.10.08.
//  Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#ifndef _mySTEP_H_CFString
#define _mySTEP_H_CFString

@class NSString;
typedef NSString *CFStringRef;

inline CFStringRef CFSTR(char *str) { return [[NSString alloc] initWithCString:str]; }

#endif
