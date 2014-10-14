/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Displays age, height, and weight information retrieved from HealthKit.
            
*/

#import "AAPLProfileViewController.h"
@import HealthKit;

typedef NS_ENUM(NSInteger, AAPLProfileViewControllerTableViewIndex) {
    AAPLProfileViewControllerTableViewIndexAge = 0,
    AAPLProfileViewControllerTableViewIndexHeight,
    AAPLProfileViewControllerTableViewIndexWeight
};


@interface AAPLProfileViewController ()

// Note that the user's age is not editable.
@property (nonatomic, weak) IBOutlet UILabel *ageUnitLabel;
@property (nonatomic, weak) IBOutlet UILabel *ageValueLabel;

@property (nonatomic, weak) IBOutlet UILabel *heightValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *heightUnitLabel;

@property (nonatomic, weak) IBOutlet UILabel *weightValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *weightUnitLabel;

@end


@implementation AAPLProfileViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Set up an HKHealthStore, asking the user for read/write permissions. The profile view controller is the
    // first view controller that's shown to the user, so we'll ask for all of the desired HealthKit permissions now.
    // In your own app, you should consider requesting permissions the first time a user wants to interact with
    // HealthKit data.
    if ([HKHealthStore isHealthDataAvailable]) {
        NSSet *writeDataTypes = [self dataTypesToWrite];
        NSSet *readDataTypes = [self dataTypesToRead];
        
        [self.healthStore requestAuthorizationToShareTypes:writeDataTypes readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"You didn't allow HealthKit to access these read/write data types. In your app, try to handle this error gracefully when a user decides not to provide access. The error was: %@. If you're using a simulator, try it on a device.", error);
                return;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                // Update the user interface based on the current user's health information.
                [self updateUsersAge];
                [self updateUsersHeight];
                [self updateUsersWeight];
            });
        }];
    }
}

#pragma mark - HealthKit Permissions

// Returns the types of data that Fit wishes to write to HealthKit.
- (NSSet *)dataTypesToWrite {
    HKQuantityType *dietaryCalorieEnergyType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed];
    HKQuantityType *activeEnergyBurnType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    HKQuantityType *heightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    
    return [NSSet setWithObjects:dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType, nil];
}

// Returns the types of data that Fit wishes to read from HealthKit.
- (NSSet *)dataTypesToRead {
    HKQuantityType *dietaryCalorieEnergyType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed];
    HKQuantityType *activeEnergyBurnType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    HKQuantityType *heightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    HKCharacteristicType *birthdayType = [HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth];
    HKQuantityType *stepCountType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKQuantityType *heartRateType = [HKQuantityType quantityTypeForIdentifier: HKQuantityTypeIdentifierHeartRate];
    
    return [NSSet setWithObjects:dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType, birthdayType, stepCountType, heartRateType, nil];
}

#pragma mark - Using HealthKit API

- (void)updateUsersAge {
    // Set the user's age unit (years).
    self.ageUnitLabel.text = NSLocalizedString(@"Age (yrs)", nil);
    
    NSError *error;
    NSDate *dateOfBirth = [self.healthStore dateOfBirthWithError:&error];
    
    if (!dateOfBirth) {
        NSLog(@"Either an error occured fetching the user's age information or none has been stored yet. In your app, try to handle this gracefully.");
        
        self.ageValueLabel.text = NSLocalizedString(@"Not available", nil);
    }
    else {
        // Compute the age of the user.
        NSDate *now = [NSDate date];
        
        NSDateComponents *ageComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:dateOfBirth toDate:now options:NSCalendarWrapComponents];
        
        NSUInteger usersAge = [ageComponents year];

        self.ageValueLabel.text = [NSNumberFormatter localizedStringFromNumber:@(usersAge) numberStyle:NSNumberFormatterNoStyle];
    }
}

- (void)updateUsersHeight {
    // Fetch user's default height unit in inches.
    NSLengthFormatter *lengthFormatter = [[NSLengthFormatter alloc] init];
    lengthFormatter.unitStyle = NSFormattingUnitStyleLong;
    
    NSLengthFormatterUnit heightFormatterUnit = NSLengthFormatterUnitInch;
    NSString *heightUnitString = [lengthFormatter unitStringFromValue:10 unit:heightFormatterUnit];
    NSString *localizedHeightUnitDescriptionFormat = NSLocalizedString(@"Height (%@)", nil);
    
    self.heightUnitLabel.text = [NSString stringWithFormat:localizedHeightUnitDescriptionFormat, heightUnitString];

    HKQuantityType *heightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    
    // Query to get the user's latest height, if it exists.
    [self fetchMostRecentDataOfQuantityType:heightType withCompletion:^(HKQuantity *mostRecentQuantity, NSError *error) {
        if (!mostRecentQuantity) {
            NSLog(@"Either an error occured fetching the user's height information or none has been stored yet. In your app, try to handle this gracefully.");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.heightValueLabel.text = NSLocalizedString(@"Not available", nil);;
            });
        }
        else {
            // Determine the height in the required unit.
            HKUnit *heightUnit = [HKUnit inchUnit];
            double usersHeight = [mostRecentQuantity doubleValueForUnit:heightUnit];
            
            // Update the user interface.
            dispatch_async(dispatch_get_main_queue(), ^{
                self.heightValueLabel.text = [NSNumberFormatter localizedStringFromNumber:@(usersHeight) numberStyle:NSNumberFormatterNoStyle];
            });
        }
    }];
}

- (void)updateUsersWeight {
    // Fetch the user's default weight unit in pounds.
    NSMassFormatter *massFormatter = [[NSMassFormatter alloc] init];
    massFormatter.unitStyle = NSFormattingUnitStyleLong;
    
    NSMassFormatterUnit weightFormatterUnit = NSMassFormatterUnitPound;
    NSString *weightUnitString = [massFormatter unitStringFromValue:10 unit:weightFormatterUnit];
    NSString *localizedWeightUnitDescriptionFormat = NSLocalizedString(@"Weight (%@)", nil);

    self.weightUnitLabel.text = [NSString stringWithFormat:localizedWeightUnitDescriptionFormat, weightUnitString];
    
    // Query to get the user's latest weight, if it exists.
    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];

    [self fetchMostRecentDataOfQuantityType:weightType withCompletion:^(HKQuantity *mostRecentQuantity, NSError *error) {
        if (!mostRecentQuantity) {
            NSLog(@"Either an error occured fetching the user's weight information or none has been stored yet. In your app, try to handle this gracefully.");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.weightValueLabel.text = NSLocalizedString(@"Not available", nil);;
            });
        }
        else {
            // Determine the weight in the required unit.
            HKUnit *weightUnit = [HKUnit poundUnit];
            double usersWeight = [mostRecentQuantity doubleValueForUnit:weightUnit];

            // Update the user interface.
            dispatch_async(dispatch_get_main_queue(), ^{
                self.weightValueLabel.text = [NSNumberFormatter localizedStringFromNumber:@(usersWeight) numberStyle:NSNumberFormatterNoStyle];
            });
        }
    }];
}

// Get the single most recent quantity sample from health store.
- (void)fetchMostRecentDataOfQuantityType:(HKQuantityType *)quantityType withCompletion:(void (^)(HKQuantity *mostRecentQuantity, NSError *error))completion {
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    
    // Since we are interested in retrieving the user's latest sample, we sort the samples in descending order, and set the limit to 1. We are not filtering the data, and so the predicate is set to nil.
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:quantityType predicate:nil limit:1 sortDescriptors:@[timeSortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (!results) {
            if (completion) {
                completion(nil, error);
            }

            return;
        }
        
        if (completion) {
            // If quantity isn't in the database, return nil in the completion block.
            HKQuantitySample *quantitySample = results.firstObject;
            HKQuantity *quantity = quantitySample.quantity;

            completion(quantity, error);
        }
    }];
    
    [self.healthStore executeQuery:query];
}

- (void)saveHeightIntoHealthStore:(double)height {
    // Save the user's height into HealthKit.
    HKUnit *inchUnit = [HKUnit inchUnit];
    HKQuantity *heightQuantity = [HKQuantity quantityWithUnit:inchUnit doubleValue:height];

    HKQuantityType *heightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    NSDate *now = [NSDate date];
    
    HKQuantitySample *heightSample = [HKQuantitySample quantitySampleWithType:heightType quantity:heightQuantity startDate:now endDate:now];
    
    [self.healthStore saveObject:heightSample withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"An error occured saving the height sample %@. In your app, try to handle this gracefully. The error was: %@.", heightSample, error);
            abort();
        }

        [self updateUsersHeight];
    }];
}

- (void)saveWeightIntoHealthStore:(double)weight {
    // Save the user's weight into HealthKit.
    HKUnit *poundUnit = [HKUnit poundUnit];
    HKQuantity *weightQuantity = [HKQuantity quantityWithUnit:poundUnit doubleValue:weight];

    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    NSDate *now = [NSDate date];
    
    HKQuantitySample *weightSample = [HKQuantitySample quantitySampleWithType:weightType quantity:weightQuantity startDate:now endDate:now];
    
    [self.healthStore saveObject:weightSample withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"An error occured saving the weight sample %@. In your app, try to handle this gracefully. The error was: %@.", weightSample, error);
            abort();
        }

        [self updateUsersWeight];
    }];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AAPLProfileViewControllerTableViewIndex index = (AAPLProfileViewControllerTableViewIndex)indexPath.row;
    
    // We won't allow people to change their date of birth, so ignore selection of the age cell.
    if (index == AAPLProfileViewControllerTableViewIndexAge) {
        return;
    }
    
    // Set up variables based on what row the user has selected.
    NSString *title;
    void (^valueChangedHandler)(double value);
    
    if (index == AAPLProfileViewControllerTableViewIndexHeight) {
        title = NSLocalizedString(@"Your Height", nil);

        valueChangedHandler = ^(double value) {
            [self saveHeightIntoHealthStore:value];
        };
    }
    else if (index == AAPLProfileViewControllerTableViewIndexWeight) {
        title = NSLocalizedString(@"Your Weight", nil);
        
        valueChangedHandler = ^(double value) {
            [self saveWeightIntoHealthStore:value];
        };
    }
    
    // Create an alert controller to present.
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    // Add the text field to let the user enter a numeric value.
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        // Only allow the user to enter a valid number.
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    
    // Create the "OK" button.
    NSString *okTitle = NSLocalizedString(@"OK", nil);
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = alertController.textFields.firstObject;
        
        double value = textField.text.doubleValue;
        
        valueChangedHandler(value);
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];

    [alertController addAction:okAction];
    
    // Create the "Cancel" button.
    NSString *cancelTitle = NSLocalizedString(@"Cancel", nil);
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];

    [alertController addAction:cancelAction];
    
    // Present the alert controller.
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Convenience

- (NSNumberFormatter *)numberFormatter {
    static NSNumberFormatter *numberFormatter;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        numberFormatter = [[NSNumberFormatter alloc] init];
    });
    
    return numberFormatter;
}

@end