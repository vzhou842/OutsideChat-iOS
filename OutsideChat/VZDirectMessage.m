//
//  VZDirectMessage.m
//  OutsideChat
//
//  Created by Victor Zhou on 7/11/15.
//  Copyright (c) 2015 Victor Zhou. All rights reserved.
//

#import "VZDirectMessage.h"
#import "JSQMessage.h"
#import "Constants.h"
#import "VZMpcManager.h"

@implementation VZDirectMessage

-(instancetype)initWithMessage:(NSString *)message recipient:(NSString *)recipient userID:(NSString *)user
{
    if (self = [super initWithMessage:message userID:user header:@""])
    {
        self.dictionary[KEY_TYPE] = @VZMessageTypeDirect;
        self.dictionary[KEY_SALT] = [NSString stringWithFormat:@"%d", arc4random()%INT16_MAX];
        self.dictionary[KEY_ENCRYPTED_SALT] = [self.dictionary[KEY_SALT] getAESEncrptyWithKey:recipient];
        self.dictionary[KEY_MESSAGE] = [message getAESEncrptyWithKey:recipient];
        
        self.data = [NSKeyedArchiver archivedDataWithRootObject:self.dictionary];
    }
    
    return self;
}

-(BOOL)decryptedSuccessfully:(NSString *)myID
{
    return ([self.dictionary[KEY_SALT] isEqualToString:[self.dictionary[KEY_ENCRYPTED_SALT] getAESDecrptyWithKey:myID]]);
}

-(NSString *)decryptedMessage:(NSString *)myID
{
    return [self.dictionary[KEY_MESSAGE] getAESDecrptyWithKey:myID];
}

-(JSQMessage *)toJSQMessage
{
    return [[JSQMessage alloc] initWithSenderId:self.dictionary[KEY_SENDER]
                              senderDisplayName:self.dictionary[KEY_SENDER]
                                           date:[NSDate date]
                                           text:[self decryptedMessage:[MPCMANAGER myID]]];
}

@end
