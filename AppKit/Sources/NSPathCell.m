//
//  NSPathCell.m
//  AppKit
//
//  Created by Fabian Spillner on 27.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//
//  Implemented by Nikolaus Schaller on 03.03.08.
//

#import <AppKit/AppKit.h>

@implementation NSPathCell

+ (Class) pathComponentCellClass;
{
	return [NSPathComponentCell class];
}

// which one is the designated initializer?

- (id) init;
{
	return [self initTextCell:@""];
}

- (id) initTextCell:(NSString *) title
{
	if((self=[super initTextCell:title]))
		{
			_needsSizing=YES;
		}
	return self;
}

- (void) dealloc;
{
	[_pathComponentCells release];
	[_backgroundColor release];
	if(_rects) objc_free(_rects);
	// others
	[super dealloc];
}

- (void) drawWithFrame:(NSRect) cellFrame inView:(NSView *) controlView
{
	[_backgroundColor set];
	NSRectFill(cellFrame);
	if(_pathStyle != NSPathStylePopUp)
		; // draw popup icon
	if([_pathComponentCells count] > 0 && _pathStyle != NSPathStylePopUp)
		{ // draw cells
			NSEnumerator *e=[_pathComponentCells objectEnumerator];
			NSPathComponentCell *cell;
			while((cell = [e nextObject]))
				[cell drawWithFrame:[self rectOfPathComponentCell:cell withFrame:cellFrame inView:controlView] inView:controlView];
			// draw item separator(s)
		}
	else if(_placeholderAttributedString)
		; // draw
	else if(_placeholderString)
		; // draw placeholderString (with default attributes)
}

- (NSArray *) allowedTypes; { return _allowedTypes; }
- (NSColor *) backgroundColor; { return _backgroundColor; }
- (NSPathComponentCell *) clickedPathComponentCell; { return _clickedPathComponentCell; }
- (id) delegate; { return _delegate; }
- (SEL) doubleAction; { return _doubleAction; }

- (void) mouseEntered:(NSEvent *) evt withFrame:(NSRect) frame inView:(NSView *) view;
{
}

- (void) mouseExited:(NSEvent *) evt withFrame:(NSRect) frame inView:(NSView *) view;
{
}

- (NSPathComponentCell *) pathComponentCellAtPoint:(NSPoint) pt withFrame:(NSRect) rect inView:(NSView *) view;
{ // locate the cell we have clicked onto
	NSEnumerator *e=[_pathComponentCells objectEnumerator];
	NSPathComponentCell *cell;
	while((cell = [e nextObject]))
		if(NSMouseInRect(pt, [self rectOfPathComponentCell:cell withFrame:rect inView:view], [view isFlipped]))
			return cell;
	return nil;
}

- (NSArray *) pathComponentCells; { return _pathComponentCells; }
- (NSPathStyle) pathStyle; { return _pathStyle; }
- (NSAttributedString *) placeholderAttributedString; { return _placeholderAttributedString; }
- (NSString *) placeholderString; { return _placeholderString; }

- (NSRect) rectOfPathComponentCell:(NSPathComponentCell *) c withFrame:(NSRect) rect inView:(NSView *) view;
{
	unsigned idx=[_pathComponentCells indexOfObjectIdenticalTo:c];
	if(idx == NSNotFound)
		return NSZeroRect;
	if(_needsSizing)
		{ // (re)calculate cell positions
			unsigned int i;
			unsigned int cnt=[_pathComponentCells count];
			NSRect r=rect;
			_rects=(NSRect *) objc_realloc(_rects, sizeof(_rects[0])*MAX(cnt, 1));
			for(i=0; i<cnt; i++)
				{
					NSPathComponentCell *cell=[_pathComponentCells objectAtIndex:i];
					
					r.size=[cell cellSize];	// make as wide as the cell content defines
					_rects[idx]=r;
					r.origin.x += NSWidth(r);	// advance
				}
			if(cnt && NSMaxX(_rects[cnt-1]) > NSMaxX(rect))
				{ // total width of cells is wider than our cell frame
				// truncate in the middle
				}
		}
	return _rects[idx];
}

- (void) setAllowedTypes:(NSArray *) types; { ASSIGN(_allowedTypes, types); }
- (void) setBackgroundColor:(NSColor *) col; { ASSIGN(_backgroundColor, col); }

- (void) setControlSize:(NSControlSize) controlSize;
{
	NSEnumerator *e=[_pathComponentCells objectEnumerator];
	NSPathComponentCell *cell;
	NSAssert(_pathStyle != NSPathStyleNavigationBar || controlSize == NSSmallControlSize, @"Navigator bare must have small control size");
	while((cell = [e nextObject]))
		[cell setControlSize:controlSize];
	_needsSizing=YES;
}

- (void) setDelegate:(id) delegate; { _delegate=delegate; }
- (void) setDoubleAction:(SEL) sel; { _doubleAction=sel; }

- (void) setObjectValue:(id <NSCopying>) obj;
{
	if([(NSObject *) obj isKindOfClass:[NSString class]])
		[self setURL:[NSURL fileURLWithPath:(NSString *) obj]];	// convert to file URL
	else
		{
		NSAssert([(id) obj isKindOfClass:[NSURL class]], @"setObjectValue expects NSURL or NSString");
		[self setURL:(NSURL *) obj];
		}
}

- (void) setPathComponentCells:(NSArray *) cells; { ASSIGN(_pathComponentCells, cells); _needsSizing=YES; }

- (void) setPathStyle:(NSPathStyle) pathStyle;
{
	_pathStyle=pathStyle;
	if(pathStyle == NSPathStyleNavigationBar)
		[self setControlSize:NSSmallControlSize];	// enforce
	else
		_needsSizing=YES;
}

- (void) setPlaceholderAttributedString:(NSAttributedString *) attrStr; { ASSIGN(_placeholderAttributedString, attrStr); }

- (void) setURL:(NSURL *) url;
{
	NSMutableArray *cells=[NSMutableArray arrayWithCapacity:10];
	BOOL isFile=[url isFileURL];
	// loop over path components
	{
		NSPathComponentCell *cell=[[[[self class] pathComponentCellClass] alloc] init];
		NSURL *partialURL;
		[cell setURL:partialURL];
		if(isFile)
			{
				NSImage *icon=[[NSWorkspace sharedWorkspace] iconForFile:[partialURL path]];
				if(icon)
					{
						// copy???
					if(_pathStyle == NSPathStyleNavigationBar)
						[icon setSize:NSMakeSize(14.0, 14.0)];
					else
						[icon setSize:NSMakeSize(16.0, 16.0)];
					[cell setImage:icon];
					}
			}
		[cells addObject:cell];
		[cell release];
	}
	[self setPathComponentCells:cells];
	[super setObjectValue:url];
}

- (NSURL *) URL; { return [self objectValue]; }

- (BOOL) trackMouse:(NSEvent *) event inRect:(NSRect) cellFrame ofView:(NSView *) controlView untilMouseUp:(BOOL) flag
{
	NSPoint point=[controlView convertPoint:[event locationInWindow] fromView:nil];
	if(![self isEnabled])
		return NO;
	if(_pathStyle == NSPathStylePopUp)
		{
			// build Menu
			// if[self isEditable], add separator&Choose...
			// popup menu
			return YES;
		}
	_clickedPathComponentCell=[self pathComponentCellAtPoint:point withFrame:cellFrame inView:controlView];
	if(_clickedPathComponentCell)
		{
			NSRect rect=[self rectOfPathComponentCell:_clickedPathComponentCell withFrame:cellFrame inView:controlView];
			return [_clickedPathComponentCell trackMouse:event inRect:rect ofView:controlView untilMouseUp:flag];	// forward tracking to clicked cell
		}
	return [super trackMouse:event inRect:cellFrame ofView:controlView untilMouseUp:flag];	// standard tracking
}													

- (void) _chooseURL:(id) sender
{ // choose specific URL from popup menu
	NSURL *url;
	// get URL from menu item (can we use representedObject?)
	[self setURL:url];
	// call action?
}

- (void) _choose:(id) sender
{ // choose from popup menu
	NSOpenPanel *openPanel=[NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:YES];
	[openPanel setResolvesAliases:YES];
	if([openPanel runModalForTypes:[self allowedTypes]] == NSOKButton)
		[self setURL:[openPanel URL]];	// change
}

- (id) initWithCoder:(NSCoder *) coder;
{
	return NIMP;
}

@end
@implementation NSObject (NSPathCellDelegate)

- (void) pathCell:(NSPathCell *) sender willDisplayOpenPanel:(NSOpenPanel *) openPanel; { return; }
- (void) pathCell:(NSPathCell *) sender willPopUpMenu:(NSMenu *) menu; { return; }

@end
