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
    [_configurations setValue:c forKey:c.alias];
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:ArangoConfigurationDidChange object:self];

  return YES;
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

  if (self != nil) {
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

    _instances = [[NSMutableDictionary alloc] init];
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

  [_instances release];

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
  self.lastError = nil;

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
                               andPort: (NSNumber*) port
                                andLog: (NSString*) logPath {
  self.lastError = nil;

  // check the port
  if ([port intValue] < 1024) {
    self.lastError = @"illegal or privileged port";
    return nil;
  }
  
  // check the instance name, remove spaces
  alias = [alias stringByReplacingOccurrencesOfString:@" " withString: @"_"];

  if ([alias isEqualToString:@""]) {
    alias = @"ArangoDB";
  }

  // normalise database path
  if ([path hasPrefix:@"~"]){
    path = [NSHomeDirectory() stringByAppendingString:[path substringFromIndex:1]];
  }
  else if ([path isEqualToString:@""]) {
    self.lastError = @"database path must not be empty";
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
  if ([logPath isEqualToString:@""]) {
    NSMutableString* logPath = [[[NSMutableString alloc] init] autorelease];
    [logPath setString:path];
    [logPath appendString:@"/"];
    [logPath appendString:alias];
    [logPath appendString:@".log"];

    if (! [[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
      BOOL ok = [[NSFileManager defaultManager] createFileAtPath:logPath
                                                        contents:nil
                                                      attributes:nil];

      if (! ok) {
        self.lastError = [[@"cannot create log file '" stringByAppendingString:logPath] stringByAppendingString:@"'"];
        return nil;
      }
    }
  }
  else {
    if ([[NSFileManager defaultManager] fileExistsAtPath:logPath isDirectory:&isDir]) {
      if (isDir) {
        NSMutableString* tmp = [[[NSMutableString alloc] initWithString:logPath] autorelease];
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
  }

  // everything ready to start
  return [[ArangoStatus alloc] initWithName:alias
                                    andPath:path
                                    andPort:port
                                 andLogPath:logPath
                                 andRunning:NO];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief reads a configurations
////////////////////////////////////////////////////////////////////////////////

- (ArangoConfiguration*) configuration: (NSString*) alias {
  return [_configurations objectForKey:alias];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief returns current status for all configurations
////////////////////////////////////////////////////////////////////////////////

- (NSArray*) currentStatus {
  NSMutableArray* result = [[[NSMutableArray alloc] init] autorelease];
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

  return [[[ArangoStatus alloc] initWithName:config.alias
                                     andPath:config.path
                                     andPort:config.port
                                  andLogPath:config.log
                                  andRunning:false] autorelease];
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
  self.lastError = nil;

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
  else {
    [self loadConfigurations];
  }

  return ok;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief deletes a configuration
////////////////////////////////////////////////////////////////////////////////

- (BOOL) deleteConfiguration: (NSString*) alias {
  self.lastError = nil;

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

- (BOOL) stopArangoDBAndDelete: (NSString*) name {
  NSLog(@"stop and delete arangodb");
  return YES;
}

- (BOOL) stopArangoDB: (NSString*) name {
  NSLog(@"stop arangodb");
  return YES;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief starts a new ArangoDB instance with the given name
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startArangoDB: (NSString*) name {

  // load configuration for name
  ArangoConfiguration* config = [_configurations objectForKey:name];
  
  if (config == nil) {
    self.lastError = [@"Cannot start instance for unknown configuration: " stringByAppendingString:name];
    return NO;
  }
  
  // check if a task with that name exists
  NSTask* task = [_instances objectForKey:name];

  if (task != nil) {
    self.lastError = [@"Instance already running: " stringByAppendingString:name];
    return NO;
  }

  // check for sandboxed mode
  if (config.bookmarks != nil  && 106 < _version) {
    NSURL* bmPath = [self urlForBookmark:config.bookmarks.path];

    if (! [bmPath startAccessingSecurityScopedResource]) {
      self.lastError = [@"Not allowed to open database path " stringByAppendingString:config.path];
      return NO;
    }

    NSURL* bmLog = [self urlForBookmark:config.bookmarks.log];

    if (! [bmLog startAccessingSecurityScopedResource]) {
      self.lastError = [@"Not allowed to open log path " stringByAppendingString:config.log];
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
  [task setLaunchPath:_arangoDBBinary];

  NSArray* arguments = [NSArray arrayWithObjects:
                        @"--config", _arangoDBConfig,
                        @"--exit-on-parent-death", @"true",
                        @"--server.endpoint", [NSString stringWithFormat:@"tcp://0.0.0.0:%@", config.port.stringValue],
                        @"--log.file", config.log,
                        @"--log.level", config.loglevel,
                        @"--server.admin-directory", _arangoDBAdminDir,
                        @"--javascript.action-directory", _arangoDBJsActionDir,
                        @"--javascript.modules-path", _arangoDBJsModuleDir,
                        database, nil];
  [task setArguments:arguments];

  // callback if the ArangoDB is terminated for whatever reason.
  if ([task respondsToSelector:@selector(setTerminationHandler:)]) {
    [task setTerminationHandler: ^(NSTask *task) {
        NSLog(@"ArangoDB instance '%@' has terminated", name);
        // TODO-FC send notification
    }];
  }

  // and launch
  NSLog(@"Preparing to start %@ with %@", _arangoDBBinary, arguments);
  [task launch];

  // and store instance
  [_instances setValue:task forKey:name];

  return YES;
}

@end

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "^\\(/// @brief\\|/// {@inheritDoc}\\|/// @addtogroup\\|/// @page\\|// --SECTION--\\|/// @\\}\\)"
// End:
