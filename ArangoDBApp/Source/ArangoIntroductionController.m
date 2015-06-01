////////////////////////////////////////////////////////////////////////////////
/// @brief introduction controller
///
/// @file
///
/// DISCLAIMER
///
/// Copyright 2014 ArangoDB GmbH, Cologne, Germany
/// Copyright 2004-2014 triAGENS GmbH, Cologne, Germany
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
/// Copyright holder is ArangoDB GmbH, Cologne, Germany
///
/// @author Dr. Frank Celler
/// @author Michael Hackstein
/// @author Copyright 2014, ArangoDB GmbH, Cologne, Germany
/// @author Copyright 2012, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

#import "ArangoIntroductionController.h"

#import "ArangoAppDelegate.h"
#import "ArangoManager.h"
#import "ArangoInstanceController.h"

// -----------------------------------------------------------------------------
// --SECTION--                                      ArangoIntroductionController
// -----------------------------------------------------------------------------

@implementation ArangoIntroductionController

// -----------------------------------------------------------------------------
// --SECTION--                                      constructors and destructors
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief constructor
////////////////////////////////////////////////////////////////////////////////

- (id) initWithArangoManager: (ArangoManager*) manager
              andAppDelegate: (ArangoAppDelegate*) delegate{
  return [self initWithArangoManager:manager
                      andAppDelegate:delegate
                         andNibNamed:@"ArangoIntroductionView"];
}

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief windows is about to close
////////////////////////////////////////////////////////////////////////////////

- (void) windowWillClose: (NSNotification*) notification {
  [self.delegate clearIntroductionDialog];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief shows the new instance dialog
////////////////////////////////////////////////////////////////////////////////

- (IBAction) createInstance: (id) sender {
  [self.window orderOut:self.window];
  [self.delegate showNewInstanceDialog];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief "show tip" button
////////////////////////////////////////////////////////////////////////////////

- (IBAction) showTooltip: (id) sender {
  int value = [sender intValue];
  
  if (value) {
    [[self manager] setShowTooltip: YES];
  }
  else {
    [[self manager] setShowTooltip: NO];
  }
}

@end

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "/// @brief\\|/// {@inheritDoc}\\|/// @page\\|// --SECTION--\\|/// @\\}"
// End:
