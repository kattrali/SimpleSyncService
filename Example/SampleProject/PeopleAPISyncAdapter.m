//
//  PeopleAPISyncAdapter.m
//  SampleProject
//
//  Created by Delisa Mason on 11/26/13.
//  Copyright (c) 2013 Delisa Mason. All rights reserved.
//

#import "PeopleAPISyncAdapter.h"
#import "PeopleAPI.h"

@implementation PeopleAPISyncAdapter

- (void)fetchDataWithCompletion:(FetchCompletionBlock)completionBlock {
    NSLog(@"Synchronizing with People API...");
    FetchCompletionBlock block = completionBlock;
    [PeopleAPI fetchUpdatedDataWithCompletionBlock:^(NSArray *data, NSError *error) {
        NSLog(@"Fetched %lu updated records", (unsigned long)data.count);
        if (block) block(data, error);
    }];
}

@end