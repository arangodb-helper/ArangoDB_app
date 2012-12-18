//
//  arangoAppDelegate.m
//  Arango
//
//  Created by Michael Hackstein on 28.08.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import "arangoAppDelegate.h"
#import <Foundation/NSTask.h>
#import "ArangoToolbarMenu.h"
#import "ArangoConfiguration.h"
#import "User.h"
#import "Bookmarks.h"
#import "ArangoUserConfigController.h"
#import "ArangoManager.h"
#import "ArangoHelpController.h"
#import "ArangoIntroductionController.h"

@implementation arangoAppDelegate

@synthesize statusMenu;
@synthesize statusItem;
@synthesize userConfigController;

NSString* adminDir;
NSString* jsActionDir;
NSString* jsModPath;
NSString* arangoVersion;
int version;


// Public function to update an given Arango with all given informations.
// If the given Arango is still running it is shutdown, updated and afterwards restarted.
/*
- (void) updateArangoConfig:(ArangoConfiguration*) config withPath:(NSString*) path andPort: (NSNumber*) port andLog: (NSString*) logPath andLogLevel:(NSString*) level andRunOnStartUp: (BOOL) ros andAlias:(NSString*) alias
{
  if ([config.isRunning isEqualToNumber:[NSNumber numberWithBool:YES]]) {
    // [config.instance terminate];
  }
  if (config.bookmarks != nil && 106 < version) {
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
 */

- (void) timedStart: (NSTimer*) timer {
  [self startArango:timer.userInfo];
}

// Public funcntion to delete the given Arango.
- (void) deleteArangoConfig:(ArangoConfiguration*) config andFiles:(BOOL) deleteFiles
{
  if ([config.isRunning isEqualToNumber:[NSNumber numberWithBool:YES]]) {
    // [config.instance terminate];
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

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

- (void) configurationDidChange: (NSNotification*) notification {
  [self.statusMenu updateMenu];
}

// Function called after the app finished lanching.
// This starts all Arangos according to the users decission.
// If this is the first launch of the App also the Configuration will be shown.
- (void) applicationDidFinishLaunching: (NSNotification *) notification {
  
  // create the ArangoDB manager
  self.manager = [[ArangoManager alloc] init];
  
  if (self.manager == nil) {
    return;
  }
  
  // check for changes in the configuration
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(configurationDidChange:)
                                               name:ArangoConfigurationDidChange
                                             object:self.manager];

  // we will have missed the first notification
  [self.statusMenu updateMenu];

  // without any configuration, display some help
  if (0 == self.manager.configurations.count) {
    [[ArangoIntroductionController alloc] initWithArangoManager:self];
  }
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
  self.statusMenu = [[ArangoToolbarMenu alloc] initWithArangoManager:self];
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
