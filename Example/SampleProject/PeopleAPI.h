//
//  PeopleAPI.h
//  SampleProject
//
//  Created by Delisa Mason on 11/27/13.
//  Copyright (c) 2013 Delisa Mason. All rights reserved.
//

typedef void (^FetchCompletionBlock)(NSArray *data, NSError *error);

@interface PeopleAPI : NSObject

+ (void)fetchUpdatedDataWithCompletionBlock:(FetchCompletionBlock)block;

@end