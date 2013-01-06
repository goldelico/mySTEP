/*
    Copyright (c) 1995-1997, Apple Enterprise Software, Inc.  All rights reserved.
*/

#import <WebObjects/WebObjects.h>

int main(int argc, const char *argv[])
{
    // WOApplicationMain() will process the arguments to this application and
    // create an instance of the application. The application instance is then sent
    // the init message, followed by the run message, which puts the application
    // into its run loop, listening for requests.
    // The content of this function is documented in WOApplication.h.
    // The first argument to WOApplicationMain() is the name of the principal class
    // for the application. If you have written a custom subclass (e.g. MyApplication)
    // and you wish to use that class as your Application class, then replace the
    // string in the function call below with the new name (@"MyApplication").

    return WOApplicationMain(@"Application", argc, argv);
}
