////////////////////////////////////////////////////////////////////////////////
/// @brief status information about ArangoDB instance / configuration
///
/// @file
///
/// DISCLAIMER
///
/// Copyright 2014 ArangoDB GmbH, Cologne, Germany
/// Copyright 2004-2014 triAGENS GmbH, Cologne, Germany
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
/// Copyright holder is ArangoDB GmbH, Cologne, Germany
///
/// @author Dr. Frank Celler
/// @author Michael Hackstein
/// @author Copyright 2014, ArangoDB GmbH, Cologne, Germany
/// @author Copyright 2012, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

#import "ArangoStatus.h"

// -----------------------------------------------------------------------------
// --SECTION--                                              ArangoBaseController
// -----------------------------------------------------------------------------

@implementation ArangoStatus

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
                    andRunning: (BOOL) isRunning {
  self = [super init];

  if (self) {
    _name = [name copy];
    _port = port;
    _path = [path copy];
    _logPath = [logPath copy];
    _logLevel = [logLevel copy];
    _runOnStartup = runOnStartUp;
    _isRunning = isRunning;
  }

  return self;
}

@end

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "/// @brief\\|/// {@inheritDoc}\\|/// @page\\|// --SECTION--\\|/// @\\}"
// End:
