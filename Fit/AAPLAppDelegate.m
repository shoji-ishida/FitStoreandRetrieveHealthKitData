/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The main application delegate.
            
*/

#import "AAPLAppDelegate.h"
#import "AAPLProfileViewController.h"
#import "AAPLJournalViewController.h"
#import "AAPLEnergyViewController.h"
@import HealthKit;

@interface AAPLAppDelegate()

@property (nonatomic) HKHealthStore *healthStore;

@end


@implementation AAPLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.healthStore = [[HKHealthStore alloc] init];

    [self setupHealthStoreForTabBarControllers];
    [self querySource];
    
    return YES;
}

#pragma mark - Convenience

// Set the healthStore property on each view controller that will be presented to the user. The root view controller is a tab
// bar controller. Each tab of the root view controller is a navigation controller which contains its root view controller—
// these are the subclasses of the view controller that present HealthKit information to the user.
- (void)setupHealthStoreForTabBarControllers {
    UITabBarController *tabBarController = (UITabBarController *)[self.window rootViewController];

    for (UINavigationController *navigationController in tabBarController.viewControllers) {
        id viewController = navigationController.topViewController;
        
        if ([viewController respondsToSelector:@selector(setHealthStore:)]) {
            [viewController setHealthStore:self.healthStore];
        }
    }
}

-(void)querySource {
    HKSampleType *sampleType =
    [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    HKSourceQuery *query =
    [[HKSourceQuery alloc]
     initWithSampleType:sampleType
     samplePredicate:nil
     completionHandler:^(HKSourceQuery *query, NSSet *sources, NSError *error) {
         
         
         if (error) {
             NSLog(@"*** An error occured while gathering the sources for step date.%@ ***", error.localizedDescription);
             abort();
         }
         
         NSLog(@"Query suceeded");
         for (HKSource *source in sources) {
             NSLog(@"name = %@", source.name);
        }
         
     }];
    
    [self.healthStore executeQuery:query];
}

@end
