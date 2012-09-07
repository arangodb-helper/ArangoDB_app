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
      NSMenuItem* edit = [[NSMenuItem alloc] init];
      [edit setTitle:@"Edit"];
      [edit setTarget:self];
      [edit setRepresentedObject:c];
      [edit setAction:@selector(editInstance:)];
      [subMenu addItem:edit];
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
  self.createNewWindowController = nil;
  self.createNewWindowController = [[arangoCreateNewDBWindowController alloc] initWithAppDelegate:self.appDelegate];
  [self.createNewWindowController.window makeKeyWindow];
}

- (void) editInstance:(id) sender
{
  self.createNewWindowController = nil;
  self.createNewWindowController = [[arangoCreateNewDBWindowController alloc] initWithAppDelegate:self.appDelegate andArango: [sender representedObject]];
  [self.createNewWindowController.window makeKeyWindow];
}

@end
