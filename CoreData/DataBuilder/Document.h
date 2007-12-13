/*
    Document.h

    Interface declaration of the Document class for the DataBuilder
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

#import <AppKit/AppKit.h>
#import <CoreData/CoreData.h>

@class DocumentWindowController;
@class AttributeEditor,
       FetchedPropertyEditor,
       RelationshipEditor,
       ConfigurationEditor,
       EntityEditor;

// notifications sent when a part of the model changes - the view
// controllers then re-update the display
extern NSString
   // the list of configurations has changed
   // object = the model in which the list of configurations changed
  * const ConfigurationsDidChangeNotification,

   // the name of a configuration has changed
   // object = the model in which the list of configurations changed
   // userInfo = {
   //   OldName = old-configuration-name;
   //   NewName = new-configuration-name;
   // };
  * const ConfigurationNameDidChangeNotification,

   // the list of entities for a particular configuration has changed.
   // object = the model in which the list of configurations changed
   // userInfo = {
   //   Configuration = configuration;
   // };
   // absence of the `Configuration' key means 'Default configuration'.
  * const EntitiesDidChangeNotification,

   // the list of properties for a particular entity has changed.
   // object = the model in which the list of configurations changed
   // userInfo = {
   //   Configuration = configuration;
   //   Entity = entity;
   // }
   // absence of the `Configuration' key means 'Default configuration'.
  * const PropertiesDidChangeNotification;

extern NSString
  * const PropertyDidChangeNotification,
  * const EntityDidChangeNotification;

/**
 * This is the main document object.
 *
 * This object owns the data model and exposes methods for various
 * controller-layer objects (such as the DocumentWindowController and the
 * various editors) to allow easy manipulation of the data model with
 * support for undo/redo/revert to saved.
 */
@interface Document : NSDocument
{
  DocumentWindowController * mainWindowController;

  NSManagedObjectModel * model;

  AttributeEditor * attributeEditor;
  ConfigurationEditor * configurationEditor;
  EntityEditor * entityEditor;
  FetchedPropertyEditor * fetchedPropertyEditor;
  RelationshipEditor * relationshipEditor;
}

- init;

- (BOOL) readFromFile: (NSString *) fileName ofType: (NSString *) type;
- (BOOL) readFromURL: (NSURL *) url ofType: (NSString *) type;

- (BOOL) writeToFile: (NSString *) fileName ofType: (NSString *) type;
- (BOOL) writeToURL: (NSURL *) url ofType: (NSString *) type;

- (void) makeWindowControllers;

/**
 * Returns the managed object model being edited in the document.
 */
- (NSManagedObjectModel *) model;

// return the various model editors, creating them if necessary
- (ConfigurationEditor *) configurationEditor;
- (EntityEditor *) entityEditor;
- (AttributeEditor *) attributeEditor;
- (FetchedPropertyEditor *) fetchedPropertyEditor;
- (RelationshipEditor *) relationshipEditor;

/**
 * Adds a new empty configuration to the model with a generated
 * unique name.
 */
- (void) addNewConfiguration;

/**
 * Sets the entities in the model.
 *
 * The `configuration' argument specifies which configuration to influence.
 * Passing `nil' means the Default configuration. The `entities' argument
 * are the entities which to set. Passing `nil' means remove the given
 * configuration.
 */
- (void) setEntities: (NSArray *) entities
    forConfiguration: (NSString *) configuration;

/**
 * Creates a new entity with a unique name and adds it to `configuration'
 * (nil denotes 'Default' configuration).
 */
- (void) addNewEntityToConfiguration: (NSString *) configuration;

/**
 * Adds `entity' to `configuration' and sets up apropriate undo actions.
 */
- (void) addEntity: (NSEntityDescription *) entity
   toConfiguration: (NSString *) configuration;

/**
 * Removes `entity' from `configuration' and sets up apropriate undo actions.
 */
- (void) removeEntity: (NSEntityDescription *) entity
    fromConfiguration: (NSString *) configuration;

/**
 * Adds a new attribute with a unique name to `entity' which is
 * contained in `configuration'.
 */
- (void) addNewAttributeToEntity: (NSEntityDescription *) entity
                 inConfiguration: (NSString *) configuration;

/**
 * Simmilar to -addNewAttributeToEntity:inConfiguration:, but does
 * so for fetched properties.
 */
- (void) addNewFetchedPropertyToEntity: (NSEntityDescription *) entity
                       inConfiguration: (NSString *) configuration;

/**
 * Simmilar to -addNewAttributeToEntity:inConfiguration:, but does
 * so for relationships.
 */
- (void) addNewRelationshipToEntity: (NSEntityDescription *) entity
                    inConfiguration: (NSString *) configuration;

/**
 * Simmilar to -addNewAttributeToEntity:inConfiguration:, but does
 * so for fetched properties.
 */
- (void) addNewFetchedPropertyToEntity: (NSEntityDescription *) entity
                       inConfiguration: (NSString *) configuration;

- (void) addProperty: (NSPropertyDescription *) property
            toEntity: (NSEntityDescription *) entity
     inConfiguration: (NSString *) configuration;
- (void) removeProperty: (NSPropertyDescription *) property
             fromEntity: (NSEntityDescription *) entity
        inConfiguration: (NSString *) configuration;

- (void)  setName: (NSString *) newName
  ofConfiguration: (NSString *) oldName;

- (void) setName: (NSString *) newName
      ofProperty: (NSPropertyDescription *) property
        inEntity: (NSEntityDescription *) entity
   configuration: (NSString *) configuration;
- (void) setOptional: (BOOL) flag
          ofProperty: (NSPropertyDescription *) property;
- (void) setTransient: (BOOL) flag
           ofProperty: (NSPropertyDescription *) property;

- (void)  setName: (NSString *) newName
         ofEntity: (NSEntityDescription *) entity
  inConfiguration: (NSString *) configuration;

- (void) setAbstract: (BOOL) flag ofEntity: (NSEntityDescription *) entity;
- (void) setManagedObjectClassName: (NSString *) aName
                          ofEntity: (NSEntityDescription *) entity;
- (void) setSuperentity: (NSEntityDescription *) superentity
               ofEntity: (NSEntityDescription *) entity;

- (void) setAttributeValueClassName: (NSString *) className
                        ofAttribute: (NSAttributeDescription *) attribute;
- (void) setAttributeType: (NSAttributeType) type
              ofAttribute: (NSAttributeDescription *) attribute;

- (void) setDestinationEntity: (NSEntityDescription *) entity
               ofRelationship: (NSRelationshipDescription *) relationship;
- (void) setInverseRelationship: (NSRelationshipDescription *) invRelationship
                 ofRelationship: (NSRelationshipDescription *) relationship;

- (void) setMaxCount: (int) newCount
      ofRelationship: (NSRelationshipDescription *) relationship;
- (void) setMinCount: (int) newCount
      ofRelationship: (NSRelationshipDescription *) relationship;

- (void) setDeleteRule: (NSDeleteRule) rule
        ofRelationship: (NSRelationshipDescription *) relationship;

@end
