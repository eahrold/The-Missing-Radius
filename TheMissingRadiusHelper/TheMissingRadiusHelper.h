//
//  TheMissingRadiusHelper.h
//  The Missing Radius
//
//  Created by Eldon Ahrold on 7/10/13.
//  Copyright (c) 2013 aapps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Interfaces.h"

@interface TheMissingRadiusHelper : NSObject <HelperAgent,NSXPCListenerDelegate>

@property (nonatomic, assign) BOOL helperToolShouldQuit;

+ (TheMissingRadiusHelper *)sharedAgent;
-(NSArray*)getAirportPassword;
-(void)installCerts:(NSString*)certificate;

@property (weak) NSXPCConnection *xpcConnection;


@end
