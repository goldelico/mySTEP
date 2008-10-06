/* 
   QTMedia.h

   mySTEP QTKit Library
 
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Nov 2006

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_QTMedia
#define _mySTEP_H_QTMedia

#import <Cocoa/Cocoa.h>

@interface QTMedia : NSObject

+ (id) mediaWithQuickTimeMedia:(Media) media error:(NSError **) err;
- (id) attributeForKey:(NSString *) key;
- (BOOL) hasCharacteristic:(NSString *) c;
- (id) initWithQuickTimeMedia:(Media) media error:(NSError **) err;
- (NSDictionary *) mediaAttributes;
- (Media) quickTimeMedia;
- (void) setAttribute:(id) value forKey:(NSString *) key;
- (void) setMediaAttributes:(NSDictionary *) attrib;
- (QTTrack *) track;

QTMediaCreationTimeAttribute
QTMediaDurationAttribute
QTMediaModificationTimeAttribute
QTMediaSampleCountAttribute
QTMediaQualityAttribute
QTMediaTimeScaleAttribute
QTMediaTypeAttribute
QTMediaTypeVideo
QTMediaTypeSound
QTMediaTypeText
QTMediaTypeBase
QTMediaTypeMPEG
QTMediaTypeMusic
QTMediaTypeTimeCode
QTMediaTypeSprite
QTMediaTypeFlash
QTMediaTypeMovie
QTMediaTypeTween
QTMediaType3D
QTMediaTypeSkin
QTMediaTypeQTVR
QTMediaTypeHint
QTMediaTypeStream Stream media.

QTMediaCharacteristicVisual
QTMediaCharacteristicAudio
QTMediaCharacteristicCanSendVideo
QTMediaCharacteristicProvidesActions
QTMediaCharacteristicNonLinear
QTMediaCharacteristicCanStep
QTMediaCharacteristicHasNoDuration
QTMediaCharacteristicHasSkinData
QTMediaCharacteristicProvidesKeyFocus
QTMediaCharacteristicHasVideoFrameRate

@end

#endif /* _mySTEP_H_QTMedia */
