#import <CoreData/CoreData.h>

#ifndef ASSIGN
#define ASSIGN(VAR, VAL) [(VAR) autorelease], (VAR)=[(VAL) retain]
#endif
#ifndef ASSIGNCOPY
#define ASSIGNCOPY(VAR, VAL) [(VAR) autorelease], (VAR)=[(VAL) copy]
#endif
#ifndef DESTROY
#define DESTROY(VAR) [(VAR) release], (VAR)=nil
#endif
#ifndef TEST_RELEASE
#define TEST_RELEASE(VAR) if(VAR) [(VAR) release]
#endif
#ifndef _
#define _(STR) STR
#endif
#ifndef sel_eq
#ifdef __APPLE__
#define sel_eq(A, B) ((A) == (B))
#endif
#endif

#ifndef NSDebugLog
#define NSDebugLog(FMT, ARGS...) 
#endif

@interface NSManagedObjectModel (Private)
- (NSDictionary *) entitiesByNameForConfiguration: (NSString *) configuration;
@end
