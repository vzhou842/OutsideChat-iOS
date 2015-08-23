//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//


// Import all the things
#import "JSQMessages.h"

#import "MessagesModel.h"
#import "NSUserDefaults+DemoSettings.h"


@class MessagesViewController;

@protocol JSQDemoViewControllerDelegate <NSObject>

- (void)didDismissJSQDemoViewController:(MessagesViewController *)vc;

@end




@interface MessagesViewController : JSQMessagesViewController <UIActionSheetDelegate>

@property (weak, nonatomic) id<JSQDemoViewControllerDelegate> delegateModal;

@property (strong, nonatomic) MessagesModel *demoData;

@property (strong, nonatomic) NSString *contactId;

@property (strong, nonatomic) NSMutableArray *messages;

- (void)closePressed:(UIBarButtonItem *)sender;

@end