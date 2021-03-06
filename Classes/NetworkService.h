//
//  LockScreenView.m
//  LockIt for Mac
//
//  Created by Q on 14.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface NetworkService : NSObject  {
	NSNetServiceBrowser *serviceBrowser;
	NSMutableData *response;
    NSMutableArray *deviceInfo;
    NSURLConnection *connection;
    NSNetService *otherSender;
    NSString *uuid;
    
    NSWindow *requestWindow;
}

@property (nonatomic, retain) NSMutableData *response;
@property (assign) IBOutlet NSWindow *requestWindow;
@property (nonatomic,retain)NSMutableArray *deviceInfo;
@property (nonatomic,retain)NSNetService *otherSender;
@property (nonatomic,retain)NSString *uuid;

-(void)setHostUUID:(NSNotification *)notification;
-(void)getHostUUID;

@end
