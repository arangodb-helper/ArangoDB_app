//
//  User.h
//  Arango
//
//  Created by Michael Hackstein on 17.09.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber * runOnStartUp;

@end
