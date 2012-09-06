//
//  arangoCreateNewDBWindowController.m
//  Arango
//
//  Created by Michael Hackstein on 04.09.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import "arangoCreateNewDBWindowController.h"
#import "arangoAppDelegate.h"

@interface arangoCreateNewDBWindowController ()

@end

@implementation arangoCreateNewDBWindowController
@synthesize window;
@synthesize dbPathField;
@synthesize portField;
@synthesize logField;
@synthesize aliasField;
@synthesize openDBButton;
@synthesize openLogButton;
@synthesize appDelegate;

- (id)initWithWindow:(NSWindow *)window
{
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (id)initWithAppDelegate:(arangoAppDelegate*) aD
{
  [[NSBundle mainBundle] loadNibNamed:@"arangoCreateNewDBWindowController" owner:self topLevelObjects:nil];
  if (self) {
    self.appDelegate = aD;
    [self showWindow:self.window];
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
  [selectDatabaseLocation setPrompt:@"Choose"];
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
  [selectLogLocation setPrompt:@"Choose"];
  if ([selectLogLocation runModal] == NSFileHandlingPanelOKButton) {
    NSArray* selection = [selectLogLocation URLs];
    return [selection objectAtIndex:0];
  }
  return NULL;
}


- (IBAction) openDatabase:(id) sender
{
  NSURL* dburl = [self showSelectDatabaseDialog];
  if (dburl) {
    BOOL isDir;
    [[NSFileManager defaultManager] fileExistsAtPath:[dburl path] isDirectory:&isDir];
    if (isDir) {
      [dbPathField setStringValue:[dburl path]];
    } else {
      NSLog(@"Is NOT a directory");
    }
  } else {
    NSLog(@"Aborted");
  }
}

- (IBAction) openLog:(id) sender
{
  NSURL* logurl = [self showSelectLogDialog];
  if (logurl) {
    BOOL isDir;
    [[NSFileManager defaultManager] fileExistsAtPath:[logurl path] isDirectory:&isDir];
    if (isDir) {
      [logField setStringValue:[logurl path]];
    } else {
      [logField setStringValue:[logurl path]];
    }
  } else {
    NSLog(@"Aborted");
  }
}

- (BOOL) checkValuesAndStartInstance
{
  NSURL* dbPath = [NSURL URLWithString:dbPathField.stringValue];
  BOOL isDir;
  [[NSFileManager defaultManager] fileExistsAtPath:[dbPath path] isDirectory:&isDir];
  if (!isDir) {
    NSLog(@"Is NOT a directory");
    return NO;
  }
  NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
  [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
  NSInteger port = [[formatter numberFromString:portField.stringValue] integerValue];
  if (port <= 0) {
    NSLog(@"Invalid Port");
    return NO;
  }
  NSString* alias = aliasField.stringValue;
  if ([alias isEqualToString:@""]) {
    alias = @"Arango";
  }
  NSURL* logPath = [NSURL URLWithString:logField.stringValue];
  [[NSFileManager defaultManager] fileExistsAtPath:[logPath path] isDirectory:&isDir];
  if (isDir) {
    logPath = [[logPath URLByAppendingPathComponent:alias] URLByAppendingPathExtension:@"log"];
    NSLog(logPath);
  }
  
  [self.appDelegate startNewArangoWithPath:[dbPath path] andPort:port andLog:[logPath path] andAlias: alias];
  return YES;
}


- (IBAction) start:(id) sender
{
  if (![self checkValuesAndStartInstance]) {
    NSLog(@"FAILED");
  } else {
    NSLog(@"Success!");
  }
}

@end
