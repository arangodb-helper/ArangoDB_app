//
//  arangoToolbarMenu.m
//  Arango
//
//  Created by Michael Hackstein on 06.09.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import "arangoToolbarMenu.h"
#import "arangoCreateNewDBWindowController.h"

@implementation arangoToolbarMenu

@synthesize createDB;
@synthesize quit;
@synthesize createNewWindowController;

// TODO: Localize
- (id)init
{
  self = [super init];
  if (self) {
    self.createDB = [[NSMenuItem alloc] init];
    [self.createDB setEnabled:YES];
    [self.createDB setTitle:@"New..."];
    //[self.createDB setKey:@"N"];
    [self.createDB setTarget:self];
    [self.createDB setAction:@selector(createNewInstance)];
    [self addItem:self.createDB];
    
    
    self.quit = [[NSMenuItem alloc] init];
    [self.quit setEnabled:YES];
    [self.quit setTitle:@"Quit"];
    //[self.quit setKey:@"Q"];
    [self.quit setTarget:self];
    [self.quit setAction:@selector(quitApplication)];
    [self addItem:self.quit];
  }
  return self;
}

- (void) quitApplication
{
  [[NSApplication sharedApplication] terminate:nil];
}

- (void) createNewInstance
{
  self.createNewWindowController = [[arangoCreateNewDBWindowController alloc] init];
  [self.createNewWindowController.window makeKeyWindow];
}


@end
