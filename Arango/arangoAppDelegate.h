//
//  arangoAppDelegate.h
//  Arango
//
//  Created by Michael Hackstein on 28.08.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class arangoToolbarMenu;
@class ArangoConfiguration;
@interface arangoAppDelegate : NSObject <NSApplicationDelegate>

@property (strong) arangoToolbarMenu* statusMenu;
@property (retain) NSStatusItem * statusItem;
@property (retain) NSManagedObjectContext* managedObjectContext;

- (void) startArango:(ArangoConfiguration*) config;
- (NSManagedObjectContext*) getArangoManagedObjectContext;
- (void) startNewArangoWithPath:(NSString*) path andPort: (NSNumber*) port andLog: (NSString*) logPath andLogLevel:(NSString*) level andAlias:(NSString*) alias;
- (void) updateArangoConfig:(ArangoConfiguration*) config withPath:(NSString*) path andPort: (NSNumber*) port andLog: (NSString*) logPath andLogLevel:(NSString*) level andAlias:(NSString*) alias;
- (void) deleteArangoConfig:(ArangoConfiguration*) config;

@end
