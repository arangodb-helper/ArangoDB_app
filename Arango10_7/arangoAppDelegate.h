//
//  arangoAppDelegate.h
//  Arango10_7
//
//  Created by Michael Hackstein on 19.09.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface arangoAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:(id)sender;

@end
