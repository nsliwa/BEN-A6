// WPResultsDetailsViewController.m
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

#import "WPResultsDetailsViewController.h"
#import "WPUtils.h"
#import "WPWatsonQuestionResponse.h"
#import "WPConstants.h"

@implementation WPResultsDetailsViewController

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
    
    //Get the current response
    WPWatson* watson = [WPWatson sharedManager];
    WPWatsonQuestionResponse* response = watson.responses[watson.currentQuestion];
    
    //Get the current answer
    NSDictionary* currentAnswer = response.answers[self.row];
    
    //Set labels for text and confidence based on the current answer
    NSNumber *conflevel = currentAnswer[KEY_CONFIDENCE];
    self.confidenceLabel.text = [NSString stringWithFormat:@"%.6f", [conflevel floatValue]];
    self.answerTextBox.text = currentAnswer[KEY_TEXT];
    
    //Get a random number and use it to populate the UI with a random evidence
    int randNum = [WPUtils randomNumberWithMax:response.evidence.count-1 andMin:0];
    randNum = self.row; // why should this be random? No thanks
    self.evidenceTextBox.text = response.evidence[randNum][KEY_TEXT];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
