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

void synchronizeDataInBackground(NSArray *data, NSOperationQueue *queue) {
    [SimpleSyncService synchronizeData:data
                        withEntityName:[Person entityName]
                   withIdentifierNamed:@"email"
                              useQueue:queue];
}

void returnDataFromAPI(NSArray *data) {
    [PeopleAPI stub:@selector(fetchUpdatedDataWithCompletionBlock:) withBlock:^id(NSArray *params) {
        SyncCompletionBlock block = [params firstObject];
        block(data, nil);
        return nil;
    }];
}

SPEC_BEGIN(SimpleSyncServiceTests)

describe(@"simple service", ^{

    NSInteger (^numberOfPeople)(void) = ^NSInteger{ return [[Person all] count]; };
    __block NSDictionary *samplePersonData = @{@"name": @"Delisa Mason",
                                               @"email": @"delisa@example.com",
                                               @"number_of_cats":@0};
    __block NSDictionary *updatedPersonData = @{@"email": samplePersonData[@"email"],
                                                @"number_of_cats":@2};

    beforeAll(^{
        [[CoreDataManager sharedManager] useInMemoryStore];
    });

    beforeEach(^{
        synchronizeData(@[samplePersonData]);
    });

    afterEach(^{
        [Person deleteAll];
    });

    describe(@"sync", ^{
        describe(@"inserting", ^{
            NSDictionary *otherPersonData = @{@"name": @"Delisa Mason",
                                              @"email": @"other_email@example.com",
                                              @"number_of_cats":@0};

            it(@"inserts new records", ^{
                [[[Person where:@{@"name":@"Delisa Mason"}] should] haveCountOf:1];
            });

            it(@"inserts new records based on a property name", ^{
                [[theBlock(^{ synchronizeData(@[otherPersonData]); }) should] change:numberOfPeople by:+1];
            });
        });

        describe(@"updating", ^{
            it(@"matches existing records to new data using a property name", ^{
                synchronizeData(@[updatedPersonData]);
                [[theBlock(^{ synchronizeData(@[updatedPersonData]); }) shouldNot] change:numberOfPeople];
            });

            it(@"updates existing records with new data", ^{
                synchronizeData(@[updatedPersonData]);
                Person *delisa = [[Person where:@{@"email":samplePersonData[@"email"]}] firstObject];
                [[delisa.numberOfCats should] equal:theValue(2)];
            });
        });

        describe(@"error handling", ^{
            context(@"data does not contain a valid ID property", ^{
                NSDictionary *invalidData = @{@"name": @"Delisa Mason", @"number_of_cats":@5};

                it(@"does not insert new records", ^{
                    [[theBlock(^{ synchronizeData(@[invalidData]); }) shouldNot] change:numberOfPeople];
                });

                it(@"skips synchronizing data without a valid ID property", ^{
                    [[theBlock(^{ synchronizeData(@[invalidData]); }) shouldNot] change:^NSInteger{
                        NSArray *people = [Person where:@{@"name":@"Delisa Mason"}];
                        Person  *delisa = [people firstObject];
                        return [delisa.numberOfCats integerValue];
                    }];
                });
            });

            context(@"some data is valid and some contains errors", ^{
                NSArray *updatedData = @[@{@"name": @"Delisa Mason", @"number_of_cats":@5},
                                         @{@"name": @"Shoes", @"email": @"shoes@example.com", @"number_of_cats":@0}];

                it(@"continues to process new data after some data contains an error", ^{
                    [[theBlock(^{ synchronizeData(updatedData); }) should] change:numberOfPeople by:+1];
                });
            });
        });
    });

    describe(@"scheduling with adapters", ^{

        beforeEach(^{
            NSArray *adapters = @[[[PeopleAPISyncAdapter alloc] initWithInterval:0.75 entityName:[Person entityName] fetchedDataIDKey:@"email"]];
            SimpleSyncService *service = [[SimpleSyncService alloc] initWithAdapters:adapters useQueue:[[NSOperationQueue alloc] init]];
            [service start];
        });
        
        it(@"inserts new records", ^{
            returnDataFromAPI(@[samplePersonData]);
            [[expectFutureValue([Person where:@{@"name":@"Delisa Mason"}]) shouldEventually] haveCountOf:1];
        });

        it(@"updates existing records", ^{
            synchronizeData(@[samplePersonData]);
            returnDataFromAPI(@[updatedPersonData]);
            [[expectFutureValue([((Person *)[[Person where:@{@"name":@"Delisa Mason"}] firstObject]) numberOfCats]) shouldEventually] equal:@2];
        });
    });
});

SPEC_END