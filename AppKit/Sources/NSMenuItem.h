/* 
   NSMenuItem.h

   Menu cell protocol and cell class.

   Modified:  H. Nikolaus Schaller <hns@computer.org>
   Date:    2003-2006
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	14. November 2007 - aligned with 10.5
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSMenuItem
#define _mySTEP_H_NSMenuItem

#import <AppKit/NSMenu.h>

// this is the official interface
// internally, NSMenuItem is implemented as a subclass of NSButtonCell

@interface NSMenuItem : NSObject <NSCopying>
{
	// officially no instance variables
}

+ (NSMenuItem *) separatorItem; 
+ (void) setUsesUserKeyEquivalents:(BOOL) flag; 
+ (BOOL) usesUserKeyEquivalents; 

- (SEL) action; 
- (NSAttributedString *) attributedTitle; 
- (BOOL) hasSubmenu; 
- (NSImage *) image; 
- (NSInteger) indentationLevel; 
- (id) initWithTitle:(NSString *) title action:(SEL) action keyEquivalent:(NSString *) keyEquivalent; 
- (BOOL) isAlternate; 
- (BOOL) isEnabled; 
- (BOOL) isHidden; 
- (BOOL) isHiddenOrHasHiddenAncestor; 
- (BOOL) isHighlighted; 
- (BOOL) isSeparatorItem; 
- (NSString *) keyEquivalent; 
- (NSUInteger) keyEquivalentModifierMask; 
- (NSMenu *) menu; 
- (NSImage *) mixedStateImage; 
- (NSString *) mnemonic; 
- (NSUInteger) mnemonicLocation; 
- (NSImage *) offStateImage; 
- (NSImage *) onStateImage; 
- (id) representedObject; 
- (void) setAction:(SEL) action; 
- (void) setAlternate:(BOOL) flag; 
- (void) setAttributedTitle:(NSAttributedString *) attrStr; 
- (void) setEnabled:(BOOL) flag; 
- (void) setHidden:(BOOL) flag; 
- (void) setImage:(NSImage *) image; 
- (void) setIndentationLevel:(NSInteger) level; 
- (void) setKeyEquivalent:(NSString *) string; 
- (void) setKeyEquivalentModifierMask:(NSUInteger) mask; 
- (void) setMenu:(NSMenu *) menu; 
- (void) setMixedStateImage:(NSImage *) image; 
- (void) setMnemonicLocation:(NSUInteger) loc; 
- (void) setOffStateImage:(NSImage *) image; 
- (void) setOnStateImage:(NSImage *) image; 
- (void) setRepresentedObject:(id) obj; 
- (void) setState:(NSInteger) state; 
- (void) setSubmenu:(NSMenu *) submenu; 
- (void) setTag:(NSInteger) tag; 
- (void) setTarget:(id) target; 
- (void) setTitle:(NSString *) title; 
- (void) setTitleWithMnemonic:(NSString *) title; 
- (void) setToolTip:(NSString *) string; 
- (void) setView:(NSView *) view; 
- (NSInteger) state; 
- (NSMenu *) submenu; 
- (NSInteger) tag; 
- (id) target; 
- (NSString *) title; 
- (NSString *) toolTip; 
- (NSString *) userKeyEquivalent; 
- (NSView *) view; 

@end

#endif /* _mySTEP_H_NSMenuItem */
