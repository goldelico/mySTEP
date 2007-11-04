/* 
 SYSLocationStatus.h
 
 Generic global location/position interface.
 
 Copyright (C)	H. Nikolaus Schaller <hns@computer.org>
 Date:			2004
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#ifndef _mySTEP_H_SYSLocationStatus
#define _mySTEP_H_SYSLocationStatus

#import <AppKit/AppKit.h>

@class SYSDevice;

extern NSString *SYSLocationInsertedNotification;		// device was inserted
extern NSString *SYSLocationEjectedNotification;		// device was ejected (or unplugged)
extern NSString *SYSLocationSuspendedNotification;		// device was deactivated
extern NSString *SYSLocationResumedNotification;		// device was activated
extern NSString *SYSLocationNMEA183Notification;		// NMEA183 record was received

typedef struct GeoLocation
{
	double longitude;	// in degrees (float would give worst case precision of 1m only)
	double latitude;	// in deg
	double height;		// in m over sea level
} GeoLocation;

typedef struct GeoMovement
{
	GeoLocation location;
	double speed;		// in m/s
	double direction;	// in degrees north
	double ascent;		// in degrees/s
	double elevation;	// in degrees
} GeoMovement;

@interface SYSLocation : NSObject
{
	@private
	SYSDevice *gps;					// GPS device (if present)
	NSDate *timeStamp;				// timestamp (in local time) of last received signal
	NSDate *time;					// last satellite time
	NSFileHandle *file;
	GeoMovement gpsData;
	unsigned numSatellites;			// with reception
	unsigned numVisibleSatellites;	// basically visible
	float precision;				// estimated precision
	BOOL noSatellite;				// not enough satellites in reception
}

+ (SYSLocation *) sharedLocation;	// shared location manager device

- (BOOL) isAvailable;				// a location device is available
- (BOOL) isValid;					// is valid (i.e. enough satellites)
- (unsigned) numberOfSatellites;	// number of received satellites
- (unsigned) numberOfVisibleSatellites;  // number of visible satellites
- (float) precision;				// estimated precision in meter
- (GeoLocation) geoLocation;		// current location
- (GeoMovement) geoMovement;		// current location + movement
- (double) locationLongitude;		// in degrees (-90 .. 90)
- (double) locationLatitude;		// in degrees (-180 .. 180)
- (double) locationHeight;			// height in m above NN
- (double) locationSpeed;			// speed in m/s over surface
- (double) locationDirection;		// direction of movement in degrees (0 .. 360)
- (double) locationAscentSpeed;		// speed in m/s of ascent/descent
- (double) locationElevation;		// elevaton angle in degrees (-90 .. 90)
- (double) locationOrientation;		// horizontal orientation of device (compass) in degrees (0 .. 360)
- (NSDate *) locationTime;			// satellite time

#define GeoLocationLatitude		@"Latitude"
#define GeoLocationLongitude	@"Longitude"
#define GeoLocationHeight		@"Height"
#define GeoLocationContinent	@"Continent"	// Europe - Europe - North America
#define GeoLocationCountry		@"Country"		// Germany - Great Britain - USA
#define GeoLocationState		@"State"		// Bavaria - England - Michigan
#define GeoLocationRegion		@"Region"		// Oberbayern - % - (South East)
#define GeoLocationDistrict		@"District"		// Landkreis MŸnchen - City of London - Wayne County
#define GeoLocationCity			@"City"			// Oberhaching - London - Dearborn
#define GeoLocationVillage		@"Village"		// Deisenhofen - Notting Hill - %
#define GeoLocationZIP			@"ZIP"			// 82041 - W11 - 48124
#define GeoLocationStreet		@"Street"		// % - Portobello Road - Oakwood Blvd.
#define GeoLocationNumber		@"Number"		// % - % - 20900
#define GeoLocationTimeZone		@"Timezone"		// Time zone name (as in NSTimeZone) of location
#define GeoLocationDistance		@"Distance"		// NSNumber with distance to point originally asked for

- (NSDictionary *) geoDataForLocation:(GeoLocation) location;			// ask Geodatabase for nearest geo-location
- (GeoLocation) geoLocationForData:(NSDictionary *) pattern;			// search for nearest known location
- (double) distanceBetween:(GeoLocation) loc1 and:(GeoLocation) loc2;	// distance in meter on earth surface
- (float) routeBetween:(GeoLocation) loc1 and:(GeoLocation) loc2;		// north-pointing angle for navigation

@end

@interface NSObject (SYSLocation)
- (void) locationInserted:(NSNotification *) n;
- (void) locationEjected:(NSNotification *) n;
- (void) locationResumed:(NSNotification *) n;
- (void) locationSuspended:(NSNotification *) n;
- (void) locationNMEA183:(NSNotification *) n;	// n.object=SysLocation n.userInfo.nmea=NSArray with NMEA record
@end

#endif