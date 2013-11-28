//
//  DMMAppDelegate.m
//  SampleProject
//
//  Created by Delisa Mason on 11/26/13.
//  Copyright (c) 2013 Delisa Mason. All rights reserved.
//

#import "DMMAppDelegate.h"
#import "Person.h"
#import "PeopleAPISyncAdapter.h"
#import "AddressBookSyncAdapter.h"

@interface DMMAppDelegate()

@property (nonatomic, strong) SimpleSyncService *syncService;
@property (nonatomic, strong) NSOperationQueue *syncQueue;

@end

@implementation DMMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.managedObjectContext = [[CoreDataManager sharedManager] managedObjectContext];
    self.syncQueue = [[NSOperationQueue alloc] init];
    [self initializeSyncService];
    [self.syncService start];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self.syncService stop];
    [self.syncQueue cancelAllOperations];
    [[CoreDataManager sharedManager] saveContext];
}

- (void)initializeSyncService {
    PeopleAPISyncAdapter *apiAdapter = [[PeopleAPISyncAdapter alloc] initWithInterval:5
                                                                           entityName:[Person entityName]
                                                                           modelIDKey:@"email"];
    AddressBookSyncAdapter *contactAdapter = [[AddressBookSyncAdapter alloc] initWithInterval:10
                                                                                   entityName:[Person entityName]
                                                                                   modelIDKey:@"email"];
    self.syncService = [[SimpleSyncService alloc] initWithAdapters:@[apiAdapter, contactAdapter]
                                                          useQueue:self.syncQueue];
}

@end