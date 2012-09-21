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
#import "User.h"
#import "arangoUserConfigController.h"

@implementation arangoAppDelegate

@synthesize statusMenu;
@synthesize statusItem;
@synthesize userConfigController;
@synthesize managedObjectContext;

NSString* adminDir;
NSString* jsActionDir;
NSString* jsModPath;
NSString* arangoVersion;


// Method to start a new Arango with the given Configuration.
- (void) startArango:(ArangoConfiguration*) config {
  NSString* arangoPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:arangoVersion] retain];
  NSString* configPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/arangod.conf"] retain];
  NSTask* newArango = [[NSTask alloc]init];
  [newArango setLaunchPath:arangoPath];
  NSArray* arguments = [NSArray arrayWithObjects:
                        @"--config", configPath,
                        @"--exit-on-parent-death", @"true",
                        @"--server.http-port", config.port.stringValue,
                        @"--log.file", config.log,
                        @"--log.level", config.loglevel,
                        @"--server.admin-directory", adminDir,
                        @"--javascript.action-directory", jsActionDir,
                        @"--javascript.modules-path", jsModPath,
                        config.path, nil];
  [newArango setArguments:arguments];
  // Callback if the Arango is terminated for whatever reason.
  if ([newArango respondsToSelector:@selector(setTerminationHandler:)]) {
    [newArango setTerminationHandler: ^(NSTask *task) {
      config.isRunning = [NSNumber numberWithBool:NO];
      config.instance = nil;
      [self save];
      [self.statusMenu updateMenu];
    }];
  }
  [newArango launch];
  config.isRunning = [NSNumber numberWithBool:YES];
  config.instance = newArango;
  [newArango release];
  [arangoPath release];
  [configPath release];
  [self save];
}

// Function to run the javascript tests.
// Should never be invoked by the enduser and is not linked in the UI.
// Can be invoked after App-launch for testing purposes.
/*
- (NSTask*) testArangoWithPath:(NSString*) path andPort: (NSNumber*) port andLog: (NSString*) logPath
{
  NSString* arangoPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:arangoVersion];
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
  [newArango release];
  return newArango;
}
*/
// Function to get the Context necessary for persistent storage.
- (NSManagedObjectContext*) getArangoManagedObjectContext
{
  if (self.managedObjectContext == nil) {
    NSURL *storeURL = [[[[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"Arango"] retain];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]]) {
      NSError* error = nil;
      if ([[NSFileManager defaultManager] respondsToSelector:@selector(createDirectoryAtURL:withIntermediateDirectories:attributes:error:)]) {
        [[NSFileManager defaultManager] createDirectoryAtURL:storeURL withIntermediateDirectories:YES attributes:nil error:&error];
      } else {
        [[NSFileManager defaultManager] createDirectoryAtPath:[storeURL path] withIntermediateDirectories:YES attributes:nil error:&error];
      }
      if (error != nil) {
        NSLog(@"Failed to create sqlite");
      }
    }
    storeURL = [[storeURL URLByAppendingPathComponent:@"Arango.sqlite"] retain];
    NSURL *modelURL = [[[NSBundle mainBundle] URLForResource:@"configurationModel" withExtension:@"momd"] retain];
    NSError *error = nil;
    NSPersistentStoreCoordinator* coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL]];
    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
      // TODO Handle Error so the user can be informed.
      // Although it should never occur anyways.
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
    }
    self.managedObjectContext = [[NSManagedObjectContext alloc] init];
    [self.managedObjectContext setPersistentStoreCoordinator:coordinator];
    [storeURL release];
    [modelURL release];
    [coordinator release];
  }
  return self.managedObjectContext;
}

// Public function to start a new Arango with all given informations.
- (void) startNewArangoWithPath:(NSString*) path andPort: (NSNumber*) port andLog: (NSString*) logPath andLogLevel:(NSString*) level andRunOnStartUp: (BOOL) ros andAlias:(NSString*) alias
{
  ArangoConfiguration* newArang = (ArangoConfiguration*) [NSEntityDescription insertNewObjectForEntityForName:@"ArangoConfiguration" inManagedObjectContext:[self getArangoManagedObjectContext]];
  newArang.path = path;
  newArang.port = port;
  newArang.log = logPath;
  newArang.loglevel = level;
  newArang.runOnStartUp = [NSNumber numberWithBool:ros];
  newArang.alias = alias;
  [self save];
  [self startArango:newArang];
  [statusMenu updateMenu];
}

// Public function to update an given Arango with all given informations.
// If the given Arango is still running it is shutdown, updated and afterwards restarted.
- (void) updateArangoConfig:(ArangoConfiguration*) config withPath:(NSString*) path andPort: (NSNumber*) port andLog: (NSString*) logPath andLogLevel:(NSString*) level andRunOnStartUp: (BOOL) ros andAlias:(NSString*) alias
{
  if ([config.isRunning isEqualToNumber:[NSNumber numberWithBool:YES]]) {
    [config.instance terminate];
    sleep(2);
  }
  config.path = path;
  config.port = port;
  config.log = logPath;
  config.loglevel = level;
  config.runOnStartUp = [NSNumber numberWithBool:ros];
  config.alias = alias;
  [self save];
  [self startArango:config];
  [statusMenu updateMenu];
}

// Public funcntion to delete the given Arango.
- (void) deleteArangoConfig:(ArangoConfiguration*) config
{
  if ([config.isRunning isEqualToNumber:[NSNumber numberWithBool:YES]]) {
    [config.instance terminate];
  }
  [[self getArangoManagedObjectContext] deleteObject: config];
  [self save];
  [statusMenu updateMenu];
}


// Public function to save all changes made to persistent objects.
// Like all ArangoConfigs and the UserConfig.
- (void) save
{
  NSError* error = nil;
  [[self getArangoManagedObjectContext] save:&error];
  if (error != nil) {
    NSLog(error.localizedDescription);
  }
}

// Function called after the app finished lanching.
// This starts all Arangos according to the users decission.
// If this is the first launch of the App also the Configuration will be shown.
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  NSFetchRequest *userRequest = [[NSFetchRequest alloc] init];
  NSEntityDescription *userEntity = [[NSEntityDescription entityForName:@"User" inManagedObjectContext: [self getArangoManagedObjectContext]] retain];
  [userRequest setEntity:userEntity];
  [userEntity release];
  NSError *error = nil;
  NSArray *fetchedResults = [[self getArangoManagedObjectContext] executeFetchRequest:userRequest error:&error];
  [userRequest release];
  NSNumber* ros = nil;
  if (fetchedResults == nil) {
    NSLog(error.localizedDescription);
  } else {
    if (fetchedResults.count > 0) {
      for (User* u in fetchedResults) {
        ros = u.runOnStartUp;
      }
    } else {
      self.userConfigController = [[arangoUserConfigController alloc] initWithAppDelegate:self];
    }
  }
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"ArangoConfiguration" inManagedObjectContext: [self getArangoManagedObjectContext]];
  [request setEntity:entity];
  [entity release];
  error = nil;
  fetchedResults = [[self getArangoManagedObjectContext] executeFetchRequest:request error:&error];
  [request release];
  if (fetchedResults == nil) {
    NSLog(error.localizedDescription);
  } else {
    switch ([ros integerValue]) {
      // Start no Arango.
      case 0:
        for (ArangoConfiguration* c in fetchedResults) {
          c.isRunning = [NSNumber numberWithBool:NO];
        }
        [self save];
        break;
      // Start all Arangos running at last shutdown.
      case 1:
        for (ArangoConfiguration* c in fetchedResults) {
          if ([c.isRunning isEqualToNumber: [NSNumber numberWithBool:YES]]) {
            [self startArango:c];
          }
        }
        break;
      // Start all defined as Run on StartUp
      case 2:
        for (ArangoConfiguration* c in fetchedResults) {
          if ([c.runOnStartUp isEqualToNumber: [NSNumber numberWithBool:YES]]) {
            [self startArango:c];
          } else {
            c.isRunning = [NSNumber numberWithBool:NO];
          }
        }
        [self save];
        break;
      // Start all
      case 3:
        for (ArangoConfiguration* c in fetchedResults) {
          [self startArango:c];
        }
        break;
        // Default: Start all Arangos running at last shutdown.
      default:
        for (ArangoConfiguration* c in fetchedResults) {
          if ([c.isRunning isEqualToNumber: [NSNumber numberWithBool:YES]]) {
            [self startArango:c];
          }
        }
        break;
    }
  }
  [self.statusMenu updateMenu];
}

// Function that gets called at App-launch.
// Sets some constants and creates the status menu with icon.
// Currently only the green logo is allowed.
-(void) awakeFromNib
{
  adminDir = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/html/admin"] retain];
  jsActionDir = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/actions/system"] retain];
  jsModPath = [[[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/modules:"] stringByAppendingString:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/modules"]] retain];
  if ([[NSBundle mainBundle] respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)]) {
    arangoVersion = @"/arangod_10_8";
  } else {
    if ([[NSFileManager defaultManager] respondsToSelector:@selector(createDirectoryAtURL:withIntermediateDirectories:attributes:error:)]) {
      arangoVersion = @"/arangod_10_7";
    } else {
      arangoVersion = @"/arangod_10_6";
    }
    
  }
  self.statusMenu = [[arangoToolbarMenu alloc] initWithAppDelegate:self];
  self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
  [self.statusItem setMenu: statusMenu];
  //[statusItem setImage: [NSImage imageNamed:@"arangoLogoGrey"]];
  [self.statusItem setImage: [NSImage imageNamed:@"arangoLogoGreen"]];
  [self.statusItem setHighlightMode:YES];
  [self.statusMenu setAutoenablesItems: NO];
}

@end
