////////////////////////////////////////////////////////////////////////////////
/// @brief ArangoDB toolbar menu (controller)
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

#import "ArangoToolbarMenu.h"

#import "ArangoManager.h"
#import "ArangoAppDelegate.h"
#import "ArangoStatus.h"

// -----------------------------------------------------------------------------
// --SECTION--                                                 ArangoToolbarMenu
// -----------------------------------------------------------------------------

@implementation ArangoToolbarMenu

// -----------------------------------------------------------------------------
// --SECTION--                                                   private methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the new instance dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showNewInstanceDialog: (id) sender {
  [_appDelegate showNewInstanceDialog];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the edit instance dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showEditInstanceDialog: (id) sender {
  [_appDelegate showEditInstanceDialog: [sender representedObject]];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the delete instance dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showDeleteInstanceDialog: (id) sender {
  [_appDelegate showDeleteInstanceDialog: [sender representedObject]];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the configuration dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showConfigurationDialog: (id) sender {
  [_appDelegate showConfigurationDialog];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the help dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showHelpDialog: (id) sender {
  [_appDelegate showHelpDialog];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief starts an instance
////////////////////////////////////////////////////////////////////////////////

- (void) startInstance: (id) sender {
  [_appDelegate startInstance: [sender representedObject]];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief stops an instance
////////////////////////////////////////////////////////////////////////////////

- (void) stopInstance: (id) sender {
  [_appDelegate stopInstance: [sender representedObject]];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief opens the administration interface
////////////////////////////////////////////////////////////////////////////////

- (void) openAdminInterface: (id) sender {
  [_appDelegate openAdminInterface: [sender representedObject]];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief quits the application
////////////////////////////////////////////////////////////////////////////////

- (void) quitApplication: (id) sender {
  [[NSApplication sharedApplication] terminate:nil];
}

// -----------------------------------------------------------------------------
// --SECTION--                                      constructors and destructors
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief default constructor
////////////////////////////////////////////////////////////////////////////////

- (id) initWithArangoManager: (ArangoManager*) manager
              andAppDelegate:(ArangoAppDelegate*) delegate {
  self = [super init];

  if (self) {
    _manager = manager;
    _appDelegate = delegate;

    [self updateMenu];
  }

  return self;
}

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief updates the menu entries
////////////////////////////////////////////////////////////////////////////////

- (void) updateMenu {

  // create the menu entries for the instances
  NSArray* entries = [_manager currentStatus];

  [self removeAllItems];
  [self setAutoenablesItems:NO];

  if (entries) {
    for (ArangoStatus* status in entries) {
      NSMenuItem* item = [[NSMenuItem alloc] init];
      [item setEnabled:YES];

      NSString* title;

      if (status.isRunning) {
        title = [NSString stringWithFormat:@"%@ (%d)",status.name,status.port];
      }
      else {
        title = [NSString stringWithFormat:@"%@ (stopped)",status.name];
      }

      [item setTitle: title];

      // create submenu for each instance
      NSMenu* subMenu = [[NSMenu alloc] init];
      [subMenu setAutoenablesItems:NO];

      // open a browser for the GUI
      NSMenuItem* browser = [[NSMenuItem alloc] init];
      [browser setEnabled:status.isRunning];
      [browser setTitle:@"Admin Interface"];
      [browser setTarget:self];
      [browser setRepresentedObject:status.name];
      [browser setAction:@selector(openAdminInterface:)];
      [subMenu addItem:browser];

      [subMenu addItem: [NSMenuItem separatorItem]];

      // edit instance
      NSMenuItem* edit = [[NSMenuItem alloc] init];
      [edit setEnabled:! status.isRunning];
      [edit setTitle:@"Edit"];
      [edit setTarget:self];
      [edit setRepresentedObject:status.name];
      [edit setAction:@selector(showEditInstanceDialog:)];
      [subMenu addItem:edit];

      // delete instance
      NSMenuItem* delete = [[NSMenuItem alloc] init];
      [delete setEnabled:! status.isRunning];
      [delete setTitle:@"Delete"];
      [delete setTarget:self];
      [delete setRepresentedObject:status.name];
      [delete setAction:@selector(showDeleteInstanceDialog:)];
      [subMenu addItem:delete];

      [subMenu addItem: [NSMenuItem separatorItem]];

      // start instance
      NSMenuItem* start = [[NSMenuItem alloc] init];
      [start setEnabled:(! status.isRunning)];
      [start setTitle:@"Start"];
      [start setTarget:self];
      [start setRepresentedObject:status.name];
      [start setAction:@selector(startInstance:)];
      [subMenu addItem:start];

      // stop instance
      NSMenuItem* stop = [[NSMenuItem alloc] init];
      [stop setEnabled:status.isRunning];
      [stop setTitle:@"Stop"];
      [stop setTarget:self];
      [stop setRepresentedObject:status.name];
      [stop setAction:@selector(stopInstance:)];
      [subMenu addItem:stop];

      // add item, submenu and release
      [item setSubmenu:subMenu];

      [self addItem:item];
    }
  }

  // create the standard menu entries
  if (entries && 0 < entries.count) {
    [self addItem:[NSMenuItem separatorItem]];
  }

  // create instance
  NSMenuItem* createDB = [[NSMenuItem alloc] init];
  [createDB setEnabled:YES];
  [createDB setTitle:@"New Instance..."];
  [createDB setTarget:self];
  [createDB setAction:@selector(showNewInstanceDialog:)];
  [self addItem:createDB];

  // configuration
  NSMenuItem* configure = [[NSMenuItem alloc] init];
  [configure setEnabled:YES];
  [configure setTitle:@"Configuration"];
  [configure setTarget:self];
  [configure setAction:@selector(showConfigurationDialog:)];
  [self addItem:configure];

  [self addItem:[NSMenuItem separatorItem]];

  // help
  NSMenuItem* help = [[NSMenuItem alloc] init];
  [help setEnabled:YES];
  [help setTitle:@"Help"];
  [help setTarget:self];
  [help setAction:@selector(showHelpDialog:)];
  [self addItem:help];

  [self addItem:[NSMenuItem separatorItem]];

  // quit
  NSMenuItem* quit = [[NSMenuItem alloc] init];
  [quit setEnabled:YES];
  [quit setTitle:@"Quit"];
  [quit setTarget:self];
  [quit setAction:@selector(quitApplication:)];
  [self addItem:quit];
}

@end

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "/// @brief\\|/// {@inheritDoc}\\|/// @page\\|// --SECTION--\\|/// @\\}"
// End:
