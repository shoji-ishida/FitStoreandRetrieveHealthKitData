//
//  StepsViewController.h
//  Fit
//
//  Created by 石田 勝嗣 on 2014/07/29.
//  Copyright (c) 2014年 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>
@import HealthKit;

@interface StepsViewController : UITableViewController

@property (nonatomic, weak) IBOutlet UILabel *totalStepsLabel;

@property (nonatomic) HKHealthStore *healthStore;

@end
