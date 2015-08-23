//
//  VZDirectMessage.h
//  OutsideChat
//
//  Created by Victor Zhou on 7/11/15.
//  Copyright (c) 2015 Victor Zhou. All rights reserved.
//

#import "VZMessage.h"
#import "JSQMessage.h"

#define KEY_SALT @"salt"
#define KEY_ENCRYPTED_SALT @"encrypted_salt"

@interface VZDirectMessage : VZMessage

-(instancetype)initWithMessage:(NSString *)message recipient:(NSString *)recipient userID:(NSString *)user;

-(BOOL)decryptedSuccessfully:(NSString *)myID;
-(NSString *)decryptedMessage:(NSString *)myID;
-(JSQMessage *)toJSQMessage;

@end
