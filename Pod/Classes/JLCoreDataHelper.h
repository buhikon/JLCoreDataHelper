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

#pragma mark -get
- (NSMutableArray *)getObjectsWithEntity:(NSString *)entityName;
- (NSMutableArray *)getObjectsWithCondition:(NSString *)condition
                                     entity:(NSString *)entityName;
- (NSMutableArray *)getObjectsWithCondition:(NSString *)condition
                                sortingKeys:(NSArray *)skeys
                                     entity:(NSString *)entityName;
- (NSMutableArray *)getObjectsWithCondition:(NSString *)condition
                                sortingKeys:(NSArray *)skeys
                                  ascending:(BOOL)ascending
                                     entity:(NSString *)entityName;

#pragma mark -set, update
- (id)set:(NSDictionary *)keyValue condition:(NSString *)condition entityName:(NSString *)entityName;
- (void)update:(NSDictionary *)keyValue condition:(NSString *)condition entityName:(NSString *)entityName;

#pragma mark -create
- (id)create:(NSDictionary *)newValue entityName:(NSString *)entityName;
- (id)createWithoutSaving:(NSDictionary *)newValue entityName:(NSString *)entityName;
- (id)createForEntityName:(NSString *)entityName initBlock:(void(^)(id newObject))initBlock;

#pragma mark -delete
- (BOOL)deleteObject:(id)object;
- (void)deleteAllObjectsForEntityName:(NSString *)entityName;

#pragma mark -singleton entity
- (id)getFirstObjectWithAttributeName:(NSString *)attributeName
                           entityName:(NSString *)entityName;
- (void)setFirstObject:(id)obj
          attibuteName:(NSString *)attibuteName
            entityName:(NSString *)entityName;
- (void)deleteFirstObjectForAttributeName:(NSString *)attibuteName
                               entityName:(NSString *)entityName;

@end
