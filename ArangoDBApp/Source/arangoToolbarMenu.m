//
//  arangoToolbarMenu.m
//  Arango
//
//  Created by Michael Hackstein on 06.09.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import "arangoToolbarMenu.h"
#import "arangoCreateNewDBWindowController.h"
#import "arangoAppDelegate.h"
#import "ArangoConfiguration.h"
#import "arangoUserConfigController.h"

@implementation arangoToolbarMenu

@synthesize createDB;
@synthesize configure;
@synthesize quit;
@synthesize createNewWindowController;
@synthesize configurationViewController;
@synthesize appDelegate;

// TODO: Localize
- (id)initWithAppDelegate:(arangoAppDelegate*) aD
{
  self = [super init];
  if (self) {
    self.createNewWindowController = nil;
    self.appDelegate = aD;
    self.createDB = [[NSMenuItem alloc] init];
    [self.createDB setEnabled:YES];
    [self.createDB setTitle:@"New..."];
    //[self.createDB setKey:@"N"];
    [self.createDB setTarget:self];
    [self.createDB setAction:@selector(createNewInstance)];
    self.configure = [[NSMenuItem alloc] init];
    [self.configure setEnabled:YES];
    [self.configure setTitle:@"Configure"];
    [self.configure setTarget:self];
    [self.configure setAction:@selector(showConfiguration)];
    self.quit = [[NSMenuItem alloc] init];
    [self.quit setEnabled:YES];
    [self.quit setTitle:@"Quit"];
    //[self.quit setKey:@"Q"];
    [self.quit setTarget:self];
    [self.quit setAction:@selector(quitApplication)];
    [self updateMenu];
  }
  return self;
}

- (void) updateMenu
{
  [self removeAllItems];
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
  [self addItem:self.quit];
}

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

- (void) quitApplication
{
  [[NSApplication sharedApplication] terminate:nil];
}

- (void) showConfiguration
{
  self.configurationViewController = [[[arangoUserConfigController alloc] initWithAppDelegate:self.appDelegate] autorelease];
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

@end
