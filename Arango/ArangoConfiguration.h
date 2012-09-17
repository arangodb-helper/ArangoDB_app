//
//  ArangoConfiguration.h
//  Arango
//
//  Created by Michael Hackstein on 12.09.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ArangoConfiguration : NSManagedObject

@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSString * log;
@property (nonatomic, retain) NSString * alias;
@property (nonatomic, retain) NSNumber * port;
@property (nonatomic, retain) NSNumber * isRunning;
@property (nonatomic, retain) NSNumber * runOnStartUp;
@property (nonatomic, retain) NSString * loglevel;
@property (retain) NSTask* instance;

@end
