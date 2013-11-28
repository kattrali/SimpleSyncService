//
//  PeopleAPI.m
//  SampleProject
//
//  Created by Delisa Mason on 11/27/13.
//  Copyright (c) 2013 Delisa Mason. All rights reserved.
//

#import "PeopleAPI.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>

static NSString * const PEOPLE_API_ENDPOINT = @"http://example.com/api/v1/people.json";

@implementation PeopleAPI

+ (void)fetchUpdatedDataWithCompletionBlock:(FetchCompletionBlock)block {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:PEOPLE_API_ENDPOINT
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             block(responseObject, nil);
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             block(nil, error);
         }];
}

@end