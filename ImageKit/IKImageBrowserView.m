//
//  IKImageBrowserView.m
//  ImageKit
//
//  Created by H. Nikolaus Schaller on 16.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "IKImageBrowserView.h"


@implementation IKImageBrowserView

- (id) initWithFrame:(NSRect) frame
{
    if((self = [super initWithFrame:frame]))
		{
			// Initialization code here.
		}
    return self;
}

- (void) dealloc;
{
	[_selectionIndexes release];
	[super dealloc];
}

- (void) drawRect:(NSRect) rect
{
    // Drawing code here.
}

- (BOOL) allowsEmptySelection; { return _allowsEmptySelection; }
- (BOOL) allowsMultipleSelection; { return _allowsMultipleSelection; }
- (BOOL) allowsReordering; { return _allowsReordering; }
- (BOOL) animates; { return _animates; }
- (NSSize) cellSize; { return _cellSize; }
- (NSUInteger) cellsStyleMask; { return _cellsStyleMask; }

- (void) collapseGroupAtIndex:(NSUInteger) index;
{
}

- (BOOL) constrainsToOriginalSize; { return _constrainsToOriginalSize; }
- (NSUInteger) contentResizingMask; { return _contentResizingMask; }
- (id) dataSource; { return _dataSource; }
- (id) delegate; { return _delegate; }
- (id) draggingDestinationDelegate; { return _draggingDestinationDelegate; }

- (void) expandGroupAtIndex:(NSUInteger) index;
{
}

- (NSUInteger) indexAtLocationOfDroppedItem;
{
	return 0;
}

- (NSInteger) indexOfItemAtPoint:(NSPoint) point;
{
	return 0;
}

- (BOOL) isGroupExpandedAtIndex:(NSUInteger) index;
{
}

- (NSRect) itemFrameAtIndex:(NSInteger) index;
{
}

- (void) reloadData;
{
}

- (void) scrollIndexToVisible:(NSInteger) index;
{
}

- (NSIndexSet *) selectionIndexes; { return _selectionIndexes; }

- (void) setAllowsEmptySelection: (BOOL) flag; { _allowsEmptySelection=flag; }
- (void) setAllowsMultipleSelection: (BOOL) flag; { _allowsMultipleSelection=flag; }
- (void) setAllowsReordering: (BOOL) flag; { _allowsReordering=flag; }
- (void) setAnimates: (BOOL) flag; { _animates=flag; }
- (void) setCellSize:(NSSize) size; { _cellSize=size; /* redraw? */ }
- (void) setCellsStyleMask:(NSUInteger) mask; { _cellsStyleMask=mask; }
- (void) setConstrainsToOriginalSize: (BOOL) flag; { _constrainsToOriginalSize=flag; }
- (void) setContentResizingMask:(NSUInteger) mask; { _contentResizingMask=mask; }
- (void) setDataSource:(id) source; { _dataSource=source; }
- (void) setDelegate:(id) delegate; { _delegate=delegate; }
- (void) setDraggingDestinationDelegate:(id) delegate; { _draggingDestinationDelegate=delegate; }

- (void) setSelectionIndexes:(NSIndexSet *) indexes byExtendingSelection:(BOOL) extend;
{
}

- (void) setZoomValue:(float) zoom;
{
	if(_zoomValue != zoom)
		{
			_zoomValue=zoom;
			// redraw
		}
}

- (float) zoomValue; { return _zoomValue; }

- (void) encodeWithCoder:(NSCoder *) coder;
{
}

- (id) initWithCoder:(NSCoder *) coder;
{
	return self;
}

- (void) mouseDown:(NSEvent *) event;
{ // tracking, selection, D&D 
}

@end

#if MATERIAL

// ----------------------------------------------------------------------------
//  MUPhotoView
//
// Copyright (c) 2006 Blake Seely
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
//    OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//  * You include a link to http://www.blakeseely.com in your final product.
// ----------------------------------------------------------------------------

#import "MUPhotoView.h"

@implementation MUPhotoView

#pragma mark -
// Initializers and Dealloc
#pragma mark Initializers and Dealloc

+ (void)initialize
{
    [self exposeBinding:@"photosArray"];
    [self exposeBinding:@"selectedPhotoIndexes"];
    [self exposeBinding:@"backgroundColor"];
    [self exposeBinding:@"photoSize"];
    [self exposeBinding:@"useShadowBorder"];
    [self exposeBinding:@"useOutlineBorder"];
    [self exposeBinding:@"useShadowSelection"];
    [self exposeBinding:@"useOutlineSelection"];
    
    [self setKeys:[NSArray arrayWithObject:@"backgroundColor"] triggerChangeNotificationsForDependentKey:@"shadowBoxColor"];
}

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil) {
        
        delegate = nil;
        sendsLiveSelectionUpdates = YES;
        useHighQualityResize = YES;
        photosArray = nil;
        photosFastArray = nil;
		
        currentSelection = [[NSMutableIndexSet alloc] init];
        
		[self setBackgroundColor:[NSColor grayColor]];
        
        useShadowBorder = YES;
        useOutlineBorder = NO;
        borderShadow = [[NSShadow alloc] init];
        [borderShadow setShadowOffset:NSMakeSize(2.0,-3.0)];
        [borderShadow setShadowBlurRadius:5.0];
        noShadow = [[NSShadow alloc] init];
        [noShadow setShadowOffset:NSMakeSize(0,0)];
        [noShadow setShadowBlurRadius:0.0];
        [self setBorderOutlineColor:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0]];
        
        
        useShadowSelection = NO;
        useBorderSelection = YES;
		
        //[self setSelectionBorderColor:[NSColor selectedControlColor]];
        [self setSelectionBorderColor:[[NSColor colorWithDeviceRed:0.0/255.0 green:204.0/255.0 blue:0.0/255.0 alpha:1.0] retain]];
		
        
        selectionBorderWidth = 3.0;
        [self setShadowBoxColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
        
        //spotlightColor = [[NSColor colorWithCalibratedRed:250/255.0 green:254/255.0 blue:224/255.0 alpha:1.0] retain];
        spotlightColor = [NSColor lightGrayColor];
        
#if 0					// dim spotlight
		spotlightBackground=[[NSColor colorWithCalibratedWhite:0.2 alpha:1.0] retain];
#else
		spotlightBackground = nil;
#endif
        useSpotlight = YES;
		
        photoSize = 100.0;
        photoVerticalSpacing = 25.0;
        photoHorizontalSpacing = 25.0;
        
        photoResizeTimer = nil;
        photoResizeTime = [[NSDate date] retain];
        isDonePhotoResizing = YES;
		
		nameBeingEdited = NSNotFound;
		dropDestinationIndex = NSNotFound;
#if 0
		NSLog(@"MUPhotoView %p initWithFrame: %@", self, NSStringFromRect(frameRect));
#endif
    }
	
	return self;
}

- (void) awakeFromNib;
{ // enclosing scroll view is now initialized
    [self updateGridAndFrame];
}

- (void)dealloc
{
    [self setBorderOutlineColor:nil];
    [self setSelectionBorderColor:nil];
    [self setShadowBoxColor:nil];
    [self setBackgroundColor:nil];
    [self setPhotosArray:nil];
	[currentSelection release];
	//    [self setSelectedPhotoIndexes:nil];
    [photoResizeTime release];
    [dragSelectedPhotoIndexes release];
    dragSelectedPhotoIndexes = nil;
    
	[super dealloc];
}

#pragma mark -
// Drawing Methods
#pragma mark Drawing Methods

- (BOOL) isOpaque
{
	return NO;	// we don't know...
}

- (BOOL)isFlipped
{
	return YES;
}

- (void) reloadData;
{
	unsigned count = [delegate photoCountForPhotoView:self];
	[(NSMutableIndexSet *) currentSelection removeIndexesInRange:NSMakeRange(count, NSNotFound-count-1)];	// remove everything beyond existing indices
	[self updateGridAndFrame];	// may have changed!
	[self setNeedsDisplayInRect:[self visibleRect]];
}

- (void)drawRect:(NSRect)rect
{
	// draw the background color
	if (useSpotlight && spotlightBackground)
		[spotlightBackground set];
	else
		[[self backgroundColor] set];
	
	[NSBezierPath fillRect:rect];	// fill background
	
	// get the number of photos
	unsigned photoCount = [self photoCount];
	if (0 == photoCount)
		return;
    
	// any other setup
	if (useHighQualityResize) {
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	}
	
	/**** BEGIN Drawing Photos ****/
	NSRange rangeToDraw = [self photoIndexRangeForRect:rect]; // adjusts for photoCount if the rect goes outside my range
	unsigned index;
	unsigned lastIndex = rangeToDraw.location + rangeToDraw.length;
	for (index = rangeToDraw.location; index <= lastIndex; index++) {
		
		// Get the image at the current index - a red square anywhere in the view means it asked for an image, but got nil for that index
		BOOL spotlighted=YES;
		NSImage *photo = nil;
		NSString *name;
		
		if ([self inLiveResize]) {
			photo = [self fastPhotoAtIndex:index];
		}
		
		if (nil == photo) {
			photo = [self photoAtIndex:index]; 
		}
		
		if (nil == photo) {
			photo = [[[NSImage alloc] initWithSize:NSMakeSize(photoSize,photoSize)] autorelease];
			[photo lockFocus];
			[[NSColor redColor] set];
			[NSBezierPath fillRect:NSMakeRect(0,0,photoSize,photoSize)];
			[photo unlockFocus];
		}
		
		// set it to draw correctly in a flipped view (will restore it after drawing)
		BOOL isFlipped = [photo isFlipped];
		[photo setFlipped:YES];
		
		// scale it to the appropriate size, this method should automatically set high quality if necessary
		photo = [self scalePhoto:photo];
		
		// get all the appropriate positioning information
		NSRect rawGridRect = [self gridRectForIndex:index];
		NSRect gridRect = [self centerScanRect:rawGridRect];
		//        NSRect gridRect = rawGridRect;
		//        NSSize scaledSize = [self scaledPhotoSizeForSize:[photo size]];
		//      NSRect rawPhotoRect = [self rectCenteredInRect:gridRect withSize:scaledSize];
		//        NSRect photoRect = [self centerScanRect:rawPhotoRect];
		//        NSRect photoRect = rawPhotoRect;
		NSRect photoRect = [self photoRectForIndex:index];
		photoRect = [self centerScanRect:photoRect];
#if 0
		if (index == 0)
			{
				NSLog(@"gridRect=%@", NSStringFromRect(rawGridRect));
				NSLog(@"centered gridRect=%@", NSStringFromRect(gridRect));
				NSLog(@"scaledSize=%@", NSStringFromSize(scaledSize));
				NSLog(@"photoRect=%@", NSStringFromRect(rawPhotoRect));
				NSLog(@"centered photoRect=%@", NSStringFromRect(photoRect));
			}
#endif
		//**** BEGIN Background Drawing - any drawing that technically goes under the image ****/
		// kSelectionStyleShadowBox draws a semi-transparent rounded rect behind/around the image
		if ([currentSelection containsIndex:index] && [self useShadowSelection]) {
			NSBezierPath *shadowBoxPath = [self shadowBoxPathForRect:gridRect];
			[shadowBoxColor set];
			[shadowBoxPath fill];
		}
		
		if (useSpotlight) {
			if (spotlightBackground) {
				[spotlightBackground set];
				NSRectFill(gridRect);
			}
			if ((spotlighted=[delegate photoView:self spotlightPhotoAtIndex:index])) { // spotlight
				NSBezierPath *spotlightPath = [self shadowBoxPathForRect:gridRect];
				[spotlightColor set];
				[spotlightPath fill];
			}
		}
		
		//**** END Background Drawing ****/
		
		// kBorderStyleShadow - set the appropriate shadow
		if ([self useShadowBorder]) {
			[borderShadow set];
		}
		
		// draw the current photo
		NSRect imageRect = NSMakeRect(0, 0, [photo size].width, [photo size].height);
		[photo drawInRect:photoRect fromRect:imageRect operation:(useOutlineBorder?NSCompositeCopy:NSCompositeSourceOver) fraction:spotlighted?1.0:1.0];
		// restore the photo's flipped status
		[photo setFlipped:isFlipped];
		
		// kBorderStyleShadow - remove the shadow after drawing the image
		[noShadow set];
		
		// draw the photo name (if any)
		
		name = [delegate photoView:self photoNameAtIndex:index];        
		if (name) { // draw photo name centered
			NSRect	nameRect = [self nameRectForIndex:index forName:name fullWidth:NO];
			[name drawInRect:nameRect withAttributes:[self nameAttributes:!spotlightBackground || useSpotlight]];
		}
		
		//**** BEGIN Foreground Drawing - includes outline borders, selection rectangles ****/
		
		// drag destination overrides current selection
		
		if (index == dropDestinationIndex) {
			NSBezierPath *selectionBorder = [NSBezierPath bezierPathWithRect:NSInsetRect(photoRect,-3.0,-3.0)];
			[selectionBorder setLineWidth:[self selectionBorderWidth]];
			[[NSColor selectedControlColor] set];
			[selectionBorder stroke];
		} 
		else if ([currentSelection containsIndex:index] && [self useBorderSelection]) {
			NSBezierPath *selectionBorder = [NSBezierPath bezierPathWithRect:NSInsetRect(photoRect,-3.0,-3.0)];
			[selectionBorder setLineWidth:[self selectionBorderWidth]];
			[[self selectionBorderColor] set];
			[selectionBorder stroke];
		} 
		else if ([self useOutlineBorder]) {
			photoRect = NSInsetRect(photoRect,0.5,0.5); // line up the 1px border so it completely fills a single row of pixels
			NSBezierPath *outline = [NSBezierPath bezierPathWithRect:photoRect];
			[outline setLineWidth:1.0];
			[borderOutlineColor set];
			[outline stroke];
		}
		
		NSRectCorner corner;
		for(corner = NSBottomLeftCorner; corner <= NSBottomRightCorner; corner++) {
			NSImage *cornerTag=[delegate photoView:self cornerTagAtIndex:index corner:corner];
			if (cornerTag) {
				NSPoint p;
				NSSize sz = [cornerTag size];
				switch(corner) {
					case NSTopLeftCorner:	p=photoRect.origin; break;
					case NSBottomLeftCorner:		p=photoRect.origin; p.y+=photoRect.size.height; break;
					case NSBottomRightCorner:		p=photoRect.origin; p.y+=photoRect.size.height; p.x+=photoRect.size.width; break;
					case NSTopRightCorner:	p=photoRect.origin; p.x+=photoRect.size.width; break;
				}
				p.x-=sz.width/2.0;
				p.y+=sz.height/2.0;
				[cornerTag dissolveToPoint:p fraction:0.8];
			}
		}
		
		//**** END Foreground Drawing ****//
	}
	
	//**** END Drawing Photos ****//
	
	//**** BEGIN Selection Rectangle ****//
	if (drawSelectionRectangle) {
		[noShadow set];
		[[NSColor whiteColor] set];
		
		float minX = (mouseDownPoint.x < mouseCurrentPoint.x) ? mouseDownPoint.x : mouseCurrentPoint.x;
		float minY = (mouseDownPoint.y < mouseCurrentPoint.y) ? mouseDownPoint.y : mouseCurrentPoint.y;
		float maxX = (mouseDownPoint.x > mouseCurrentPoint.x) ? mouseDownPoint.x : mouseCurrentPoint.x;
		float maxY = (mouseDownPoint.y > mouseCurrentPoint.y) ? mouseDownPoint.y : mouseCurrentPoint.y;
		NSRect selectionRectangle = NSMakeRect(minX,minY,maxX-minX,maxY-minY);
		[NSBezierPath strokeRect:selectionRectangle];
		
		[[NSColor colorWithDeviceRed:0.8 green:0.8 blue:0.8 alpha:0.5] set];
		[NSBezierPath fillRect:selectionRectangle];
	}
	
	if (nameBeingEdited != NSNotFound) { // draw first responder box around field editor
		NSText *fe = [[self window] fieldEditor:NO forObject:self];
		NSBezierPath *selectionBorder = [NSBezierPath bezierPathWithRect:NSInsetRect([fe frame], -3.0, -3.0)];
		[selectionBorder setLineWidth:[self selectionBorderWidth]];
		[[self selectionBorderColor] set];
		[selectionBorder stroke];
	}
	//**** END Selection Rectangle ****//
	
}

#pragma mark -
// Delegate Accessors
#pragma mark Delegate Accessors

- (id)delegate
{
    return delegate;
}

- (void)setDelegate:(id)del
{
    [self willChangeValueForKey:@"delegate"];
    delegate = del;
    [self didChangeValueForKey:@"delegate"];
}

#pragma mark -
// Photos Methods
#pragma mark Photo Methods

- (NSArray *)photosArray
{
    //NSLog(@"in -photosArray, returned photosArray = %@", photosArray);
    return [[photosArray retain] autorelease]; 
}

- (void)setPhotosArray:(NSArray *)aPhotosArray
{
    //NSLog(@"in -setPhotosArray:, old value of photosArray: %@, changed to: %@", photosArray, aPhotosArray);
    if (photosArray != aPhotosArray) {
        [photosArray release];
        [self willChangeValueForKey:@"photosArray"];
        photosArray = [aPhotosArray mutableCopy];
        [self didChangeValueForKey:@"photosArray"];
        
        // update live resize array
        if (nil != photosFastArray) {
            [photosFastArray release];
        }
        photosFastArray = [[NSMutableArray alloc] initWithCapacity:[aPhotosArray count]];
        unsigned i;
        for (i = 0; i < [photosArray count]; i++)
			{
				[photosFastArray addObject:[NSNull null]];
			}
        
        // update internal grid size, adjust height based on the new grid size
        [self scrollPoint:([self frame].origin)];
        [self setNeedsDisplayInRect:[self visibleRect]];
    }
}

#pragma mark -
// Selection Management
#pragma mark Selection Management

- (void) scrollToPhotoAtIndex:(unsigned) idx;
{
	if (idx != NSNotFound)
		[self scrollRectToVisible:[self gridRectForIndex:idx]];
}

- (NSIndexSet *)currentSelection
{
	return currentSelection;
}

- (void)changeSelection:(NSIndexSet *)indexes
{ // change selection
	[self setCurrentSelection:indexes];							// update selection
	[delegate photoView:self changeSelection:indexes];	// and notify delegate
}

- (void)setCurrentSelection:(NSIndexSet *)indexes
{
	[self dirtyDisplayRectsForNewSelection:indexes oldSelection:currentSelection];
	[currentSelection autorelease];
	currentSelection = [indexes mutableCopy];
	unsigned count = [delegate photoCountForPhotoView:self];
	[(NSMutableIndexSet *) currentSelection removeIndexesInRange:NSMakeRange(count, NSNotFound-count-1)];	// remove everything beyond existing indices
	
#if REMOVE
	NSMutableIndexSet *oldSelection = nil;
	
	// Set the new selection, but save the old selection so we know exactly what to redraw
	if (nil != [self selectedPhotoIndexes]) {
		oldSelection = [[self selectedPhotoIndexes] retain];
		[self setSelectedPhotoIndexes:indexes];
	} 
	else if (nil != delegate) {
		// We have to iterate through the photos to figure out which ones the delegate thinks are selected - that's the only way to know the old selection when in delegate mode
		oldSelection = [[NSMutableIndexSet alloc] init];
		int i, count = [self photoCount];
		for( i = 0; i < count; i += 1 ) {
			if ([self isPhotoSelectedAtIndex:i]) {
				[oldSelection addIndex:i];
			}
		}
		
		// Now update the selection
		indexes = [delegate photoView:self willsetCurrentSelection:indexes];
		[self setSelectedPhotoIndexes:indexes];
		[delegate photoView:self didsetCurrentSelection:indexes];
	}
	
	[self dirtyDisplayRectsForNewSelection:indexes oldSelection:oldSelection];
	[oldSelection release];
#endif
	
}

#pragma mark -
// Selection Style
#pragma mark Selection Style

- (BOOL)allowsMultipleSelection;
{
	return allowsMultipleSelection;
}

- (void)setAllowsMultipleSelection:(BOOL)flag;
{
	allowsMultipleSelection = flag;
}

- (BOOL)useBorderSelection
{
    //NSLog(@"in -useBorderSelection, returned useBorderSelection = %@", useBorderSelection ? @"YES": @"NO");
    return useBorderSelection;
}

- (void)setUseBorderSelection:(BOOL)flag
{
    //NSLog(@"in -setUseBorderSelection, old value of useBorderSelection: %@, changed to: %@", (useBorderSelection ? @"YES": @"NO"), (flag ? @"YES": @"NO"));
    [self willChangeValueForKey:@"useBorderSelection"];
    useBorderSelection = flag;
    [self didChangeValueForKey:@"useBorderSelection"];
    
    [self setNeedsDisplayInRect:[self visibleRect]];
}

- (NSColor *)selectionBorderColor
{
    //NSLog(@"in -selectionBorderColor, returned selectionBorderColor = %@", selectionBorderColor);
    return [[selectionBorderColor retain] autorelease]; 
}

- (void)setSelectionBorderColor:(NSColor *)aSelectionBorderColor
{
    //NSLog(@"in -setSelectionBorderColor:, old value of selectionBorderColor: %@, changed to: %@", selectionBorderColor, aSelectionBorderColor);
    if (selectionBorderColor != aSelectionBorderColor) {
        [selectionBorderColor release];
        [self willChangeValueForKey:@"selectionBorderColor"];
        selectionBorderColor = [aSelectionBorderColor copy];
        [self didChangeValueForKey:@"selectionBorderColor"];
    }
}

- (BOOL)useShadowSelection
{
    //NSLog(@"in -useShadowSelection, returned useShadowSelection = %@", useShadowSelection ? @"YES": @"NO");
    return useShadowSelection;
}

- (void)setUseShadowSelection:(BOOL)flag
{
    //NSLog(@"in -setUseShadowSelection, old value of useShadowSelection: %@, changed to: %@", (useShadowSelection ? @"YES": @"NO"), (flag ? @"YES": @"NO"));
    [self willChangeValueForKey:@"useShadowSelection"];
    useShadowSelection = flag;
    [self willChangeValueForKey:@"useShadowSelection"];
    
    [self setNeedsDisplayInRect:[self visibleRect]];
}

- (BOOL)usesSpotlight; { return useSpotlight; }
- (void)setUseSpotlight:(BOOL)flag; { useSpotlight = flag; }

#pragma mark -
// Appearance
#pragma mark Appearance

- (BOOL)useShadowBorder
{
    //NSLog(@"in -useShadowBorder, returned useShadowBorder = %@", useShadowBorder ? @"YES": @"NO");
    return useShadowBorder;
}

- (void)setUseShadowBorder:(BOOL)flag
{
    //NSLog(@"in -setUseShadowBorder, old value of useShadowBorder: %@, changed to: %@", (useShadowBorder ? @"YES": @"NO"), (flag ? @"YES": @"NO"));
    [self willChangeValueForKey:@"useShadowBorder"];
    useShadowBorder = flag;
    [self didChangeValueForKey:@"useShadowBorder"];
    
    [self setNeedsDisplayInRect:[self visibleRect]];
}

- (BOOL)useOutlineBorder
{
    //NSLog(@"in -useOutlineBorder, returned useOutlineBorder = %@", useOutlineBorder ? @"YES": @"NO");
    return useOutlineBorder;
}

- (void)setUseOutlineBorder:(BOOL)flag
{
    //NSLog(@"in -setUseOutlineBorder, old value of useOutlineBorder: %@, changed to: %@", (useOutlineBorder ? @"YES": @"NO"), (flag ? @"YES": @"NO"));
    [self willChangeValueForKey:@"useOutlineBorder"];
    useOutlineBorder = flag;
    [self didChangeValueForKey:@"useOutlineBorder"];
    
    [self setNeedsDisplayInRect:[self visibleRect]];
}

- (NSColor *)backgroundColor
{
    //NSLog(@"in -backgroundColor, returned backgroundColor = %@", backgroundColor);
    return [[backgroundColor retain] autorelease]; 
}

- (void)setBackgroundColor:(NSColor *)aBackgroundColor
{
    //NSLog(@"in -setBackgroundColor:, old value of backgroundColor: %@, changed to: %@", backgroundColor, aBackgroundColor);
    if (backgroundColor != aBackgroundColor) {
        [backgroundColor release];
        [self willChangeValueForKey:@"backgroundColor"];
        backgroundColor = [aBackgroundColor copy];
        [self didChangeValueForKey:@"backgroundColor"];
        
        // adjust the shadow box selection color based on the background color. values closer to white use black and vice versa
        NSColor *newShadowBoxColor;
        float whiteValue = 0.0;
        if ([backgroundColor numberOfComponents] >= 3) {
            float red, green, blue;
            [backgroundColor getRed:&red green:&green blue:&blue alpha:NULL];
            whiteValue = (red + green + blue) / 3;
        } else if ([backgroundColor numberOfComponents] >= 1) {
            [backgroundColor getWhite:&whiteValue alpha:NULL];
        }
        
        if (0.5 > whiteValue)
            newShadowBoxColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.5];
        else
            newShadowBoxColor = [NSColor colorWithDeviceWhite:0.0 alpha:0.5];
        [self setShadowBoxColor:newShadowBoxColor];
    }
}

- (float)photoSize
{
#if 0
    NSLog(@"in -photoSize, returned photoSize = %f", photoSize);
#endif
	return photoSize;
}

- (void)setPhotoSize:(float)aPhotoSize
{
	if (photoSize == aPhotoSize)
		return;	// unchanged
#if 0
	NSLog(@"in -setPhotoSize, old value of photoSize: %f, changed to: %f", photoSize, aPhotoSize);
#endif
	[self willChangeValueForKey:@"photoSize"];
	photoSize = aPhotoSize;
	[self didChangeValueForKey:@"photoSize"];
	[self reloadData];
#if OLD
    // update internal grid size, adjust height based on the new grid size
    // to make sure the same photos stay in view, get a visible photos' index, then scroll to that photo after the update
    NSRect visibleRect = [self visibleRect];
    float heightRatio = visibleRect.origin.y / [self frame].size.height;
    visibleRect.origin.y = heightRatio * [self frame].size.height;
    [self scrollRectToVisible:visibleRect];
    
    [self setNeedsDisplayInRect:[self visibleRect]];
    
    // update time for live resizing
    if (nil != photoResizeTime) {
        [photoResizeTime release];
        photoResizeTime = nil;
    }
    isDonePhotoResizing = NO;
    photoResizeTime = [[NSDate date] retain];
    if (nil == photoResizeTimer) {
        photoResizeTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updatePhotoResizing) userInfo:nil repeats:YES];
    }
#endif
}


- (NSDictionary *) nameAttributes:(BOOL) spotlighted;
{
	return	[NSDictionary dictionaryWithObjectsAndKeys:
			 spotlighted?[NSColor blackColor]:[NSColor whiteColor], NSForegroundColorAttributeName,
			 nil, NSFontAttributeName,
			 nil];
}

- (float)heightOfNameField
{
    return 22.0;
}

- (void)sizeToFit;
{ // resize to fit the enclosing view
#if 0
	NSLog(@"MUPhotoView %p sizeToFit: %@", self, NSStringFromRect([[self superview] bounds]));
#endif
	[super setFrame:[[self superview] bounds]];
	[self updateGridAndFrame];	// force update
	[self setNeedsDisplayInRect:[self visibleRect]];    
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSize
{
#if 0
	NSLog(@"MUPhotoView %p resizeWithOldSuperviewSize: %@", self, NSStringFromSize(oldBoundsSize));
	NSLog(@"autoresizingMask: %u", [self autoresizingMask]);
#endif
	[super resizeWithOldSuperviewSize:oldBoundsSize];
	[self updateGridAndFrame];	// force update
	[self setNeedsDisplayInRect:[self visibleRect]];    
	//	[self sizeToFit];	// track size of superview
}

#pragma mark -
// Don't Mess With Texas
#pragma mark Dont Mess With Texas
// haven't tested changing these behaviors yet - there's no reason they shouldn't work... but use at your own risk.

- (float)nameFieldSpacing
{
    return 10.0;
}

- (float)photoVerticalSpacing
{
    //NSLog(@"in -photoVerticalSpacing, returned photoVerticalSpacing = %f", photoVerticalSpacing);
    return photoVerticalSpacing;
}

- (void)setPhotoVerticalSpacing:(float)aPhotoVerticalSpacing
{
    //NSLog(@"in -setPhotoVerticalSpacing, old value of photoVerticalSpacing: %f, changed to: %f", photoVerticalSpacing, aPhotoVerticalSpacing);
    [self willChangeValueForKey:@"photoVerticalSpacing"];
    photoVerticalSpacing = aPhotoVerticalSpacing;
    [self didChangeValueForKey:@"photoVertificalSpacing"];
    
    // update internal grid size, adjust height based on the new grid size
    NSRect visibleRect = [self visibleRect];
    float heightRatio = visibleRect.origin.y / [self frame].size.height;
    visibleRect.origin.y = heightRatio * [self frame].size.height;
    [self scrollRectToVisible:visibleRect];
    [self setNeedsDisplayInRect:[self visibleRect]]; 
    
    
    // update time for live resizing
    if (nil != photoResizeTime) {
        [photoResizeTime release];
        photoResizeTime = nil;
    }
    isDonePhotoResizing = NO;
    photoResizeTime = [[NSDate date] retain];
    if (nil == photoResizeTimer) {
        photoResizeTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(updatePhotoResizing) userInfo:nil repeats:YES];
    }
    
}

- (float)photoHorizontalSpacing
{
    //NSLog(@"in -photoHorizontalSpacing, returned photoHorizontalSpacing = %f", photoHorizontalSpacing);
    return photoHorizontalSpacing;
}

- (void)setPhotoHorizontalSpacing:(float)aPhotoHorizontalSpacing
{
    //NSLog(@"in -setPhotoHorizontalSpacing, old value of photoHorizontalSpacing: %f, changed to: %f", photoHorizontalSpacing, aPhotoHorizontalSpacing);
    [self willChangeValueForKey:@"photoHorizontalSpacing"];
    photoHorizontalSpacing = aPhotoHorizontalSpacing;
    [self didChangeValueForKey:@"photoHorizontalSpacing"];
    
    // update internal grid size, adjust height based on the new grid size
    NSRect visibleRect = [self visibleRect];
    float heightRatio = visibleRect.origin.y / [self frame].size.height;
    visibleRect.origin.y = heightRatio * [self frame].size.height;
    [self scrollRectToVisible:visibleRect];
    [self setNeedsDisplayInRect:[self visibleRect]];    
	
    // update time for live resizing
    if (nil != photoResizeTime) {
        [photoResizeTime release];
        photoResizeTime = nil;
    }
    isDonePhotoResizing = NO;
    photoResizeTime = [[NSDate date] retain];
    if (nil == photoResizeTimer) {
        photoResizeTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(updatePhotoResizing) userInfo:nil repeats:YES];
    }
    
}


- (NSColor *)borderOutlineColor
{
    //NSLog(@"in -borderOutlineColor, returned borderOutlineColor = %@", borderOutlineColor);
    return [[borderOutlineColor retain] autorelease]; 
}

- (void)setBorderOutlineColor:(NSColor *)aBorderOutlineColor
{
    //NSLog(@"in -setBorderOutlineColor:, old value of borderOutlineColor: %@, changed to: %@", borderOutlineColor, aBorderOutlineColor);
    if (borderOutlineColor != aBorderOutlineColor) {
        [borderOutlineColor release];
        [self willChangeValueForKey:@"borderOutlineColor"];
        borderOutlineColor = [aBorderOutlineColor copy];
        [self didChangeValueForKey:@"borderOutlineColor"];
        
        [self setNeedsDisplayInRect:[self visibleRect]];
    }
}

- (NSColor *)shadowBoxColor
{
    //NSLog(@"in -shadowBoxColor, returned shadowBoxColor = %@", shadowBoxColor);
    return [[shadowBoxColor retain] autorelease]; 
}

- (void)setShadowBoxColor:(NSColor *)aShadowBoxColor
{
    //NSLog(@"in -setShadowBoxColor:, old value of shadowBoxColor: %@, changed to: %@", shadowBoxColor, aShadowBoxColor);
    if (shadowBoxColor != aShadowBoxColor) {
        [shadowBoxColor release];
        shadowBoxColor = [aShadowBoxColor copy];
        
        [self setNeedsDisplayInRect:[self visibleRect]];
    }
    
}
- (float)selectionBorderWidth
{
    //NSLog(@"in -selectionBorderWidth, returned selectionBorderWidth = %f", selectionBorderWidth);
    return selectionBorderWidth;
}

- (void)setSelectionBorderWidth:(float)aSelectionBorderWidth
{
    //NSLog(@"in -setSelectionBorderWidth, old value of selectionBorderWidth: %f, changed to: %f", selectionBorderWidth, aSelectionBorderWidth);
    selectionBorderWidth = aSelectionBorderWidth;
}


#pragma mark -
// Mouse Event Methods
#pragma mark Mouse Event Methods

- (void) textDidEndEditing: (NSNotification *)aNotification
{ // we are the delegate of the field editor
	if (nameBeingEdited != NSNotFound)
		{
			NSText *fe = [[self window] fieldEditor:NO forObject:self];
			NSString *string=[[[fe string] copy] autorelease];	// removeFromSuoerview will clear the string!
#if 0
			NSLog(@"textDidEndEditing:%@", aNotification);
			NSLog(@"string=%@", string);
#endif
			[self setNeedsDisplayInRect:NSInsetRect([fe frame], -10.0, -10.0)];	// redraw everything inc. space covered by focus box...
			[fe removeFromSuperview];
			[delegate photoView:self setPhotoName:string atIndex:nameBeingEdited];
			[self setNeedsDisplayInRect:[self gridRectForIndex:nameBeingEdited]];	// redraw after updating
			nameBeingEdited=NSNotFound;
		}
}

#if 1	// workaround - since after deleting from the end in a multiline text field editor, it does not redraw properly the background

- (void) textDidBeginEditing: (NSNotification *)aNotification
{ // we are the delegate of the field editor
	if (nameBeingEdited != NSNotFound)
		{
			NSText *fe = [[self window] fieldEditor:NO forObject:self];
			feFrame = [fe frame];	// initial size
		}
}

- (void) textDidChange: (NSNotification *)aNotification
{ // we are the delegate of the field editor
	if (nameBeingEdited != NSNotFound)
		{
			NSText *fe = [[self window] fieldEditor:NO forObject:self];
#if 0
			NSLog(@"textDidChange:%@", aNotification);
#endif
			[self setNeedsDisplayInRect:NSInsetRect(NSUnionRect(feFrame, [fe frame]), -10.0, -10.0)];
			feFrame = [fe frame];	// may have been reduced in size
		}
}

#endif

- (void) mouseDown:(NSEvent *) event
{
	drawSelectionRectangle = allowsMultipleSelection;
	mouseDownPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	mouseCurrentPoint = mouseDownPoint;
	lastMouseCurrentPoint = mouseCurrentPoint;
	
	unsigned				clickedIndex = [self photoIndexForPoint:mouseDownPoint];
	NSRect					photoRect = [self photoRectForIndex:clickedIndex];
	NSString				*name = [delegate photoView:self photoNameAtIndex:clickedIndex];        
	NSRect					nameRect = [self nameRectForIndex:clickedIndex forName:name fullWidth:NO];
	unsigned int			flags = [event modifierFlags];
	NSMutableIndexSet*		indexes = [currentSelection mutableCopy];
	BOOL					imageHit = NSPointInRect(mouseDownPoint, photoRect);
	if (nameRect.size.width < 30.0)
		nameRect.size.width = 30.0;	// force minimum width
	if (imageHit) {
		
		if (flags & NSCommandKeyMask) {
			// Flip current image selection state.
			if ([indexes containsIndex:clickedIndex]) { // is contained, remove
				[indexes removeIndex:clickedIndex];
			} else { // is not contained, add
				if (!allowsMultipleSelection)
					[indexes removeAllIndexes];
				[indexes addIndex:clickedIndex];
			}
		}
		else if (allowsMultipleSelection && (flags & NSShiftKeyMask) != 0) {
			// Add range to selection.
			if ([indexes count] == 0) {
				[indexes addIndex:clickedIndex];	// is first
			} else {
				unsigned int origin = (clickedIndex < [indexes lastIndex]) ? clickedIndex :[indexes lastIndex];
				unsigned int length = (clickedIndex < [indexes lastIndex]) ? [indexes lastIndex] - clickedIndex : clickedIndex - [indexes lastIndex];
				length++;
				[indexes addIndexesInRange:NSMakeRange(origin, length)];
			}
		} else { // no modifier - if click on non-selected item, reduce multi-selection to single-selection
			if (![indexes containsIndex:clickedIndex]) { // is not any of the selected
				[indexes removeAllIndexes];
				[indexes addIndex:clickedIndex];
			}
		}
		
		potentialDrag = [delegate photoViewAllowsDrag:self];
	} 
	else if (NSPointInRect(mouseDownPoint, nameRect)) { // name area below the photo
		NSWindow *w;
		NSText *fe = [[self window] fieldEditor:YES forObject:self];
#if 0
		NSLog(@"hit name %@ - fe=%@", name, fe);
		NSLog(@"fe window=%@", [fe window]);
		NSLog(@"fe superview=%@", [fe superview]);
#endif
		if ((w = [fe window])) {
			[w makeFirstResponder:w];	// make sure that we release first responder status if fe did exist and was active
		}
		[self addSubview:fe];	// make it our subview
		nameBeingEdited=clickedIndex;
		[self setFieldEditor:fe frameForIndex:clickedIndex];
		[fe setAlignment:NSCenterTextAlignment];
		[(NSTextView *) fe setAllowsUndo:YES];
		[fe setTextColor:[NSColor blackColor]];
		[fe setString:name];	// insert current text value
		[fe setDelegate:self];
		[fe setSelectedRange:(NSRange){0, [name length]}];	// select all
		[[self window] makeFirstResponder:fe];	// make the field editor the first responder
		[fe setNeedsDisplay:YES];
		feFrame = [fe frame];	// save
		//		[fe mouseDown:event];	// pass first click to field editor
		return;	// don't change selection
	}
	else { // clicked outside of any image
		if ((flags & (NSShiftKeyMask|NSCommandKeyMask)) == 0) {
			[indexes removeAllIndexes];	// neither shift nor command key
		}
		potentialDrag = NO;
	}
	
	[self setCurrentSelection:indexes];	// update selection
	[indexes release];
}

- (void)mouseDragged:(NSEvent *)event
{
	mouseCurrentPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	
	if (NSEqualPoints(mouseCurrentPoint, lastMouseCurrentPoint))
		return;	// not really dragged
	
	lastMouseCurrentPoint = mouseCurrentPoint;
	
	// if the mouse has moved less than 5px in either direction, don't register the drag yet
	float xFromStart = fabs((mouseDownPoint.x - mouseCurrentPoint.x));
	float yFromStart = fabs((mouseDownPoint.y - mouseCurrentPoint.y));
	if ((xFromStart < 5) && (yFromStart < 5)) {
		return;
		
	} 
	else if (potentialDrag && (nil != delegate)) {
		// create a drag image
		unsigned clickedIndex = [self photoIndexForPoint:mouseDownPoint];
		NSImage *clickedImage = [self photoAtIndex:clickedIndex];
		BOOL flipped = [clickedImage isFlipped];
		[clickedImage setFlipped:NO];
		NSSize scaledSize = [self scaledPhotoSizeForSize:[clickedImage size]];
		if (nil == clickedImage) { // creates a red image, which should let the user/developer know something is wrong
			clickedImage = [[[NSImage alloc] initWithSize:NSMakeSize(photoSize,photoSize)] autorelease];
			[clickedImage lockFocus];
			[[NSColor redColor] set];
			[NSBezierPath fillRect:NSMakeRect(0,0,photoSize,photoSize)];
			[clickedImage unlockFocus];
		}
		NSImage *dragImage = [[NSImage alloc] initWithSize:scaledSize];
		
		// draw the drag image as a semi-transparent copy of the image the user dragged, and optionally a red badge indicating the number of photos
		[dragImage lockFocus];
		[clickedImage drawInRect:NSMakeRect(0,0,scaledSize.width,scaledSize.height) fromRect:NSMakeRect(0,0,[clickedImage size].width,[clickedImage size].height)  operation:NSCompositeCopy fraction:0.5];
		[dragImage unlockFocus];
		
		[clickedImage setFlipped:flipped];
		
		// if there's more than one image, put a badge on the photo
		if ([currentSelection count] > 1) {
			NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
			[attributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
			[attributes setObject:[NSFont fontWithName:@"Helvetica" size:12] forKey:NSFontAttributeName];
			NSAttributedString *badgeString = [[NSAttributedString alloc] initWithString:[[NSNumber numberWithInt:[currentSelection count]] stringValue] attributes:attributes];
			NSSize stringSize = [badgeString size];
			int diameter = stringSize.width;
			if (stringSize.height > diameter) diameter = stringSize.height;
			
			diameter = stringSize.width;
			if (stringSize.height > diameter) {
				diameter = stringSize.height;
			}
			diameter += 3;
			
			// calculate the badge circle
			int minY = 0;
			int maxY = minY + diameter;
			
			int minX = (diameter - stringSize.width) / 2 - 1;
			int maxX = minX + diameter;
			
			NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(minX,minY,maxX-minX,maxY-minY)];
			// draw the circle
			[dragImage lockFocus];
			[[NSColor colorWithDeviceRed:1 green:0.1 blue:0.1 alpha:0.7] set];
			[circle fill];
			[dragImage unlockFocus];
			
			// draw the string
			NSPoint point;
			point.x = maxX - ((maxX - minX) / 2) - (stringSize.width / 2);
			point.y = (maxY - minY) / 2 - (stringSize.height / 2) + 1;
			
			[dragImage lockFocus];
			[badgeString drawAtPoint:point];
			[dragImage unlockFocus];
			
			[badgeString release];
			[attributes release];
		}
		
		// get the supported drag data types from the delegate
		NSArray *types = [delegate pasteboardDragTypesForPhotoView:self];
		
		if (nil != types) {
			// get the pasteboard and register the returned types with delegate as the owner
			NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSDragPboard];
			NSString *type;
			NSEnumerator *te = [types objectEnumerator];
			[pb declareTypes:types owner:delegate];
			while((type = [te nextObject]))
				[delegate photoView:self writePasteboard:pb forPhotoAtIndexes:currentSelection dataType:type];
			
			// place the cursor in the center of the drag image
			NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
			NSSize imageSize = [dragImage size];
			p.x = p.x - imageSize.width / 2;
			p.y = p.y + imageSize.height / 2;
			
			[self dragImage:dragImage at:p offset:NSMakeSize(0,0) event:event pasteboard:pb source:self slideBack:YES];
		}
		
		[dragImage release];
		
	} else {
		// adjust the mouse current point so that it's not outside the frame
		NSRect frameRect = [self frame];
		if (mouseCurrentPoint.x < NSMinX(frameRect))
			mouseCurrentPoint.x = NSMinX(frameRect);
		if (mouseCurrentPoint.x > NSMaxX(frameRect))
			mouseCurrentPoint.x = NSMaxX(frameRect);
		if (mouseCurrentPoint.y < NSMinY(frameRect))
			mouseCurrentPoint.y = NSMinY(frameRect);
		if (mouseCurrentPoint.y > NSMaxY(frameRect))
			mouseCurrentPoint.y = NSMaxY(frameRect);
		
		// determine the rect for the current drag area
		float minX, maxX, minY, maxY;
		minX = (mouseCurrentPoint.x < mouseDownPoint.x) ? mouseCurrentPoint.x : mouseDownPoint.x;
		minY = (mouseCurrentPoint.y < mouseDownPoint.y) ? mouseCurrentPoint.y : mouseDownPoint.y;
		maxX = (mouseCurrentPoint.x > mouseDownPoint.x) ? mouseCurrentPoint.x : mouseDownPoint.x;
		maxY = (mouseCurrentPoint.y > mouseDownPoint.y) ? mouseCurrentPoint.y : mouseDownPoint.y;
		if (maxY > NSMaxY(frameRect))
			maxY = NSMaxY(frameRect);
		if (maxX > NSMaxX(frameRect))
			maxX = NSMaxX(frameRect);
		
		NSRect selectionRect = NSMakeRect(minX,minY,maxX-minX,maxY-minY);
		
		unsigned minIndex = [self photoIndexForPoint:NSMakePoint(minX, minY)];
		unsigned xRun = [self photoIndexForPoint:NSMakePoint(maxX, minY)] - minIndex + 1;
		unsigned yRun = [self photoIndexForPoint:NSMakePoint(minX, maxY)] - minIndex + 1;
		unsigned selectedRows = (yRun / columns);
		
		// Save the current selection (if any), then populate the drag indexes
		// this allows us to shift band select to add to the current selection.
		
		dragSelectedPhotoIndexes = [currentSelection mutableCopy];
		// add indexes in the drag rectangle
		int i;
		for (i = 0; i <= selectedRows; i++) {
			unsigned rowStartIndex = (i * columns) + minIndex;
			int j;
			for (j = rowStartIndex; j < (rowStartIndex + xRun); j++) {
				if (NSIntersectsRect([self photoRectForIndex:j],selectionRect)) {
					if(!allowsMultipleSelection)
						[dragSelectedPhotoIndexes removeAllIndexes];
					[dragSelectedPhotoIndexes addIndex:j];
				}
			}
		}
		// if requested, set the selection. this could cause a rapid series of KVO notifications, so if this is false, the view tracks
		// the selection internally, but doesn't pass it to the bindings or the delegates until the drag is over.
		// This will cause an appropriate redraw.
		if (sendsLiveSelectionUpdates)
			{
				[self setCurrentSelection:dragSelectedPhotoIndexes];
			}
		
		// autoscrolling
		if (autoscrollTimer == nil) {
			autoscrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(autoscroll) userInfo:nil repeats:YES];
		}
		
		//    [[self superview] autoscroll:event];
		[self autoscroll:event];
		
		[self setNeedsDisplayInRect:[self visibleRect]];	// update the selection rectangle
	}
}


- (void)mouseUp:(NSEvent *)event
{
#if 0
	NSLog(@"event = %@", event);
#endif
	if ([dragSelectedPhotoIndexes count] > 0) { // finishing a drag selection
		// move the drag indexes into the main selection indexes
		[self changeSelection:dragSelectedPhotoIndexes];
		[dragSelectedPhotoIndexes release];
		dragSelectedPhotoIndexes = nil;
		[self setNeedsDisplayInRect:[self visibleRect]];	// remove any dragging hints
	} else if ([event clickCount] == 2) { // Double-click Handling
		[delegate photoView:self doubleClick:currentSelection];
	} else {
		[delegate photoView:self singleClick:currentSelection];
	}
	
	if (autoscrollTimer != nil) {
		[autoscrollTimer invalidate];
		autoscrollTimer = nil;
	}
    
	drawSelectionRectangle = NO;
}

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	if (nil != delegate)
		return [delegate photoView:self draggingSourceOperationMaskForLocal:isLocal];
	else
		return NSDragOperationNone;
}

- (void)autoscroll
{ // timeout to simulate additional mouseMoved Events
	NSEvent *event = [NSApp currentEvent];
	mouseCurrentPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	//	[[self superview] autoscroll:event];
	[self mouseDragged:event];
}

#pragma mark -
// Responder Method
#pragma mark Responder Methods

- (BOOL)acceptsFirstResponder
{
	return([self photoCount] > 0);
}

- (BOOL)resignFirstResponder
{
	[self setNeedsDisplay:YES];
	return YES;
}

- (BOOL)becomeFirstResponder
{
	[self setNeedsDisplay:YES];
	return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{
	NSString*					eventKey = [theEvent charactersIgnoringModifiers];
	unichar						keyChar = 0;
	
	if ([eventKey length] == 1)
		{
			keyChar = [eventKey characterAtIndex:0];
			if (keyChar == ' ')
				{
					[delegate photoView:self doubleClick:currentSelection];
					return;
				}
		}
	
	[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}

- (void)deleteBackward:(id)sender
{
    if (0 < [currentSelection count]) {
        [self removePhotosAtIndexes:currentSelection];
    }
}

- (void)selectAll:(id)sender
{
    if (0 < [self photoCount]) {
		[self changeSelection:[[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, [self photoCount])] autorelease]];
    }
}

- (void)insertTab:(id)sender
{
	[[self window] selectKeyViewFollowingView:self];
}

- (void)insertBackTab:(id)sender
{
	[[self window] selectKeyViewPrecedingView:self];
}

// FIXME: these menthods should all call 
- (void)moveLeft:(id)sender
{
	NSIndexSet*					indexes = currentSelection;
	NSMutableIndexSet*			newIndexes = [[NSMutableIndexSet alloc] init];
	
	if (([indexes count] > 0) && (![indexes containsIndex:0]))
		{
			[newIndexes addIndex:[indexes firstIndex] - 1];
		}
	else
		{
			if (([indexes count] == 0) && ([self photoCount] > 0))
				{
					[newIndexes addIndex:[self photoCount] - 1];
				}
		}
	
	if ([newIndexes count] > 0)
		{
			[self changeSelection:newIndexes];
			[self scrollRectToVisible:[self gridRectForIndex:[newIndexes firstIndex]]];
		}
	
	[newIndexes release];
}

- (void)moveLeftAndModifySelection:(id)sender
{
    NSIndexSet *indexes = currentSelection;
	if (([indexes count] > 0) && (![indexes containsIndex:0])) {
		NSMutableIndexSet *newIndexes = [indexes mutableCopy];
        [newIndexes addIndex:([newIndexes firstIndex] - 1)];
        [self changeSelection:newIndexes];
		[self scrollRectToVisible:[self gridRectForIndex:[newIndexes firstIndex]]];
        [newIndexes release];
	}
}

- (void)moveRight:(id)sender
{
	NSIndexSet*					indexes = currentSelection;
	NSMutableIndexSet*			newIndexes = [[NSMutableIndexSet alloc] init];
	
	if (([indexes count] > 0) && (![indexes containsIndex:[self photoCount] - 1]))
		{
			[newIndexes addIndex:[indexes lastIndex] + 1];
		}
	else
		{
			if (([indexes count] == 0) && ([self photoCount] > 0))
				{
					[newIndexes addIndex:0];
				}
		}
	
	if ([newIndexes count] > 0)
		{
			[self changeSelection:newIndexes];
			[self scrollRectToVisible:[self gridRectForIndex:[newIndexes lastIndex]]];
		}
	
	[newIndexes release];
}

- (void)moveRightAndModifySelection:(id)sender
{
    NSIndexSet *indexes = currentSelection;
	if (([indexes count] > 0) && (![indexes containsIndex:([self photoCount] - 1)])) {
		NSMutableIndexSet *newIndexes = [indexes mutableCopy];
        [newIndexes addIndex:([newIndexes lastIndex] + 1)];
        [self changeSelection:newIndexes];
		[self scrollRectToVisible:[self gridRectForIndex:[newIndexes lastIndex]]];
        [newIndexes release];
	}
}

- (void)moveDown:(id)sender
{
	NSIndexSet*					indexes = currentSelection;
	NSMutableIndexSet*			newIndexes = [[NSMutableIndexSet alloc] init];
	unsigned int				destinationIndex = [indexes lastIndex] + columns;
	unsigned int				lastIndex = [self photoCount] - 1;
	
	if (([indexes count] > 0) && (destinationIndex <= lastIndex))
		{
			[newIndexes addIndex:destinationIndex];
		}
	else
		{
			if (([indexes count] == 0) && ([self photoCount] > 0))
				{
					[newIndexes addIndex:0];
				}
		}
	
	if ([newIndexes count] > 0)
		{
			[self changeSelection:newIndexes];
			[self scrollRectToVisible:[self gridRectForIndex:[newIndexes lastIndex]]];
		}
	
	[newIndexes release];
}

- (void)moveDownAndModifySelection:(id)sender
{
	NSIndexSet *indexes = currentSelection;
	unsigned int destinationIndex = [indexes lastIndex] + columns;
	unsigned int lastIndex = [self photoCount] - 1;
	
	if (([indexes count] > 0) && (destinationIndex <= lastIndex)) {
		NSMutableIndexSet *newIndexes = [indexes mutableCopy];
        NSRange addRange;
        addRange.location = [indexes lastIndex] + 1;
        addRange.length = columns;
        [newIndexes addIndexesInRange:addRange];
        [self changeSelection:newIndexes];
		[self scrollRectToVisible:[self gridRectForIndex:[newIndexes lastIndex]]];
        [newIndexes release];
	}
}

- (void)moveUp:(id)sender
{
	NSIndexSet*					indexes = currentSelection;
	NSMutableIndexSet*			newIndexes = [[NSMutableIndexSet alloc] init];
	
	if (([indexes count] > 0) && ([indexes firstIndex] >= columns))
		{
			[newIndexes addIndex:[indexes firstIndex] - columns];
		}
	else
		{
			if (([indexes count] == 0) && ([self photoCount] > 0))
				{
					[newIndexes addIndex:[self photoCount] - 1];
				}
		}
	
	if ([newIndexes count] > 0)
		{
			[self changeSelection:newIndexes];
			[self scrollRectToVisible:[self gridRectForIndex:[newIndexes firstIndex]]];
		}
	
	[newIndexes release];
}

- (void)moveUpAndModifySelection:(id)sender
{
	NSMutableIndexSet *indexes = [currentSelection mutableCopy];
	if (([indexes count] > 0) && ([indexes firstIndex] >= columns)) {
		[indexes addIndexesInRange:NSMakeRange(([indexes firstIndex] - columns), columns + 1)];
		[self changeSelection:indexes];
		[self scrollRectToVisible:[self gridRectForIndex:[indexes firstIndex]]];
	}	
	[indexes release];
}

- (void)scrollToEndOfDocument:(id)sender
{
    [self scrollRectToVisible:[self gridRectForIndex:([self photoCount] - 1)]];
}

- (void)scrollToBeginningOfDocument:(id)sender
{
    [self scrollPoint:NSZeroPoint];
}

- (void)moveToEndOfLine:(id)sender
{
	NSIndexSet *indexes = currentSelection;
	if ([indexes count] > 0) {
		unsigned int destinationIndex = ([indexes lastIndex] + columns) - ([indexes lastIndex] % columns) - 1;
		if (destinationIndex >= [self photoCount]) {
			destinationIndex = [self photoCount] - 1;
		}
		NSIndexSet *newIndexes = [[NSIndexSet alloc] initWithIndex:destinationIndex];
        [self changeSelection:newIndexes];
		[self scrollRectToVisible:[self gridRectForIndex:destinationIndex]];
        [newIndexes release];
	}
}

- (void)moveToEndOfLineAndModifySelection:(id)sender
{
	NSMutableIndexSet *indexes = [currentSelection mutableCopy];
	if ([indexes count] > 0) {
		unsigned int destinationIndexPlusOne = ([indexes lastIndex] + columns) - ([indexes lastIndex] % columns);
		if (destinationIndexPlusOne >= [self photoCount]) {
			destinationIndexPlusOne = [self photoCount];
		}
		[indexes addIndexesInRange:NSMakeRange(([indexes lastIndex]), (destinationIndexPlusOne - [indexes lastIndex]))];
		[self changeSelection:indexes];
		[self scrollRectToVisible:[self gridRectForIndex:[indexes lastIndex]]];
	}
	[indexes release];
}

- (void)moveToBeginningOfLine:(id)sender
{
	NSIndexSet *indexes = currentSelection;
	if ([indexes count] > 0) {
		unsigned int destinationIndex = [indexes firstIndex] - ([indexes firstIndex] % columns);
		NSIndexSet *newIndexes = [[NSIndexSet alloc] initWithIndex:destinationIndex];
        [self changeSelection:newIndexes];
		[self scrollRectToVisible:[self gridRectForIndex:destinationIndex]];
		[newIndexes release];
	}
}

- (void)moveToBeginningOfLineAndModifySelection:(id)sender
{
	NSMutableIndexSet *indexes = [currentSelection mutableCopy];
	if ([indexes count] > 0) {
		unsigned int destinationIndex = [indexes firstIndex] - ([indexes firstIndex] % columns);
		[indexes addIndexesInRange:NSMakeRange(destinationIndex, ([indexes firstIndex] - destinationIndex))];
		[self changeSelection:indexes];
		[self scrollRectToVisible:[self gridRectForIndex:destinationIndex]];
	}
	[indexes release];
}

- (void)moveToBeginningOfDocument:(id)sender
{
    if (0 < [self photoCount]) {
        [self changeSelection:[NSIndexSet indexSetWithIndex:0]];
        [self scrollPoint:NSZeroPoint];
    }
}

- (void)moveToBeginningOfDocumentAndModifySelection:(id)sender
{
	NSMutableIndexSet *indexes = [currentSelection mutableCopy];
	if ([indexes count] > 0) {
		[indexes addIndexesInRange:NSMakeRange(0, [indexes firstIndex])];
		[self changeSelection:indexes];
		[self scrollRectToVisible:NSZeroRect];
	}
	[indexes release];
}

- (void)moveToEndOfDocument:(id)sender
{
    if (0 < [self photoCount]) {
        [self changeSelection:[NSIndexSet indexSetWithIndex:([self photoCount] - 1)]];
        [self scrollRectToVisible:[self gridRectForIndex:([self photoCount] - 1)]];
    }
}

- (void)moveToEndOfDocumentAndModifySelection:(id)sender
{
	NSMutableIndexSet *indexes = [currentSelection mutableCopy];
	if ([indexes count] > 0) {
		[indexes addIndexesInRange:NSMakeRange([indexes lastIndex], ([self photoCount] - [indexes lastIndex]))];
		[self changeSelection:indexes];
		[self scrollRectToVisible:[self gridRectForIndex:[indexes lastIndex]]];
	}
}

#pragma mark NSDraggingDestination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{ // dragged image has entered our frame
	return [self draggingUpdated:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	NSPoint mouse = [sender draggingLocation];	// mouse position in window coordinates
	NSPoint mousePoint = [self convertPoint:mouse fromView:nil];	// convert from window coordinates
	
	[self setNeedsDisplayInRect:[self gridRectForIndex:dropDestinationIndex]];	// update previous
	dropDestinationIndex = [self photoIndexForPoint:mousePoint];
	
	NSRect photoRect = [self photoRectForIndex:dropDestinationIndex];
	BOOL imageHit = NSPointInRect(mousePoint, photoRect);
	
	if (!imageHit)
		{
			dropDestinationIndex = NSNotFound;
			return NSDragOperationNone;	// can't drop outside the real image frame
		}
	[self setNeedsDisplayInRect:[self gridRectForIndex:dropDestinationIndex]];	// update new location
	// we should ask the delegate if it really accepts the specific drop, i.e. if the list of tags dropped is already attached...
	// FIXME:
	// add more visual feedback than changing the + emblem
	// highlight as a drag destination
	//
	return [sender draggingSourceOperationMask] & NSDragOperationCopy;
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{ // dragging ended somewhere else
	[self draggingUpdated:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{ // image has left our frame
	[self draggingUpdated:sender];
}

- (BOOL)wantsPeriodicDraggingUpdates
{
	return NO;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{ // finally agree or refuse the operation
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{ // call delegate to really import the data
	NSPoint mouse = [sender draggingLocation];	// mouse position in window coordinates
	NSPoint mousePoint = [self convertPoint:mouse fromView:nil];	// convert from window coordinates
	unsigned photoIndex = [self photoIndexForPoint:mousePoint];
	
	return [delegate photoView:self acceptDrop:sender onPhotoIndex:photoIndex];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{ // dragging finally done
	[self setNeedsDisplayInRect:[self gridRectForIndex:dropDestinationIndex]];	// update previous
	dropDestinationIndex = NSNotFound;
}

@end

#pragma mark -
// Delegate Default Implementations
#pragma mark Delegate Default Implementations

@implementation NSObject (MUPhotoViewDelegate)

// will only get called if photoArray has not been set, or has not been bound
- (unsigned)photoCountForPhotoView:(MUPhotoView *)view
{
    return 0;
}

- (BOOL) photoViewAllowsDrag:(MUPhotoView *)view
{
	return YES;
}

- (NSString *)photoView:(MUPhotoView *)view photoNameAtIndex:(unsigned)index
{
    return nil;
}

- (void)photoView:(MUPhotoView *)view setPhotoName:(NSString *) name atIndex:(unsigned)index;
{
	return;	// ignore
}

- (BOOL)photoView:(MUPhotoView *)view spotlightPhotoAtIndex:(unsigned)index;
{
	return NO;
}

- (NSImage *)photoView:(MUPhotoView *)view cornerTagAtIndex:(unsigned)index corner:(NSRectCorner) corner;
{
	return nil;
}

- (NSImage *)photoView:(MUPhotoView *)view photoAtIndex:(unsigned)index
{
    return nil;
}

- (NSImage *)photoView:(MUPhotoView *)view fastPhotoAtIndex:(unsigned)index
{
    return [self photoView:view photoAtIndex:index];
}

// selection

- (BOOL)photoView:(MUPhotoView *)view isPhotoSelectedAtIndex:(unsigned)index;
{
	return [[view currentSelection] containsIndex:index];
}

// drag
- (unsigned int)photoView:(MUPhotoView *)view draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
    return NSDragOperationNone;
}

- (NSArray *)pasteboardDragTypesForPhotoView:(MUPhotoView *)view
{
    return [NSArray array];
}

- (void)photoView:(MUPhotoView *)view writePasteboard:(NSPasteboard *) pb forPhotoAtIndexes:(NSIndexSet *)index dataType:(NSString *)type;
{
	return;
}

- (BOOL)photoView:(MUPhotoView *)view acceptDrop:(id <NSDraggingInfo>)info onPhotoIndex:(unsigned) photoIndex;
{
	return NO;	// reject by default
}

// did dragg a selection box
- (void) photoView:(MUPhotoView *)view changeSelection:(NSIndexSet *)indexes;
{
}

// single click
- (void)photoView:(MUPhotoView *)view singleClick:(NSIndexSet *) indexes
{
    
}

// double-click
- (void)photoView:(MUPhotoView *)view doubleClick:(NSIndexSet *) indexes
{
    
}

// photo removal support
- (NSIndexSet *)photoView:(MUPhotoView *)view willRemovePhotosAtIndexes:(NSIndexSet *)indexes
{
    return [NSIndexSet indexSet];
}

- (void)photoView:(MUPhotoView *)view didRemovePhotosAtIndexes:(NSIndexSet *)indexes
{
    
}

@end

#pragma mark -
// Private
#pragma mark Private

@implementation MUPhotoView (PrivateAPI)

- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)theEvent
{
	NSPoint mouseEventLocation;
	
	mouseEventLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	unsigned clickedIndex = [self photoIndexForPoint:mouseEventLocation];
	NSRect photoRect = [self photoRectForIndex:clickedIndex];
	
	return(NSPointInRect(mouseEventLocation, photoRect));
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	// CEsfahani - If acceptsFirstMouse unconditionally returns YES, then it is possible to lose the selection if
	// the user clicks in the content of the window without hitting one of the selected images.  This is
	// the Finder's behavior, and it bothers me.
	// It seems I have two options: unconditionally return YES, or only return YES if we clicked in an image.
	// But, does anyone rely on losing the selection if I bring a window forward?
	
	NSPoint mouseEventLocation;
	
	mouseEventLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	unsigned clickedIndex = [self photoIndexForPoint:mouseEventLocation];
	NSRect photoRect = [self photoRectForIndex:clickedIndex];
	
	return NSPointInRect(mouseEventLocation, photoRect);
}

- (void)viewDidEndLiveResize
{
    [self setNeedsDisplayInRect:[self visibleRect]];
}

- (NSRect) nameRectForIndex:(unsigned) index forName:(NSString *) name fullWidth:(BOOL) flag;
{ // get bounding box of given name
	NSRect					photoRect = [self photoRectForIndex:index];
	NSSize					textSize = name?[name sizeWithAttributes:[self nameAttributes:NO]]:NSMakeSize(20.0, [self heightOfNameField]);
	if (flag)	// as wide as the photo width
		return NSMakeRect(photoRect.origin.x, photoRect.origin.y+photoRect.size.height+[self nameFieldSpacing], photoRect.size.width, textSize.height);
	else		// as wide as needed
		return NSMakeRect(photoRect.origin.x+(photoRect.size.width-textSize.width)/2, photoRect.origin.y+photoRect.size.height+[self nameFieldSpacing], textSize.width, textSize.height);
}

- (void) setFieldEditor:(NSText *) fe frameForIndex:(unsigned) index;
{
	if (index != NSNotFound)
		{
			NSString				*name = [delegate photoView:self photoNameAtIndex:index];        
			NSRect					nameRect = [self nameRectForIndex:index forName:name fullWidth:YES];
			[fe setFrame:nameRect];
			[self setNeedsDisplay:YES];
		}
}

- (void)setFrame:(NSRect)frame
{
#if 0
	NSLog(@"MUPhotoView %p setFrame: %@", self, NSStringFromRect(frame));
#endif
	[super setFrame:frame];			// adjust
	[self updateGridAndFrame];	// force update (which may readjust the frame again!)
}

- (void)updateGridAndFrame
{
	NSRect frame = [self frame];
#if DEBUG
	NSLog(@"updateGridAndFrame");
#endif
    /**** BEGIN Dimension calculations and adjustments ****/
    
    // get the number of photos
    unsigned photoCount = [self photoCount];
    
    // calculate the base grid size
    gridSize.height = [self photoSize] + [self nameFieldSpacing] + [self heightOfNameField] + [self photoVerticalSpacing];
    gridSize.width = [self photoSize] + [self photoHorizontalSpacing];
    
    // calculate the number of columns that fit into our width
	
    columns = frame.size.width / gridSize.width;
    
    // minimum 1 column
    if (columns < 1)
        columns = 1;
    
    // adjust the grid size width for any extra space
    gridSize.width = frame.size.width / columns;
	
    // if we have fewer photos than columns, adjust downwards
    if (photoCount > 0 && photoCount < columns)
        columns = photoCount;
    
    // calculate the number of rows of photos based on the total count and the number of columns
    rows = photoCount / columns;
    if (0 < (photoCount % columns))
		rows++;	// add one partial row
	
    // adjust my frame height to contain all the photos
    
	float h = rows * gridSize.height;	// required height for all entries
    
	if (h < [[self superview] bounds].size.height)
		h = [[self superview] bounds].size.height;	// at least as large as the clipview
    
	if (frame.size.height != h)
		{ // set my new frame height
#if DEBUG
			NSLog(@"updateGridAndFrame - set new height");
#endif
			frame.size.height = h;	// adjust
			[super setFrame:frame];	// may be called in [self setFrame]!
		}
	
    // FIXME: outer scroll bars are note updated synchronuously!!
	
    NSScrollView *s = [self enclosingScrollView];
    [s reflectScrolledClipView:[s contentView]];	// adjust scrollers
	
    [s setNeedsDisplay:YES];
    
    /**** END Dimension calculations and adjustments ****/
}

// will fetch from the internal array if not nil, from delegate otherwise
- (unsigned)photoCount
{
    if (nil != [self photosArray])
        return [[self photosArray] count];
    else if (nil != delegate)
        return [delegate photoCountForPhotoView:self];
    else
        return 0;
}

- (NSImage *)photoAtIndex:(unsigned)index
{
    if ((nil != [self photosArray]) && (index < [self photoCount]))
        return [[self photosArray] objectAtIndex:index];
    else if ((nil != delegate) && (index < [self photoCount]))
        return [delegate photoView:self photoAtIndex:index];
    else
        return nil;
}

- (void)updatePhotoResizing
{
    NSTimeInterval timeSinceResize = [[NSDate date] timeIntervalSinceReferenceDate] - [photoResizeTime timeIntervalSinceReferenceDate];
    if (timeSinceResize > 1) {
        isDonePhotoResizing = YES;
        [photoResizeTimer invalidate];
        photoResizeTimer = nil;
    }
    [self setNeedsDisplayInRect:[self visibleRect]];
}

- (BOOL)inLiveResize
{
    return ([super inLiveResize]) || (!isDonePhotoResizing);
}

- (NSImage *)fastPhotoAtIndex:(unsigned)index
{
    NSImage *fastPhoto;
    if ((nil != [self photosArray]) && (index < [[self photosArray] count]))
		{
			fastPhoto = [photosFastArray objectAtIndex:index];
			if ((NSNull *)fastPhoto == [NSNull null])
				{
					// Change this if you want higher/lower quality fast photos
					float fastPhotoSize = 100.0;
					
					NSImageRep *fullSizePhotoRep = [[self scalePhoto:[self photoAtIndex:index]] bestRepresentationForDevice:nil];
					
					// Figure out what the scaled size is
					float longSide = [fullSizePhotoRep pixelsWide];
					if (longSide < [fullSizePhotoRep pixelsHigh])
						longSide = [fullSizePhotoRep pixelsHigh];
					
					float scale = fastPhotoSize / longSide;
					
					NSSize scaledSize;
					scaledSize.width = [fullSizePhotoRep pixelsWide] * scale;
					scaledSize.height = [fullSizePhotoRep pixelsHigh] * scale;
					
					// Draw the full-size image into our fast, small image.
					fastPhoto = [[NSImage alloc] initWithSize:scaledSize];
					[fastPhoto setFlipped:YES];
					[fastPhoto lockFocus];
					[fullSizePhotoRep drawInRect:NSMakeRect(0.0, 0.0, scaledSize.width, scaledSize.height)];
					[fastPhoto unlockFocus];
					
					// Save it off
					[photosFastArray replaceObjectAtIndex:index withObject:fastPhoto];
					
					[fastPhoto autorelease];
				}
		} else if ((nil != delegate) && ([delegate respondsToSelector:@selector(photoView:fastPhotoAtIndex:)])) {
			fastPhoto = [delegate photoView:self fastPhotoAtIndex:index];
		}
    
    // if the above calls failed, try to just fetch the full size image
    if (nil == fastPhoto) {
        fastPhoto = [self photoAtIndex:index];
    }
    
    return fastPhoto;
}


// placement and hit detection
- (NSSize)scaledPhotoSizeForSize:(NSSize)size
{
    float longSide = size.width;
    if (longSide < size.height)
        longSide = size.height;
    
    float scale = [self photoSize] / longSide;
    
    NSSize scaledSize;
	//    scaledSize.width = floor(size.width * scale);
	//    scaledSize.height = floor(size.height * scale);
    scaledSize.width = size.width * scale;
    scaledSize.height = size.height * scale;
    
    return scaledSize;
}

- (NSImage *)scalePhoto:(NSImage *)image
{
    // calculate the new image size based on the scale
    NSSize newSize;
    NSImageRep *bestRep = [image bestRepresentationForDevice:nil];
    newSize.width = [bestRep pixelsWide];
    newSize.height = [bestRep pixelsHigh];
#if 0
    NSLog(@"%@", NSStringFromSize(newSize));
#endif
    // resize the image
    [image setScalesWhenResized:YES];
    [image setSize:newSize];
    
    return image;
}

- (unsigned)photoIndexForPoint:(NSPoint)point
{
	unsigned column = point.x / gridSize.width;
	unsigned row = point.y / gridSize.height;
	
	return ((row * columns) + column);
}

- (NSRange)photoIndexRangeForRect:(NSRect)rect
{
    unsigned start = [self photoIndexForPoint:rect.origin];
	unsigned finish = [self photoIndexForPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
	
    if (finish >= [self photoCount])
        finish = [self photoCount] - 1;
    
	return NSMakeRange(start, finish-start);
    
}

- (NSRect)gridRectForIndex:(unsigned)index
{
	unsigned row = index / columns;
	unsigned column = index % columns;
	float x = column * gridSize.width;
	float y = row * gridSize.height;
	
	return NSMakeRect(x, y, gridSize.width, gridSize.height);
}

- (NSRect)rectCenteredInRect:(NSRect)rect withSize:(NSSize)size
{
    float x = rect.origin.x + ((rect.size.width - size.width) / 2);
    float y = rect.origin.y + ((rect.size.height - size.height) / 2);
    
	//    return NSMakeRect(x, y, size.width, size.height);
    return NSMakeRect(floor(x), floor(y), size.width, size.height);
}

- (NSRect)photoRectForIndex:(unsigned)index
{
	if ([self photoCount] == 0)
		return NSZeroRect;
	
	// get the grid rect for this index
	NSRect gridRect = [self gridRectForIndex:index];
	
	// get the actual image
	NSImage *photo = [self photoAtIndex:index];
	if (nil == photo)
		return NSZeroRect;
	
	// scale to the current photoSize
	photo = [self scalePhoto:photo];
	
	// scale the dimensions
	NSSize scaledSize = [self scaledPhotoSizeForSize:[photo size]];
	
	// get the photo rect centered in the grid less space for the name
	gridRect.size.height -= ([self nameFieldSpacing] + [self heightOfNameField])/2;
	NSRect photoRect = [self rectCenteredInRect:gridRect withSize:scaledSize];
	
	return photoRect;
}

- (NSBezierPath *)shadowBoxPathForRect:(NSRect)rect
{
	NSRect inset = NSInsetRect(rect,5.0,5.0);
	//float radius = 15.0;
	float radius = 0.0;
	
	float minX = NSMinX(inset);
	float midX = NSMidX(inset);
	float maxX = NSMaxX(inset);
	float minY = NSMinY(inset);
	float midY = NSMidY(inset);
	float maxY = NSMaxY(inset);
	
	NSBezierPath *path = [[NSBezierPath alloc] init];
	[path moveToPoint:NSMakePoint(midX, minY)];
	[path appendBezierPathWithArcFromPoint:NSMakePoint(maxX,minY) toPoint:NSMakePoint(maxX,midY) radius:radius];
	[path appendBezierPathWithArcFromPoint:NSMakePoint(maxX,maxY) toPoint:NSMakePoint(midX,maxY) radius:radius];
	[path appendBezierPathWithArcFromPoint:NSMakePoint(minX,maxY) toPoint:NSMakePoint(minX,midY) radius:radius];
	[path appendBezierPathWithArcFromPoint:NSMakePoint(minX,minY) toPoint:NSMakePoint(midX,minY) radius:radius];
	
	return [path autorelease];
}

// photo removal
- (void)removePhotosAtIndexes:(NSIndexSet *)indexes
{
	// let the delegate know that we're about to delete, give it a chance to modify the indexes we'll delete
	NSIndexSet *modifiedIndexes = indexes;
	if ((nil != delegate) && ([delegate respondsToSelector:@selector(photoView:willRemovePhotosAtIndexes:)])) {
		modifiedIndexes = [delegate photoView:self willRemovePhotosAtIndexes:indexes];
	}
	
	// if using bindings, do the removal
	if ((0 < [modifiedIndexes count]) && (nil != [self photosArray])) {
		[self willChangeValueForKey:@"photosArray"];
		[photosArray removeObjectsAtIndexes:modifiedIndexes];
		[self didChangeValueForKey:@"photosArray"];
	}
	
	if ((nil != delegate) && ([delegate respondsToSelector:@selector(photoView:didRemovePhotosAtIndexes:)])) {
		[delegate photoView:self didRemovePhotosAtIndexes:modifiedIndexes];
	}
}

#if UNUSED
- (NSImage *)scaleImage:(NSImage *)image toSize:(float)size
{
    NSImageRep *fullSizePhotoRep = [[self scalePhoto:image] bestRepresentationForDevice:nil];
	
    float longSide = [fullSizePhotoRep pixelsWide];
    if (longSide < [fullSizePhotoRep pixelsHigh])
        longSide = [fullSizePhotoRep pixelsHigh];
	
    float scale = size / longSide;
	
    NSSize scaledSize;
    scaledSize.width = [fullSizePhotoRep pixelsWide] * scale;
    scaledSize.height = [fullSizePhotoRep pixelsHigh] * scale;
	
    NSImage *fastPhoto = [[NSImage alloc] initWithSize:scaledSize];
    [fastPhoto setFlipped:YES];
    [fastPhoto lockFocus];
	NSLog(@"compositing = %d",		[[NSGraphicsContext currentContext] compositingOperation]);
    [fullSizePhotoRep drawInRect:NSMakeRect(0.0, 0.0, scaledSize.width, scaledSize.height)];
    [fastPhoto unlockFocus];
	
    return [fastPhoto autorelease];
}

#endif

- (void)dirtyDisplayRectsForNewSelection:(NSIndexSet *)newSelection oldSelection:(NSIndexSet *)oldSelection
{
	NSRect visibleRect = [self visibleRect];
	
    // Figure out how the selection changed and only update those areas of the grid
	NSMutableIndexSet *changedIndexes = [NSMutableIndexSet indexSet];
	if (oldSelection && newSelection)
		{
			// First, see which of the old are different than the new
			unsigned int index = [newSelection firstIndex];
			
			while (index != NSNotFound)
				{
					if (![oldSelection containsIndex:index])
						{
							[changedIndexes addIndex:index];
						}
					index = [newSelection indexGreaterThanIndex:index];
				}
			
			// Next, see which of the new are different from the old
			index = [oldSelection firstIndex];
			while (index != NSNotFound)
				{
					if (![newSelection containsIndex:index])
						{
							[changedIndexes addIndex:index];
						}
					index = [oldSelection indexGreaterThanIndex:index];
				}
			
			// Loop through the changes and dirty the rect for each
			index = [changedIndexes firstIndex];
			while (index != NSNotFound)
				{
					NSRect photoRect = [self gridRectForIndex:index];
					if (NSIntersectsRect(visibleRect, photoRect))
						{
							[self setNeedsDisplayInRect:photoRect];
						}
					index = [changedIndexes indexGreaterThanIndex:index];
				}
			
		}
	else
		{
			[self setNeedsDisplayInRect:visibleRect];
		}
	
}

@end

#endif