//
//  IKImageBrowser.h
//  ImageKit
//
//  Created by H. Nikolaus Schaller on 16.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IKImageBrowserView : NSView
{

}

@end

@interface NSObject (IKImageBrowserDataSource)

- (NSDictionary *) imageBrowser:(IKImageBrowserView *) browser groupAtIndex:(NSUInteger) index;
- (id) imageBrowser:(IKImageBrowserView *) browser itemAtIndex:(NSUInteger) index;
- (BOOL) imageBrowser:(IKImageBrowserView *) browser movesItemsAtIndexes:(NSIndexSet *) from toIndex:(NSUInteger) to;
- (void) imageBrowser:(IKImageBrowserView *) browser removeItemsAtIndexes:(NSIndexSet *) from;
- (NSUInteger) imageBrowser:(IKImageBrowserView *) browser writeItemsAtIndexes:(NSIndexSet *) from toPasteBoard:(NSPasteboard *) pb;
- (NSUInteger) numberOfGroupsInImageBrowser:(IKImageBrowserView *) browser;
- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *) browser;

@end

@interface NSObject (IKImageBrowserItem)

- (id) imageRepresentation;
- (NSString *) imageRepresentationType;
- (NSString *) imageSubtitle;
- (NSString *) imageTitle;
- (NSString *) imageUID;
- (NSUInteger) imageVersion;
- (BOOL) isSelectable;

@end

extern NString *IKImageBrowserPathRepresentationType;
// etc.
