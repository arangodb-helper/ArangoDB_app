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

#import "ArangoConfiguration.h"
#import "ArangoHelpController.h"
#import "ArangoManager.h"
#import "ArangoStatus.h"
#import "arangoAppDelegate.h"
#import "arangoCreateNewDBWindowController.h"
#import "ArangoUserConfigController.h"

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
  NSArray* entries = [self.delegate.manager currentStatus];

  [self removeAllItems];
  
  if (entries) {
    for (ArangoStatus* status in entries) {
      NSMenuItem* item = [[NSMenuItem alloc] init];
      [item setEnabled:YES];

      NSString* title = status.name;

      if (status.isRunning) {
        title = [title stringByAppendingString:@" (Running)"];
      }
      else {
        title = [title stringByAppendingString:@" (Stopped)"];
      }

      [item setTitle: title];

      [item setTarget:self];
      [item setRepresentedObject:status.name];
      [item setAction:@selector(toggleArango:)];
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
  [createDB setAction:@selector(createNewInstance)];
  [self addItem:createDB];
  [createDB release];
    
  // configuration
  NSMenuItem* configure = [[NSMenuItem alloc] init];
  [configure setEnabled:YES];
  [configure setTitle:@"Configuration"];
  [configure setTarget:self];
  [configure setAction:@selector(showConfiguration)];
  [self addItem:configure];
  [configure release];
  
  [self addItem:[NSMenuItem separatorItem]];
  
  // help
  NSMenuItem* help = [[NSMenuItem alloc] init];
  [help setEnabled:YES];
  [help setTitle:@"Help"];
  [help setTarget:self];
  [help setAction:@selector(showHelp)];
  [self addItem:help];
  [help release];
  
  [self addItem:[NSMenuItem separatorItem]];
  
  // quit
  NSMenuItem* quit = [[NSMenuItem alloc] init];
  [quit setEnabled:YES];
  [quit setTitle:@"Quit"];
  [quit setTarget:self];
  [quit setAction:@selector(quitApplication)];
  [self addItem:quit];
  [quit release];
}

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief default constructor
////////////////////////////////////////////////////////////////////////////////

- (id) initWithAppDelegate: (arangoAppDelegate*) delegate {
  self = [super init];

  if (self) {
    _delegate = delegate;
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

////////////////////////////////////////////////////////////////////////////////
/// @brief show the help dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showConfiguration {
  if (self.userConfigController) {
    [NSApp activateIgnoringOtherApps:YES];

    [self.userConfigController.window makeKeyAndOrderFront:self];
    [self.userConfigController showWindow:self.userConfigController.window];
  }
  else {
    self.userConfigController = [[[ArangoUserConfigController alloc] initWithAppDelegate:self.delegate] autorelease];
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief show the help dialog
////////////////////////////////////////////////////////////////////////////////

- (void) showHelp {

  if (self.helpController) {
    [NSApp activateIgnoringOtherApps:YES];

    [self.helpController.window makeKeyAndOrderFront:self];
    [self.helpController showWindow:self.helpController.window];
  }
  else {
    self.helpController = [[[ArangoHelpController alloc] initWithAppDelegate:self.delegate andNibNamed:@"ArangoHelpView"] autorelease];
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief quites the application
////////////////////////////////////////////////////////////////////////////////

- (void) quitApplication {
  [[NSApplication sharedApplication] terminate:nil];
}

/*
- (void) updateMenu
{



  // Request stored Arangos
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"ArangoConfiguration" inManagedObjectContext: [self.appDelegate getArangoManagedObjectContext]];
  [request setEntity:entity];
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"alias" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
  NSError *error = nil;
  NSArray *fetchedResults = [[self.appDelegate getArangoManagedObjectContext] executeFetchRequest:request error:&error];
  [request release];
  if (fetchedResults == nil) {
    NSLog(@"%@", error.localizedDescription);
  } else {
    for (ArangoConfiguration* c in fetchedResults) {
      
      NSMenuItem* item = [[NSMenuItem alloc] init];
      [item setEnabled:YES];
      NSString* itemTitle = @"%a (%p)";
      itemTitle = [[itemTitle stringByReplacingOccurrencesOfString:@"%a" withString:c.alias] stringByReplacingOccurrencesOfString:@"%p" withString:[NSString stringWithFormat:@"%i",[c.port intValue]]];
      [item setTitle: itemTitle];
      if ([c.isRunning isEqualToNumber: [NSNumber numberWithBool:YES]]) {
        [item setState:1];
      } else {
        [item setState:0];
      }
      [item setTarget:self];
      [item setRepresentedObject:c];
      [item setAction:@selector(toggleArango:)];
      [self addItem:item];
      [item release];
      NSMenu* subMenu = [[NSMenu alloc] init];
      NSMenuItem* browser = [[NSMenuItem alloc] init];
      [browser setTitle:@"Browser"];
      [browser setTarget:self];
      [browser setRepresentedObject:c];
      [browser setAction:@selector(openBrowser:)];
      [subMenu addItem:browser];
      [browser release];
      [subMenu addItem: [NSMenuItem separatorItem]];
      NSMenuItem* edit = [[NSMenuItem alloc] init];
      [edit setTitle:@"Edit"];
      [edit setTarget:self];
      [edit setRepresentedObject:c];
      [edit setAction:@selector(editInstance:)];
      [subMenu addItem:edit];
      [edit release];
      NSMenuItem* delete = [[NSMenuItem alloc] init];
      [delete setTitle:@"Delete"];
      [delete setTarget:self];
      [delete setRepresentedObject:c];
      [delete setAction:@selector(deleteInstance:)];
      [subMenu addItem:delete];
      [delete release];
      [item setSubmenu:subMenu];
      [subMenu release];
      
    }
  }

  [self addItem:[NSMenuItem separatorItem]];
  [self addItem:self.createDB];
  [self addItem:self.configure];
  [self addItem:self.help];
  [self addItem:self.quit];
}
 */

/*

- (void) toggleArango: (id) sender{
  ArangoConfiguration* arango = [sender representedObject];
  if ([arango.isRunning isEqualToNumber: [NSNumber numberWithBool:NO]]) {
    arango.isRunning = [NSNumber numberWithBool:YES];
    [self.appDelegate startArango:arango];
  } else {
    arango.isRunning = [NSNumber numberWithBool:NO];
    [arango.instance terminate];
  }
  NSError* error = nil;
  [[self.appDelegate getArangoManagedObjectContext] save: &error];
  if (error != nil) {
    NSLog(@"%@", error.localizedDescription);
  }
  [self updateMenu];
}


- (void) createNewInstance
{
  self.createNewWindowController = [[[arangoCreateNewDBWindowController alloc] initWithAppDelegate:self.appDelegate] autorelease];
}

- (void) editInstance:(id) sender
{
  self.createNewWindowController = [[[arangoCreateNewDBWindowController alloc] initWithAppDelegate:self.appDelegate andArango:[sender representedObject]] autorelease];
}

// TODO: Ask user if data should be deleted also!
- (void) deleteInstance:(id) sender
{
  ArangoConfiguration* config = [sender representedObject];
  NSMutableString* infoText = [[NSMutableString alloc] init];
  [infoText setString:@"Do you want to delete the contents of folder \""];
  [infoText appendString:config.path];
  [infoText appendString:@"\" and the log-file as well?"];
  NSAlert* info = [NSAlert alertWithMessageText:@"Delete Data?" defaultButton:@"Keep Data" alternateButton:@"Abort" otherButton:@"Delete Data" informativeTextWithFormat:@"%@",infoText];
  [infoText release];
  [info beginSheetModalForWindow:nil modalDelegate:self didEndSelector:@selector(confirmedDialog:returnCode:contextInfo:) contextInfo: (void *)(config)];
}

- (void) confirmedDialog:(NSAlert*) dialog returnCode:(int) rC contextInfo: (ArangoConfiguration *) config
{
  if (rC == -1) {
    [self.appDelegate deleteArangoConfig:config andFiles:YES];
  } else if (rC == 1) {
    [self.appDelegate deleteArangoConfig:config andFiles:NO];
  }
  
}

- (void) openBrowser:(id) sender
{
  ArangoConfiguration* config = [sender representedObject];
  NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
  [f setThousandSeparator:@""];
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[@"http://localhost:" stringByAppendingString:[f stringFromNumber:config.port]]]];
  [f release];
}
 */

@end
