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
	// FIXME: NSHUDWindowMask
	// FIXME: NSDocModalWindowMask
	if(self)
		{
		_w.releasedWhenClosed = NO;	// panels need explicit release
		_w.hidesOnDeactivate = YES;
			[self setFloatingPanel:aStyle&NSUtilityWindowMask];	// other mask bits are handled in NSWindow
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

- (BOOL) _needsPanelToBecomeKey:(NSView *) v
{
	NSEnumerator *e;
	if([v needsPanelToBecomeKey])
		return YES;
	e=[[v subviews] objectEnumerator];
	while((v=[e nextObject]))
		if([self _needsPanelToBecomeKey:v])
			return YES;	// any subview wants to make us key
	return NO;
}

- (BOOL) canBecomeKeyWindow
{
	if(_becomesKeyOnlyIfNeeded)
		{
#if 0
		NSLog(@"canBecomeKeyWindow=%d: %@", [self _needsPanelToBecomeKey:[self contentView]], self);
#endif
		return [self _needsPanelToBecomeKey:[self contentView]];
		}
	else
		return [super canBecomeKeyWindow];
}

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
		[v setAutoresizesSubviews:YES];
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
#endif // OLD
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
	[self _setIncludeNewFolderButton:YES];
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

- (void) setPrompt:(NSString *)prompt
{ // set the prompt button string
	if([prompt hasSuffix:@":"])
		prompt=[prompt substringToIndex:[prompt length]-1];	// remove : suffix according to docmentation
	[okButton setTitle:prompt];
}

- (void) setNameFieldLabel:(NSString *)label { return; }
- (void) setMessage:(NSString *)message { return; }
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
	
//	if([[browser selectedCell] isLeaf])		// remove file component of path (this is the rightmost lowest cell)
	path = [path stringByDeletingLastPathComponent];	
	
	return ([path length] == 0) ? lastValidPath : path;
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
			{ // unreadable
				// FIXME: better restore the previous path? Or just as far as it works?
			NSString *a = [[NSProcessInfo processInfo] processName];
			// what should we do here? Ignore?
			NSRunAlertPanel(a, @"Invalid path: '%@'",@"Continue",nil,nil,f);
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
	if(includeNewFolderButton != flag)
		{
		includeNewFolderButton=flag;
		[newFolderButton setHidden:!flag];
		// rearrange layout, i.e. resize search field
		}
}

- (BOOL) _includeNewFolderButton; { return includeNewFolderButton; }

- (IBAction) _home:(id)sender;
{
	NSLog(@"home...");
	[self setDirectory:NSHomeDirectory()];
	[browser setPath:[self directory]];
	[browser loadColumnZero];
}

- (IBAction) _mount:(id)sender;	// "disk button"
{
	NSLog(@"mount...");
	[[NSWorkspace sharedWorkspace] mountNewRemovableMedia];
	[self setDirectory:@"/Volumes"];
	[browser setPath:[self directory]];
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
		// check for hidden files
		[files addObject:file];
		}
	sortedFiles=[files sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];	// sort alphabetically
#if 1
	NSLog(@"sortedFiles=%@", sortedFiles);
#endif
	count = [sortedFiles count];
#if 1
    NSLog(@"createRowsForColumn");
#endif
	[matrix renewRows:count columns:1];				// create necessary cells
	[matrix sizeToCells];	
	
    for (i = 0; i < count; ++i) 
		{
		id cell = [matrix cellAtRow: i column: 0];
		BOOL is_dir = NO;
		NSString *filename=[sortedFiles objectAtIndex: i];
		NSString *path=[NSString stringWithFormat:@"%@/%@", ptc, filename];
		[cell setStringValue:filename];
		[fm fileExistsAtPath:path isDirectory: &is_dir];
		[cell setEnabled:(is_dir || [self _isAllowedFile:filename])]; // disable cell if file extension is not allowed
#if 1
		NSLog(@"path=%@", path);
		NSLog(@"is_dir=%@", is_dir?@"yes":@"no");
		NSLog(@"treatsFilePackagesAsDirectories=%@", treatsFilePackagesAsDirectories?@"yes":@"no");
		NSLog(@"isFilePackageAtPath=%@", [[NSWorkspace sharedWorkspace] isFilePackageAtPath:path]?@"yes":@"no");
#endif
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
	int i, count;
	[super browser:sender createRowsForColumn:column inMatrix:matrix];	// standard
    for (i = 0; i < count; ++i) 
		{ // loop a second time and update the setEnabled flag
		id cell = [matrix cellAtRow: i column: 0];
		BOOL is_dir = NO;
		NSString *filename=[cell stringValue];
		NSString *path=[NSString stringWithFormat:@"%@/%@", ptc, filename];
		[fm fileExistsAtPath:path isDirectory: &is_dir];
		[cell setEnabled:(is_dir && _op.canChooseDirectories) || (_op.canChooseFiles && [self _isAllowedFile:filename])]; // disable cell if file extension is not allowed
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

// FIXME: this should be a ColorPicker bundle!

@interface GSColorWheelView : NSImageView
{
	IBOutlet NSColorPanel *_colorPanel;	// connected in NIB file
	NSPoint _selection;
}

- (void) setColorPanel:(NSColorPanel *) panel;
- (NSColorPanel *) colorPanel;

@end

@implementation GSColorWheelView

- (void) drawRect:(NSRect) rect;
{
	NSColor *c=[_colorPanel color];
	float brightness=[c brightnessComponent];
	// make us handle use brightness by dimming the image
	[super drawRect:rect];
	[[NSColor whiteColor] set];
	// convert current color into position
	_selection=NSMakePoint(30, 30);	// and remember
	rect=NSMakeRect(_selection.x, _selection.y, 1, 1);
	NSFrameRect(NSInsetRect(rect, -2, -2));	// draw small white square box at current selection position
}

- (void) setColorPanel:(NSColorPanel *) panel; { _colorPanel=panel; }
- (NSColorPanel *) colorPanel; { return _colorPanel; }

- (void) mouseDown:(NSEvent *) event;
{
	while(YES)
		{
		NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
		NSColor *c=nil;
		// convert position into color
		if(c)
			{ // mouse is within circle
/*
 NSRect r;
			r.origin.x=MIN(_selection.x, p.x);
			r.origin.y=MIN(_selection.y, p.y);
			r.size.width=fabs(_selection.x - p.x);
			r.size.height=fabs(_selection.y - p.y);
			[self setNeedsDisplayInRect:NSInsetRect(r, -2.0, -2.0)];
 */ // the following code will make us update...
			[_colorPanel setColor:c];
			}
		if([event type] == NSLeftMouseUp)
			break;
		event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
								   untilDate:[NSDate distantFuture]						// get next event
									  inMode:NSEventTrackingRunLoopMode 
									 dequeue:YES];
		}
}

@end

@implementation NSColorPanel

static NSColorPanel *__colorPanel;

- (void) awakeFromNib;
{
#if 1
	NSLog(@"NSColorPanel - awake from NIB");
#endif
	__colorPanel=self;
	[__colorPanel setWorksWhenModal:YES];
	_showsAlpha=YES;	// default
}

+ (BOOL) sharedColorPanelExists				{ return __colorPanel != nil; }

+ (NSColorPanel *) sharedColorPanel
{
	if ((!__colorPanel) && ![NSBundle loadNibNamed:@"ColorPanel" owner:NSApp])	// looks for ColorPanel.nib in ressources of NSApp's bundle
		[NSException raise: NSInternalInconsistencyException 
					format: @"Unable to open color panel model file."];
	[__colorPanel center];
	return __colorPanel;
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

+ (void) setPickerMask:(unsigned int)mask			{ NIMP }
+ (void) setPickerMode:(int)mode			{ NIMP }

+ (BOOL) dragColor:(NSColor *)aColor
		 withEvent:(NSEvent *)anEvent
		  fromView:(NSView *)sourceView
{
	return NO;
}

- (IBAction) _notify:(id) sender;
{
	NSColor *c=[_colorWell color];
	float r, g, b, a;
#if 0
	NSLog(@"NSColorPanel _notify: %@", sender);
	NSLog(@"fltvalue=%lf", [sender floatValue]);
	NSLog(@"intvalue=%lf", [sender intValue]);
#endif
	if(sender == _brightness || sender == _brightnessSlider)
		{ // Color Wheel
		float h, s, b;
		[c getHue:&h saturation:&s brightness:&b alpha:&a];
		if(sender == _brightness)
			b=[sender floatValue];
		else
			b=[sender intValue]/255.0;
		c=[NSColor colorWithCalibratedHue:h saturation:s brightness:b alpha:a];
		}
	else
		{ // RGB or Alpha
		[c getRed:&r green:&g blue:&b alpha:&a];
		if(sender == _redSlider)
			r=[sender floatValue];
		else if(sender == _greenSlider)
			g=[sender floatValue];
		else if(sender == _blueSlider)
			b=[sender floatValue];
		else if(sender == _alphaSlider)
			a=[sender floatValue];
		else if(sender == _red)	// text field
			r=[sender intValue]/255.0;
		else if(sender == _green)
			g=[sender intValue]/255.0;
		else if(sender == _blue)
			b=[sender intValue]/255.0;
		else if(sender == _alpha)
			a=[sender intValue]/255.0;
		c=[NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
		}
	[self setColor:c];
	if(_target && _action)
		[NSApp sendAction:_action to:_target from:self];
}

- (IBAction) _pick:(id) sender;
{ // called from button action method
	NSLog(@"pick mode");
	// pick and update color from screen
}

- (void) _update;
{ // update sliders etc.
	BOOL hideAlpha=!(![NSColor ignoresAlpha] && _showsAlpha);
	float red, green, blue, alpha, brightness;
	[[_colorWell color] getRed:&red green:&green blue:&blue alpha:&alpha];
	[_alpha setHidden:hideAlpha];
	[_alphaSlider setHidden:hideAlpha];
	// show/hide message
	if(!hideAlpha)
		{
		[_alphaSlider setFloatValue:alpha];
		[_alpha setIntValue:(int)(255*alpha)];
		}
	[_html setStringValue:[NSString stringWithFormat:@"#%02x%02x%02x", (int)(255*red), (int)(255*green), (int)(255*blue)]];
	switch([_colorTabs indexOfTabViewItem:[_colorTabs selectedTabViewItem]])
		{
		case 0:
			[_redSlider setFloatValue:red];
			[_red setIntValue:(int)(255*red)];
			[_greenSlider setFloatValue:green];
			[_green setIntValue:(int)(255*green)];
			[_blueSlider setFloatValue:blue];
			[_blue setIntValue:(int)(255*blue)];
			break;
		case 1:
			break;
		case 2:
			brightness=[[_colorWell color] brightnessComponent];
			[_brightnessSlider setFloatValue:brightness];
			[_brightness setIntValue:(int)(255*brightness)];
			break;
		}
}

- (void) tabView:(NSTabView *) tabView didSelectTabViewItem:(NSTabViewItem *) tabViewItem
{ // different tab has been seleceted
#if 1
	NSLog(@"tabViewItem %@", tabViewItem);
#endif
	[self _update];
}

- (NSView *) accessoryView					{ return _accessoryView; }
- (BOOL) isContinuous						{ return _isContinuous; }
- (BOOL) showsAlpha							{ return _showsAlpha; }
- (int) mode								{ return _mode; }
- (float) alpha								{ return [_alphaSlider isHidden]?1.0:[[_colorWell color] alphaComponent]; }
- (NSColor *) color							{ return [_colorWell color]; }

- (void) setAction:(SEL)aSelector			{ _action=aSelector; }

- (void) setMode:(int)mode					{ _mode=mode; }

- (void) setTarget:(id)anObject				{ _target=anObject; }
- (void) attachColorList:(NSColorList *)aColorList		{}
- (void) detachColorList:(NSColorList *)aColorList		{}

- (void) setContinuous:(BOOL)flag
{
	_isContinuous=flag;
	[_redSlider setContinuous:_isContinuous];		// sliders will trigger action(s)
	[_greenSlider setContinuous:_isContinuous];
	[_blueSlider setContinuous:_isContinuous];
	[_alphaSlider setContinuous:_isContinuous];
}

- (void) setAccessoryView:(NSView *)aView
{
	ASSIGN(_accessoryView, aView);
	[self _update];
	// should also update the full window
}

- (void) setShowsAlpha:(BOOL)flag
{
	_showsAlpha=flag;
	[self _update];
}

- (void) setColor:(NSColor *)aColor
{
	NSAssert(aColor, @"setColor is nil");
	if([_colorWell color] == aColor)
		return;	// unchanged
	[_colorWell setColor:aColor];
	if([_colorTabs indexOfTabViewItem:[_colorTabs selectedTabViewItem]] == 2)
		[_colorWheel setNeedsDisplay:YES];	// we are showing the color wheel
	[self _update];	// update sliders and text fields
	// FIXME: send NSColorPanelColorDidChangeNotification
}

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

- (id) initWithPickerMask:(unsigned int)aMask colorPanel:(NSColorPanel *)colorPanel
{
	if((self=[super init]))
		{
		__colorPanel = colorPanel;
		}
	return self;
}

- (NSColorPanel *) colorPanel						{ return __colorPanel; }

- (void) insertNewButtonImage:(NSImage *)newImage in:(NSButtonCell *)newButtonCell	{ SUBCLASS; }

- (NSImage *) provideNewButtonImage					{ return nil; }
- (void) setMode:(int)mode							{ SUBCLASS; }
- (void) attachColorList:(NSColorList *)colorList	{ SUBCLASS; }
- (void) detachColorList:(NSColorList *)colorList	{ SUBCLASS; }
- (void) alphaControlAddedOrRemoved:(id)sender		{ SUBCLASS; }
- (void) viewSizeChanged:(id)sender					{ return; }

@end
