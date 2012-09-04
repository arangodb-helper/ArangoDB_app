//
//  arangoCreateNewDBWindowController.m
//  Arango
//
//  Created by Michael Hackstein on 04.09.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import "arangoCreateNewDBWindowController.h"

@interface arangoCreateNewDBWindowController ()

@end

@implementation arangoCreateNewDBWindowController
@synthesize window;
@synthesize dbPathField;
@synthesize portField;
@synthesize logField;
@synthesize aliasField;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (NSURL*) showSelectDatabaseDialog
{
  NSOpenPanel* selectDatabaseLocation = [NSOpenPanel openPanel];
  [selectDatabaseLocation setCanChooseFiles:NO];
  [selectDatabaseLocation setCanChooseDirectories:YES];
  [selectDatabaseLocation setAllowsMultipleSelection:NO];
  if ([selectDatabaseLocation runModal] == NSFileHandlingPanelOKButton) {
    NSArray* selection = [selectDatabaseLocation URLs];
    return[selection objectAtIndex:0];
  }
  return NULL;
}

- (NSURL*) showSelectLogDialog
{
  NSOpenPanel* selectLogLocation = [NSOpenPanel openPanel];
  [selectLogLocation setCanChooseFiles:YES];
  [selectLogLocation setCanChooseDirectories:YES];
  [selectLogLocation setAllowsMultipleSelection:NO];
  if ([selectLogLocation runModal] == NSFileHandlingPanelOKButton) {
    NSArray* selection = [selectLogLocation URLs];
    return [selection objectAtIndex:0];
  }
  return NULL;
}


- (IBAction) openDatabase
{
  NSURL* dburl = [self showSelectDatabaseDialog];
  if (dburl) {
    BOOL isDir;
    [[NSFileManager defaultManager] fileExistsAtPath:[dburl path] isDirectory:&isDir];
    if (isDir) {
      
    } else {
      
    }
  } else {
    
  }
}

- (IBAction) openLog
{
  NSURL* logurl = [self showSelectLogDialog];
  BOOL isDir;
  [[NSFileManager defaultManager] fileExistsAtPath:[logurl path] isDirectory:&isDir];
  if (isDir) {
    
  } else {
    
  }
}

-(IBAction) start
{
  
}

@end
