/* 
   QTDataReference.h

   mySTEP 

   Author:	H. N. Schaller <hns@computer.org>
   Date:	Nov 2006

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_QTDataReference
#define _mySTEP_H_QTDataReference

#import <Cocoa/Cocoa.h>

@interface QTDataReference : NSObject	// is this a class cluster that returns subclass objects?

// + (id) dataReferenceWithDataRef:(Handle) ref type:(NSString *) type;
+ (id) dataReferenceWithDataRefData:(NSData *) ref type:(NSString *) type;
+ (id) dataReferenceWithReferenceToData:(NSData *) data;
+ (id) dataReferenceWithReferenceToData:(NSData *) data name:(NSString *) name MIMEType:(NSString *) type;
+ (id) dataReferenceWithReferenceToFile:(NSString *) file;
+ (id) dataReferenceWithReferenceToURL:(NSURL *) url;
// - (Handle) dataRef;
- (NSData *) dataRefData;
- (NSString *) dataRefType;
// - (id) initWithDataRef:(Handle) ref type:(NSString *) type;
- (id) initWithDataRefData:(NSData *) ref type:(NSString *) type;
- (id) initWithReferenceToData:(NSData *) data;
- (id) initWithReferenceToData:(NSData *) data name:(NSString *) name MIMEType:(NSString *) type;
- (id) initWithReferenceToFile:(NSString *) name;
- (id) initWithReferenceToURL:(NSURL *) url;
- (NSString *) MIMEType;
- (NSString *) name;
- (NSData *) referenceData;
- (NSString *) referenceFile;
- (NSURL *) referenceURL;
// - (void) setDataRef:(Handle) dataRef;
- (void) setDataRefType:(NSString *) type;

@end

QTDataReferenceTypeFile
QTDataReferenceTypeHandle
QTDataReferenceTypePointer
QTDataReferenceTypeResource
QTDataReferenceTypeURL

#endif /* _mySTEP_H_QTDataReference */
