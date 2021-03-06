//
//  DMMSimpleSyncService.m
//  SimpleSyncService
//
//  Copyright (c) 2014 Delisa Mason. http://delisa.me
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
#import <ObjectiveRecord/ObjectiveRecord.h>

static SimpleSyncService *sharedServiceInstance;

static BOOL syncData(NSArray *data, NSString *entityName, NSString *dataPropertyName, NSString *modelPropertyName) {
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
    context.parentContext = [[CoreDataManager sharedManager] managedObjectContext];
    return [SimpleSyncService synchronizeData:data
                               withEntityName:entityName
                                    inContext:context
                      withDataIdentifierNamed:dataPropertyName
                      andModelIdentifierNamed:modelPropertyName];
}

@interface NSOperationQueue (SimpleSyncService)

- (void)DMM_enqueueBlock:(void(^)())block;
@end

@implementation NSOperationQueue (SimpleSyncService)

- (void)DMM_enqueueBlock:(void (^)())block
{
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    [operation addExecutionBlock:block];
    [self addOperation:operation];
}

@end

@interface SimpleSyncService ()

@property (nonatomic, strong) NSArray *adapters;
@property (nonatomic, strong) NSMutableArray *adapterTimers;
@property (nonatomic) NSOperationQueue *queue;
@end

@implementation SimpleSyncService

- (id)initWithAdapters:(NSArray *)adapters useQueue:(NSOperationQueue *)queue {
    if (self = [super init]) {
        _adapters = adapters;
        _queue    = queue;
        _adapterTimers = [[NSMutableArray alloc] initWithCapacity:adapters.count];
    }

    return self;
}

- (void)start {
    if (self.adapterTimers.count > 0)
        return;

    NSRunLoop *runner = [NSRunLoop currentRunLoop];

    for (DMMSyncServiceAdapter *adapter in self.adapters) {
        NSTimer *timer = [NSTimer timerWithTimeInterval:adapter.interval
                                                 target:self
                                               selector:@selector(fireTimer:)
                                               userInfo:adapter
                                                repeats:YES];
        [self fireTimer:timer];
        [runner addTimer:timer forMode:NSDefaultRunLoopMode];
        [self.adapterTimers addObject:timer];
    }
}

- (void)stop {
    [self.adapterTimers makeObjectsPerformSelector:@selector(invalidate)];
    [self.adapterTimers removeAllObjects];
}

- (void)fireTimer:(NSTimer *)timer {
    DMMSyncServiceAdapter *adapter = (DMMSyncServiceAdapter *)timer.userInfo;
    [self.queue DMM_enqueueBlock:^{
        [adapter fetchDataWithCompletion:^(NSArray *fetchedData, NSError *error) {
            syncData(fetchedData, adapter.entityName, adapter.fetchedDataIDKey, adapter.modelIDKey);
        }];
    }];
}

+ (void)synchronizeData:(NSArray *)data
         withEntityName:(NSString *)entityName
withDataIdentifierNamed:(NSString *)dataPropertyName
andModelIdentifierNamed:(NSString *)modelPropertyName
               useQueue:(NSOperationQueue *)queue {
    [queue DMM_enqueueBlock:^{
        syncData(data, entityName, dataPropertyName, modelPropertyName);
    }];
}

+ (void)synchronizeData:(NSArray *)data
         withEntityName:(NSString *)entityName
    withIdentifierNamed:(NSString *)identifierPropertyName
               useQueue:(NSOperationQueue *)queue {
    [self synchronizeData:data withEntityName:entityName withDataIdentifierNamed:identifierPropertyName andModelIdentifierNamed:identifierPropertyName useQueue:queue];
}

+ (BOOL)synchronizeData:(NSArray *)data
         withEntityName:(NSString *)entityName
              inContext:(NSManagedObjectContext *)context
    withIdentifierNamed:(NSString *)identifierPropertyName {
    return [self synchronizeData:data withEntityName:entityName inContext:context withDataIdentifierNamed:identifierPropertyName andModelIdentifierNamed:identifierPropertyName];
}

+ (BOOL)synchronizeData:(NSArray *)data
         withEntityName:(NSString *)entityName
              inContext:(NSManagedObjectContext *)context
withDataIdentifierNamed:(NSString *)dataPropertyName
andModelIdentifierNamed:(NSString *)modelPropertyName {
    if (data.count == 0) return YES;

    NSError *error = nil;
    NSArray *updatedIdentifiers = [data valueForKey:dataPropertyName];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.predicate = [NSPredicate predicateWithFormat:@"%K IN %@", modelPropertyName, updatedIdentifiers];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:modelPropertyName ascending:YES]];
    NSArray *existingRecords = [context executeFetchRequest:request error:&error];

    if (existingRecords) {
        for (int i = 0; i < updatedIdentifiers.count; i++) {
            id identifier = updatedIdentifiers[i];
            if ([identifier isEqual:[NSNull null]]) {
                NSLog(@"ERROR: No identifier property named '%@' found in updated data: %@", dataPropertyName, data[i]);
                continue;
            }

            NSManagedObject *record = [self recordInArray:existingRecords
                                                withValue:identifier
                                                   forKey:modelPropertyName];
            if (!record) {
                record = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                       inManagedObjectContext:context];
            }
            [record update:[self dictionary:data[i] replacingKey:dataPropertyName withKey:modelPropertyName]];
        }
        return [self saveContext:context];
    } else if (error) {
        NSLog(@"ERROR: Synchronization Service failed to fetch existing records: %@", error.localizedDescription);
        return NO;
    }
    return YES;
}

+ (NSManagedObject *)recordInArray:(NSArray *)records withValue:(id)value forKey:(NSString *)key {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", key, value];
    return [[records filteredArrayUsingPredicate:predicate] firstObject];
}

+ (BOOL)saveContext:(NSManagedObjectContext *)context {
    if (![context hasChanges]) return YES;

    NSError *error = nil;
    BOOL success = [context save:&error];
    if (success) {
        NSManagedObjectContext *parent = context.parentContext;
        if (parent) {
            [parent performBlock:^{
                NSError * propagation = nil;
                [parent save:&propagation];
                if (propagation)
                    NSLog(@"ERROR: Synchronization Service failed to propagate changes to parent context: %@", propagation.localizedDescription);
            }];
        }
    } else {
        NSLog(@"ERROR: Synchronization Service save failed: %@", error.localizedDescription);
    }
    return success;
}

+ (NSDictionary *)dictionary:(NSDictionary *)data replacingKey:(NSString *)oldKey withKey:(NSString *)newKey {
    if ([oldKey isEqualToString:newKey])
        return data;

    NSMutableDictionary *dict = data.mutableCopy;
    dict[newKey] = dict[oldKey];
    [dict removeObjectForKey:oldKey];
    return dict;
}

@end