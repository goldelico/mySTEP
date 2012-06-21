//
//  MKShape.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <MapKit/MKAnnotation.h>

@interface MKShape : NSObject <MKAnnotation>
{
	/*@property(nonatomic, copy)*/ NSString *subtitle;
	/*@property(nonatomic, copy)*/ NSString *title;
}

- (void) setSubtitle:(NSString *) s;
- (void) setTitle:(NSString *) t;
// - (NSString *) subtitle;
// - (NSString *) title;

@end

// EOF
