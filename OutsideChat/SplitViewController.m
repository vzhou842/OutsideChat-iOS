//
//  SplitViewController.m
//  OutsideChat
//
//  Created by Zachary Liu on 7/12/15.
//  Copyright (c) 2015 Victor Zhou. All rights reserved.
//

#import "SplitViewController.h"
#import "Mapbox.h"
#import "MessagesViewController.h"
#import "Constants.h"

@interface SplitViewController ()
@property (weak, nonatomic) IBOutlet UIView *mapView;
@property (strong, nonatomic) RMMapView *mapEmbedView;
@property (strong, nonatomic) NSMutableDictionary *mapMarkers;
@property (strong, nonatomic) NSMutableDictionary *contactLocations;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (strong, nonatomic) NSString *selectedContactID;
- (IBAction)segmentControlChanged:(id)sender;

@end

@implementation SplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //navbar background
    self.navigationController.navigationBar.barTintColor = OUR_TURQUOISE;
    self.navigationController.navigationBar.translucent = NO; 
    
    RMMBTilesSource *offlineSource = [[RMMBTilesSource alloc] initWithTileSetResource:@"map" ofType:@"mbtiles"];

    self.mapEmbedView = [[RMMapView alloc] initWithFrame:self.mapView.bounds andTilesource:offlineSource];

    self.mapEmbedView.zoom = 2;
    
    self.mapEmbedView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    self.mapEmbedView.adjustTilesForRetinaDisplay = YES; // these tiles aren't designed specifically for retina, so make them legible
    
    [self.mapView addSubview:self.mapEmbedView];
    
    //try to get a weather update
    [MPCMANAGER trySendWeatherUpdate];

    self.contactLocations = [[NSMutableDictionary alloc] init];
    self.mapMarkers = [[NSMutableDictionary alloc] init];

    // TEST
    [self.contactLocations setObject:@"" forKey:@"1111111111"];
    [self.tableView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveMessage:)
                                                 name:VZNotificationNameLocationMessage
                                               object:nil];
}



#pragma mark UITableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.contactLocations count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    
    NSString *contactID = [self.contactLocations allKeys][indexPath.row];
    CLLocation *loc = [self.contactLocations allValues][indexPath.row];
    
    cell.textLabel.text = contactID;
    cell.detailTextLabel.text = loc.description;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSString *contactID = [self.contactLocations allKeys][indexPath.row];
    self.selectedContactID = contactID;
    [self performSegueWithIdentifier:@"message" sender:self];
}


#pragma mark IBActions
- (IBAction)segmentControlChanged:(id)sender {
    UISegmentedControl *segmentedControl = (UISegmentedControl *) sender;
    NSInteger selectedSegment = segmentedControl.selectedSegmentIndex;
    
    switch (selectedSegment) {
        case 0:
            [self.mapView setHidden:NO];
            [self.tableView setHidden:YES];
            break;
            
        case 1:
            [self.mapView setHidden:YES];
            [self.tableView setHidden:NO];
            break;
    }
}

- (void) receiveMessage:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:VZNotificationNameLocationMessage])
    {
        CLLocation *loc = notification.userInfo[VZNotificationKeyLocation];
        NSString *senderID = notification.userInfo[VZNotificationKeyLocationPeer];
        
        RMPointAnnotation *annotation = [self.mapMarkers objectForKey:senderID];
        
        if (annotation) {
            [self.mapEmbedView removeAnnotation:annotation];
        }
        
        annotation = [[RMPointAnnotation alloc]
                                         initWithMapView:self.mapEmbedView
                                         coordinate:loc.coordinate
                                         andTitle:senderID];
        
        [self.mapEmbedView addAnnotation:annotation];
        [self.mapMarkers setObject:annotation forKey:senderID];
        
        [self.contactLocations setObject:loc forKey:senderID];
        [self.tableView reloadData];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([[segue identifier] isEqualToString:@"message"])
    {
        MessagesViewController *vc = [segue destinationViewController];
        [vc setContactId:self.selectedContactID];
    }
}

@end
