//
//  VZMpcManager.m
//  OutsideChat
//
//  Created by Victor Zhou on 7/11/15.
//  Copyright (c) 2015 Victor Zhou. All rights reserved.
//

#import "VZMpcManager.h"

@implementation VZMpcManager
{
    CLLocationManager *_manager;
}

+ (id)shared {
    static VZMpcManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

-(id)init
{
    self = [super init];
    
    if (self) {
        _sessions = [[NSMutableDictionary alloc] init];
        _currentlyConnectingSessions = [[NSMutableArray alloc] init];
        
        //init sent/stored message if necessary
        if (!SENT_MESSAGES) {
            SET_SENT_MESSAGES([[NSMutableDictionary alloc] init]);
            SYNC_STORAGE();
        }
        if (!STORED_MESSAGES) {
            SET_STORED_MESSAGES([[NSMutableArray alloc] init]);
            SYNC_STORAGE();
        }
        
        //geolocation
        _manager = [[CLLocationManager alloc] init];
        _manager.delegate = self;
        _manager.distanceFilter = 20.0; //meters
        _manager.desiredAccuracy = kCLLocationAccuracyBest;
        if ([_manager respondsToSelector:@selector(requestWhenInUseAuthorization)])
        {
            [_manager requestWhenInUseAuthorization];
        }
        [_manager startUpdatingLocation];
        
        [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(trySendLocationUpdate) userInfo:nil repeats:false];
        [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(trySendLocationUpdate) userInfo:nil repeats:true];
    }
    
    return self;
}

#pragma mark Public
-(void)setupPeerWithName:(NSString *)displayName
{
    self.myID = [displayName copy];
    
    _peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
    
    _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:_peerID serviceType:DEFAULT_SERVICE_TYPE];
    _browser.delegate = self;
    [_browser startBrowsingForPeers];
    
    _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_peerID
                                                    discoveryInfo:nil
                                                      serviceType:DEFAULT_SERVICE_TYPE];
    _advertiser.delegate = self;
    [_advertiser startAdvertisingPeer];
    
    DLog(@"Set up peer with display name: %@", displayName);
}

-(void)sendDirectMessage:(NSString *)message to:(NSString *)recipientID
{
    VZDirectMessage *dm = [[VZDirectMessage alloc] initWithMessage:message recipient:recipientID userID:_peerID.displayName];
    
    if (![_sessions objectForKey:recipientID]) {
        DLog(@"Could not send direct message straight to %@ -- there was no existing connection.", recipientID);
        
        //send to all connected peers for storage, also store locally
        [self sendMessageToAllPeers:dm ignoring:nil];
        
        //store this message for future peers-----
        [self _storeMessage:dm];
    }
    else
    {
        MCSession *session = _sessions[recipientID];
        NSError *error;
        [session sendData:dm.data toPeers:session.connectedPeers withMode:MCSessionSendDataUnreliable error:&error];
        if (error) {
            DLog(@"\n***** ERROR *****\nSending message to %@ failed with error %@.", recipientID, error.localizedDescription);
            [self _storeMessage:dm];
        }
    }
}

-(void)trySendLocationUpdate
{
    DLog(@"Trying to send location update...");
    CLLocation *loc = _manager.location;
    
    if (loc) {
        [self sendLocationUpdate:loc];
    }
}

-(void)sendLocationUpdate:(CLLocation *)loc
{
    DLog(@"Sending location update with location: %f,%f", loc.coordinate.latitude, loc.coordinate.longitude);
    
    VZMessage *m = [[VZMessage alloc] initWithMessage:[NSString stringWithFormat:@"%f\n%f", (float)loc.coordinate.latitude, (float)loc.coordinate.longitude]
                                               userID:_peerID.displayName
                                               header:LOCATION_MESSAGE_HEADER];
    
    [self sendMessageToAllPeers:m ignoring:nil];
    
    [self _storeMessage:m];
}

-(void)sendAdminUpdate:(NSString *)message
{
    VZMessage *m = [[VZMessage alloc] initWithMessage:message
                                               userID:_peerID.displayName
                                               header:ADMIN_MESSAGE_HEADER];
    
    [self sendMessageToAllPeers:m ignoring:nil];
    
    [self _storeMessage:m];
}

-(void)trySendWeatherUpdate
{
    //this includes our weather api key
    NSURL *url = [NSURL URLWithString:@"http://api.wunderground.com/api/60206f760a43cef5/conditions/q/CA/San_Francisco.json"];
    
    // create a GET request
    SGHTTPRequest *req = [SGHTTPRequest requestWithURL:url];
    
    // optional success handler
    req.onSuccess = ^(SGHTTPRequest *_req)
    {
        DLog(@"Weather Response: %@", _req.responseString);
        
        NSData *jsonData = [_req.responseString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *myError = nil;
        NSDictionary *res = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&myError];
        
        NSString *tempF = @"", *windMPH = @"", *precip1hr = @"", *precipToday = @"";
        
        if (res[@"current_observation"][@"temp_f"])
            tempF = res[@"current_observation"][@"temp_f"];
        if (res[@"current_observation"][@"wind_mph"])
            windMPH = res[@"current_observation"][@"wind_mph"];
        if (res[@"current_observation"][@"precip_1hr_string"])
            precip1hr = res[@"current_observation"][@"precip_1hr_string"];
        if (res[@"current_observation"][@"precip_today_string"])
            precipToday = res[@"current_observation"][@"precip_today_string"];
        
        tempF = [NSString stringWithFormat:@"%.1f", [tempF floatValue]];
        
        NSString *weatherMessage = [NSString stringWithFormat:@"It is currently %@ degrees Fahrenheit with %@ MPH winds.\nThe precipitation for the next hour is %@, and the precipitation for the entire day today will be %@.", tempF, windMPH, precip1hr, precipToday];
        
        DLog(@"Generated Weather update message: %@", weatherMessage);
        
        VZMessage *m = [[VZMessage alloc] initWithMessage:weatherMessage
                                                   userID:_peerID.displayName
                                                   header:WEATHER_MESSAGE_HEADER];
        
        [self sendMessageToAllPeers:m ignoring:nil];
        
        [self _storeMessage:m];
        
    };
    
    // optional failure handler
    req.onFailure = ^(SGHTTPRequest *_req)
    {
        DLog(@"Weather Error with status code %d: %@", (int)_req.statusCode, _req.error.localizedDescription);
    };
    
    // start the request in the background
    [req start];
    DLog(@"Trying to request weather data...");
}

-(int)sendMessageToAllPeers:(VZMessage *)message ignoring:(NSArray *)ignores
{
    NSMutableArray *sentArray = [[NSMutableArray alloc] init];
    int sentNum = 0;
    
    for (NSString *key in _sessions)
    {
        MCSession *tempSession = _sessions[key];
        
        if ([ignores containsObject:tempSession])
            continue;
        
        //send this message to the other guy in this session
        NSError *error;
        [tempSession sendData:message.data toPeers:tempSession.connectedPeers withMode:MCSessionSendDataUnreliable error:&error];
        if (error) {
            DLog(@"\n***** ERROR *****\nsending message failed with error: %@", error.localizedDescription);
        }
        else
        {
            sentNum++;
            [sentArray addObject:((MCPeerID *)(tempSession.connectedPeers[0])).displayName];
        }
    }
    
    //record the display names this message has been sent to
    NSMutableDictionary *sent = [SENT_MESSAGES mutableCopy];
    [sent setObject:sentArray forKey:message.dictionary[KEY_ID]];
    SET_SENT_MESSAGES(sent);
    SYNC_STORAGE();
    
    DLog(@"Sent message %@ to %d peers", message, sentNum);
    
    return sentNum;
}

#pragma mark MCSessionDelegate
-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnected)
    {
        DLog(@"Session with %@ connected.", peerID.displayName);
        _sessions[peerID.displayName] = session;
        if ([_currentlyConnectingSessions containsObject:session]) {
            [_currentlyConnectingSessions removeObject:session];
        }
        
        //see if there's stuff we need to forward to this new peer
        DLog(@"%d items in stored messages.", (int)[STORED_MESSAGES count]);
        for (NSData *data in STORED_MESSAGES)
        {
            VZMessage *m = [[VZMessage alloc] initWithData:data];
            NSString *newPeerName = ((MCPeerID *)session.connectedPeers[0]).displayName;
            
            //check if this guy is the sender of that message
            if ([newPeerName isEqualToString:m.dictionary[KEY_SENDER]])
                continue;
            
            //check if already sent to this guy before
            NSArray *sentArray = [SENT_MESSAGES objectForKey:m.dictionary[KEY_ID]];
            if (sentArray)
            {
                if ([sentArray containsObject:newPeerName])
                    continue;
            }
            
            //if we get here, we need to send the data to this peer
            NSError *error;
            [session sendData:data toPeers:session.connectedPeers withMode:MCSessionSendDataUnreliable error:&error];
            if (error) {
                DLog(@"\n***** ERROR *****\nsending data to new peer %@ failed with error: %@", peerID.displayName, error.localizedDescription);
            }
            else
            {
                DLog(@"Sent stored data to new peer %@.\n", peerID.displayName);
                NSMutableDictionary *sentDict = [SENT_MESSAGES mutableCopy];
                NSMutableArray *sentArray = [[sentDict objectForKey:m.dictionary[KEY_ID]] mutableCopy];
                if (!sentArray) {
                    sentArray = [[NSMutableArray alloc] init];
                }
                [sentArray addObject:((MCPeerID *)session.connectedPeers[0]).displayName];
                [sentDict setObject:sentArray forKey:m.dictionary[KEY_ID]];
                SET_SENT_MESSAGES(sentDict);
                SYNC_STORAGE();
            }
        }
        
    }
    else if (state == MCSessionStateConnecting)
    {
        DLog(@"Connecting to %@...", peerID.displayName);
    }
    else if (state == MCSessionStateNotConnected)
    {
        DLog(@"Session with %@ disconnected.", peerID.displayName);
        if (_sessions[peerID.displayName]) {
            [_sessions removeObjectForKey:peerID.displayName];
        }
        if ([_currentlyConnectingSessions containsObject:session]) {
            [_currentlyConnectingSessions removeObject:session];
        }
        
    }
}


-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    VZMessage *dm = [[VZMessage alloc] initWithData:data];
    
    if ([dm.dictionary[KEY_TYPE] intValue] == VZMessageTypeDefault)
    {
        //DEFAULT message
        DLog(@"Received Message (type Default)");
        
        //process the message locally
        NSString *text = dm.dictionary[KEY_MESSAGE];
        if ([[text substringToIndex:LOCATION_MESSAGE_HEADER.length] isEqualToString:LOCATION_MESSAGE_HEADER])
        {
            //location
            DLog(@"Default Message is a Location message");
            NSString *body = [text substringFromIndex:LOCATION_MESSAGE_HEADER.length];
            NSArray *components = [body componentsSeparatedByString:@"\n"];
            
            if (components.count != 2) {
                DLog(@"\n*****ERRROR*****\nThere are %d components when split by newline.", (int)components.count);
                return;
            }
            
            float latitude = [components[0] floatValue];
            float longitude = [components[1] floatValue];
            
            CLLocation *loc = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:VZNotificationNameLocationMessage
                                                                object:nil
                                                              userInfo:@{VZNotificationKeyLocation : loc,
                                                                         VZNotificationKeyLocationPeer : dm.dictionary[KEY_SENDER]}];
            
            NSMutableDictionary *stored = [STORED_LOCATIONS mutableCopy];
            stored[dm.dictionary[KEY_SENDER]] = @{VZLocationStoreLatitudeKey : @(latitude),
                                                  VZLocationStoreLongitudeKey : @(longitude),
                                                  VZLocationStoreTimestampKey : dm.dictionary[KEY_TIMESTAMP]};
            SET_STORED_LOCATIONS(stored);
            SYNC_STORAGE();
        }
        else if ([[text substringToIndex:ADMIN_MESSAGE_HEADER.length] isEqualToString:ADMIN_MESSAGE_HEADER])
        {
            //admin blast
            DLog(@"Default Message is an Admin message");
            NSString *body = [text substringFromIndex:ADMIN_MESSAGE_HEADER.length];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:VZNotificationNameAdminMessage
                                                                object:nil
                                                              userInfo:@{VZNotificationKeyAdminMessage : body}];
            
            [[[UIAlertView alloc] initWithTitle:@"Alert from Outside Lands"
                                        message:body
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
        else if ([[text substringToIndex:WEATHER_MESSAGE_HEADER.length] isEqualToString:WEATHER_MESSAGE_HEADER])
        {
            //weather update
            DLog(@"Default Message is a Weather message");
            NSString *body = [text substringFromIndex:WEATHER_MESSAGE_HEADER.length];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:VZNotificationNameWeatherMessage
                                                                object:nil
                                                              userInfo:@{VZNotificationKeyWeatherMessage : body}];
            
            if ([[NSDate date] timeIntervalSinceDate:LAST_WEATHER_UPDATE] >= MIN_WEATHER_UPDATE_TIMEOUT)
            {
                [[[UIAlertView alloc] initWithTitle:@"Weather Update"
                                            message:body
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
                SET_LAST_WEATHER_UPDATE([NSDate date]);
                SYNC_STORAGE();
            }
        }
        else
        {
            DLog(@"\n*****ERROR*****\n: Could not determine type of message:\n%@", text);
        }
        
        //spread the message on
        [self sendMessageToAllPeers:dm ignoring:@[session]];
        
        //store for future peers
        [self _storeMessage:dm];
    }
    else
    {
        DLog(@"Received Message (type Direct)");
        
        VZDirectMessage *m = [[VZDirectMessage alloc] initWithData:data];
        
        //DIRECT message
        if ([m decryptedSuccessfully:_peerID.displayName])
        {
            DLog(@"Successfully decrypted direct message from %@", peerID.displayName);
            
            [self storeContactMessage:m];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:VZNotificationNameDirectMessage
                                                                object:nil
                                                              userInfo:@{VZNotificationKeyMessage : m}];
//                                                              userInfo:@{VZNotificationKeyMessage : [m decryptedMessage:_peerID.displayName]}];
        }
        else
        {
            //couldn't decrypt, so forward
            DLog(@"Failed to decrypt direct message from %@", peerID.displayName);
            
            [self sendMessageToAllPeers:m ignoring:@[session]];
            
            //store this message for future peers
            [self _storeMessage:m];
        }
    }
}


-(void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    DLog(@"\n*****ERRROR*****\nReceiving Resource even though this should not be possible.\nName:%@\nPeer:%@", resourceName, peerID.displayName);
}

-(void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    DLog(@"\n*****ERRROR*****\nFinished Receiving Resource even though this should not be possible.\nName:%@\nPeer:%@", resourceName, peerID.displayName);
}


-(void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    DLog(@"\n*****ERRROR*****\nReceiving Stream even though this should not be possible.\nName:%@\nPeer:%@", streamName, peerID.displayName);
}


#pragma mark MCNearbyServiceAdvertiserDelegate
-(void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context  invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler
{
    DLog(@"Advertiser received invitation from peer: %@", peerID);
    MCSession *session = [[MCSession alloc] initWithPeer:_peerID];
    session.delegate = self;
    [_currentlyConnectingSessions addObject:session];
    invitationHandler(true, session);
}

#pragma mark MCNearbyServiceBrowserDelegate
-(void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    DLog(@"\n***** ERROR *****\nBrowser did not start browsing for peers.");
}

-(void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    //invite using default timeout
    DLog(@"Found Peer: %@", peerID.displayName);
    if ([self _shouldInvitePeer:peerID])
    {
        DLog(@"Inviting Peer: %@", peerID.displayName);
        MCSession *session = [[MCSession alloc] initWithPeer:_peerID];
        session.delegate = self;
        [_currentlyConnectingSessions addObject:session];
        [browser invitePeer:peerID toSession:session withContext:nil timeout:0];
    }
}

-(void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    DLog(@"Lost peer: %@", peerID.displayName);
}

#pragma mark CLLocationManager Delegate

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    DLog(@"Location Manager failed with error: %@", error.localizedDescription);
}
-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    CLLocation *currentLocation = newLocation;
    if (currentLocation != nil) {
        [self sendLocationUpdate:newLocation];
    }
}

#pragma mark Private
-(BOOL)_shouldInvitePeer:(MCPeerID *)peerID
{
    //only invite if alphabetically before the other peer
    NSComparisonResult result = [_peerID.displayName compare:peerID.displayName];
    if (result == NSOrderedSame && [peerID isEqual:_peerID])
        DLog(@"Other peer is self...");
    else
        DLog(@"\n***** ERROR *****\nOther peer has same display name as local peer!");
    
    return (result == NSOrderedAscending);
}

-(void)_storeMessage:(VZMessage *)message
{
    NSMutableArray *stored = [STORED_MESSAGES mutableCopy];
    [stored addObject:message.data];
    SET_STORED_MESSAGES(stored);
    SYNC_STORAGE();
    DLog(@"Stored messages now has %d items", (int)[STORED_MESSAGES count]);
}

-(NSMutableArray *)getContactMessagesForContact:(NSString *)contact
{
    NSMutableDictionary *allMessages = [CONTACT_MESSAGES mutableCopy];
    NSMutableArray *contactMessages = [allMessages objectForKey:contact];
    if (!contactMessages) {
        contactMessages = [[NSMutableArray alloc] init];
    }
    return contactMessages;
}

-(void)storeContactMessage:(VZMessage *)message
{
    NSMutableArray *messages = [self getContactMessagesForContact:[message getSender]];
    [messages addObject:message];
}
@end
