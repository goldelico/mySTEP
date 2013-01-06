/*$Id: Shikenjo.m,v 1.5 2003/06/18 14:56:20 alain Exp $*/

// Copyright (c) 1997, 1998, 1999, Sen:te Ltd.  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "Shikenjo.h"
#import <SenTestingKit/SenTestingKit.h>
#import <SenFoundation/SenFoundation.h>

static NSString *TestCoverageDefaultKey = @"SenTest";
static NSString *TestRunnerPathDefaultKey = @"TestRunnerPath";


static NSString *notificationIdentifier = nil;
static NSString *LoadableExtensions = @"LoadableExtensions";
static NSString *ExecutableExtensions = @"ExecutableExtensions";
static NSString *TestedUnitPath = @"TestedUnitPath";

static NSString *WindowTitle = @"Unit Test";


@interface NSNotification (Shikenjo)
- (id) unarchivedRun;
- (id) unarchivedException;
@end

@implementation NSNotification (Shikenjo)
- (id) unarchivedRun
{
    return [NSUnarchiver unarchiveObjectWithData:[[self userInfo] objectForKey:@"object"]];
}


- (id) unarchivedException
{
    return [NSUnarchiver unarchiveObjectWithData:[[self userInfo] objectForKey:@"exception"]];
}
@end


@implementation Shikenjo
+ (void) initialize
{
    [super initialize];
    [NSUserDefaults registerDefaultsFromBundle:[NSBundle mainBundle]];
    notificationIdentifier = [[[NSProcessInfo processInfo] globallyUniqueString] copy];
}


+ (NSSet *) executableExtensions
{
    return [NSSet setWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:ExecutableExtensions]];
}


+ (NSSet *) loadableExtensions
{
    return [NSSet setWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:LoadableExtensions]];
}


+ (NSSet *) testableExtensions
{
    NSMutableSet *extensions = [NSMutableSet set];
    [extensions unionSet:[self executableExtensions]];
    [extensions unionSet:[self loadableExtensions]];
    return extensions;
}


- init
{
    self = [super init];
    failures = [[NSMutableArray alloc] init];
    testedUnitPath = [[[NSUserDefaults standardUserDefaults] stringForKey:TestedUnitPath] retain];
    return self;
}


- (void) setupWindow
{
    if (testedUnitPath != nil) {
        [window setTitle:[NSString stringWithFormat:@"%@ - '%@'", WindowTitle, [testedUnitPath lastPathComponent]]];
    }
    else {
        [window setTitle:WindowTitle];
    }
}


- (void) setupFailureTable:(NSTableView *) aTable
{
    [aTable setDataSource:self];
    [aTable setDelegate:self];
}


- (void) resetProgressView
{
    [progressView setDoubleValue:0.0];
    [progressView setMaxValue:1.0];
}


- (void) resetFailureTableView
{
    [failures removeAllObjects];
    [failureTableView reloadData];
}


- (void) resetFields
{
    [casesField setIntValue:0];
    [failuresField setIntValue:0];
    [errorsField setIntValue:0];
    [messageField setStringValue:@""];
    [self resetProgressView];
    [self resetFailureTableView];
}


- (void) registerSelector:(SEL) aSelector withDistributedNotificationName:(NSString *) aNotificationName
{
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:aSelector
                                                            name:aNotificationName
                                                          object:notificationIdentifier
                                              suspensionBehavior:NSNotificationSuspensionBehaviorHold];
}


- (void) registerToTestNotifications
{
     [self registerSelector:@selector(testSuiteDidStart:) withDistributedNotificationName:SenTestSuiteDidStartNotification];
     [self registerSelector:@selector(testSuiteDidStop:) withDistributedNotificationName:SenTestSuiteDidStopNotification];

     [self registerSelector:@selector(testCaseDidStart:) withDistributedNotificationName:SenTestCaseDidStartNotification];
     [self registerSelector:@selector(testCaseDidStop:) withDistributedNotificationName:SenTestCaseDidStopNotification];
     [self registerSelector:@selector(testCaseDidFail:) withDistributedNotificationName:SenTestCaseDidFailNotification];
}


- (void) unregisterFromTestNotifications
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}


- (void) setTestingTask:(NSTask *) aTask
{
    if (testingTask != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSTaskDidTerminateNotification
                                                      object:testingTask];
    }
    ASSIGN (testingTask, aTask);
    if (testingTask != nil) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(taskDidTerminate:)
                                                     name:NSTaskDidTerminateNotification
                                                   object:testingTask];
    }
}


- (void) setTestedUnitPath:(NSString *) aPath
{
    ASSIGN (testedUnitPath, aPath);
    [[NSUserDefaults standardUserDefaults] setObject:testedUnitPath forKey:TestedUnitPath];
    [self setupWindow];
}


- (BOOL) isExecutablePath:(NSString *) path
{
    return [[[self class] executableExtensions] containsObject:[path pathExtension]];
}


- (NSString *) testedUnitPath
{
    return testedUnitPath;
}


- (void) launchTestingTask
{
    NSMutableArray *arguments = [NSMutableArray array];
    NSTask *task = [[[NSTask alloc] init] autorelease];

    [arguments setArgumentDefaultValue:[[NSUserDefaults standardUserDefaults] stringForKey:TestCoverageDefaultKey] forKey:TestCoverageDefaultKey];
    [arguments setArgumentDefaultValue:@"SenTestDistributedNotifier" forKey:@"SenTestObserverClass"];
    [arguments setArgumentDefaultValue:notificationIdentifier forKey:@"SenTestNotificationIdentifier"];

    if ([self isExecutablePath:testedUnitPath]) {
        [task setLaunchPath: [[NSBundle bundleWithPath:testedUnitPath] executablePath]];

        //if ([[[NSUserDefaults standardUserDefaults] stringForKey:TestCoverageDefaultKey] isEqualToString:@"Self"]) {
        [arguments setArgumentDefaultValue:testedUnitPath forKey:SenTestedUnitPath];
        //}
    }
    else  {
        [task setLaunchPath:[[NSUserDefaults standardUserDefaults] stringForKey:TestRunnerPathDefaultKey]];
        [arguments addObject:[testedUnitPath asUnixPath]];
}

[task setArguments:arguments];
[self setTestingTask:task];
[self registerToTestNotifications];
[testingTask launch];
}


- (void) terminateTestingTask
{
    if ([testingTask isRunning]) {
        [testingTask terminate];
    }
    [self unregisterFromTestNotifications];
}


- (void) start
{
    startedSuiteCount = 0;
    [self resetFields];
    [self launchTestingTask];
    [runButton setImage:[NSImage imageNamed:@"Stop"]];
    [runButton setAction:@selector (stop:)];
}


- (void) stop
{
    [self terminateTestingTask];
    [runButton setImage:[NSImage imageNamed:@"Run"]];
    [runButton setAction:@selector (run:)];
    [self resetProgressView];
}


- (IBAction) run:(id)sender
{
    [self start];
}


- (IBAction) stop:(id)sender
{
    [self stop];
    [messageField setStringValue:@"interrupted."];
}


- (IBAction) chooseUnit:(id)sender
{
    int result;
    NSArray *fileTypes = [[[self class] testableExtensions] allObjects];
    NSOpenPanel *panel = [NSOpenPanel openPanel];

    NSString *openDirectory = (testedUnitPath != nil) ? [testedUnitPath stringByDeletingLastPathComponent] : NSHomeDirectory();
    NSString *openFile = (testedUnitPath != nil) ? [testedUnitPath lastPathComponent] : nil;

    [panel setAllowsMultipleSelection:NO];
    result = [panel runModalForDirectory:openDirectory file:openFile types:fileTypes];
    if (result == NSOKButton) {
        [self setTestedUnitPath:[[panel filenames] lastObject]];
    }
}


- (void) applicationDidFinishLaunching:(NSNotification *) aNotification
{
    [self stop];
    [self setupFailureTable:failureTableView];
    [self setupWindow];
}


- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    if ([[[self class] testableExtensions] containsObject:[filename pathExtension]]){
        [self setTestedUnitPath:filename];
        [self performSelector:@selector(run:) withObject:nil afterDelay:0.0];
        return YES;
    }
    return NO;
}


- (void) testSuiteDidStart:(NSNotification *) notification
{
    [[NSDistributedNotificationCenter defaultCenter] setSuspended:YES];
    {
        SenTestRun *testRun = [notification unarchivedRun];
        if (startedSuiteCount == 0) {
            ASSIGN (startTime, [testRun startDate]);
            [progressView setMaxValue:(double) [[testRun test] testCaseCount]];
        }
        startedSuiteCount++;
    }
    [[NSDistributedNotificationCenter defaultCenter] setSuspended:NO];
}


- (void) testSuiteDidStop:(NSNotification *) notification
{
    [[NSDistributedNotificationCenter defaultCenter] setSuspended:YES];
    {
        startedSuiteCount--;
        if (startedSuiteCount == 0) {
            SenTestRun *testRun = [notification unarchivedRun];
            ASSIGN (stopTime, [testRun stopDate]);
            [self stop];
            [messageField setStringValue:[NSString stringWithFormat:@"started %@, terminated %@.",
                [startTime dateWithCalendarFormat:@"%H:%M:%S" timeZone:nil],
                [stopTime dateWithCalendarFormat:@"%H:%M:%S" timeZone:nil]]];
        }
    }
    [[NSDistributedNotificationCenter defaultCenter] setSuspended:NO];
}


- (void) testCaseDidStart:(NSNotification *) notification
{
    [[NSDistributedNotificationCenter defaultCenter] setSuspended:YES];
    {
        SenTestRun *testRun = [notification unarchivedRun];
        [messageField setStringValue:[[testRun test] description]];
    }
    [[NSDistributedNotificationCenter defaultCenter] setSuspended:NO];
}


- (void) testCaseDidStop:(NSNotification *) notification
{
    [[NSDistributedNotificationCenter defaultCenter] setSuspended:YES];
    {
        [casesField setIntValue:[casesField intValue] + 1];
        [progressView setDoubleValue:[casesField doubleValue]];
    }
    [[NSDistributedNotificationCenter defaultCenter] setSuspended:NO];
}


- (void) taskDidTerminate:(NSNotification *) notification
{
}


- (void) testCaseDidFail:(NSNotification *) notification
{
    [[NSDistributedNotificationCenter defaultCenter] setSuspended:YES];
    {
        SenTestRun *testRun = [notification unarchivedRun];
        NSException *exception = [notification unarchivedException];
        id test = [testRun test];
        NSMutableDictionary *exceptionDescription = [NSMutableDictionary dictionary];
    
        if ([exception isOfType:SenTestFailureException]) {
            [failuresField setIntValue:[failuresField intValue] + 1];
            [exceptionDescription setObject:NSLocalizedString (SenTestFailureException, @"") forKey:@"Type"];
        }
        else {
            [errorsField setIntValue:[errorsField intValue] + 1];
            [exceptionDescription setObject:NSLocalizedString (@"OtherException", @"") forKey:@"Type"];
        }
    
        [exceptionDescription addEntriesFromDictionary:[exception userInfo]];
        [exceptionDescription setObject:[exception reason] forKey:@"Reason"];
        [exceptionDescription setObject:[test description] forKey:@"Case"];
        [failures addObject:exceptionDescription];
        [failureTableView reloadData];
    }
    [[NSDistributedNotificationCenter defaultCenter] setSuspended:NO];
}


- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [failures count];
}


- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    return [[failures objectAtIndex:rowIndex] objectForKey:[aTableColumn identifier]];
}


- (void) tableView:(NSTableView *)tv willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if ([[tableColumn identifier] isEqualToString:@"Icon"]){
        NSString *exceptionName = [[failures objectAtIndex:row] objectForKey:@"Type"];
        [cell setBackgroundColor:[exceptionName isEqualToString:NSLocalizedString (SenTestFailureException, @"")] ? [NSColor redColor] : [NSColor blackColor]];
        [cell setDrawsBackground:YES];
    }
}
@end
