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

#import "ArangoConfiguration.h"
#import "User.h"
#import "Bookmarks.h"

// -----------------------------------------------------------------------------
// --SECTION--                                                 private functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief moves database files
////////////////////////////////////////////////////////////////////////////////

static int TRI_MoveDatabaseFiles (NSString* src, NSString* dst) {
  DIR * d;
  struct dirent * de;

  d = opendir([src fileSystemRepresentation]);

  if (d == 0) {
    return errno;
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
        NSLog(@"Cannot renamed %@ to %@: %@", from, to, err.localizedDescription);
        closedir(d);
        return -1;
      }
    }

    de = readdir(d);
  }

  closedir(d);
  return 0;
}

// -----------------------------------------------------------------------------
// --SECTION--                                              ArangoBaseController
// -----------------------------------------------------------------------------

@implementation ArangoManager

// -----------------------------------------------------------------------------
// --SECTION--                                                   private methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief saves all changes made to the configuration
////////////////////////////////////////////////////////////////////////////////

- (BOOL) save
{
  NSError* error = nil;

  [self.managedObjectContext save:&error];

  if (error != nil) {
    NSLog(@"Cannot save configuration: %@", error.localizedDescription);
    return NO;
  }

  return YES;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief creates bookmark from url
////////////////////////////////////////////////////////////////////////////////

- (NSData*)bookmarkForURL:(NSURL*)url {
  if (self.version == 106) {
    return nil;
  }

  NSError* error = nil;
  NSData* bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                   includingResourceValuesForKeys:nil
                                    relativeToURL:nil
                                            error:&error];
  if (error || (bookmark == nil)) {
    NSLog(@"Failed to create Bookmark");
    NSLog(@"%@", error.localizedDescription);

    return nil;
  }

  return bookmark;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief extracts url from bookmark
////////////////////////////////////////////////////////////////////////////////

- (NSURL*) urlForBookmark: (NSData*) bookmark
{
  if (self.version == 106) {
    return nil;
  }

  BOOL bookmarkIsStale = NO;
  NSError* error = nil;
  NSURL* bookmarkURL = [NSURL URLByResolvingBookmarkData:bookmark
                                                 options:(NSURLBookmarkResolutionWithoutUI|NSURLBookmarkResolutionWithSecurityScope)
                                           relativeToURL:nil
                                     bookmarkDataIsStale:&bookmarkIsStale
                                                   error:&error];
  
  if (bookmarkIsStale || error != nil) {
    NSLog(@"Failed to resolve URL");
    NSLog(@"%@", error.localizedDescription);
    return nil;
  }

  return bookmarkURL;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief gets the Context necessary for persistent storage
////////////////////////////////////////////////////////////////////////////////

- (NSManagedObjectContext*) getArangoManagedObjectContext
{
  if (self.managedObjectContext == nil) {
    NSURL *storeURL = [[[[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"ArangoDB"] retain];

    if (![[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]]) {
      NSError* error = nil;
      
      if ([[NSFileManager defaultManager] respondsToSelector:@selector(createDirectoryAtURL:withIntermediateDirectories:attributes:error:)]) {
        [[NSFileManager defaultManager] createDirectoryAtURL:storeURL withIntermediateDirectories:YES attributes:nil error:&error];
      }
      else {
        [[NSFileManager defaultManager] createDirectoryAtPath:[storeURL path] withIntermediateDirectories:YES attributes:nil error:&error];
      }
      
      if (error != nil) {
        NSLog(@"Failed to create sqlite");
        return nil;
      }
    }
    
    storeURL = [[storeURL URLByAppendingPathComponent:@"ArangoDB.sqlite"] retain];

    NSURL *modelURL = [[[NSBundle mainBundle] URLForResource:@"configurationModel" withExtension:@"momd"] retain];
    NSError *error = nil;
    NSPersistentStoreCoordinator* coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL]];

    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      return nil;
    }
    
    self.managedObjectContext = [[NSManagedObjectContext alloc] init];
    [self.managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    [storeURL release];
    [modelURL release];
    [coordinator release];
  }
  
  return self.managedObjectContext;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief loads the configurations
////////////////////////////////////////////////////////////////////////////////

- (BOOL) loadConfigurations
{
  [self getArangoManagedObjectContext];
  
  if (self.managedObjectContext == nil) {
    return NO;
  }
  
  // load the global user configuration
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
  NSEntityDescription *entity = [[NSEntityDescription entityForName:@"User" inManagedObjectContext: self.managedObjectContext] retain];
  [request setEntity:entity];
  [entity release];
  
  NSError *error = nil;
  NSArray *fetchedResults = [self.managedObjectContext executeFetchRequest:request error:&error];
  [request release];
  
  if (fetchedResults == nil) {
    NSLog(@"cannot load global user configuration: %@", error.localizedDescription);
    return NO;
  }
  else {
    if (0 < fetchedResults.count) {
      for (User* u in fetchedResults) {
        self.user = u;
      }
    }
    else {
      self.user = (User*) [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:self.managedObjectContext];
    }
  }
  
  // load the configurations
  request = [[NSFetchRequest alloc] init];
  entity = [NSEntityDescription entityForName:@"ArangoConfiguration" inManagedObjectContext: self.managedObjectContext];
  [request setEntity:entity];
  [entity release];
  
  error = nil;
  self.configurations = [self.managedObjectContext executeFetchRequest:request error:&error];
  [request release];

  if (self.configurations == nil) {
    NSLog(@"cannot load configurations: %@", error.localizedDescription);
    return NO;
  }
  
  // map names to configurations
  self.namedConfigurations = [[NSMutableDictionary alloc] init];
  
  for (ArangoConfiguration* c in self.configurations) {
    [self.namedConfigurations setValue:c forKey:c.alias];
  }
  
  return YES;
}

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief default constructor
////////////////////////////////////////////////////////////////////////////////

- (ArangoManager*) init
{
  self = [super init];

  if (self) {
    if ([[NSBundle mainBundle] respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)]) {
      self.arangoDBVersion = @"/arangod_10_8";
      self.version = 108;
    } 
    else if ([[NSFileManager defaultManager] respondsToSelector:@selector(createDirectoryAtURL:withIntermediateDirectories:attributes:error:)]) {
      self.arangoDBVersion = @"/arangod_10_7";
      self.version = 107;
    } 
    else {
      self.arangoDBVersion = @"/arangod_10_6";
      self.version = 106;
    }

    NSString* path = [[NSBundle mainBundle] resourcePath];

    self.arangoDBBinary = [path stringByAppendingString:self.arangoDBVersion];
    self.arangoDBConfig = [path stringByAppendingString:@"/arangod.conf"];
    self.arangoDBAdminDir = [path stringByAppendingString:@"/html/admin"];
    self.arangoDBJsActionDir = [path stringByAppendingString:@"/js/actions/system"];
    self.arangoDBJsModuleDir = [[path stringByAppendingString:@"/js/server/modules:"] stringByAppendingString:[path stringByAppendingString:@"/js/common/modules"]];

    BOOL ok = [self loadConfigurations];

    if (! ok) {
      [self release];
      return nil;
    }
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief creates a new configuration
////////////////////////////////////////////////////////////////////////////////

- (BOOL) createConfiguration: (NSString*) alias
                    withPath: (NSString*) path
                     andPort: (NSNumber*) port
                      andLog: (NSString*) logPath
                 andLogLevel: (NSString*) logLevel
             andRunOnStartUp: (BOOL) ros
{
  if ([self.namedConfigurations objectForKey:alias] != nil) {
    NSLog(@"Configuration already exists: %@", alias);
    return NO;
  }

  ArangoConfiguration* config = (ArangoConfiguration*) [NSEntityDescription insertNewObjectForEntityForName:@"ArangoConfiguration" inManagedObjectContext:self.managedObjectContext];

  if (self.version > 106) {
    NSURL* pathURL = [NSURL fileURLWithPath:path];
    NSData* bookmarkPath = [self bookmarkForURL:pathURL];
    NSURL* logURL = [NSURL fileURLWithPath:logPath];
    NSData* bookmarkLog = [self bookmarkForURL:logURL];
    Bookmarks* bookmarks = (Bookmarks*) [NSEntityDescription insertNewObjectForEntityForName:@"Bookmarks" inManagedObjectContext:self.managedObjectContext];

    bookmarks.path = bookmarkPath;
    bookmarks.log = bookmarkLog;
    bookmarks.config = config;

    config.bookmarks = bookmarks;
  }

  config.alias = alias;
  config.path = path;
  config.port = port;
  config.log = logPath;
  config.loglevel = logLevel;
  config.runOnStartUp = [NSNumber numberWithBool:ros];

  return [self save];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief starts a new ArangoDB instance with the given name
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startArangoDB: (NSString*) name
{

  // load configuration for name
  ArangoConfiguration* config = [self.namedConfigurations objectForKey:name];
  
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

    res = TRI_MoveDatabaseFiles(config.path, database);

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

@end

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "^\\(/// @brief\\|/// {@inheritDoc}\\|/// @addtogroup\\|/// @page\\|// --SECTION--\\|/// @\\}\\)"
// End:
