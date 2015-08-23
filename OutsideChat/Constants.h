//
//  Constants.h
//  OutsideChat
//
//  Created by Victor Zhou on 7/11/15.
//  Copyright (c) 2015 Victor Zhou. All rights reserved.
//

#ifndef OutsideChat_Constants_h
#define OutsideChat_Constants_h

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#define IS_DEBUG true

#if IS_DEBUG
#define DLog(s, ... ) NSLog( @"<%@:(%d)> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DLog(s, ... )
#endif

#define MPCMANAGER [VZMpcManager shared]


#define STORAGE [NSUserDefaults standardUserDefaults]
#define SYNC_STORAGE() [STORAGE synchronize]

#define LOCAL_PEER (NSString *)[STORAGE objectForKey:@"local_peer"]
#define SET_LOCAL_PEER(a) [STORAGE setObject:a forKey:@"local_peer"]

#define STORED_LOCATIONS (NSDictionary *)[STORAGE objectForKey:@"stored_locations"]
#define SET_STORED_LOCATIONS(a) [STORAGE setObject:a forKey:@"stored_locations"]

#define LAST_WEATHER_UPDATE (NSDate *)[STORAGE objectForKey:@"last_weather_update"]
#define SET_LAST_WEATHER_UPDATE(a) [STORAGE setObject:a forKey:@"last_weather_update"]


#define MIN_WEATHER_UPDATE_TIMEOUT 300 //seconds

#define OUR_TURQUOISE [UIColor colorWithRed:58.0/255.0 green:176.0/255.0 blue:176.0/255.0 alpha:1.0]
#define OUR_RED [UIColor colorWithRed:214.0/255.0 green:72.0/255.0 blue:58.0/255.0 alpha:1.0]
#define OUR_YELLOW [UIColor colorWithRed:242.0/255.0 green:158.0/255.0 blue:8.0/255.0 alpha:1.0]


///Direct messages can only be read by the recipient intended and are encrypted.
#define VZMessageTypeDirect 1337
///Default messages can be read by anyone and are plain text.
#define VZMessageTypeDefault 1338

#define DEFAULT_SERVICE_TYPE @"VZ-default"


#define VZNotificationNameDirectMessage @"VZNotificationNameDirectMessage"
#define VZNotificationKeyMessage @"messageKey"

#define VZNotificationNameLocationMessage @"VZNotificationNameLocationMessage"
#define VZNotificationKeyLocation @"locationKey"
#define VZNotificationKeyLocationPeer @"locationPeerKey"

#define VZNotificationNameAdminMessage @"VZNotificationNameAdminMessage"
#define VZNotificationKeyAdminMessage @"adminMessageKey"

#define VZNotificationNameWeatherMessage @"VZNotificationNameWeatherMessage"
#define VZNotificationKeyWeatherMessage @"weatherMessageKey"

#define VZLocationStoreTimestampKey @"VZLocationStoreTimestampKey"
#define VZLocationStoreLatitudeKey @"VZLocationStoreLatitudeKey"
#define VZLocationStoreLongitudeKey @"VZLocationStoreLongitudeKey"

#endif
