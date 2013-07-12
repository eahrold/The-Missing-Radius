//
//  TheMissingRadiusController.h
//  The Missing Radius
//
//  Created by Eldon Ahrold on 6/23/13.
//  Copyright (c) 2013 aapps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>


@interface TheMissingRadiusController : NSObject

@property (assign) IBOutlet NSTextView * statusField;

@property (assign) IBOutlet NSTextField* radiusServer;
@property (assign) IBOutlet NSTextField* secondaryServer;

@property (assign) IBOutlet NSTextField* airportIP;
@property (assign) IBOutlet NSTextField* apShortName;

@property (assign) IBOutlet NSTextField* sharedSecret;

@property (assign) IBOutlet NSTabView* tmrTabs;
@property (assign) IBOutlet NSButton* captureButton;
@property (assign) IBOutlet NSButton* addNasButton;

@property (assign) IBOutlet NSButton* getNasListButton;
@property (assign) IBOutlet NSButton* getConfigButton;

@property (assign) IBOutlet NSPopUpButton* radiusCertificate;

@property (assign) IBOutlet NSPanel *progressPanel;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSButton *progressCancelButton;
@property (copy) NSString *progressMessage;

@end
