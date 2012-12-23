////////////////////////////////////////////////////////////////////////////////
/// @brief status information about ArangoDB instance / configuration
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
/// @author Copyright 2012, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

@class User;

// -----------------------------------------------------------------------------
// --SECTION--                                              ArangoBaseController
// -----------------------------------------------------------------------------

@interface ArangoStatus : NSObject

// -----------------------------------------------------------------------------
// --SECTION--                                                        properties
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief name of the configuration
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSString* name;

////////////////////////////////////////////////////////////////////////////////
/// @brief port to listen to
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, assign, readonly) int port;

////////////////////////////////////////////////////////////////////////////////
/// @brief path of database files
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSString* path;

////////////////////////////////////////////////////////////////////////////////
/// @brief path of log file
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSString* logPath;

////////////////////////////////////////////////////////////////////////////////
/// @brief path of log level
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSString* logLevel;

////////////////////////////////////////////////////////////////////////////////
/// @brief run-on-startup
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, assign, readonly) BOOL runOnStartup;

////////////////////////////////////////////////////////////////////////////////
/// @brief is running
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, assign, readonly) BOOL isRunning;

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief default constructor
////////////////////////////////////////////////////////////////////////////////

- (ArangoStatus*) initWithName: (NSString*) name
                       andPath: (NSString*) path
                       andPort: (int) port
                    andLogPath: (NSString*) logPath
                   andLogLevel: (NSString*) logLevel
               andRunOnStartup: (BOOL) runOnStartUp
                    andRunning: (BOOL) isRunning;

@end

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "^\\(/// @brief\\|/// {@inheritDoc}\\|/// @addtogroup\\|/// @page\\|// --SECTION--\\|/// @\\}\\)"
// End:
