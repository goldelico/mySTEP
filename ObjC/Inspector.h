//
//  Inspector.h
//  ObjCKit
//
//  Created by H. Nikolaus Schaller on 20.06.14.
//  Copyright 2014 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <ObjCKit/AST.h>


@interface Inspector : NSObject
{
	IBOutlet NSWindow *inspector;
	IBOutlet NSOutlineView *outlineView;
	IBOutlet NSTableView *attributesView;
	Node *root;
	Node *selectedNode;	// shown in attributesView
}

- (void) openInspector:(Node *) node;	// open in a window (needs a NSRunLoop)

@end
