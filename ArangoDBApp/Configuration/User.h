//
//  User.h
//
// Simple class to make user-decissions permanent.
//
//  Created by Michael Hackstein on 17.09.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

// Decision which Arangos should be started on App-Startup:
// * 0 => None
// * 1 => Arangos that were running at last shutdown.
// * 2 => Arangos that are labeled by the user.
// * 3 => All Arangos.
@property (nonatomic, strong) NSNumber * runOnStartUp;

@property (nonatomic, strong) NSNumber * showTooltip;


@end
