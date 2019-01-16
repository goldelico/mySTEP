/*
    ModelEditor.m

    Implementation of the ModelEditor class for the DataBuilder application.

    Copyright (C) 2005  Saso Kiselkov

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#import "Private.h"

#import "ModelEditor.h"

#import <Foundation/NSException.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSDebug.h>

#import <AppKit/NSView.h>

@implementation ModelEditor

- (void) dealloc
{
  NSDebugLog(@"%@: dealloc", [self className]);

  TEST_RELEASE(model);
  TEST_RELEASE(view);

  [super dealloc];
}

- initWithModel: (NSManagedObjectModel *) aModel
       document: (Document *) aDocument
{
  if ((self=[super init]))
    {
      ASSIGN(model, aModel);

      document = aDocument;

    }
  return self;
}

- (void) awakeFromNib
{
  [view retain];
  [view removeFromSuperview];
  DESTROY(bogusWindow);
}

- (NSView *) view
{
  return view;
}

@end
