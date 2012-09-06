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
      if (c.isRunning) {
        [item setState:1];
      } else {
        [item setState:0];
      }
      [self addItem:item];
    }
  }
  [self addItem:self.createDB];
  [self addItem:self.quit];
  [self update];
}


- (void) quitApplication
{
  [[NSApplication sharedApplication] terminate:nil];
}

- (void) createNewInstance
{
  self.createNewWindowController = [[arangoCreateNewDBWindowController alloc] initWithAppDelegate:self.appDelegate];
  [self.createNewWindowController.window makeKeyWindow];
}


@end
