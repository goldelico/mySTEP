//
//	AppController.m
//

#import "AppController.h"
#include <limits.h>

@implementation NSFlipImageView
- (BOOL) isFlipped;
{
	return flipped;
}
- (void) setFlipped:(BOOL) flag
{
	flipped=flag;
}
- (void) drawRect:(NSRect) rect
{
	[super drawRect:rect];
}
@end

@implementation NSAffineTransform (Description)

- (NSString *) description;
{
	NSAffineTransformStruct ts=[self transformStruct];
	return [NSString stringWithFormat:
		@"((%g %g) / (%g %g)) (%g %g))",
		ts.m11, ts.m21,
		ts.m12, ts.m22,
		ts.tX, ts.tY];		
}

@end

@implementation AppController

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication; { return YES; }

- (IBAction) printBezelStyle:(id) Sender;
{
	NSLog(@"Bezel Style = %lu", [(NSButton *) Sender bezelStyle]);
}

- (IBAction) periodic:(id) Sender;
{
	[cont setIntValue:[cont intValue]+1];
	[cont setNeedsDisplay:YES];
}

void printWindowList()
{
	NSInteger list[100];
	NSInteger n;
	int i;
	NSCountWindows(&n);
	NSWindowList(sizeof(list)/sizeof(list[0]), list);
	for(i=0; i<n; i++)
			{
				NSWindow *win=[NSApp windowWithWindowNumber:list[i]];
				NSLog(@"[%02d]: %ld %ld %@ %@", i, (long)list[i], (long)[win level], [win title], win);
			}
}

- (void) awakeFromNib
{
	NSWindow *w;
	NSLog(@"awakeFromNib");
	NSLog(@"NSNotFound=%lu %lu %08lx", NSNotFound, NSNotFound, NSNotFound);
	NSLog(@"NSApp=%@", NSApp);
	NSLog(@"Bundle=%@", [NSBundle bundleForClass:[self class]]);
#if 1
	NSLog(@"scale factor=%lf", [[[NSScreen screens] objectAtIndex:0] userSpaceScaleFactor]);
#endif
#if 1
	NSLog(@"KVOSlider %@", kvoSlider);
	NSLog(@"  class %p %@", [kvoSlider class], [kvoSlider class]);
#if 0
	NSLog(@"  isa %p %@", object_getClass(kvoSlider), object_getClass(kvoSlider));
#endif
#endif
#if 1
	[buttonTable reloadData];
	NSLog(@"buttonTable=%@", buttonTable);
	NSLog(@"buttonTable enclosingScrollView=%@", [buttonTable enclosingScrollView]);
	NSLog(@"flipped %d", [[buttonTable enclosingScrollView] isFlipped]);
	NSLog(@"buttonTable enclosingScrollView verticalScroller=%@", [[buttonTable enclosingScrollView] verticalScroller]);
	NSLog(@"flipped %d", [[[buttonTable enclosingScrollView] verticalScroller] isFlipped]);
	NSLog(@"floatValue=%lf", [[[buttonTable enclosingScrollView] verticalScroller] floatValue]);
#endif
#if 1
	NSLog(@"available Font Families=%@", [[NSFontManager sharedFontManager] availableFontFamilies]);
	NSLog(@"available Fonts=%@", [[NSFontManager sharedFontManager] availableFonts]);
	NSLog(@"font collections=%@", [[NSFontManager sharedFontManager] collectionNames]);
	// this one appears to be empty??
	NSLog(@"'All Fonts' collection=%@", [[NSFontManager sharedFontManager] fontDescriptorsInCollection:@"All Fonts"]);
	NSLog(@"'Web' collection=%@", [[NSFontManager sharedFontManager] fontDescriptorsInCollection:@"Web"]);
	NSLog(@"'Undefined' collection=%@", [[NSFontManager sharedFontManager] fontDescriptorsInCollection:@"Undefined"]);
#if 1
	{ // NSFont and NSFontDescriptor
		NSFont *f=[NSFont boldSystemFontOfSize:12];
		NSFontDescriptor *fd;
		NSLog(@"test boldSystemFontOfSize:12 = %@", f);
		NSLog(@"descriptor = %@", [f fontDescriptor]);
		NSLog(@"boundingRectForFont = %@", NSStringFromRect([f boundingRectForFont]));
		NSLog(@"numberOfGlyphs = %lu", (unsigned long)[f numberOfGlyphs]);
		NSLog(@"ascender = %f", [f ascender]);
		NSLog(@"descender = %f", [f descender]);
		NSLog(@"leading = %f", [f leading]);
		NSLog(@"lineHeight = %f", [f defaultLineHeightForFont]);
		NSLog(@"xHeight = %f", [f xHeight]);
		NSLog(@"capHeight = %f", [f capHeight]);
		NSLog(@"underlinePosition = %f", [f underlinePosition]);
		NSLog(@"underlineThickness = %f", [f underlineThickness]);
		f=[f screenFontWithRenderingMode:1];
		NSLog(@"renderingMode = %d", [f renderingMode]);
		NSLog(@"screen font = %@", f);
		NSLog(@"descriptor = %@", [f fontDescriptor]);
		f=[f printerFont];
		NSLog(@"renderingMode = %d", [f renderingMode]);
		NSLog(@"printer font = %@", f);
		NSLog(@"descriptor = %@", [f fontDescriptor]);
		fd=[NSFontDescriptor fontDescriptorWithName:@"Helvetica" size:12.0];
		NSLog(@"Helvetica 12.0 = %@", fd);
		NSLog(@"// match keys are NSFontNameAttribute, NSFontSizeAttribute");
		NSLog(@"match keys=%@", [NSSet setWithArray:[[fd fontAttributes] allKeys]]);
		NSLog(@"// matchingFontDescriptorsWithMandatoryKeys returns an array of NSFontDescriptors (with no NSFontSizeAttribute for scalable fonts!)");
		NSLog(@"// this one returns only plain Helvetica (but not helvetica bold)");
		NSLog(@"fonts1 = %@", [fd matchingFontDescriptorsWithMandatoryKeys:[NSSet setWithArray:[[fd fontAttributes] allKeys]]]);
		NSLog(@"// this one returns all Helvetica faces (but no others!) ??? is NSFontFamilyAttribute a default ???");
		NSLog(@"fonts2 = %@", [fd matchingFontDescriptorsWithMandatoryKeys:[[NSSet new] autorelease]]);	// result is array of NSFontDescriptors(!), always matches name, does not contain size property
		fd=[NSFontDescriptor fontDescriptorWithName:@"Helvetica" size:12.0];
		NSLog(@"// this one has NSFontSizeAttribute");
		NSLog(@"fonts3a = %@", fd);
		NSLog(@"// these don't have NSFontSizeAttribute! i.e. even if it is a mandatory key, a scalable font matches all sizes");
		NSLog(@"fonts3b = %@", [fd matchingFontDescriptorsWithMandatoryKeys:[NSSet setWithObjects:NSFontNameAttribute, NSFontSizeAttribute, nil]]);	// result is array of NSFontDescriptors(!), always matches name, does not contain size property
		NSLog(@"fonts3c = %@", [fd matchingFontDescriptorsWithMandatoryKeys:[NSSet setWithObjects:NSFontNameAttribute, nil]]);	// result is array of NSFontDescriptors(!), always matches name, does not contain size property
		NSLog(@"// here the fd has a NSFontSizeAttribute");
		NSLog(@"fonts4 = %@", [[NSFont fontWithDescriptor:fd size:17.0] fontDescriptor]);
		NSLog(@"// returns nil (font not found)");
		NSLog(@"non-existing font %@", [NSFont fontWithName:@"nonexistingfontname" size:10.0]);
		NSLog(@"// simply returns the descriptor (does not check for existence)");
		NSLog(@"non-existing-font descriptor %@", [NSFontDescriptor fontDescriptorWithName:@"nonexistingfontname" size:10.0]);
		NSLog(@"// returns a default font (Georgia)");
		NSLog(@"font with non-existing-font descriptor %@", [NSFont fontWithDescriptor:[NSFontDescriptor fontDescriptorWithName:@"nonexistingfontname" size:10.0] size:12.0]);
		NSLog(@"// returns a default font (Helvetica)");
		NSLog(@"userFont %@", [NSFont userFontOfSize:12.0]);
		NSLog(@"// returns a different default font (Monaco)");
		NSLog(@"userFixedPitchFont %@", [NSFont userFixedPitchFontOfSize:12.0]);
	}
#endif	
#endif
#if 0
	v=[NSMenuView alloc];
	NSLog(@"allocated");
	v=[v initWithFrame:NSMakeRect(0.0, 0.0, 100.0, 100.0)];
	[v setMenu:[NSApp mainMenu]];   // use to display the main menu
	NSLog(@"main menu attached");
	NSLog(@"view created: %@", v);
	[[win contentView] addSubview:v];
	[[win contentView] setNeedsDisplay:YES];	// and reflect change
	NSLog(@"added to %@ content View %@ - %@", win, [win contentView], [[win contentView] subviews]);
#endif
//	NSLog(@"PATH_MAX=%d", PATH_MAX);
	w=nil;
	NSLog(@"before alloc %lu, %@", (unsigned long)[w retainCount], [NSApp windows]);
	printWindowList();
	w=[NSWindow alloc];
	NSLog(@"after alloc %lu, %@", (unsigned long)[w retainCount], [NSApp windows]);
	printWindowList();
	w=[w initWithContentRect:NSMakeRect(10.0, 10.0, 50.0, 50.0) styleMask:0 backing:0 defer:NO];
	NSLog(@"after init %lu, %@", (unsigned long)[w retainCount], [NSApp windows]);
	printWindowList();
	[w orderFront:self];
	NSLog(@"after orderFront %lu, %@", (unsigned long)[w retainCount], [NSApp windows]);
	printWindowList();
	[w orderBack:self];
	NSLog(@"after orderBack %lu, %@", (unsigned long)[w retainCount], [NSApp windows]);
	printWindowList();
	[w orderOut:self];
	NSLog(@"after orderOut %lu, %@", (unsigned long)[w retainCount], [NSApp windows]);
	printWindowList();
	[w setReleasedWhenClosed:NO];
	[w close];  // might (auto)release
	NSLog(@"after close %lu, %@", (unsigned long)[w retainCount], [NSApp windows]);
	printWindowList();
	[w retain];
	NSLog(@"after retain %lu, %@", (unsigned long)[w retainCount], [NSApp windows]);
	[w release];
	NSLog(@"after release %lu, %@", (unsigned long)[w retainCount], [NSApp windows]);
	[w release];
	NSLog(@"after 2nd release %lu, %@", (unsigned long)[w retainCount], [NSApp windows]);
#if 1
	{ // check that Foundation is working properly
		NSAffineTransform *atm, *atm2;
		int i;
		atm=[NSAffineTransform transform];
		NSLog(@"unity=%@", atm);
		for(i=1; i<3; i++)
			{
			[atm translateXBy:10.0 yBy:20.0];
			NSLog(@"translated by (10,20)=%@", atm);
			[atm scaleXBy:2.0 yBy:3.0];
			NSLog(@"scaled by (2,3)=%@", atm);
			[atm rotateByDegrees:30.0];
			NSLog(@"rotated by (30deg)=%@", atm);
			}
		[atm invert];
		NSLog(@"inverted=%@", atm);
		atm2=[NSAffineTransform transform];
		[atm2 translateXBy:-10.0 yBy:-20.0];
		NSLog(@"atm2 translated by (-10,-20)=%@", atm2);
		[atm2 rotateByDegrees:60.0];
		NSLog(@"atm2 rotated by (90deg)=%@", atm2);
		[atm prependTransform:atm2];
		NSLog(@"atm2 prepended=%@", atm);
		NSLog(@"point %@ -> %@", NSStringFromPoint(NSMakePoint(20.0, 10.0)), NSStringFromPoint([atm transformPoint:NSMakePoint(20.0, 10.0)]));
		NSLog(@"size %@ -> %@", NSStringFromSize(NSMakeSize(30.0, 20.0)), NSStringFromSize([atm transformSize:NSMakeSize(30.0, 20.0)]));
		[atm appendTransform:atm2];
		NSLog(@"atm2 appended=%@", atm);
		NSLog(@"point %@ -> %@", NSStringFromPoint(NSMakePoint(20.0, 10.0)), NSStringFromPoint([atm transformPoint:NSMakePoint(20.0, 10.0)]));
		NSLog(@"size %@ -> %@", NSStringFromSize(NSMakeSize(30.0, 20.0)), NSStringFromSize([atm transformSize:NSMakeSize(30.0, 20.0)]));
	}
#endif
		{
			NSToolbar *toolBar=[[NSToolbar alloc] initWithIdentifier:@"toolbar"];
			[toolBar setDelegate:self];
			[toolBar setAllowsUserCustomization:YES];
			[toolBar setAutosavesConfiguration:YES];
			// if first initialization
			[toolBar setSizeMode:NSToolbarSizeModeSmall];
			[toolBar setDisplayMode:NSToolbarDisplayModeIconOnly];
			[toolWin setToolbar:toolBar];	// will override from user defaults if user has changed
			NSLog(@"toolbar = %@", toolBar);
			NSLog(@"toolbar config = %@", [toolBar configurationDictionary]);
			NSLog(@"toolbar visible = %@", [toolBar visibleItems]);
			NSLog(@"toolbar items = %@", [toolBar items]);
		}
#if 0
		{
			NSPathControl *npc = [[[NSPathControl alloc] initWithFrame:[pathControl frame]] autorelease];	// is not fully initialized when loading from NIB
			[npc setAutoresizingMask:[pathControl autoresizingMask]];
			[[pathControl superview] replaceSubview:pathControl with:npc];
			pathControl=npc;
			[pathControl setURL:[NSURL fileURLWithPath:NSHomeDirectory()]];
		}
#endif
	{
		NSImage *_image=[[NSImage alloc] initWithSize:NSMakeSize(256.0, 256.0)];	// write error message into a tile
		[_image setFlipped:NO];
		[_image lockFocus];
		[@"someMessage" drawInRect:[_image alignmentRect] withAttributes:nil];
		[_image unlockFocus];
		[imageDrawing setImage:_image];
		[_image release];
	}
	int i;
	for(i=1; i<100; i++)	// make a long menu that needs scrolling
		[[longMenu submenu] addItemWithTitle:[NSString stringWithFormat:@"-- %d --", i] action:@selector(doSomething:) keyEquivalent:@""];
	NSMenuItem *item=[[NSApp mainMenu] itemAtIndex:0];
	[item setImage:[NSImage imageNamed:@"1bK"]];	// set an image
}

#pragma mark Toolbar

- (id) toolbarDictEntryForKey:(NSString *) key;
{
	static NSMutableDictionary *cache;	// should be instance variable!
	if (!cache)
		cache = [[NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Toolbar" ofType:@"plist"]] retain];
	return [cache objectForKey:key];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
	return [self toolbarDictEntryForKey:@"Allowed Items"];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
	return [self toolbarDictEntryForKey:@"Default Items"];
}

- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar
      itemForItemIdentifier:(NSString *)itemIdentifier
  willBeInsertedIntoToolbar:(BOOL)flag
{ // create item - must be cached
	NSMutableDictionary *itemData = [[self toolbarDictEntryForKey:@"Items"] objectForKey:itemIdentifier];	// get dict info
	NSToolbarItem *toolbarItem = [itemData objectForKey:@"theitem"];
	if (!toolbarItem)
			{ // create a new one
				toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
#if 0
				NSLog(@"create item %@: %@", itemIdentifier, itemData);
#endif
				[itemData setObject:toolbarItem forKey:@"theitem"];	// save in toolbar dictionary
				[toolbarItem setLabel:[itemData objectForKey:@"Label"]];
				[toolbarItem setPaletteLabel:[itemData objectForKey:@"PaletteLabel"]];
				[toolbarItem setToolTip:[itemData objectForKey:@"ToolTip"]];
				[toolbarItem setTarget:self];
				
				NSImage *icon = nil;
				
				if ([itemData objectForKey:@"DynamicImage"])
						{ // try to dynamically generate the image
							SEL iconsel = NSSelectorFromString([itemData objectForKey:@"DynamicImage"]);
							if ([self respondsToSelector:iconsel])
									{
#if 0
										NSLog(@"calling dynamic image method: %@", [itemData objectForKey:@"DynamicImage"]);
#endif
										icon = [self performSelector:iconsel];
									}
							else
								NSLog(@"selector %@ not found.", [itemData objectForKey:@"DynamicImage"]);
						}
				
				if (!icon)	// load (default) image
					icon = [NSImage imageNamed:[itemData objectForKey:@"Image"]];
				if (icon)
					[toolbarItem setImage:icon];
				NSString *action = [itemData objectForKey:@"Action"];
				[toolbarItem setAction:NSSelectorFromString(action)];
				NSView *view = nil;	// custom view
				if ([itemData objectForKey:@"NibOutlet"])
						{ // custom sub-view has been loaded from NIB
							view = [self valueForKey:[itemData objectForKey:@"NibOutlet"]];
#if 0
							NSLog(@"got view from outlet %@: %@", [itemData objectForKey:@"NibOutlet"], view);
#endif
							[view setFrameOrigin:NSZeroPoint];	// move to location where we need it
						}
				else if ([itemData objectForKey:@"Class"] && [itemData objectForKey:@"Size"])
						{ // create a custom sub-view
#if 0
							NSLog(@"create view of class: %@", [itemData objectForKey:@"Class"]);
#endif
							view = [[[NSClassFromString([itemData objectForKey:@"Class"]) alloc] initWithFrame:(NSRect){ NSZeroPoint, NSSizeFromString([itemData objectForKey:@"Size"]) }] autorelease];
						}
				if (view)
						{
							SEL init;
							init = NSSelectorFromString([itemData objectForKey:@"Initialize"]);
							if (init)
									{ // give application a chance to modify a new view
										if ([self respondsToSelector:init])
												{
#if 0
													NSLog(@"calling initializer method: %@", [itemData objectForKey:@"Initialize"]);
#endif
													[self performSelector:init withObject:view];
												}
										else
												{
													NSLog(@"selector %@ not found.", [itemData objectForKey:@"Initialize"]);
												}
									}
							[toolbarItem setView:view];
							if (action && [view isKindOfClass:[NSControl class]]) // attach an action to new view as well
								[(NSControl *) view setAction:NSSelectorFromString(action)];
						}
				
				if ([itemData objectForKey:@"MinWidth"])
					[toolbarItem setMinSize:NSMakeSize([[itemData objectForKey:@"MinWidth"] doubleValue], NSHeight([view frame]))];
				else if (view)  // if not overridden, get from view
					[toolbarItem setMinSize:[view frame].size];
				if ([itemData objectForKey:@"MaxWidth"])
					[toolbarItem setMaxSize:NSMakeSize([[itemData objectForKey:@"MaxWidth"] doubleValue], NSHeight([view frame]))];
				else if (view) // if not overridden, get from view
					[toolbarItem setMaxSize:[view frame].size];
				
				if ([itemData objectForKey:@"Menu"])
						{ // attach a custom menu 
							// FIXME: should load from NIB file as well
							NSMenu *submenu = [[[NSMenu alloc] init] autorelease];
							NSMenuItem *submenuItem = [[[NSMenuItem alloc] initWithTitle: @"Search Panel"
																				  action: @selector(searchUsingSearchPanel:)
																		   keyEquivalent: @""] autorelease];
							NSMenuItem *menuFormRep = [[[NSMenuItem alloc] init] autorelease];
							[submenu addItem:submenuItem];
							[submenuItem setTarget:self];
							[menuFormRep setSubmenu:submenu];
							[menuFormRep setTitle:[toolbarItem label]];
							[toolbarItem setMenuFormRepresentation:menuFormRep];
						}
			}
	return toolbarItem;
}

- (BOOL) validateToolbarItem:(NSToolbarItem *) item
{
	//	return [self validateAction:NSStringFromSelector([item action])];	
	return YES;
}

- (IBAction) singleClick:(id) Sender;
{
	NSLog(@"doSomething: %@", Sender);
}

- (IBAction) doSomething:(id) Sender;
{
	NSLog(@"doSomething: %@", Sender);
	[v setHorizontal:![v isHorizontal]];
//	[tf setStringValue:[NSString stringWithFormat:@"%@%@\n", [tf stringValue], [Sender title]]];
	[v dataWithPDFInsideRect:[v bounds]];
}

- (IBAction) saveDocumentAs:(id) Sender;
{
	NSSavePanel *o=[NSSavePanel savePanel];
	[o runModal];
}

- (IBAction) openDocument:(id) Sender;
{
	NSOpenPanel *o=[NSOpenPanel openPanel];
	[o runModal];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
	if(aTableView == buttonTable)
		return 8*(NSRoundedDisclosureBezelStyle+5);
	return 100;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *ident=[aTableColumn identifier];
#if 0
	NSLog(@"ident=%@", ident);
#endif
	if(aTableView == buttonTable)
		{
		if([ident isEqualToString:@"bezel"])
			return [NSString stringWithFormat:@"%ld", rowIndex/8];
		if([ident isEqualToString:@"type"])
			return [NSString stringWithFormat:@"%ld", rowIndex%8];
		return @"";
		}
	else
		{
		if([ident isEqualToString:@"image"])
			return [NSImage imageNamed:@"1bK Copy.png"];
		if([ident isEqualToString:@"icon"])
			return [NSImage imageNamed:@"1bK Copy.png"];
		}
	return [NSString stringWithFormat:@"%ld: %@", (long)rowIndex, ident];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *ident=[aTableColumn identifier];
	if(aTableView == buttonTable)
		{
		if([ident isEqualToString:@"button"])
			{
			[(NSButtonCell *) aCell setBordered:YES];
			[(NSButtonCell *) aCell setButtonType:rowIndex%8];
			[(NSButtonCell *) aCell setBezelStyle:rowIndex/8];
			[(NSButtonCell *) aCell setTitle:@"Button"];
			}
		if([ident isEqualToString:@"buttonh"])
			{
			[(NSButtonCell *) aCell setBordered:YES];
			[(NSButtonCell *) aCell setButtonType:rowIndex%8];
			[(NSButtonCell *) aCell setBezelStyle:rowIndex/8];
			[(NSButtonCell *) aCell setTitle:@"Button"];
			[(NSButtonCell *) aCell setHighlighted:YES];
			}
		}
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id) val forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSLog(@"setObjectValue [%ld, %@] := %@", (long)rowIndex, [aTableColumn identifier], val);
}

- (IBAction) horizClipView:(id) Sender;
{
	NSRect bounds=[clipView bounds];
	bounds.origin.x=[Sender floatValue];
	[clipView setBounds:bounds];
	[clipView setNeedsDisplay:YES];
}

- (IBAction) vertClipView:(id) Sender;
{
	NSRect bounds=[clipView bounds];
	bounds.origin.y=[Sender floatValue];
#if 0
	[clipView setBackgroundColor:[NSColor yellowColor]];
	[clipView setDrawsBackground:YES];
#endif
	[clipView setBounds:bounds];
	[clipView setNeedsDisplay:YES];
}

- (IBAction) scroll:(id) sender;
{
#if 1
	NSLog(@"self flipped=%d", [clipView isFlipped]);
	NSLog(@"doc  flipped=%d", [[clipView documentView] isFlipped]);
#endif	
	[clipView scrollRect:NSMakeRect(0, 0, 100, 100) by:NSMakeSize(10, 30)];
}

- (IBAction) rotate:(id) sender;
{
	NSInteger tag=[sender tag];
	switch(tag)
	{
		case -1:
			[rotation setFlipped:[sender state] == NSOnState];
			break;
		case 0:
			[rotation setFrameRotation:[sender floatValue]];
			break;
		case 1:
			[rotation setBoundsRotation:[sender floatValue]];
			break;
		case 2: {
			NSRect r=[rotation frame];
			r.size.width *= ([sender floatValue]-90);
			r.size.height *= ([sender floatValue]-90);
			[rotation setBoundsSize:r.size];
			break;
		}
	}
	[rotation setNeedsDisplay:YES];
}

- (NSInteger) alignment;
{
	return [[alignmentButton selectedItem] tag];
}

- (NSInteger) contentToShow;
{
	return [[contentToShow selectedItem] tag];
}

- (BOOL) isFlipped;
{
	return [flip state] == NSOnState;
}

- (IBAction) changed:(id) sender
{
	[alignmentView setNeedsDisplay:YES];
}

@end

