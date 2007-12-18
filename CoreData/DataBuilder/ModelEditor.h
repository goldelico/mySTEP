/*
    ModelEditor.h

    Interface declaration of the ModelEditor class for the DataBuilder
    application.

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

#import <Foundation/NSObject.h>

#import <CoreData/NSManagedObjectModel.h>

@class NSView, NSWindow;
@class Document;

/**
 * Abstract superclass for all data-model editors.
 *
 * Editing various aspects of the data model (such as entities, attributes,
 * and configurations) is done through 'editor' objects. They all inherit
 * from this common abstract superclass. It provides them with a link to the
 * document, data model and automagically handles their view setup when
 * unarchived from the nib.
 */
@interface ModelEditor : NSObject
{
  NSManagedObjectModel * model;

  // weak reference
  Document * document;

@private
  /**
   * Every editor should contain in it's nib a view keyed to the NSOwner's
   * 'view' outlet - this will be the view of the editor put into the
   * main document window.
   */
  NSView * view;
  /**
   * This outlet should be keyed to the window in which the view has been
   * modelled. The ModelEditor class automatically takes the main view
   * of the editor out of the window and disposes of the window at nib
   * unarchiving time.
   */
  NSWindow * bogusWindow;
}

/**
 * Designated initializer. Subclasses should override this method in order
 * to implement their initialization (such as load their Nib file).
 */
- initWithModel: (NSManagedObjectModel *) aModel
       document: (Document *) document;

/**
 * Takes the view out of the bogusWindow. If a subclasses overrides this
 * method, it should invoke the superclass' implementation too.
 */
- (void) awakeFromNib;

/// Returns the editor's view.
- (NSView *) view;

@end
