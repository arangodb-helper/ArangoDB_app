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

#import <Foundation/Foundation.h>

@class ArangoStatus;
@class User;

// -----------------------------------------------------------------------------
// --SECTION--                                                     notifications
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief configuration did change
////////////////////////////////////////////////////////////////////////////////

extern NSString* ArangoConfigurationDidChange;

// -----------------------------------------------------------------------------
// --SECTION--                                              ArangoBaseController
// -----------------------------------------------------------------------------

@interface ArangoManager : NSObject

// -----------------------------------------------------------------------------
// --SECTION--                                                        properties
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief last error message
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong) NSString* lastError;

////////////////////////////////////////////////////////////////////////////////
/// @brief version we are running under
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, assign, readonly) int version;

////////////////////////////////////////////////////////////////////////////////
/// @brief link to the js folder in application support
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSURL* js;

////////////////////////////////////////////////////////////////////////////////
/// @brief name of to ArangoDB binary
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSString* arangoDBVersion;

////////////////////////////////////////////////////////////////////////////////
/// @brief full paths to ArangoDB binary
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSString* arangoDBBinary;

////////////////////////////////////////////////////////////////////////////////
/// @brief paths to ArangoDB configuration
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSString* arangoDBConfig;

////////////////////////////////////////////////////////////////////////////////
/// @brief paths to ArangoDB admin directory
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSString* arangoDBAdminDir;

////////////////////////////////////////////////////////////////////////////////
/// @brief paths to ArangoDB JavaScript action directory
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSString* arangoDBJsActionDir;

////////////////////////////////////////////////////////////////////////////////
/// @brief paths to ArangoDB JavaScript startup directory
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSString* arangoDBJsStartupDir;

////////////////////////////////////////////////////////////////////////////////
/// @brief paths to ArangoDB FOXX apps startup directory
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSString* arangoDBJsAppDir;

////////////////////////////////////////////////////////////////////////////////
/// @brief paths to ArangoDB temporal directory
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSString* arangoDBTempDir;

////////////////////////////////////////////////////////////////////////////////
/// @brief paths to ArangoDB JavaScript module directory
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSString* arangoDBJsModuleDir;

////////////////////////////////////////////////////////////////////////////////
/// @brief paths to ArangoDB JavaScript package directory
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSString* arangoDBJsPackageDir;

////////////////////////////////////////////////////////////////////////////////
/// @brief the context of all objects for permanent storage
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSManagedObjectContext* managedObjectContext;

////////////////////////////////////////////////////////////////////////////////
/// @brief name to configuration mapping
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSMutableDictionary* configurations;

////////////////////////////////////////////////////////////////////////////////
/// @brief user configuration
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) User* user;

////////////////////////////////////////////////////////////////////////////////
/// @brief name to instance mapping
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSMutableDictionary* instances;

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief default constructor
////////////////////////////////////////////////////////////////////////////////

- (ArangoManager*) init;

////////////////////////////////////////////////////////////////////////////////
/// @brief finds a free port
////////////////////////////////////////////////////////////////////////////////

- (NSNumber*) findFreePort;

////////////////////////////////////////////////////////////////////////////////
/// @brief starts up all instances
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startupInstances;

////////////////////////////////////////////////////////////////////////////////
/// @brief creates a new configuration
////////////////////////////////////////////////////////////////////////////////

- (BOOL) createConfiguration: (NSString*) alias
                    withPath: (NSString*) path
                     andPort: (int) port
                      andLog: (NSString*) logPath
                 andLogLevel: (NSString*) logLevel
             andRunOnStartUp: (BOOL) ros;

////////////////////////////////////////////////////////////////////////////////
/// @brief prepares directories
////////////////////////////////////////////////////////////////////////////////

- (ArangoStatus*) prepareConfiguration: (NSString*) alias
                              withPath: (NSString*) path
                               andPort: (int) port
                                andLog: (NSString*) logPath
                           andLogLevel: (NSString*) logLevel;

////////////////////////////////////////////////////////////////////////////////
/// @brief returns current status for all configurations
////////////////////////////////////////////////////////////////////////////////

- (NSArray*) currentStatus;

////////////////////////////////////////////////////////////////////////////////
/// @brief returns current status for a configurations
////////////////////////////////////////////////////////////////////////////////

- (ArangoStatus*) currentStatus: (NSString*) alias;

////////////////////////////////////////////////////////////////////////////////
/// @brief updates a configuration
////////////////////////////////////////////////////////////////////////////////

- (BOOL) updateConfiguration: (NSString*) alias
                    withPath: (NSString*) path
                     andPort: (int) port
                      andLog: (NSString*) logPath
                 andLogLevel: (NSString*) logLevel
             andRunOnStartUp: (BOOL) ros;

////////////////////////////////////////////////////////////////////////////////
/// @brief updates a configuration
////////////////////////////////////////////////////////////////////////////////

- (BOOL) updateConfiguration: (NSString*) alias
               withIsRunning: (BOOL) isRunning;

////////////////////////////////////////////////////////////////////////////////
/// @brief deletes a configuration
////////////////////////////////////////////////////////////////////////////////

- (BOOL) deleteConfiguration: (NSString*) alias;

////////////////////////////////////////////////////////////////////////////////
/// @brief deletes database and log files
////////////////////////////////////////////////////////////////////////////////

- (BOOL) deleteDatabasePath: (NSString*) path
                 andLogFile: (NSString*) logPath;

////////////////////////////////////////////////////////////////////////////////
/// @brief starts a new ArangoDB instance with the given name
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startArangoDB: (NSString*) name;

////////////////////////////////////////////////////////////////////////////////
/// @brief stops an ArangoDB instance
////////////////////////////////////////////////////////////////////////////////

- (BOOL) stopArangoDB: (NSString*) name
              andWait: (BOOL) waitForTermination;

////////////////////////////////////////////////////////////////////////////////
/// @brief runOnStartup options
////////////////////////////////////////////////////////////////////////////////

- (int) runOnStartup;

////////////////////////////////////////////////////////////////////////////////
/// @brief startupOnLogin options
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startupOnLogin;

////////////////////////////////////////////////////////////////////////////////
/// @brief sets startupOnLogin and runOnStartup
////////////////////////////////////////////////////////////////////////////////

- (void) setRunOnStartup: (int) runOnStartup
       setStartupOnLogin: (BOOL) startupOnLogin;

// -----------------------------------------------------------------------------
// --SECTION--                                            User Interface Actions
// -----------------------------------------------------------------------------



@end

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "^\\(/// @brief\\|/// {@inheritDoc}\\|/// @addtogroup\\|/// @page\\|// --SECTION--\\|/// @\\}\\)"
// End:
