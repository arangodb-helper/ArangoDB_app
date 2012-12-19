////////////////////////////////////////////////////////////////////////////////
/// @brief create or update instance controller
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

#import "ArangoInstanceController.h"

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

@implementation ArangoInstanceController

// -----------------------------------------------------------------------------
// --SECTION--                                                   private methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the file browser
////////////////////////////////////////////////////////////////////////////////

- (NSURL*) showFileBrowser: (BOOL) directories {
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
/// @brief display advanced box
////////////////////////////////////////////////////////////////////////////////

- (void) displayAdvanced: (id) sender {
  double height = _advancedOptions.frame.size.height - HeightCorrection;

  NSRect okRect = _okButton.frame;
  okRect.origin.y -= height;
  _okButton.frame = okRect;

  NSRect abortRect = _abortButton.frame;
  abortRect.origin.y -= height;
  _abortButton.frame = abortRect;
  
  [_okButton setHidden:NO];
  [_abortButton setHidden:NO];

  [_advancedOptions setHidden:NO];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief hide advanced box
////////////////////////////////////////////////////////////////////////////////

- (void) hideAdvanced: (id) sender {
  double height = _advancedOptions.frame.size.height - HeightCorrection;

  NSRect okRect = _okButton.frame;
  okRect.origin.y += height;
  _okButton.frame = okRect;
  
  NSRect abortRect = _abortButton.frame;
  abortRect.origin.y += height;
  _abortButton.frame = abortRect;

  [_okButton setHidden:NO];
  [_abortButton setHidden:NO];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief toggle advanced box
////////////////////////////////////////////////////////////////////////////////

- (void) toggleAdvancedBox: (BOOL) animate {
  double height = _advancedOptions.frame.size.height - HeightCorrection;
  NSRect changeTo = self.window.frame;

  [_okButton setHidden:YES];
  [_abortButton setHidden:YES];

  // show advance
  if ([_advancedOptions isHidden]) {
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

    [_advancedOptions setHidden:YES];

    [self.window setFrame:changeTo display:NO animate:animate];

    [NSTimer scheduledTimerWithTimeInterval:toSleep
                                     target:self
                                   selector:@selector(hideAdvanced:)
                                   userInfo:nil
                                    repeats:NO];
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief ignores confirmed errors
////////////////////////////////////////////////////////////////////////////////

- (void) confirmedError: (NSAlert*) alert
             returnCode: (int) returnCode
            contextInfo: (void*) contextInfo {
}

////////////////////////////////////////////////////////////////////////////////
/// @brief creates a new instance
////////////////////////////////////////////////////////////////////////////////

- (BOOL) createNewInstance {

  // prepare configuration
  ArangoStatus* status = [self.delegate prepareConfiguration:_nameField.stringValue
                                                    withPath:_databaseField.stringValue
                                                     andPort:[[_portFormatter numberFromString:_portField.stringValue] intValue]
                                                      andLog:_logField.stringValue
                                                 andLogLevel:_logLevelOptions.stringValue];

  if (status == nil) {
    return NO;
  }

  // create configuration
  BOOL ok = [self.delegate createConfiguration:status.name
                                      withPath:status.path
                                       andPort:status.port
                                        andLog:status.logPath
                                   andLogLevel:status.logLevel
                               andRunOnStartUp:_runOnStartupButton.state == NSOnState];

  if (ok) {
    [self.window close];
  }
  
  return ok;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief ignores confirmed errors
////////////////////////////////////////////////////////////////////////////////

- (void) stopAlertDidEnd: (NSAlert*) alert
              returnCode: (NSInteger) returnCode
             contextInfo: (void*) contextInfo {
}

////////////////////////////////////////////////////////////////////////////////
/// @brief updates a new instance
////////////////////////////////////////////////////////////////////////////////

- (BOOL) updateInstance {
  ArangoStatus* status = [self.delegate currentStatus:_status.name];

  if (status == nil) {
    [self.window close];
    return YES;
  }

  if (status.isRunning) {
    NSAlert* info = [[[NSAlert alloc] init] autorelease];
      
    [info setMessageText:@"ArangoDB instance must be stopped!"];
    [info setInformativeText:@"The ArangoDB instance must be stopped before moving the database directory."];

    [info beginSheetModalForWindow:self.window
                     modalDelegate:self
                    didEndSelector:@selector(stopAlertDidEnd:returnCode:contextInfo:)
                       contextInfo:nil];

    return YES;
  }

  // update configuration
  BOOL ok = [self.delegate updateConfiguration:_status.name
                                      withPath:_databaseField.stringValue
                                       andPort:[[_portFormatter numberFromString:_portField.stringValue] intValue]
                                        andLog:_logField.stringValue
                                   andLogLevel:_logLevelOptions.stringValue
                               andRunOnStartUp:_runOnStartupButton.state == NSOnState];

  if (! ok) {
    return NO;
  }
  
  [self.window close];
  return YES;
}

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief default constructor
////////////////////////////////////////////////////////////////////////////////

- (id) initWithArangoManager: (ArangoManager*) delegate {
  self = [super initWithArangoManager:delegate
                          andNibNamed:@"ArangoNewInstanceView"
                 andReleasedWhenClose:YES];

  if (self) {
    _portFormatter = [[NSNumberFormatter alloc] init];
    [_portFormatter setNumberStyle:NSNumberFormatterNoStyle];
    [_portFormatter setGeneratesDecimalNumbers:NO];
    [_portFormatter setMinimumFractionDigits:0];
    [_portFormatter setMaximumFractionDigits:0];
    [_portFormatter setThousandSeparator:@""];
    [_portField setFormatter:_portFormatter];

    _portField.stringValue = [_portFormatter stringFromNumber:[self.delegate findFreePort]];

    _status = nil;
  }

  return self;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief constructor
////////////////////////////////////////////////////////////////////////////////

- (id) initWithArangoManager: (ArangoManager*) delegate
                   andStatus: (ArangoStatus*) status {
  self = [self initWithArangoManager: delegate];

  if (self) {
    _status = [status retain];

    self.window.title = @"Edit ArangoDB";
    _okButton.title = @"Save";
    _databaseField.stringValue = status.path;
    _portField.stringValue = [_portFormatter stringFromNumber:[NSNumber numberWithInt:status.port]];
    _logField.stringValue = status.logPath;
    _nameField.stringValue = status.name;
    _logLevelOptions.stringValue = status.logLevel;

    if (status.runOnStartup) {
      _runOnStartupButton.state = NSOnState;
    }
    else {
      _runOnStartupButton.state = NSOffState;
    }
  }

  return self;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief destructor
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
  [_portFormatter release];
  [_status release];
  
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
/// @brief browse database path
////////////////////////////////////////////////////////////////////////////////

- (IBAction) browseDatabase: (id) sender {
  NSURL* dburl = [self showFileBrowser:YES];

  if (dburl) {
    BOOL isDir;
    [[NSFileManager defaultManager] fileExistsAtPath:[dburl path] isDirectory:&isDir];

    if (isDir) {
      [_databaseField setStringValue:[dburl path]];
    }
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief browse log file
////////////////////////////////////////////////////////////////////////////////

- (IBAction) browseLog: (id) sender {
  NSURL* logurl = [self showFileBrowser:NO];

  if (logurl) {
    [_logField setStringValue:[logurl path]];
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief create instance
////////////////////////////////////////////////////////////////////////////////

- (IBAction) saveInstance: (id) sender {
  BOOL ok;
  
  if (_status == nil) {
    ok = [self createNewInstance];
  }
  else {
    ok = [self updateInstance];
  }

  if (! ok) {
      NSAlert* info = [[[NSAlert alloc] init] autorelease];
      
      [info setMessageText:@"Cannot create new ArangoDB instance!"];
      [info setInformativeText:[NSString stringWithFormat:@"Encountered error: \"%@\", please correct and try again.",self.delegate.lastError]];

      [info beginSheetModalForWindow:self.window
                       modalDelegate:self
                      didEndSelector:@selector(confirmedError:returnCode:contextInfo:)
                         contextInfo:nil];
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief abort
////////////////////////////////////////////////////////////////////////////////

- (IBAction) abortCreate: (id) sender {
  [self.window close];
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
