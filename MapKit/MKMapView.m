//
//  MKMapView.m
//  MapKit
//
//  Created by H. Nikolaus Schaller on 20.10.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <MapKit/MapKit.h>


@implementation MKMapView

static MKMapRect worldMap;	// visible map rect at z=0 (topmost tile)

#define TILEPIXELS	256.0

#define CACHESIZE 100

static NSMutableDictionary *imageCache;
static NSMutableArray *imageLRU;

+ (void) initialize
{
	if(self == [MKMapView class])
		{
		MKMapPoint topRight=MKMapPointForCoordinate((CLLocationCoordinate2D) { 85.0, 180.0 });	// CLLocationCoordinate2D is (latitude, longigude) which corresponds to (y, x)
#if 1	// for testing...
		CLLocationCoordinate2D test=MKCoordinateForMapPoint(topRight);
		if(test.latitude != 85.0 || test.longitude != 180.0)
			NSLog(@"conversion error");
#endif
		worldMap.origin=MKMapPointForCoordinate((CLLocationCoordinate2D) { -85.0, -180.0  });
		worldMap.size.width=topRight.x - worldMap.origin.x;
		worldMap.size.height=topRight.y - worldMap.origin.y;
		imageCache=[[NSMutableDictionary alloc] initWithCapacity:CACHESIZE];
		imageLRU=[[NSMutableArray alloc] initWithCapacity:CACHESIZE];
		}
}

- (id) initWithFrame:(NSRect) frameRect
{
	if((self=[super initWithFrame:frameRect]))
		{
		annotations=[[NSMutableArray alloc] initWithCapacity:50];
		overlays=[[NSMutableArray alloc] initWithCapacity:20];
		visibleMapRect=[self mapRectThatFits:worldMap];	// start with world map
		}
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
- (BOOL) isFlipped; { return YES; }

// FIXME: how does resizing modify the visibleMapRect?
// we must overwrite setFrame(Size) and adjust the visibleRect

- (NSString *) tileURLForZ:(int) z x:(int) x y:(int) y;
{
	if(z < 0 || z > 20)
		return nil;
	return [NSString stringWithFormat:@"http://tile.openstreetmap.org/%d/%d/%d.png", z, x, y];
}

- (BOOL) drawTileForZ:(int) z x:(int) x y:(int) y intoRect:(NSRect) rect load:(BOOL) flag;
{
	NSString *url;
	NSRect bounds = [self bounds];
	MKZoomScale scale = MIN(bounds.size.width / TILEPIXELS * worldMap.size.width / visibleMapRect.size.width, bounds.size.height / TILEPIXELS * worldMap.size.height / visibleMapRect.size.height);
	float lscale=log10(scale);	// gives z-Factor
	int z=ceil(lscale);
	int iscale = 1<<z;
	MKMapSize tileSize = (MKMapSize) { worldMap.size.width / iscale, worldMap.size.height / iscale };	// size of single tile (at nominal scale)
	int x, y;
	
	int minx=floor(MKMapRectGetMinX(visibleMapRect) / worldMap.size.width);
	int maxx=ceil(MKMapRectGetMaxX(visibleMapRect) / worldMap.size.width);
	int miny=floor(MKMapRectGetMinY(visibleMapRect) / worldMap.size.height);
	int maxy=ceil(MKMapRectGetMaxY(visibleMapRect) / worldMap.size.height);
	
	NSRect drawRect;
	// draw rect is determined by x, y, z, bounds, worldMap, visibleMapRect
	if(!NSIntersectsRect(drawRect, rect))
		return YES;	// does not fall into drawing rect
	url=[self tileURLForZ:z x:x y:y];
	if(url)
		{
		NSImage *img=[imageCache objectForKey:url];
		if(!img)
			{ // not in cache
				BOOL r=NO;
				if(flag)
					{
					// start tile loader
					// if we add the first tile to load, call [delegate didStartLoading]
					// for each tile that arrives, call setNeedsDisplayInRect:
					// when the last tile arrives, call [delegate didFinishLoading]
					img=[[[NSImage alloc] initByReferencingURL:[NSURL URLWithString:url]] autorelease];
					[imageCache setObject:img forKey:url];
					if([imageLRU count] > CACHESIZE)
						[imageLRU removeLastObject];	// remove least recently used tile
					}
#if 0 // recursion does not work!!!
				// look for a replacement (in z+1 or z-1 direction)
				if(z > 0)
					{ // try covering tile at lower zoom factor
						// double size of rect
						// FIXME: we should be able to move the rect origin but how? Depends on the lsb of x and y
						r |= [self drawTileForZ:z-1 x:x/2 y:y/2 intoRect:rect load:NO];
					}
				if(z < 20)
					{ // try tiles at higher zoom factor
						// split rect into 4 parts
						r |= [self drawTileForZ:z+1 x:2*x y:2*y intoRect:rect load:NO];
						r |= [self drawTileForZ:z+1 x:2*x+1 y:2*y intoRect:rect load:NO];
						r |= [self drawTileForZ:z+1 x:2*x y:2*y+1 intoRect:rect load:NO];
						r |= [self drawTileForZ:z+1 x:2*x+1 y:2*y+1 intoRect:rect load:NO];
					}
				return r;
#endif
			}
		else
			[imageLRU removeObject:img];
		[imageLRU insertObject:img atIndex:0];  // move to beginning of LRU list

		[img drawInRect:drawRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		return YES;
		}
	return NO;
}

- (void) drawRect:(NSRect) rect
{
	NSRect bounds = [self bounds];
	MKZoomScale scale = MIN(bounds.size.width / TILEPIXELS * worldMap.size.width / visibleMapRect.size.width, bounds.size.height / TILEPIXELS * worldMap.size.height / visibleMapRect.size.height);
	float lscale=log10(scale);	// gives z-Factor
	int z=ceil(lscale);
	int iscale = 1<<z;
	MKMapSize tileSize = (MKMapSize) { worldMap.size.width / iscale, worldMap.size.height / iscale };	// size of single tile (at nominal scale)
	int x, y;
	
	int minx=floor(MKMapRectGetMinX(visibleMapRect) / worldMap.size.width);
	int maxx=ceil(MKMapRectGetMaxX(visibleMapRect) / worldMap.size.width);
	int miny=floor(MKMapRectGetMinY(visibleMapRect) / worldMap.size.height);
	int maxy=ceil(MKMapRectGetMaxY(visibleMapRect) / worldMap.size.height);
	// draw background
#if 1
	[@"I am the MKMapView" drawInRect:NSMakeRect(10.0, 10.0, 100.0, 100.0) withAttributes:nil];
	[[annotations description] drawInRect:NSMakeRect(10.0, 50.0, 100.0, 100.0) withAttributes:nil];
#endif	
	minx += floor((NSMinX(rect)) / TILEPIXELS);	// we can skip the first tiles for partial redraw
	maxx -= floor((NSMaxX(bounds) - NSMaxX(rect)) / TILEPIXELS);	// we can skip the last tiles for partial redraw
	miny += floor((NSMinY(rect)) / TILEPIXELS);	// we can skip the first tiles for partial redraw
	maxy -= floor((NSMaxY(bounds) - NSMaxY(rect)) / TILEPIXELS);	// we can skip the last tiles for partial redraw

	for(y = miny; y < maxy; y++)
		{
		for(x = minx; x < maxx; x++)
			{
			NSRect rect = { { 0, 0 }, { TILEPIXELS, TILEPIXELS } };
			rect.origin=bounds.origin;
			rect.origin.x = bounds.origin.x + x*TILEPIXELS;
			rect.origin.y = bounds.origin.y + y*TILEPIXELS;
			[self drawTileForZ:z x:x y:y intoRect:rect load:YES];
			}
		}
	/* draw annotations and overlays (not here - they are handled through subviews) */
}

- (void) addAnnotation:(id <MKAnnotation>) a; { [annotations addObject:a]; [self setNeedsDisplay:YES]; }	// could optimize drawing rect?
- (void) addAnnotations:(NSArray *) a; { [annotations addObjectsFromArray:a]; [self setNeedsDisplay:YES]; }
- (void) addOverlay:(id <MKOverlay>) o; { [overlays addObject:o]; [self setNeedsDisplay:YES]; }
- (void) addOverlays:(NSArray *) o; { [overlays addObjectsFromArray:o]; [self setNeedsDisplay:YES]; }
- (NSArray *) annotations;{ return annotations; }
//- (NSRect) annotationVisibleRect;{ return annotationVisibleRect; }
- (CLLocationCoordinate2D) centerCoordinate; { return MKCoordinateRegionForMapRect(visibleMapRect).center; }
//- (NSPoint) convertCoordinate:(CLLocationCoordinate2D) coord toPointToView:(UIView *) view;
//- (CLLocationCoordinate2D) convertPoint:(NSPoint) point toCoordinateFromView:(UIView *) view;
//- (MKCoordinateRegion) convertRect:(NSRect) coord toRegionFromView:(UIView *) view;
//- (NSRect) convertRegion:(MKCoordinateRegion) region toRectToView:(UIView *) view;
- (id <MKMapViewDelegate>) delegate; { return delegate; }
//- (MKAnnotationView *) equeueReusableAnnotationViewWithIdentifier:(NSString *) ident;

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
	return rect;
}


- (MKMapRect) mapRectThatFits:(MKMapRect) rect edgePadding:(UIEdgeInsets) insets;
{
	return rect;
}

- (MKMapType) mapType; { return mapType; }
- (NSArray *) overlays; { return overlays; }
- (MKCoordinateRegion) region; { return MKCoordinateRegionForMapRect(visibleMapRect); }

- (MKCoordinateRegion) regionThatFits:(MKCoordinateRegion) region;
{
	return region;
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
{ // keep zoom constand andjust move centetr
	MKMapRect visible=visibleMapRect;
	// set new center=MKMapPointForCoordinate(center)
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
	MKMapRect visible;
	reg=[self regionThatFits:reg];	// adjust to aspect ratio
	
	MKMapPointForCoordinate(reg.center);	// get center
	
	// convert span to map rect
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

- (void) setUserLocationVisible:(BOOL) flag; { userLocationVisible=flag; [self setNeedsDisplay:YES]; }

- (void) setVisibleMapRect:(MKMapRect) rect;
{
	visibleMapRect=rect;
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

- (void) _scaleBy:(float) factor
{
	MKMapRect v=[self visibleMapRect];
	v.origin.x += 0.5*v.size.width;		// center
	v.origin.y += 0.5*v.size.height;	// center
	v.size.width *= factor;
	v.size.height *= factor;
	v.origin.x -= 0.5*v.size.width;		// left corner
	v.origin.y -= 0.5*v.size.height;	// bottom corner
	[self setVisibleMapRect:v animated:YES];	
}

- (void) zoomIn:(id) sender;
{
	[self _scaleBy:0.5];
}

- (void) zoomOut:(id) sender;
{
	[self _scaleBy:2.0];
}

- (void) moveLeft:(id) sender;
{
	MKMapRect v=[self visibleMapRect];
	v.origin.x -= 0.1*v.size.width;
	[self setVisibleMapRect:v animated:YES];
}

- (void) moveRight:(id) sender;
{
	MKMapRect v=[self visibleMapRect];
	v.origin.x += 0.1*v.size.width;
	[self setVisibleMapRect:v animated:YES];
}

- (void) moveUp:(id) sender;
{
	MKMapRect v=[self visibleMapRect];
	v.origin.y += 0.1*v.size.height;
	[self setVisibleMapRect:v animated:YES];
}

- (void) moveDown:(id) sender;
{
	MKMapRect v=[self visibleMapRect];
	v.origin.y -= 0.1*v.size.height;
	[self setVisibleMapRect:v animated:YES];
}

- (void) mouseDown:(NSEvent *)theEvent;
{
	NSPoint p0 = [[self superview] convertPoint:[theEvent locationInWindow] fromView:nil];	// initial point
}

- (void) scrollWheel:(NSEvent *) event;
{ // scroll or zoom
	MKMapRect v=[self visibleMapRect];
	if(([event modifierFlags] & NSAlternateKeyMask) != 0)
		{ // zoom
			[self _scaleBy:pow(1.1, [event deltaY])];
			return;
		}
	// convert pixels into MKMapRect coordinates so that we scroll by 1 px
	v.origin.x += 0.1*[event deltaX]*v.size.width;
	v.origin.y += 0.1*[event deltaY]*v.size.height;
	[self setVisibleMapRect:v animated:YES];
}

@end



#if OLD // initial Code taken from Navigator.app

#define WORLD_ZOOM (40077000.0/(0.0254/72))	// earth circumference (40077 km) in pixels (72 per inch)

@interface TileLoader : NSObject
{
	NSURL *_url;
	NSURLConnection *_connection;
	NSMutableData *_data;
	NSImage *_image;
	NSView *_delegate;
}
- (id) initWithContentsOFURL:(NSURL *) url forView:(NSView *) delegate;
- (void) start;
- (NSImage *) image;
@end

@implementation TileLoader

static NSMutableArray *loadQueue;	// TileLoaders to be started
static int alreadyLoading=0;

- (id) initWithContentsOFURL:(NSURL *) url forView:(NSView *) delegate;
{
	if((self=[super init]))
		{
		_delegate=delegate;
		_url=[url retain];
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
		_connection=[[NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:_url] delegate:self] retain];
		[_url release];
		_url=nil;
		[_connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSEventTrackingRunLoopMode];
		alreadyLoading++;
		[loadQueue removeObjectIdenticalTo:self];	// and remove (if we are in the queue)
		}
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if(!_data)
		_data=[data mutableCopy];
	else
		[_data appendData:data];
}

- (void) connection:(NSURLConnection *) connection didFailWithError:(NSError *)error
{
#if 1
	NSLog(@"didFailWithError: %@", error);
#endif
	_image=[[NSImage alloc] initWithSize:NSMakeSize(256.0, 256.0)];	// write error message into a tile
	[_image setFlipped:NO];
	[_image lockFocus];
	[[error localizedDescription] drawInRect:[_image alignmentRect] withAttributes:nil];
	[_image unlockFocus];
	[self connectionDidFinishLoading:connection];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
	[_connection release];
	_connection=nil;
	if(!_image && _data)
		{
		_image=[[NSImage alloc] initWithData:_data];
		[_image setFlipped:YES];
		[_data release];
		_data=nil;
		}
	[_delegate setNeedsDisplay:YES];
	alreadyLoading--;
	NSAssert(alreadyLoading >= 0, @"never become negative");
	if([loadQueue count] > 0)
		{ // start next one
			[[loadQueue lastObject] start];	// will remove self
		}
}

// if we don't have the correct zoom but can get it by zooming...

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
		return nil;	// already loading
	return _image;
}

- (void) dealloc
{
	[_connection cancel];
	[_connection release];
	[_data release];
	[_image release];
	[_url release];
	[super dealloc];
}

@end

/*
 conversion of geo location and zoom into Mapnik tile path
 http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
 */


@interface MapWorldView : NSView	// show the world map
{
	NSMutableDictionary *tileCache;		// image tiles (256x256 PNG)
}

// we should be able to add waypoint and path objects

// should be rescaled if frame bounds are changed!

- (void) addPath:(NSBezierPath *) path;
- (void) addLabel:(NSString *) label atLocation:(GeoLocation) loc;

- (GeoLocation) locationForPoint:(NSPoint) pnt;	// point in our frame coordinates
- (NSPoint) pointForLocation:(GeoLocation) loc;	// our frame coordinates for location

@end

@implementation MapWorldView	// draw 4 worlds - adjusting tile resolution as needed

- (BOOL) isOpaque; { return YES; }
- (BOOL) isFlipped; { return YES; }

- (void) dealloc
{
	[tileCache release];
	[super dealloc];
}

- (NSString *) urlForZ:(int) z x:(int) x y:(int) y;
{
	// make choosable by user
	// may also interpret placeholders in format string...
	// file://opt/local/TP/%d/%d/%d.png to read peutinger tabula...
	return [NSString stringWithFormat:@"http://tile.openstreetmap.org/%d/%d/%d.png", z, x, y];
}

- (void) drawRect:(NSRect) rect
{ // convert rect to be drawn into tiles based on current zoom
	int z=0;
	long z2;
	double tsize;
	double z12;
	NSRect fromRect=NSZeroRect;
	NSRect toRect;
	long tx, ty, ex, ey;
	long x, y;
	NSSize size=[self frame].size;
	double w0=MAX(size.width, size.height);
#if 0
	{ // some test code...
		Geo loc=[self locationForPoint:NSMakePoint(300.0, 234.0)];
		NSLog(@"lat=%f long=%f", loc.latitude, loc.longitude);
		NSLog(@"pnt=%@", NSStringFromPoint([self pointForLocation:loc]));
		exit(1);
	}
#endif
	z2=(int) (w0 / 256.0);	// how many tiles would fit into width...
	while(z2 > 1 && z < 18)
		z++, z2 >>= 1;	// this is definitively faster than using log2()
	z2 = 1 << z;	// how many tiles to really span across the view
	tsize = w0 / (2.0*z2);	// size of one tile
	toRect.size = NSMakeSize(tsize, tsize);
	z12 = 1.0 / tsize;	// reciprocal
	tx = floor(z12*NSMinX(rect));	// scale to tile number
	ty = floor(z12*NSMinY(rect));	// scale to tile number
	ex = ceil(z12*NSMaxX(rect));	// scale to tile number	
	ey = ceil(z12*NSMaxY(rect));	// scale to tile number
	for(y=ty; y<ey; y++)
		{
		for(x=tx; x<ex; x++)
			{ // draw all tiles in given rect
				NSString *u=[self urlForZ:z x:x%z2 y:y%z2];
				//							NSString *u=[NSString stringWithFormat:@"http://tile.openstreetmap.org/%d/%d/%d.png", z, x%z2, y%z2];
				TileLoader *t;
				NSImage *img;
				toRect.origin=NSMakePoint(tsize*x, tsize*y);			// tile drawing origin (must be calculated as double precision!)
				if(!(t=[tileCache objectForKey:u]))
					{ // not yet found
#if 1
						NSLog(@"load from %@", u);
#endif
						if((t=[[TileLoader alloc] initWithContentsOFURL:[NSURL URLWithString:u] forView:self]))		// create new tile loader
							{
							if(!tileCache)
								tileCache=[[NSMutableDictionary alloc] initWithCapacity:15];
							else if([tileCache count] > 1000)
								{
								// remove some less used tiles
								}
							[tileCache setObject:t forKey:u];	// save connection
							[t release];
							}
					}
				img=[t image];
				if(!img)
					{ // still loading
						// we could improve by allowing more than z-1 - so we would need to loop and shift the /2 resp. %2 value in a long variable and calculate the factor 0.5*iSize on the fly
						// do we need that? Has to be tested on a slow internet connection (GPRS)
						if(z > 0)
							{ // try to substitute a lower resolution image
								NSString *u=[self urlForZ:z-1 x:(x%z2)/2 y:(y%z2)/2];
								//													NSString *u=[NSString stringWithFormat:@"http://tile.openstreetmap.org/%d/%d/%d.png", z-1, (x%z2)/2, (y%z2)/2];
								if((img=[[tileCache objectForKey:u] image]))
									{ // exists! Calculate source quadrant to show (define fromRect)
										NSSize iSize=[img size];
										fromRect.size.width=0.5*iSize.width;
										fromRect.size.height=0.5*iSize.height;
										fromRect.origin.x=((x%z2)%2)*fromRect.size.width;
										fromRect.origin.y=((y%z2)%2)*fromRect.size.height;
									}
							}
						if(!img)
							{ // none found
								img=[NSImage imageNamed:@"Loading"];
								[img setFlipped:YES];
							}
					}
				else
					fromRect=NSZeroRect;	// show full image
				[img drawInRect:toRect fromRect:fromRect operation:NSCompositeSourceOver fraction:1.0];	// draw scaled tile
#if 1
				[[NSColor blueColor] set];
				NSFrameRect(toRect);
#endif
			}
		}
}

- (GeoLocation) locationForPoint:(NSPoint) pnt;	// point in our frame coordinates
{ // convert given point into location
	NSSize mapSize=[self frame].size;
	double x = 2.0 * pnt.x / mapSize.width;							// 0 ... +1
	double y = 2.0 * (pnt.y / mapSize.height - 1.0);		// 0 ... +1
	double n;
	GeoLocation loc;
	while(x > 1.0) x-=1.0;
	while(x < 0.0) x+=1.0;
	while(y > 1.0) y-=1.0;
	while(y < 0.0) y+=1.0;
	loc.longitude = (180.0 - x * 360.0);	// +180 ... -180
	n = M_PI - (2.0 * M_PI) * y;	// +PI ... -PI
	loc.latitude = (180.0 / M_PI) * atan(0.5 * (exp(n) - exp(-n)));
	loc.altitude = 0.0;
	return loc;
}

- (NSPoint) pointForLocation:(GeoLocation) loc;	// our frame coordinates for location
{
	NSSize mapSize=[self frame].size;
	double l = loc.latitude * (M_PI / 180.0);		// latitude is limited to approx. +/- 85 deg
	double y = 1.0 - log( tan(l) + 1.0 / cos(l)) / M_PI;
	//	return (int)(floor((1.0 - log( tan(lat * M_PI/180.0) + 1.0 / cos(lat * M_PI/180.0)) / M_PI) / 2.0 * pow(2.0, z))); 
	double x = (180.0 - loc.longitude) / 360.0;
	return NSMakePoint(x*mapSize.width*0.5, y*mapSize.height*0.25);
}

@end

@implementation MapView

- (id) initWithFrame:(NSRect) frame
{
	if((self=[super initWithFrame:frame]))
		{
		_mapWorldView=[[MapWorldView alloc] initWithFrame:frame];
		[self addSubview:_mapWorldView];
		[_mapWorldView release];
		}
	return self;
}

- (void) setFrame:(NSRect) frame
{
	[super setFrame:frame];
	// may adjust bounds so that map center is stabilized
	[[NSNotificationCenter defaultCenter] postNotificationName:MapViewDidChangeNotification object:self];
}

- (void) setFrameOrigin:(NSPoint) frame
{
	[super setFrameOrigin:frame];
	// may adjust bounds so that map center is stabilized
	[[NSNotificationCenter defaultCenter] postNotificationName:MapViewDidChangeNotification object:self];
}

- (void) setFrameSize:(NSSize) frame
{
	[super setFrameSize:frame];
	// may adjust bounds so that map center is stabilized
	[[NSNotificationCenter defaultCenter] postNotificationName:MapViewDidChangeNotification object:self];
}

- (BOOL) acceptsFirstResponder;	{ return YES; }
- (BOOL) isOpaque; { return NO; }
// - (BOOL) isFlipped; { return YES; }
- (BOOL) acceptsFirstMouse:(NSEvent *)theEvent { return YES; }
- (NSView *) hitTest:(NSPoint)aPoint { return self; }	// don't pass to subview

- (NSPoint) center
{
	NSRect bounds=[self bounds];
	return NSMakePoint(NSMidX(bounds), NSMidY(bounds));	// origin + size/2
}

- (void) scrollTo:(NSPoint) center;
{
	NSSize size=[_mapWorldView frame].size;	// document view's size
	NSRect bounds=[self bounds];
	center.x -= bounds.size.width*0.5;
	center.y -= bounds.size.height*0.5;	// define lower left corner
	size.width *= 0.5;
	size.height *= 0.5;
	while(center.x < 0.0)
		center.x += size.width;
	while(center.x > size.width)
		center.x -= size.width;		// keep in boundaries
	while(center.y < 0.0)
		center.y += size.height;
	while(center.y > size.height)
		center.y -= size.height;	// keep in boundaries
	[self setBoundsOrigin:center];
	// we may here cancel some load operations!!!
	[self setNeedsDisplay:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:MapViewDidChangeNotification object:self];
}

- (void) scrollBy:(NSSize) pix;
{ // scroll by pixels and update everything
#if 0
	NSLog(@"scrollBy: %@", NSStringFromSize(pix));
#endif
	if(pix.width != 0.0 || pix.height != 0.0)
		{
		// we could copy pixels and redraw only newly exposed areas
		NSPoint center=[self center];		// current origin
		[self scrollTo:NSMakePoint(center.x + pix.width, center.y + pix.height)];
		}
}

- (GeoLocation) locationForPoint:(NSPoint) pnt;	// point in our frame coordinates
{ // convert given point into location
	NSPoint origin=[self bounds].origin;
	pnt=[_mapWorldView convertPoint:pnt fromView:self];
	// CHECKME for mySTEP: this Cocoa method does NOT account for bounds.origin!
	pnt.x += origin.x;
	pnt.y -= origin.y;
	return [_mapWorldView locationForPoint:pnt];
}

- (GeoLocation) location;
{ // get coordinates of current view in latitude / longitude
	NSRect frame=[self frame];
	return [self locationForPoint:NSMakePoint(NSMidX(frame), NSMidY(frame))];
}

- (void) setLocation:(GeoLocation) loc;	// set center location
{	// apply mercator mapping
	NSRect bounds=[_mapWorldView frame];
	NSPoint pnt=[_mapWorldView pointForLocation:loc];
	pnt.y = bounds.size.height/2.0 - pnt.y;
	// CHECKME for mySTEP: this Cocoa method does NOT account for bounds.origin!
	//	pnt=[_mapWorldView convertPoint:pnt toView:nil];
	[self scrollTo:pnt];
}

- (void) setZoom:(float) zoom;
{ // 1.0 = 1:1 i.e. reality - so a typical zoom factor is 0.0002 i.e. 100m -> 2cm
	NSPoint center=[self center];
	float b;
	float bb;
	if(zoom < 1.0/150000000.0)
		zoom = 1.0/150000000.0;	// make world fit into some cm...
	else if(zoom > 1.0)
		zoom = 1.0;
	b=zoom*(2.0*WORLD_ZOOM);	// but draw 4 earths within our frame
	bb=b/[_mapWorldView frame].size.width;	// scaling factor
	[_mapWorldView setFrameSize:NSMakeSize(b, b)];
	[self scrollTo:NSMakePoint(bb*center.x, bb*center.y)];	// set origin in new coordinates & send notification
}

- (float) zoom;
{
	return [_mapWorldView frame].size.width/(2.0*WORLD_ZOOM);
}

- (void) zoomIn:(id) sender;
{
	[self setZoom:2.0*[self zoom]];
}

- (void) zoomOut:(id) sender;
{
	[self setZoom:0.5*[self zoom]];
}

- (void) moveLeft:(id) sender;
{
	[self scrollBy:NSMakeSize(-20.0, 0)];
}

- (void) moveRight:(id) sender;
{
	[self scrollBy:NSMakeSize(20.0, 0)];
}

- (void) moveUp:(id) sender;
{
	[self scrollBy:NSMakeSize(0, 20.0)];
}

- (void) moveDown:(id) sender;
{
	[self scrollBy:NSMakeSize(0, -20.0)];
}

- (void) mouseDown:(NSEvent *)theEvent;
{
	// NOTE: don't convert to bounds coordinates since they are scaled as needed
	NSPoint p0 = [[self superview] convertPoint:[theEvent locationInWindow] fromView:nil];	// initial point
	while(YES)
		{
		/* FIXME: recognize long-press and popup context menu!
		 menu could do:
		 mark waypoint
		 make center
		 make destination
		 show tile address
		 zoom in
		 zoom out
		 etc.
		 */
		NSEvent *event = [NSApp nextEventMatchingMask:(NSLeftMouseUpMask|NSLeftMouseDraggedMask)
											untilDate:[NSDate distantFuture]						// get next event
											   inMode:NSEventTrackingRunLoopMode 
											  dequeue:YES];
		NSPoint p = [[self superview] convertPoint:[event locationInWindow] fromView:nil];
#if 1
		NSLog(@"NSControl mouseDown point=%@", NSStringFromPoint(p));
#endif
		[self scrollBy:NSMakeSize(p0.x - p.x, p0.y - p.y)];	// follow mouse
		p0 = p;
		if([event type] == NSLeftMouseUp)
			break;	// done
		}
	if([theEvent clickCount] > 1)
		{ // was a double click - center + zoom
#if 0
			NSLog(@"event modifier %d", [theEvent modifierFlags]);
#endif
			if([theEvent modifierFlags] & NSControlKeyMask)
				[self zoomOut:nil];
			else
				{ // move to clicked position
					NSPoint origin=[self bounds].origin;
					NSPoint pnt=[theEvent locationInWindow];
					pnt=[[self superview] convertPoint:pnt fromView:nil];
					// CHECKME for mySTEP: this Cocoa method does NOT account for bounds.origin!
					origin.x += pnt.x;
					origin.y += pnt.y;
					[self scrollTo:origin];
					[self zoomIn:nil];
				}
		}
}

- (void) scrollWheel:(NSEvent *) event;
{
	if(([event modifierFlags] & NSAlternateKeyMask) != 0)
		{ // scroll
			[self setZoom:pow(1.1, [event deltaY])*[self zoom]];
			// could also rotate based on [event deltaX]
			return;
		}
	[self scrollBy:NSMakeSize([event deltaX], [event deltaY])];
}

- (void) drawRect:(NSRect) rect
{
#if 1
	[[NSColor greenColor] set];
	NSRectFill(rect);
#endif
}

- (void) unlockFocus
{ // draw over subviews!
#if 1	// should be a preference
	NSRect bounds=[self bounds];
	[[NSColor yellowColor] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMidX(bounds), NSMinY(bounds)) toPoint:NSMakePoint(NSMidX(bounds), NSMaxY(bounds))];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(bounds), NSMidY(bounds)) toPoint:NSMakePoint(NSMaxX(bounds), NSMidY(bounds))];
#endif
	[super unlockFocus];
}

@end

#endif

