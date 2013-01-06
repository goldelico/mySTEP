// define states of the program

extern NSString * const State_Begin;
extern NSString * const State_End;
extern NSString * const State_Process;

@interface MyProcess : NSObject
{
    int count;
}
- (id)init;
- (void)run:(int)times;
@end