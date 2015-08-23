//
//  VZMessage.m
//  OutsideChat
//
//  Created by Victor Zhou on 7/12/15.
//  Copyright (c) 2015 Victor Zhou. All rights reserved.
//

#import "VZMessage.h"

@implementation VZMessage

-(instancetype)initWithData:(NSData *)data
{
    if (self = [super init])
    {
        _data = data;
        _dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:_data];
    }
    
    return self;
}

-(instancetype)initWithMessage:(NSString *)message userID:(NSString *)user header:(NSString *)header
{
    if (self = [super init])
    {
        _dictionary = [[NSMutableDictionary alloc] init];
        _dictionary[KEY_TYPE] = @VZMessageTypeDefault;
        _dictionary[KEY_SENDER] = user;
        _dictionary[KEY_MESSAGE] = [NSString stringWithFormat:@"%@%@", header, message];
        _dictionary[KEY_ID] = [self _generateID];
        _dictionary[KEY_TIMESTAMP] = [NSDate date];
        
        _data = [NSKeyedArchiver archivedDataWithRootObject:_dictionary];
    }
    
    return self;
}

-(NSString *)getSender
{
    return _dictionary[KEY_SENDER];
}


-(NSString *)_generateID
{
    if (!NUM_USED_IDS) {
        SET_NUM_USED_IDS(@0);
    }
    NSString *theID = [NSString stringWithFormat:@"%@_%d", [UIDevice currentDevice].name, NUM_USED_IDS];
    SET_NUM_USED_IDS(@(NUM_USED_IDS+1));
    return theID;
}

@end
