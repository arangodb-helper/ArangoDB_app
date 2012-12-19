////////////////////////////////////////////////////////////////////////////////
/// @brief ArangoDB application delegate
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

#import <Cocoa/Cocoa.h>

@class ArangoToolbarMenu;
@class ArangoManager;

// -----------------------------------------------------------------------------
// --SECTION--                                                 ArangoAppDelegate
// -----------------------------------------------------------------------------

@interface ArangoAppDelegate : NSObject <NSApplicationDelegate>

// -----------------------------------------------------------------------------
// --SECTION--                                                        properties
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief the underlying menu of the status-bar icon
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, assign, readonly) ArangoToolbarMenu* statusMenu;

////////////////////////////////////////////////////////////////////////////////
/// @brief the icon as well as an accesspoint for the menu
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, assign, readonly) NSStatusItem * statusItem;

////////////////////////////////////////////////////////////////////////////////
/// @brief the manager (model)
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, assign, readonly) ArangoManager* manager;

@end

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "^\\(/// @brief\\|/// {@inheritDoc}\\|/// @addtogroup\\|/// @page\\|// --SECTION--\\|/// @\\}\\)"
// End:
