////////////////////////////////////////////////////////////////////////////////
/// @brief new instance controller
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

#import "ArangoNewInstanceController.h"

#import "ArangoConfiguration.h"
#import "ArangoManager.h"
#import "ArangoStatus.h"
#import "ArangoToolbarMenu.h"
#import "arangoAppDelegate.h"

// -----------------------------------------------------------------------------
// --SECTION--                                                 private constants
// -----------------------------------------------------------------------------

static const double HeightCorrection = 10;

// -----------------------------------------------------------------------------
// --SECTION--                                       ArangoNewInstanceController
// -----------------------------------------------------------------------------

@implementation ArangoNewInstanceController

// -----------------------------------------------------------------------------
// --SECTION--                                                   private methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the file browser
////////////////////////////////////////////////////////////////////////////////

- (NSURL*) showFileBrowser: (BOOL) directories
{
  NSOpenPanel* browser = [NSOpenPanel openPanel];
  [browser setCanChooseFiles:(! directories)];
  [browser setCanChooseDirectories:YES];
  [browser setCanCreateDirectories:directories];
  [browser setAllowsMultipleSelection:NO];
  [browser setPrompt:@"Choose"];

  if ([browser runModal] == NSFileHandlingPanelOKButton) {
    NSArray* selection = [browser URLs];
    return [selection objectAtIndex:0];
  }

  return NULL;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief ignores confirmed errors
////////////////////////////////////////////////////////////////////////////////

- (void) confirmedError: (NSAlert*) alert
             returnCode: (int) returnCode
            contextInfo: (void*) contextInfo {
}

////////////////////////////////////////////////////////////////////////////////
/// @brief display advanced box
////////////////////////////////////////////////////////////////////////////////

- (void) displayAdvanced: (id) sender {
  double height = self.advancedOptions.frame.size.height - HeightCorrection;

  NSRect okRect = self.okButton.frame;
  okRect.origin.y -= height;
  self.okButton.frame = okRect;

  NSRect abortRect = self.abortButton.frame;
  abortRect.origin.y -= height;
  self.abortButton.frame = abortRect;
  
  [self.okButton setHidden:NO];
  [self.abortButton setHidden:NO];

  [self.advancedOptions setHidden:NO];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief hide advanced box
////////////////////////////////////////////////////////////////////////////////

- (void) hideAdvanced: (id) sender {
  double height = self.advancedOptions.frame.size.height - HeightCorrection;

  NSRect okRect = self.okButton.frame;
  okRect.origin.y += height;
  self.okButton.frame = okRect;
  
  NSRect abortRect = self.abortButton.frame;
  abortRect.origin.y += height;
  self.abortButton.frame = abortRect;

  [self.okButton setHidden:NO];
  [self.abortButton setHidden:NO];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief toggle advanced box
////////////////////////////////////////////////////////////////////////////////

- (void) toggleAdvancedBox: (BOOL) animate {
  double height = self.advancedOptions.frame.size.height - HeightCorrection;
  NSRect changeTo = self.window.frame;

  [self.okButton setHidden:YES];
  [self.abortButton setHidden:YES];

  // show advance
  if ([self.advancedOptions isHidden]) {
    changeTo.size.height += height;
    changeTo.origin.y -= height;

    double toSleep = [self.window animationResizeTime:changeTo];

    [self.window setFrame:changeTo display:NO animate:animate];

    [NSTimer scheduledTimerWithTimeInterval:toSleep
                                     target:self
                                   selector:@selector(displayAdvanced:)
                                   userInfo:nil
                                    repeats:NO];
  }

  // hide advance
  else {
    changeTo.size.height -= height;
    changeTo.origin.y += height;

    double toSleep = [self.window animationResizeTime:changeTo];

    [self.advancedOptions setHidden:YES];

    [self.window setFrame:changeTo display:NO animate:animate];

    [NSTimer scheduledTimerWithTimeInterval:toSleep
                                     target:self
                                   selector:@selector(hideAdvanced:)
                                   userInfo:nil
                                    repeats:NO];
  }
}

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief default constructor
////////////////////////////////////////////////////////////////////////////////

- (id) initWithAppDelegate: (arangoAppDelegate*) delegate {
  self = [super initWithAppDelegate:delegate nibNamed:@"ArangoNewInstanceView"];

  if (self) {
    [self.window setReleasedWhenClosed:YES];

    _portFormatter = [[NSNumberFormatter alloc] init];
    [_portFormatter setNumberStyle:NSNumberFormatterNoStyle];
    [_portFormatter setGeneratesDecimalNumbers:NO];
    [_portFormatter setMinimumFractionDigits:0];
    [_portFormatter setMaximumFractionDigits:0];
    [_portFormatter setThousandSeparator:@""];
    [_portField setFormatter:self.portFormatter];

    _configuration = nil;
  }

  return self;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief constructor
////////////////////////////////////////////////////////////////////////////////

- (id) initWithAppDelegate: (arangoAppDelegate*) delegate
          andConfiguration: (ArangoConfiguration*) config {
  self = [self initWithAppDelegate: delegate];

  if (self) {
    _configuration = config;

    self.window.title = @"Edit ArangoDB";
    self.okButton.title = @"Edit";
    self.databaseField.stringValue = config.path;
    self.portField.stringValue = [self.portFormatter stringFromNumber:config.port];
    self.logField.stringValue = config.log;
    self.nameField.stringValue = config.alias;
    self.logLevelOptions.stringValue = config.loglevel;

    if ([config.runOnStartUp isEqualToNumber: [NSNumber numberWithBool:YES]]) {
      self.runOnStartupButton.state = NSOnState;
    }
    else {
      self.runOnStartupButton.state = NSOffState;
    }
  }

  return self;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief destructor
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
  [_portFormatter release];
  
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief awake
////////////////////////////////////////////////////////////////////////////////

- (void) awakeFromNib {
  [_portField setFormatter:_portFormatter];
  [self toggleAdvancedBox:NO];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief browse log file
////////////////////////////////////////////////////////////////////////////////

- (IBAction) browseDatabase: (id) sender {
  NSURL* dburl = [self showFileBrowser:YES];

  if (dburl) {
    BOOL isDir;
    [[NSFileManager defaultManager] fileExistsAtPath:[dburl path] isDirectory:&isDir];

    if (isDir) {
      [self.databaseField setStringValue:[dburl path]];
    }
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief browse log file
////////////////////////////////////////////////////////////////////////////////

- (IBAction) browseLog: (id) sender {
  NSURL* logurl = [self showFileBrowser:NO];

  if (logurl) {
    [self.logField setStringValue:[logurl path]];
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief create instance
////////////////////////////////////////////////////////////////////////////////

- (IBAction) createInstance: (id) sender {

  // prepare configuration
  ArangoStatus* status = [self.delegate.manager prepareConfiguration:self.nameField.stringValue
                                                            withPath:self.databaseField.stringValue
                                                             andPort:[self.portFormatter numberFromString:_portField.stringValue]
                                                              andLog:self.logField.stringValue];

  if (status == nil) {
    NSAlert* info = [[NSAlert alloc] init];

    [info setMessageText:@"Cannot create new ArangoDB instance!"];
    [info setInformativeText:[[@"Encountered error: " stringByAppendingString:self.delegate.manager.lastError] stringByAppendingString:@", please correct and try again."]];

    [info beginSheetModalForWindow:self.window
                     modalDelegate:self
                    didEndSelector:@selector(confirmedError:returnCode:contextInfo:)
                       contextInfo:nil];
    return;
  }

  // create configuration
  BOOL ok = [self.delegate.manager createConfiguration:status.name
                                              withPath:status.path
                                               andPort:status.port
                                                andLog:status.logPath
                                           andLogLevel:self.logLevelOptions.stringValue
                                       andRunOnStartUp:self.runOnStartupButton.state == NSOnState];

  if (! ok) {
    NSAlert* info = [[NSAlert alloc] init];

    [info setMessageText:@"Cannot create new ArangoDB instance!"];
    [info setInformativeText:[[@"Encountered error: " stringByAppendingString:self.delegate.manager.lastError] stringByAppendingString:@", please correct and try again."]];

    [info beginSheetModalForWindow:self.window
                     modalDelegate:self
                    didEndSelector:@selector(confirmedError:returnCode:contextInfo:)
                       contextInfo:nil];
    return;
  }

  // that's it
  [self.window orderOut:self.window];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief abort
////////////////////////////////////////////////////////////////////////////////

- (IBAction) abortCreate: (id) sender {
  [self.window orderOut:self.window];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief toggle advanced
////////////////////////////////////////////////////////////////////////////////

- (IBAction) toggleAdvanced: (id) sender {
  [self toggleAdvancedBox:YES];
}

@end

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "^\\(/// @brief\\|/// {@inheritDoc}\\|/// @addtogroup\\|/// @page\\|// --SECTION--\\|/// @\\}\\)"
// End:
