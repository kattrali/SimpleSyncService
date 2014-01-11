//
//  DMMSimpleSyncService.h
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

#import "DMMSyncServiceAdapter.h"

@interface SimpleSyncService : NSObject

/**
 Sets up a service instance to trigger adapters at intervals to fetch data
 for updating a data model

 @param adapters an array of DMMSyncServiceAdapter instances. When
 nil, the sync service does nothing
 @param queue a queue on which the service should run Core Data operations.
 When nil, the service will use the main queue.
 */
- (id)initWithAdapters:(NSArray *)adapters
              useQueue:(NSOperationQueue *)queue;

/**
 Start synchronization tasks
 */
- (void)start;

/**
 Stops all synchronization tasks
 */
- (void)stop;

/**
 Synchronize Core Data entity instances with an array of updated model 
 data in dictionaries
 @param data an NSArray of NSDictionary instances
 @param entityName the name of the entity model to be synchronized
 @param context an NSManagedObjectContext on which Core Data tasks should
 be performed
 @param identifierPropertyName a property name with corresponding unique
 values in the data array objects and the core data model
 */
+ (BOOL)synchronizeData:(NSArray *)data
         withEntityName:(NSString *)entityName
              inContext:(NSManagedObjectContext *)context
    withIdentifierNamed:(NSString *)identifierPropertyName;

/**
 Synchronize Core Data entity instances with an array of updated model
 data in dictionaries
 @param data an NSArray of NSDictionary instances
 @param entityName the name of the entity model to be synchronized
 @param identifierPropertyName a property name with corresponding unique
 values in the data array objects and the core data model
 @param queue a queue on which the service should run Core Data operations.
 When nil, the service will use the main queue.
 */
+ (void)synchronizeData:(NSArray *)data
         withEntityName:(NSString *)entityName
    withIdentifierNamed:(NSString *)identifierPropertyName
               useQueue:(NSOperationQueue *)queue;
@end