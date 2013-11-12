///////////////////////////////////////////////////////////////////////////////
/// @brief ArangoDB instance manager
///
/// @file
///
/// DISCLAIMER
///
/// Copyright 2012 triAGENS GmbH, Cologne, Germany
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///     http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///
/// Copyright holder is triAGENS GmbH, Cologne, Germany
///
/// @author Dr. Frank Celler
/// @author Michael Hackstein
/// @author Copyright 2012, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

#import "ArangoManager.h"

#include <dirent.h>
#include <sys/file.h>
#include <sys/stat.h>

#import "ArangoConfiguration.h"
#import "ArangoStatus.h"
#import "User.h"
#import "Bookmarks.h"
#import "ArangoUpgradeInfoController.h"

// -----------------------------------------------------------------------------
// --SECTION--                                                  database version
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief deployed version of ArangoDB
////////////////////////////////////////////////////////////////////////////////

const float _currentVersion = 1.3f;


// -----------------------------------------------------------------------------
// --SECTION--                                                     notifications
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief configuration did change
////////////////////////////////////////////////////////////////////////////////

NSString* ArangoConfigurationDidChange = @"ConfigurationDidChange";

// -----------------------------------------------------------------------------
// --SECTION--                                              ArangoBaseController
// -----------------------------------------------------------------------------

@implementation ArangoManager

// -----------------------------------------------------------------------------
// --SECTION--                                                   private methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief moves database files to new destination
////////////////////////////////////////////////////////////////////////////////

- (BOOL) moveDatabaseFiles: (NSString*) src 
             toDestination: (NSString*) dst {

  // TODO use the Mac OS X functions
  DIR * d;
  struct dirent * de;

  d = opendir([src fileSystemRepresentation]);

  if (d == 0) {
    self.lastError = [[[@"cannot open database directory '" stringByAppendingString:src] stringByAppendingString:@"': "] stringByAppendingString:[NSString stringWithCString:strerror(errno) encoding:NSUTF8StringEncoding]];
    return NO;
  }

  de = readdir(d);

  while (de != 0) {
    if (strncmp(de->d_name, "collection-",11) == 0 || strcmp(de->d_name, "VERSION") == 0) {
      NSString* component = [NSString stringWithCString: de->d_name encoding:NSUTF8StringEncoding];
      NSString* from = [[src stringByAppendingString:@"/"] stringByAppendingString: component];
      NSString* to = [[dst stringByAppendingString:@"/"] stringByAppendingString: component];

      NSError* err;
      BOOL ok = [[NSFileManager defaultManager] moveItemAtPath:from toPath:to error:&err];
      
      if (ok) {
        NSLog(@"Renamed %@ to %@", from, to);
      }
      else {
        self.lastError = [[[@"cannot rename file '" stringByAppendingString:from] stringByAppendingString:@"': "] stringByAppendingString:err.localizedDescription];
        closedir(d);
        return NO;
      }
    }

    de = readdir(d);
  }

  closedir(d);
  return YES;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief creates folder for FOXX apps
////////////////////////////////////////////////////////////////////////////////

- (BOOL) createServerJSFolders {
  NSError* err = nil;
  NSFileManager* fm = [NSFileManager defaultManager];

  if (! [fm fileExistsAtPath:[_js path]]) {
    [fm createDirectoryAtURL:_js withIntermediateDirectories:YES attributes:nil error:&err];
    if (err != nil) {
      self.lastError = [@"failed to create js scripts folder: " stringByAppendingString:err.localizedDescription];
      return NO;
    }
  }

  NSURL* apps = [_js URLByAppendingPathComponent:@"apps"];
  
  if (! [fm fileExistsAtPath:[apps path]]) {
    [fm createDirectoryAtURL:apps withIntermediateDirectories:YES attributes:nil error:&err];
    if (err != nil) {
      self.lastError = [@"failed to create js apps folder: " stringByAppendingString:err.localizedDescription];
      return NO;
    }
  }
  
  NSURL* tempPath = [_js URLByAppendingPathComponent:@"tmp"];
  
  if (! [fm fileExistsAtPath:[tempPath path]]) {
    [fm createDirectoryAtURL:tempPath withIntermediateDirectories:YES attributes:nil error:&err];
    if (err != nil) {
      self.lastError = [@"failed to create temp folder: " stringByAppendingString:err.localizedDescription];
      return NO;
    }
  }
  
  NSURL* tempDownload = [tempPath URLByAppendingPathComponent:@"downloads"];
  
  if (! [fm fileExistsAtPath:[tempDownload path]]) {
    [fm createDirectoryAtURL:tempDownload withIntermediateDirectories:YES attributes:nil error:&err];
    if (err != nil) {
      self.lastError = [@"failed to create downloads folder: " stringByAppendingString:err.localizedDescription];
      return NO;
    }
  }
  
  NSURL* aardvark = [[[[[NSBundle mainBundle] resourceURL]
                        URLByAppendingPathComponent:@"js"]
                        URLByAppendingPathComponent:@"apps"]
                        URLByAppendingPathComponent:@"aardvark"];

  [fm createSymbolicLinkAtURL:[apps URLByAppendingPathComponent:@"aardvark"] withDestinationURL:aardvark error:&err];
  
  if (err != nil) {
    self.lastError = [@"failed to create symbolic link to foxx manager: " stringByAppendingString:err.localizedDescription];
    return NO;
  }
  
  return YES;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief creates the context necessary for persistent storage
////////////////////////////////////////////////////////////////////////////////

- (BOOL) createManagedObjectContext {
  if (_managedObjectContext == nil) {
    NSError* err = nil;
    NSURL* storeURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"ArangoDB"];

    // create storage path
    if (! [[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]]) {
      [[NSFileManager defaultManager] createDirectoryAtURL:storeURL withIntermediateDirectories:YES attributes:nil error:&err];
      if (err != nil) {
        self.lastError = [@"failed to create SQLITE application storage: " stringByAppendingString:err.localizedDescription];
        return NO;
      }
    }
    
    // create SQLITE
    NSURL* sqliteURL = [storeURL URLByAppendingPathComponent:@"ArangoDB.sqlite"];
    NSURL* modelURL = [[NSBundle mainBundle] URLForResource:@"configurationModel" withExtension:@"momd"];
    NSManagedObjectModel* model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSPersistentStoreCoordinator* coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

    if (! [coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:sqliteURL options:nil error:&err]) {
      self.lastError = [@"cannot create SQLITE storage: " stringByAppendingString:err.localizedDescription];
      return NO;
    }
    
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
  }
  
  return YES;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief saves all changes made to the configuration
////////////////////////////////////////////////////////////////////////////////

- (BOOL) saveConfigurations {
  NSError* err = nil;

  [_managedObjectContext save:&err];

  if (err != nil) {
    self.lastError = [@"cannot save configuration: " stringByAppendingString:err.localizedDescription];
    return NO;
  }

  return YES;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief creates bookmark for a configuration
////////////////////////////////////////////////////////////////////////////////

- (void) createBookmarks: (ArangoConfiguration*) config {
  if (config.bookmarks != nil) {
    [self deleteBookmarks:config];
  }

  NSURL* pathURL = [NSURL fileURLWithPath:config.path];
  NSData* path = [self bookmarkForURL:pathURL];

  NSData* log = nil;

  if (! [config.log isEqualToString:@""]) {
    NSURL* logURL = [NSURL fileURLWithPath:config.log];
    log = [self bookmarkForURL:logURL];
  }

  Bookmarks* bookmarks = (Bookmarks*) [NSEntityDescription insertNewObjectForEntityForName:@"Bookmarks"
                                                                    inManagedObjectContext:_managedObjectContext];

  bookmarks.path = path;
  bookmarks.log = log;
  bookmarks.config = config;

  config.bookmarks = bookmarks;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief deletes bookmark from a configuration
////////////////////////////////////////////////////////////////////////////////

- (void) deleteBookmarks: (ArangoConfiguration*) config {
  Bookmarks* bookmarks = config.bookmarks;

  if (bookmarks != nil) {
    config.bookmarks = nil;
    bookmarks.config = nil;

    [_managedObjectContext deleteObject:bookmarks];
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief creates bookmark from url
////////////////////////////////////////////////////////////////////////////////

- (NSData*) bookmarkForURL: (NSURL*) url {
  if (_version <= 106) {
    return nil;
  }

  NSError* err = nil;
  NSData* bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                   includingResourceValuesForKeys:nil
                                    relativeToURL:nil
                                            error:&err];
  if (err != nil) {
    self.lastError = [@"failed to create bookmark: " stringByAppendingString:err.localizedDescription];
    return nil;
  }

  return bookmark;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief extracts url from bookmark
////////////////////////////////////////////////////////////////////////////////

- (NSURL*) urlForBookmark: (NSData*) bookmark {
  if (_version <= 106) {
    return nil;
  }

  BOOL isStale = NO;
  NSError* err = nil;
  NSURL* url = [NSURL URLByResolvingBookmarkData:bookmark
                                         options:(NSURLBookmarkResolutionWithoutUI|NSURLBookmarkResolutionWithSecurityScope)
                                   relativeToURL:nil
                             bookmarkDataIsStale:&isStale
                                           error:&err];
  
  if (err != nil) {
    self.lastError = [@"failed to resolve URL: " stringByAppendingString:err.localizedDescription];
    return nil;
  }

  if (isStale) {
    self.lastError = @"failed to resolve URL: bookmark is stale";
    return nil;
  }

  return url;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief loads all configurations
////////////////////////////////////////////////////////////////////////////////

- (BOOL) loadConfigurations {

  // create managed context
  BOOL ok = [self createManagedObjectContext];

  if (! ok) {
    return NO;
  }
  
  // load the global user configuration
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"User"
                                            inManagedObjectContext: _managedObjectContext];
  [request setEntity:entity];
  
  NSError *err = nil;
  NSArray *fetchedResults = [_managedObjectContext executeFetchRequest:request error:&err];
  
  if (fetchedResults == nil) {
    self.lastError = [@"cannot load global user configuration: " stringByAppendingString:err.localizedDescription];
    return NO;
  }
  else {
    if (0 < fetchedResults.count) {
      for (User* u in fetchedResults) {
        _user = u;
        break;
      }
    }
    else {
      _user = (User*) [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                    inManagedObjectContext:_managedObjectContext];
    }
  }

  // load the configurations
  request = [[NSFetchRequest alloc] init];
  entity = [NSEntityDescription entityForName:@"ArangoConfiguration"
                       inManagedObjectContext: _managedObjectContext];
  [request setEntity:entity];

  err = nil;
  NSArray* configurations = [_managedObjectContext executeFetchRequest:request error:&err];

  if (err != nil) {
    self.lastError = [@"cannot load configurations: " stringByAppendingString:err.localizedDescription];
    return NO;
  }

  // update bookmarks if necessary
  BOOL changed = NO;
  
  for (ArangoConfiguration* config in configurations) {
    if (106 < _version) {
      if (config.bookmarks == nil) {
        [self createBookmarks:config];
        changed = YES;
      }
    }
    else {
      if (config.bookmarks != nil) {
        [self deleteBookmarks:config];
        changed = YES;
      }
    }
  }
  
  if (changed) {
    BOOL ok = [self saveConfigurations];
    
    if (! ok) {
      return NO;
    }
    
    return [self loadConfigurations];
  }

  // map names to configurations
  _configurations = [[NSMutableDictionary alloc] init];
  
  for (ArangoConfiguration* c in configurations) {
    if (c.alias == nil || c.path == nil) {
      continue;
    }
    
    if (c.log == nil) {
      c.log = @"";
    }
    
    if (c.loglevel == nil) {
      c.loglevel = @"info";
    }
    [_configurations setValue:c forKey:c.alias];
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:ArangoConfigurationDidChange object:self];

  return YES;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief deletes database files
////////////////////////////////////////////////////////////////////////////////

- (void) deleteFiles: (NSTimer*) timer {
  ArangoStatus* status = timer.userInfo;

  // check if the instance is still running
  NSTask* task = [_instances objectForKey:status.name];

  if (task != nil && [task isRunning]) {
    [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(deleteFiles:)
                                   userInfo:status
                                    repeats:NO];
    return;
  }

  // delete log file and database path
  NSError* err = nil;
  [[NSFileManager defaultManager] removeItemAtPath:status.logPath error:&err];

  if (err != nil) {
    NSLog(@"%@", err.localizedDescription);
    // TODO send a notification
  }

  err = nil;
  [[NSFileManager defaultManager] removeItemAtPath:status.path error:&err];

  if (err != nil) {
    NSLog(@"%@", err.localizedDescription);
    // TODO send a notification
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief normalizes and checks the log path
////////////////////////////////////////////////////////////////////////////////

- (NSString*) checkLogPath: (NSString*) logPath
                   andName: (NSString*) alias {
  if ([logPath isEqualToString:@""]) {
    return logPath;
  }

  BOOL isDir;
    
  if ([[NSFileManager defaultManager] fileExistsAtPath:logPath isDirectory:&isDir]) {
    if (isDir) {
      NSMutableString* tmp = [[NSMutableString alloc] initWithString:logPath];
      [tmp appendString:@"/"];
      [tmp appendString:alias];
      [tmp appendString:@".log"];
      logPath = tmp;

      if (![[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
        BOOL ok = [[NSFileManager defaultManager] createFileAtPath:logPath
                                                          contents:nil
                                                        attributes:nil];

        if (! ok) {
          self.lastError = [[@"cannot create log file '" stringByAppendingString:logPath] stringByAppendingString:@"'"];
          return nil;
        }
      }
    }
  }
  else {
    BOOL ok = [[NSFileManager defaultManager] createFileAtPath:logPath contents:nil attributes:nil];
    
    if (! ok) {
      self.lastError = [[@"cannot create log file '" stringByAppendingString:logPath] stringByAppendingString:@"'"];
      return nil;
    }
  }

  return logPath;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief normalizes and checks the database path
////////////////////////////////////////////////////////////////////////////////

- (NSString*) checkDatabasePath: (NSString*) path
                        andName: (NSString*) name {
  if ([path isEqualToString:@""]) {
    path = [NSHomeDirectory() stringByAppendingString:[@"/" stringByAppendingString:name]];
  }
  else if ([path hasPrefix:@"~"]){
    return [NSHomeDirectory() stringByAppendingString:[path substringFromIndex:1]];
  }
  else if ([path isEqualToString:@""]) {
    self.lastError = @"database path must not be empty";
    return nil;
  }
  
  return path;
}

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief default constructor
////////////////////////////////////////////////////////////////////////////////

- (ArangoManager*) init {
  self = [super init];

  if (self != nil) {
    if ([[NSBundle mainBundle] respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)]) {
      _arangoDBVersion = @"/opt/arangodb/sbin/arangodb";
      _version = 108;
    } 
    else if ([[NSFileManager defaultManager] respondsToSelector:@selector(createDirectoryAtURL:withIntermediateDirectories:attributes:error:)]) {
      _arangoDBVersion = @"/opt/arangodb/sbin/arangodb";
      _version = 107;
    }
    else {
      _arangoDBVersion = @"/opt/arangodb/sbin/arangodb";
      _version = 106;
    }

    NSURL* appSupportURL = [[[[NSFileManager defaultManager]
                              URLsForDirectory:NSApplicationSupportDirectory
                              inDomains:NSUserDomainMask]
                            lastObject]
                            URLByAppendingPathComponent:@"ArangoDB"];
    
    // create js path
    _js = [appSupportURL URLByAppendingPathComponent:@"js"];
    [self createServerJSFolders];
    
    NSString* path = [[NSBundle mainBundle] resourcePath];
    NSString* jsPath = [_js path];

    _arangoDBBinary = [path stringByAppendingString:_arangoDBVersion];
    _arangoDBConfig = [path stringByAppendingString:@"/arangod.conf"];
    _arangoDBAdminDir = [path stringByAppendingString:@"/html/admin"];
    
    _arangoDBJsStartupDir = [path stringByAppendingString:@"/js"];
    _arangoDBJsActionDir = [path stringByAppendingString:@"/js/actions"];
    _arangoDBJsAppDir = [path stringByAppendingString:@"/js/apps"];
    _arangoDBTempDir = [jsPath stringByAppendingString:@"/tmp"];
    
    NSString* path1 = [path stringByAppendingString:@"/js/server/modules"];
    NSString* path2 = [path stringByAppendingString:@"/js/common/modules"];
    NSString* path3 = [path stringByAppendingString:@"/js/node"];
    
    _arangoDBJsModuleDir = [[[[path1 stringByAppendingString: @";"]
                              stringByAppendingString: path2]
                              stringByAppendingString: @";"]
                              stringByAppendingString: path3];
    
    _arangoDBJsPackageDir = [path stringByAppendingString: @"/js/npm"];

    BOOL ok = [self loadConfigurations];

    if (! ok) {
      // TODO-fc broadcast fatal error
      return nil;
    }

    _instances = [[NSMutableDictionary alloc] init];
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief finds a free port
////////////////////////////////////////////////////////////////////////////////

- (NSNumber*) findFreePort {
  NSMutableArray* ports = [[NSMutableArray alloc] init];

  for (ArangoConfiguration* config in [_configurations allValues]) {
    [ports addObject:config.port];
  }

  [ports sortedArrayUsingComparator: ^(id obj1, id obj2) {return [obj1 compare:obj2];}];
  
  NSNumber* port = [NSNumber numberWithInt:8000];
  
  for (NSNumber* used in ports) {
    NSComparisonResult cmp = [port compare:used];
    
    if (cmp == NSOrderedAscending) {
      return port;
    }
    else if (cmp == NSOrderedSame) {
      port = [NSNumber numberWithInt:[port intValue] + 1];
    }
  }

  return port;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief starts up all instances
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startupInstances {
  BOOL ok = YES;
  int ros = [self runOnStartup];

  // arangos that were running at last shutdown
  if (ros == 1) {
    for (ArangoConfiguration* config in [_configurations allValues]) {
      if ([config.isRunning intValue] != 0) {
        ok = [self startArangoDB:config.alias] && ok;
      }
    }
  }

  // arangos that are labeled by the user
  else if (ros == 2) {
    for (ArangoConfiguration* config in [_configurations allValues]) {
      if ([config.runOnStartUp intValue] != 0) {
        ok = [self startArangoDB:config.alias] && ok;
      }
    }
  }

  // all arangos
  else if (ros == 3) {
    for (ArangoConfiguration* config in [_configurations allValues]) {
      ok = [self startArangoDB:config.alias] && ok;
    }
  }

  return ok;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief creates a new configuration
////////////////////////////////////////////////////////////////////////////////

- (BOOL) createConfiguration: (NSString*) alias
                    withPath: (NSString*) path
                     andPort: (int) port
                      andLog: (NSString*) logPath
                 andLogLevel: (NSString*) logLevel
             andRunOnStartUp: (BOOL) ros {
  self.lastError = nil;

  if ([_configurations objectForKey:alias] != nil) {
    self.lastError = [@"configuration already exists: " stringByAppendingString:alias];
    return NO;
  }

  ArangoConfiguration* config = (ArangoConfiguration*) [NSEntityDescription insertNewObjectForEntityForName:@"ArangoConfiguration" inManagedObjectContext:_managedObjectContext];

  config.alias = alias;
  config.path = path;
  config.port = [NSNumber numberWithInt:port];
  config.log = logPath;
  config.loglevel = logLevel;
  config.runOnStartUp = [NSNumber numberWithBool:ros];
  config.isRunning = [NSNumber numberWithBool:YES];

  if (106 < _version) {
    [self createBookmarks:config];
  }

  // save and broadcast change
  BOOL ok = [self saveConfigurations];

  if (ok) {
    [_configurations setValue:config forKey:alias];
    [[NSNotificationCenter defaultCenter] postNotificationName:ArangoConfigurationDidChange object:self];
  }
  else {
    [self loadConfigurations];
  }

  return ok;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief prepares directories
////////////////////////////////////////////////////////////////////////////////

- (ArangoStatus*) prepareConfiguration: (NSString*) alias
                              withPath: (NSString*) path
                               andPort: (int) port
                                andLog: (NSString*) logPath
                           andLogLevel: (NSString*) logLevel {

  // check the port
  if (port < 1024) {
    self.lastError = @"illegal or privileged port";
    return nil;
  }
  
  // check the instance name, remove spaces
  alias = [alias stringByReplacingOccurrencesOfString:@" " withString: @"_"];
  alias = [alias stringByReplacingOccurrencesOfString:@"/" withString: @"_"];
  alias = [alias stringByReplacingOccurrencesOfString:@"." withString: @"_"];

  if ([alias isEqualToString:@""]) {
    alias = @"ArangoDB";
  }

  // normalise database path
  path = [self checkDatabasePath:path andName:alias];

  if (path == nil) {
    return nil;
  }

  // try to create database directory
  if (! [[NSFileManager defaultManager] fileExistsAtPath:path]) {
    NSError* err = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&err];

    if (err != nil) {
      self.lastError = [@"cannot create database path: " stringByAppendingString:err.localizedDescription];
      return nil;
    }
  }

  // database path must be a directory and writeable
  BOOL isDir;
  [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];

  if (isDir) {
    if (! [[NSFileManager defaultManager] isWritableFileAtPath:path]) {
      self.lastError = @"cannot write into database directory";
      return nil;
    }
  }
  else {
    self.lastError = @"database path is not a directory";
    return nil;
  }

  // check the log path
  logPath = [self checkLogPath:logPath
                       andName:alias];

  // everything ready to start
  return [[ArangoStatus alloc] initWithName:alias
                                    andPath:path
                                    andPort:port
                                 andLogPath:logPath
                                andLogLevel:logLevel
                            andRunOnStartup:NO
                                 andRunning:NO];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief returns current status for all configurations
////////////////////////////////////////////////////////////////////////////////

- (NSArray*) currentStatus {
  NSMutableArray* result = [[NSMutableArray alloc] init];
  NSArray* configurations = [[_configurations allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

  for (NSString* name in configurations) {
    ArangoStatus* status = [self currentStatus:name];
    
    [result addObject:status];
  }

  return result;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief returns current status for a configurations
////////////////////////////////////////////////////////////////////////////////

- (ArangoStatus*) currentStatus: (NSString*) alias {
  ArangoConfiguration* config = [_configurations objectForKey:alias];

  if (config == nil) {
    return nil;
  }

  BOOL isRunning = NO;
  NSTask* task = [_instances objectForKey:alias];

  if (task != nil) {
    isRunning = [task isRunning];
  }

  return [[ArangoStatus alloc] initWithName:config.alias
                                    andPath:config.path
                                    andPort:[config.port intValue]
                                 andLogPath:config.log
                                andLogLevel:config.loglevel
                            andRunOnStartup:([config.runOnStartUp intValue] != 0)
                                 andRunning:isRunning];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief updates a configuration
////////////////////////////////////////////////////////////////////////////////

- (BOOL) updateConfiguration: (NSString*) alias
                    withPath: (NSString*) path
                     andPort: (int) port
                      andLog: (NSString*) logPath
                 andLogLevel: (NSString*) logLevel
             andRunOnStartUp: (BOOL) ros {

  // extract configuration
  ArangoConfiguration* config = [_configurations objectForKey:alias];

  if (config == nil) {
    self.lastError = [@"cannot update unknown configuration: " stringByAppendingString:alias];
    return NO;
  }

  // check the port
  if (port < 1024) {
    self.lastError = @"illegal or privileged port";
    return NO;
  }

  // check the log-path
  logPath = [self checkLogPath:logPath
                       andName:alias];

  if (logPath == nil) {
    return NO;
  }

  // check if we have to change the path, instance should be shut-down in this case
  if (! [config.path isEqualToString:path]) {

    // normalise database path
    path = [self checkDatabasePath:path andName:alias];

    if (path == nil) {
      return NO;
    }

    // path must not already exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
      self.lastError = @"cannot move database files: destination path already exists";
      return NO;
    }

    // instance must be shut-down
    BOOL isRunning = NO;
    NSTask* task = [_instances objectForKey:alias];

    if (task != nil) {
      isRunning = [task isRunning];
    }
    
    if (isRunning) {
      self.lastError = @"cannot change database path while instance is running";
      return NO;
    }

    // move files
    NSError* err;
    BOOL ok = [[NSFileManager defaultManager] moveItemAtPath:config.path toPath:path error:&err];

    if (! ok) {
      self.lastError = [@"cannot move database files: " stringByAppendingString:err.localizedDescription];
      return NO;
    }
  }

  // update config
  config.path = path;
  config.port = [NSNumber numberWithInt:port];
  config.log = logPath;
  config.loglevel = logLevel;
  config.runOnStartUp = [NSNumber numberWithBool:ros];

  if (106 < _version) {
    [self createBookmarks:config];
  }

  // save and broadcast change
  BOOL ok = [self saveConfigurations];

  if (ok) {
    [[NSNotificationCenter defaultCenter] postNotificationName:ArangoConfigurationDidChange object:self];
  }
  else {
    [self loadConfigurations];

    if (! [config.path isEqualToString:path]) {
      NSError* err;
      [[NSFileManager defaultManager] moveItemAtPath:path toPath:config.path error:&err];
    }
  }

  return ok;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief updates a configuration
////////////////////////////////////////////////////////////////////////////////

- (BOOL) updateConfiguration: (NSString*) alias
               withIsRunning: (BOOL) isRunning {

  // extract configuration
  ArangoConfiguration* config = [_configurations objectForKey:alias];

  if (config == nil) {
    self.lastError = [@"cannot update unknown configuration: " stringByAppendingString:alias];
    return NO;
  }

  // update config
  config.isRunning = [NSNumber numberWithBool:isRunning];

  // save and broadcast change
  BOOL ok = [self saveConfigurations];

  if (ok) {
    [[NSNotificationCenter defaultCenter] postNotificationName:ArangoConfigurationDidChange object:self];
  }
  else {
    [self loadConfigurations];
  }

  return ok;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief deletes database and log files
////////////////////////////////////////////////////////////////////////////////

- (BOOL) deleteDatabasePath: (NSString*) path
                 andLogFile: (NSString*) logPath {

  NSLog(@"Starting to remove database files");

  // remove security
  if (106 < _version) {
    [[NSURL fileURLWithPath:path] stopAccessingSecurityScopedResource];

    if (! [logPath isEqualToString:@""]) {
      [[NSURL fileURLWithPath:logPath] stopAccessingSecurityScopedResource];
    }
  }

  // delete log file and database path
  NSError* err = nil;
  BOOL ok;

  if (! [logPath isEqualToString:@""]) {
    ok = [[NSFileManager defaultManager] removeItemAtPath:logPath error:&err];

    if (! ok) {
      NSLog(@"cannot log file %@", err.localizedDescription);
      self.lastError = [NSString stringWithFormat:@"cannot remove database files: %@",err.localizedDescription];
    }
  }

  ok = [[NSFileManager defaultManager] removeItemAtPath:path error:&err];

  if (! ok) {
    NSLog(@"cannot remove database files %@", err.localizedDescription);
    self.lastError = [NSString stringWithFormat:@"cannot remove database files: %@",err.localizedDescription];
  }

  return ok;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief deletes a configuration
////////////////////////////////////////////////////////////////////////////////

- (BOOL) deleteConfiguration: (NSString*) alias {
  ArangoConfiguration* config = [_configurations objectForKey:alias];

  if (config == nil) {
    self.lastError = [@"cannot delete unknown configuration: " stringByAppendingString:alias];
    return NO;
  }

  // delete bookmarks
  [self deleteBookmarks:config];

  // delete configuration
  [_managedObjectContext deleteObject:config];

  // save and broadcast change
  BOOL ok = [self saveConfigurations];

  if (ok) {
    [_configurations removeObjectForKey:alias];
    [[NSNotificationCenter defaultCenter] postNotificationName:ArangoConfigurationDidChange object:self];
  }
  else {
    [self loadConfigurations];
  }

  return ok;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief starts a new ArangoDB instance with the given name
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startArangoDB: (NSString*) name {

  // load configuration for name
  ArangoConfiguration* config = [_configurations objectForKey:name];
  
  if (config == nil) {
    self.lastError = [@"cannot start instance for unknown configuration: " stringByAppendingString:name];
    return NO;
  }
  
  // check if a task with that name exists
  NSTask* task = [_instances objectForKey:name];

  if (task != nil) {
    if ([task isRunning]) {
      self.lastError = [@"instance already running: " stringByAppendingString:name];
      return NO;
    }
  }

  // check for sandboxed mode
  if (config.bookmarks != nil  && 106 < _version) {
    NSURL* bmPath = [self urlForBookmark:config.bookmarks.path];

    if (! [bmPath startAccessingSecurityScopedResource]) {
      self.lastError = [@"not allowed to open database path " stringByAppendingString:config.path];
      return NO;
    }

    if (! [config.log isEqualToString:@""]) {
      NSURL* bmLog = [self urlForBookmark:config.bookmarks.log];

      if (! [bmLog startAccessingSecurityScopedResource]) {
        self.lastError = [@"not allowed to open log path " stringByAppendingString:config.log];
        return NO;
      }
    }
  }

  // cleanup path from version 1.0
  NSString* database = [config.path stringByAppendingString:@"/database"];
  
  if (! [[NSFileManager defaultManager] isReadableFileAtPath:database]) {
    int res = mkdir([database fileSystemRepresentation], 0777);

    if (res != 0) {
      NSLog(@"Cannot create database directory: %@", database);
      return NO;
    }

    BOOL ok = [self moveDatabaseFiles:config.path toDestination:database];

    if (! ok) {
      NSLog(@"Cannot move database directory to %@", database);
      return NO;
    }
  }

  // create log path
  NSString* logPath = config.log;

  if ([logPath isEqualToString:@""]) {
    NSMutableString* tmp = [[NSMutableString alloc] init];
    [tmp setString:config.path];
    [tmp appendString:@"/"];
    [tmp appendString:config.alias];
    [tmp appendString:@".log"];
    logPath = tmp;
    
    if (! [[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
      BOOL ok = [[NSFileManager defaultManager] createFileAtPath:logPath
                                                        contents:nil
                                                      attributes:nil];

      if (! ok) {
        self.lastError = [[@"cannot create log file '" stringByAppendingString:logPath] stringByAppendingString:@"'"];
        return NO;
      }
    }
  }

  // check if upgrade is necessary.
  NSError* versionReadError;
  NSString* versionFile = [database stringByAppendingString:@"/VERSION"];
  NSData* versionInfo = [NSData dataWithContentsOfFile:versionFile];
  if (versionInfo != nil) {
    id obj = [NSJSONSerialization JSONObjectWithData:versionInfo options:0 error:&versionReadError];
    
    if (versionReadError != nil) {
      self.lastError = @"Version information error";
      NSLog(@"Version information error while parsing JSON: %@", versionReadError);
      return NO;
    }
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
      NSDictionary* json = obj;
      NSString* versionString = [json objectForKey:@"version"];
      float dbVersion = [versionString floatValue];
      if (dbVersion < _currentVersion) {
        NSAlert* confirmUpgrade = [NSAlert
                                   alertWithMessageText:@"Datafiles have to be upgraded"
                                   defaultButton:@"Upgrade"
                                   alternateButton:@"Cancel"
                                   otherButton:nil
                                   informativeTextWithFormat:@"The files in your database directory have been created with ArangoDB version %.1f and should be upgraded to version %.1f. If you cancel this operation your ArangoDB will not be started.", dbVersion, _currentVersion];
        NSInteger clicked = [confirmUpgrade runModal];

        // User did Cancel the operation
        if (clicked == NSAlertAlternateReturn) {
          self.lastError = @"Upgrade canceled";
          NSLog(@"User did cancel the upgrade.");
          return NO;
        }

        // Database needs upgrade
        NSArray* upgradeArguments = [NSArray arrayWithObjects:
                                     @"--config", _arangoDBConfig,
                                     @"--exit-on-parent-death", @"true",
                                     @"--server.endpoint", [NSString stringWithFormat:@"tcp://0.0.0.0:%@", config.port.stringValue],
                                     @"--server.admin-directory", _arangoDBAdminDir,
                                     @"--javascript.modules-path", _arangoDBJsModuleDir,
                                     @"--javascript.startup-directory", _arangoDBJsStartupDir,
                                     @"--javascript.action-directory", _arangoDBJsActionDir,
                                     @"--upgrade",
                                     database,
                                     nil];

        NSTask* upgrade = [[NSTask alloc] init];
        [upgrade setLaunchPath:_arangoDBBinary];
        [upgrade setArguments:upgradeArguments];
        ArangoUpgradeInfoController* infoScreen = [[ArangoUpgradeInfoController alloc]
                                                   initWithArangoManager:self
                                                   andAppDelegate:(ArangoAppDelegate*)[[NSApplication sharedApplication] delegate]];
        [upgrade launch];
        [upgrade waitUntilExit];
        int upgradeStatus = [upgrade terminationStatus];
        [infoScreen closeInfo:nil];

        if (upgradeStatus != 0) {
          NSLog(@"Upgrade failed with status: %i", upgradeStatus);
          self.lastError = @"Upgrade process failed, see log for details";
          return NO;
        }
      }
    }
    else {
      self.lastError = @"Could not parse version information";
      NSLog(@"JSON Parsing failed...: %@", obj);
      return NO;
    }
  }

  // prepare task
  task = [[NSTask alloc] init];
  [task setLaunchPath:_arangoDBBinary];

  NSArray* arguments = [NSArray arrayWithObjects:
                        @"--config", _arangoDBConfig,
                        @"--exit-on-parent-death", @"true",
                        @"--server.endpoint", [NSString stringWithFormat:@"tcp://0.0.0.0:%@", config.port.stringValue],
                        @"--log.file", logPath,
                        @"--log.level", config.loglevel,
                        @"--server.admin-directory", _arangoDBAdminDir,
                        @"--javascript.action-directory", _arangoDBJsActionDir,
                        @"--javascript.startup-directory", _arangoDBJsStartupDir,
                        @"--javascript.modules-path", _arangoDBJsModuleDir,
                        @"--javascript.package-path", _arangoDBJsPackageDir,
                        @"--javascript.app-path", _arangoDBJsAppDir,
                        @"--temp-path", _arangoDBTempDir,
                        database,
                        nil];
  [task setArguments:arguments];

  // callback if the ArangoDB is terminated for whatever reason.
  if ([task respondsToSelector:@selector(setTerminationHandler:)]) {
    [task setTerminationHandler: ^(NSTask *task) {
        NSLog(@"ArangoDB instance '%@' has terminated", name);
        [[NSNotificationCenter defaultCenter] postNotificationName:ArangoConfigurationDidChange object:self];
    }];
  }

  // and launch
  NSLog(@"Preparing to start %@ with %@", _arangoDBBinary, arguments);
  [task launch];

  // and store instance
  [_instances setValue:task forKey:name];

  config.isRunning = [NSNumber numberWithBool:YES];
  [self saveConfigurations];

  [[NSNotificationCenter defaultCenter] postNotificationName:ArangoConfigurationDidChange object:self];

  return YES;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief stops an ArangoDB instance
////////////////////////////////////////////////////////////////////////////////

- (BOOL) stopArangoDB: (NSString*) name
              andWait: (BOOL) waitForTerminate {
  NSLog(@"Stopping ArangoDB instance '%@'", name);
  // load configuration for name (might already be deleted)
  ArangoConfiguration* config = [_configurations objectForKey:name];
  
  if (config != nil) {
    config.isRunning = [NSNumber numberWithBool:NO];
    [self saveConfigurations];
  }
  
  // check if task exists
  NSTask* task = [_instances objectForKey:name];

  if (task == nil) {
    return YES;
  }

  // terminate
  if ([task isRunning]) {
    [task terminate];
  }

  // wait for termination
  if (waitForTerminate) {
    [task waitUntilExit];
  }
  
  return YES;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief runOnStartup options
////////////////////////////////////////////////////////////////////////////////

- (int) runOnStartup {
  return [_user.runOnStartUp intValue];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief startupOnLogin options
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startupOnLogin {
  LSSharedFileListRef autostart = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems, nil);

  if (autostart) {
    UInt32 seedValue;
    NSArray  *loginItemsArray = (NSArray *) CFBridgingRelease(LSSharedFileListCopySnapshot(autostart, &seedValue));

    for (int i = 0; i<  [loginItemsArray count];  ++i) {
      LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef) [loginItemsArray objectAtIndex:i];
      CFURLRef url = (__bridge CFURLRef) [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];

      if (LSSharedFileListItemResolve(itemRef, 0, &url, nil) == noErr) {
        NSString * urlPath = [(__bridge NSURL*)url path];

        if ([urlPath compare:[[NSBundle mainBundle] bundlePath]] == NSOrderedSame) {
          return YES;
        }
      }
    }

  }

  return NO;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief sets startupOnLogin and runOnStartup
////////////////////////////////////////////////////////////////////////////////

- (void) setRunOnStartup: (int) runOnStartup
       setStartupOnLogin: (BOOL) startupOnLogin {

  // update run on startup
  _user.runOnStartUp = [NSNumber numberWithInt:runOnStartup];
  [self saveConfigurations];

  // check startupOnLogin
  LSSharedFileListRef autostart = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems, nil);

  if (autostart) {
    if (startupOnLogin) {
      LSSharedFileListItemRef arangoStarter = LSSharedFileListInsertItemURL(autostart, kLSSharedFileListItemLast, nil, nil, (__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]], nil, nil);

      if (arangoStarter) {
        CFRelease(arangoStarter);
      }

      CFRelease(autostart);
    }
    else {
      UInt32 seedValue;
      NSArray  *loginItemsArray = (NSArray *) CFBridgingRelease(LSSharedFileListCopySnapshot(autostart, &seedValue));

      for (int i = 0; i< [loginItemsArray count]; i++){
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef) [loginItemsArray objectAtIndex:i];
        CFURLRef url = (__bridge CFURLRef) [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];

        if (LSSharedFileListItemResolve(itemRef, 0, &url, nil) == noErr) {
          NSString * urlPath = [(__bridge NSURL*)url path];

          if ([urlPath compare:[[NSBundle mainBundle] bundlePath]] == NSOrderedSame){
            LSSharedFileListItemRemove(autostart,itemRef);
          }
        }
      }

    }
  }
}

@end

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "^\\(/// @brief\\|/// {@inheritDoc}\\|/// @addtogroup\\|/// @page\\|// --SECTION--\\|/// @\\}\\)"
// End:
