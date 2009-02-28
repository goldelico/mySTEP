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
	float altitude;		// in m over sea level
	float precision;	// in m (>1000 should be assumed to be completely invalid)
} GeoLocation;

typedef struct GeoMovement
{
	GeoLocation location;
	float speed;		// in m/s
	float direction;	// in degrees north
	float ascent;		// in degrees/s
	float elevation;	// in degrees upwards
	float precision;	// speed precision
} GeoMovement;

@interface SYSLocation : NSObject
{
	@private
	SYSDevice *gps;					// GPS device (if present)
	NSDate *timeStamp;				// timestamp (in local time) of last received signal
	NSDate *time;					// last satellite time
	NSFileHandle *file;
	NSString *lastChunk;
	GeoMovement gpsData;
	unsigned numSatellites;			// with reception
	unsigned numVisibleSatellites;	// basically visible
	BOOL noSatellite;				// not enough satellites in reception
}

+ (SYSLocation *) sharedLocation;	// shared location manager device

- (BOOL) isAvailable;				// a location device is available
- (BOOL) isValid;					// is valid (i.e. enough satellites)
- (unsigned) numberOfSatellites;	// number of received satellites
- (unsigned) numberOfVisibleSatellites;  // number of visible satellites
- (GeoLocation) geoLocation;		// current location
- (double) locationLongitude;		// in degrees (-90 .. 90)
- (double) locationLatitude;		// in degrees (-180 .. 180)
- (float) locationAltitude;			// height in m above NN
- (float) locationOrientation;		// horizontal orientation of device (compass) in degrees (0 .. 360)
- (float) locationPrecision;			// 
- (GeoMovement) geoMovement;		// current location + movement
- (float) locationSpeed;			// speed in m/s over surface
- (float) locationDirection;		// direction of movement in degrees (0 .. 360)
- (float) locationAscentSpeed;		// speed in m/s of ascent/descent
- (float) locationElevation;		// elevaton angle in degrees (-90 .. 90)
- (float) locationSpeedPrecision;			// 
- (NSDate *) locationTime;			// satellite time

#define GeoLocationLatitude		@"Latitude"
#define GeoLocationLongitude	@"Longitude"
#define GeoLocationHeight		@"Height"
#define GeoLocationContinent	@"Continent"	// Europe - Europe - North America
#define GeoLocationCountry		@"Country"		// Germany - Great Britain - USA
#define GeoLocationState		@"State"		// Bavaria - England - Michigan
#define GeoLocationRegion		@"Region"		// Oberbayern - % - (South East)
#define GeoLocationDistrict		@"District"		// Landkreis München - City of London - Wayne County
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
