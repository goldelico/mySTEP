//
//  IKImageBrowser.h
//  ImageKit
//
//  Created by H. Nikolaus Schaller on 16.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum
{
	IKCellsStyleNone		= 0,
	IKCellsStyleShadowed	= 1,
	IKCellsStyleOutlined	= 2,
	IKCellsStyleTitled		= 4,
	IKCellsStyleSubtitled	= 8
};

enum
{
	IKGroupBezelStyle		= 0,
	IKGroupDisclosureStyle
};

@interface IKImageBrowserView : NSView
{
	id _dataSource;
	id _delegate;
	id _draggingDestinationDelegate;
	NSIndexSet *_selectionIndexes;
	NSSize _cellSize;
	float _zoomValue;
	NSUInteger _cellsStyleMask;
	NSUInteger _contentResizingMask;
	BOOL _allowsEmptySelection;
	BOOL _allowsMultipleSelection;
	BOOL _allowsReordering;
	BOOL _animates;
	BOOL _constrainsToOriginalSize;
}

- (BOOL) allowsEmptySelection;
- (BOOL) allowsMultipleSelection;
- (BOOL) allowsReordering;
- (BOOL) animates;
- (NSSize) cellSize;
- (NSUInteger) cellsStyleMask;
- (void) collapseGroupAtIndex:(NSUInteger) index;
- (BOOL) constrainsToOriginalSize;
- (NSUInteger) contentResizingMask;
- (id) dataSource;
- (id) delegate;
- (id) draggingDestinationDelegate;
- (void) expandGroupAtIndex:(NSUInteger) index;
- (NSUInteger) indexAtLocationOfDroppedItem;
- (NSInteger) indexOfItemAtPoint:(NSPoint) point;
- (id) initWithFrame:(NSRect) frame;
- (BOOL) isGroupExpandedAtIndex:(NSUInteger) index;
- (NSRect) itemFrameAtIndex:(NSInteger) index;
- (void) reloadData;
- (void) scrollIndexToVisible:(NSInteger) index;
- (NSIndexSet *) selectionIndexes;
- (void) setAllowsEmptySelection: (BOOL) flag;
- (void) setAllowsMultipleSelection: (BOOL) flag;
- (void) setAllowsReordering: (BOOL) flag;
- (void) setAnimates: (BOOL) flag;
- (void) setCellSize:(NSSize) size;
- (void) setCellsStyleMask:(NSUInteger) mask;
- (void) setConstrainsToOriginalSize: (BOOL) flag;
- (void) setContentResizingMask:(NSUInteger) mask;
- (void) setDataSource:(id) source;
- (void) setDelegate:(id) delegate;
- (void) setDraggingDestinationDelegate:(id) delegate;
- (void) setSelectionIndexes:(NSIndexSet *) indexes byExtendingSelection:(BOOL) extend;
- (void) setZoomValue:(float) zoom;
- (float) zoomValue;

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

extern NSString *IKImageBrowserBackgroundColorKey;
extern NSString *IKImageBrowserSelectionColorKey;
extern NSString *IKImageBrowserCellsOutlineColorKey;
extern NSString *IKImageBrowserCellsTitleAttributesKey;
extern NSString *IKImageBrowserCellsHighlightedTitleAttributesKey;
extern NSString *IKImageBrowserCellsSubtitleAttributesKey;
extern NSString *IKImageBrowserGroupRangeKey;
extern NSString *IKImageBrowserGroupBackgroundColorKey;
extern NSString *IKImageBrowserGroupTitleKey;
extern NSString *IKImageBrowserGroupStyleKey;
