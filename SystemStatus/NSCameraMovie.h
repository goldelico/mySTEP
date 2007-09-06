/*
 *  NSCameraMovie.h
 *  mySTEP
 *
 *  Created by Dr. H. Nikolaus Schaller on Sat Sep 27 2003.
 *  Copyright (c) 2003 DSITRI. All rights reserved.
 *
 *  licensed under the LGPL
 */

#import <Foundation/Foundation.h>
#import <SystemStatus/SYSDevice.h>

extern NSString *NSCameraShutterPressedNotification;
extern NSString *NSCameraShutterReleasedNotification;

@interface NSCameraStream : NSInputStream
{
	@private
	SYSDevice *camera;			// camera raw device (a SYSDevice *)
	NSFileHandle *file;			// file handle to communicate with the camera
	float width, height, zoom;
	float speed;
	BOOL capturing;
	BOOL hflip, vflip;
}

- (id) propertyForKey:(NSString *)key;
- (BOOL) setProperty:(id)property forKey:(NSString *)key;


- (id) init;
- (BOOL) available;		// camera device is available
// the following methods will raise an exception if the camera is not available
- (int) getStatus;
- (BOOL) startCapture;
- (BOOL) clearShutterLatch;
- (BOOL) setCaptureFrame:(BOOL) rotate size:(NSSize) size zoom:(float) zoom; 
- (BOOL) setHorizontalFlip:(BOOL) flip;
- (BOOL) setVerticalFlip:(BOOL) flip;
- (BOOL) setCaptureSpeed:(float) speed;	// values below 1.0 are "slow", 1.0 and above are "high"

@end