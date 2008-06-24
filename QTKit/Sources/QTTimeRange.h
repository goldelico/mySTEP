/* 
   QTTimeRange.h

   mySTEP QTKit Library

   Author:	H. N. Schaller <hns@computer.org>
   Date:	Nov 2006

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_QTTimeRange
#define _mySTEP_H_QTTimeRange

#import <Cocoa/Cocoa.h>

typedef struct _QTTimeRange
{
	QTTime time;
	QTTime duration;
} QTTimeRange; 

BOOL QTEqualTimeRanges(QTTimeRange r1, QTTimeRange r2);
QTTimeRange QTIntersectionTimeRange(QTTimeRange r1, QTTimeRange r2);
QTTimeRange QTMakeTimeRange(QTTime t, QTTime dur);
NSString *QTStringFromTimeRange(QTTimeRange r);
BOOL QTTimeInTimeRange(QTTime t, QTTimeRange r);
QTTime QTTimeRangeEnd(QTTimeRange r);
QTTimeRange QTTimeRangeFromString(NSString *str);
QTTimeRange QTUnionTimeRange(QTTimeRange r1, QTTimeRange r2);

@interface NSCoder (QTTimeRange)
- (QTTimeRange) decodeQTTimeRangeForKey:(NSString *) key;
- (void) encodeQTTimeRange:(QTTimeRange) range forKey:(NSString *) key;
@end

@interface NSValue (QTTimeRange)
+ (NSValue *) valueWithQTTimeRange:(QTTimeRange) range;
- (QTTimeRange) QTTimeRangeValue;
@end

#endif /* _mySTEP_H_QTTimeRange */
