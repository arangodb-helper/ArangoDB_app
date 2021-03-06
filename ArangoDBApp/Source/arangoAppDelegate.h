////////////////////////////////////////////////////////////////////////////////
/// @brief ArangoDB application delegate
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

#import <Cocoa/Cocoa.h>

@class ArangoHelpController;
@class ArangoInstanceController;
@class ArangoIntroductionController;
@class ArangoManager;
@class ArangoReminderController;
@class ArangoToolbarMenu;
@class ArangoUserConfigController;

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

@property (nonatomic, strong, readonly) ArangoToolbarMenu* statusMenu;

////////////////////////////////////////////////////////////////////////////////
/// @brief the icon as well as an access point for the menu
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) NSStatusItem* statusItem;

////////////////////////////////////////////////////////////////////////////////
/// @brief the manager
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong, readonly) ArangoManager* manager;

////////////////////////////////////////////////////////////////////////////////
/// @brief introduction controller
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong) ArangoIntroductionController* introductionController;

////////////////////////////////////////////////////////////////////////////////
/// @brief reminder controller
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong) ArangoReminderController* reminderController;

////////////////////////////////////////////////////////////////////////////////
/// @brief instance controller
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong) ArangoInstanceController* instanceController;

////////////////////////////////////////////////////////////////////////////////
/// @brief configuration controller
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong) ArangoUserConfigController* configController;

////////////////////////////////////////////////////////////////////////////////
/// @brief help controller
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong) ArangoHelpController* helpController;

////////////////////////////////////////////////////////////////////////////////
/// @brief edit controllers
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, strong) NSMutableDictionary* editControllers;

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the introduction dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showIntroductionDialog;

////////////////////////////////////////////////////////////////////////////////
/// @brief clears the introduction dialog
////////////////////////////////////////////////////////////////////////////////

- (void) clearIntroductionDialog;

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the reminder dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showReminderDialog;

////////////////////////////////////////////////////////////////////////////////
/// @brief clears the reminder dialog
////////////////////////////////////////////////////////////////////////////////

- (void) clearReminderDialog;

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the new instance dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showNewInstanceDialog;

////////////////////////////////////////////////////////////////////////////////
/// @brief clears the new instance dialog
////////////////////////////////////////////////////////////////////////////////

- (void) clearNewInstanceDialog;

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the configuration dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showConfigurationDialog;

////////////////////////////////////////////////////////////////////////////////
/// @brief clears the configuration dialog
////////////////////////////////////////////////////////////////////////////////

- (void) clearConfigurationDialog;

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the help dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showHelpDialog;

////////////////////////////////////////////////////////////////////////////////
/// @brief clears the help dialog
////////////////////////////////////////////////////////////////////////////////

- (void) clearHelpDialog;

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the edit instance dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showEditInstanceDialog: (NSString*) config;

////////////////////////////////////////////////////////////////////////////////
/// @brief clears the edit instance dialog
////////////////////////////////////////////////////////////////////////////////

- (void) clearEditInstanceDialog: (NSString*) config;

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the delete instance dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showDeleteInstanceDialog: (NSString*) config;

////////////////////////////////////////////////////////////////////////////////
/// @brief starts an instance
////////////////////////////////////////////////////////////////////////////////

- (void) startInstance: (NSString*) config;

////////////////////////////////////////////////////////////////////////////////
/// @brief stops an instance
////////////////////////////////////////////////////////////////////////////////

- (void) stopInstance: (NSString*) config;

////////////////////////////////////////////////////////////////////////////////
/// @brief opens the administration interface
////////////////////////////////////////////////////////////////////////////////

- (void) openAdminInterface: (NSString*) config;

@end

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "/// @brief\\|/// {@inheritDoc}\\|/// @page\\|// --SECTION--\\|/// @\\}"
// End:
