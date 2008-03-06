//
//  PDFPage.h
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on Fri Nov 9 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import "PDFKitPrivate.h"

@implementation PDFPage

// manage annotations

// FIXME: add to PDF object hierarchy -> [_page objectForKey:@"Annots"]

- (NSArray *) annotations; { return _annotations; }

- (void) addAnnotation:(PDFAnnotation *) annotation;
{
	if(![_annotations containsObject:annotation])
		[_annotations addObject:annotation];
}

- (void) removeAnnotation:(PDFAnnotation *) annotation;
{
	[_annotations removeObject:annotation];
}
- (PDFAnnotation *) annotationAtPoint:(NSPoint) point;
{
	// go through annotations and check coordinates
	return nil;
}

- (BOOL) displaysAnnotations; { return _displaysAnnotations; }
- (void) setDisplaysAnnotations:(BOOL) flag; { _displaysAnnotations=flag; }

// get raw text and raw data

- (NSAttributedString *) attributedString;
{
	NSEnumerator *e=[[self _content] objectEnumerator];
	NSMutableAttributedString *result=[[[NSMutableAttributedString alloc] init] autorelease];
	// we can even set some document-wide attributes like margins, page size, ...
	// and even document info like NSTitleDocumentAttribute
	NSMutableDictionary *attrib=[NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSFont systemFontOfSize:12], NSFontAttributeName,
		[NSColor blackColor], NSForegroundColorAttributeName,
		[NSNumber numberWithInt:0], NSSuperscriptAttributeName,
		nil];
	PDFStream *content;
	id llobj=nil;
	id lobj=nil;
#if 1
	NSLog(@"content streams: %@", [self _content]);
#endif
	while((content=[[e nextObject] self]))
		{ // process next content stream
		NSDictionary *resources;
		PDFParser *parser;
		id obj;
		float ts=0.0;
#if 1
		NSLog(@"content: %@", content);
#endif
#if 0
		NSLog(@"decoded: %@", [content data]);
#endif
//		NS_DURING
		resources=[content objectForKey:@"Resources"];
		if(!resources)
			resources=[self _inheritedPageAttribute:@"Resources"];
		parser=[PDFParser parserWithData:[content data]];
			while((obj=[parser _parseObject]))
				{ // process objects
				if([obj isPDFKeyword])
					{ // atom or keyword
#if 0
					NSLog(@"keyword: %@", obj);
#endif
					if([obj isEqualToString:@"BT"]) // begin text
						ts=0.0;
					else if([obj isEqualToString:@"Tf"])
						{
						NSDictionary *dict=[[resources objectForKey:@"Font"] self];
#if 1
						NSLog(@"set Tf = %@", llobj);
						NSLog(@"Fonts: %@", [resources objectForKey:@"Font"]);
#endif
						obj=[[dict objectForKey:[llobj value]] self];
						NSLog(@"set Tf = %@", obj);
						[attrib setObject:[NSFont systemFontOfSize:[lobj floatValue]] forKey:NSFontAttributeName];
						}
					else if([obj isEqualToString:@"Ts"])
						[attrib setObject:[NSNumber numberWithInt:[lobj intValue]] forKey:NSSuperscriptAttributeName];
					// process stroke/fill color to change NSForegroundColorAttributeName
					else if([obj isEqualToString:@"Tj"] || [obj isEqualToString:@"'"] || [obj isEqualToString:@"\""])
						{
						NSAttributedString *str=[[NSAttributedString alloc] initWithString:[lobj stringByAppendingString:@"\n"] attributes:attrib];
						[result appendAttributedString:str];
						}
					else if([obj isEqualToString:@"TJ"])
						{ // array TJ - array contains strings and numbers - numbers are offsets
						NSEnumerator *es=[lobj objectEnumerator];
						NSAttributedString *astr;
						while((obj=[es nextObject]))
							{
#if 0
							NSLog(@"TJ: %@", obj);
#endif
							if([obj isKindOfClass:[NSString class]])
								{ // append string
								astr=[[NSAttributedString alloc] initWithString:obj attributes:attrib];
								[result appendAttributedString:astr];
								}
							}
						astr=[[NSAttributedString alloc] initWithString:@"\n" attributes:attrib];
						[result appendAttributedString:astr];
						}
					// ignore all others
					}
				llobj=lobj;
				lobj=obj;
				}
//		NS_HANDLER
//			NSLog(@"attributedString: %@", localException);	// ignore
//		NS_ENDHANDLER
		}
	return result;
}

- (NSString *) string; { return [[self attributedString] string]; }
- (unsigned) numberOfCharacters; { return [[self string] length]; }

- (NSData *) dataRepresentation;
{ // create PDF-1.4 document for just this page
	NSLog(@"content=%@", [self _content]);	// may be array of indirect objects
	return nil;
}

	// handle document

- (PDFDocument *) document; { return _document; }

- (NSMutableDictionary *) _page; { return _page; }

- (NSArray *) _content;
{
	id content=[[_page objectForKey:@"Contents"] self];
	if(!content)
		return [NSArray array];	// no content - empty page
	if([content isKindOfClass:[NSArray class]])
		return content;	// should be array of streams
	return [NSArray arrayWithObject:content];	// single stream object
}

- (id) _initWithDocument:(PDFDocument *) document andPageDictionary:(NSMutableDictionary *) page;
{
	if(!document || !page)
		{
		[self release];
		return nil;
		}
	if((self=[self initWithDocument:document]))
		{
		_page=[page retain];	// page attributes/values
#if 1
		NSLog(@"initialized: %@", self);
#endif
		}
	return self;
}

- (id) initWithDocument:(PDFDocument *) document;
{ // may be overridden in subclasses
	if((self=[super init]))
		{
		_document=[document retain];
		}
	return self;
}

- (NSString *) description;
{
/*
	Page 1; label = 2
		media (0.0, 0.0) [595.0, 842.0]
		crop (0.0, 0.0) [595.0, 842.0]
		rot 0
		'RŸckrufe von Personenwagen  D...'
 */
	unsigned i=[_document indexForPage:self];
	return [NSString stringWithFormat:@"%@ %d: Label=%@", NSStringFromClass([self class]), i, [self label]];
}

- (void) dealloc;
{
	[_annotations release];
	[_page release];
	[_document release];
	[super dealloc];
}

- (NSString *) label;
{
	unsigned i=[_document indexForPage:self];
	id lbl;
	if(i == NSNotFound)
		return nil;
	lbl=[[_document _root] objectForKey:@"PageLabels"];
	if(lbl)
		{ // page lables tree exists
		lbl=[[lbl self] _objectAtIndexInNumberTree:i];
		if(lbl)
			return [lbl self];	// fetch
		}
	return [NSString stringWithFormat:@"%u", i+1];	// substitute for older PDF versions
}

// drawing

- (void) drawWithBox:(PDFDisplayBox) box;
{
	NSEnumerator *e=[[self _content] objectEnumerator];
	PDFStream *content;
	PDFParser *parser;
	NSDictionary *resources;
	id obj;
	NSMutableArray *arg=[NSMutableArray arrayWithCapacity:10];
	NSMutableArray *gstack=[[NSMutableArray alloc] initWithCapacity:10];	// graphics state stack
	int compat=0;				// compatibility mode
	NSBezierPath *path=[NSBezierPath bezierPath];	// current path
	NSFont *font=[NSFont systemFontOfSize:12];	// default font
	NSAffineTransform *tm=nil;	// text matrix
	NSAffineTransform *tlm=nil;
	float tc=0.0;
	float tw=0.0;
	float tz=1.0;
	float tl=0.0;
	float ts=0.0;
	// initialize defaults (which color space??)
	NSColor *strokeColor=[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0];		// default color
	NSColor *fillColor=[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0];
#if 0
	NSLog(@"content streams: %@", [self _content]);
#endif
	[strokeColor setStroke];
	[fillColor setFill];
	// handle rotation, i.e. modify the inital transformation matrix
	// how to use the displayBox? initialize clipping path?
	while((content=[e nextObject]))
		{ // process all content streams
#if 1
		NSLog(@"content: %@", content);
#endif
		NS_DURING
			content=[content self];	// fetch 
#if 0
			NSLog(@"decoded: %@", [content data]);
#endif
			resources=[content objectForKey:@"Resources"];
			if(!resources)
				resources=[self _inheritedPageAttribute:@"Resources"];
#if 0
			NSLog(@"resources=%@", resources);
#endif
			parser=[PDFParser parserWithData:[content data]];
			while((obj=[parser _parseObject]))
				{ // process objects
				unsigned argc=[arg count];	// number of arguments
				if([obj isPDFKeyword])
					{ // atom or keyword
					/*
					 FIXME: the compare methods should be optimized, e.g. by
					 - have most probable and fastest running keywords coming first
					 - or use an NSDict to map to method calls?
					 */
#if 0
					NSLog(@"keyword: %@", obj);
#endif
					if([obj isEqualToString:@"BX"])
						compat++;
					else if(compat > 0 && [obj isEqualToString:@"EX"])
						compat--;
					else if([obj isEqualToString:@"q"])
						{
						[gstack addObject:path];
						path=[[path copy] autorelease];
						[path removeAllPoints];	// start a fresh path that inherits all attributes
						[NSGraphicsContext saveGraphicsState];	// push graphics state - fill/stroke color etc. (everything which understands 'set')
#if 0
						NSLog(@"q -> %d", [gstack count]);
#endif
						}
					else if([obj isEqualToString:@"Q"])
						{
#if 0
						NSLog(@"Q <- %d", [gstack count]);
#endif
						if([gstack count] == 0)
							{
							NSLog(@"Q: empty stack!");
							continue;	// ignore
							}
						path=[gstack lastObject];
						[gstack removeLastObject];	// pull
						[NSGraphicsContext restoreGraphicsState];
						}
					else if(argc == 6 && [obj isEqualToString:@"cm"])
						{
						NSAffineTransformStruct str=
							{
							[[arg objectAtIndex:0] floatValue],
							[[arg objectAtIndex:1] floatValue],
							[[arg objectAtIndex:2] floatValue],
							[[arg objectAtIndex:3] floatValue],
							[[arg objectAtIndex:4] floatValue],
							[[arg objectAtIndex:5] floatValue]
							};
						static NSAffineTransform *ctm;
						if(!ctm) ctm=[[NSAffineTransform alloc] init];
#if 0
						NSLog(@"set ctm=%@", arg);
#endif
						[ctm setTransformStruct:str];
#if 1
						NSLog(@"ctm=%@", ctm);
#endif
						[ctm concat];	// combine in the NSGraphicsContext
						}
					else if(argc == 1 && [obj isEqualToString:@"w"])
						[path setLineWidth:[[arg objectAtIndex:0] floatValue]];	// convert from user space coords to points
					else if(argc == 1 && [obj isEqualToString:@"J"])
						[path setLineCapStyle:[[arg objectAtIndex:0] intValue]];
					else if(argc == 1 && [obj isEqualToString:@"j"])
						[path setLineJoinStyle:[[arg objectAtIndex:0] intValue]];
					else if(argc == 1 && [obj isEqualToString:@"M"])
						[path setMiterLimit:[[arg objectAtIndex:0] floatValue]];
					else if(argc == 2 && [obj isEqualToString:@"d"])
						{
						NSArray *pattern=[arg objectAtIndex:0];
						unsigned int i, cnt=[pattern count];	// number of elements
						float *pat=(float *) malloc(cnt*sizeof(pat[0]));
						if(pat != NULL)
							{
							for(i=0; i<cnt; i++)
								pat[i]=[[pattern objectAtIndex:i] floatValue]; // extract values 
							[path setLineDash:pat count:cnt phase:[[arg objectAtIndex:1] floatValue]];
							free(pat);
							}
						}
					else if(argc == 1 && [obj isEqualToString:@"i"])
						[path setFlatness:[[arg objectAtIndex:0] floatValue]];
					else if(argc == 1 && [obj isEqualToString:@"ri"])
						{
						NSLog(@"%@ ri", arg);
						// arg ri - color rendering intent
						}
					else if(argc == 1 && [obj isEqualToString:@"gs"])
						{
						NSDictionary *dict=[[resources objectForKey:@"ExtGState"] self];
#if 0
						NSLog(@"set gs from = %@", [arg objectAtIndex:0]);
						NSLog(@"ExtGStates: %@", [resources objectForKey:@"ExtGState"]);
#endif
						dict=[[dict objectForKey:[[arg objectAtIndex:0] value]] self];
#if 1
						NSLog(@"set gs = %@", obj);
#endif
						if((obj=[dict objectForKey:@"LW"])) [path setLineWidth:[obj floatValue]];
//						if((obj=[dict objectForKey:@"LC"])) [path setLineCapStyle:[obj intValue]];
						if((obj=[dict objectForKey:@"SA"])) NSLog(@"SA=%@", obj);
//						if((obj=[dict objectForKey:@"SM"])) [path setFlatness:[obj floatValue]];
						}
					else if(argc == 2 && [obj isEqualToString:@"m"])
						{
						[path moveToPoint:NSMakePoint([[arg objectAtIndex:0] floatValue], [[arg objectAtIndex:1] floatValue])];
#if 0
						NSLog(@"%@ %@: path %@", arg, obj, path);
#endif
						}
					else if(argc == 2 && [obj isEqualToString:@"l"])
						{
						if([path isEmpty])	// some bad file might start with l
							{
							NSLog(@"PDF warning: path should not start with l");
							[path moveToPoint:NSMakePoint([[arg objectAtIndex:0] floatValue], [[arg objectAtIndex:1] floatValue])];
							}
						else
							[path lineToPoint:NSMakePoint([[arg objectAtIndex:0] floatValue], [[arg objectAtIndex:1] floatValue])];
#if 0
						NSLog(@"%@ %@: path %@", arg, obj, path);
#endif
						}
					else if(argc == 6 && [obj isEqualToString:@"c"])
						{
						[path curveToPoint:NSMakePoint([[arg objectAtIndex:4] floatValue], [[arg objectAtIndex:5] floatValue])
							 controlPoint1:NSMakePoint([[arg objectAtIndex:0] floatValue], [[arg objectAtIndex:1] floatValue])
							 controlPoint2:NSMakePoint([[arg objectAtIndex:2] floatValue], [[arg objectAtIndex:3] floatValue])
							];
#if 0
						NSLog(@"%@ %@: path %@", arg, obj, path);
#endif
						}
					else if(argc == 4 && [obj isEqualToString:@"v"])
						{
						[path curveToPoint:NSMakePoint([[arg objectAtIndex:2] floatValue], [[arg objectAtIndex:3] floatValue])
							 controlPoint1:[path currentPoint]
							 controlPoint2:NSMakePoint([[arg objectAtIndex:0] floatValue], [[arg objectAtIndex:1] floatValue])
							];
#if 0
						NSLog(@"%@ %@: path %@", arg, obj, path);
#endif
						}
					else if(argc == 4 && [obj isEqualToString:@"v"])
						{
						NSPoint xy3=NSMakePoint([[arg objectAtIndex:2] floatValue], [[arg objectAtIndex:3] floatValue]);
						[path curveToPoint:xy3
							 controlPoint1:NSMakePoint([[arg objectAtIndex:0] floatValue], [[arg objectAtIndex:1] floatValue])
							 controlPoint2:xy3
							];
#if 0
						NSLog(@"%@ %@: path %@", arg, obj, path);
#endif
						}
					else if(argc == 0 && [obj isEqualToString:@"h"])
						{
						[path closePath];
#if 0
						NSLog(@"%@ %@: path %@", arg, obj, path);
#endif
						}
					else if(argc == 4 && [obj isEqualToString:@"re"])
						{
						[path appendBezierPathWithRect:
							NSMakeRect([[arg objectAtIndex:0] floatValue],
									   [[arg objectAtIndex:1] floatValue],
									   [[arg objectAtIndex:2] floatValue],
									   [[arg objectAtIndex:3] floatValue])];
#if 0
						NSLog(@"%@ %@: path %@", arg, obj, path);
#endif
						}
					else if(argc == 0 && [obj isEqualToString:@"S"])
						{
#if 0
						NSLog(@"%@ %@: path %@", arg, obj, path);
#endif
						[path stroke];
						[path removeAllPoints];
						}
					else if(argc == 0 && [obj isEqualToString:@"s"])
						{
#if 0
						NSLog(@"%@ %@: path %@", arg, obj, path);
#endif
						[path closePath];
						[path stroke];
						[path removeAllPoints];
						}
					else if(argc == 0 && ([obj isEqualToString:@"f"] || [obj isEqualToString:@"F"]))
						{
#if 0
						NSLog(@"%@ %@: path %@", arg, obj, path);
#endif
						[path setWindingRule:NSNonZeroWindingRule];
						[path fill];
						[path removeAllPoints];
						}
					else if(argc == 0 && [obj isEqualToString:@"f*"])
						{
#if 0
						NSLog(@"%@ %@: path %@", arg, obj, path);
#endif
						[path setWindingRule:NSEvenOddWindingRule];
						[path fill];
						[path removeAllPoints];
						}
					else if(argc == 0 && [obj isEqualToString:@"B"])
						{
#if 0
						NSLog(@"%@ %@: path %@", arg, obj, path);
#endif
						[path stroke];
						[path setWindingRule:NSNonZeroWindingRule];
						[path fill];
						[path removeAllPoints];
						}
					else if(argc == 0 && [obj isEqualToString:@"B*"])
						{
#if 0
						NSLog(@"%@ %@: path %@", arg, obj, path);
#endif
						[path stroke];
						[path setWindingRule:NSEvenOddWindingRule];
						[path fill];
						[path removeAllPoints];
						}
					else if(argc == 0 && [obj isEqualToString:@"b"])
						{
#if 0
						NSLog(@"%@ %@: path %@", arg, obj, path);
#endif
						[path closePath];
						[path stroke];
						[path setWindingRule:NSNonZeroWindingRule];
						[path fill];
						[path removeAllPoints];
						}
					else if(argc == 0 && [obj isEqualToString:@"b*"])
						{
#if 0
						NSLog(@"%@ %@: path %@", arg, obj, path);
#endif
						[path closePath];
						[path stroke];
						[path setWindingRule:NSEvenOddWindingRule];
						[path fill];
						[path removeAllPoints];
						}
					else if(argc == 0 && [obj isEqualToString:@"n"])
						{
#if 0
						NSLog(@"n");
#endif
						[path removeAllPoints];
						}
					else if(argc == 0 && [obj isEqualToString:@"W"])
						{
#if 0
						NSLog(@"W clip: %@", path);
#endif
						[path setWindingRule:NSNonZeroWindingRule];
						[path addClip];
						// FIXME: should we save a copy?
						// should postpone until after we have stroked next time?
						}
					else if(argc == 0 && [obj isEqualToString:@"W*"])
						{
#if 0
						NSLog(@"W* clip: %@", path);
#endif
						[path setWindingRule:NSEvenOddWindingRule];
						[path setClip];
						}
					// set stroking colors
					else if(argc == 1 && [obj isEqualToString:@"CS"])
						{
						if([obj isEqualToString:@"DeviceGray"])
							strokeColor=[NSColor colorWithDeviceWhite:0.0 alpha:1.0];		// current color;
						else if([obj isEqualToString:@"DeviceRGB"])
							strokeColor=[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0];		// current color;
						else if([obj isEqualToString:@"DeviceCMYK"])
							strokeColor=[NSColor colorWithDeviceCyan:0.0 magenta:0.0 yellow:0.0 black:0.0 alpha:1.0];		// current color;
						else if([obj isEqualToString:@"Pattern"])
							NSLog(@"%@ CS", obj);
						else
							NSLog(@"%@ CS", obj) /* look into ColorSpace subdictionary */;
						[strokeColor setStroke];
						}
					else if(argc == 1 && [obj isEqualToString:@"cs"])
						{
						if([obj isEqualToString:@"DeviceGray"])
							fillColor=[NSColor colorWithDeviceWhite:0.0 alpha:1.0];		// current color;
						else if([obj isEqualToString:@"DeviceRGB"])
							fillColor=[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0];		// current color;
						else if([obj isEqualToString:@"DeviceCMYK"])
							fillColor=[NSColor colorWithDeviceCyan:0.0 magenta:0.0 yellow:0.0 black:0.0 alpha:1.0];		// current color;
						else if([obj isEqualToString:@"Pattern"])
							NSLog(@"%@ cs", obj);
						else
							NSLog(@"%@ cs", obj) /* look into ColorSpace subdictionary */;
						[fillColor setFill];
						}
					else if([obj isEqualToString:@"SC"])
						{ // #args depends on color space
						obj=[strokeColor colorSpaceName];
						if(argc == 1 && [obj isEqualToString:@"NSDeviceWhiteColorSpace"])
							strokeColor=[NSColor colorWithDeviceWhite:[[arg objectAtIndex:0] floatValue]
																alpha:1.0];		// current color;
						else if(argc == 3 && [obj isEqualToString:@"NSDeviceRGBColorSpace"])
							strokeColor=[NSColor colorWithDeviceRed:[[arg objectAtIndex:0] floatValue]
															  green:[[arg objectAtIndex:1] floatValue]
															   blue:[[arg objectAtIndex:2] floatValue]
															  alpha:1.0];		// current color;
						else if(argc == 4 && [obj isEqualToString:@"NSDeviceCMYKColorSpace"])
							strokeColor=[NSColor colorWithDeviceCyan:[[arg objectAtIndex:0] floatValue] 
															 magenta:[[arg objectAtIndex:1] floatValue]
															  yellow:[[arg objectAtIndex:2] floatValue]
															   black:[[arg objectAtIndex:3] floatValue]
															   alpha:1.0];		// current color;
						else
							NSLog(@"unknown color space for %@ SC: %@", arg, obj);
						[strokeColor setStroke];
						}
					else if([obj isEqualToString:@"sc"])
						{ // argc depends on color space
						// we might also try to deduce the color space from argc!
						obj=[fillColor colorSpaceName];
						if(argc == 1 && [obj isEqualToString:@"NSDeviceWhiteColorSpace"])
							fillColor=[NSColor colorWithDeviceWhite:[[arg objectAtIndex:0] floatValue]
															  alpha:1.0];		// current color;
						else if(argc == 3 && [obj isEqualToString:@"NSDeviceRGBColorSpace"])
							fillColor=[NSColor colorWithDeviceRed:[[arg objectAtIndex:0] floatValue]
															green:[[arg objectAtIndex:1] floatValue]
															 blue:[[arg objectAtIndex:2] floatValue]
															alpha:1.0];		// current color;
						else if(argc == 4 && [obj isEqualToString:@"NSDeviceCMYKColorSpace"])
							fillColor=[NSColor colorWithDeviceCyan:[[arg objectAtIndex:0] floatValue] 
														   magenta:[[arg objectAtIndex:1] floatValue]
															yellow:[[arg objectAtIndex:2] floatValue]
															 black:[[arg objectAtIndex:3] floatValue]
															 alpha:1.0];		// current color;
						else
							NSLog(@"unknown color space for %@ sc: %@", arg, obj);
						[fillColor setStroke];
						}
					else if(argc == 3 && [obj isEqualToString:@"RG"])
						[strokeColor=[NSColor colorWithDeviceRed:[[arg objectAtIndex:0] floatValue]
														   green:[[arg objectAtIndex:1] floatValue]
															blue:[[arg objectAtIndex:2] floatValue]
														   alpha:1.0] setStroke];		// current color;
					else if(argc == 3 && [obj isEqualToString:@"rg"])
						[fillColor=[NSColor colorWithDeviceRed:[[arg objectAtIndex:0] floatValue]
														 green:[[arg objectAtIndex:1] floatValue]
														  blue:[[arg objectAtIndex:2] floatValue]
														 alpha:1.0] setFill];		// current color;
					else if(argc == 1 && [obj isEqualToString:@"G"])
						[strokeColor=[NSColor colorWithDeviceWhite:[[arg objectAtIndex:0] floatValue]
															 alpha:1.0] setStroke];		// current color;
					else if(argc == 1 && [obj isEqualToString:@"g"])
						[fillColor=[NSColor colorWithDeviceWhite:[[arg objectAtIndex:0] floatValue]
														   alpha:1.0] setFill];		// current color;
					else if(argc == 4 && [obj isEqualToString:@"K"])
						[strokeColor=[NSColor colorWithDeviceCyan:[[arg objectAtIndex:0] floatValue] 
														  magenta:[[arg objectAtIndex:1] floatValue]
														   yellow:[[arg objectAtIndex:2] floatValue]
															black:[[arg objectAtIndex:3] floatValue]
															alpha:1.0] setStroke];		// current color;
					else if(argc == 4 && [obj isEqualToString:@"k"])
						[fillColor=[NSColor colorWithDeviceCyan:[[arg objectAtIndex:0] floatValue] 
														magenta:[[arg objectAtIndex:1] floatValue]
														 yellow:[[arg objectAtIndex:2] floatValue]
														  black:[[arg objectAtIndex:3] floatValue]
														  alpha:1.0] setFill];		// current color;
					else if(argc == 0 && [obj isEqualToString:@"BT"])
						{ // begin text - init Tm, Tlm to identity matrix
						tm=[NSAffineTransform transform];
						tlm=[NSAffineTransform transform];
						tc=0.0;
						tw=0.0;
						tz=1.0;
						tl=0.0;
						ts=0.0;
						}
					else if(argc == 0 && [obj isEqualToString:@"ET"])
						{ // end text - discard Tm, Tlm
						tm=tlm=nil;
						}
					else if(argc == 2 && [obj isEqualToString:@"Tf"])
						{
						NSDictionary *dict=[[resources objectForKey:@"Font"] self];
#if 0
						NSLog(@"set Tf = %@", [arg objectAtIndex:0]);
						NSLog(@"Fonts: %@", [resources objectForKey:@"Font"]);
#endif
						obj=[[dict objectForKey:[[arg objectAtIndex:0] value]] self];
						[[obj objectForKey:@"FontDescriptor"] self];	// fetch
						NSLog(@"set Tf = %@", obj);
						// update
						// font=[self _getFont:obj];	// translate
						}
					else if(argc == 1 && [obj isEqualToString:@"Tc"])
						tc=[[arg objectAtIndex:0] floatValue];
					else if(argc == 1 && [obj isEqualToString:@"Tw"])
						tw=[[arg objectAtIndex:0] floatValue];
					else if(argc == 1 && [obj isEqualToString:@"Tz"])
						tz=[[arg objectAtIndex:0] floatValue]*0.01;
					else if(argc == 1 && [obj isEqualToString:@"TL"])
						tl=[[arg objectAtIndex:0] floatValue];
					else if(argc == 1 && [obj isEqualToString:@"Ts"])
						ts=[[arg objectAtIndex:0] floatValue];
					else if(argc == 1 && [obj isEqualToString:@"Tj"])
						NSLog(@"string: %@", [arg objectAtIndex:0]);
					else if(argc == 1 && [obj isEqualToString:@"'"])
						{
						/* do T* first */
						NSLog(@"string: %@", [arg objectAtIndex:0]);
						}
					else if(argc == 3 && [obj isEqualToString:@"\""])
						{
						tw=[[arg objectAtIndex:0] floatValue];
						tc=[[arg objectAtIndex:1] floatValue];
						/* do T* first */
						NSLog(@"string: %@", [arg objectAtIndex:2]);
						}
					else if(argc == 2 && [obj isEqualToString:@"Td"])
						; // x y Td move to start of next line with given offsets
					else if(argc == 2 && [obj isEqualToString:@"TD"])
						{
						tl=-[[arg objectAtIndex:1] floatValue];
						; // do x y Td
						}
					else if(argc == 6 && [obj isEqualToString:@"Tm"])
						{
						NSAffineTransformStruct str=
						{
							[[arg objectAtIndex:0] floatValue],
							[[arg objectAtIndex:1] floatValue],
							[[arg objectAtIndex:2] floatValue],
							[[arg objectAtIndex:3] floatValue],
							[[arg objectAtIndex:4] floatValue],
							[[arg objectAtIndex:5] floatValue]
						};
						[tm setTransformStruct:str];
#if 1
						NSLog(@"Tm=%@", tm);
#endif
						}
					else if(argc == 1 && [obj isEqualToString:@"TJ"])
						{ // array TJ - array contains strings and numbers - numbers are offsets
						NSEnumerator *es=[[arg objectAtIndex:0] objectEnumerator];
						while((obj=[es nextObject]))
							{
							if([obj isKindOfClass:[NSNumber class]])
								;	// move horizontal
							else
								NSLog(@"string: %@", obj);							
							}
						}
					else if(argc == 1 && [obj isEqualToString:@"Tr"])
						NSLog(@"%@ Tr", arg); // int Tr - set text rendering mode
					else if(argc == 0 && [obj isEqualToString:@"T*"])
						NSLog(@"%@ T*", arg); // T* - move to start of next line (xoff=0, yoff=TL)
					else if(argc == 1 && [obj isEqualToString:@"Do"])
						{ // draw object
						Class imgClass;
						NSData *data;
						NSDictionary *dict=[[resources objectForKey:@"XObject"] self];
#if 0
						NSLog(@"draw object %@", [arg objectAtIndex:0]);
						NSLog(@"Fonts: %@", [resources objectForKey:@"XObject"]);
#endif
						obj=[[dict objectForKey:[[arg objectAtIndex:0] value]] self];
#if 1
						NSLog(@"draw object %@", obj);
#endif
						data=[obj decode];
						imgClass=[NSImageRep imageRepClassForData:data];	// decode from stream
						if(!imgClass)
							NSLog(@"can't draw object %@", [arg objectAtIndex:0]);
						else
							{
							NSImageRep *rep;
							rep=[imgClass imageRepWithData:data];
							[rep draw];
							// if successful, we should cache the imagerep so that we don't need the stream again
							}
						}
					else if(compat == 0)
						{ // unknown keyword - and not bracketed by BX/EX
						NSLog(@"unknown keyword %@ %@", arg, obj);
						}
					[arg removeAllObjects];	// clear stack
					}
				else
					{
#if 0
					NSLog(@"arg: %@", obj);
#endif
					[arg addObject:obj];
					}
				}
			NS_HANDLER
				NSLog(@"drawWithBox: %@ %@", localException, path);	// ignore
			NS_ENDHANDLER
		}
	[gstack release];
	if(_displaysAnnotations)
		{ // draw them as well
		}
}

- (int) rotation; { return [[self _inheritedPageAttribute:@"Rotation"] intValue]; }
- (void) setRotation:(int) angle;
{
	// check for valid rotation values - must be pos/neg multiple of 90
	[_page setObject:[NSNumber numberWithInt:angle] forKey:@"Rotation"];
	[self _touch];
}

	// finding/selecting elements

- (NSRect) boundsForBox:(PDFDisplayBox) box
{
	NSArray *bx=nil;
	if(box == kPDFDisplayBoxArtBox)
		bx=[self _inheritedPageAttribute:@"ArtBox"];
	else if(box == kPDFDisplayBoxTrimBox)
		bx=[self _inheritedPageAttribute:@"TrimBox"];
	else if(box == kPDFDisplayBoxBleedBox)
		bx=[self _inheritedPageAttribute:@"BleedBox"];
	else if(!bx || box == kPDFDisplayBoxCropBox)
		bx=[self _inheritedPageAttribute:@"CropBox"];
	else if(!bx || box == kPDFDisplayBoxMediaBox)
		bx=[self _inheritedPageAttribute:@"MediaBox"];
	if(!bx)
		;	// exception - still not defined
	// do we need to handle rotation?
	return NSMakeRect([[bx objectAtIndex:0] floatValue], [[bx objectAtIndex:1] floatValue], [[bx objectAtIndex:2] floatValue], [[bx objectAtIndex:3] floatValue]);
}

- (void) setBounds:(NSRect) bounds forBox:(PDFDisplayBox) box;
{
	NSString *key;
	switch(box)
		{
		case kPDFDisplayBoxMediaBox: key=@"MediaBox"; break;
		case kPDFDisplayBoxCropBox: key=@"CropBox"; break;
		case kPDFDisplayBoxBleedBox: key=@"BleedBox"; break;
		case kPDFDisplayBoxTrimBox: key=@"TrimBox"; break;
		case kPDFDisplayBoxArtBox: key=@"ArtBox"; break;
		default:
			// error
			return;
		}
	if(box != kPDFDisplayBoxMediaBox && NSIsEmptyRect(bounds))
		[_page removeObjectForKey:key];
	else
		[_page setObject:[NSArray arrayWithObjects:
			[NSNumber numberWithFloat:bounds.origin.x],
			[NSNumber numberWithFloat:bounds.origin.y],
			[NSNumber numberWithFloat:bounds.size.width],
			[NSNumber numberWithFloat:bounds.size.height],
			nil] forKey:key];
	[self _touch];
}

- (NSRect) characterBoundsAtIndex:(int) index; { NIMP; return NSZeroRect; }
- (int) characterIndexAtPoint:(NSPoint) point; { NIMP; return 0; }

- (PDFSelection *) selectionForLineAtPoint:(NSPoint) point; { NIMP; return nil; }
- (PDFSelection *) selectionForRange:(NSRange) range; { NIMP; return nil; }
- (PDFSelection *) selectionForRect:(NSRect) rect; { NIMP; return nil; }
- (PDFSelection *) selectionForWordAtPoint:(NSPoint) point; { NIMP; return nil; }
- (PDFSelection *) selectionFromPoint:(NSPoint) start toPoint:(NSPoint) end; { NIMP; return nil; }

- (void) _touch; { [_document _touch]; }

- (id) _inheritedPageAttribute:(NSString *) str;
{
	NSDictionary *dict=[_page self];
	while(dict)
		{
		id val=[[dict objectForKey:str] self];
		if(val)
			return val;	// is defined here
		dict=[[dict objectForKey:@"Parent"] self];	// go up one level
		}
	return nil;	// defined nowhere (might be an error - or substitute default)
}

@end