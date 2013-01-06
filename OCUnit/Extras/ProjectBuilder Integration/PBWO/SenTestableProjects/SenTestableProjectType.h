/*$Id: SenTestableProjectType.h,v 1.1 2003/11/21 14:44:33 phink Exp $*/
// Copyright (c) 2000 Sen:te Ltd.  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import <Foundation/Foundation.h>
//#import <ProjectBuilder/PBProjectType.h>

@interface PBProjectType : NSObject
{
    NSDictionary * infoDict;
    NSString * wrapperDirectory;
    NSMutableArray * allowableSubprojectTypes;
    NSDictionary * additionalAttributes;
    id delegate;
}
- (NSArray *)buildTargets;
@end

@interface SenTestableProjectType : PBProjectType
{

}
- (NSArray *)buildTargets;

@end
