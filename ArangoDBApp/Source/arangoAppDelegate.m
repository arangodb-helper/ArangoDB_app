////////////////////////////////////////////////////////////////////////////////
/// @brief ArangoDB application delegate
///
/// @file
///
/// DISCLAIMER
///
/// Copyright 2014 ArangoDB GmbH, Cologne, Germany
/// Copyright 2012-2014 triAGENS GmbH, Cologne, Germany
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
/// @author Copyright 2012-2014, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

#import "ArangoAppDelegate.h"

#import "ArangoInstanceController.h"
#import "ArangoIntroductionController.h"
#import "ArangoReminderController.h"
#import "ArangoManager.h"
#import "ArangoStatus.h"
#import "ArangoToolbarMenu.h"
#import "ArangoUserConfigController.h"

// -----------------------------------------------------------------------------
// --SECTION--                                                 ArangoAppDelegate
// -----------------------------------------------------------------------------

@implementation ArangoAppDelegate

// -----------------------------------------------------------------------------
// --SECTION--                                                   private methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief callback for configuration changed notification
////////////////////////////////////////////////////////////////////////////////

- (void) configurationDidChange: (NSNotification*) notification {
  [_statusMenu updateMenu];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief handles singleton dialogs
////////////////////////////////////////////////////////////////////////////////

- (void) showSingletonDialog: (NSString*) dialog withConstructor: (id (^)(void)) callback {
  ArangoBaseController* controller = [self valueForKey:dialog];

  if (controller != nil) {
    [controller.window makeKeyAndOrderFront:self];
    [controller showWindow:controller.window];
  }
  else {
    controller = callback();
    [self setValue:controller forKey:dialog];
  }

  [NSApp activateIgnoringOtherApps:YES];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief deletes an instance
////////////////////////////////////////////////////////////////////////////////

- (void) deleteInstance: (NSString*) config andDeleteData: (BOOL) deleteData {
  ArangoStatus* status = [_manager currentStatus:config];

  // already deleted
  if (status == nil) {
    return;
  }

  BOOL ok = [_manager deleteConfiguration:config];

  if (! ok) {
    NSAlert* info = [[NSAlert alloc] init];

    [info setMessageText:@"Cannot delete ArangoDB instance!"];
    [info setInformativeText:[NSString stringWithFormat:@"Encountered error: \"%@\", please correct and try again.",
                                                        _manager.lastError]];

    [info runModal];
    return;
  }

  [_manager stopArangoDB:config andWait:YES];

  if (deleteData) {
    [_manager deleteDatabasePath:status.path
                      andLogFile:status.logPath];
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief deletes an instance
////////////////////////////////////////////////////////////////////////////////

- (void) deleteInstanceAnswer: (NSAlert*) dialog
                   returnCode: (int) returnCode
                  contextInfo: (NSString*) config {
  if (returnCode == NSAlertThirdButtonReturn) {
    return;
  }

  [self deleteInstance: config andDeleteData: (returnCode == NSAlertSecondButtonReturn)];
}

// -----------------------------------------------------------------------------
// --SECTION--                                      constructors and destructors
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief creates the status menu item with icon
////////////////////////////////////////////////////////////////////////////////

- (void) awakeFromNib {
  _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];

  [_statusItem setImage:[NSImage imageNamed:@"IconColor"]];
  [_statusItem setHighlightMode:YES];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief destructor
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief called after application has been launched
////////////////////////////////////////////////////////////////////////////////

- (void) applicationDidFinishLaunching: (NSNotification *) notification {

  // create the ArangoDB manager
  _manager = [[ArangoManager alloc] init];

  if (_manager == nil) {
    NSAlert* info = [[NSAlert alloc] init];

    [info setMessageText:@"ArangoDB application failed to start!"];
    [info setInformativeText:@"Cannot create or load the configuration. Please reinstall the application."];

    [info runModal];
    [[NSApplication sharedApplication] terminate:nil];

    return;
  }

  // create a please for the controllers
  _editControllers = [[NSMutableDictionary alloc] init];

  // check for changes in the configuration
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(configurationDidChange:)
                                               name:ArangoConfigurationDidChange
                                             object:_manager];

  // create the menu
  _statusMenu = [[ArangoToolbarMenu alloc] initWithArangoManager:_manager
                                                  andAppDelegate:self];
  [_statusItem setMenu: _statusMenu];
  [_statusMenu setAutoenablesItems: NO];

  // we will have missed the first notification
  [_statusMenu updateMenu];

  // without any configuration, display some help
  if (0 == _manager.configurations.count) {
    [_manager setShowTooltip: YES];
    [self showIntroductionDialog];
  }
  else if ([_manager showTooltip]) {
    [self showReminderDialog];
  }
  else {
    [_manager startupInstances];
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the introduction dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showIntroductionDialog {
  [self showSingletonDialog: @"introductionController" withConstructor: ^id (void) {
    return [[ArangoIntroductionController alloc] initWithArangoManager:_manager
                                                        andAppDelegate:self];
  }];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief clears the introduction dialog
////////////////////////////////////////////////////////////////////////////////

- (void) clearIntroductionDialog {
  _introductionController = nil;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the reminder dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showReminderDialog {
  [self showSingletonDialog: @"reminderController" withConstructor: ^id (void) {
    return [[ArangoReminderController alloc] initWithArangoManager:_manager
                                                    andAppDelegate:self];
  }];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief clears the reminder dialog
////////////////////////////////////////////////////////////////////////////////

- (void) clearReminderDialog {
  _reminderController = nil;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the new instance dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showNewInstanceDialog {
  [self showSingletonDialog: @"instanceController" withConstructor: ^id (void) {
      return [[ArangoInstanceController alloc] initWithArangoManager:_manager
                                                      andAppDelegate:self];
    }];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief clears the new instance dialog
////////////////////////////////////////////////////////////////////////////////

- (void) clearNewInstanceDialog {
  _instanceController = nil;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the configuration dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showConfigurationDialog {
  [self showSingletonDialog: @"configController" withConstructor: ^(void) {
      return [[ArangoUserConfigController alloc] initWithArangoManager:_manager
                                                        andAppDelegate:self];
    }];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief clears the configuration dialog
////////////////////////////////////////////////////////////////////////////////

- (void) clearConfigurationDialog {
  _configController = nil;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief show the help dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showHelpDialog {
  [self showSingletonDialog: @"helpController" withConstructor: ^(void) {
      return [[ArangoHelpController alloc] initWithArangoManager:_manager
                                                  andAppDelegate:self];
    }];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief clears the help dialog
////////////////////////////////////////////////////////////////////////////////

- (void) clearHelpDialog {
  _helpController = nil;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the edit instance dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showEditInstanceDialog: (NSString*) config {
  ArangoStatus* status = [_manager currentStatus:config];

  if (status == nil) {
    return;
  }

  ArangoBaseController* controller = [_editControllers objectForKey:config];

  if (controller != nil) {
    [controller.window makeKeyAndOrderFront:self];
    [controller showWindow:controller.window];
  }
  else {
    controller =   [[ArangoInstanceController alloc] initWithArangoManager:_manager
                                                            andAppDelegate:self
                                                             andConfigName:config
                                                                 andStatus:status];

    [_editControllers setObject:controller forKey:config];
  }

  [NSApp activateIgnoringOtherApps:YES];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief clears the edit instance dialog
////////////////////////////////////////////////////////////////////////////////

- (void) clearEditInstanceDialog: (NSString*) config {
  [_editControllers removeObjectForKey:config];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the delete instance dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showDeleteInstanceDialog: (NSString*) config {
  ArangoStatus* status = [_manager currentStatus:config];

  // already deleted
  if (status == nil) {
    return;
  }

  if (status.isRunning) {
    NSAlert* info = [[NSAlert alloc] init];

    [info setMessageText:@"ArangoDB instance must be stopped!"];
    [info setInformativeText:@"The ArangoDB instance must be stopped before deleting it."];

    [info runModal];
    return;
  }

  // ask user if s/he wants the database files to be removed
  NSAlert* info = [[NSAlert alloc] init];

  [info setMessageText:@"Delete ArangoDB instance data!"];
  [info setInformativeText:[NSString stringWithFormat:@"Do you want to delete the contents of folder \"%@\" and the log-file as well?",status.path]];
  [info addButtonWithTitle:@"Keep Data"];
  [info addButtonWithTitle:@"Delete Data"];
  [info addButtonWithTitle:@"Cancel"];

  [info beginSheetModalForWindow:nil
                   modalDelegate:self
                  didEndSelector:@selector(deleteInstanceAnswer:returnCode:contextInfo:)
                     contextInfo:(__bridge void *)(config)];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief starts an instance
////////////////////////////////////////////////////////////////////////////////

- (void) startInstance: (NSString*) config {
  ArangoStatus* status = [_manager currentStatus:config];

  // already deleted
  if (status == nil) {
    return;
  }

  // start the instance
  BOOL ok = [_manager startArangoDB:config];

  if (ok) {
    [_manager updateConfiguration:config withIsRunning:YES];
  }
  else {
    NSAlert* info = [[NSAlert alloc] init];

    [info setMessageText:@"Cannot start ArangoDB instance!"];
    [info setInformativeText:
            [NSString 
              stringWithFormat:@"Encountered error: %@, please correct and try again.",_manager.lastError]];

    [info runModal];
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief stops an instance
////////////////////////////////////////////////////////////////////////////////

- (void) stopInstance: (NSString*) config {
  ArangoStatus* status = [_manager currentStatus:config];

  // already deleted
  if (status == nil) {
    return;
  }

  // start the instance
  [_manager stopArangoDB:config andWait:NO];
  [_manager updateConfiguration:config withIsRunning:NO];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief opens a browser window to the administration interface
////////////////////////////////////////////////////////////////////////////////

- (void) openAdminInterface: (NSString*) config {
  ArangoStatus* status = [_manager currentStatus:config];

  // already deleted
  if (status == nil) {
    return;
  }

  NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
  [f setThousandSeparator:@""];
  [[NSWorkspace sharedWorkspace]
    openURL:[NSURL 
              URLWithString:[NSString 
                              stringWithFormat:@"http://localhost:%d/_admin/html/index.html",status.port]]];
}

@end

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "/// @brief\\|/// {@inheritDoc}\\|/// @page\\|// --SECTION--\\|/// @\\}"
// End:
