//
//  JLCoreDataHelper.h
//
//  Version 1.0.0
//
//  Created by Joey L. on 7/23/15.
//  Copyright (c) 2015 Joey L. All rights reserved.
//
//  https://github.com/buhikon/JLCoreDataHelper
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface JLCoreDataHelper : NSObject

+ (void)initializeWithDataModelName:(NSString *)dataModelName;
+ (JLCoreDataHelper *)sharedInstance;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

// general queries
- (NSMutableArray *)getObjectsWithCondition:(NSString *)condition
                                sortingKeys:(NSArray *)skeys
                                     entity:(NSString *)entityName;
- (NSMutableArray *)getObjectsWithCondition:(NSString *)condition
                                sortingKeys:(NSArray *)skeys
                                  ascending:(BOOL)ascending
                                     entity:(NSString *)entityName;
- (void)set:(NSDictionary *)keyValue condition:(NSString *)condition entityName:(NSString *)entityName;
- (void)update:(NSDictionary *)keyValue condition:(NSString *)condition entityName:(NSString *)entityName;

- (id)create:(NSDictionary *)newValue entityName:(NSString *)entityName;
- (id)createWithoutSaving:(NSDictionary *)newValue entityName:(NSString *)entityName;

- (BOOL)deleteObject:(id)object;
- (void)deleteAllObjectsForEntityName:(NSString *)entityName;

// (for singleton entity)
- (id)getFirstObjectWithAttributeName:(NSString *)attributeName
                           entityName:(NSString *)entityName;
- (void)setFirstObject:(id)obj
          attibuteName:(NSString *)attibuteName
            entityName:(NSString *)entityName;
- (void)deleteFirstObjectForAttributeName:(NSString *)attibuteName
                               entityName:(NSString *)entityName;

@end
