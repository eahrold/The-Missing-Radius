//
//  TheMissingRadiusHelper.m
//  The Missing Radius
//
//  Created by Eldon Ahrold on 7/10/13.
//  Copyright (c) 2013 aapps. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import <syslog.h>
#import "TheMissingRadiusHelper.h"
#import "Interfaces.h"

#define hLog(fmt, ...) syslog(LOG_NOTICE, [[NSString stringWithFormat:fmt, ##__VA_ARGS__] UTF8String]);
#define doSleep(fmt, ...)  [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow: fmt, ##__VA_ARGS__]];

@implementation TheMissingRadiusHelper
@synthesize helperToolShouldQuit;

//----------------------------------------
// Helper Singleton 
//----------------------------------------
+ (TheMissingRadiusHelper *)sharedAgent {
    static dispatch_once_t onceToken;
    static TheMissingRadiusHelper *shared;
    dispatch_once(&onceToken, ^{
        shared = [TheMissingRadiusHelper new];
    });
    return shared;
}


//----------------------------------------
// Set up the one method of NSXPClistener
//----------------------------------------
- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    newConnection.exportedObject = self;
    
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperProgress)];
    self.xpcConnection = newConnection;
    
    [newConnection resume];
    return YES;
}


//----------------------------------------
// Protocol methods from Interfaces.h
//----------------------------------------

// *** Process Methods *** //
-(void)startRadiusServer{
    NSTask *task = [[NSTask alloc] init];
    [task setStandardOutput: [NSPipe pipe]];
    [task setStandardInput: [NSPipe pipe]];
    [task setStandardError: [task standardOutput]]; // Get standard error output too
    [task setLaunchPath: @"/bin/launchctl"];
    [task setArguments:[NSArray arrayWithObjects:@"load",@"-w",@"/System/Library/LaunchDaemons/org.freeradius.radiusd.plist",nil]];
    
}


-(void)quitHelper{
    self.helperToolShouldQuit = YES;
}
// *** End Process Methods *** //



// *** Status Methods *** //
-(void)getConfig:(void (^)(NSString *response))reply;{
    NSString* response;
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/sbin/radiusconfig"];
    [task setArguments:[NSArray arrayWithObjects:@"-getconfig",nil]];
    
    //Set up Pipes
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardInput:[NSPipe pipe]];
    [task setStandardOutput:outputPipe];
    [task setStandardError: [task standardOutput]]; // Get standard error output too

    [task launch];
    
    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    response = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    
    reply(response);
}

-(void)getNasList:(void (^)(NSString *response))reply{
    NSString* response;
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/sbin/radiusconfig"];
    [task setArguments:[NSArray arrayWithObjects:@"-naslistxml",@"--with-status", nil]];
    
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardInput:[NSPipe pipe]];
    [task setStandardOutput:outputPipe];
    
    [task launch];
    //[task waitUntilExit];
    
    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    response = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    
    
    // This is just UI junkFood to demo how the helper app can update the main app
    double progress = 0;
    [[self.xpcConnection remoteObjectProxy] setProgress:progress];
    
    double i  = 0;
    for (i=0 ;  i < 100; i++) {
        progress = i;
        [[self.xpcConnection remoteObjectProxy] setProgress:progress];
        doSleep(0.01); // we'll run the macro just slow down the UI a little
    }
    reply(response);
}
// *** End Status Methods *** //



//*** Config Setting Methods ***//
-(void)setConfig:(NSString *)certificate{
    
    [self installCerts:certificate];
    
    NSTask *task = [[NSTask alloc] init];
    [task setStandardOutput: [NSPipe pipe]];
    [task setStandardInput: [NSPipe pipe]];
    [task setStandardError: [task standardOutput]]; // Get standard error output too
    [task setLaunchPath: @"/usr/sbin/radiusconfig"];
    [task setArguments:[NSArray arrayWithObjects:@"-setconfig",@"private_key_password",@"Apple:UseCertAdmin",nil]];
    
    //Set up Pipes
    [task setStandardOutput: [NSPipe pipe]];
    [task setStandardInput: [NSPipe pipe]];
    [task setStandardError: [task standardOutput]]; // Get standard error output too
    
    [task launch];
}


-(void)setConfig:(NSString*)certificate withPassword:(NSString *)privateKeyPass{
}


-(void)addNasClient:(NSString*)airport shortName:(NSString*)shortname
 sharedSecret:(NSString*)secret withReply:(void (^)(NSString *response))reply{    
    NSString* sn;
    if([shortname isEqual: @""])
        sn = @"ape_x";
    else
        sn = shortname;

    //Set up Task
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/sbin/radiusconfig"];
    [task setArguments:[NSArray arrayWithObjects:@"-addclient",airport,sn,nil]];

    //Set up Pipes
    [task setStandardOutput: [NSPipe pipe]];
    [task setStandardInput: [NSPipe pipe]];
    [task setStandardError: [task standardOutput]]; // Get standard error output too
    
    [task launch];
    
    //Send the Shared Secret to the command prompt
    NSFileHandle *commandPrompt = [[task standardInput] fileHandleForWriting];
    
    //make sure the string terminates wiht a \n to simulate the enter key
    NSString * secretString = [ NSString stringWithFormat: @"%@\n",secret];
    [commandPrompt writeData:[secretString dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString* response = @"Added NAS to list Station";
    reply(response);
}


-(void)captureBaseStation:(NSString*)airport serverName:(NSString*)server sharedSecret:(NSString*)secret withReply:(void (^)(NSString *response))reply{
   
    NSString* response;
    double progress = 0;
    [[self.xpcConnection remoteObjectProxy] setProgress:progress];
    doSleep(2);
    
    NSArray * pwArray = [self getAirportPassword];
    NSString* password = [pwArray objectAtIndex:0];
    
    if ( [password isEqual: @""] || [password isEqual: @"nopass"]){
        response = @"No password was supplied";
    }
    
    else{
    
        NSTask *task = [[NSTask alloc] init];
        // set up the task
        [task setLaunchPath: @"/usr/sbin/radiusconfig"];
        [task setArguments:[NSArray arrayWithObjects:@"--capture-base-station",airport,server,nil]];

        // set up the pipes
        [task setStandardOutput: [NSPipe pipe]];
        [task setStandardInput: [NSPipe pipe]];
        [task setStandardError: [task standardOutput]]; // Get standard error output too
               
        [task launch];
        
        // radiusconfig will prompt with two items, first prompts for the airport password,
        // then for the shared secret.  Pipe those into the task
        NSFileHandle *commandPrompt = [[task standardInput] fileHandleForWriting];
        NSString * passString = [ NSString stringWithFormat: @"%@\n",password];
        NSString * secString = [ NSString stringWithFormat: @"%@\n",secret];
        
        [commandPrompt writeData:[passString dataUsingEncoding:NSUTF8StringEncoding]];
        [commandPrompt writeData:[secString dataUsingEncoding:NSUTF8StringEncoding]];

        [task waitUntilExit];
        [task terminate];
        
        if (![task isRunning]) {
            int rc = [task terminationStatus];
            if (rc == 0)
                response = [NSString stringWithFormat: @"Captured Base Station %@",airport];
            else
                response = [NSString stringWithFormat: @"Could Not Capture Base Station Eror %d",rc];
        }
    }
    reply(response);
}
//*** End Config Setting Methods ***//



//----------------------------------
//  Private Methods
//----------------------------------
-(void)installCerts:(NSString *)certificate{
    NSString* certKey = [NSString stringWithFormat: @"/etc/certificates/%@.key.pem",certificate];
    NSString* certCert = [NSString stringWithFormat: @"/etc/certificates/%@.cert.pem",certificate];
    NSString* certChain = [NSString stringWithFormat: @"/etc/certificates/%@.chain.pem",certificate];
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/sbin/radiusconfig"];
    [task setArguments:[NSArray arrayWithObjects:@"-installcerts",certKey,certCert,certChain,nil]];
    
    [task setStandardOutput: [NSPipe pipe]];
    [task setStandardInput: [NSPipe pipe]];
    [task setStandardError: [task standardOutput]]; // Get standard error output too
    
    [task launch];
    [task waitUntilExit];
}

-(NSArray*)getAirportPassword{
    CFUserNotificationRef passwordDialog;
	SInt32 error;
	CFOptionFlags responseFlags;
	int button;
	CFStringRef passwordRef;
	
	NSMutableArray *returnArray = [NSMutableArray arrayWithObjects:@"nopass",[NSNumber numberWithInt:0],nil];
	
	NSString *passwordMessageString = @"Please enter the Base Station Password";
    NSString *explanationString = @"we need that to attempt to caputer the base station";
	
    
	NSDictionary *panelDict = [NSDictionary dictionaryWithObjectsAndKeys:passwordMessageString,kCFUserNotificationAlertHeaderKey,
                                                                        explanationString,kCFUserNotificationTextFieldTitlesKey,
                                                                        @"Cancel",kCFUserNotificationAlternateButtonTitleKey,
                                                                        nil];
	
	passwordDialog = CFUserNotificationCreate(kCFAllocatorDefault,
											  0,
											  kCFUserNotificationPlainAlertLevel
											  |
											  CFUserNotificationSecureTextField(0),
											  &error,
											  (__bridge CFDictionaryRef)panelDict);
	
	
    
	if (error){
		// There was an error creating the password dialog
		CFRelease(passwordDialog);
		[returnArray replaceObjectAtIndex:1 withObject:[NSNumber numberWithInt:error]];
		return returnArray;
	}
	

	error = CFUserNotificationReceiveResponse(passwordDialog,
											  0,
											  &responseFlags);
    
	if (error){
		CFRelease(passwordDialog);
		[returnArray replaceObjectAtIndex:1 withObject:[NSNumber numberWithInt:error]];
		return returnArray;
	}
	
	
	button = responseFlags & 0x3;
	if (button == kCFUserNotificationAlternateResponse) {
		CFRelease(passwordDialog);
		[returnArray replaceObjectAtIndex:1 withObject:[NSNumber numberWithInt:1]];
		return returnArray;
	}
	

	passwordRef = CFUserNotificationGetResponseValue(passwordDialog,
													 kCFUserNotificationTextFieldValuesKey,
													 0);
	
	
	[returnArray replaceObjectAtIndex:0 withObject:(__bridge NSString*)passwordRef];
	CFRelease(passwordDialog); // Note that this will release the passwordRef as well
    

	return returnArray;
}


@end
