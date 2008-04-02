//
//  NSRuleEditor.h
//  AppKit
//
//  Created by Fabian Spillner on 03.12.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <AppKit/NSControl.h>

typedef NSUInteger NSRuleEditorNestingMode;

enum {
	NSRuleEditorNestingModeSingle,
	NSRuleEditorNestingModeList,
	NSRuleEditorNestingModeCompound,
	NSRuleEditorNestingModeSimple
};

typedef NSUInteger NSRuleEditorRowType;

enum {
	NSRuleEditorRowTypeSimple,
	NSRuleEditorRowTypeCompound
};

extern NSString * const NSRuleEditorPredicateLeftExpression;
extern NSString * const NSRuleEditorPredicateRightExpression;
extern NSString * const NSRuleEditorPredicateComparisonModifier;
extern NSString * const NSRuleEditorPredicateOptions;
extern NSString * const NSRuleEditorPredicateOperatorType;
extern NSString * const NSRuleEditorPredicateCustomSelector;
extern NSString * const NSRuleEditorPredicateCompoundType;

extern NSString *NSRuleEditorRowsDidChangeNotification; 

@interface NSRuleEditor : NSControl {

}

- (void) addRow:(id) sender; 
- (BOOL) canRemoveAllRows; 
- (NSArray *) criteriaForRow:(NSInteger) index; 
- (NSString *) criteriaKeyPath; 
- (id) delegate; 
- (NSArray *) displayValuesForRow:(NSInteger) index; 
- (NSString *) displayValuesKeyPath; 
- (NSDictionary *) formattingDictionary; 
- (NSString *) formattingStringsFilename; 
- (void) insertRowAtIndex:(NSInteger) index 
				 withType:(NSRuleEditorRowType) type 
			asSubrowOfRow:(NSInteger) row 
				  animate:(BOOL) flag; 
- (BOOL) isEditable; 
- (NSRuleEditorNestingMode) nestingMode; 
- (NSInteger) numberOfRows; 
- (NSInteger) parentRowForRow:(NSInteger) row; 
- (NSPredicate *) predicate; 
- (NSPredicate *) predicateForRow:(NSInteger) row; 
- (void) reloadCriteria; 
- (void) reloadPredicate; 
- (void) removeRowAtIndex:(NSInteger) index; 
- (void) removeRowsAtIndexes:(NSIndexSet *) rowIds includeSubrows:(BOOL) flag; 
- (Class) rowClass; 
- (NSInteger) rowForDisplayValue:(id) value; 
- (CGFloat) rowHeight; 
- (NSRuleEditorRowType) rowTypeForRow:(NSInteger) row; 
- (NSString *) rowTypeKeyPath; 
- (NSIndexSet *) selectedRowIndexes; 
- (void) selectRowIndexes:(NSIndexSet *) ids byExtendingSelection:(BOOL) flag; 
- (void) setCanRemoveAllRows:(BOOL) flag; 
- (void) setCriteria:(NSArray *) crits andDisplayValues:(NSArray *) vals forRowAtIndex:(NSInteger) index; 
- (void) setCriteriaKeyPath:(NSString *) path; 
- (void) setDelegate:(id) delegate; 
- (void) setDisplayValuesKeyPath:(NSString *) path; 
- (void) setEditable:(BOOL) flag; 
- (void) setFormattingDictionary:(NSDictionary *) dict; 
- (void) setFormattingStringsFilename:(NSString *) filename; 
- (void) setNestingMode:(NSRuleEditorNestingMode) flag; 
- (void) setRowClass:(Class) rowClass; 
- (void) setRowHeight:(CGFloat) height; 
- (void) setRowTypeKeyPath:(NSString *) path; 
- (void) setSubrowsKeyPath:(NSString *) path; 
- (NSIndexSet *) subrowIndexesForRow:(NSInteger) row; 
- (NSString *) subrowsKeyPath; 
- (void) viewDidMoveToWindow; 

@end

@interface NSRuleEditor (Delegate)

- (id) ruleEditor:(NSRuleEditor *) editor child:(NSInteger) idx forCriterion:(id) crit withRowType:(NSRuleEditorRowType) type; 
- (id) ruleEditor:(NSRuleEditor *) editor displayValueForCriterion:(id) crit inRow:(NSInteger) row; 
- (NSInteger) ruleEditor:(NSRuleEditor *) editor numberOfChildrenForCriterion:(id) crit withRowType:(NSRuleEditorRowType) type; 
- (NSDictionary *) ruleEditor:(NSRuleEditor *) editor predicatePartsForCriterion:(id) crit withDisplayValue:(id) val inRow:(NSInteger) row;
- (void) ruleEditorRowsDidChange:(NSNotification *) notif; 

@end
