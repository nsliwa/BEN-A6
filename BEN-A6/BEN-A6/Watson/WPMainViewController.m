// WPMainViewController.m
//
// Copyright (c) 2014 Carlos Andreu
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "WPMainViewController.h"
#import "WPWatson.h"
#import "WPResultsTableViewController.h"
#import "WPUtils.h"
#import "WPConstants.h"

@implementation WPMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _questionTextField.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction) askWatsonButtonClicked:(id)sender
{
    //Hide the keyboard
    [self.view endEditing:YES];
}

-(BOOL) textFieldShouldEndEditing:(UITextField *)textField
{
    NSLog(@"end editing");
    [_questionTextField resignFirstResponder];
    return true;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    
    NSLog(@"should return");
    [_questionTextField resignFirstResponder];
    return true;
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Touches began");
    [self.view endEditing:(true)];
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //Check for the right segue
    if ([segue.identifier isEqualToString:SEGUE_SHOW_ANSWER_LIST]) {

        //Build a loading animation
        UIActivityIndicatorView *spinner = [WPUtils buildBusyIndicator];
        
        //Get the table view controller that will have the answers
        WPResultsTableViewController *tableViewController = segue.destinationViewController;
        
        //Add the loading animation and start it
        [tableViewController.view addSubview:spinner];
        [spinner startAnimating];
        
        //Get the question from the UI
        NSString* question = self.questionTextField.text;

        //Send an asynchronous network request to the watson API
        [[WPWatson sharedManager] askQuestion:question completionHandler:^(NSError *connectionError) {
                        
            //Reload the table to show the data from the response, must be done on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [tableViewController.tableView reloadData];
                
                //Stop the loading animation
                [spinner stopAnimating];
            });
        }];

    }
}

@end
