//
//  DMMSimpleSyncService.m
//  SimpleSyncService
//
//  Copyright (c) 2013 Delisa Mason. http://delisa.me
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.

#import "SimpleSyncService.h"
#import "DMMSyncServiceAdapter.h"
#import "DMMFetchDataOperation.h"
#import <ObjectiveRecord/ObjectiveRecord.h>

static SimpleSyncService * sharedServiceInstance;

@interface SimpleSyncService ()

@property (nonatomic, strong) NSArray * adapters;
@property (nonatomic, strong) NSMutableArray * adapterTimers;
@property (nonatomic) NSOperationQueue * queue;

@end

@implementation SimpleSyncService

- (id)initWithAdapters:(NSArray *)adapters
              useQueue:(NSOperationQueue *)queue {
    if (self = [super init]) {
        _adapters = adapters;
        _queue    = queue;
        _adapterTimers = [[NSMutableArray alloc] initWithCapacity:adapters.count];
    }

    return self;
}

- (void)start {
    NSRunLoop *runner = [NSRunLoop currentRunLoop];

    for (DMMSyncServiceAdapter * adapter in self.adapters) {
        NSTimer * timer = [NSTimer timerWithTimeInterval:adapter.interval
                                                  target:self
                                                selector:@selector(fireTimer:)
                                                userInfo:adapter
                                                 repeats:YES];
        [runner addTimer:timer forMode:NSDefaultRunLoopMode];
        [self.adapterTimers addObject:timer];
    }
}

- (void)stop {
    [self.adapterTimers makeObjectsPerformSelector:@selector(invalidate)];
    [self.adapterTimers removeAllObjects];
}

- (void)fireTimer:(NSTimer *)timer {
    DMMSyncServiceAdapter * adapter = (DMMSyncServiceAdapter *)timer.userInfo;
    DMMFetchDataOperation * operation = [[DMMFetchDataOperation alloc] initWithSyncAdapter:adapter];
    [self.queue addOperation:operation];
}

+ (BOOL)synchronizeData:(NSArray *)data
         withEntityName:(NSString *)entityName
              inContext:(NSManagedObjectContext *)context
    withIdentifierNamed:(NSString *)identifierPropertyName {
    if (data.count == 0) return YES;

    NSError *error = nil;
    NSArray *updatedIdentifiers = [data valueForKey:identifierPropertyName];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSString *propertyFormat = [NSString stringWithFormat:@"%@ IN %%@", identifierPropertyName];
    request.predicate = [NSPredicate predicateWithFormat:propertyFormat, updatedIdentifiers];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:identifierPropertyName ascending:YES]];
    NSArray *existingRecords = [context executeFetchRequest:request error:&error];

    if (existingRecords) {
        for (int i = 0; i < updatedIdentifiers.count; i++) {
            id identifier = updatedIdentifiers[i];
            if ([identifier isEqual:[NSNull null]]) {
                NSLog(@"ERROR: No identifier property named '%@' found in updated data: %@", identifierPropertyName, data[i]);
                continue;
            }

            NSManagedObject *record = [self recordInArray:existingRecords
                                                withValue:identifier
                                                   forKey:identifierPropertyName];
            if (!record) {
                record = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                       inManagedObjectContext:context];
            }
            [record update:data[i]];
        }
        return [self saveContext:context];
    } else if (error) {
        NSLog(@"ERROR: Synchronization Service failed to fetch existing records: %@", error.localizedDescription);
        return NO;
    }
    return YES;
}

+ (NSManagedObject *)recordInArray:(NSArray *)records
                         withValue:(id)value
                            forKey:(NSString *)key {
    NSString *propertyFormat = [NSString stringWithFormat:@"%@ == %%@", key];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:propertyFormat, value];
    NSArray *matches = [records filteredArrayUsingPredicate:predicate];

    return [matches firstObject];
}

+ (BOOL)saveContext:(NSManagedObjectContext *)context {
    if (![context hasChanges]) return YES;

    NSError *error = nil;
    BOOL success = [context save:&error];

    if (success) {
        NSManagedObjectContext *parent = context.parentContext;
        if (parent) {
            NSError * propagation = nil;
            [parent save:&propagation];
            if (propagation) {
                NSLog(@"ERROR: Synchronization Service failed to propagate changes to main context: %@", error.localizedDescription);
            }
        }
    } else {
        NSLog(@"ERROR: Synchronization Service save failed: %@", error.localizedDescription);
    }
    return success;
}

@end