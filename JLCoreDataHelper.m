//
//  JLCoreDataHelper.m
//
//  Version 1.0.0
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

@interface JLCoreDataHelper ()
@property (strong, nonatomic) NSString *dataModelName;
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

#pragma mark - public methods

+ (void)initializeWithDataModelName:(NSString *)dataModelName
{
    [JLCoreDataHelper sharedInstance].dataModelName = dataModelName;
}

#pragma mark -get

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
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:[self managedObjectContext]];
        
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
        
        resultList = [[self executeFetch:retrieveRequest] mutableCopy];
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
                NSLog(@"%s: [%@] There is no result", __FUNCTION__, entityName);
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
// update first item if exists
- (void)set:(NSDictionary *)keyValue condition:(NSString *)condition entityName:(NSString *)entityName
{
    NSArray *arr = [self getObjectsWithCondition:condition sortingKeys:nil entity:entityName];
    if(arr.count == 0) {
        [self create:keyValue entityName:entityName];
    }
    else {
        id obj = arr[0];
        [obj setValuesForKeysWithDictionary:keyValue];
    }
    [self saveContext];
}

// update all objs which matchs the condition in the entity
- (void)update:(NSDictionary *)keyValue condition:(NSString *)condition entityName:(NSString *)entityName
{
    NSArray *arr = [self getObjectsWithCondition:condition sortingKeys:nil entity:entityName];
    if(arr.count > 0) {
        for (id obj in arr) {
            [obj setValuesForKeysWithDictionary:keyValue];
        }
        [self saveContext];
    }
}

#pragma mark -create

- (id)create:(NSDictionary *)newValue entityName:(NSString *)entityName
{
    id obj = [self createWithoutSaving:newValue entityName:entityName];
    [self saveContext];
    return obj;
    
}
- (id)createWithoutSaving:(NSDictionary *)newValue entityName:(NSString *)entityName
{
    id obj = nil;
    @try {
        obj = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                            inManagedObjectContext:self.managedObjectContext];
        
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

#pragma mark -delete

- (BOOL)deleteObject:(id)object
{
    @try {
        [self.managedObjectContext deleteObject:object];
        [self saveContext];
    }
    @catch (NSException *e) {
        NSLog(@"Exception : %@", e);
    }
}
- (void)deleteAllObjectsForEntityName:(NSString *)entityName {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                              inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = entity;
    
    NSArray *items = [self executeFetch:fetchRequest];
    fetchRequest = nil;
    
    for (NSManagedObject *managedObject in items) {
        [[self managedObjectContext] deleteObject:managedObject];
    }
    [self saveContext];
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
            [self saveContext];
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


#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

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

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", self.dataModelName]];
    NSError *error = nil;
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:nil
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
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
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

-(void)rollback {
    [[self managedObjectContext] rollback];
}

-(NSArray *)executeFetch:(NSFetchRequest *)fetchRequest {
    NSError *error = nil;
    @try {
        [self.persistentStoreCoordinator lock];
        NSArray *items = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
        [self.persistentStoreCoordinator unlock];
        
        return items;
    }
    @catch (NSException *exception) {
        NSLog(@"%s: %@", __FUNCTION__, [error localizedDescription]);
        @throw exception;
    }
    return nil;
}


@end