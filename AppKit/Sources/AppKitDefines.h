//
//  AppKitDefines.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
//  Copyright (c) 2006 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSAppKitDefines
#define _mySTEP_H_NSAppKitDefines

#ifndef TYPEDBITFIELD
#if USE_BITFIELDS
#define TYPEDBITFIELD(type, name, size)	type name:size
#define UIBITFIELD(type, name, size)	unsigned int name:size
#define IBITFIELD(type, name, size)		int name:size
#else
#define TYPEDBITFIELD(type, name, size)	unsigned int name:size	// gcc 2.95.3 does not understand "type name:size"
#define UIBITFIELD(type, name, size)	unsigned int name:size
#define IBITFIELD(type, name, size)		int name:size
#endif
#endif

#endif /* _mySTEP_H_NSAppKitDefines */
