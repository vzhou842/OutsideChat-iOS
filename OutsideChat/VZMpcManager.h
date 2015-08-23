//
//  VZMpcManager.h
//  OutsideChat
//
//  Created by Victor Zhou on 7/11/15.
//  Copyright (c) 2015 Victor Zhou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "Constants.h"
#import "VZDirectMessage.h"
#import <SGHTTPRequest/SGHTTPRequest.h>

#define SENT_MESSAGES (NSMutableDictionary *)[STORAGE objectForKey:@"sent_message"]
#define SET_SENT_MESSAGES(a) [STORAGE setObject:a forKey:@"sent_message"]

#define CONTACT_MESSAGES (NSMutableDictionary *)[STORAGE objectForKey:@"contact_messages"]
#define SET_CONTACT_MESSAGES(a) [STORAGE setObject:a forKey:@"contact_messages"]

#define STORED_MESSAGES (NSMutableArray *)[STORAGE objectForKey:@"stored_messages"]
#define SET_STORED_MESSAGES(a) [STORAGE setObject:a forKey:@"stored_messages"]


@interface VZMpcManager : NSObject <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) NSString *myID;

@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) NSMutableDictionary *sessions;
@property (nonatomic, strong) NSMutableArray *currentlyConnectingSessions;

@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;

+ (id)shared;

-(void)setupPeerWithName:(NSString *)displayName;

-(void)sendDirectMessage:(NSString *)message to:(NSString *)recipientID;
-(void)trySendLocationUpdate;
-(void)sendLocationUpdate:(CLLocation *)loc;
-(void)sendAdminUpdate:(NSString *)message;
-(void)trySendWeatherUpdate;

///returns the number of messages sent
-(int)sendMessageToAllPeers:(VZMessage *)message ignoring:(NSArray *)ignores;

-(NSMutableArray *)getContactMessagesForContact:(NSString *)contact;
-(void)storeContactMessage:(VZMessage *)message;
@end
