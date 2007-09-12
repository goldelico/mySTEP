/*
 NSPanel.m
 
 Panel window subclass, related functions and standard system
 panels:  NSSavePanel, NSOpenPanel, NSFontPanel, NSColorPanel
 
 Copyright (C) 1996 Free Software Foundation, Inc.
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

#import <Foundation/NSBundle.h>
#import <Foundation/NSException.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSCoder.h>

#import <AppKit/AppKit.h>
#import "NSAppKitPrivate.h"

#define ALERT_PANEL_WIDTH	362

//*****************************************************************************
//
// 		NSPanel
//
//*****************************************************************************

@implementation	NSPanel

+ (void) _defaultButtonAction:(id)sender
{
	[NSApp stopModalWithCode:NSAlertDefaultReturn];
}

+ (void) _alternateButtonAction:(id)sender
{
	[NSApp stopModalWithCode:NSAlertAlternateReturn];
}

+ (void) _otherButtonAction:(id)sender
{ 
	[NSApp stopModalWithCode:NSAlertOtherReturn];
}

- (id) init
{
	return [self initWithContentRect: NSZeroRect
						   styleMask: (NSTitledWindowMask | NSClosableWindowMask)
							 backing: NSBackingStoreBuffered
							   defer: NO
							  screen: nil];
}

- (id) initWithContentRect:(NSRect)contRect
				 styleMask:(unsigned int)aStyle
				   backing:(NSBackingStoreType)bufferingType
					 defer:(BOOL)flag
					screen:aScreen
{
#if 0
	NSLog(@"init NSPanel with styleMask %08x", aStyle);
#endif
	self=[super initWithContentRect:contRect
						  styleMask:aStyle
							backing:bufferingType
							  defer:flag
							 screen:aScreen];
	if(self)
		{
		_w.releasedWhenClosed = NO;	// panels need explicit release
		_w.hidesOnDeactivate = YES;
		[self setTitle: @""];
		}
	NSDebugLog(@"NSPanel end of init\n");
	
	return self;
}

#if 0	// should be done by NSButton keyEquivalent for close button in decoration!?
		// no, should be by input manager mapping of NSResponder

- (void) keyDown:(NSEvent*)event
{ // If we receive an escape, close.
	if ([@"\e" isEqualToString: [event charactersIgnoringModifiers]] &&
		([self styleMask] & NSClosableWindowMask) == NSClosableWindowMask)
		[self close];
	else
		[super keyDown: event];
}
#endif

// Panel Behavior
- (void) setFloatingPanel:(BOOL)flag		{ [self setLevel:flag?NSFloatingWindowLevel:NSNormalWindowLevel]; }
- (void) setWorksWhenModal:(BOOL)flag		{ _worksWhenModal = flag; }
- (BOOL) isFloatingPanel					{ return [self level] == NSFloatingWindowLevel; }
- (BOOL) worksWhenModal						{ return _worksWhenModal; }
- (BOOL) becomesKeyOnlyIfNeeded				{ return _becomesKeyOnlyIfNeeded; }

- (BOOL) canBecomeMainWindow					
{ 
	return NO; 
}

- (void) setBecomesKeyOnlyIfNeeded:(BOOL)flag	
{ 
	_becomesKeyOnlyIfNeeded = flag;
}

// NSCoding protocol

- (void) encodeWithCoder:(NSCoder *) aCoder		{ [super encodeWithCoder:aCoder]; }
- (id) initWithCoder:(NSCoder *) aDecoder		{ return [super initWithCoder:aDecoder]; }

@end /* NSPanel */

	//*****************************************************************************
	//
	// 		Alert panel functions
	//
	//*****************************************************************************

	static id _NSGetAlertPanel(NSString *icon,
							   NSString *title,
							   NSString *msg,
							   NSString *defaultButton,
							   NSString *alternateButton,
							   NSString *otherButton,
							   va_list ap)
{ // create panel
		NSString *message;
		NSPanel *p;
		NSView *cv;
		NSButton *d=nil, *a=nil, *o=nil;
		NSTextField *m, *t;
		NSRect rect = {{0,95},{240,2}};
		unsigned bs = 8;								// Inter-button space
		unsigned bh = 24;								// Button height
		unsigned bw = 80;								// Button width
		id v;
		NSFont *bfont;			// button font
		NSDictionary *attr;		// attributes
		
#if 0
		NSLog(@"_NSGetAlertPanel message=%@", msg);
#endif
		message = [[[NSString alloc] initWithFormat: msg arguments: ap] autorelease];
#if 0
		NSLog(@"  => %@", message);
#endif
		
		p = [[NSPanel alloc] initWithContentRect:(NSRect){{0,0},{rect.size.width,162}}
									   styleMask: NSTitledWindowMask
										 backing: NSBackingStoreRetained
										   defer: YES
										  screen: nil];
#if 0
		NSLog(@"panel=%@", p);
#endif
		cv = [p contentView];
#if 0		
		v = [[NSBox alloc] initWithFrame: rect];		// create middle groove
		[v setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
		[v setTitlePosition: NSNoTitle];
		[v setBorderType: NSGrooveBorder];
		[cv addSubview: v];
		[v release];
#endif
		// create message field
		m = [[NSTextField alloc] initWithFrame: (NSRect){{68,46},{rect.size.width-68-4,70}}];
		[m setEditable: NO];
		[m setSelectable: NO];
		[m setBordered: NO];
		[m setDrawsBackground: NO];
		[m setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin | NSViewHeightSizable];
		[m setAlignment: NSLeftTextAlignment];
		[m setStringValue: (message ? message : @"")];
		[m setFont: [NSFont systemFontOfSize: 9.0]];
		[cv addSubview: m];
		[m release];
		// create title field
		t = [[NSTextField alloc] initWithFrame: (NSRect){{68,121},{rect.size.width-68-4,21}}];
		[t setAutoresizingMask: NSViewWidthSizable| NSViewMinYMargin];
		[t setEditable: NO];
		[t setSelectable: NO];
		[t setBordered: NO];
		[t setDrawsBackground: NO];
		// should make attributed string that is boldface
		[t setStringValue: (title ? title : @"Alert")];
		[t setFont: [NSFont boldSystemFontOfSize: 12.0]];
		[cv addSubview: t];
		[t release];
		// create icon view
		v = [[NSImageView alloc] initWithFrame: (NSRect){{10,105},{48,48}}];
		
		[v setImage:[NSImage imageNamed: NSApplicationIcon]];			// use icon!
		
		[cv addSubview: v];
		[v release];
		
		rect = (NSRect){{240-4, bs},{bw, bh}};
		if(!(bfont=[NSFont systemFontOfSize: 10.0]))
			NSLog(@"NSPanel: can't allocate font");
		attr=[NSDictionary dictionaryWithObjectsAndKeys:bfont, NSFontAttributeName, nil];
		
		if (defaultButton == nil)
			defaultButton = @"OK";	// enforce default button
		
		if(defaultButton)
			{ // default goes to the right
			if([defaultButton length] == 0)
				defaultButton=@"OK";	// use default for default button :-)
			rect.size.width=[defaultButton sizeWithAttributes:attr].width;	// text width
			if(rect.size.width < bw)
				rect.size.width=bw;
			rect.origin.x-=rect.size.width;
			d = [[NSButton alloc] initWithFrame: rect];
			[d setFont:bfont];
			[d setButtonType: NSMomentaryPushInButton];
			[d setBordered: YES];
			[d setBezelStyle: NSRoundedBezelStyle];
			[d setTarget: [NSPanel class]];
			[d setAction: @selector(_defaultButtonAction:)];
			[d setTitle: defaultButton];
			[d setKeyEquivalent: @"\n"];
			[p setInitialFirstResponder: d];
			[cv addSubview: d];
			[d release];
			rect.origin.x-=bs;	// button spacing
			}
		
		if(otherButton)
			{ // other button goes to the middle
			rect.size.width=[otherButton sizeWithAttributes:attr].width;	// text width
			if(rect.size.width < bw)
				rect.size.width=bw;
			if(otherButton)
				rect.origin.x-=rect.size.width;
			o = [[NSButton alloc] initWithFrame: rect];
			[o setFont:bfont];
			[o setButtonType: NSMomentaryPushInButton];
			[o setBordered: YES];
			[o setBezelStyle: NSRoundedBezelStyle];
			[o setTitle: otherButton];
			//			[d setKeyEquivalent: @"\??"];
			[o setTarget: [NSPanel class]];
			[o setAction: @selector(_otherButtonAction:)];
			[cv addSubview: o];
			[o release];
			rect.origin.x-=bs;	// button spacing
			}
		
		if(alternateButton)
			{ // alternate goes to the left
			rect.origin.x=4;
			rect.size.width=[alternateButton sizeWithAttributes:attr].width;	// text width
			if(rect.size.width < bw)
				rect.size.width=bw;
			a = [[NSButton alloc] initWithFrame: rect];
			[a setFont:bfont];
			[a setButtonType: NSMomentaryPushInButton];
			[a setBordered: YES];
			[a setBezelStyle: NSRoundedBezelStyle];
			[a setTitle: alternateButton];
			[d setKeyEquivalent: @"\e"];
			[a setTarget: [NSPanel class]];
			[a setAction: @selector(_alternateButtonAction:)];
			[cv addSubview: a];
			[a release];
			}
		// if there is a (localized) "Don't Save" alt/other buton: assign ctrl-D as keyEquivalent
		
#if OLD		
		{
			if (__alertPanel == nil)
				{
				_message = m;
				_title = t;
				_default = d;
				_alternate = a;
				_other = o;
				}	}
		else												// reuse existing alert
			{												// panel
			cv = [(p = __alertPanel) contentView];
			
			if (msg)
				{
				[_message setStringValue: msg];
				if ([_message superview] == nil)
					[cv addSubview: _message];
				}
			else
				if ([_message superview] != nil)
					[[_message retain] removeFromSuperview];
			
			[_title setStringValue: (title ? title : @"Alert")];
			
			if (defaultButton)
				{
				[(d = _default) setTitle: defaultButton];
				if ([_default superview] == nil)
					[cv addSubview: _default];
				[__alertPanel makeFirstResponder: _default];
				}
			else
				if ([_default superview] != nil)
					[[_default retain] removeFromSuperview];
			
			if (alternateButton)
				{
				[(a = _alternate) setTitle: alternateButton];
				if ([_alternate superview] == nil)
					[cv addSubview: _alternate];
				}
			else
				if ([_alternate superview] != nil)
					[[_alternate retain] removeFromSuperview];
			
			if (otherButton)
				{
				[(o = _other) setTitle: otherButton];
				if ([_other superview] == nil)
					[cv addSubview: _other];
				}
			else
				if ([_other superview] != nil)
					[[_other retain] removeFromSuperview];
			}
#if 0	// reuse
		if (defaultButton)
			{
			numButtons++;
			maxWidth = [[d cell] cellSize].width;
			}
		if (alternateButton)
			{
			numButtons++;
			maxWidth = MAX([[a cell] cellSize].width, maxWidth);
			}
		if (otherButton)
			{
			numButtons++;
			maxWidth = MAX([[o cell] cellSize].width, maxWidth);
			}
		
		if (numButtons)
			{
			NSRect rect = [d frame];
			NSRect frame = [p frame];
			float maxButtonWidthInFrame = ((NSWidth(frame) - 8) / numButtons) - 8;
			BOOL shouldAdjustButtonWidth = NO;
			
			if(maxWidth > maxButtonWidthInFrame)			// widen the panel to
				{											// accomadate buttons 
				float newWidth = MIN(((maxWidth + 8) * numButtons) + 8,
									 [p maxSize].width);
				
				NSWidth(frame) = newWidth;
				[p setFrame:frame display:NO];
				shouldAdjustButtonWidth = YES;
				}
			else											// reset panel to defs
				if(maxButtonWidthInFrame > (maxWidth + 8)
				   && NSWidth(frame) != ALERT_PANEL_WIDTH)
					{	
					NSWidth(frame) = ALERT_PANEL_WIDTH;
					[p setFrame:frame display:NO];
					shouldAdjustButtonWidth = YES;
					}
			
			if(shouldAdjustButtonWidth)
				{
				NSWidth(rect) = maxWidth;
				NSMinX(rect) = NSWidth(frame) - (8 + NSWidth(rect));
				if (defaultButton)
					{
					[d setFrame:rect];
					NSMinX(rect) -= (8 + NSWidth(rect));
					}
				if (alternateButton)
					{
					[a setFrame:rect];
					NSMinX(rect) -= (8 + NSWidth(rect));
					}
				if (otherButton)
					[o setFrame:rect];
				}	}
#endif
#endif OLD
#if 1
		NSLog(@"panel=%@", p);
#endif
		return p;
}

id NSGetAlertPanel(NSString *title,
				   NSString *msg,
				   NSString *defaultButton,
				   NSString *alternateButton,
				   NSString *otherButton, ...)
{
	NSPanel *p;
	va_list	ap;
	va_start (ap, otherButton);
	p=_NSGetAlertPanel(@"Alert",title,msg,defaultButton,alternateButton,otherButton,ap);
	va_end (ap);
	return p;
}

id NSGetCriticalAlertPanel(NSString *title,
						   NSString *msg,
						   NSString *defaultButton,
						   NSString *alternateButton,
						   NSString *otherButton, ...)
{
	NSPanel *p;
	va_list	ap;
	va_start (ap, otherButton);
	p=_NSGetAlertPanel(@"CriticalAlert",title,msg,defaultButton,alternateButton,otherButton,ap);
	va_end (ap);
	return p;
}

id NSGetInformationalAlertPanel(NSString *title,
								NSString *msg,
								NSString *defaultButton,
								NSString *alternateButton,
								NSString *otherButton, ...)
{
	NSPanel *p;
	va_list	ap;
	va_start (ap, otherButton);
	p=_NSGetAlertPanel(@"InformationalAlert",title,msg,defaultButton,alternateButton,otherButton,ap);
	va_end (ap);
	return p;
}

void
NSReleaseAlertPanel(id alertPanel)
{
	[alertPanel orderOut: nil];	// don't close but simply make invisible
	//	if (alertPanel != __alertPanel)
	// CHECKME: this should be the last reference and close the panel
	[alertPanel release];	// it wasn't the shared alert panel
							//	else
							//		__alertPanelIsActive = NO;
}

static int _NSRunPanel(NSPanel *p)
{ // run any panel
	int r = NSAlertErrorReturn;	// default
	[p center];
	//	[[p contentView] display];	// required?
	r=[NSApp runModalForWindow: p];
	NSReleaseAlertPanel(p);	
	return r;
}

int
NSRunAlertPanel(NSString *title,
				NSString *msg,
				NSString *defaultButton,
				NSString *alternateButton,
				NSString *otherButton, ...)
{
	va_list	ap;
	NSPanel *p;	
	
	va_start (ap, otherButton);
	p=_NSGetAlertPanel(@"Alert",title,msg,defaultButton,alternateButton,otherButton,ap);
	va_end (ap);
	
	return _NSRunPanel(p);
}

int
NSRunCriticalAlertPanel(NSString *title,
						NSString *msg,
						NSString *defaultButton,
						NSString *alternateButton,
						NSString *otherButton, ...)
{
	va_list	ap;
	NSPanel *p;	
	
	va_start (ap, otherButton);
	p=_NSGetAlertPanel(@"Critical",title,msg,defaultButton,alternateButton,otherButton,ap);
	va_end (ap);
	
	return _NSRunPanel(p);
}

int
NSRunInformationalAlertPanel(NSString *title,
							 NSString *msg,
							 NSString *defaultButton,
							 NSString *alternateButton,
							 NSString *otherButton, ...)
{
	va_list	ap;
	NSPanel *p;	
	
	va_start (ap, otherButton);
	p=_NSGetAlertPanel(@"Informational",title,msg,defaultButton,alternateButton,otherButton,ap);
	va_end (ap);
	
	return _NSRunPanel(p);
}

//*****************************************************************************
//
// 		NSSavePanel 
//
//*****************************************************************************

@implementation NSSavePanel

static NSSavePanel *__savePanel;

- (void) awakeFromNib;
{
#if 1
	NSLog(@"NSSavePanel - awake from NIB");
#endif
	includeNewFolderButton = YES;
	[self setCanCreateDirectories:YES];
	[self setDirectory:@"/"];
	[self setPrompt:@"Save"];
	[self setTitle:@"Save"];
	[self setNameFieldLabel:@"Save As:"];
	__savePanel=self;
}

+ (NSSavePanel *) savePanel
{ // load the save panel from the NIB file
#if OLD
	if(!__savePanel)
		__savePanel=[self new];	// alloc and init
	return __savePanel;
#endif
	if (!__savePanel)
		{
		[NSKeyedUnarchiver setClass:nil forClassName:@"NSSavePanel"];	// just be sure: reset mapping
		if(![NSBundle loadNibNamed:@"SavePanel" owner:NSApp])	// looks for SavePanel.nib in ressources of NSApp's bundle
			[NSException raise: NSInternalInconsistencyException format: @"Unable to open save panel model file."];
		}
	[__savePanel center];
	return __savePanel;
}

+ (id) alloc;
{
	return __savePanel ? __savePanel : (__savePanel=(NSSavePanel *) NSAllocateObject(self, 0, NSDefaultMallocZone())); 
}

- (void) dealloc;
{
	[_accessoryView release];
	[super dealloc];
}

#if OLD
- (id) init
{
	self=[super init];
	if(self)
		{
		if(!__loading)
			{ // not loading from NIB file
			__loading=YES;	// avoid recursion
			__unarchivedPanel=nil;
			[NSUnarchiver decodeClassName:@"GSSavePanel" 
							  asClassName:NSStringFromClass([self class])];	// unarchive as same class as the self object
			if(![NSBundle loadNibNamed:@"SavePanel" owner:NSApp] || !__unarchivedPanel)	// make the application the file owner (ignored)
				[NSException raise:NSInternalInconsistencyException 
							format:@"Cannot open save panel model file."];
			[self release];
			self=__unarchivedPanel;	// replace by unarchived panel
			treatsFilePackagesAsDirectories = NO;
			includeNewFolderButton = YES;
			allowsOtherFileTypes = NO;
			[self setCanCreateDirectories:YES];
			[self setDirectory:@"/"];
			[self setPrompt:@"Save"];
			[self setTitle:@"Save"];
			[self setNameFieldLabel:@"Save As:"];
			}
		else
			{ // we are the object fetched from the NIB file
			  // CHECKME: does this really happen?
			  // does unarchiving call init?
			NSLog(@"NSSavePanel -init should not be called");
			}
		}
	return self;
}
#endif

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSDragPboard];
	NSString *Path = [pb stringForType:NSFilenamesPboardType];
	
	NSLog (@"performDragOperation Path: '%@'\n", Path);
	
	if (![Path isEqualToString:[[browser path] lastPathComponent]])
		{
		if (![browser setPath:Path])
			{
			NSString *a = [[NSProcessInfo processInfo] processName];
			
			NSRunAlertPanel(a,@"Invalid path: '%@'",@"Continue",nil,nil, Path);
			
			return NO;
			}
		else
			{
			[self endEditingFor:nil];
			[self _setFilename:Path];
			}	
		}
	
	return YES;
}

- (unsigned int) draggingUpdated:(id <NSDraggingInfo>)sender
{
	return NSDragOperationGeneric;
}

- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	NSLog(@"NSSavePanel prepareForDragOperation\n");
	return YES;
}

- (unsigned int) draggingEntered:(id <NSDraggingInfo>)sender
{
	NSLog(@"NSSavePanel draggingEntered\n");
	return NSDragOperationGeneric;
}

- (NSView *) accessoryView				{ return _accessoryView; }
- (void) setAccessoryView:(NSView *)aView	{ ASSIGN(_accessoryView, aView); }		// rearrange layout

- (void) validateVisibleColumns			{ NIMP; }
- (void) selectText:(id)sender			{ [fileName selectText:nil]; }	// deprecated in 10.3 - but used internally

- (BOOL) allowsOtherFileTypes; { return allowsOtherFileTypes; }
- (BOOL) canSelectHiddenExtension; { return canSelectHiddenExtension; }
- (NSString *) title					{ return [super title]; }		// ditto
- (NSString *) prompt					{ return [okButton title]; }
- (NSString *) nameFieldLabel			{ return @"Save As:"; }
- (NSString *) message					{ return @""; }
- (BOOL) treatsFilePackagesAsDirectories { return treatsFilePackagesAsDirectories; }
- (BOOL) canCreateDirectories			{ return [self _includeNewFolderButton]; }

- (void) setAllowsOtherFileTypes:(BOOL) flag; { allowsOtherFileTypes=flag; }
- (void) setCanSelectHiddenExtension:(BOOL) flag; { canSelectHiddenExtension=flag; }
- (void) setTitle:(NSString *)title		{ [super setTitle:title]; }		// use Panel's title
- (void) setPrompt:(NSString *)prompt	{ [okButton setTitle:prompt]; }
- (void) setNameFieldLabel:(NSString *)label { }
- (void) setMessage:(NSString *)message { }
- (void) setTreatsFilePackagesAsDirectories:(BOOL)flag { treatsFilePackagesAsDirectories = flag; }
- (void) setCanCreateDirectories:(BOOL)flag { [self _setIncludeNewFolderButton:flag]; }

- (NSArray *) allowedFileTypes;			{ return requiredTypes; }
- (void) setAllowedFileTypes:(NSArray *)types; { ASSIGN(requiredTypes, types); }

- (NSString *) requiredFileType
{
	if(!requiredTypes || ![requiredTypes count])
		return nil;
	return [requiredTypes objectAtIndex:0];
}

- (void) setRequiredFileType:(NSString *)type
{
	ASSIGN(requiredTypes, type?[NSArray arrayWithObject:type]:nil);
}

- (void) setDirectory:(NSString *)path
{
	NSString *standardizedPath = [path stringByStandardizingPath];
#if 1
	NSLog(@"NSSavePanel setDirectory: %@", standardizedPath);
#endif
	if(standardizedPath && [browser setPath:standardizedPath])
		ASSIGN(lastValidPath, path);
#if 1
	NSLog(@"  -> path: %@ directory: %@", [browser path], [self directory]);
#endif
}

- (int) runModalForDirectory:(NSString *)path 				// Run NSSavePanel
						file:(NSString *)name
{	
	int	ret;
	static BOOL registered = NO;
	
	if (!registered)
		{
		registered = YES;
		[[self contentView] registerForDraggedTypes:nil];
		}
	
	[self setDirectory:path];
	[browser setPath:[[self directory] stringByAppendingPathComponent:name]];
	[browser loadColumnZero];
	
	[self _setFilename:name];
	
	// modify other UI things like new folder button
	
	//	[self display];
	[self makeKeyAndOrderFront:self];
    ret = [NSApp runModalForWindow:self];
    
#if 0
    // FIXME: replace warning
    if ([self class] == [NSSavePanel class]
		&& [[browser selectedCell] isLeaf] && ret == NSOKButton)
		if (NSRunAlertPanel(@"Save", @"File %@ in %@ exists. Replace it?", 
							@"Cancel", nil,
							[form stringValue],
							[self directory]) == NSAlertAlternateReturn)
			return NSCancelButton;
#endif
#if 1
	NSLog(@"r=%d selected url=%@", ret, [self URL]);
#endif
	
    return ret;
}

- (int) runModal
{
	return [self runModalForDirectory:[self directory] file:@""];
}

- (NSString *) directory
{	
	NSString *path = [browser path];
	
	if([[browser selectedCell] isLeaf])		// remove file component of path
		path = [path stringByDeletingLastPathComponent];	
	
	return (![path length]) ? lastValidPath : path;
}

- (NSString *) filename
{	
	NSString *r = [[self directory] stringByAppendingPathComponent:[fileName stringValue]];
	NSString *rf = [self requiredFileType];
	// FIXME: we should go through list and append first one only if there is no match
	if (rf && ![[r pathExtension] isEqualToString:rf])
		r = [r stringByAppendingPathExtension:rf];	// append/enforce
	return [r stringByExpandingTildeInPath];
}

- (NSURL *) URL; { return [NSURL fileURLWithPath:[self filename]]; }

	// Target / Action 

- (void) ok:(id)sender
{ 
	NSString *f = [fileName stringValue];
	f=[f stringByExpandingTildeInPath];			// if there is a tilde
	if (![f isEqualToString:[[browser path] lastPathComponent]] && [f isAbsolutePath])
		{ // user has typed some new absolute path
		if (![browser setPath:[fileName stringValue]])
			{
			NSString *a = [[NSProcessInfo processInfo] processName];
			// what should we do here? Ignore?
			NSRunAlertPanel(a,@"Invalid path: '%@'",@"Continue",nil,nil,f);
			return;
			}		
		}
	if(_delegate
	   && [_delegate respondsToSelector:@selector(panel:isValidFilename:)]
	   && ![_delegate panel:sender isValidFilename:[self filename]])
		return;
	
	[NSApp stopModalWithCode:NSOKButton];
	[self orderOut:self];
}

- (void) cancel:(id)sender
{	
	[NSApp stopModalWithCode:NSCancelButton];
	[self orderOut:self];
}

// private methods

- (BOOL) _isAllowedFile:(NSString *) path;
{
	return allowsOtherFileTypes || [requiredTypes containsObject:[path pathExtension]];
}

- (void) _setFilename:(NSString *) name;
{
	[fileName setStringValue:name];
	[fileName selectText:nil];
	// should we also check for directories?
	[okButton setEnabled:[name length] != 0 && [self _isAllowedFile:name]];
}

- (void) _setIncludeNewFolderButton:(BOOL) flag;
{
	includeNewFolderButton=flag;
	[newFolderButton setHidden:!flag];
	// rearrange layout
}

- (BOOL) _includeNewFolderButton; { return includeNewFolderButton; }

- (IBAction) _home:(id)sender;
{
	NSLog(@"home...");
	[self setDirectory:NSHomeDirectory()];
	[browser loadColumnZero];
}

- (IBAction) _mount:(id)sender;	// "disk button"
{
	NSLog(@"mount...");
	[[NSWorkspace sharedWorkspace] mountNewRemovableMedia];
	[self setDirectory:@"/Volumes"];
	[browser loadColumnZero];
}

- (IBAction) _unmount:(id)sender;
{
	NSLog(@"unmount...");
	// check if we are within /Volumes?
	[[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath:[browser path]];
	//	[browser reloadData];
}

- (IBAction) _newFolder:(id)sender;
{
	NSLog(@"new folder...");
}

- (IBAction) _search:(id)sender;
{
	NSLog(@"search...");
}

- (IBAction) _click:(id)sender;
{
	NSLog(@"click...");
}

- (void) browser:(NSBrowser *) sender 						// browser delegate
		 createRowsForColumn:(int) column
		inMatrix:(NSMatrix *) matrix
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *ptc = [sender pathToColumn: column];
	NSArray *f = [fm directoryContentsAtPath: ptc];
	int i, count;
	NSMutableArray *files = [NSMutableArray arrayWithCapacity:[f count]];
	NSArray *sortedFiles;
	NSEnumerator *e=[f objectEnumerator];
	NSString *file;
	while((file=[e nextObject]))
		{
		if([file hasPrefix:@"."])
			continue;	// skip
		[files addObject:file];
		}
	sortedFiles=[files sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];	// sort alphabetically
	count = [sortedFiles count];
#if 0	
    NSLog(@"createRowsForColumn");
#endif
	[matrix renewRows:count columns:1];				// create necessary cells
	[matrix sizeToCells];	
	
	if (count == 0)
		return;
	
    for (i = 0; i < count; ++i) 
		{
		id cell = [matrix cellAtRow: i column: 0];
		BOOL is_dir = NO;
		NSString *filename=[sortedFiles objectAtIndex: i];
		NSString *path=[NSString stringWithFormat:@"%@/%@", ptc, filename];
		[cell setStringValue:filename];
		[fm fileExistsAtPath:path isDirectory: &is_dir];
		[cell setEnabled:(is_dir || [self _isAllowedFile:filename])]; // disable cell if file extension is not allowed
																	  // FIXME: handle 
		[cell setLeaf: (!(is_dir) || (!treatsFilePackagesAsDirectories && [[NSWorkspace sharedWorkspace] isFilePackageAtPath:path]))];
		}
}

#if 0
- (void) browser:(NSBrowser*)sender 
 willDisplayCell:(id)cell
		   atRow:(int)row
		  column:(int)column
{
	// here we could change the cell
#if 0
    NSLog(@"willDisplayCell");
#endif
}
#endif

- (BOOL) browser:(NSBrowser *)sender 
		 selectCellWithString:(NSString *)title
		inColumn:(int)column
{
	NSString *p = [sender pathToColumn: column];
	NSMutableString *s = [[[NSMutableString alloc] initWithString:p] autorelease];
#if 1
    NSLog(@"-browser:selectCellWithString {%@}", title);
#endif
	[self _setFilename:title];	// what happens on clicking a directory with appropriate extension?
    if (column > 0)
		[s appendString: @"/"];
    [s appendString:title];
	
#if 1
	NSLog(@"-browser: source path: %@", s);
#endif
    return YES;
}

#if 0	// not used
- (BOOL) fileManager:(NSFileManager*)fileManager shouldProceedAfterError:(NSDictionary*)errorDictionary
{
    return YES;
}
#endif

#if OLD
- (void) encodeWithCoder:(NSCoder *)aCoder				// NSCoding protocol
{
	[aCoder encodeObject: _accessoryView];
	[aCoder encodeObject: [self title]];
	[aCoder encodeObject: [self prompt]];
	[aCoder encodeObject: [self directory]];
	[aCoder encodeObject: [fileName stringValue]];
	[aCoder encodeObject: requiredTypes];
	// save other variables
	// FIXME?????
	//	[aCoder encodeValueOfObjCType: @encode(BOOL) at:&required_type];
	[aCoder encodeConditionalObject:_delegate];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
#if 1
	NSLog(@"%@ initWithCoder:%@", aDecoder);
	NSLog(@"+classforname=%@", NSStringFromClass([NSKeyedUnarchiver classForClassName:@"NSSavePanel"]));
	NSLog(@"-classforname=%@", NSStringFromClass([(NSKeyedUnarchiver *) aDecoder classForClassName:@"NSSavePanel"]));
#endif
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		return self;
	else
		{
		_accessoryView = [[aDecoder decodeObject] retain];
		[self setTitle:[aDecoder decodeObject]];
		[self setPrompt:[aDecoder decodeObject]];
		[self setDirectory:[aDecoder decodeObject]];
		[self _setFilename:[aDecoder decodeObject]];
		requiredTypes = [[aDecoder decodeObject] retain];
		//	[aDecoder decodeValueOfObjCType: @encode(BOOL) at:&required_type];
		_delegate = [[aDecoder decodeObject] retain];
		}
	return self;
}
#endif

@end /* NSSavePanel */

//*****************************************************************************
//
// 		NSOpenPanel 
//
//*****************************************************************************

@implementation NSOpenPanel

static NSOpenPanel *__openPanel;

- (void) awakeFromNib;
{
#if 1
	NSLog(@"NSOpenPanel - awake from NIB");
#endif
	[self setTitle:@"Open"];
	[self setPrompt:@"Open"];
	[self _setIncludeNewFolderButton:NO];	// don't include by default
	_op.canChooseFiles = YES;
	includeNewFolderButton = NO;
	__openPanel=self;
}

+ (NSOpenPanel *) openPanel
{ // load the save panel from the NIB file
	if (!__openPanel)
		{
		BOOL flag;
#if 0
		NSLog(@"classforname=%@", NSStringFromClass([NSKeyedUnarchiver classForClassName:@"NSSavePanel"]));
#endif
		[NSKeyedUnarchiver setClass:self forClassName:@"NSSavePanel"];
#if 0
		NSLog(@"classforname=%@", NSStringFromClass([NSKeyedUnarchiver classForClassName:@"NSSavePanel"]));
#endif
		flag=[NSBundle loadNibNamed:@"SavePanel" owner:NSApp];	// looks for SavePanel.nib in ressources of NSApp's bundle
		[NSKeyedUnarchiver setClass:nil forClassName:@"NSSavePanel"];	// reset mapping
		if(!flag)
			[NSException raise: NSInternalInconsistencyException format: @"Unable to open save panel model file."];
		}
	[__openPanel center];
	return __openPanel;
}

+ (id) alloc;
{
	return __openPanel ? __openPanel : (__openPanel=(NSOpenPanel *) NSAllocateObject(self, 0, NSDefaultMallocZone())); 
}

#if OLD

+ (NSOpenPanel *) openPanel
{	
	if(!__openPanel)
		__openPanel=[self new];
	return __openPanel;
}

- (id) init
{	
	self = [super init];	// init NSSavePanel part - will load a replacement panel from NIB file
	if(self)
		{
		[self setTitle:@"Open"];
		[self setPrompt:@"Open"];
		[self _setIncludeNewFolderButton:NO];	// don't include by default
		_op.canChooseFiles = YES;
		includeNewFolderButton = NO;
		}
  	return self;
}

#endif

- (void) setAllowsMultipleSelection:(BOOL)flag
{	
	_op.allowsMultipleSelect = flag;
	[browser setAllowsMultipleSelection:flag];
}

- (void) setCanChooseDirectories:(BOOL)flag	{ _op.canChooseDirectories = flag;}
- (void) setCanChooseFiles:(BOOL)flag		{ _op.canChooseFiles = flag; }
- (BOOL) allowsMultipleSelection 			{ return _op.allowsMultipleSelect;}
- (BOOL) canChooseDirectories				{ return _op.canChooseDirectories;}
- (BOOL) canChooseFiles						{ return _op.canChooseFiles; }

	// - (NSString*) filename 						{ return [browser path]; }

- (NSArray *) filenames
{	
	if(_op.allowsMultipleSelect) 
		{	
		NSEnumerator *e = [[browser selectedCells] objectEnumerator];
		NSMutableArray *array = [NSMutableArray array];
		NSString *d = [self directory];
		id c;
		
		while((c = [e nextObject]))
			[array addObject:[NSString stringWithFormat:@"%@/%@", d, [c stringValue]]];
		return array;
		}
	
	return [NSArray arrayWithObject:[self filename]];
}

- (NSArray *) URLs; { return NIMP; }

- (int) runModalForTypes:(NSArray *)fileTypes			// Run the NSOpenPanel
{	
	return [self runModalForDirectory:[self directory] 
								 file: @"" 
								types: fileTypes];
}

- (int) runModalForDirectory:(NSString *)path 
						file:(NSString *)name
					   types:(NSArray *)fileTypes
{	
	ASSIGN(requiredTypes, fileTypes);
	return [self runModalForDirectory:path file:name];
}

- (void) browser:(NSBrowser*)sender 						// browser delegate
		 createRowsForColumn:(int)column
		inMatrix:(NSMatrix*)matrix
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *ptc = [sender pathToColumn: column];
	NSArray *f = [fm directoryContentsAtPath: ptc];
	int i, count;
	NSMutableArray *files = [NSMutableArray arrayWithCapacity:[f count]];
	NSArray *sortedFiles;
	NSEnumerator *e=[f objectEnumerator];
	NSString *file;
	while((file=[e nextObject]))
		{
		if([file hasPrefix:@"."])
			continue;	// skip
		[files addObject:file];
		}
	sortedFiles=[files sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];	// sort alphabetically
	count = [sortedFiles count];
#if 0	
    NSLog(@"createRowsForColumn");
#endif
	[matrix renewRows:count columns:1];				// create necessary cells
	[matrix sizeToCells];	
	
	if (count == 0)
		return;
	
    for (i = 0; i < count; ++i) 
		{
		id cell = [matrix cellAtRow: i column: 0];
		BOOL is_dir = NO;
		NSString *filename=[sortedFiles objectAtIndex: i];
		NSString *path=[NSString stringWithFormat:@"%@/%@", ptc, filename];
		[cell setStringValue:filename];
		[fm fileExistsAtPath:path isDirectory: &is_dir];
		if(is_dir)
			{
			[cell setEnabled:_op.canChooseDirectories];
			// FIXME: but we should be able to traverse the directory structure!
			[cell setEnabled:YES];
			}
		else
			{
			[cell setEnabled:(_op.canChooseFiles && [self _isAllowedFile:filename])]; // disable cell if file extension is not allowed
			}
		[cell setLeaf: (!(is_dir) || (!treatsFilePackagesAsDirectories && [[NSWorkspace sharedWorkspace] isFilePackageAtPath:path]))];
		}
}

#if OLD
- (void) encodeWithCoder:(NSCoder *)aCoder				// NSCoding protocol
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeValueOfObjCType:@encode(unsigned int) at:&_op];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		return self;
	[aDecoder decodeValueOfObjCType:@encode(unsigned int) at:&_op];
	
	return self;
}
#endif

@end /* NSOpenPanel */

//*****************************************************************************
//
// 		NSColorPanel 
//
//*****************************************************************************

#import <math.h>
int __colorWheelSize = 159;

typedef struct WheelMatrix {
    unsigned int width, height;			// Size of the colorwheel
    unsigned char *data[3];				// Wheel data (R,G,B)
    unsigned char values[256];			// Precalculated values R,G & B = 0-255
} wheelMatrix;

unsigned char
getShift(unsigned char value)
{
	unsigned char i = -1;
	
    if (value == 0)
		return 0;
	
    while (value) 
		{
		value >>= 1;
		i++;
		}
	
    return i;
}

static wheelMatrix *
wheelCreateMatrix(unsigned int width, unsigned int height)
{
	wheelMatrix	*matrix = NULL;
	int	i;
    
    assert((width > 0) && (height > 0));
    
    matrix = malloc(sizeof(wheelMatrix));
    memset(matrix, 0, sizeof(wheelMatrix));
    matrix->width = width;
    matrix->height = height;
	
    for (i = 0; i < 3; i++)
		matrix->data[i] = malloc(width * height * sizeof(unsigned char));
	
    return matrix;
}

static void
wheelDestroyMatrix(wheelMatrix *matrix)
{
	int i;
    
	if (!matrix)
		return;
    
    for (i = 0; i < 3; i++)
		if (matrix->data[i])
	    	free(matrix->data[i]);
	
    free(matrix);
}

static void
wheelInitMatrix(wheelMatrix *matrix)
{
	int i, x, y;
	long ofs[4];
	int xcor, ycor;
	int dhue[4];
	const int cw_halfsize = (__colorWheelSize) / 2;
	const int cw_sqsize = (__colorWheelSize) * (__colorWheelSize);
	const int uchar_shift = getShift(sizeof(unsigned char));
	struct HSB_Color hsb;
	
    hsb.brightness = 255;
    
    ofs[0] = -1;							// offsets are counterclockwise
    ofs[1] = -(__colorWheelSize);			// (in triangles)
	
    for (y = 0; y < cw_halfsize; y++) 
		{
		for (x = y; x < (__colorWheelSize-y); x++) 
			{			// (xcor, ycor) is (x,y) relative to center of matrix
			xcor = 2 * x - __colorWheelSize;
			ycor = 2 * y - __colorWheelSize;
			// saturation will wrap after 255
			hsb.saturation = rint(255.0 * sqrt(xcor * xcor + ycor * ycor) 
								  / __colorWheelSize);
			ofs[0]++;								// top quadrant of matrix
			ofs[1] += __colorWheelSize;				// left quadrant    ____
    	    ofs[2] = cw_sqsize - 1 - ofs[0];		// bottom quadrant |\  /|
			ofs[3] = cw_sqsize - 1 - ofs[1];		// right quadrant  | \/ |
	    											//                 | /\ |
			if (hsb.saturation < 256)				//                 |/__\|
				{
				if (xcor != 0)
					dhue[0] = rint(atan((double)ycor / (double)xcor) 
								   * (180.0 / M_PI)) + (xcor < 0 ? 180.0 : 0.0);
				else
					dhue[0] = 270;
				
				dhue[0] = 360 - dhue[0];	// Reverse direction of ColorWheel
				dhue[1] = 270 - dhue[0] + (dhue[0] > 270 ? 360 : 0);
				dhue[2] = dhue[0] - 180 + (dhue[0] < 180 ? 360 : 0);
				dhue[3] = 90 - dhue[0]  + (dhue[0] > 90  ? 360 : 0);
				
				for (i = 0; i < 4; i++)
					{
					int shift = (ofs[i] << uchar_shift);
					struct RGB_Color rgb;
					
					hsb.hue = dhue[i];
					GSConvertHSBtoRGB(hsb, &rgb);
					matrix->data[0][shift] = (unsigned char)(rgb.red);
					matrix->data[1][shift] = (unsigned char)(rgb.green);
					matrix->data[2][shift] = (unsigned char)(rgb.blue);
					}	}
			else 
				{
				for (i = 0; i < 4; i++) 
					{
					int shift = (ofs[i] << uchar_shift);
					
					matrix->data[0][shift] = (unsigned char)0;
					matrix->data[1][shift] = (unsigned char)0;
					matrix->data[2][shift] = (unsigned char)0;
					}	}	}
		
		ofs[0] += 2 * y + 1;
		ofs[1] += 1 - (__colorWheelSize) * (__colorWheelSize - 1 - 2 * y);
		}
}

@implementation NSColorPanel

static NSColorPanel *__colorPanel;

- (void) awakeFromNib;
{
#if 1
	NSLog(@"NSColorPanel - awake from NIB");
#endif
	__colorPanel=self;
	[__colorPanel setWorksWhenModal:YES];
}

+ (BOOL) sharedColorPanelExists				{ return __colorPanel != nil; }

+ (NSColorPanel *) sharedColorPanel
{
	if ((!__colorPanel) && ![NSBundle loadNibNamed:@"ColorPanel" owner:NSApp])	// looks for ColorPanel.nib in ressources of NSApp's bundle
		[NSException raise: NSInternalInconsistencyException 
					format: @"Unable to open color panel model file."];
	[__colorPanel center];
	return __colorPanel;
#if OLD
	BOOL needsColorWheel = (!__colorPanel);
	
	//	__colorPanel=[[self alloc] initWithFrame;
	if ((!__colorPanel) && ![NSBundle loadNibNamed:@"ColorPanel" owner:__colorPanel])
		[NSException raise: NSInternalInconsistencyException 
					format: @"Unable to open color panel model file."];
	
	if(needsColorWheel)
		{
		NSImage *im = [[NSImage alloc] initWithSize: NSZeroSize];
		NSBitmapImageRep *imageRep = [NSBitmapImageRep alloc];
		// int row, col;
		
		[imageRep initWithBitmapDataPlanes: NULL
								pixelsWide: 159
								pixelsHigh: 159
							 bitsPerSample: 8
						   samplesPerPixel: 3
								  hasAlpha: NO
								  isPlanar: NO
							colorSpaceName: nil
							   bytesPerRow: 0
							  bitsPerPixel: 0];
		
		[im addRepresentation:imageRep];
		[[[[__colorPanel contentView] subviews] objectAtIndex:0] setImage: im];
		
		{
			int x, y;
			unsigned long ofs = 0;
			wheelMatrix *w;
			unsigned char *data = [imageRep bitmapData];
			
			w = wheelCreateMatrix(__colorWheelSize, __colorWheelSize);
			wheelInitMatrix(w);
			
			for (y = 0; y < __colorWheelSize ; y++) 
				for (x = 0; x < __colorWheelSize ; x++) 
					{
					if ((w->data[0][ofs] != 0)				// if inside wheel
						&& (w->data[1][ofs] != 0) 
						&& (w->data[2][ofs] != 0))
						{
						*(data++) = (unsigned char)(w->data[0][ofs]);
						*(data++) = (unsigned char)(w->data[1][ofs]);
						*(data++) = (unsigned char)(w->data[2][ofs]);
						//						*(ptr++) = 0;
						}
					else 
						{
						*(data++) = (0xae);
						*(data++) = (0xaa);
						*(data++) = (0xae);
						//						*(ptr++) = 255;
						}
					ofs++;
					}
					wheelDestroyMatrix(w);
		}
		}
	return __colorPanel;
#endif
}

+ (id) alloc
{ 
	return __colorPanel ? __colorPanel : (__colorPanel=(NSColorPanel *) NSAllocateObject(self, 0, NSDefaultMallocZone())); 
}

- (void) dealloc;
{
	[_accessoryView release];
	[super dealloc];
}

+ (void) setPickerMask:(int)mask			{ NIMP }
+ (void) setPickerMode:(int)mode			{ NIMP }

+ (BOOL) dragColor:(NSColor **)aColor
		 withEvent:(NSEvent *)anEvent
		  fromView:(NSView *)sourceView		{ return NO; }

- (void) _notify;
{
	[[NSApp targetForAction:@selector(changeColor:)] changeColor:self];	// send to the first responder
}

- (NSView *) accessoryView					{ return _accessoryView; }
- (BOOL) isContinuous						{ return NO; }
- (BOOL) showsAlpha							{ return NO; }
- (int) mode								{ return 0; }
- (void) setAccessoryView:(NSView *)aView	{ ASSIGN(_accessoryView, aView); }
- (void) setAction:(SEL)aSelector			{}
- (void) setContinuous:(BOOL)flag			{}
- (void) setMode:(int)mode					{}
- (void) setShowsAlpha:(BOOL)flag			{}
- (void) setTarget:(id)anObject				{}
- (void) attachColorList:(NSColorList *)aColorList		{}
- (void) detachColorList:(NSColorList *)aColorList		{}
- (float) alpha								{ return 0; }
- (NSColor *) color							{ return nil; }
- (void) setColor:(NSColor *)aColor			{}

- (void) encodeWithCoder:(NSCoder *)aCoder				// NSCoding protocol
{
	[super encodeWithCoder:aCoder];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		return self;
	
	return self;
}

@end /* NSColorPanel */

// abstract superclass which enables adding of custom UI's to NSColorPanel

@implementation NSColorPicker

- (id) initWithPickerMask:(int)aMask colorPanel:(NSColorPanel *)colorPanel
{
	if((self=[super init]))
		{
		__colorPanel = colorPanel;
		}
	return self;
}

- (NSColorPanel *) colorPanel						{ return __colorPanel; }

- (void) insertNewButtonImage:(NSImage *)newImage
						   in:(NSButtonCell *)newButtonCell	{}

- (NSImage *) provideNewButtonImage					{ return nil; }
- (void) setMode:(int)mode							{}
- (void) attachColorList:(NSColorList *)colorList	{}
- (void) detachColorList:(NSColorList *)colorList	{}
- (void) alphaControlAddedOrRemoved:(id)sender		{}
- (void) viewSizeChanged:(id)sender					{}

@end