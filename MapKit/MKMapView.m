//
//  MKMapView.m
//  MapKit
//
//  Created by H. Nikolaus Schaller on 20.10.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#ifdef __mySTEP__	// workaround for what appears to be a library/gcc bug

extern double exp2(double);
extern double log2(double);

#endif

#define TILEPIXELS	256.0

@interface _MKTile : NSObject
{
	NSURL *_url;
	NSURLConnection *_connection;
	NSMutableData *_data;
	NSImage *_image;
	MKMapView *_delegate;
}

// FIXME: what about multiple MapViews?

- (id) initWithContentsOFURL:(NSURL *) url forView:(MKMapView *) delegate;
- (void) start;
- (NSImage *) image;
@end

@implementation _MKTile

static NSMutableArray *loadQueue;	// TileLoaders to be started
static int alreadyLoading=0;

- (NSString *) description
{
	return [NSString stringWithFormat:@"MKTile: %@%@", _url, _image?@"":@" no image"];
}

- (id) initWithContentsOFURL:(NSURL *) url forView:(MKMapView *) delegate;
{
	if((self=[super init]))
		{
		_delegate=[delegate retain];
		_url=[url retain];
		if(alreadyLoading == 0)
			// protect against exceptions
			[[_delegate delegate] mapViewWillStartLoadingMap:_delegate];
		if(alreadyLoading < 5)
			[self start];
		else
			{ // enqueue
				if(!loadQueue)
					loadQueue=[[NSMutableArray alloc] initWithCapacity:20];
				[loadQueue addObject:self];	// put into queue
			}
		}
	return self;
}

- (void) start
{
	if(!_connection)
		{
		alreadyLoading++;
		_connection=[[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:_url] delegate:self startImmediately:NO];
		[_url release];
		_url=nil;
		[_connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSEventTrackingRunLoopMode];	// load even if we are tracking (moving the map)
#if __APPLE__
		// this is needed since recently on the Mac although
		// documentation says that the connection is already
		// scheduled in the default run loop mode
		[_connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
#endif
		[loadQueue removeObjectIdenticalTo:self];	// remove from queue (if we are in the queue)
		[_connection start];	// may immediately call connection:didFailWithError:
		}
}

- (void) connection:(NSURLConnection *) connection didReceiveData:(NSData *) data
{
	if(!_data)
		_data=[data mutableCopy];
	else
		[_data appendData:data];
}

- (void) connection:(NSURLConnection *) connection didFailWithError:(NSError *) error
{
#if 1
	NSLog(@"didFailWithError: %@", error);
#endif
	// could we generate an alternative URL?
	// this requires the tile loader to know (x,y,z) instead of complete URLs
	// and the tile cache must be indexed through (x,y,z)
#if 1
	_image=[[NSImage alloc] initWithSize:NSMakeSize(TILEPIXELS, TILEPIXELS)];	// write error message into a tile
	//	[_image setFlipped:NO];
	[_image lockFocus];
	[[error localizedDescription] drawInRect:[_image alignmentRect] withAttributes:nil];
	[_image unlockFocus];
#endif
	[self connectionDidFinishLoading:connection];
}

- (void) connectionDidFinishLoading:(NSURLConnection *) connection
{
	if(connection != _connection)
		return;	// ignore spurious callback (e.g. after didFailWithError)
	[_connection release];
	_connection=nil;
	// FIXME: if the page does not exist or is temporarily not available, we may have got a html/text response!
	if(!_image && [_data length] > 0)
		{ // get image from data (unless we show an error message)
			_image=[[NSImage alloc] initWithData:_data];
			//		[_image setFlipped:YES];
		}
	[_data release];
	_data=nil;
	[_delegate setNeedsDisplay:YES];	// and redisplay (we should just specify a rect where we want to be updated)
	alreadyLoading--;
	NSAssert(alreadyLoading >= 0, @"never become negative");
	if([loadQueue count] > 0)
		[[loadQueue lastObject] start];	// start next in queue (and remove)
	else if(alreadyLoading == 0)
		// protect against exceptions
		[[_delegate delegate] mapViewDidFinishLoadingMap:_delegate];
}

- (NSImage *) image;
{
	if(_url)
		{
		if([loadQueue lastObject] != self)
			{ // LRU handling
				[loadQueue removeObjectIdenticalTo:self];
				[loadQueue addObject:self];
			}
		return nil;
		}
	if(_connection)
		return nil;	// already/still loading
	return _image;
}

- (void) dealloc
{
	[_connection cancel];
	[_connection release];
	[_delegate release];
	[_data release];
	[_image release];
	[_url release];
	[super dealloc];
}

@end

static MKMapRect _MKMapRectForCoordinateRegion(MKCoordinateRegion reg)
{ // convert corner points (may have different center!)
	MKMapPoint sw=MKMapPointForCoordinate((CLLocationCoordinate2D) { reg.center.latitude-0.5*reg.span.latitudeDelta, reg.center.longitude-0.5*reg.span.longitudeDelta });
	MKMapPoint ne=MKMapPointForCoordinate((CLLocationCoordinate2D) { reg.center.latitude+0.5*reg.span.latitudeDelta, reg.center.longitude+0.5*reg.span.longitudeDelta });
	return (MKMapRect) { sw, (MKMapSize) { ne.x-sw.x, ne.y-sw.y }};
}

@implementation MKMapView

static MKMapRect worldMap;	// visible map rect at z=0 (topmost tile)

#define CACHESIZE 100

static NSMutableDictionary *imageCache;
static NSMutableArray *tileLRU;

+ (void) initialize
{
	if(self == [MKMapView class])
		{
		MKMapPoint topRight=MKMapPointForCoordinate((CLLocationCoordinate2D) { 85.05112, 180.0-1e-12 });	// CLLocationCoordinate2D is (latitude, longigude) which corresponds to (y, x)
#if 1	// for testing...
		CLLocationCoordinate2D test=MKCoordinateForMapPoint(topRight);
		if(fabs(test.latitude - 85.05112) > 1e-6 || fabs(test.longitude - 180.0) > 1e-6)
			{
			NSLog(@"internal conversion error");
			topRight=MKMapPointForCoordinate((CLLocationCoordinate2D) { 85.05112, 180.0 });	// CLLocationCoordinate2D is (latitude, longigude) which corresponds to (y, x)
			test=MKCoordinateForMapPoint(topRight);
			}
#endif
		worldMap.origin=MKMapPointForCoordinate((CLLocationCoordinate2D) { -85.05112, -180.0+1e-12 });
#if 0
		NSLog(@"bottom left: %@", MKStringFromMapPoint(worldMap.origin));
		NSLog(@"top right:   %@", MKStringFromMapPoint(topRight));
#endif
		worldMap.size.width=topRight.x - worldMap.origin.x;
		worldMap.size.height=topRight.y - worldMap.origin.y;
		imageCache=[[NSMutableDictionary alloc] initWithCapacity:CACHESIZE];
		tileLRU=[[NSMutableArray alloc] initWithCapacity:CACHESIZE];
		}
}

- (id) initWithFrame:(NSRect) frameRect
{
	if((self=[super initWithFrame:frameRect]))
		{
		annotations=[[NSMutableArray alloc] initWithCapacity:50];
		overlays=[[NSMutableArray alloc] initWithCapacity:20];
		// FIXME: take only that part of the worldMap that has the same aspect ratio
		visibleMapRect=worldMap;
		visibleMapRect.size.width *= NSWidth(frameRect)/TILEPIXELS;	// scale so that tiles are TILEPIXELS large (this may repeat the world map if the frame is larger than 256 pixels)
		visibleMapRect.size.height *= NSHeight(frameRect)/TILEPIXELS;
		scrollEnabled=YES;
		zoomEnabled=YES;
		[self setShowsUserLocation:YES];
		}
	return self;
}

- (void) setFrameSize:(NSSize) newSize
{ // keep contents centered
#if 1
	NSRect frame=[self frame];
	float fx=newSize.width / frame.size.width;
	float fy=newSize.height / frame.size.height;
	visibleMapRect.origin.x += 0.5*visibleMapRect.size.width;	// keep center stable
	//	visibleMapRect.origin.x *= fx;
	visibleMapRect.size.width *= fx;
	visibleMapRect.origin.x -= 0.5*visibleMapRect.size.width;	// new left edge
	visibleMapRect.origin.y += 0.5*visibleMapRect.size.height;
	//	visibleMapRect.origin.y *= fy;
	visibleMapRect.size.height *= fy;
	visibleMapRect.origin.y -= 0.5*visibleMapRect.size.height;
#endif
	[super setFrameSize:newSize];
	[self setNeedsDisplay:YES];
}

#if OLD

- (void) setFrame:(NSRect) frameRect
{ // adjust aspect ratio
#if 0
	NSRect frame=[self frame];
	float fx=frameRect.size.width / frame.size.width;
	float fy=frameRect.size.height / frame.size.height;
	// adjust for movement of frame.origin!
	visibleMapRect.origin.x += 0.5*visibleMapRect.size.width;	// keep center stable
	//	visibleMapRect.origin.x *= fx;
	visibleMapRect.size.width *= fx;
	visibleMapRect.origin.x -= 0.5*visibleMapRect.size.width;	// new left edge
	visibleMapRect.origin.y -= 0.5*visibleMapRect.size.height;
	//	visibleMapRect.origin.y *= fy;
	visibleMapRect.size.height *= fy;
	visibleMapRect.origin.y += 0.5*visibleMapRect.size.height;
#endif
	// lock setFrameSize to change visibleMapRect again!
	[super setFrame:frameRect];	// this will/may call setFrameSize
	// unlock
	[self setNeedsDisplay:YES];
}

- (void) setBounds:(NSRect) boundsRect
{ // adjust aspect ratio
#if 0
	NSRect frame=[self frame];
	float fx=frameRect.size.width / frame.size.width;
	float fy=frameRect.size.height / frame.size.height;
	// adjust for movement of frame.origin!
	visibleMapRect.origin.x += 0.5*visibleMapRect.size.width;	// keep center stable
	//	visibleMapRect.origin.x *= fx;
	visibleMapRect.size.width *= fx;
	visibleMapRect.origin.x -= 0.5*visibleMapRect.size.width;	// new left edge
	visibleMapRect.origin.y -= 0.5*visibleMapRect.size.height;
	//	visibleMapRect.origin.y *= fy;
	visibleMapRect.size.height *= fy;
	visibleMapRect.origin.y += 0.5*visibleMapRect.size.height;
#endif
	[super setBounds:boundsRect];
}

- (void) setBoundsSize:(NSSize) newSize
{
	[super setBoundsSize:newSize];
}
#endif
- (id) initWithCoder:(NSCoder *) aDecoder;
{
	self=[super initWithCoder:aDecoder];
	// delegate?
	// visibleMapRect?
	// scrollEnabled
	// [self setShowsUserLocation:[aDecoder boolForKey:@"key"]];
	// zoomEnabled
	return self;
}

- (void) dealloc;
{
	[annotations release];
	[overlays release];
	[userLocation release];
	[super dealloc];
}

- (BOOL) isOpaque; { return YES; }
// - (BOOL) isFlipped; { return YES; }	// no we are not flipped
- (BOOL) acceptsFirstResponder { return YES; }	// otherwise we don't receive keyboard and arrow key events/actions


// FIXME: we could define a NSAffineTransform that we update parallel to changes of bounds and visibleMapRect
// FIXME: we need to scale by 1.0-MIN(fabs(sin([self boundsRotation])), fabs(cos([self boundsRotation]))) to compensate for rotated bounds

- (NSPoint) _pointForMapPoint:(MKMapPoint) pnt
{ // convert map point to bounds point (using visibleMapRect)
	NSRect bounds=[self bounds];
	MKMapRect visible=[self visibleMapRect];
	return NSMakePoint(NSMinX(bounds)+NSWidth(bounds)*(pnt.x-MKMapRectGetMinX(visible))/MKMapRectGetWidth(visible),
					   NSMinY(bounds)+NSHeight(bounds)*(pnt.y-MKMapRectGetMinY(visible))/MKMapRectGetHeight(visible));
}

- (NSRect) _rectForMapRect:(MKMapRect) rect
{ // convert map rect to bounds rect (using visibleMapRect)
	NSRect bounds=[self bounds];
	MKMapRect visible=[self visibleMapRect];
	return NSMakeRect(NSMinX(bounds)+NSWidth(bounds)*(MKMapRectGetMinX(rect)-MKMapRectGetMinX(visible))/MKMapRectGetWidth(visible),
					  NSMinY(bounds)+NSHeight(bounds)*(MKMapRectGetMinY(rect)-MKMapRectGetMinY(visible))/MKMapRectGetHeight(visible),
					  NSWidth(bounds)*MKMapRectGetWidth(rect)/MKMapRectGetWidth(visible),
					  NSHeight(bounds)*MKMapRectGetHeight(rect)/MKMapRectGetHeight(visible)
					  );
}

- (MKMapPoint) _mapPointForPoint:(NSPoint) pnt
{ // convert map point to bounds point (using visibleMapRect)
	NSRect bounds=[self bounds];
	MKMapRect visible=[self visibleMapRect];
	return MKMapPointMake(MKMapRectGetMinX(visible)+MKMapRectGetWidth(visible)*(pnt.x-NSMinX(bounds))/NSWidth(bounds),
						  MKMapRectGetMinY(visible)+MKMapRectGetHeight(visible)*(pnt.y-NSMinY(bounds))/NSHeight(bounds));
}

- (MKMapRect) _mapRectForRect:(NSRect) rect
{ // convert map rect to bounds rect (using visibleMapRect)
	NSRect bounds=[self bounds];
	MKMapRect visible=[self visibleMapRect];
	return MKMapRectMake(MKMapRectGetMinX(visible)+MKMapRectGetWidth(visible)*(NSMinX(rect)-NSMinX(bounds))/NSWidth(bounds),
						 MKMapRectGetMinY(visible)+MKMapRectGetHeight(visible)*(NSMinY(rect)-NSMinY(bounds))/NSHeight(bounds),
						 NSWidth(rect)*MKMapRectGetWidth(visible)/NSWidth(bounds),
						 NSHeight(rect)*MKMapRectGetHeight(visible)/NSHeight(bounds)
						 );
}

// FIXME: how does resizing modify the visibleMapRect?
// we must overwrite setFrame(Size) and adjust the visibleRect

- (NSString *) _tileURLForZ:(int) z x:(int) x y:(int) y;
{ // conversion of geo location and zoom into Mapnik tile path: http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
	long iscale;
	NSString *url;
	if(z < 0 || z > 18)	// this is for OSM tiles
		return nil;
	iscale = 1<<z;
	x %= iscale;	// repeat tile pattern if we wrap around the map
	if(x < 0) x += iscale;	// c99 defines negative return value for negative dividend but we need the positive modulus
	y = (iscale-1) - y;	// flip - OpenStreetMap has (0,0) at top left position and we at bottom left
	y %= iscale;
	if(y < 0) y += iscale;
	switch(mapType) {
			// ignored
	}
	url=[[NSBundle bundleForClass:[self class]] pathForResource:@"PreinstalledTiles" ofType:@""];
	url=[url stringByAppendingFormat:@"/%d/%d/%d.png", z, x, y];
	if([[NSFileManager defaultManager] fileExistsAtPath:url])
		url=[[NSURL fileURLWithPath:url] absoluteString];
	// url=[@"file:///" stringByAppendingString:url];	// stored in bundle for offine access
	else
		{ // not preinstalled to work offline
			url=[NSString stringWithFormat:@"http://tile.openstreetmap.org/%d/%d/%d.png", z, x, y];
#if 0	// debugging http loader - we can then look into the server log
			url=[NSString stringWithFormat:@"http://download.goldelico.com/quantumstep/OSM/%d/%d/%d.png", z, x, y];
#endif
		}
	return url;
}

- (BOOL) _drawTileForZ:(int) z x:(int) x y:(int) y intoRect:(NSRect) rect load:(BOOL) flag;
{ // draw tile in required zoom at given position if it intersects the rect
	float iscale = exp2(-z);
	MKMapSize tileSize = (MKMapSize) { worldMap.size.width * iscale, worldMap.size.height * iscale };	// size of single tile (at scale z)
	MKMapRect mapRect = MKMapRectMake(x*tileSize.width, y*tileSize.height, tileSize.width, tileSize.height);
	NSRect drawRect = [self _rectForMapRect:mapRect];	// transform tile
	NSString *url;
	_MKTile *tile;
	NSImage *img;
#if 1
	NSLog(@"mapRect=%@", MKStringFromMapRect(mapRect));
	NSLog(@"drawRect=%@", NSStringFromRect(drawRect));
#endif
	if(!NSIntersectsRect(drawRect, rect))
		return NO;	// tile does not fall into drawing rect
	url=[self _tileURLForZ:z x:x y:y];	// repeat tiles if necessary
	if(!url)
		return NO;	// can't translate
	tile=[imageCache objectForKey:url];	// check cache
	if(!tile)
		{ // not in cache
			if(!flag)
				return NO;	// and don't load
			if(url)
				{ // start tile loader
#if 1
					NSLog(@"loading %@", url);
#endif
					tile=[[[_MKTile alloc] initWithContentsOFURL:[NSURL URLWithString:url] forView:self] autorelease];
					[imageCache setObject:tile forKey:url];
					if([tileLRU count] > CACHESIZE)
						[tileLRU removeLastObject];	// if we run out of space, remove least recently used tile
				}
			else
				tile=nil;
		}
	else
		[tileLRU removeObject:tile];	// remove from current LRU position
	img=[tile image];	// get image
	if(img)
		[tileLRU insertObject:tile atIndex:0];  // move to beginning of LRU list
	if(!img)
		{ // did not draw - stich together from higher resolution
#if 1
			// FIXME: should this go recursively?
			// to a defined number of levels? Or just be limited by tile size?
			[self _drawTileForZ:z+1 x:2*x y:2*y intoRect:rect load:NO];
			[self _drawTileForZ:z+1 x:2*x+1 y:2*y intoRect:rect load:NO];
			[self _drawTileForZ:z+1 x:2*x y:2*y+1 intoRect:rect load:NO];
			[self _drawTileForZ:z+1 x:2*x+1 y:2*y+1 intoRect:rect load:NO];
#endif
		}
#if 0
	NSLog(@"drawTile z=%d x=%d y=%d into %@ %@", z, x, y, NSStringFromRect(drawRect), [tile image]);
#endif
	[img drawInRect:drawRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
#if 0
	if(img)
		[[NSColor greenColor] set];
	else
		[[NSColor redColor] set];
	NSFrameRect(drawRect);	// draw a box around the tile
#endif
	return img != nil;
}

- (void) drawRect:(NSRect) rect
{
	// FIXME: adjust scale by bounds/TILESIZE
	MKZoomScale scale = MAX(worldMap.size.width / visibleMapRect.size.width, worldMap.size.height / visibleMapRect.size.height);
	float lscale=log2(scale);
//	int z=ceil(lscale);
	int z=floor(lscale);	// basic scale
	// these limits are source-dependent - but should we really limit here???
	if(z < 0) z = 0;	// limit tile scaling
	if(z > 18) z = 18;	// for OSM tiles
	float iscale = exp2(z);	// scale factor
	MKMapRect r=[self _mapRectForRect:rect];
	int minx=floor(iscale*MKMapRectGetMinX(r) / worldMap.size.width);	// get tile index range at zoom z
	int maxx=ceil(iscale*MKMapRectGetMaxX(r) / worldMap.size.width);
	int miny=floor(iscale*MKMapRectGetMinY(r) / worldMap.size.height);
	int maxy=ceil(iscale*MKMapRectGetMaxY(r) / worldMap.size.height);
	int x, y;
	
	NSEnumerator *e;
	NSObject <MKAnnotation> *a;
	
	[[NSColor controlColor] set];
	NSRectFill(rect);	// draw grey background
	
	// optionally draw a meridian or tile grid?
	
#if 1
	{
	NSString *str=@"I am the MKMapView\n";
	str=[str stringByAppendingFormat:@"%@\n", [annotations description]];
	str=[str stringByAppendingFormat:@"%@\n", MKStringFromMapRect(visibleMapRect)];
	str=[str stringByAppendingFormat:@"%@\n", MKStringFromMapRect(worldMap)];
	[str drawInRect:NSMakeRect(10.0, 10.0, 1000.0, 300.0) withAttributes:nil];
	}
#endif	
	
	// FIXME: if we zoom out very far, we may have to draw very many very small tiles making drawing slow

	for(y = miny; y < maxy; y++)
		{
		for(x = minx; x < maxx; x++)
			[self _drawTileForZ:z x:x y:y intoRect:rect load:YES];
		}
	// FIXME: should we have some flag to update only if any annotation or visibleMapRect changes?
	/* draw annotations and overlays (not here - they are handled through subviews) */
	// but we should check annotations / annotation views if they are still visible
	e=[annotations objectEnumerator];
	while((a=[e nextObject]))
		{ // update position of annotation
			
		}
}

- (void) addAnnotation:(id <MKAnnotation>) a; { [annotations addObject:a]; [self setNeedsDisplay:YES]; }	// could optimize drawing rect?
- (void) addAnnotations:(NSArray *) a; { [annotations addObjectsFromArray:a]; [self setNeedsDisplay:YES]; }
- (void) addOverlay:(id <MKOverlay>) o; { [overlays addObject:o]; [self setNeedsDisplay:YES]; }
- (void) addOverlays:(NSArray *) o; { [overlays addObjectsFromArray:o]; [self setNeedsDisplay:YES]; }
- (NSArray *) annotations;{ return annotations; }

- (NSRect) annotationVisibleRect;
{
	NSRect r=NSZeroRect;
	// loop over all visible annotations and r=NSUnionRect(r, [annotation frame]);
	return r;
}

- (CLLocationCoordinate2D) centerCoordinate; { return MKCoordinateRegionForMapRect(visibleMapRect).center; }

- (NSPoint) convertCoordinate:(CLLocationCoordinate2D) coord toPointToView:(UIView *) view;
{
	MKMapPoint pnt=MKMapPointForCoordinate(coord);
	NSPoint p=[self _pointForMapPoint:pnt];	// map to point
	return [self convertPoint:p toView:view];
}

- (CLLocationCoordinate2D) convertPoint:(NSPoint) point toCoordinateFromView:(UIView *) view;
{
	NSPoint pnt=[self convertPoint:point fromView:view];
	MKMapPoint p=[self _mapPointForPoint:pnt];
	return MKCoordinateForMapPoint(p);
}

- (MKCoordinateRegion) convertRect:(NSRect) coord toRegionFromView:(UIView *) view;
{
	NSRect rect=[self convertRect:coord fromView:view];
	MKMapRect r=[self _mapRectForRect:rect];
	return MKCoordinateRegionForMapRect(r);	// FIXME: this function is not completely implemented
}

- (NSRect) convertRegion:(MKCoordinateRegion) region toRectToView:(UIView *) view;
{
	/* FIXME: this is not well defined since there is no MKMapRectForCoordinateRegion function - and the rect becomes distorted
	 We may have to take the center of the region and apply the span uniformly
	 
	 MKMapRect rect=MKMapRectForCoordinateRegion(region);
	 NSRect r=[self _rectForMapRect:rect];	// map to point
	 return [self convertRect:r toView:view];	
	 */
	return NSZeroRect;
}

- (id <MKMapViewDelegate>) delegate; { return delegate; }

- (MKAnnotationView *) dequeueReusableAnnotationViewWithIdentifier:(NSString *) ident;
{ // not yet implemented
	// can we have multiple views with same ident?
	// if yes, we need a NSDictionary with NSMutableArray entries
	// this method looks if we have such an identifier
	return nil;
}

- (void) _enqueueReusableAnnotationView:(MKAnnotationView *) view
{ // has moved off-screen
	NSString *ident=[view reuseIdentifier];
	if(ident)
		{ // put into queue
			[view prepareForReuse];	// give them a chance to prepare for reuse
		}
}

- (void) deselectAnnotation:(id <MKAnnotation>) a animated:(BOOL) flag;
{
	[[self viewForAnnotation:a] setSelected:NO animated:flag];
}

- (void) exchangeOverlayAtIndex:(NSUInteger) idx1 withOverlayAtIndex:(NSUInteger) idx2; { [overlays exchangeObjectAtIndex:idx1 withObjectAtIndex:idx2]; [self setNeedsDisplay:YES]; }

- (void) insertOverlay:(id <MKOverlay>) o aboveOverlay:(id <MKOverlay>) sibling;
{ // search 
	NSUInteger idx=[overlays indexOfObject:sibling];
	if(idx == NSNotFound)
		; // raise exception
	[self insertOverlay:o atIndex:idx+1];
}

- (void) insertOverlay:(id <MKOverlay>) o atIndex:(NSUInteger) idx; { [overlays insertObject:o atIndex:idx]; [self setNeedsDisplay:YES]; }

- (void) insertOverlay:(id <MKOverlay>) o belowOverlay:(id <MKOverlay>) sibling;
{ // search  
	NSUInteger idx=[overlays indexOfObject:sibling];
	if(idx == NSNotFound)
		; // raise exception
	[self insertOverlay:o atIndex:idx];
}

- (BOOL) isScrollEnabled; { return scrollEnabled; }

- (BOOL) isUserLocationVisible;
{
	if(!userLocation)
		return NO;
	// use horizontal accuracy and current location to check if the user location is (at least) partially on screen
	return YES;
}

- (BOOL) isZoomEnabled; { return zoomEnabled; }

- (MKMapRect) mapRectThatFits:(MKMapRect) rect;
{
	UIEdgeInsets insets = { 0, 0, 0, 0 };
	return [self mapRectThatFits:rect edgePadding:insets];
}

- (MKMapRect) mapRectThatFits:(MKMapRect) rect edgePadding:(UIEdgeInsets) insets;
{
	NSRect frame=[self frame];
	float fx;
	float fy;
	frame.origin.x += insets.left;
	frame.size.width -= insets.left+insets.right;
	frame.origin.y += insets.bottom;
	frame.size.height -= insets.bottom+insets.top;
	fx=rect.size.width / frame.size.width;
	fy=rect.size.height / frame.size.height;
	if(fx > fy)
		{ // wider than screen - cut left&right
			rect.origin.x += 0.5*rect.size.width;	// keep center stable
			rect.origin.x *= fy/fx;
			rect.size.width *= fy/fx;
			rect.origin.x -= 0.5*rect.size.width;	// new left edge			
		}
	else
		{ // higher than screen - cut top&bottom
			rect.origin.y -= 0.5*rect.size.height;
			rect.origin.y *= fx/fy;
			rect.size.height *= fx/fy;
			rect.origin.y += 0.5*rect.size.height;			
		}
	return rect;
}

- (MKMapType) mapType; { return mapType; }
- (NSArray *) overlays; { return overlays; }
- (MKCoordinateRegion) region; { return MKCoordinateRegionForMapRect(visibleMapRect); }

- (MKCoordinateRegion) regionThatFits:(MKCoordinateRegion) region;
{
	return MKCoordinateRegionForMapRect([self mapRectThatFits:_MKMapRectForCoordinateRegion(region)]);
}

- (void) removeAnnotation:(id <MKAnnotation>) a; { [annotations removeObjectIdenticalTo:a]; [self setNeedsDisplay:YES]; }
- (void) removeAnnotations:(NSArray *) a; { [annotations removeObjectsInArray:a]; [self setNeedsDisplay:YES]; }
- (void) removeOverlay:(id <MKOverlay>) a; { [overlays removeObjectIdenticalTo:a]; [self setNeedsDisplay:YES]; }
- (void) removeOverlays:(NSArray *) a; { [overlays removeObjectsInArray:a]; [self setNeedsDisplay:YES]; }

- (void) selectAnnotation:(id <MKAnnotation>) a animated:(BOOL) flag;
{
	[[self viewForAnnotation:a] setSelected:YES animated:flag];
}

- (NSArray *) selectedAnnotations;
{
	NSMutableArray *r=[NSMutableArray arrayWithCapacity:10];
	NSEnumerator *e=[annotations objectEnumerator];
	id <MKAnnotation> a;
	while((a=[e nextObject]))
		{ // go through annotation views and check isSelected
			if([[self viewForAnnotation:a] isSelected])
				[r addObject:a];
		}
	return r;
}

- (void) setCenterCoordinate:(CLLocationCoordinate2D) center;
{
	[self setCenterCoordinate:center animated:NO];
}

- (void) setCenterCoordinate:(CLLocationCoordinate2D) center animated:(BOOL) flag;
{ // keep zoom constant and just move center
	MKMapRect visible=[self visibleMapRect];
	MKMapPoint newCenter=MKMapPointForCoordinate(center);
#if 1
	NSLog(@"setCenterCoordinate:%@", MKStringFromMapPoint(newCenter));
#endif
	visible=MKMapRectMake(newCenter.x-0.5*MKMapRectGetWidth(visible), newCenter.y-0.5*MKMapRectGetHeight(visible), MKMapRectGetWidth(visible), MKMapRectGetHeight(visible));
	[self setVisibleMapRect:visible animated:flag];	// show new map rect
}

- (void) setDelegate:(id <MKMapViewDelegate>) d; { delegate=d; }
- (void) setMapType:(MKMapType) type; { mapType=type; [self setNeedsDisplay:YES]; }

- (void) setRegion:(MKCoordinateRegion) reg;
{
	[self setRegion:reg animated:NO];
}

- (void) setRegion:(MKCoordinateRegion) reg animated:(BOOL) flag;
{
	MKMapRect visible=[self mapRectThatFits:_MKMapRectForCoordinateRegion(reg)];
	[self setVisibleMapRect:visible animated:flag];
}

- (void) setScrollEnabled:(BOOL) flag; { scrollEnabled=flag; }

- (void) setSelectedAnnotation:(NSArray *) a;
{ // copy property
	[annotations autorelease];
	annotations=[a copy];
	// select them all
}

- (void) setShowsUserLocation:(BOOL) flag;
{
	flag = (flag != 0);
	if(showsUserLocation != flag)
		{ // changes
			if((showsUserLocation=flag))
				{
				[delegate mapViewWillStartLocatingUser:self];
				userLocation=[MKUserLocation new];	// create
				[self addAnnotation:userLocation];
				}
			else
				{
				[self removeAnnotation:userLocation];
				[userLocation release];
				userLocation=nil;				
				[delegate mapViewDidStopLocatingUser:self];
				}
		}
}

- (void) setVisibleMapRect:(MKMapRect) rect;
{
#if 1
	NSLog(@"setVisibleMapRect:%@", MKStringFromMapRect(rect));
#endif
	//	rect=[self mapRectThatFits:rect edgePadding:insets];
	// notify delegate
	visibleMapRect=rect;
	// update annotation an overlay views
	[self setNeedsDisplay:YES];
}

- (void) setVisibleMapRect:(MKMapRect) rect animated:(BOOL) flag;
{
	if(flag)
		{
		// animate by defining a timer and the delta
		}
	[self setVisibleMapRect:rect];
}

- (void) setVisibleMapRect:(MKMapRect) rect edgePadding:(UIEdgeInsets) insets animated:(BOOL) flag;
{
	rect=[self mapRectThatFits:rect edgePadding:insets];
	[self setVisibleMapRect:rect animated:flag];
}

- (void) setZoomEnabled:(BOOL) flag; { zoomEnabled=flag; }
- (BOOL) showsUserLocation; { return showsUserLocation; }
- (MKUserLocation *) userLocation; { return userLocation; }

- (MKAnnotationView *) viewForAnnotation:(id <MKAnnotation>) a;
{
	// check queue/cache
	MKAnnotationView *v=[delegate mapView:self viewForAnnotation:a];
	if(!v)
		{ // use default view
			
		}
	return v;
}

- (MKOverlayView *) viewForOverlay:(id <MKOverlay>) o;
{
	// check queue/cache
	MKOverlayView *v=[delegate mapView:self viewForOverlay:o];
	return v;	
}

- (MKMapRect) visibleMapRect; { return visibleMapRect; }

- (void) _scaleBy:(float) factor aroundCenter:(MKMapPoint) center
{
	if(zoomEnabled)
		{
		MKMapRect v=[self visibleMapRect];
		v.size.width *= factor;
		v.size.height *= factor;
		v.origin.x = center.x - factor*(center.x - v.origin.x);		// new left corner (using new size)
		v.origin.y = center.y - factor*(center.y - v.origin.y);		// new bottom corner
		[self setVisibleMapRect:v animated:YES];			
		}
}

- (void) _scaleBy:(float) factor
{
	MKMapRect v=[self visibleMapRect];
	[self _scaleBy:factor aroundCenter:MKMapPointMake(MKMapRectGetMidX(v), MKMapRectGetMidY(v))];	// scale around visible center
}

- (void) _moveByX:(double) x Y:(double) y;
{
	if(scrollEnabled)
		{
		MKMapRect v=[self visibleMapRect];
		v.origin.x += x;
		v.origin.y += y;
		[self setVisibleMapRect:v animated:YES];		
		}
}

- (IBAction) zoomIn:(id) sender;
{
	[self _scaleBy:0.5];
}

- (IBAction) zoomOut:(id) sender;
{
	[self _scaleBy:2.0];
}

- (IBAction) moveLeft:(id) sender;
{
	if(([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0)
		[self _scaleBy:1.0/0.9];
	else
		[self _moveByX:-0.1*[self visibleMapRect].size.width Y:0.0];
}

- (IBAction) moveRight:(id) sender;
{
	if(([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0)
		[self _scaleBy:0.9];
	else
		[self _moveByX:+0.1*[self visibleMapRect].size.width Y:0.0];
}

- (IBAction) moveUp:(id) sender;
{
	if(([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0)
		[self _scaleBy:0.9];
	else
		[self _moveByX:0.0 Y:+0.1*[self visibleMapRect].size.height];
}

- (IBAction) moveDown:(id) sender;
{
	if(([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0)
		[self _scaleBy:1.0/0.9];
	else
		[self _moveByX:0.0 Y:-0.1*[self visibleMapRect].size.height];
}

- (void) scrollWheel:(NSEvent *) event;
{ // scroll or zoom
	if(([event modifierFlags] & NSAlternateKeyMask) != 0)
		{ // soft zoom in/out
			[self _scaleBy:pow(1.1, [event deltaY])];
		}
	else
		{
		NSRect r=(NSRect) { NSZeroPoint, { [event deltaX], [event deltaY] } };	// rect with 1x1 px
		MKMapRect m=[self _mapRectForRect:r];	// get offset
		[self _moveByX:m.size.width Y:m.size.height];
		}
}

- (void) mouseDown:(NSEvent *)theEvent;
{ // we come here only if hitTest of MKAnnotationViews and MKOverlayViews did fail
	NSPoint p0 = [self convertPoint:[theEvent locationInWindow] fromView:nil];	// initial point
	MKMapPoint pnt = [self _mapPointForPoint:p0];	// where did we click on the Mercator map?
	MKMapPoint speed = { 0.0, 0.0 };
#if 1
	CLLocationCoordinate2D latlong=MKCoordinateForMapPoint(pnt);
	NSLog(@"NSControl mouseDown point=%@", NSStringFromPoint(p0));
	NSLog(@"  MKMapPoint %@", MKStringFromMapPoint(pnt));
	NSLog(@"  MKCoordinate %@", [NSString stringWithFormat:@"{lat=%g,lng=%g}", latlong.latitude, latlong.longitude]);
#endif
	if([theEvent clickCount] > 1)
		{ // was a double click - zoom with keeping the clicked point stable
#if 1
			NSLog(@"dbl click event modifier %d", [theEvent modifierFlags]);
#endif
			[self _scaleBy:([theEvent modifierFlags] & NSControlKeyMask) ? 2.0 : 0.5 aroundCenter:pnt];
			return;
		}
	while(YES)
		{
		if([theEvent type] == NSLeftMouseUp)
			{
			if(speed.x || speed.y)
				{ // mouse did go up during movement
				// if we have speed, continue to roll...
				// but we should set up a timer
				// and make the speed an iVar
				// and stop the timer if the mouse is clicked again
				// speed must decrease (linearly?)
				}
			break;
			}
		if([theEvent type] == NSLeftMouseDragged)
			{ // NSMouseDragged
				NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];	// initial point
				MKMapPoint p2 = [self _mapPointForPoint:p];	// where did we drag to on the Mercator map?
				pnt = [self _mapPointForPoint:p0];	// last click on Mercator map (which has been moved!)
				speed.x = pnt.x - p2.x;	// movement vector
				speed.y = pnt.y - p2.y;
				[self _moveByX:speed.x Y:speed.y];
				p0=p;	// remember screen coordinates since the mercator position changes
			}
		theEvent = [NSApp nextEventMatchingMask:(NSLeftMouseUpMask|NSLeftMouseDraggedMask)
									  untilDate:[NSDate distantFuture]						// get next event
										 inMode:NSEventTrackingRunLoopMode 
										dequeue:YES];
		}
}

@end

@implementation MKPlacemark // based on CLPlacemark

- (NSString *) subtitle;
{
	return @"MKPlacemark subtitle";
}

- (NSString *) title;
{
	return @"MKPlacemark title";
}

@end

@implementation MKReverseGeocoder

- (void) cancel;
{
	[geocoder cancelGeocode];
}

- (CLLocationCoordinate2D) coordinate;
{
	return coordinate;
}

- (id <MKReverseGeocoderDelegate>) delegate;
{
	return delegate;
}

- (void) setDelegate:(id <MKReverseGeocoderDelegate>) d;
{
	delegate=d;
}

- (id) initWithCoordinate:(CLLocationCoordinate2D) coord;
{
	if((self=[super init]))
		{
		coordinate=coord;
		}
	return self;
}

- (void) dealloc
{
	[geocoder cancelGeocode];
	[geocoder release];
	[placemark release];
	[super dealloc];
}

- (BOOL) isQuerying;
{
	return [geocoder isGeocoding];
}

- (MKPlacemark *) placemark;
{
	return placemark;
}

- (void) placemarks:(NSArray *) placemarks error:(NSError *) error
{
	if([placemarks count] >= 1)
		{
		placemark=[[placemarks objectAtIndex:0] retain];
		[delegate reverseGeocoder:self didFindPlacemark:placemark];
		}
	else
		[delegate reverseGeocoder:self didFailWithError:error];
}

- (void) start;
{
	if(!geocoder)
		{ // build query and start
			CLLocation *location=[[CLLocation alloc] initWithCoordinate:coordinate
															   altitude:0.0		// sea level
													 horizontalAccuracy:0.0		// exact
													   verticalAccuracy:-1.0	// unknown
															  timestamp:[NSDate date]];	// now
			CLGeocodeCompletionHandler handler=[NSBlockHandler handlerWithDelegate:self action:@selector(placemarks:error:)];
			geocoder=[[CLGeocoder alloc] init];
			[geocoder reverseGeocodeLocation:location completionHandler:handler];
			[location release];
		}
}

@end

