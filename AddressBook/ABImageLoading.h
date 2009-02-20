//
//  ABImageLoading.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Aug 18 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//
//	reviewed for 10.4 compatibility, Aug 2007
//
//  for documentation please refer to
//  http://developer.apple.com/documentation/UserExperience/Reference/AddressBook/Classes/ABAddressBook_Class/Reference/Reference.html
//

#import <AddressBook/ABTypedefs.h>

@protocol ABImageClient

- (void) consumeImageData:(NSData*) data forTag:(int) tag;

@end
