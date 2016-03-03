//
//  JLCoreDataHelper.m
//
//  Version 0.2.0
//
//  Created by Joey L. on 7/23/15.
//  Copyright (c) 2015 Joey L. All rights reserved.
//
//  https://github.com/buhikon/JLCoreDataHelper
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#import "JLCoreDataHelper.h"
#import <objc/runtime.h>

@interface JLCoreDataHelper ()
@property (strong, nonatomic) NSString *dataModelName;
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSManagedObjectContext *> *managedObjectContextPool;
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSPersistentStoreCoordinator *> *persistentStoreCoordinatorPool;
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSString *> *entityStoreTypePool;
@end

@implementation JLCoreDataHelper

static JLCoreDataHelper *instance = nil;

#pragma mark -
#pragma mark singleton

+ (JLCoreDataHelper *)sharedInstance
{
    @synchronized(self)
    {
        if (!instance)
            instance = [[JLCoreDataHelper alloc] init];
        
        return instance;
    }
}

#pragma mark - accessor

- (NSMutableDictionary<NSString *, NSManagedObjectContext *> *)managedObjectContextPool
{
    if(!_managedObjectContextPool) {
        _managedObjectContextPool = [[NSMutableDictionary<NSString *, NSManagedObjectContext *> alloc] init];
    }
    return _managedObjectContextPool;
}

- (NSMutableDictionary<NSString *, NSPersistentStoreCoordinator *> *)persistentStoreCoordinatorPool
{
    if(!_persistentStoreCoordinatorPool) {
        _persistentStoreCoordinatorPool = [[NSMutableDictionary<NSString *, NSPersistentStoreCoordinator *> alloc] init];
    }
    return _persistentStoreCoordinatorPool;
}

- (NSMutableDictionary<NSString *, NSString *> *)entityStoreTypePool
{
    if(!_entityStoreTypePool) {
        _entityStoreTypePool = [[NSMutableDictionary<NSString *, NSString *> alloc] init];
    }
    return _entityStoreTypePool;
}

#pragma mark - public methods

+ (void)initializeWithDataModelName:(NSString *)dataModelName
{
    [JLCoreDataHelper sharedInstance].dataModelName = dataModelName;
}
+ (void)setStoreType:(JLCoreDataStoreType)storeType forEntity:(NSString *)entityName {

    NSString *storeTypeStr = nil;
    switch (storeType) {
        case JLCoreDataStoreTypeSQLite: {
            storeTypeStr = NSSQLiteStoreType;
            break;
        }
#ifdef JLCOREDATAHELPER_MACOS
        case JLCoreDataStoreTypeXML: {
            storeTypeStr = NSXMLStoreType;
            break;
        }
#endif
        case JLCoreDataStoreTypeBinary: {
            storeTypeStr = NSBinaryStoreType;
            break;
        }
        case JLCoreDataStoreTypeMemory: {
            storeTypeStr = NSInMemoryStoreType;
            break;
        }
        default: {
            break;
        }
    }
    
    
    if(entityName.length > 0 && storeTypeStr.length > 0) {
        [[JLCoreDataHelper sharedInstance].entityStoreTypePool setObject:storeTypeStr forKey:entityName];
    }
    
}

#pragma mark -get

- (NSMutableArray *)getObjectsWithEntity:(NSString *)entityName
{
    return [self getObjectsWithCondition:nil
                             sortingKeys:nil
                               ascending:YES
                                  entity:entityName];
}
- (NSMutableArray *)getObjectsWithCondition:(NSString *)condition
                                     entity:(NSString *)entityName
{
    return [self getObjectsWithCondition:condition
                             sortingKeys:nil
                               ascending:YES
                                  entity:entityName];
}
- (NSMutableArray *)getObjectsWithCondition:(NSString *)condition
                                sortingKeys:(NSArray *)skeys
                                     entity:(NSString *)entityName
{
    return [self getObjectsWithCondition:condition
                             sortingKeys:skeys
                               ascending:YES
                                  entity:entityName];
}
- (NSMutableArray *)getObjectsWithCondition:(NSString *)condition
                                sortingKeys:(NSArray *)skeys
                                  ascending:(BOOL)ascending
                                     entity:(NSString *)entityName
{
    NSMutableArray *resultList = nil;
    @try
    {
        NSFetchRequest *retrieveRequest = [[NSFetchRequest alloc] init];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:[self managedObjectContextForEntity:entityName]];
        
        retrieveRequest.entity = entity;
        
        if (condition != nil && [condition length] > 0)
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:condition];
            [retrieveRequest setPredicate:predicate];
        }
        
        if (skeys != nil)
        {
            NSMutableArray *sortDescriptors = [[NSMutableArray alloc] init];
            for(NSString* sortKey in skeys) {
                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKey ascending:ascending];
                [sortDescriptors addObject:sortDescriptor];
            }
            [retrieveRequest setSortDescriptors:sortDescriptors];
        }
        
        resultList = [[self executeFetch:retrieveRequest entity:entityName] mutableCopy];
        //		[retrieveRequest release];
        retrieveRequest = nil;
        
        if (resultList == nil)
        {
            NSLog(@"%s: [%@] error", __FUNCTION__, entityName);
            return nil;
        }
        else
        {
            if ([resultList count] == 0)
            {
                return nil;
            }
        }
    }
    @catch (NSException *e)
    {
        NSLog(@"%s: [%@] %@:%@", __FUNCTION__, entityName, e.name, e.reason);
    }
    return resultList;
}

#pragma mark -set, update

// create if not exists,
// update (only) **FIRST** item if exists
- (id)set:(NSDictionary *)keyValue condition:(NSString *)condition entityName:(NSString *)entityName
{
    NSArray *arr = [self getObjectsWithCondition:condition sortingKeys:nil entity:entityName];
    id obj = nil;
    if(arr.count == 0) {
        obj = [self create:keyValue entityName:entityName];
    }
    else {
        obj = arr[0];
        [obj setValuesForKeysWithDictionary:keyValue];
    }
    [self saveContextForEntity:entityName];
    
    return obj;
}

// update all objs which matchs the condition in the entity
- (void)update:(NSDictionary *)keyValue condition:(NSString *)condition entityName:(NSString *)entityName
{
    NSArray *arr = [self getObjectsWithCondition:condition sortingKeys:nil entity:entityName];
    if(arr.count > 0) {
        for (id obj in arr) {
            [obj setValuesForKeysWithDictionary:keyValue];
        }
        [self saveContextForEntity:entityName];
    }
}

#pragma mark -create

- (id)create:(NSDictionary *)newValue entityName:(NSString *)entityName
{
    id obj = [self createWithoutSaving:newValue entityName:entityName];
    [self saveContextForEntity:entityName];
    return obj;
    
}
- (id)createWithoutSaving:(NSDictionary *)newValue entityName:(NSString *)entityName
{
    id obj = nil;
    @try {
        obj = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                            inManagedObjectContext:[self managedObjectContextForEntity:entityName]];
        
        if (newValue != nil) {
            NSEnumerator *enumerator = [newValue keyEnumerator];
            id key = [enumerator nextObject];
            for (; key != nil; key = [enumerator nextObject]) {
                @try {
                    [obj setValue:newValue[key] forKey:key];
                }
                @catch(NSException *e) {
                    NSLog(@"Exception : %@", e);
                }
            }
        }
    }
    @catch (NSException *e) {
        NSLog(@"Exception : %@", e);
    }
    return obj;
}
- (id)createForEntityName:(NSString *)entityName initBlock:(void(^)(id newObject))initBlock
{
    id obj = nil;
    @try {
        obj = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                            inManagedObjectContext:[self managedObjectContextForEntity:entityName]];
        if(initBlock) {
            initBlock(obj);
        }
    }
    @catch (NSException *e) {
        NSLog(@"Exception : %@", e);
    }
    
    [self saveContextForEntity:entityName];
    
    return obj;
}

#pragma mark -delete

- (BOOL)deleteObject:(id)object
{
    for (NSManagedObjectContext *managedObjectContext in self.managedObjectContextPool) {
        @try {
            [managedObjectContext deleteObject:object];
            [self saveContextForManagedObjectContext:managedObjectContext];
        }
        @catch (NSException *e) {
            NSLog(@"Exception : %@", e);
        }
    }
}
- (void)deleteAllObjectsForEntityName:(NSString *)entityName {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                              inManagedObjectContext:[self managedObjectContextForEntity:entityName]];
    fetchRequest.entity = entity;
    
    NSArray *items = [self executeFetch:fetchRequest entity:entityName];
    fetchRequest = nil;
    
    for (NSManagedObject *managedObject in items) {
        [[self managedObjectContextForEntity:entityName] deleteObject:managedObject];
    }
    [self saveContextForEntity:entityName];
}

#pragma mark -singleton entity

- (id)getFirstObjectWithAttributeName:(NSString *)attributeName
                           entityName:(NSString *)entityName
{
    id result = nil;
    NSArray *arr = [self getObjectsWithCondition:nil sortingKeys:nil entity:entityName];
    if(arr.count > 0) {
        id obj = arr[0];
        result = [obj valueForKey:attributeName];
    }
    return result;
}

- (void)setFirstObject:(id)obj
          attibuteName:(NSString *)attibuteName
            entityName:(NSString *)entityName
{
    // (* argument obj can be nil.)
    if(attibuteName && entityName) {
        // update
        NSArray *arr = [self getObjectsWithCondition:nil sortingKeys:nil entity:entityName];
        if(arr.count > 0) {
            id objInArr = arr[0];
            [objInArr setValue:obj forKey:attibuteName];
            [self saveContextForEntity:entityName];
        }
        else {
            // create single object (when first access)
            [self create:@{attibuteName:obj} entityName:entityName];
        }
    }
}

- (void)deleteFirstObjectForAttributeName:(NSString *)attibuteName
                               entityName:(NSString *)entityName
{
    [self setFirstObject:nil
            attibuteName:attibuteName
              entityName:entityName];
}

#pragma mark - private methods

- (NSDictionary *)dictionaryForObject:(id)obj
{
    unsigned int count = 0;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    objc_property_t *properties = class_copyPropertyList([obj class], &count);
    
    for (NSInteger i=0; i<count; i++) {
        NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
        id value = [obj valueForKey:key];
        if (value) {
            [dict setObject:value forKey:key];
        }
    }
    free(properties);
    
    return dict;
}

#pragma mark - Core Data stack

@synthesize managedObjectModel = _managedObjectModel;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses an application directory in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:self.dataModelName withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// * storeType : NSSQLiteStoreType, NSXMLStoreType, NSBinaryStoreType, NSInMemoryStoreType
- (NSPersistentStoreCoordinator *)createPersistentStoreCoordinatorForStoreType:(NSString *)storeType {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    
    // Create the coordinator and store
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", self.dataModelName]];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                             nil];
    NSError *error = nil;
    if (![persistentStoreCoordinator addPersistentStoreWithType:storeType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:options
                                                           error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = @"There was an error creating or loading the application's saved data.";;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return persistentStoreCoordinator;
}

// * storeType : NSSQLiteStoreType, NSXMLStoreType, NSBinaryStoreType, NSInMemoryStoreType
- (NSManagedObjectContext *)createManagedObjectContextForStoreType:(NSString *)storeType {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinatorForStoreType:storeType];
    if (!coordinator) {
        return nil;
    }
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [managedObjectContext setPersistentStoreCoordinator:coordinator];
    return managedObjectContext;
}

#pragma mark -

- (NSString *)storeTypeForEntity:(NSString *)entityName {
    
    NSString *storeType = self.entityStoreTypePool[entityName];
    if(!storeType) {
        storeType = NSSQLiteStoreType;
    }
    return storeType;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinatorForEntity:(NSString *)entityName {
    NSString *storeType = [self storeTypeForEntity:entityName];
    return [self persistentStoreCoordinatorForStoreType:storeType];
}
- (NSPersistentStoreCoordinator *)persistentStoreCoordinatorForStoreType:(NSString *)storeType {
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [self.persistentStoreCoordinatorPool objectForKey:storeType];
    if(!persistentStoreCoordinator) {
        persistentStoreCoordinator = [self createPersistentStoreCoordinatorForStoreType:storeType];
        [self.persistentStoreCoordinatorPool setObject:persistentStoreCoordinator forKey:storeType];
    }
    return persistentStoreCoordinator;
}
- (NSManagedObjectContext *)managedObjectContextForEntity:(NSString *)entityName {
    NSString *storeType = [self storeTypeForEntity:entityName];
    return [self managedObjectContextForStoreType:storeType];
}
- (NSManagedObjectContext *)managedObjectContextForStoreType:(NSString *)storeType {
    NSManagedObjectContext *managedObjectContext = [self.managedObjectContextPool objectForKey:storeType];
    if(!managedObjectContext) {
        managedObjectContext = [self createManagedObjectContextForStoreType:storeType];
        [self.managedObjectContextPool setObject:managedObjectContext forKey:storeType];
    }
    return managedObjectContext;
}


#pragma mark - Core Data Saving support

- (void)saveContext {
    for (NSManagedObjectContext *managedObjectContext in self.managedObjectContextPool) {
        [self saveContextForManagedObjectContext:managedObjectContext];
    }
}

- (void)saveContextForEntity:(NSString *)entityName {
    NSManagedObjectContext *managedObjectContext = [self managedObjectContextForEntity:entityName];
    [self saveContextForManagedObjectContext:managedObjectContext];
}
- (void)saveContextForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (managedObjectContext != nil) {
        NSError *error = nil;
        @synchronized(self) {
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }
    }
}

//-(void)rollback {
//    [[self managedObjectContext] rollback];
//}

-(NSArray *)executeFetch:(NSFetchRequest *)fetchRequest entity:(NSString *)entityName {
    NSError *error = nil;
    @try {
        [[self persistentStoreCoordinatorForEntity:entityName] lock];
        NSArray *items = [[self managedObjectContextForEntity:entityName] executeFetchRequest:fetchRequest error:&error];
        [[self persistentStoreCoordinatorForEntity:entityName] unlock];
        
        return items;
    }
    @catch (NSException *exception) {
        NSLog(@"%s: %@", __FUNCTION__, [error localizedDescription]);
        @throw exception;
    }
    return nil;
}


@end