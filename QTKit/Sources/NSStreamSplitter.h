/*
 NSStreamSplitter.h
 
 mySTEP 
 
 Author:	H. N. Schaller <hns@computer.org>
 Date:	Nov 2006
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 
 Objects of this class split a stream to multiple handlers, e.g. a single camera movie stream to a file and to a NSMovie
 
 */

#import <Foundation/Foundation.h>

@interface NSStreamSplitter : NSStream
{
	NSInputStream *_source;
	NSMutableArray *_destinations;
}

- (NSInputStream *) source;
- (void) setSource:(NSInputStream *) source;
- (void) addDestination:(NSOutputStream *) handler;
- (void) removeDestination:(NSOutputStream *) handler;

- (void) stream:(NSStream *) stream handleEvent:(NSStreamEvent) event;
					 
@end
