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
#import "Bookmarks.h"
#import "arangoUserConfigController.h"
#import "ArangoManager.h"
#import "ArangoIntroductionController.h"

@implementation arangoAppDelegate

@synthesize statusMenu;
@synthesize statusItem;
@synthesize userConfigController;
@synthesize managedObjectContext;

NSString* adminDir;
NSString* jsActionDir;
NSString* jsModPath;
NSString* arangoVersion;
int version;


// Method to start a new Arango with the given Configuration.
- (void) startArango:(ArangoConfiguration*) config {
  [self.manager startArangoDB:config.alias];

  [self.statusMenu updateMenu];
}

// Function to get the Context necessary for persistent storage.
- (NSManagedObjectContext*) getArangoManagedObjectContext
{
  if (self.managedObjectContext == nil) {
    NSURL *storeURL = [[[[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"ArangoDB"] retain];
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
    storeURL = [[storeURL URLByAppendingPathComponent:@"ArangoDB.sqlite"] retain];
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
  BOOL ok = [self.manager createConfiguration:alias withPath:path andPort:port andLog:logPath andLogLevel:level andRunOnStartUp:ros];

  if (! ok) {
    // TODO-fc error handling
    return;
  }

  [self.manager startArangoDB:alias];
  [statusMenu updateMenu];
}

// Public function to update an given Arango with all given informations.
// If the given Arango is still running it is shutdown, updated and afterwards restarted.
- (void) updateArangoConfig:(ArangoConfiguration*) config withPath:(NSString*) path andPort: (NSNumber*) port andLog: (NSString*) logPath andLogLevel:(NSString*) level andRunOnStartUp: (BOOL) ros andAlias:(NSString*) alias
{
  if ([config.isRunning isEqualToNumber:[NSNumber numberWithBool:YES]]) {
    [config.instance terminate];
  }
  if (config.bookmarks != nil && version > 106) {
    NSURL* oldPath = [self urlForBookmark:config.bookmarks.path];
    if (oldPath != nil) {
      [oldPath stopAccessingSecurityScopedResource];
    }
    NSURL* oldLogPath = [self urlForBookmark:config.bookmarks.log];
    if (oldLogPath != nil) {
      [oldLogPath stopAccessingSecurityScopedResource];
    }
    if (![config.path isEqualToString:path]) {
      NSURL* newPath = [NSURL fileURLWithPath:path];
      NSData* bookmarkPath = [self bookmarkForURL:newPath];
      if (bookmarkPath != nil) {
        config.bookmarks.path = bookmarkPath;
      }
    }
    if (![config.log isEqualToString:logPath]) {
      NSURL* newLog = [NSURL fileURLWithPath:path];
      NSData* bookmarkLog = [self bookmarkForURL:newLog];
      if (bookmarkLog != nil) {
        config.bookmarks.log = bookmarkLog;
      }
    }
  }
  config.path = path;
  config.port = port;
  config.log = logPath;
  config.loglevel = level;
  config.runOnStartUp = [NSNumber numberWithBool:ros];
  config.alias = alias;
  [self save];
  [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(timedStart:) userInfo:config repeats:NO];
  [statusMenu updateMenu];
}

- (void) timedStart: (NSTimer*) timer {
  [self startArango:timer.userInfo];
}

// Public funcntion to delete the given Arango.
- (void) deleteArangoConfig:(ArangoConfiguration*) config andFiles:(BOOL) deleteFiles
{
  if ([config.isRunning isEqualToNumber:[NSNumber numberWithBool:YES]]) {
    [config.instance terminate];
  }
  if (deleteFiles) {
      [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(deleteFiles:) userInfo:config repeats:NO];
  } else {
    if (config.bookmarks != nil  && version > 106) {
      NSURL* oldPath = [self urlForBookmark:config.bookmarks.path];
      if (oldPath != nil) {
        [oldPath stopAccessingSecurityScopedResource];
      }
      NSURL* oldLogPath = [self urlForBookmark:config.bookmarks.log];
      if (oldLogPath != nil) {
        [oldLogPath stopAccessingSecurityScopedResource];
      }
      [[self getArangoManagedObjectContext] deleteObject: config.bookmarks];
      config.bookmarks = nil;
    }
    [[self getArangoManagedObjectContext] deleteObject: config];
    [self save];
    [statusMenu updateMenu];
  }
}

- (void) deleteFiles: (NSTimer*) timer {
  ArangoConfiguration* config = timer.userInfo;
  NSError* error = nil;
  if (config.bookmarks != nil  && version > 106) {
    
    NSURL* oldLogPath = [self urlForBookmark:config.bookmarks.log];
    if (oldLogPath != nil) {
      [oldLogPath stopAccessingSecurityScopedResource];
    }
    [[NSFileManager defaultManager] removeItemAtPath:config.log error:&error];
    if (error != nil) {
      NSLog(@"%@", error.localizedDescription);
    }
    error = nil;
    NSURL* oldPath = [self urlForBookmark:config.bookmarks.path];
    if (oldPath != nil) {
      [oldPath stopAccessingSecurityScopedResource];
    }
    [[NSFileManager defaultManager] removeItemAtPath:config.path error:&error];
    if (error != nil) {
      NSLog(@"%@", error.localizedDescription);
    }
    [[self getArangoManagedObjectContext] deleteObject: config.bookmarks];
    config.bookmarks = nil;
  } else {
    [[NSFileManager defaultManager] removeItemAtPath:config.log error:&error];
    if (error != nil) {
      NSLog(@"%@", error.localizedDescription);
    }
    error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:config.path error:&error];
    if (error != nil) {
      NSLog(@"%@", error.localizedDescription);
    }
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
    NSLog(@"%@", error.localizedDescription);
  }
}

// Function called after the app finished lanching.
// This starts all Arangos according to the users decission.
// If this is the first launch of the App also the Configuration will be shown.
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  self.manager = [[ArangoManager alloc] init];
  
  if (self.manager == nil) {
    return;
  }
                            
  if (0 == self.manager.configurations.count) {
    [[ArangoIntroductionController alloc] initWithAppDelegate:nil];
  }
  
  
  
  NSFetchRequest *userRequest = [[NSFetchRequest alloc] init];
  NSEntityDescription *userEntity = [[NSEntityDescription entityForName:@"User" inManagedObjectContext: [self getArangoManagedObjectContext]] retain];
  [userRequest setEntity:userEntity];
  [userEntity release];
  NSError *error = nil;
  NSArray *fetchedResults = [[self getArangoManagedObjectContext] executeFetchRequest:userRequest error:&error];
  [userRequest release];
  NSNumber* ros = nil;
  if (fetchedResults == nil) {
    NSLog(@"%@", error.localizedDescription);
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
    NSLog(@"%@", error.localizedDescription);
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
    version = 108;
  } else {
    if ([[NSFileManager defaultManager] respondsToSelector:@selector(createDirectoryAtURL:withIntermediateDirectories:attributes:error:)]) {
      arangoVersion = @"/arangod_10_7";
      version = 107;
    } else {
      arangoVersion = @"/arangod_10_6";
      version = 106;
    }
    
  }
  self.statusMenu = [[arangoToolbarMenu alloc] initWithAppDelegate:self];
  self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
  [self.statusItem setMenu: statusMenu];
  [self.statusItem setImage: [NSImage imageNamed:@"IconColor"]];
  [self.statusItem setHighlightMode:YES];
  [self.statusMenu setAutoenablesItems: NO];
}

- (NSData*)bookmarkForURL:(NSURL*)url {
  if (version == 106) {
    return nil;
  }
  NSError* theError = nil;
  NSData* bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                   includingResourceValuesForKeys:nil
                                    relativeToURL:nil
                                            error:&theError];
  if (theError || (bookmark == nil)) {
    
    NSLog(@"Failed to create Bookmark");
    NSLog(@"%@", theError.localizedDescription);
    return nil;
  }
  return bookmark;
}

- (NSURL*)urlForBookmark:(NSData*)bookmark {
  if (version == 106) {
    return nil;
  }
  BOOL bookmarkIsStale = NO;
  NSError* theError = nil;
  NSURL* bookmarkURL = [NSURL URLByResolvingBookmarkData:bookmark
                                                 options:(NSURLBookmarkResolutionWithoutUI|NSURLBookmarkResolutionWithSecurityScope)
                                           relativeToURL:nil
                                     bookmarkDataIsStale:&bookmarkIsStale
                                                   error:&theError];
  
  if (bookmarkIsStale || (theError != nil)) {
    NSLog(@"Failed to resolve URL");
    NSLog(@"%@", theError.localizedDescription);
  }
  return bookmarkURL;
}


@end
