//
//  arangoAppDelegate.h
//
// This is the main controlling class for the ArangoDB.
// It manages all permanent objects and keeps links to the menu.
// Additionally it allows to create/update permanent configurations of Arangos.
//
//  Created by Michael Hackstein on 28.08.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class arangoToolbarMenu;
@class ArangoConfiguration;
@class arangoUserConfigController;

@interface arangoAppDelegate : NSObject <NSApplicationDelegate>

// The underlying menu of the status-bar icon.
@property (strong) arangoToolbarMenu* statusMenu;
// A controller for user-configuration.
@property (strong) arangoUserConfigController* userConfigController;
// The item in the statusbar, containing the icon as well as an accesspoint for the menu.
@property (retain) NSStatusItem * statusItem;
// The context of all objects for permanent storage.
@property (retain) NSManagedObjectContext* managedObjectContext;

// Function to start an Arango with the given configuration.
- (void) startArango:(ArangoConfiguration*) config;
// Function to request the context.
- (NSManagedObjectContext*) getArangoManagedObjectContext;
// Function to start an Arango giving all parameters individually.
- (void) startNewArangoWithPath:(NSString*) path andPort: (NSNumber*) port andLog: (NSString*) logPath andLogLevel:(NSString*) level andRunOnStartUp: (BOOL) ros andAlias:(NSString*) alias;
// Function to update a given configuration to all given parameters.
- (void) updateArangoConfig:(ArangoConfiguration*) config withPath:(NSString*) path andPort: (NSNumber*) port andLog: (NSString*) logPath andLogLevel:(NSString*) level andRunOnStartUp: (BOOL) ros andAlias:(NSString*) alias;
// Function to delete a given configuration.
// Will ask the user if data should be deleted as well.
- (void) deleteArangoConfig:(ArangoConfiguration*) config;
// Function to save all changes made to permanent objects.
- (void) save;

@end
