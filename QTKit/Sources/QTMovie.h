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

enum _QTMovieFileTypeOptions
{ 
    QTIncludeStillImageTypes  =  1 << 0, 
    QTIncludeTranslatableTypes =  1 << 1, 
    QTIncludeAggressiveTypes =  1 << 2, 
    QTIncludeCommonTypes = 0, 
    QTIncludeAllTypes = 0xffff 
} QTMovieFileTypeOptions; 

typedef enum _QTMovieOperationPhase
{ 
    QTMovieOperationBeginPhase = movieProgressOpen, 
    QTMovieOperationUpdatePercentPhase = movieProgressUpdatePercent, 
    QTMovieOperationEndPhase = movieProgressClose 
} QTMovieOperationPhase;

@interface QTMediaovie : NSObject <NSCoding>

+ (BOOL) canInitWithDataReference:(QTDataReference*) ref;
+ (BOOL) canInitWithFile:(NSString *) file;
+ (BOOL) canInitWithPasteboard:(NSPasteboard *) pb;
+ (BOOL) canInitWithURL:(NSURL *) url;
+ (id) movie;
+ (NSArray *) movieFileTypes:(QTMovieTypeOptions) types;
+ (id) movieNamed:(NSString *) name error:(NSError **) err;
+ (NSArray *) movieUnfilteredFileTypes;
+ (NSArray *) movieUnfilteredPasteboardTypes;
+ (id) movieWithAttributes:(NSDictionary *) attr error:(NSError **) err;
+ (id) movieWithData:(NSData *) data error:(NSError **) err;
+ (id) movieWithDataReference:(QTDataReference *) data error:(NSError **) err;
+ (id) movieWithFile:(NSString *) file error:(NSError **) err;
+ (id) movieWithPasteboard:(NSPasteboard *) pb error:(NSError **) err;
// + (id) movieWithQuickTimeMovie:(Movie) movie disposeWhenDone:(BOOL) flag error:(NSError **) err;
+ (id) movieWithURL:(NSURL *) url error:(NSError **) err;

- (void) addImage:(NSImage *) image forDuration:(QTTime) duration withAttributes:(NSDictionary *) attr;
- (void) appendSelectionFromMovie:(id) movie;
- (id) attributeForKey:(NSString *) key;
- (BOOL) canUpdateMovieFile;
- (NSImage *) currentFrameImage;
- (QTTime) currentTime;
- (id) delegate;
- (void) deleteSegment:(QTTimeRange) segment;
- (QTTime) duration;
- (NSImage *) frameImageAtTime:(QTTime) time;
- (void) gotoBeginning;
- (void) gotoEnd;
- (void) gotoNextSelectionPoint;
- (void) gotoPosterTime;
- (void) gotoPreviousSelectionPoint;
- (id) initWithAttributes:(NSDictionary *) attr error:(NSError **) err;
- (id) initWithData:(NSData *) data error:(NSError **) err;
- (id) initWithDataReference:(QTDataReference *) ref error:(NSError **) err;
- (id) initWithFile:(NSString *) file error:(NSError **) err;
- (id) initWithMovie:(QTMovie *) movie timeRange:(QTTimeRange) range error:(NSError **) err;
- (id) initWithPasteboard:(NSPasteboard *) pb error:(NSError **) err;
// - (id) initWithQuickTimeMovie:(Movie) movie disposeWhenDone:(BOOL) flag error:(NSError **) err;
- (id) initWithURL:(NSURL *) url error:(NSError **) err;
- (void) insertEmptySegmentAt:(QTTimeRange) range;
- (void) insertSegmentOfMovie:(QTMovie *) movie fromRange:(QTTimeRange) src scaledToRange:(QTTimeRange) dst;
- (void) insertSegmentOfMovie:(QTMovie *) movie timeRange:(QTTimeRange) rng atTime:(QTTime) time;
- (NSDictionary *) movieAttributes;
- (NSData *) movieFormatRepresentation;
- (QTMovie *) movieWithTimeRange:(QTTimeRange) range error:(NSError **) err;
- (BOOL) muted;
- (void) play;
- (NSImage *) posterImage;
	// - (Movie) quickTimeMovie;
	// - (MovieController) quickTimeMovieController;
- (float) rate;
- (void) replaceSelectionWithSelectionFromMovie:(id) movie;
- (void) scaleSegment:(QTTimeRange) segment newDuration:(QTTime) duration;
- (QTTime) selectionDuration;
- (QTTime) selectionEnd;
- (QTTime) selectionStart;
- (void) setAttribute:(id) value forKey:(NSString *) key;
- (void) setCurrentTime:(QTTime) time;
- (void) setDelegate:(id) delegate;
- (void) setMovieAttributes:(NSDictionary *) attr;
- (void) setMuted:(BOOL) mute;
- (void) setRate:(float) rate;
- (void) setSelection:(QTTimeRange) selection;
- (void) setVolume:(float) vol;
- (void) stepBackward;
- (void) stepForward;
- (void) stop;
- (NSArray *) tracks;
- (NSArray *) tracksOfMediaType:(NSString *) type;
- (BOOL) updateMovieFile;
- (float) volume;
- (BOOL) writeToFile:(NSString *) name withAttributes:(NSDictionary *) attr;

@end

@interface NSObject (QTMovieDelegate)

- (QTMovie *) externalMovie:(NSDictionary *) dict;
- (BOOL) movie:(QTMovie *) movie linkToURL:(NSURL *) url;
- (BOOL) movie:(QTMovie *) movie shouldContinueOperation:(NSString *) op
withPhase:(QTMovieOperationPhase) phase atPercent:(NSNumber *) percent
withAttributes:(NSDictionary *) attr;
- (BOOL) movieShouldTask:(id) movie; 

@end

QTMovieActiveSegmentAttribute
QTMovieAutoAlternatesAttribute
QTMovieCopyrightAttribute
QTMovieCreationTimeAttribute
QTMovieCurrentSizeAttribute
QTMovieCurrentTimeAttribute
QTMovieDataSizeAttribute
QTMovieDelegateAttribute
QTMovieDisplayNameAttribute
QTMovieDontInteractWithUserAttribute
QTMovieDurationAttribute
QTMovieEditableAttribute
QTMovieFileNameAttribute
QTMovieHasAudioAttribute
QTMovieHasDurationAttribute
QTMovieHasVideoAttribute
QTMovieIsActiveAttribute
QTMovieIsInteractiveAttribute
QTMovieIsLinearAttribute
QTMovieIsSteppableAttribute
QTMovieLoadStateAttribute
QTMovieLoopsAttribute
QTMovieLoopsBackAndForthAttribute
QTMovieModificationTimeAttribute
QTMovieMutedAttribute
QTMovieNaturalSizeAttribute
QTMoviePlaysAllFramesAttribute
QTMoviePlaysSelectionOnlyAttribute
QTMoviePosterTimeAttribute
QTMoviePreferredMutedAttribute
QTMoviePreferredRateAttribute
QTMoviePreferredVolumeAttribute
QTMoviePreviewModeAttribute
QTMoviePreviewRangeAttribute
QTMovieRateAttribute
QTMovieRateChangesPreservePitchAttribute

QTMovieSelectionAttribute
QTMovieTimeScaleAttribute
QTMovieURLAttribute
QTMovieVolumeAttribute

QTMovieMessageNotificationParameter
QTMovieRateDidChangeNotificationParameter
QTMovieStatusFlagsNotificationParameter
QTMovieStatusCodeNotificationParameter
QTMovieStatusStringNotificationParameter
QTMovieTargetIDNotificationParameter
QTMovieTargetNameNotificationParameter

QTMovieExport
QTMovieExportType
QTMovieFlatten
QTMovieExportSettings
QTMovieExportManufacturer

QTAddImageCodecType
QTAddImageCodecQuality

QTMovieDataReferenceAttribute
QTMoviePasteboardAttribute
QTMovieDataAttribute

QTMovieFileOffsetAttribute
QTMovieResolveDataRefAttribute
QTMovieAskUnresolvedDataRefAttribute
QTMovieOpenAsyncOKAttribute

QTMovieChapterDidChangeNotification
QTMovieChapterListDidChangeNotification
QTMovieCloseWindowRequestNotification
QTMovieDidEndNotification
QTMovieEditabilityDidChangeNotification
QTMovieEditedNotification
QTMovieEnterFullScreenRequestNotification
QTMovieExitFullScreenRequestNotification
QTMovieLoadStateDidChangeNotification
QTMovieLoopModeDidChangeNotification
QTMovieMessageStringPostedNotification
QTMovieRateDidChangeNotification
QTMovieSelectionDidChangeNotification
QTMovieSizeDidChangeNotification
QTMovieStatusStringPostedNotification
QTMovieTimeDidChangeNotification
QTMovieVolumeDidChangeNotification


