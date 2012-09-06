//
//  arangoAppDelegate.m
//  Arango
//
//  Created by Michael Hackstein on 28.08.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import "arangoAppDelegate.h"
#import <Foundation/NSTask.h>
#import "arangoToolbarMenu.h"
#import "ArangoConfiguration.h"

@implementation arangoAppDelegate

@synthesize statusMenu;
@synthesize statusItem;


NSString* adminDir;
NSString* jsActionDir;
NSString* jsModPath;

- (NSTask*) startArangoWithPath:(NSString*) path andPort: (NSNumber*) port andLog: (NSString*) logPath
{
  NSString* arangoPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/arangod"];
  NSString* configPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/arangod.conf"];
  NSTask* newArango = [[NSTask alloc]init];
  [newArango setLaunchPath:arangoPath];
  NSArray* arguments = [NSArray arrayWithObjects:
                        @"--config", configPath,
                        @"--exit-on-parent-death", @"true",
                        @"--server.http-port", port.stringValue,
                        @"--log.file", logPath,
                        @"--server.admin-directory", adminDir,
                        @"--javascript.action-directory", jsActionDir,
                        @"--javascript.modules-path", jsModPath,
                        path, nil];
  [newArango setArguments:arguments];
  newArango.terminationHandler = ^(NSTask *task) {
    NSLog(@"Terminated Arango");
  };
  [newArango launch];
  return newArango;
}


- (NSTask*) testArangoWithPath:(NSString*) path andPort: (NSNumber*) port andLog: (NSString*) logPath
{
  NSString* arangoPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/arangod"];
  NSString* configPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/arangod.conf"];
  NSTask* newArango = [[NSTask alloc]init];
  [newArango setLaunchPath:arangoPath];
  NSArray* arguments = [NSArray arrayWithObjects:
                        @"--config", configPath,
                        @"--exit-on-parent-death", @"true",
                        @"--server.http-port", port.stringValue,
                        @"--log.file", logPath,
                        @"--server.admin-directory", adminDir,
                        @"--javascript.action-directory", jsActionDir,
                        @"--javascript.modules-path", jsModPath,
                        @"--javascript.gc-interval", @"1",
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-document.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-edge.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-compactor.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-collection.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-simple-query.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-index.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-index-geo.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-cap-constraint.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-unique-constraint.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-hash-index.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-relational.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-complex.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-refaccess-attribute.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-queries-optimiser.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-variables.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-operators.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-queries-noncollection.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-refaccess-variable.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-escaping.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-skiplist.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-queries-simple.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-ranges.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-arithmetic.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-ternary.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-logical.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-bind.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-parse.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-hash.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-queries-collection.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-queries-variables.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-queries-geo.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-functions.js"],
                        path, nil];
  [newArango setArguments:arguments];
  newArango.terminationHandler = ^(NSTask *task) {
    NSLog(@"Terminated Arango");
  };
  [newArango launch];
  return newArango;
}

- (NSManagedObjectContext*) getArangoManagedObjectContext
{
  if (self.managedObjectContext == nil) {
    NSURL *storeURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"Arango.sqlite"];
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"configurationModel" withExtension:@"momd"];
    NSError *error = nil;
    NSPersistentStoreCoordinator* coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL]];
    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
      // TODO Handle Error.
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
    }
    self.managedObjectContext = [[NSManagedObjectContext alloc] init];
    [self.managedObjectContext setPersistentStoreCoordinator:coordinator];
  }
  return self.managedObjectContext;
}

- (void) startNewArangoWithPath:(NSString*) path andPort: (NSNumber*) port andLog: (NSString*) logPath andAlias:(NSString*) alias
{
  NSTask* arang = [self startArangoWithPath:path andPort: port andLog:logPath];
  NSLog([NSString stringWithFormat:@"Started new Arango at PID %i as Alias %@",[arang processIdentifier], alias]);
  NSManagedObjectContext* ctxt = [self getArangoManagedObjectContext];
  ArangoConfiguration* newArang = (ArangoConfiguration*) [NSEntityDescription insertNewObjectForEntityForName:@"ArangoConfiguration" inManagedObjectContext:ctxt];
  newArang.path = path;
  newArang.port = port;
  newArang.log = logPath;
  newArang.alias = alias;
  newArang.isRunning = [NSNumber numberWithBool:YES];
  [statusMenu updateMenu];
}




// System Stuff

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
}



-(void) awakeFromNib
{
  adminDir = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/html/admin"];
  jsActionDir = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/actions/system"];
  jsModPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/modules:"] stringByAppendingString:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/modules"]];
  statusMenu = [[arangoToolbarMenu alloc] initWithAppDelegate:self];
  statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
  [statusItem setMenu: statusMenu];
  [statusItem setImage: [NSImage imageNamed:@"arangoStatusLogo"]];
  [statusItem setHighlightMode:YES];
  [statusMenu setAutoenablesItems: NO];
}

@end
