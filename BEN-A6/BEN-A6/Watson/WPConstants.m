// WPConstants.m
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

#import "WPConstants.h"

@implementation WPConstants

NSString* const MY_IDENTIFIER = @"myIdentifier";

NSString* const SEGUE_SHOW_ANSWER_LIST = @"showAnswerList";
NSString* const SEGUE_SHOW_RESULTS_DETAILS = @"ShowResultDetails";

NSString* const KEY_TEXT = @"text";
NSString* const KEY_CONFIDENCE = @"confidence";

NSString* const FAKE_FILE_NAME = @"fake";
NSString* const FAKE_FILE_EXTENSION = @"json";

NSString* const PATH_TO_ANSWERS = @"question.answers";
NSString* const PATH_TO_EVIDENCE = @"question.evidencelist";
// @"https://watson.ihost.com/instance/%@/deepqa/v1/question"
NSString* const URL_WATSON_ASK_QUESTION_TEMPLATE = @"https://watson-wdc01.ihost.com/instance/%@/deepqa/v1/question";
NSString* const WATSON_ASK_QUESTION_PAYLOAD_TEMPLATE = @"{\"question\": {\"questionText\": \"%@\"}}";

NSString* const KEY_CONFIG_PLIST_USER = @"smu_student1";
NSString* const KEY_CONFIG_PLIST_PASSWORD = @"QFbQTOcG";
NSString* const KEY_CONFIG_PLIST_WATSON_INSTANCE_ID = @"520";

NSString* const CONFIG_PLIST_FILE_NAME = @"config";
NSString* const CONFIG_PLIST_EXTENSION = @"plist";

NSUInteger const MAX_NUM_QUESTION_CACHED = 3;

@end
