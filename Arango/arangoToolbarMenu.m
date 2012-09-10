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

@implementation arangoToolbarMenu

@synthesize createDB;
@synthesize quit;
@synthesize createNewWindowController;

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
  NSError *error = nil;
  NSArray *fetchedResults = [[self.appDelegate getArangoManagedObjectContext] executeFetchRequest:request error:&error];
  if (fetchedResults == nil) {
    NSLog(error.localizedDescription);
  } else {
    for (ArangoConfiguration* c in fetchedResults) {
      
      NSMenuItem* item = [[NSMenuItem alloc] init];
      [item setEnabled:YES];
      [item setTitle: c.alias];
      if ([c.isRunning isEqualToNumber: [NSNumber numberWithBool:YES]]) {
        [item setState:1];
      } else {
        [item setState:0];
      }
      [item setTarget:self];
      [item setRepresentedObject:c];
      [item setAction:@selector(toggleArango:)];
      [self addItem:item];
      
      NSMenu* subMenu = [[NSMenu alloc] init];
      NSMenuItem* browser = [[NSMenuItem alloc] init];
      [browser setTitle:@"Browser"];
      [browser setTarget:self];
      [browser setRepresentedObject:c];
      [browser setAction:@selector(openBrowser:)];
      [subMenu addItem:browser];
      [subMenu addItem: [NSMenuItem separatorItem]];
      NSMenuItem* edit = [[NSMenuItem alloc] init];
      [edit setTitle:@"Edit"];
      [edit setTarget:self];
      [edit setRepresentedObject:c];
      [edit setAction:@selector(editInstance:)];
      [subMenu addItem:edit];
      NSMenuItem* delete = [[NSMenuItem alloc] init];
      [delete setTitle:@"Delete"];
      [delete setTarget:self];
      [delete setRepresentedObject:c];
      [delete setAction:@selector(deleteInstance:)];
      [subMenu addItem:delete];
      
      [item setSubmenu:subMenu];
      
    }
  }
  [self addItem:[NSMenuItem separatorItem]];
  [self addItem:self.createDB];
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
    NSLog(error.localizedDescription);
  }
  [self updateMenu];
}

- (void) quitApplication
{
  [[NSApplication sharedApplication] terminate:nil];
}

- (void) createNewInstance
{
  self.createNewWindowController = [[arangoCreateNewDBWindowController alloc] initWithAppDelegate:self.appDelegate];
}

- (void) editInstance:(id) sender
{
  self.createNewWindowController = [[arangoCreateNewDBWindowController alloc] initWithAppDelegate:self.appDelegate andArango:[sender representedObject]];
}

// TODO: Ask user if data should be deleted also!
- (void) deleteInstance:(id) sender
{
  ArangoConfiguration* config = [sender representedObject];
  NSMutableString* infoText = [[NSMutableString alloc] init];
  [infoText setString:@"Do you want to delete the contents of folder \""];
  [infoText appendString:config.path];
  [infoText appendString:@"\" and the log-file as well?"];
  NSAlert* info = [NSAlert alertWithMessageText:@"Delete Data?" defaultButton:@"Keep Data" alternateButton:@"Abort" otherButton:@"Delete Data" informativeTextWithFormat:infoText];
  [info beginSheetModalForWindow:nil modalDelegate:self didEndSelector:@selector(confirmedDialog:returnCode:contextInfo:) contextInfo:(__bridge void *)(config)];
}

- (void) confirmedDialog:(NSAlert*) dialog returnCode:(int) rC contextInfo: (ArangoConfiguration *) config
{
  if (rC == -1) {
    if ([config.isRunning isEqualToNumber:[NSNumber numberWithBool:YES]]) {
      [config.instance terminate];
      sleep(2);
    }
    NSError* error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:config.log error:&error];
    if (error != nil) {
      NSLog(error.localizedDescription);
    }
    error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:config.path error:&error];
    if (error != nil) {
      NSLog(error.localizedDescription);
    }
    [self.appDelegate deleteArangoConfig:config];
  } else if (rC == 1) {
    [self.appDelegate deleteArangoConfig:config];
  }
  
}

- (void) openBrowser:(id) sender
{
  ArangoConfiguration* config = [sender representedObject];
  NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
  [f setThousandSeparator:@""];
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[@"http://localhost:" stringByAppendingString:[f stringFromNumber:config.port]]]];
}

@end
