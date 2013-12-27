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

@property (weak) IBOutlet NSTextField *emailField;
@property (weak) IBOutlet NSTextField *nameField;
@property (weak) IBOutlet NSTextField *catsField;

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
                                                                           fetchedDataIDKey:@"email"];
    AddressBookSyncAdapter *contactAdapter = [[AddressBookSyncAdapter alloc] initWithInterval:10
                                                                                   entityName:[Person entityName]
                                                                                   fetchedDataIDKey:@"email"];
    self.syncService = [[SimpleSyncService alloc] initWithAdapters:@[apiAdapter, contactAdapter]
                                                          useQueue:self.syncQueue];
}

- (IBAction)saveNewMember:(NSButton *)sender {
    NSString *email = [self.emailField stringValue];
    if (email) {
        NSMutableDictionary *attributes = @{@"email": email}.mutableCopy;
        NSString *name = [self.nameField stringValue];
        if (name) attributes[@"name"] = name;
        NSString *cats = [self.catsField stringValue];
        if (cats) attributes[@"numberOfCats"] = @([cats integerValue]);
        [self.emailField setStringValue:@""];
        [self.nameField setStringValue:@""];
        [self.catsField setStringValue:@""];

        [SimpleSyncService synchronizeData:@[attributes]
                            withEntityName:[Person entityName]
                                 inContext:[[CoreDataManager sharedManager] managedObjectContext]
                       withIdentifierNamed:@"email"];
    }
}

@end