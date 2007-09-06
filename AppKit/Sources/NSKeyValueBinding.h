//
//  NSKeyValueBinding.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Tue Oct 05 2004.
//  Copyright (c) 2004 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef mySTEP_NSKEYVALUEBINDING_H
#define mySTEP_NSKEYVALUEBINDING_H

#import "AppKit/AppKit.h"

extern id NSMultipleValuesMarker;
extern id NSNoSelectionMarker;
extern id NSNotApplicableMarker;

@interface NSObject (NSPlaceholder)

+ (id) defaultPlaceholderForMarker:(id) marker withBinding:(NSString *) binding;
+ (void) setDefaultPlaceholder:(id) placeholder forMarker:(id) marker withBinding:(NSString *) binding;

@end

@interface NSObject (NSKeyValueBindingCreation)

+ (void) exposeBinding:(NSString *) key;
- (NSArray *) exposedBindings;
- (Class) valueClassForBinding:(NSString *) binding;
- (void) bind:(NSString *) binding toObject:(id) controller withKeyPath:(NSString *) keyPath options:(NSDictionary *) options;
- (void) unbind:(NSString *) binding;

@end

@interface NSObject (NSEditor)

- (BOOL) commitEditing;
- (void) commitEditingWithDelegate:(id) delegate didCommitSelector:(SEL) sel contextInfo:(void *) ctxt;
- (void) editor:(id) editor didCommit:(BOOL) flag contextInfo:(void *) ctxt;
- (void) discardEditing;

@end

@interface NSObject (NSEditorRegistration)

- (void) objectDidBeginEditing:(id) editor;
- (void) objectDidEndEditing:(id) editor;

@end

#endif mySTEP_NSKEYVALUEBINDING_H
