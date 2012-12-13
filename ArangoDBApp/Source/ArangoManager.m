////////////////////////////////////////////////////////////////////////////////
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
  DIR * d;
  struct dirent * de;

  d = opendir([src fileSystemRepresentation]);

  if (d == 0) {
    self.lastError = [[[@"Cannot open database directory " stringByAppendingString:src] stringByAppendingString:@": "] stringByAppendingString:[NSString stringWithCString:strerror(errno) encoding:NSUTF8StringEncoding]];
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
        self.lastError = [[[@"Cannot rename file " stringByAppendingString:from] stringByAppendingString:@": "] stringByAppendingString:err.localizedDescription];
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
/// @brief creates the context necessary for persistent storage
////////////////////////////////////////////////////////////////////////////////

- (BOOL) createManagedObjectContext {
  if (_managedObjectContext == nil) {
    NSError* err = nil;
    NSURL *storeURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"ArangoDB"];

    // create storage path
    if (! [[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]]) {
      if ([[NSFileManager defaultManager] respondsToSelector:@selector(createDirectoryAtURL:withIntermediateDirectories:attributes:error:)]) {
        [[NSFileManager defaultManager] createDirectoryAtURL:storeURL withIntermediateDirectories:YES attributes:nil error:&err];
      }
      else {
        [[NSFileManager defaultManager] createDirectoryAtPath:[storeURL path] withIntermediateDirectories:YES attributes:nil error:&err];
      }
      
      if (err != nil) {
        self.lastError = [@"failed to create SQLITE application storage: " stringByAppendingString:err.localizedDescription];
        return NO;
      }
    }
    
    // create SQLITE
    NSURL* sqliteURL = [storeURL URLByAppendingPathComponent:@"ArangoDB.sqlite"];
    NSURL* modelURL = [[NSBundle mainBundle] URLForResource:@"configurationModel" withExtension:@"momd"];
    NSManagedObjectModel* model = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] autorelease];
    NSPersistentStoreCoordinator* coordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model] autorelease];

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
  NSError* error = nil;

  [_managedObjectContext save:&error];

  if (error != nil) {
    self.lastError = [@"cannot save configuration: " stringByAppendingString: error.localizedDescription];
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

  NSURL* logURL = [NSURL fileURLWithPath:config.log];
  NSData* log = [self bookmarkForURL:logURL];

  Bookmarks* bookmarks = (Bookmarks*) [NSEntityDescription insertNewObjectForEntityForName:@"Bookmarks" inManagedObjectContext:_managedObjectContext];

  bookmarks.path = path;
  bookmarks.log = log;
  bookmarks.config = config;

  config.bookmarks = bookmarks;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief deletes bookmark from a configuration
////////////////////////////////////////////////////////////////////////////////

- (void) deleteBookmarks: (ArangoConfiguration*) config {
  [_managedObjectContext deleteObject:config.bookmarks];
  config.bookmarks = nil;
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
  if (err) {
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
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext: _managedObjectContext];
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
      }
    }
    else {
      _user = (User*) [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:_managedObjectContext];
    }
  }
  
  // load the configurations
  request = [[[NSFetchRequest alloc] init] autorelease];
  entity = [NSEntityDescription entityForName:@"ArangoConfiguration" inManagedObjectContext: _managedObjectContext];
  [request setEntity:entity];

  err = nil;
  NSArray* configurations = [_managedObjectContext executeFetchRequest:request error:&err];

  if (err) {
    self.lastError = [@"cannot load configurations: " stringByAppendingString:err.localizedDescription];
    return NO;
  }

  // update bookmarks if necessary
  for (ArangoConfiguration* config in configurations) {
    if (106 < _version) {
      if (config.bookmarks == nil) {
        [self createBookmarks:config];
      }
    }
    else {
      if (config.bookmarks != nil) {
        [self deleteBookmarks:config];
      }
    }
  }  

  // map names to configurations
  _configurations = [[NSMutableDictionary alloc] init];
  
  for (ArangoConfiguration* c in configurations) {
    [_configurations setValue:c forKey:c.alias];
  }
  
  // in case we changed the bookmarks
  return [self saveConfigurations];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief deletes database files XXXX
////////////////////////////////////////////////////////////////////////////////

/*
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
  }
  else {
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
 */

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief default constructor
////////////////////////////////////////////////////////////////////////////////

- (ArangoManager*) init {
  self = [super init];

  if (self) {
    if ([[NSBundle mainBundle] respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)]) {
      _arangoDBVersion = @"/arangod_10_8";
      _version = 108;
    } 
    else if ([[NSFileManager defaultManager] respondsToSelector:@selector(createDirectoryAtURL:withIntermediateDirectories:attributes:error:)]) {
      _arangoDBVersion = @"/arangod_10_7";
      _version = 107;
    } 
    else {
      _arangoDBVersion = @"/arangod_10_6";
      _version = 106;
    }

    NSString* path = [[NSBundle mainBundle] resourcePath];

    _arangoDBBinary = [path stringByAppendingString:_arangoDBVersion];
    _arangoDBConfig = [path stringByAppendingString:@"/arangod.conf"];
    _arangoDBAdminDir = [path stringByAppendingString:@"/html/admin"];
    _arangoDBJsActionDir = [path stringByAppendingString:@"/js/actions/system"];
    _arangoDBJsModuleDir = [[path stringByAppendingString:@"/js/server/modules:"] stringByAppendingString:[path stringByAppendingString:@"/js/common/modules"]];

    BOOL ok = [self loadConfigurations];

    if (! ok) {
      // TODO-fc broadcast fatal error
      [self release];
      return nil;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:ArangoConfigurationDidChange object:self];
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief destructor
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
  [_arangoDBVersion release];
  [_arangoDBBinary release];
  [_arangoDBConfig release];
  [_arangoDBAdminDir release];
  [_arangoDBJsActionDir release];
  [_arangoDBJsModuleDir release];

  [_managedObjectContext release];

  [_configurations release];
  [_user release];

  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief creates a new configuration
////////////////////////////////////////////////////////////////////////////////

- (BOOL) createConfiguration: (NSString*) alias
                    withPath: (NSString*) path
                     andPort: (NSNumber*) port
                      andLog: (NSString*) logPath
                 andLogLevel: (NSString*) logLevel
             andRunOnStartUp: (BOOL) ros {
  if ([_configurations objectForKey:alias] != nil) {
    self.lastError = [@"configuration already exists: " stringByAppendingString:alias];
    return NO;
  }

  ArangoConfiguration* config = (ArangoConfiguration*) [NSEntityDescription insertNewObjectForEntityForName:@"ArangoConfiguration" inManagedObjectContext:_managedObjectContext];

  config.alias = alias;
  config.path = path;
  config.port = port;
  config.log = logPath;
  config.loglevel = logLevel;
  config.runOnStartUp = [NSNumber numberWithBool:ros];

  if (106 < _version) {
    [self createBookmarks:config];
  }

  // save and broadcast change
  BOOL ok = [self saveConfigurations];

  if (ok) {
    [_configurations setValue:config forKey:alias];
    [[NSNotificationCenter defaultCenter] postNotificationName:ArangoConfigurationDidChange object:self];
  }

  return ok;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief returns current status
////////////////////////////////////////////////////////////////////////////////

- (NSArray*) currentStatus {
  NSMutableArray* result = [[[NSMutableArray alloc] init] autorelease];
  NSArray* configurations = [_configurations allKeys];

  for (NSString* name in configurations) {
    ArangoConfiguration* config = [_configurations objectForKey:name];
    ArangoStatus* status = [[ArangoStatus alloc] initWithName:config.alias
                                                      andPort:config.port
                                                   andRunning:false];
    
    [result addObject:status];
    [status release];
  }

  return result;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief updates a configuration
////////////////////////////////////////////////////////////////////////////////

- (BOOL) updateConfiguration: (NSString*) alias
                    withPath: (NSString*) path
                     andPort: (NSNumber*) port
                      andLog: (NSString*) logPath
                 andLogLevel: (NSString*) logLevel
             andRunOnStartUp: (BOOL) ros {
  ArangoConfiguration* config = [_configurations objectForKey:alias];

  if (config == nil) {
    self.lastError = [@"cannot update unknown configuration: " stringByAppendingString:alias];
    return NO;
  }

  config.path = path;
  config.port = port;
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
  [_managedObjectContext deleteObject: config];

  // save and broadcast change
  BOOL ok = [self saveConfigurations];

  if (ok) {
    [_configurations removeObjectForKey:alias];
    [[NSNotificationCenter defaultCenter] postNotificationName:ArangoConfigurationDidChange object:self];
  }

  return ok;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief starts a new ArangoDB instance with the given name
////////////////////////////////////////////////////////////////////////////////

/*
- (BOOL) startArangoDB: (NSString*) name
{

  // load configuration for name
  ArangoConfiguration* config = [self.configurations objectForKey:name];
  
  if (config == nil) {
    NSLog(@"Unkown configuration: %@, cannot start instance", name);
    return NO;
  }
  
  // check if a task with that name exists
  if (config.instance != nil) {
    NSLog(@"Tasks already exists for instance named %@", name);
    return NO;
  }

  // check for sandboxed mode
  if (config.bookmarks != nil  && self.version > 106) {
    NSURL* bmPath = [self urlForBookmark:config.bookmarks.path];
    config.path = [bmPath path];

    if (! [bmPath startAccessingSecurityScopedResource]) {
      NSLog(@"Not allowed to open path.");
      return NO;
    }

    NSURL* bmLog = [self urlForBookmark:config.bookmarks.log];
    config.log = [bmLog path];

    if (! [bmLog startAccessingSecurityScopedResource]) {
      NSLog(@"Not allowed to open log.");
      return NO;
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

    res = [self moveDatabaseFiles:config.path toDestination:database];

    if (res != 0) {
      NSLog(@"Cannot move database directory to %@", database);
      return NO;
    }
  }

  // prepare task
  task = [[NSTask alloc] init];
  [task setLaunchPath:self.arangoDBBinary];

  NSArray* arguments = [NSArray arrayWithObjects:
                        @"--config", self.arangoDBConfig,
                        @"--exit-on-parent-death", @"true",
                        @"--server.endpoint", [NSString stringWithFormat:@"tcp://0.0.0.0:%@", config.port.stringValue],
                        @"--log.file", config.log,
                        @"--log.level", config.loglevel,
                        @"--server.admin-directory", self.arangoDBAdminDir,
                        @"--javascript.action-directory", self.arangoDBJsActionDir,
                        @"--javascript.modules-path", self.arangoDBJsModuleDir,
                        database, nil];
  [task setArguments:arguments];

  config.instance = task;

  // callback if the ArangoDB is terminated for whatever reason.
  if ([task respondsToSelector:@selector(setTerminationHandler:)]) {
    [task setTerminationHandler: ^(NSTask *task) {
        NSLog(@"ArangoDB instance '%@' has terminated", name);
        // TODO-FC send notification
    }];
  }

  // and launch
  NSLog(@"Preparing to start %@ with %@", self.arangoDBBinary, arguments);
  [task launch];

  return YES;
}
 */

@end

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "^\\(/// @brief\\|/// {@inheritDoc}\\|/// @addtogroup\\|/// @page\\|// --SECTION--\\|/// @\\}\\)"
// End:
