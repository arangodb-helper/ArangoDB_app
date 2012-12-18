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
#import "ArangoNewInstanceController.h"

// -----------------------------------------------------------------------------
// --SECTION--                                                 ArangoToolbarMenu
// -----------------------------------------------------------------------------

@implementation ArangoToolbarMenu

// -----------------------------------------------------------------------------
// --SECTION--                                                   private methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief updates the menu entries
////////////////////////////////////////////////////////////////////////////////

- (void) updateMenu {

  // create the menu entries for the instances
  NSArray* entries = [self.delegate currentStatus];

  [self removeAllItems];
  [self setAutoenablesItems:NO];
  
  if (entries) {
    for (ArangoStatus* status in entries) {
      NSMenuItem* item = [[NSMenuItem alloc] init];
      [item setEnabled:YES];

      NSString* title = status.name;

      if (status.isRunning) {
        title = [[[title stringByAppendingString:@" ("] stringByAppendingString:[status.port stringValue]] stringByAppendingString:@")"];
      }
      else {
        title = [title stringByAppendingString:@" (Stopped)"];
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
      [browser release];

      [subMenu addItem: [NSMenuItem separatorItem]];

      // edit instance
      NSMenuItem* edit = [[NSMenuItem alloc] init];
      [edit setEnabled:YES];
      [edit setTitle:@"Edit"];
      [edit setTarget:self];
      [edit setRepresentedObject:status.name];
      [edit setAction:@selector(editInstance:)];
      [subMenu addItem:edit];
      [edit release];

      // delete instance
      NSMenuItem* delete = [[NSMenuItem alloc] init];
      [delete setEnabled:YES];
      [delete setTitle:@"Delete"];
      [delete setTarget:self];
      [delete setRepresentedObject:status.name];
      [delete setAction:@selector(deleteInstance:)];
      [subMenu addItem:delete];
      [delete release];

      [subMenu addItem: [NSMenuItem separatorItem]];

      // start instance
      NSMenuItem* start = [[NSMenuItem alloc] init];
      [start setEnabled:(! status.isRunning)];
      [start setTitle:@"Start"];
      [start setTarget:self];
      [start setRepresentedObject:status.name];
      [start setAction:@selector(startInstance:)];
      [subMenu addItem:start];
      [start release];

      // stop instance
      NSMenuItem* stop = [[NSMenuItem alloc] init];
      [stop setEnabled:status.isRunning];
      [stop setTitle:@"Stop"];
      [stop setTarget:self];
      [stop setRepresentedObject:status.name];
      [stop setAction:@selector(stopInstance:)];
      [subMenu addItem:stop];
      [stop release];

      // add item, submenu and release
      [item setSubmenu:subMenu];
      [subMenu release];
      
      [self addItem:item];
      [item release];
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
  [createDB release];
    
  // configuration
  NSMenuItem* configure = [[NSMenuItem alloc] init];
  [configure setEnabled:YES];
  [configure setTitle:@"Configuration"];
  [configure setTarget:self];
  [configure setAction:@selector(showConfiguration:)];
  [self addItem:configure];
  [configure release];
  
  [self addItem:[NSMenuItem separatorItem]];
  
  // help
  NSMenuItem* help = [[NSMenuItem alloc] init];
  [help setEnabled:YES];
  [help setTitle:@"Help"];
  [help setTarget:self];
  [help setAction:@selector(showHelp:)];
  [self addItem:help];
  [help release];
  
  [self addItem:[NSMenuItem separatorItem]];
  
  // quit
  NSMenuItem* quit = [[NSMenuItem alloc] init];
  [quit setEnabled:YES];
  [quit setTitle:@"Quit"];
  [quit setTarget:self];
  [quit setAction:@selector(quitApplication:)];
  [self addItem:quit];
  [quit release];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief creates an instance
////////////////////////////////////////////////////////////////////////////////

- (void) createNewInstance: (id) sender {
  [[ArangoNewInstanceController alloc] initWithArangoManager:self.delegate];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief updates an instance
////////////////////////////////////////////////////////////////////////////////

- (void) editInstance: (id) sender {
  ArangoConfiguration* config = [self.delegate configuration:[sender representedObject]];

  if (config == nil) {
    return;
  }

  [[ArangoNewInstanceController alloc] initWithArangoManager:self.delegate
                                            andConfiguration:config];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief deletes an instance
////////////////////////////////////////////////////////////////////////////////

- (void) deleteInstance: (id) sender {
  NSString* config = [sender representedObject];
  ArangoStatus* status = [self.delegate currentStatus:config];

  // already deleted
  if (status == nil) {
    return;
  }

  // ask use if he wants the database files to be removed
  NSMutableString* infoText = [[NSMutableString alloc] init];
  [infoText setString:@"Do you want to delete the contents of folder \""];
  [infoText appendString:status.path];
  [infoText appendString:@"\" and the log-file as well?"];

  NSAlert* info = [NSAlert alertWithMessageText:@"Delete Data?" defaultButton:@"Keep Data" alternateButton:@"Abort" otherButton:@"Delete Data" informativeTextWithFormat:@"%@",infoText];

  [infoText release];
  [info beginSheetModalForWindow:nil modalDelegate:self didEndSelector:@selector(confirmedDeleteInstance:returnCode:contextInfo:) contextInfo:config];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief confirms or rejects 
////////////////////////////////////////////////////////////////////////////////

- (void) confirmedDeleteInstance: (NSAlert*) dialog
                      returnCode: (int) rc 
                     contextInfo: (NSString*) config
{
  ArangoStatus* status = [self.delegate currentStatus:config];

  // already deleted
  if (status == nil) {
    return;
  }

  if (rc == -1 || rc == 1) {
    [self.delegate deleteConfiguration:config];
  }
  else {
    return;
  }

  if (rc == -1) {
    [self.delegate stopArangoDBAndDelete:status];
  }
  else {
    [self.delegate stopArangoDB:config];
  }  
}

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the configuration dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showConfiguration: (id) sender {
  if (self.userConfigController) {
    [NSApp activateIgnoringOtherApps:YES];

    [self.userConfigController.window makeKeyAndOrderFront:self];
    [self.userConfigController showWindow:self.userConfigController.window];
  }
  else {
    self.userConfigController = [[[ArangoUserConfigController alloc] initWithArangoManager:self.delegate] autorelease];
  }
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
    self.helpController = [[[ArangoHelpController alloc] initWithArangoManager:self.delegate andNibNamed:@"ArangoHelpView"] autorelease];
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief starts an instance
////////////////////////////////////////////////////////////////////////////////

- (void) startInstance: (id) sender {
  NSString* config = [sender representedObject];
  ArangoStatus* status = [self.delegate currentStatus:config];

  // already deleted
  if (status == nil) {
    return;
  }

  // start the instance
  [self.delegate startArangoDB:config];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief stops an instance
////////////////////////////////////////////////////////////////////////////////

- (void) stopInstance: (id) sender {
  NSString* config = [sender representedObject];
  ArangoStatus* status = [self.delegate currentStatus:config];

  // already deleted
  if (status == nil) {
    return;
  }

  // start the instance
  [self.delegate stopArangoDB:config];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief quits the application
////////////////////////////////////////////////////////////////////////////////

- (void) openBrowser: (id) sender {
  NSString* config = [sender representedObject];
  ArangoStatus* status = [self.delegate currentStatus:config];

  // already deleted
  if (status == nil) {
    return;
  }

  NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
  [f setThousandSeparator:@""];
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[@"http://localhost:" stringByAppendingString:[f stringFromNumber:status.port]]]];
  [f release];
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

- (id) initWithArangoManager: (ArangoManager*) delegate {
  self = [super init];

  if (self) {
    _delegate = delegate;
    _helpController = nil;
    _userConfigController = nil;

    [self updateMenu];
  }

  return self;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief destructor
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
  self.helpController = nil;
  self.userConfigController = nil;

  [super dealloc];
}

@end

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "^\\(/// @brief\\|/// {@inheritDoc}\\|/// @addtogroup\\|/// @page\\|// --SECTION--\\|/// @\\}\\)"
// End:
