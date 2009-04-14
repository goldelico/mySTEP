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
	if(self=[super initTextCell:title])
	{
		[self setStringValue:title];
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
	[(_backgroundColor?_backgroundColor:[NSColor controlHighlightColor]) set];
	NSRectFill(cellFrame);
	if(_pathStyle != NSPathStylePopUp)
		; // draw popup icon
	if([_pathComponentCells count] > 0 && _pathStyle != NSPathStylePopUp)
	{ // draw cells
		NSEnumerator *e=[_pathComponentCells objectEnumerator];
		NSPathComponentCell *cell;
		while((cell = [e nextObject]))
		{
			NSRect m = [self rectOfPathComponentCell:cell withFrame:cellFrame inView:controlView];
			[cell drawWithFrame:m inView:controlView];
			// draw item separator(s)
			if (cell != nil) { // draw the separator...
				NSBezierPath *theSeparator = [NSBezierPath bezierPath];
				NSSize cellSize = [cell cellSize];				
				NSRect sepRect = NSMakeRect(m.origin.x+cellSize.width, (cellFrame.size.height/2)-3.0, 6.0,6.0);
				[[NSColor grayColor] setFill];
				[theSeparator moveToPoint:NSMakePoint(sepRect.origin.x, sepRect.origin.y)];
				[theSeparator lineToPoint:NSMakePoint(sepRect.origin.x, sepRect.origin.y + sepRect.size.height)];
				[theSeparator lineToPoint:NSMakePoint(sepRect.origin.x + sepRect.size.width, sepRect.origin.y + (sepRect.size.height /2))];
				[theSeparator lineToPoint:NSMakePoint(sepRect.origin.x, sepRect.origin.y)];
				[theSeparator closePath];
				[theSeparator fill];
			}
		}
	}
	else
		[self drawWithFrame:cellFrame inView:controlView];	// should handle placeholder string
}

- (NSArray *) allowedTypes; { return _allowedTypes; }
- (NSColor *) backgroundColor; { return _backgroundColor; }
- (NSPathComponentCell *) clickedPathComponentCell; { return _clickedPathComponentCell; }
- (id) delegate; { return _delegate; }
- (SEL) doubleAction; { return _doubleAction; }

- (void) mouseEntered:(NSEvent *) evt withFrame:(NSRect) frame inView:(NSView *) view;
{
	_dontTruncateCell = [self pathComponentCellAtPoint: [evt locationInWindow] withFrame:frame inView:view];
	_needsSizing=YES;	// recalculate cell positions
	[[self controlView] updateCell:self];
	NSLog(@"Mouse entered!");
	if (_dontTruncateCell) {
		NSLog(@"Cell gefunden");
	}
}

- (void) mouseExited:(NSEvent *) evt withFrame:(NSRect) frame inView:(NSView *) view;
{
	_dontTruncateCell=nil;
	_needsSizing=YES;	
	[[self controlView] updateCell:self];
	NSLog(@"Mouse exited!");
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
- (NSString *) placeholderString;			{ return ([_placeholderString isKindOfClass:[NSString class]])?_placeholderString:nil; }
- (void) setPlaceholderString:(NSString *) string; { ASSIGN(_placeholderString, string); }
- (NSAttributedString *) placeholderAttributedString;	{ return ([_placeholderString isKindOfClass:[NSAttributedString class]])?_placeholderString:nil; }
- (void) setPlaceholderAttributedString:(NSAttributedString *) string; { ASSIGN(_placeholderString, string); }

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
							r.size.height=rect.size.height;	// and as high as the NSPathCell
							_rects[i]=r;
							r.origin.x += NSWidth(r)+8.0;	// advance
						}
				if(cnt > 0 && NSMaxX(_rects[cnt-1]) > NSMaxX(rect))
						{ // total width of cells is wider than our cell frame
							float oversize=NSMaxX(_rects[cnt-1]) - NSMaxX(rect);
							if(cnt > 1 && _dontTruncateCell)
								oversize /= (cnt-2);	// how much we have to reduce each cell except the cell where the mouse is currently over
							else
								oversize /= (cnt-1);	// how much we have to reduce each cell
							for(i=0; i<cnt; i++)
									{
										if([_pathComponentCells objectAtIndex:i] == _dontTruncateCell)
											continue;	// exclude from truncating this cell
										_rects[i].size.width -= oversize;	// reduce total width
										if(_rects[i].size.width < _rects[i].size.height)
											_rects[i].size.width = _rects[i].size.height;	// must be at least a square to show the icon
//										[[_pathComponentCells objectAtIndex:i] setLineBreakMode:NSLineBreakByTruncatingTail];
										if(i+1 < cnt)
											_rects[i+1].origin.x = NSMaxX(_rects[i])+8.0;	// define start of next cell
									}
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
	[[self controlView] updateCell:self];
}

- (void) setDelegate:(id) delegate; { _delegate=delegate; }
- (void) setDoubleAction:(SEL) sel; { _doubleAction=sel; }

- (void) setObjectValue:(id <NSCopying>) obj;
{
	if([(NSObject *) obj isKindOfClass:[NSString class]])
		[self setURL:[NSURL fileURLWithPath:(NSString *) obj]];	// convert to file URL and calls [super setObjectValue]
	else
	{
		NSAssert([(id) obj isKindOfClass:[NSURL class]], @"setObjectValue expects NSURL or NSString");
		[self setURL:(NSURL *) obj];	// calls [super setObjectValue]
	}
}

- (void) setPathComponentCells:(NSArray *) cells; { ASSIGN(_pathComponentCells, cells); _needsSizing=YES; [[self controlView] updateCell:self]; }

- (void) setPathStyle:(NSPathStyle) pathStyle;
{
	_pathStyle=pathStyle;
	_needsSizing=YES;	// resize for new style
	if(pathStyle == NSPathStyleNavigationBar)
		[self setControlSize:NSSmallControlSize];	// enforce
	[[self controlView] updateCell:self];
}

- (void) setURL:(NSURL *) url;
{
	int i;
	if (url != nil) {
		BOOL isFile=[url isFileURL];
		NSArray *pathComponents = [[url path] pathComponents]; // get Array of Path parts
		unsigned cnt = [pathComponents count];
		NSMutableArray *cells=[NSMutableArray arrayWithCapacity:cnt];
		NSString *partialURLString=@"/";
		for(i=0; i<cnt; i++)
		{ // loop over all path components and create a cell for each one
			NSPathComponentCell *cell = [[[[self class] pathComponentCellClass] alloc] init];
			NSURL *partialURL;
			partialURLString = [partialURLString stringByAppendingPathComponent:[pathComponents objectAtIndex:i]];	// add next component
			if(isFile) {
				partialURL = [NSURL fileURLWithPath:partialURLString];
			} else {
				// FIXME: this does not cover all legal cases, e.g. user&password included, empty host name etc.
				partialURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@://%@%@", [url scheme], [url host] /* FIXME: , [url port] */, partialURLString]];	// should include scheme, host etc.
			}
			[cell setTitle:[[partialURL path] lastPathComponent]];
			if (isFile && i==0) {
				[cell setTitle:[[NSFileManager defaultManager] displayNameAtPath:[pathComponents objectAtIndex:i]]];
			}
			if(isFile) 
			{ // Get the icon of the file
				NSImage *icon=[[NSWorkspace sharedWorkspace] iconForFile:partialURLString];
				if(icon)
				{
					[icon setScalesWhenResized:YES];
					if(_pathStyle == NSPathStyleNavigationBar)
						[icon setSize:NSMakeSize(14.0, 14.0)];
					else
						[icon setSize:NSMakeSize(16.0, 16.0)];
					[cell setImage:icon];
				}
			}
			[cell setURL:partialURL];
			[cells addObject:cell];
			[cell release];
			[partialURL release];
		}
		[self setPathComponentCells:cells];
		[super setObjectValue:url];	// store URL as object value
	}
}

- (NSURL *) URL; { return [self objectValue]; }

- (BOOL) trackMouse:(NSEvent *) event inRect:(NSRect) cellFrame ofView:(NSView *) controlView untilMouseUp:(BOOL) flag
{
	NSPoint point=[controlView convertPoint:[event locationInWindow] fromView:nil];
	if(![self isEnabled])
		return NO;
	if(_pathStyle == NSPathStylePopUp)
	{
		NSMenu *menu=nil;
		// build Menu
		// if[self isEditable], add separator&Choose...
		[_delegate pathCell:self willPopUpMenu:menu];
		[_controlView pathCell:self willPopUpMenu:menu];	// so that it can translate into a pathControl: willPopUpMenu:
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
	[_delegate pathCell:self willDisplayOpenPanel:openPanel];
	[_controlView pathCell:self willDisplayOpenPanel:openPanel];	// so that it can translate into a pathControl: willDisplayOpenPanel:
	if([openPanel runModalForTypes:[self allowedTypes]] == NSOKButton)
		[self setURL:[openPanel URL]];	// change
}

- (id) initWithCoder:(NSCoder *) coder;
{
	if((self = [super initWithCoder:coder]))
			{
				// FIXME: check what IB writes into NIB/XIB files
				[self setAllowedTypes:[coder decodeObjectForKey:@"allowedTypes"]];
				[self setBackgroundColor:[coder decodeObjectForKey:@"backgroundColor"]];
				[self setPathComponentCells:[coder decodeObjectForKey:@"componentCells"]];
				[self setPlaceholderAttributedString:[coder decodeObjectForKey:@"placeholderAttributedString"]];
	}
	return self;
}

@end

@implementation NSObject (NSPathCellDelegate)

- (void) pathCell:(NSPathCell *) sender willDisplayOpenPanel:(NSOpenPanel *) openPanel; { return; }
- (void) pathCell:(NSPathCell *) sender willPopUpMenu:(NSMenu *) menu; { return; }

@end
