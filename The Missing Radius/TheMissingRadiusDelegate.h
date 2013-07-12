//
//  AppDelegate.h
//  The Missing Radius
//
//  Created by Eldon Ahrold on 6/23/13.
//  Copyright (c) 2013 aapps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface TheMissingRadiusDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (assign) IBOutlet NSTextView * statusField;

@property (assign) IBOutlet NSTextField* radiusServer;
@property (assign) IBOutlet NSTextField* secondaryServer;

@property (assign) IBOutlet NSTextField* airportIP;
@property (assign) IBOutlet NSTextField* apShortName;

@property (assign) IBOutlet NSTextField* sharedSecret;
@property (assign) IBOutlet NSPopUpButton* radiusCertificate;


@end
