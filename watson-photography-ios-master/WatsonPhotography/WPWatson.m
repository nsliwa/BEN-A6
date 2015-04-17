// WPWatson.m
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

#import "WPWatson.h"
#import "WPUtils.h"
#import "WPConstants.h"

@implementation WPWatson

//This class is a singleton
+(instancetype) sharedManager
{
    //Keep the instance of the singleton in sharedManager
    static WPWatson *sharedManager = nil;
    
    //Call the code below only a single time to initialize the singleton instance
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
        
        //Set current question and responses as empty string and dictionary respectively
        sharedManager.currentQuestion = @"";
        sharedManager.responses = [[NSMutableDictionary alloc] init];
        
        //Queue used for the asynchornous network requests
        sharedManager.queue = [[NSOperationQueue alloc] init];
    });
    
    return sharedManager;
}

-(void) askQuestion:(NSString*) question completionHandler:(void (^)(NSError* connectionError)) callback
{
    //Save the question, we reference this in our controllers
    self.currentQuestion = question;
    
    //Clear cache if more than 3 questions have been cached
    if ([self.responses count] > MAX_NUM_QUESTION_CACHED) {
        self.responses = [[NSMutableDictionary alloc] init];
    }
    
    //Check if the question if not in the cache
    if (! self.responses[question]) {
        
        //Read config.plist
        NSString *path = [[NSBundle mainBundle] pathForResource:CONFIG_PLIST_FILE_NAME ofType:CONFIG_PLIST_EXTENSION];
        NSDictionary *config = [[NSDictionary alloc] initWithContentsOfFile:path];
        
        //Get the user and password from config.plist
        NSString* user = config[KEY_CONFIG_PLIST_USER];
        NSString* pass = config[KEY_CONFIG_PLIST_PASSWORD];
        NSString* instanceId = config[KEY_CONFIG_PLIST_WATSON_INSTANCE_ID];
        
        //When no user or password is found, use fake data
        if (![user length] || ![pass length] || ![instanceId length]) {
        
            NSLog(@"No user, password or instance id found in the config file, using fake data.");
            
            //Read data from fake.json
            NSString *filePath = [[NSBundle mainBundle] pathForResource:FAKE_FILE_NAME ofType:FAKE_FILE_EXTENSION];
            NSData *data = [NSData dataWithContentsOfFile:filePath];
            
            //Save the response
            [self _saveWithResponseData:data andQuestion:question];

            //Inform the caller we are done, nil means no error
            callback(nil);
        
        } else {
            
            //Pepare the url and request to contact the server
            NSString* urlWithInstanceId = [NSString stringWithFormat:URL_WATSON_ASK_QUESTION_TEMPLATE, instanceId];
            NSURL* url = [NSURL URLWithString:urlWithInstanceId];
            NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
            [request setHTTPMethod: @"POST"];
            [request setValue:@"30" forHTTPHeaderField:@"X-SyncTimeout"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            //[request setValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
            
            //The server uses basic auth, the format is: 'Basic base64(user:pass)'
            NSString* authHeader = [WPUtils getBase64AuthHeaderWithUsername:user andPassword:pass];
            [request setValue:authHeader forHTTPHeaderField:@"Authorization"];
            
            //Add the question to the post body
            NSString *postString = [NSString stringWithFormat:WATSON_ASK_QUESTION_PAYLOAD_TEMPLATE, question];
            [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
            
            //Send the network request
            [NSURLConnection sendAsynchronousRequest:request queue:self.queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 
                 if (error) {
                 
                     NSLog(@"Error contacting the server: %@", error);
                 
                 } else {
//                     NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//                     NSLog(@"%@", newStr);
//                     NSLog(@"%@", response);
                     //Save the response
                     [self _saveWithResponseData:data andQuestion:question];
                 }
                
                //Inform the caller we are done
                callback(error);
             }];
        }

    } else {
        
        //Getting here means the question is already cached
        
        //Inform the caller we are done, nil means no error
        callback(nil);
    }
}

#pragma mark PRIVATE

-(void) _saveWithResponseData:(NSData*) data andQuestion:(NSString*) question
{
    //Extract the useful bits (answers and evidence)
    WPWatsonQuestionResponse* res = [WPUtils buildResponseObjectWithData:data];
    
    //Save it so we can reference it in our controller
    [self.responses setObject:res forKey:question];
}

@end
