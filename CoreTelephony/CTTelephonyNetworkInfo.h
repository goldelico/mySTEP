//
//  CRTagManagerDelegate.h
//  CoreRFID
//
//  Created by H. Nikolaus Schaller on 09.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CRTag;
@class CRTagManager;

@protocol CRTagManagerDelegate <NSObject>

- (void) tagManager:(CRTagManager *) mngr didFailWithError:(NSError *) err;
- (void) tagManager:(CRTagManager *) mngr didFindTag:(CRTag *) err;
- (void) tagManager:(CRTagManager *) mngr didLooseTag:(CRTag *) err;

@end
