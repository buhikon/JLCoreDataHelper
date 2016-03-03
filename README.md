# JLCoreDataHelper

[![CI Status](http://img.shields.io/travis/Joey L./JLCoreDataHelper.svg?style=flat)](https://travis-ci.org/Joey L./JLCoreDataHelper)


## Installation

JLCoreDataHelper is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "JLCoreDataHelper"
```


## Before Start

1. Create Data Model file. (.xcdatamodeld)
2. Set entities and attributes as you wish.
3. Perform below code at the beginning of app starts. `application:didFinishLaunchingWithOptions:` method is recommended for this.
```
#import <JLCoreDataHelper/JLCoreDataHelper.h>
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [JLCoreDataHelper initializeWithDataModelName:@"Data Model file name here" saveFolderName:@"folder name"]; 
}
```
4. It's possible to set a store type to a specific entity like below:
```
[JLCoreDataHelper setStoreType:JLCoreDataStoreTypeMemory forEntity:@"Entity Name"];
```

## Usage

use below public methods to manage data.

```
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
```



## License

JLCoreDataHelper is available under the MIT license. See the LICENSE file for more info.
