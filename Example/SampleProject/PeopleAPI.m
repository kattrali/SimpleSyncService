//
//  PeopleAPI.m
//  SampleProject
//
//  Created by Delisa Mason on 11/27/13.
//  Copyright (c) 2013 Delisa Mason. All rights reserved.
//

#import "PeopleAPI.h"

static NSString * const PEOPLE_API_ENDPOINT = @"http://example.com/api/v1/people.json";

@implementation PeopleAPI

+ (void)fetchUpdatedDataWithCompletionBlock:(FetchCompletionBlock)block {
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:PEOPLE_API_ENDPOINT]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            block(nil, connectionError);
            return;
        }
        NSArray* people = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        block(people, connectionError);
    }];
}

@end