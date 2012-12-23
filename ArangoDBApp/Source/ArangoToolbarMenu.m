////////////////////////////////////////////////////////////////////////////////
/// @brief ArangoDB toolbar menu (controller)
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

#import "ArangoToolbarMenu.h"

#import "ArangoHelpController.h"
#import "ArangoManager.h"
#import "ArangoStatus.h"
#import "ArangoUserConfigController.h"
#import "arangoAppDelegate.h"
#import "ArangoInstanceController.h"

// -----------------------------------------------------------------------------
// --SECTION--                                                 ArangoToolbarMenu
// -----------------------------------------------------------------------------

@implementation ArangoToolbarMenu

// -----------------------------------------------------------------------------
// --SECTION--                                                   private methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief creates an instance
////////////////////////////////////////////////////////////////////////////////

- (void) createNewInstance: (id) sender {
  // will autorelease on close
  [self.delegate addController:[[ArangoInstanceController alloc] initWithArangoManager:self.manager
                                                                        andAppDelegate:self.delegate]];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief updates an instance
////////////////////////////////////////////////////////////////////////////////

- (void) editInstance: (id) sender {
  ArangoStatus* status = [self.manager currentStatus:[sender representedObject]];

  if (status == nil) {
    return;
  }

  // will autorelease on close
  [self.delegate addController:[[ArangoInstanceController alloc] initWithArangoManager:self.manager
                                                                        andAppDelegate:self.delegate
                                                                             andStatus:status]];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief ignores confirmed errors
////////////////////////////////////////////////////////////////////////////////

- (void) stopAlertDidEnd: (NSAlert*) alert
              returnCode: (NSInteger) returnCode
             contextInfo: (void*) contextInfo {
}

////////////////////////////////////////////////////////////////////////////////
/// @brief confirms or rejects 
////////////////////////////////////////////////////////////////////////////////

- (void) confirmedDeleteInstance: (NSAlert*) dialog
                      returnCode: (int) returnCode
                     contextInfo: (NSString*) config
{
  ArangoStatus* status = [self.manager currentStatus:config];

  // already deleted
  if (status == nil) {
    return;
  }

  if (returnCode == NSAlertThirdButtonReturn) {
    return;
  }

  BOOL ok = [self.manager deleteConfiguration:config];

  if (! ok) {
    NSAlert* info = [[NSAlert alloc] init];
      
    [info setMessageText:@"Cannot delete ArangoDB instance!"];
    [info setInformativeText:[NSString stringWithFormat:@"Encountered error: \"%@\", please correct and try again.",self.manager.lastError]];

    [info runModal];
    return;
  }

  [self.manager stopArangoDB:config andWait:YES];

  if (returnCode == NSAlertSecondButtonReturn) {
    [self.manager deleteDatabasePath:status.path
                           andLogFile:status.logPath];
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief deletes an instance
////////////////////////////////////////////////////////////////////////////////

- (void) deleteInstance: (id) sender {
  NSString* config = [sender representedObject];
  ArangoStatus* status = [self.manager currentStatus:config];

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
                  didEndSelector:@selector(confirmedDeleteInstance:returnCode:contextInfo:)
                     contextInfo:(__bridge void *)(config)];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the configuration dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showConfiguration: (id) sender {
  // will autorelease on close
  [self.delegate addController:[[ArangoUserConfigController alloc] initWithArangoManager:self.manager
                                                                          andAppDelegate:self.delegate]];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the help dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showHelp: (id) sender {
  if (self.helpController) {
    [NSApp activateIgnoringOtherApps:YES];

    [self.helpController.window makeKeyAndOrderFront:self];
    [self.helpController showWindow:self.helpController.window];
  }
  else {
    self.helpController = [[ArangoHelpController alloc] initWithArangoManager:self.manager
                                                               andAppDelegate:self.delegate
                                                                    andNibNamed:@"ArangoHelpView"];
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief starts an instance
////////////////////////////////////////////////////////////////////////////////

- (void) startInstance: (id) sender {
  NSString* config = [sender representedObject];
  ArangoStatus* status = [self.manager currentStatus:config];

  // already deleted
  if (status == nil) {
    return;
  }

  // start the instance
  BOOL ok = [self.manager startArangoDB:config];

  if (ok) {
    [self.manager updateConfiguration:config withIsRunning:YES];
  }
  else {
    NSAlert* info = [[NSAlert alloc] init];
      
    [info setMessageText:@"Cannot start ArangoDB instance!"];
    [info setInformativeText:[NSString stringWithFormat:@"Encountered error: %@, please correct and try again.",self.manager.lastError]];

    [info runModal];
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief stops an instance
////////////////////////////////////////////////////////////////////////////////

- (void) stopInstance: (id) sender {
  NSString* config = [sender representedObject];
  ArangoStatus* status = [self.manager currentStatus:config];

  // already deleted
  if (status == nil) {
    return;
  }

  // start the instance
  [self.manager stopArangoDB:config andWait:NO];
  [self.manager updateConfiguration:config withIsRunning:NO];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief quits the application
////////////////////////////////////////////////////////////////////////////////

- (void) openBrowser: (id) sender {
  NSString* config = [sender representedObject];
  ArangoStatus* status = [self.manager currentStatus:config];

  // already deleted
  if (status == nil) {
    return;
  }

  NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
  [f setThousandSeparator:@""];
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%d/_admin/html/index.html",status.port]]];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief quits the application
////////////////////////////////////////////////////////////////////////////////

- (void) quitApplication: (id) sender {
  [[NSApplication sharedApplication] terminate:nil];
}

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief default constructor
////////////////////////////////////////////////////////////////////////////////

- (id) initWithArangoManager: (ArangoManager*) manager
              andAppDelegate:(ArangoAppDelegate*) delegate {
  self = [super init];

  if (self) {
    _manager = manager;
    _delegate = delegate;
    _helpController = nil;

    [self updateMenu];
  }

  return self;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief updates the menu entries
////////////////////////////////////////////////////////////////////////////////

- (void) updateMenu {
  
  // create the menu entries for the instances
  NSArray* entries = [self.manager currentStatus];
  
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
      [browser setAction:@selector(openBrowser:)];
      [subMenu addItem:browser];
      
      [subMenu addItem: [NSMenuItem separatorItem]];
      
      // edit instance
      NSMenuItem* edit = [[NSMenuItem alloc] init];
      [edit setEnabled:! status.isRunning];
      [edit setTitle:@"Edit"];
      [edit setTarget:self];
      [edit setRepresentedObject:status.name];
      [edit setAction:@selector(editInstance:)];
      [subMenu addItem:edit];
      
      // delete instance
      NSMenuItem* delete = [[NSMenuItem alloc] init];
      [delete setEnabled:! status.isRunning];
      [delete setTitle:@"Delete"];
      [delete setTarget:self];
      [delete setRepresentedObject:status.name];
      [delete setAction:@selector(deleteInstance:)];
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
  [createDB setAction:@selector(createNewInstance:)];
  [self addItem:createDB];
  
  // configuration
  NSMenuItem* configure = [[NSMenuItem alloc] init];
  [configure setEnabled:YES];
  [configure setTitle:@"Configuration"];
  [configure setTarget:self];
  [configure setAction:@selector(showConfiguration:)];
  [self addItem:configure];
  
  [self addItem:[NSMenuItem separatorItem]];
  
  // help
  NSMenuItem* help = [[NSMenuItem alloc] init];
  [help setEnabled:YES];
  [help setTitle:@"Help"];
  [help setTarget:self];
  [help setAction:@selector(showHelp:)];
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
// outline-regexp: "^\\(/// @brief\\|/// {@inheritDoc}\\|/// @addtogroup\\|/// @page\\|// --SECTION--\\|/// @\\}\\)"
// End:
