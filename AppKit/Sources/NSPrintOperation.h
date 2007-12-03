/* 
   NSPrintOperation.h

   Controls operations generating EPS or PS print jobs.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   H.N.Schaller, Jan 2006 - API revised to be compatible to 10.4

   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	03. December 2007 - aligned with 10.5 
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSPrintOperation
#define _mySTEP_H_NSPrintOperation

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

@class NSString;
@class NSData;
@class NSMutableData;
@class NSView;
@class NSPrintInfo;
@class NSPrintPanel;
@class NSGraphicsContext;
@class NSProgressIndicator;
@class NSTextField;

typedef enum _NSPrintingPageOrder
{
	NSDescendingPageOrder,
	NSSpecialPageOrder,
	NSAscendingPageOrder,
	NSUnknownPageOrder
} NSPrintingPageOrder;

extern NSString *NSPrintOperationExistsException;

@interface NSPrintOperation : NSObject
{
	IBOutlet NSWindow *_progressPanel;
	IBOutlet NSProgressIndicator *_progressIndicator;
	IBOutlet NSTextField *_progessMessage;
	NSView *_accessoryView;
	NSPrintInfo *_printInfo;
	NSPrintPanel *_printPanel;
	NSGraphicsContext *_context;
	NSString *_jobStyleHint;
	NSMutableData *_data;	// if we want to save to NSData
	NSString *_path;		// if we want to save to file
	NSView *_view;			// view to print
	NSRect _insideRect;		// rectangle
	int _currentPage;		// current page number
	NSPrintingPageOrder _pageOrder;
	BOOL _cancelled;
	BOOL _success;
	BOOL _canSpawnSeparateThread;
	BOOL _showPrintPanel;
	BOOL _showProgressPanel;
	BOOL _showPanels;
}

+ (NSPrintOperation *) currentOperation;
+ (NSPrintOperation *) EPSOperationWithView:(NSView *) view 
								 insideRect:(NSRect) rect 
									 toData:(NSMutableData *) epsData; 
+ (NSPrintOperation *) EPSOperationWithView:(NSView *) view 
								 insideRect:(NSRect) rect 
									 toData:(NSMutableData *) data 
								  printInfo:(NSPrintInfo *) printInfo; 
+ (NSPrintOperation *) EPSOperationWithView:(NSView *) view 
								 insideRect:(NSRect) rect 
									 toPath:(NSString *) path 
								  printInfo:(NSPrintInfo *) printInfo; 
+ (NSPrintOperation *) PDFOperationWithView:(NSView *) view
								 insideRect:(NSRect) rect
									 toData:(NSMutableData *) data;
+ (NSPrintOperation *) PDFOperationWithView:(NSView *) view
								 insideRect:(NSRect) rect
									 toData:(NSMutableData *) data
								  printInfo:(NSPrintInfo *) printInfo;
+ (NSPrintOperation *) PDFOperationWithView:(NSView *) view
								 insideRect:(NSRect) rect
									 toPath:(NSString *) path
								  printInfo:(NSPrintInfo *) printInfo;
+ (NSPrintOperation *) printOperationWithView:(NSView *) view;
+ (NSPrintOperation *) printOperationWithView:(NSView *) view
									printInfo:(NSPrintInfo *) printInfo;
+ (void) setCurrentOperation:(NSPrintOperation *) operation;

- (NSView *) accessoryView;
- (BOOL) canSpawnSeparateThread;
- (void) cleanUpOperation;
- (NSGraphicsContext *) context;
- (NSGraphicsContext *) createContext;
- (NSInteger) currentPage;
- (BOOL) deliverResult;
- (void) destroyContext;
- (BOOL) isCopyingOperation;
- (NSString *) jobStyleHint;
- (NSString *) jobTitle; 
- (NSPrintingPageOrder) pageOrder;
- (NSRange) pageRange; 
- (NSPrintInfo *) printInfo;
- (NSPrintPanel *) printPanel;
- (BOOL) runOperation;
- (void) runOperationModalForWindow:(NSWindow *) docWindow
						   delegate:(id) delegate
					 didRunSelector:(SEL) didRunSelector
						contextInfo:(void *) contextInfo;
- (void) setAccessoryView:(NSView *) aView;
- (void) setCanSpawnSeparateThread:(BOOL) flag;
- (void) setJobStyleHint:(NSString *) hint;
- (void) setJobTitle:(NSString *) title; 
- (void) setPageOrder:(NSPrintingPageOrder) order;
- (void) setPrintInfo:(NSPrintInfo *) aPrintInfo;
- (void) setPrintPanel:(NSPrintPanel *) panel;
- (void) setShowsPrintPanel:(BOOL) flag;
- (void) setShowsProgressPanel:(BOOL) flag;
- (BOOL) showPanels;
- (BOOL) showsPrintPanel; 
- (BOOL) showsProgressPanel; 
- (NSView *) view;

@end

#endif /* _mySTEP_H_NSPrintOperation */
