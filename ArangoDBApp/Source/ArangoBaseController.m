////////////////////////////////////////////////////////////////////////////////
/// @brief base controller
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

#import "ArangoBaseController.h"

#import "ArangoAppDelegate.h"
#import "ArangoManager.h"

// -----------------------------------------------------------------------------
// --SECTION--                                              ArangoBaseController
// -----------------------------------------------------------------------------

@implementation ArangoBaseController

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief default constructor
////////////////////////////////////////////////////////////////////////////////

- (id) initWithArangoManager: (ArangoManager*) manager
              andAppDelegate: (ArangoAppDelegate*) delegate
                 andNibNamed: (NSString*) name {

  // loadNibNamed:owner:topLevelObjects was introduced in 10.8
  if ([[NSBundle mainBundle] respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)]) {
    self = [super init];
      
    if (self) {
      [[NSBundle mainBundle] loadNibNamed:name owner:self topLevelObjects:nil];
    }
  }
  else {
    self = [self initWithWindowNibName:name owner:self];
  }

  if (self) {
    _manager = manager;
    _delegate = delegate;
    
    [self.window setDelegate:self];

    [self.window setReleasedWhenClosed:NO];
    [self.window center];

    [NSApp activateIgnoringOtherApps:YES];
    
    [self.window makeKeyWindow];
    [self showWindow:self.window];
  }
  
  return self;
}

@end

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "^\\(/// @brief\\|/// {@inheritDoc}\\|/// @addtogroup\\|/// @page\\|// --SECTION--\\|/// @\\}\\)"
// End:
