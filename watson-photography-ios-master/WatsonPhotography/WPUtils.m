// WPUtils.m
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

#import "WPUtils.h"

@implementation WPUtils

+(void) styleNavigationBar
{
    [[UINavigationBar appearance] setBarTintColor:UIColorFromRGB(0x0629dc1)];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0, 1);
    
    
    NSDictionary* textAttr = @{NSForegroundColorAttributeName : [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0],
                               NSShadowAttributeName: shadow,
                               NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:19.0]};
    
    [[UINavigationBar appearance] setTitleTextAttributes: textAttr];
}

+(UIActivityIndicatorView*) buildBusyIndicator
{
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    [spinner setColor:[UIColor blackColor]];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    spinner.center = CGPointMake(screenWidth/2, screenHeight/2);
    
    return spinner;
}

+(int) randomNumberWithMax:(int) max andMin:(int) min
{    
    int randNum = rand() % (max - min) + min;
    
    return randNum;
}

+(WPWatsonQuestionResponse*) buildResponseObjectWithData:(NSData*) data
{
    NSArray *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                            options:kNilOptions
                                                              error:nil];
    
    WPWatsonQuestionResponse* res = [[WPWatsonQuestionResponse alloc] init];
    res.answers = [jsonResponse valueForKeyPath:PATH_TO_ANSWERS];
    res.evidence = [jsonResponse valueForKeyPath:PATH_TO_EVIDENCE];
    
    return res;
}

+(NSString*) getBase64AuthHeaderWithUsername:(NSString*) user andPassword:(NSString*) password
{
    NSString* base64Login = [NSString stringWithFormat:@"%@:%@", user, password];
    
    NSData *plainDataLogin = [base64Login dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64StringLogin = [NSString stringWithFormat:@"Basic %@", [plainDataLogin base64EncodedStringWithOptions:kNilOptions]];
    
    return base64StringLogin;
}


@end
