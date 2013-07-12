//
//  Interfaces.h
//  The Missing Radius
//
//  Created by Eldon Ahrold on 7/10/13.
//  Copyright (c) 2013 aapps. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kHelperName @"com.aapps.TheMissingRadiusHelper"


@protocol HelperAgent <NSObject>

-(void)addNasClient:(NSString*)airport
          shortName:(NSString*)shortname
       sharedSecret:(NSString*)secret
          withReply:(void (^)(NSString *response))reply;

-(void)captureBaseStation:(NSString*)airport
               serverName:(NSString*)server
             sharedSecret:(NSString*)secret
                withReply:(void (^)(NSString *response))reply;


-(void)startRadiusServer;

-(void)getConfig:(void (^)(NSString *response))reply;
-(void)getNasList:(void (^)(NSString *response))reply;

-(void)setConfig:(NSString*)certificate;
-(void)setConfig:(NSString*)certificate withPassword:(NSString*)privateKeyPass;


-(void)quitHelper;

@end

@protocol HelperProgress
- (void)setProgress:(double)progress;
- (void)setProgress:(double)progress withMessage:(NSString*)message;
@end