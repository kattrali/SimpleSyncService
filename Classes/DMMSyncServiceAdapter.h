//
//  DMMSyncServiceAdapter.h
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

typedef void (^SyncCompletionBlock)(NSArray *fetchedData, NSError *error);

/**
 A pluggable data fetch adapter intended to be triggered via periodic
 data requests
 */
@interface DMMSyncServiceAdapter : NSObject

/**
 The interval at which this adapter should perform a fetch
 */
@property (readonly, nonatomic) NSTimeInterval interval;

/**
 The entity which should be updated with fetched data
 */
@property (readonly, nonatomic, strong) NSString *entityName;

/**
 The property contained by the entity and fetched data which should
 be used to determine whether a fetched data object should be used to
 update an existing record or create a new one.
 */
@property (readonly, nonatomic, strong) NSString *fetchedDataIDKey;

/**
 Create a new synchronization adapter
 @param interval time interval in seconds at which the adapter should 
 be triggered
 @param entityName the entity name of the Core Data model to be updated
 @param fetchedDataIDKey the name of a key on each of the fetched data 
 dictionary objects uniquely identifying it in the array. The key is
 translated into a property name on the corresponding Core Data model using
 ObjectiveRecord's mappings feature.
 @see ObjectiveRecord/NSManagedObject+Mappings.h
 */
- (id)initWithInterval:(NSTimeInterval)seconds
            entityName:(NSString *)entityName
      fetchedDataIDKey:(NSString *)fetchedDataIDKey;

/**
 Data fetching method invoked by the synchronization service. Once the 
 fetch is complete, the completion block must be invoked with the fetched
 data as the first argument.
 Override this method when subclassing DMMSyncServiceAdapter.
 @param completionBlock the block to invoke once the synchronization task
 is complete.
 */
- (void)fetchDataWithCompletion:(SyncCompletionBlock)completionBlock;

@end
