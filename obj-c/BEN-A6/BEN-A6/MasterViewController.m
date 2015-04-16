//
//  MasterViewController.m
//  BEN-A6
//
//  Created by Nicole Sliwa on 4/8/15.
//  Copyright (c) 2015 Team B.E.N. All rights reserved.
//

#import "MasterViewController.h"

@interface MasterViewController ()

@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    // Get destination view
    CaptureViewController *vc = [segue destinationViewController];
    
    if ([[segue identifier] isEqualToString:@"segue_learn"]) {
        
        
        
        // Get button tag number (or do whatever you need to do here, based on your object
        NSInteger tagIndex = [(UIButton *)sender tag];
        
        // Pass the information to your destination view
        [vc setSelectedButton:tagIndex];
}
    else if ([[segue identifier] isEqualToString:@"segue_learn"]) {
    }


@end
