//
//  TheMissingRadiusController.m
//  The Missing Radius
//
//  Created by Eldon Ahrold on 6/23/13.
//  Copyright (c) 2013 aapps. All rights reserved.
//
#import <Security/Authorization.h>
#import "TheMissingRadiusController.h"

#import "Interfaces.h"

@interface TheMissingRadiusController ()

- (void)appendLog:(NSString *)log;
- (BOOL)emptyFields:(NSArray*)reqFields;

@end


@implementation TheMissingRadiusController

//---------------------------------
//  Private Methods
//---------------------------------

- (void)appendLog:(NSString *)log {
    NSTextStorage *textStore = [_statusField textStorage];
    [textStore appendAttributedString:[[NSAttributedString alloc] initWithString:log]];
}

//  This checks for any empty fileds (Must pass an array of NSTextFields)
- (BOOL)emptyFields:(NSArray*)reqFields {
    NSColor* alertColor = [NSColor yellowColor];
    for (id field in reqFields) {
        NSLog(@"Checking %@",[field stringValue]);
        if ([[field stringValue] isEqual:@""]){
            [field setBackgroundColor:alertColor];
            [field setBordered:YES];
            [self showAlert:@"Please fill out all fields"];
            return NO;
        }
        [field setBackgroundColor:[NSColor whiteColor]];

    }
    return YES;
}

//--------------------------------------------------------------------------------------------
//  Progress Panel Items / Alert
//--------------------------------------------------------------------------------------------
- (void)startProgressPanelWithMessage:(NSString *)message indeterminate:(BOOL)indeterminate {    
    // Display a progress panel as a sheet
    self.progressMessage = message;
    if (indeterminate) {
        [self.progressIndicator setIndeterminate:YES];
    } else {
        [self.progressIndicator setIndeterminate:NO];
        [self.progressIndicator setUsesThreadedAnimation:YES];
        [self.progressIndicator setDoubleValue:0.0];
    }
    [self.progressIndicator startAnimation:self];
    [self.progressCancelButton setEnabled:NO];
    [NSApp beginSheet:self.progressPanel
       modalForWindow:[[NSApplication sharedApplication] mainWindow]
        modalDelegate:self
       didEndSelector:nil
          contextInfo:NULL];
}

- (void)setProgress:(double)progress {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.progressIndicator setDoubleValue:progress];
    }];
}

- (void)setProgress:(double)progress withMessage:(NSString *)message {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.progressIndicator setDoubleValue:progress];
        self.progressMessage = message;
    }];
}

- (void)stopProgressPanel {
    [self.progressPanel orderOut:self];
    [NSApp endSheet:self.progressPanel returnCode:0];
}
- (IBAction)cancel:(id)sender {
    [self.progressPanel orderOut:self];
    [NSApp endSheet:self.progressPanel returnCode:1];
}


- (void)showAlert:(NSString*)msg{
    NSWindow *mainWindow = [[NSApplication sharedApplication] mainWindow];
    
    NSAlert *alert = [[NSAlert alloc] init];
                        [alert setMessageText:msg];
                        [alert addButtonWithTitle:@"OK"];
                        [alert setAlertStyle:NSInformationalAlertStyle];
    
    [alert beginSheetModalForWindow:mainWindow
                         modalDelegate:self
                        didEndSelector:nil
                           contextInfo:nil];
}

- (void)showErrorAlert:(NSError *)error {
    [[NSAlert alertWithError:error] beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow]
                                               modalDelegate:self
                                              didEndSelector:nil
                                                 contextInfo:nil];
}

//-------------------------------------------
//  IBActions 
//-------------------------------------------

- (IBAction)getNasButtonPressed:(id)sender{
    [self startProgressPanelWithMessage:@"Getting List of Connected Devices..." indeterminate:NO];
    NSXPCConnection *connection = [[NSXPCConnection alloc]initWithMachServiceName:kHelperName
                                                                        options:NSXPCConnectionPrivileged];
    
    
    // setting up both the remoteObjectInterface and exportedInterface allows bi-directional communication the methods in the remoteObject Inteface are set in the HelperApp.m and the methods in the exportedInterface are located in this file
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperProgress)];
    connection.exportedObject = self;
    
    [connection resume];
    [[connection remoteObjectProxy] getNasList:^(NSString *response){
                                                 [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                     NSLog(@"%@",response);
                                                     [self appendLog:response];
                                                     [self stopProgressPanel];
                                                 }];
                                                 NSLog(@"ending service");
                                                 [connection invalidate];
                                             }];
}


- (IBAction)getConfigButtonPressed:(id)sender{
    [self startProgressPanelWithMessage:@"Getting Radius Configuration..." indeterminate:NO];
        
    NSXPCConnection *connection = [[NSXPCConnection alloc]initWithMachServiceName:kHelperName
                                                                          options:NSXPCConnectionPrivileged];
    
    
    // setting up both the remoteObjectInterface and exportedInterface allows bi-directional communication the methods in the remoteObject Inteface are set in the HelperApp.m and the methods in the exportedInterface are located in this file
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperProgress)];
    connection.exportedObject = self;
    
    [connection resume];
    [[connection remoteObjectProxy] getConfig:^(NSString *response){
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSLog(@"%@",response);
            [self appendLog:response];
            [self stopProgressPanel];
        }];
        NSLog(@"ending service");
        [connection invalidate];
    }];
}


- (IBAction)addNasButtonPressed:(id)sender{
    NSLog(@"Test Button Pressed");
    
    NSXPCConnection *connection = [[NSXPCConnection alloc]
                                   initWithMachServiceName:kHelperName options:NSXPCConnectionPrivileged];
    
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperProgress)];
    connection.exportedObject = self;

    
    [connection resume];
    [[connection remoteObjectProxy] addNasClient:[_airportIP stringValue]
                                       shortName:[_apShortName stringValue]
                                    sharedSecret:[_sharedSecret stringValue]
                                       withReply:^(NSString *response){
                                           
                                         [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                             NSLog(@"%@",response);
                                             [self appendLog:response];
                                         }];
                                         NSLog(@"ending service");
                                         [connection invalidate];
                                     }];
}

- (IBAction)setConfigButtonPressed:(id)sender{
    NSArray * reqFields = [NSArray arrayWithObjects:_airportIP,
                                                    _radiusServer,
                                                    _sharedSecret,
                                                    nil];
    if(![self emptyFields:reqFields]){
        NSLog(@"Woops");
        return;
    }
    
    NSLog(@"OK");

    NSXPCConnection *connection = [[NSXPCConnection alloc]
                                   initWithMachServiceName:kHelperName options:NSXPCConnectionPrivileged];
    
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperProgress)];
    connection.exportedObject = self;
    
    [connection resume];
    [[connection remoteObjectProxy] setConfig:self.radiusCertificate.titleOfSelectedItem];
    [connection invalidate];

}

- (IBAction)captureButtonPressed:(id)sender{
    NSString* pgmsg = [NSString stringWithFormat:@"Trying to Capture Base Station %@",[_airportIP stringValue]];
    [self startProgressPanelWithMessage:pgmsg indeterminate:YES];
    NSXPCConnection *connection = [[NSXPCConnection alloc]
                                   initWithMachServiceName:kHelperName options:NSXPCConnectionPrivileged];
    
    // Set up bi-directional communication
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperProgress)];
    connection.exportedObject = self;
    
    [connection resume];
    [[connection remoteObjectProxy] captureBaseStation:[_airportIP stringValue]
                                            serverName:[_radiusServer stringValue]
                                          sharedSecret:[_sharedSecret stringValue]
                                             withReply:^(NSString *response){
                                                 [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                     NSLog(@"%@",response);
                                                     [self stopProgressPanel];
                                                     [self appendLog:response];
                                                 }];
                                                 [connection invalidate];
                                             }];
}

- (IBAction)clearStatusWindow:(id)sender{
    NSInteger length = [[_statusField textStorage] length];
    [[_statusField textStorage]replaceCharactersInRange:NSMakeRange(0, length) withString:@""];
}
@end
