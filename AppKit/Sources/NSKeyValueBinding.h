/*
  NSKeyValueBinding.h
  mySTEP

  Created by Dr. H. Nikolaus Schaller on Tue Oct 05 2004.
  Copyright (c) 2004 DSITRI.

  Author:	Fabian Spillner <fabian.spillner@gmail.com>
  Date:		9. November 2007 - aligned with 10.5 
 
  This file is part of the mySTEP Library and is provided
  under the terms of the GNU Library General Public License.
*/

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

- (void) bind:(NSString *) binding toObject:(id) controller withKeyPath:(NSString *) keyPath options:(NSDictionary *) options;
- (NSArray *) exposedBindings;
- (NSDictionary *) infoForBinding:(NSString *) binding;
- (NSArray *) optionDescriptionsForBinding:(NSString *) binding;
- (void) unbind:(NSString *) binding;
- (Class) valueClassForBinding:(NSString *) binding;


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

extern NSString *NSAllowsEditingMultipleValuesSelectionBindingOption;
extern NSString *NSAllowsNullArgumentBindingOption;
extern NSString *NSAlwaysPresentsApplicationModalAlertsBindingOption;
extern NSString *NSConditionallySetsEditableBindingOption;
extern NSString *NSConditionallySetsEnabledBindingOption;
extern NSString *NSConditionallySetsHiddenBindingOption;
extern NSString *NSContinuouslyUpdatesValueBindingOption;
extern NSString *NSCreatesSortDescriptorBindingOption;
extern NSString *NSDeletesObjectsOnRemoveBindingsOption;
extern NSString *NSDisplayNameBindingOption;
extern NSString *NSDisplayPatternBindingOption;
extern NSString *NSContentPlacementTagBindingOption;
extern NSString *NSHandlesContentAsCompoundValueBindingOption;
extern NSString *NSInsertsNullPlaceholderBindingOption;
extern NSString *NSInvokesSeparatelyWithArrayObjectsBindingOption;
extern NSString *NSMultipleValuesPlaceholderBindingOption;
extern NSString *NSNoSelectionPlaceholderBindingOption;
extern NSString *NSNotApplicablePlaceholderBindingOption;
extern NSString *NSNullPlaceholderBindingOption;
extern NSString *NSRaisesForNotApplicableKeysBindingOption;
extern NSString *NSPredicateFormatBindingOption;
extern NSString *NSSelectorNameBindingOption;
extern NSString *NSSelectsAllWhenSettingContentBindingOption;
extern NSString *NSValidatesImmediatelyBindingOption;
extern NSString *NSValueTransformerNameBindingOption;
extern NSString *NSValueTransformerBindingOption;

extern NSString *NSObservedObjectKey;
extern NSString *NSObservedKeyPathKey;
extern NSString *NSOptionsKey;

extern NSString *NSAlignmentBinding;
extern NSString *NSAlternateImageBinding;
extern NSString *NSAlternateTitleBinding;
extern NSString *NSAnimateBinding;
extern NSString *NSAnimationDelayBinding;
extern NSString *NSArgumentBinding;
extern NSString *NSAttributedStringBinding;
extern NSString *NSContentArrayBinding;
extern NSString *NSContentArrayForMultipleSelectionBinding;
extern NSString *NSContentBinding;
extern NSString *NSContentDictionaryBinding;
extern NSString *NSContentHeightBinding;
extern NSString *NSContentObjectBinding;
extern NSString *NSContentObjectsBinding;
extern NSString *NSContentSetBinding;
extern NSString *NSContentValuesBinding;
extern NSString *NSContentWidthBinding;
extern NSString *NSCriticalValueBinding;
extern NSString *NSDataBinding;
extern NSString *NSDisplayPatternTitleBinding;
extern NSString *NSDisplayPatternValueBinding;
extern NSString *NSDocumentEditedBinding;
extern NSString *NSDoubleClickArgumentBinding;
extern NSString *NSDoubleClickTargetBinding;
extern NSString *NSEditableBinding;
extern NSString *NSEnabledBinding;
extern NSString *NSExcludedKeysBinding;
extern NSString *NSFilterPredicateBinding;
extern NSString *NSFontBinding;
extern NSString *NSFontBoldBinding;
extern NSString *NSFontFamilyNameBinding;
extern NSString *NSFontItalicBinding;
extern NSString *NSFontNameBinding;
extern NSString *NSFontSizeBinding;
extern NSString *NSHeaderTitleBinding;
extern NSString *NSHiddenBinding;
extern NSString *NSImageBinding;
extern NSString *NSIncludedKeysBinding;
extern NSString *NSInitialKeyBinding;
extern NSString *NSInitialValueBinding;
extern NSString *NSIsIndeterminateBinding;
extern NSString *NSLabelBinding;
extern NSString *NSLocalizedKeyDictionaryBinding;
extern NSString *NSManagedObjectContextBinding;
extern NSString *NSMaximumRecentsBinding;
extern NSString *NSMaxValueBinding;
extern NSString *NSMaxWidthBinding;
extern NSString *NSMinValueBinding;
extern NSString *NSMinWidthBinding;
extern NSString *NSMixedStateImageBinding;
extern NSString *NSOffStateImageBinding;
extern NSString *NSOnStateImageBinding;
extern NSString *NSPredicateBinding;
extern NSString *NSRecentSearchesBinding;
extern NSString *NSRepresentedFilenameBinding;
extern NSString *NSRowHeightBinding;
extern NSString *NSSelectedIdentifierBinding;
extern NSString *NSSelectedIndexBinding;
extern NSString *NSSelectedLabelBinding;
extern NSString *NSSelectedObjectBinding;
extern NSString *NSSelectedObjectsBinding;
extern NSString *NSSelectedTagBinding;
extern NSString *NSSelectedValueBinding;
extern NSString *NSSelectedValuesBinding;
extern NSString *NSSelectionIndexesBinding;
extern NSString *NSSelectionIndexPathsBinding;
extern NSString *NSSortDescriptorsBinding;
extern NSString *NSTargetBinding;
extern NSString *NSTextColorBinding;
extern NSString *NSTitleBinding;
extern NSString *NSToolTipBinding;
extern NSString *NSTransparentBinding;
extern NSString *NSValueBinding;
extern NSString *NSValuePathBinding;
extern NSString *NSValueURLBinding;
extern NSString *NSVisibleBinding;
extern NSString *NSWarningValueBinding;
extern NSString *NSWidthBinding;

#endif // mySTEP_NSKEYVALUEBINDING_H
