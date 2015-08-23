//
//  LoginVC.m
//  OutsideChat
//
//  Created by Victor Zhou on 7/11/15.
//  Copyright (c) 2015 Victor Zhou. All rights reserved.
//

#import "LoginVC.h"

@interface LoginVC ()
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
- (IBAction)save:(id)sender;

@end

@implementation LoginVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //navbar background
    self.navigationController.navigationBar.barTintColor = OUR_TURQUOISE;
    self.navigationController.navigationBar.translucent = NO;

    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (LOCAL_PEER) {
        [MPCMANAGER setupPeerWithName:LOCAL_PEER];
        [self performSegueWithIdentifier:@"save" sender:self];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)save:(id)sender {
    NSString *name = self.usernameField.text;
    if (name.length != 10) {
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:@"Please enter a 10 digit phone number"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;
    }
    SET_LOCAL_PEER(name);
    SYNC_STORAGE();
    [MPCMANAGER setupPeerWithName:name];
    [self performSegueWithIdentifier:@"save" sender:self];
}
@end
