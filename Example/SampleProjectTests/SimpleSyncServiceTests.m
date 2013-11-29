//
//  SimpleSyncServiceTests.m
//  SampleProject
//
//  Created by Delisa Mason on 11/27/13.
//  Copyright 2013 Delisa Mason. All rights reserved.
//

#import "Kiwi.h"
#import "Person.h"
#import "PeopleAPI.h"
#import "PeopleAPISyncAdapter.h"

void synchronizeData(NSArray *data) {
    NSManagedObjectContext *context = [[CoreDataManager sharedManager] managedObjectContext];
    [SimpleSyncService synchronizeData:data
                        withEntityName:[Person entityName]
                             inContext:context
                   withIdentifierNamed:@"email"];
}

SPEC_BEGIN(SimpleSyncServiceTests)

describe(@"simple service", ^{
    beforeAll(^{
        [[CoreDataManager sharedManager] useInMemoryStore];
    });

    afterEach(^{
        [Person deleteAll];
    });

    __block NSDictionary *samplePersonData = @{@"name": @"Delisa Mason",
                                               @"email": @"delisa@example.com",
                                               @"number_of_cats":@0};
    __block NSDictionary *updatedPersonData = @{@"email": samplePersonData[@"email"],
                                                @"number_of_cats":@2};

    describe(@"sync", ^{
        it(@"inserts new records", ^{
            synchronizeData(@[samplePersonData]);
            [[[Person where:@{@"name":@"Delisa Mason"}] should] haveCountOf:1];
        });

        it(@"matches existing records to new data using a property name", ^{
            [Person create:samplePersonData];
            synchronizeData(@[updatedPersonData]);
            [[[Person all] should] haveCountOf:1];
        });

        it(@"updates existing records with new data", ^{
            [Person create:samplePersonData];
            synchronizeData(@[updatedPersonData]);
            Person *delisa = [[Person where:@{@"email":samplePersonData[@"email"]}] firstObject];
            [[delisa.numberOfCats should] equal:theValue(2)];
        });
    });

    describe(@"scheduling with adapters", ^{

        beforeEach(^{
            NSArray *adapters = @[[[PeopleAPISyncAdapter alloc] initWithInterval:0.75
                                                                      entityName:[Person entityName]
                                                                      modelIDKey:@"email"]];
            SimpleSyncService *service = [[SimpleSyncService alloc] initWithAdapters:adapters
                                                                            useQueue:[[NSOperationQueue alloc] init]];
            [service start];
        });
        
        it(@"inserts new records", ^{
            [PeopleAPI stub:@selector(fetchUpdatedDataWithCompletionBlock:)
                  withBlock:^id(NSArray *params) {
                      SyncCompletionBlock block = [params firstObject];
                      block(@[samplePersonData], nil);
                      return nil;
                  }];
            [[expectFutureValue([Person where:@{@"name":@"Delisa Mason"}]) shouldEventually] haveCountOf:1];
        });

        it(@"updates existing records", ^{
            synchronizeData(@[samplePersonData]);
            [PeopleAPI stub:@selector(fetchUpdatedDataWithCompletionBlock:)
                  withBlock:^id(NSArray *params) {
                      SyncCompletionBlock block = [params firstObject];
                      block(@[updatedPersonData], nil);
                      return nil;
                  }];

            [[expectFutureValue([((Person *)[[Person where:@{@"name":@"Delisa Mason"}] firstObject]) numberOfCats]) shouldEventually] equal:theValue(2)];
        });
    });
});

SPEC_END