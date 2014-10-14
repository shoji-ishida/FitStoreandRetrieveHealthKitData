//
//  StepsViewController.m
//  Fit
//
//  Created by 石田 勝嗣 on 2014/07/29.
//  Copyright (c) 2014年 Apple. All rights reserved.
//

#import "StepsViewController.h"

@interface StepsViewController ()

@property (nonatomic) int totalSteps;

@end

@implementation StepsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"Steps:viewDidLoad");
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSLog(@"Steps:viewWillAppear");
    [self.refreshControl addTarget:self action:@selector(refreshStatistics) forControlEvents:UIControlEventValueChanged];
    
    [self refreshStatistics];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshStatistics) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)refreshStatistics {
    [self.refreshControl beginRefreshing];
    
    NSLog(@"Steps:refreshStatics");
    [self fetchTotalStepsWithCompletionHandler:^(int totalSteps, NSError *error) {
        NSLog(@"Steps:refreshStatics:handler");
        dispatch_async(dispatch_get_main_queue(), ^{
            self.totalSteps = totalSteps;
            
            [self.refreshControl endRefreshing];
        });
    }];
}

- (void)fetchTotalStepsWithCompletionHandler:(void (^)(int, NSError *))completionHandler {
    
    NSLog(@"Steps:fetchTotalStepsWithCompletionHandler");
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *now = [NSDate date];
    
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
    
    NSDate *startDate = [calendar dateFromComponents:components];
    
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    
    HKQuantityType *sampleType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
    
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:sampleType quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
        if (!result) {
            NSLog(@"Steps:QUery error");
            if (completionHandler) {
                completionHandler(0, error);
            }
            return;
        }
        NSLog(@"Steps: %@", result.sumQuantity);
        int totalSteps = [result.sumQuantity doubleValueForUnit:[HKUnit countUnit]];
        if (completionHandler) {
            completionHandler(totalSteps, error);
        }
    }];
    
    [self.healthStore executeQuery:query];
}

- (void)setTotalSteps:(int)totalSteps {
    NSLog(@"Steps:setTotalSteps %i", totalSteps);
    _totalSteps = totalSteps;
    
      self.totalStepsLabel.text = [@(_totalSteps) stringValue];
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
