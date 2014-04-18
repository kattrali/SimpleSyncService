//
//  AddressBookSyncAdapter.m
//  SampleProject
//
//  Created by Delisa Mason on 11/28/13.
//  Copyright (c) 2013 Delisa Mason. All rights reserved.
//

#import "AddressBookSyncAdapter.h"
#import "PeopleAPI.h"
#import <AddressBook/AddressBook.h>

@implementation AddressBookSyncAdapter

- (void)fetchDataWithCompletion:(FetchCompletionBlock)completionBlock {
    NSLog(@"Searching address book for Cat Club members...");
    ABAddressBook *book = [ABAddressBook sharedAddressBook];
    ABSearchElement *hasCatClubEmail =
        [ABPerson searchElementForProperty:kABEmailProperty
                                     label:nil
                                       key:nil
                                     value:@"catclub.org"
                                comparison:kABContainsSubStringCaseInsensitive];
    NSArray *searchResults = [book recordsMatchingSearchElement:hasCatClubEmail];
    completionBlock([self formatRecords:searchResults], nil);
}

- (NSArray *)formatRecords:(NSArray *)records {
    return [records map:^id(ABRecord *record) {
        NSMutableDictionary *attributes = [[NSMutableDictionary alloc] initWithCapacity:2];
        NSString *name  = [self fullNameFromRecord:record];
        NSString *email = [self emailFromRecord:record];
        if (name)  attributes[@"name"] = name;
        if (email) attributes[@"email"] = email;
        return attributes;
    }];
}

- (NSString *)emailFromRecord:(ABRecord *)record {
    ABMultiValue *emailData = [record valueForKey:kABEmailProperty];
    for (int i = 0; i < emailData.count; i++) {
        NSString *email = [emailData valueAtIndex:i];
        if ([[email lowercaseString] containsString:@"catclub.org"])
            return email;
    }
    return nil;
}

- (NSString *)fullNameFromRecord:(ABRecord *)record {
    NSString *firstName = [record valueForKey:kABFirstNameProperty];
    NSString *lastName  = [record valueForKey:kABLastNameProperty];
    if (firstName && lastName)
        return NSStringWithFormat(@"%@ %@", firstName, lastName);
    else if (firstName)
        return firstName;
    else
        return lastName;
}
@end