/* 
   NSWindowController.h

   The document controller class

   Author:    Fabian Spillner <fabian.spillner@gmail.com>
   Date:      20. December 2007 - aligned with 10.5 
 
   Copyright (C) 1999 Free Software Foundation, Inc.

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

#ifndef _GNUstep_H_NSWindowController
#define _GNUstep_H_NSWindowController

#import <Foundation/NSObject.h>
#import <AppKit/NSNibDeclarations.h>

@class NSString;
@class NSArray;
@class NSWindow;
@class NSDocument;

@interface NSWindowController : NSObject <NSCoding>
{
  @private
    NSWindow            *_window;
    NSString            *_windowNibName;
    NSString            *_windowNibPath;
    NSString            *_windowFrameAutosaveName;
    NSDocument          *_document;
    NSArray             *_topLevelObjects;
    id                  _owner;
    struct ___wcFlags 
    {
      unsigned int shouldCloseDocument:1;
      unsigned int shouldCascade:1;
      unsigned int nibIsLoaded:1;
      unsigned int RESERVED:29;
    } _wcFlags;
    void                *_reserved1;
    void                *_reserved2;
}

- (void) close;
- (id) document;
- (id) initWithWindow:(NSWindow *) window;
- (id) initWithWindowNibName:(NSString *) windowNibName;  // self is the owner
- (id) initWithWindowNibName:(NSString *) windowNibName  owner:(id) owner;
- (id) initWithWindowNibPath:(NSString *) windowNibPath
					   owner:(id) owner;
- (BOOL) isWindowLoaded;
- (void) loadWindow;
- (id) owner;
- (void) setDocument:(NSDocument *) document;
- (void) setDocumentEdited:(BOOL) flag;
- (void) setShouldCascadeWindows:(BOOL) flag;
- (void) setShouldCloseDocument:(BOOL) flag;
- (void) setWindow:(NSWindow *) aWindow;
- (void) setWindowFrameAutosaveName:(NSString *) name;
- (BOOL) shouldCascadeWindows;
- (BOOL) shouldCloseDocument;
- (IBAction) showWindow:(id) sender;
- (void) synchronizeWindowTitleWithDocumentName;
- (NSWindow *) window;
- (void) windowDidLoad;
- (NSString *) windowFrameAutosaveName;
- (NSString *) windowNibName;
- (NSString *) windowNibPath;
- (NSString *) windowTitleForDocumentDisplayName:(NSString *) displayName;
- (void) windowWillLoad;

@end

#endif /* _GNUstep_H_NSWindowController */
