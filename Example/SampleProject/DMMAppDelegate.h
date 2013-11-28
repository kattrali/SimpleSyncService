//
//  DMMAppDelegate.h
//  SampleProject
//
//  Created by Delisa Mason on 11/26/13.
//  Copyright (c) 2013 Delisa Mason. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DMMAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
