// WPConstants.h
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

#import <Foundation/Foundation.h>

@interface WPConstants : NSObject

extern NSString* const MY_IDENTIFIER;

extern NSString * const SEGUE_SHOW_ANSWER_LIST;
extern NSString * const SEGUE_SHOW_RESULTS_DETAILS;

extern NSString * const KEY_TEXT;
extern NSString * const KEY_CONFIDENCE;

extern NSString * const FAKE_FILE_NAME;
extern NSString * const FAKE_FILE_EXTENSION;

extern NSString * const PATH_TO_ANSWERS;
extern NSString * const PATH_TO_EVIDENCE;

extern NSString * const URL_WATSON_ASK_QUESTION_TEMPLATE;
extern NSString * const WATSON_ASK_QUESTION_PAYLOAD_TEMPLATE;

extern NSString * const KEY_CONFIG_PLIST_USER;
extern NSString * const KEY_CONFIG_PLIST_PASSWORD;
extern NSString * const KEY_CONFIG_PLIST_WATSON_INSTANCE_ID;

extern NSString * const CONFIG_PLIST_FILE_NAME;
extern NSString * const CONFIG_PLIST_EXTENSION;

extern NSUInteger const MAX_NUM_QUESTION_CACHED;

@end
