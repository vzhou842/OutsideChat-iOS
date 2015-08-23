//
//  VZMessage.h
//  OutsideChat
//
//  Created by Victor Zhou on 7/12/15.
//  Copyright (c) 2015 Victor Zhou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"
#import <KC_Encryption/EncryptEncodeHelper.h>

#define KEY_TYPE @"type"
#define KEY_MESSAGE @"message"
#define KEY_SENDER @"sender"
#define KEY_ID @"id"
#define KEY_TIMESTAMP @"timestamp"

#define NUM_USED_IDS [(NSNumber *)[STORAGE objectForKey:@"num_used_ids"] intValue]
#define SET_NUM_USED_IDS(a) [STORAGE setObject:a forKey:@"num_used_ids"]


#define LOCATION_MESSAGE_HEADER @"com.victorzhou.outsidechat.locationMessageHeader"
#define ADMIN_MESSAGE_HEADER @"com.victorzhou.outsidechat.adminMessageHeader"
#define WEATHER_MESSAGE_HEADER @"com.victorzhou.outsidechat.weatherMessageHeader"


@interface VZMessage : NSObject

@property(nonatomic, retain) NSMutableDictionary *dictionary;
@property(nonatomic, retain) NSData *data;

-(instancetype)initWithData:(NSData *)data;
-(instancetype)initWithMessage:(NSString *)message userID:(NSString *)user header:(NSString *)header;
-(NSString *)getSender;

@end
