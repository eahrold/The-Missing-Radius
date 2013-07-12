//
//  AppDelegate.m
//  The Missing Radius
//
//  Created by Eldon Ahrold on 6/23/13.
//  Copyright (c) 2013 aapps. All rights reserved.
//

#import <ServiceManagement/ServiceManagement.h>

#import "TheMissingRadiusDelegate.h"
#import "Interfaces.h"

@interface TheMissingRadiusDelegate ()

-(void)appendLog:(NSString *)log;
-(BOOL)blessHelperWithLabel:(NSString *)label error:(NSError **)error;
-(BOOL)helperNeedsInstalling;
-(void)tellHelperToQuit;

@end

@implementation TheMissingRadiusDelegate

- (void)appendLog:(NSString *)log {
    NSString * msg = [NSString stringWithFormat:@"%@\n",log];
    [[_statusField textStorage] appendAttributedString:[[NSAttributedString alloc] initWithString:msg]];
}

-(void)tellHelperToQuit{
    // Send a message to the helper tool telling it to call it's quitHelper method.
    NSXPCConnection *connection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperName options:NSXPCConnectionPrivileged];
    
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    [connection resume];
    [[connection remoteObjectProxy] quitHelper];
    [connection invalidate];
}

-(void)setCertList{
    [self.radiusCertificate removeAllItems];
    
    NSArray *certDir = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/etc/certificates" error:nil];
    NSArray *certs = [certDir filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH 'cert.pem'"]];
    NSUInteger count = [certs count];
    
    for (NSUInteger i=0; i < count; i++) {
        NSString * cn = [certs objectAtIndex:i];
        [self.radiusCertificate addItemWithTitle:[cn stringByReplacingOccurrencesOfString:@".cert.pem" withString:@""]];
    }    
}

-(void)setUserDefaults{
    NSUserDefaults * setDefaults = [NSUserDefaults standardUserDefaults];
    
    [setDefaults setObject:self.apShortName.stringValue forKey:@"apShortName"];
    [setDefaults setObject:self.airportIP.stringValue forKey:@"airportID"];
    [setDefaults setObject:self.radiusServer.stringValue forKey:@"radiusServer"];
    [setDefaults setObject:self.secondaryServer.stringValue forKey:@"secondaryServer"];
    
    [setDefaults synchronize];
}

-(void)getUserDefualts{
    NSUserDefaults *getDefaults = [NSUserDefaults standardUserDefaults];
    self.airportIP.stringValue = [getDefaults stringForKey:@"airportID"];
    self.apShortName.stringValue = [getDefaults stringForKey:@"apShortName"];
    self.radiusServer.stringValue = [getDefaults stringForKey:@"radiusServer"];
    self.secondaryServer.stringValue = [getDefaults stringForKey:@"secondaryServer"];

}

-(BOOL)preAuthorize{
    OSStatus result;
    AuthorizationItem authItems = {kAuthorizationRightExecute, 0, NULL, 0};
    AuthorizationRights authRights = {1, &authItems};
    AuthorizationFlags authFlags =  kAuthorizationFlagDefaults |
    kAuthorizationFlagInteractionAllowed |
    kAuthorizationFlagPreAuthorize |
    kAuthorizationFlagExtendRights;
    
    
    AuthorizationRef authRef = NULL;
    
    result =  AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, authFlags, &authRef);
    if (result != errAuthorizationSuccess) {
        [self appendLog:[NSString stringWithFormat:@"Failed to create AuthorizationRef. Error code: %d", result]];
    }
    else {
        result = AuthorizationCopyRights (authRef, &authRights, NULL, authFlags, NULL );
    }
    
    AuthorizationFree (authRef, kAuthorizationFlagDefaults);
    return result;
}

//----------------------------------------------
//  SMJobBless
//----------------------------------------------

- (BOOL)blessHelperWithLabel:(NSString *)label
                       error:(NSError **)error {
    
    OSStatus result;
    
	AuthorizationItem authItem		= { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
	AuthorizationRights authRights	= { 1, &authItem };
	AuthorizationFlags authFlags		=	kAuthorizationFlagDefaults				|
    kAuthorizationFlagInteractionAllowed	|
    kAuthorizationFlagPreAuthorize			|
    kAuthorizationFlagExtendRights;
    
	AuthorizationRef authRef = NULL;
	
	/* Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper). */
    result = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, authFlags, &authRef);
	if (result != errAuthorizationSuccess) {
        [self appendLog:[NSString stringWithFormat:@"Failed to create AuthorizationRef. Error code: %d", result]];
        
	} else {
		/* This does all the work of verifying the helper tool against the application
		 * and vice-versa. Once verification has passed, the embedded launchd.plist
		 * is extracted and placed in /Library/LaunchDaemons and then loaded. The
		 * executable is placed in /Library/PrivilegedHelperTools.
		 */
		result = SMJobBless(kSMDomainSystemLaunchd, (CFStringRef)label, authRef, (CFErrorRef *)error);
	}
    
	AuthorizationFree (authRef, kAuthorizationFlagDefaults);
	return result;
}


-(BOOL)helperNeedsInstalling{
    //This dose the job of checking wether the Helper App needs updateing,
    //Much of this was taken from Eric Gorr's adaptation of SMJobBless http://ericgorr.net/cocoadev/SMJobBless.zip
    OSStatus result = YES;
    
    
    // The SMJobCopyDictionary extracts information we'll need to
    //determine the currently installed helper version.  The kHelperName (defined in SMJobBlessAppController.h)
    // needs to be the same as the "Label" key in the SMJobBlessHelper-Launchd.plist
    NSDictionary* installedHelperJobData = (NSDictionary*)SMJobCopyDictionary( kSMDomainSystemLaunchd, (CFStringRef)kHelperName );
    
    if ( installedHelperJobData ){
        // uncomment the next line if you're interested in seeing what info you can access from the SMJobCopyDictionary
        //NSLog( @"helperJobData: %@", installedHelperJobData );
        
        // Using the returned SMJobCopyDictionary, get the version of the currently installed helper tool
        NSString* installedPath = [[installedHelperJobData objectForKey:@"ProgramArguments"] objectAtIndex:0];
        NSURL* installedPathURL = [NSURL fileURLWithPath:installedPath];
        NSDictionary* installedInfoPlist = (NSDictionary*)CFBundleCopyInfoDictionaryForURL( (CFURLRef)installedPathURL );
        //NSLog(@"installedInfoPlist:%@",installedInfoPlist);
        NSString* installedBundleVersion = [installedInfoPlist objectForKey:@"CFBundleVersion"];
        
        NSLog( @"Currently installed helper version: %@", installedBundleVersion );
        
        
        // Now we'll get the version of the helper that is inside of the Main App's bundle
        NSString * wrapperPath = [NSString stringWithFormat:@"Contents/Library/LaunchServices/%@",kHelperName];
        
        NSBundle* appBundle = [NSBundle mainBundle];
        NSURL* appBundleURL	= [appBundle bundleURL];
        NSURL* currentHelperToolURL	= [appBundleURL URLByAppendingPathComponent:wrapperPath];
        NSDictionary* currentInfoPlist = (NSDictionary*)CFBundleCopyInfoDictionaryForURL( (CFURLRef)currentHelperToolURL );
        NSString* currentBundleVersion = [currentInfoPlist objectForKey:@"CFBundleVersion"];
        
        NSLog( @"Avaliable helper version: %@", currentBundleVersion );
        
        
        // Compare the Version numbers -- This could be done much better...
        if ([installedBundleVersion compare:currentBundleVersion options:NSNumericSearch] == NSOrderedDescending
            || [installedBundleVersion isEqualToString:currentBundleVersion]) {
            NSLog(@"Current version of Helper App installed");
            result = NO;
        }
	}
    return result;
}



//-------------------------------------------------------------------
//  App Delegate Goodies
//-------------------------------------------------------------------

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
//    if (![self preAuthorize] == errAuthorizationSuccess){
//        [NSApp terminate:nil];
//    }
    
    NSError *error = nil;
    if ( [self helperNeedsInstalling] && ![self blessHelperWithLabel:kHelperName error:&error] ){
        [self appendLog:@"Something went wrong!"];
    }
    else{
        [self appendLog:@"Helper installed & available."];
        [self getUserDefualts];
        [self setCertList];
    }

}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication{
    return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification{
    [self tellHelperToQuit];
    [self setUserDefaults];
}

@end
