//
//  arangoCreateNewDBWindowController.m
//  Arango
//
//  Created by Michael Hackstein on 04.09.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import "arangoCreateNewDBWindowController.h"
#import "arangoAppDelegate.h"
#import "ArangoConfiguration.h"
#import "arangoToolbarMenu.h"

@interface arangoCreateNewDBWindowController ()

@end

@implementation arangoCreateNewDBWindowController
@synthesize portFormatter;
@synthesize okButton;
@synthesize abortButton;
@synthesize dbPathField;
@synthesize portField;
@synthesize logField;
@synthesize aliasField;
@synthesize openDBButton;
@synthesize openLogButton;
@synthesize appDelegate;
@synthesize editedConfig;
@synthesize showAdvanced;
@synthesize logLevelLabel;
@synthesize logLevelOptions;
@synthesize runOnStartup;
@synthesize logLabel;

const int advancedHeightDifference = 70;
float yButtonPosition = 0;

- (id)initWithWindow:(NSWindow *)window
{
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (id)initWithAppDelegate:(arangoAppDelegate*) aD
{
  if([[NSBundle mainBundle] respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)]) {
    self = [super init];
    [[NSBundle mainBundle] loadNibNamed:@"arangoCreateNewDBWindowController" owner:self topLevelObjects:nil];
  } else {
    self = [self initWithWindowNibName:@"arangoCreateNewDBWindowController" owner:self];
  }
  if (self) {
    self.portFormatter = [[NSNumberFormatter alloc] init];
    [self.portFormatter setNumberStyle:NSNumberFormatterNoStyle];
    [self.portFormatter setGeneratesDecimalNumbers:NO];
    [self.portFormatter setMinimumFractionDigits:0];
    [self.portFormatter setMaximumFractionDigits:0];
    [self.portFormatter setThousandSeparator:@""];
    [self.portField setFormatter:self.portFormatter];
    self.appDelegate = aD;
    [self.window setReleasedWhenClosed:NO];
    self.window.delegate = self;
    [self.window center];
    [NSApp activateIgnoringOtherApps:YES];
    [self.window makeKeyWindow];
    [self showWindow:self.window];
  }
  return self;
}


- (id)initWithAppDelegate:(arangoAppDelegate*) aD andArango: (ArangoConfiguration*) config
{
  if([[NSBundle mainBundle] respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)]) {
    self = [super init];
    [[NSBundle mainBundle] loadNibNamed:@"arangoCreateNewDBWindowController" owner:self topLevelObjects:nil];
  } else {
    self = [self initWithWindowNibName:@"arangoCreateNewDBWindowController" owner:self];
  }
  if (self) {
    self.portFormatter = [[NSNumberFormatter alloc] init];
    [self.portFormatter setNumberStyle:NSNumberFormatterNoStyle];
    [self.portFormatter setGeneratesDecimalNumbers:NO];
    [self.portFormatter setMinimumFractionDigits:0];
    [self.portFormatter setMaximumFractionDigits:0];
    [self.portFormatter setThousandSeparator:@""];
    self.appDelegate = aD;
    [self.window setReleasedWhenClosed:NO];
    self.window.delegate = self;
    [self fillArango: config];
    [self.window center];
    [NSApp activateIgnoringOtherApps:YES];
    [self.window makeKeyWindow];
    [self showWindow:self.window];
  }
  return self;
}

- (void) awakeFromNib
{
  yButtonPosition = self.okButton.frame.origin.y;
  [self.portField setFormatter:self.portFormatter];
  [self toggleAdvanced:NO];
}


- (void) fillArango: (ArangoConfiguration*) config
{
  self.dbPathField.stringValue = config.path;
  self.portField.stringValue = [self.portFormatter stringFromNumber:config.port];
  self.logField.stringValue = config.log;
  self.aliasField.stringValue = config.alias;
  self.logLevelOptions.stringValue = config.loglevel;
  if ([config.runOnStartUp isEqualToNumber: [NSNumber numberWithBool:YES]]) {
    self.runOnStartup.state = NSOnState;
  } else {
    self.runOnStartup.state = NSOffState;
  }
  self.editedConfig = config;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

- (void) windowWillClose:(NSNotification *)notification
{
  [self.portFormatter release];
}

- (NSURL*) showSelectDatabaseDialog
{
  NSOpenPanel* selectDatabaseLocation = [NSOpenPanel openPanel];
  [selectDatabaseLocation setCanChooseFiles:NO];
  [selectDatabaseLocation setCanChooseDirectories:YES];
  [selectDatabaseLocation setCanCreateDirectories:YES];
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
    }
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
  }
}

- (BOOL) checkValuesAndStartInstance
{
  NSURL* dbPath;
  if ([dbPathField.stringValue hasPrefix:@"~"]){
    dbPath = [NSURL URLWithString:[NSHomeDirectory() stringByAppendingString:[dbPathField.stringValue substringFromIndex:1]]];
  } else {
    dbPath = [NSURL URLWithString:dbPathField.stringValue];
  }
  if (![[NSFileManager defaultManager] fileExistsAtPath:[dbPath path]]) {
    NSError* error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:[dbPath path] withIntermediateDirectories:YES attributes:nil error:&error];
    if (error != nil) {
      NSAlert* info = [[NSAlert alloc] init];
      [info setMessageText:@"Error while Creating File!"];
      [info setInformativeText:error.localizedDescription];
      [info beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(confirmedError:returnCode:contextInfo:) contextInfo:nil];
      return NO;
    }
  }
  BOOL isDir;
  [[NSFileManager defaultManager] fileExistsAtPath:[dbPath path] isDirectory:&isDir];
  if (!isDir) {
    if (![[NSFileManager defaultManager] isWritableFileAtPath:[dbPath path]]) {
      NSAlert* info = [[NSAlert alloc] init];
      [info setMessageText:@"Invalid Location!"];
      [info setInformativeText:@"Arango is not allowed to write in the selected folder."];
      [info beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(confirmedError:returnCode:contextInfo:) contextInfo:nil];
      return NO;
    }
    NSAlert* info = [[NSAlert alloc] init];
    [info setMessageText:@"Invalid Location!"];
    [info setInformativeText:@"The path you have defined is not a folder."];
    [info beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(confirmedError:returnCode:contextInfo:) contextInfo:nil];
    return NO;
  }
  NSNumber* port = [self.portFormatter numberFromString:portField.stringValue];
  if (port <= 0) {
    NSAlert* info = [[NSAlert alloc] init];
    [info setMessageText:@"Invalid Port!"];
    [info setInformativeText:@"The Port you have defined is either not a number or blocked."];
    [info beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(confirmedError:returnCode:contextInfo:) contextInfo:nil];
    return NO;
  }
  NSString* alias = aliasField.stringValue;
  alias = [alias stringByReplacingOccurrencesOfString:@" " withString: @"_"];
  if ([alias isEqualToString:@""]) {
    alias = @"Arango";
  }
  NSURL* logPath;
  if ([logField.stringValue isEqualToString:@""]) {
    logPath = dbPath;
    NSMutableString* append = [[NSMutableString alloc] init];
    [append setString:[logPath path]];
    [append appendString:@"/"];
    [append appendString:alias];
    [append appendString:@".log"];
    logPath = [NSURL fileURLWithPath:append];
    [append release];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[logPath path]]) {
      [[NSFileManager defaultManager] createFileAtPath:[logPath path] contents:nil attributes:nil];
    }
  } else {
    logPath = [NSURL URLWithString:logField.stringValue];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[logPath path] isDirectory:&isDir]) {
      if (isDir) {
        NSMutableString* append = [[NSMutableString alloc] init];
        [append setString:[logPath path]];
        [append appendString:@"/"];
        [append appendString:alias];
        [append appendString:@".log"];
        logPath = [NSURL fileURLWithPath:append];
        [append release];
        if (![[NSFileManager defaultManager] fileExistsAtPath:[logPath path]]) {
          [[NSFileManager defaultManager] createFileAtPath:[logPath path] contents:nil attributes:nil];
        }
      }
    } else {
      [[NSFileManager defaultManager] createFileAtPath:[logPath path] contents:nil attributes:nil];
    }
  }
  if (self.editedConfig != nil) {
    [self.appDelegate updateArangoConfig:self.editedConfig withPath:[dbPath path] andPort:port andLog:[logPath path] andLogLevel:self.logLevelOptions.stringValue andRunOnStartUp: (self.runOnStartup.state == NSOnState) andAlias:alias];
  } else {
    [self.appDelegate startNewArangoWithPath:[dbPath path] andPort:port andLog:[logPath path] andLogLevel:self.logLevelOptions.stringValue andRunOnStartUp: (self.runOnStartup.state == NSOnState) andAlias: alias];
  }
  return YES;
}


- (IBAction) start:(id) sender
{
  if (![self checkValuesAndStartInstance]) {
    NSLog(@"FAILED");
  } else {
    [self.window orderOut:self.window];
  }
}



- (void)confirmedError:(NSAlert *)alert
                          returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
  
}

- (void) displayAdvanced: (id) sender
{
  NSRect okRect = self.okButton.frame;
  okRect.origin.y = yButtonPosition;
  self.okButton.frame = okRect;
  NSRect abortRect = self.abortButton.frame;
  abortRect.origin.y = yButtonPosition;
  self.abortButton.frame = abortRect;
  [self.logField setHidden:NO];
  [self.logLabel setHidden:NO];
  [self.logLevelLabel setHidden:NO];
  [self.logLevelOptions setHidden:NO];
  [self.openLogButton setHidden:NO];
  [self.okButton setHidden:NO];
  [self.abortButton setHidden:NO];
  
}

- (void) displayControls: (id) sender
{
  NSRect okRect = self.okButton.frame;
  okRect.origin.y = yButtonPosition;
  self.okButton.frame = okRect;
  NSRect abortRect = self.abortButton.frame;
  abortRect.origin.y = yButtonPosition;
  self.abortButton.frame = abortRect;
  [self.okButton setHidden:NO];
  [self.abortButton setHidden:NO];
}

- (void) toggleAdvanced: (BOOL) animate
{
  NSRect changeTo = self.window.frame;
  [self.okButton setHidden:YES];
  [self.abortButton setHidden:YES];
  if ([self.logField isHidden]) {
    changeTo.size.height += advancedHeightDifference;
    changeTo.origin.y -= advancedHeightDifference;
    double toSleep = [self.window animationResizeTime:changeTo];
    [self.window setFrame:changeTo display:NO animate:animate];
    [NSTimer scheduledTimerWithTimeInterval:toSleep target:self selector:@selector(displayAdvanced:) userInfo:nil repeats:NO];
  } else {
    changeTo.size.height -= advancedHeightDifference;
    changeTo.origin.y += advancedHeightDifference;
    double toSleep = [self.window animationResizeTime:changeTo];
    [self.logField setHidden:YES];
    [self.logLabel setHidden:YES];
    [self.logLevelLabel setHidden:YES];
    [self.logLevelOptions setHidden:YES];
    [self.openLogButton setHidden:YES];
    [self.window setFrame:changeTo display:NO animate:animate];
    [NSTimer scheduledTimerWithTimeInterval:toSleep target:self selector:@selector(displayControls:) userInfo:nil repeats:NO];
  }
  
}

- (IBAction) abort: (id) sender
{
  [self.window orderOut:self.window];
}

- (IBAction) disclose: (id) sender
{
  [self toggleAdvanced:YES];
}

@end
