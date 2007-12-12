/*
   NSTextContainer.h

   An NSTextContainer defines a region in which to lay out text.  It's main 
   responsibility is to calculate line fragments which fall within the region 
   it represents.  Containers have a line fragment padding which is used by 
   the typesetter to inset text from the edges of line fragments along the 
   sweep direction.

   The container can enforce any other geometric constraints as well.  When 
   drawing the text that has been laid in a container, a NSTextView will clip 
   to the interior of the container (it clips to the container's rectagular 
   area only, however, not to the arbitrary shape the container may define 
   for text flow).

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998
   Source by Daniel Bðhringer integrated into mySTEP gui
   by Felipe A. Rodriguez <far@ix.netcom.com> 

   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jun 2006 - aligned with 10.4

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <Foundation/Foundation.h>

@class NSLayoutManager;
@class NSTextView;

typedef enum _NSLineSweepDirection
{
    NSLineSweepLeft = 0,
    NSLineSweepRight = 1,
    NSLineSweepDown = 2,
    NSLineSweepUp = 3,
} NSLineSweepDirection;

typedef enum _NSLineMovementDirection
{
    NSLineDoesntMove = 0, 
    NSLineMovesLeft = 1,
    NSLineMovesRight = 2,
    NSLineMovesDown = 3,
    NSLineMovesUp = 4,
} NSLineMovementDirection;


@interface NSTextContainer : NSObject
{
	NSLayoutManager	*layoutManager;
    NSTextView		*textView;
    NSSize 			size;
    float			lineFragmentPadding;
	BOOL			widthTracksTextView;
	BOOL			heightTracksTextView;
//	BOOL			observingFrameChanges;
}

- (NSSize) containerSize;
- (BOOL) containsPoint:(NSPoint) point;
- (BOOL) heightTracksTextView;
- (id) initWithContainerSize:(NSSize) size;
- (BOOL) isSimpleRectangularTextContainer;
- (NSLayoutManager *) layoutManager;
- (CGFloat) lineFragmentPadding;
- (NSRect) lineFragmentRectForProposedRect:(NSRect) proposedRect
							sweepDirection:(NSLineSweepDirection) sweepDirection
						 movementDirection:(NSLineMovementDirection) movementDirection
							 remainingRect:(NSRectPointer) remainingRect;
- (void) replaceLayoutManager:(NSLayoutManager *) newLayoutManager;
- (void) setContainerSize:(NSSize) size;
- (void) setHeightTracksTextView:(BOOL) flag;
- (void) setLayoutManager:(NSLayoutManager *) layoutManager;
- (void) setLineFragmentPadding:(CGFloat) pad;
- (void) setTextView:(NSTextView *) textView;
- (void) setWidthTracksTextView:(BOOL) flag;
- (NSTextView *) textView;
- (BOOL) widthTracksTextView;

@end

