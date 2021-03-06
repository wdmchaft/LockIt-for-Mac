//
//  LockScreenView.m
//  LockIt for Mac
//
//  Created by Q on 14.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import "NetworkService.h"
#import "DataModel.h"
#import "GrowlImplementation.h"

@implementation NetworkService
@synthesize response, requestWindow, deviceInfo, otherSender, uuid;

- (id) init {
	self = [super init];
	if (self != nil) {
        serviceBrowser = [[NSNetServiceBrowser alloc] init];
		[serviceBrowser setDelegate:self];
		[serviceBrowser searchForServicesOfType:@"_lockitiphone._tcp." inDomain:@""];
		self.response = [NSMutableData data];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(setHostUUID:)
													 name:@"recieveUUID"
												   object:nil];
        [self getHostUUID];
	}
	return self;
}



-(void)setHostUUID:(NSNotification *)notification{
    self.uuid = [[notification userInfo]objectForKey:@"uuid"];
}

-(void)getHostUUID{
    NSNotificationCenter * center;
    center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:@"getUUID"
                          object:self];
}
 
- (void) dealloc {
    [uuid release];
    [otherSender release];
	[serviceBrowser release];
    [deviceInfo release];
	[response release];
    [requestWindow release];

	[super dealloc];
}

// Error handling code
- (void)handleError:(NSNumber *)error {
    NSLog(@"An error occurred. Error code = %d", [error intValue]);
    // Handle error here
}

#pragma mark -
#pragma mark NetServices delegate methods
// Sent when browsing begins
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser {
	// Show a spinning wheel or something else
}

// Sent when browsing stops
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser {
	// Stop the spinning wheel
}

// Sent if browsing fails
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
			 didNotSearch:(NSDictionary *)errorDict {
    [self handleError:[errorDict objectForKey:NSNetServicesErrorCode]];
}

// Sent when a service appears
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
		   didFindService:(NSNetService *)aNetService
			   moreComing:(BOOL)moreComing {
    
//	NSLog(@"Found NetService: %@", [aNetService name]);
	
	NSString *cache1 = [NSString stringWithFormat:@"%@ %@", [aNetService name], @"connected"];
//	NSString *cache2 = [NSString stringWithFormat:@"%@ %@\n%@\n%@", [aNetService name], @"connected", [aNetService hostName], [aNetService port]];
	
    [GrowlImplementation sendGrowlNotifications:[aNetService name] :cache1 :@"Connect/Disconnect notifications":@"Extra Bonjour.png"];
 //   [self sendGrowlNotifications:[aNetService name] :cache2 :@"Go on/off detail"];
	
	[aNetService setDelegate:self];
	[aNetService resolveWithTimeout:2];
	[aNetService retain];
}

// Sent when a service disappears
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
		 didRemoveService:(NSNetService *)aNetService
			   moreComing:(BOOL)moreComing {
	
	NSString *cache1 = [NSString stringWithFormat:@"%@ %@", [aNetService name], @"disconnected"];
	
	//[self sendGrowlNotifications:[aNetService name] :cache1 :@"Go on/off"];
    [GrowlImplementation sendGrowlNotifications:[aNetService name] :cache1 :@"Connect/Disconnect notifications":@"Extra Bonjour.png"];
    
//	NSLog(@"Lost  NetService: %@", [aNetService name]);
    
    NSDictionary *devInfo  = [NSDictionary dictionaryWithObjectsAndKeys:[aNetService name], @"deviceName", nil];
    
    NSNotificationCenter * center;
	center = [NSNotificationCenter defaultCenter];
	[center postNotificationName:@"removeDevice"
						  object:self
						userInfo:devInfo];
    
}

// NetService is now ready to be used
- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    NSLog(@"NetService-UUID: %@",self.uuid);
    NSString *urlString   = [NSString stringWithFormat:@"http://%@:%i/%@/identify", [sender hostName], [sender port], self.uuid];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    self.otherSender = sender;
}

// NetService didn't resolve the request. Push a growl notification
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    [self handleError:[errorDict objectForKey:NSNetServicesErrorCode]];
    NSLog(@"fail: DID NOT RESOLVE!");
    NSString *cache1 = [NSString stringWithFormat:@"%@\n%@",@"Error to connect to an client",[[errorDict objectForKey:NSNetServicesErrorCode] localizedDescription]] ;
    [GrowlImplementation sendGrowlNotifications:@"Error" :cache1 :@"Go on/off":@"Extra Bonjour.png"];
	[sender release];
}


#pragma mark -
#pragma mark NSConnection delegate methods

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)urlResponse {
	[self.response setLength:0];
}

- (void)connection:(NSURLConnection *)connection
	didReceiveData:(NSData *)data {
	// Received another block of data. Appending to existing data
    [self.response appendData:data];
}

// An error occured by NSURLConnection
- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error {
    NSLog(@"%@",[error localizedDescription]);
    NSString *cache1 = [NSString stringWithFormat:@"%@\n%@",@"Error to connect to an client",[error localizedDescription]] ;
	NSLog(@"%@",[error localizedDescription]);
	[GrowlImplementation sendGrowlNotifications:@"Error" :cache1 :@"Go on/off":@"Extra Bonjour.png"];
}

// Connection finished loading. Add the device to dataArray by NSNotification. Once this method is invoked, "serverResponse" contains the complete result
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
	NSPropertyListFormat format;
    NSDictionary *dict =  [NSPropertyListSerialization propertyListFromData:self.response mutabilityOption:0 format:&format errorDescription:nil];
    
    NSDictionary *devInfo  = [NSDictionary dictionaryWithObjectsAndKeys:[otherSender name], @"deviceName", [otherSender hostName], @"deviceHostname", [NSNumber numberWithInteger:[otherSender port]], @"devicePort", [dict objectForKey:@"uuid"], @"deviceUUID", nil];
    
    NSNotificationCenter * center;
	center = [NSNotificationCenter defaultCenter];
	[center postNotificationName:@"addDevice"
						  object:self
						userInfo:devInfo];
}

@end