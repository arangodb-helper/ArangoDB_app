//
//  ArangoConfiguration.h
//
// Simple class to store configurations permanently.
//
//  Created by Michael Hackstein on 12.09.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ArangoConfiguration : NSManagedObject

// The path to the database-folder
@property (nonatomic, retain) NSString * path;
// The path to the log-file
@property (nonatomic, retain) NSString * log;
// The alias name.
@property (nonatomic, retain) NSString * alias;
// The port on which Arango is listening.
@property (nonatomic, retain) NSNumber * port;
// Boolean value if the Arango is currently running.
@property (nonatomic, retain) NSNumber * isRunning;
// Boolean value if the Arango should be started on startup (if user decides to use the labeling option)
@property (nonatomic, retain) NSNumber * runOnStartUp;
// The level that should be logged.
@property (nonatomic, retain) NSString * loglevel;
// A pointer to the Task running the Arango.
// This value is NOT permanent.
// There is no point in making a reference permanent to a task that is killed with shutdown of the app.
@property (retain) NSTask* instance;

@end
