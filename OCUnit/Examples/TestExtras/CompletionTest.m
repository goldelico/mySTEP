/* CompletionTest.m created by phink on Mon 02-Nov-1998 */

#import "CompletionTest.h"


@implementation CompletionTest
- (void) setUp
{
    [[textView window] makeKeyAndOrderFront:nil];
    [[textView window] makeFirstResponder:textView];
}


- (void) setText:(NSString *) aText
{
	[textView setString:aText];
}


- (NSString *) nextCompletionFrom:(NSString *) aText
{
    [textView complete:nil];
    return [[textView string] substringFromIndex:[aText length]];
}


- (NSString *) firstCompletionForText:(NSString *) aText
{
    [self setText:aText];
    return [self nextCompletionFrom:aText];
}


- (NSSet *) allCompletionsForText:(NSString *) aText
{
    NSMutableSet *completions = [NSMutableSet set];
    [self setText:aText];
    while (YES) {
        NSString *nextCompletion = [self nextCompletionFrom:aText];
        if ([completions containsObject:nextCompletion]) {
            return completions;
        }
        [completions addObject:nextCompletion];
    }
    return completions;
}


- (void) testFirstCompletion
{
    shouldBeEqual ([self firstCompletionForText:@"Apple A"], @"pple");
}


- (void) testNoCompletion
{
    shouldBeEqual ([self firstCompletionForText:@"Apple X"], @"");
    should ([[self firstCompletionForText:@"Apple X"] length] == 0);
}


- (void) testOneCompletionForTwoWords
{
    shouldBeEqual ([self firstCompletionForText:@"Apple \n\tApple\tAppl"], @"e");
}


- (void) testForward
{
    NSString *text = @"A Stepwise Apple";
    [self setText:text];
    [textView setSelectedRange:NSMakeRange (1, 0)];
    shouldBeEqual ([self nextCompletionFrom:text], @"pple"); 
}


- (void) testCycle
{
    shouldBeEqual ([self allCompletionsForText:@"Apple Atari Amiga A"], ([NSSet setWithObjects:@"pple", @"tari", @"miga", nil]));
}
@end
