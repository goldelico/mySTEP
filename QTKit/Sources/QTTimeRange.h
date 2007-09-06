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
BOOL QTGetTimeInterval(QTTime t, NSTimeInterval *ti);
BOOL QTGetTimeRecord(QTTime t, TimeRecord *rec);
QTTimeRange QTIntersectionTimeRange(QTTimeRange r1, QTTimeRange r2);
QTTime QTMakeTime(long long t, long scale);
QTTimeRange QTMakeTimeRange(QTTime t, QTTime dur);
QTTime QTMakeTimeScaled(QTTime t, long scale);
QTTime QTMakeTimeWithTimeInterval(NSTimeInterval t);
QTTime QTMakeTimeWithTimeRecord(TimeRecord t);
OSType QTOSTypeForString(NSString *str);
NSString *QTStringForOSType(OSType t);
NSString *QTStringFromTime(QTTime t);
NSString *QTStringFromTimeRange(QTTimeRange r);
NSComparisonResult QTTimeCompare(QTTime t1, QTTime t2);
QTTime QTTimeDecrement(QTTime t, QTTime dec);
QTTime QTTimeFromString(NSString *str);
QTTime QTTimeIncrement(QTTime t, QTTime inc);
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
