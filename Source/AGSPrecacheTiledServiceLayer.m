//
//  AGSPrecacheTiledServiceLayer.m
//  tiled-layer-generic
//
//  Created by Nicholas Furness on 10/1/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "AGSPrecacheTiledServiceLayer.h"

typedef enum {
    AGSTileLoadingStateNone,
    AGSTileLoadingStateLoading,
    AGSTileLoadingStateLoaded,
    AGSTileLoadingStateCached,
    AGSTileLoadingStateFailed
} AGSTileLoadingState;

#pragma mark - Precache Tile Operation Delegate Potocol
@class AGSPrecachedTileOperation;

@protocol AGSPrecachedTileOperationDelegate <NSObject>
-(void)precacheTileOperation:(AGSPrecachedTileOperation *)operation
                      loaded:(BOOL)loaded
                    tileData:(NSData *)tileData
                  forTileKey:(AGSTileKey *)tileKey;
@end

@interface AGSPrecacheTiledServiceLayer () <AGSPrecachedTileOperationDelegate, AGSLayerDelegate>
@property (nonatomic, strong) NSMutableDictionary *cachedTiles;
@property (nonatomic, strong) NSMutableDictionary *lodsByLevel;
-(void)cacheData:(NSData *)tileData forTileKey:(AGSTileKey *)key;
-(NSData *)cachedDataForTileKey:(AGSTileKey *)key;
-(NSArray *)adjacentKeysToKey:(AGSTileKey *)key;
-(NSArray *)adjacentUncachedKeysToKey:(AGSTileKey *)key;
@end

@interface AGSPrecacheTiledCacheEntry : NSObject
@property (nonatomic, strong) NSData *tileData;
@property (nonatomic, strong, readonly) AGSTileKey *tileKey;
@property (nonatomic, strong, readonly) NSDate *created;
@property (nonatomic, strong, readonly) NSDate *lastAccessed;
@property (nonatomic, assign) AGSTileLoadingState loadingState;
+(AGSPrecacheTiledCacheEntry *)tiledCacheEntry:(NSData *)tileData forKey:(AGSTileKey *)key;
@end

@implementation AGSPrecacheTiledCacheEntry
@synthesize tileData = _tileData;

-(id)initWithTileData:(NSData *)tileData forKey:(AGSTileKey *)key
{
    self = [super init];
    if (self) {
        _tileKey = key;
        _created = [NSDate date];
        _lastAccessed = [NSDate date];
        self.tileData = tileData;
    }
    return self;
}

+(AGSPrecacheTiledCacheEntry *)tiledCacheEntry:(NSData *)tileData forKey:(AGSTileKey *)key
{
    AGSPrecacheTiledCacheEntry *entry = [[AGSPrecacheTiledCacheEntry alloc] initWithTileData:tileData
                                                                                      forKey:key];
    return entry;
}

-(void)setTileData:(NSData *)tileData
{
    _tileData = tileData;
    _loadingState = _tileData?AGSTileLoadingStateLoaded:AGSTileLoadingStateNone;
}

-(NSData *)tileData
{
    _lastAccessed = [NSDate date];
    return _tileData;
}
@end

#pragma mark - AGSTileKey Category
@interface AGSTileKey (AGSPrecacheLayer)
-(NSString *)uniqueKeyForLayer;
@end

@implementation AGSTileKey (AGSPrecacheLayer)
-(NSString *)uniqueKeyForLayer
{
    return [NSString stringWithFormat:@"%d.%d.%d", self.level, self.column, self.row];
}
@end

#pragma mark - Precache Tile Operation
@interface AGSPrecachedTileOperation : NSOperation
-(id)initWithTileKey:(AGSTileKey *)tileKey
        forBaseLayer:(AGSTiledLayer *)baseLayer
         forDelegate:(id<AGSPrecachedTileOperationDelegate>)target
     alsoGetAdjacent:(BOOL)getAdjacent;
@property (nonatomic, strong, readonly) AGSTileKey *tileKey;
@property (nonatomic, strong) AGSTiledServiceLayer *baseLayer;
@property (nonatomic, weak) id<AGSPrecachedTileOperationDelegate> delegate;
@property (nonatomic, assign) BOOL getAdjacent;
@end

@implementation AGSPrecachedTileOperation
-(id)initWithTileKey:(AGSTileKey *)tileKey
        forBaseLayer:(AGSTiledServiceLayer *)baseLayer
         forDelegate:(id<AGSPrecachedTileOperationDelegate>)target
     alsoGetAdjacent:(BOOL)getAdjacent
{
    self = [super init];
    if (self)
    {
        _tileKey = tileKey;
        _baseLayer = baseLayer;
        _getAdjacent = getAdjacent;
        self.delegate = target;
    }
    return self;
}

-(BOOL)isConcurrent
{
    return YES;
}

-(void)callDelegateWithData:(NSData *)data forKey:(AGSTileKey *)tileKey wasLoaded:(BOOL)loaded
{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(precacheTileOperation:loaded:tileData:forTileKey:)])
    {
        [self.delegate precacheTileOperation:self
                                      loaded:loaded
                                    tileData:data
                                  forTileKey:tileKey];
    }
}

-(void)main
{
    if (self.isCancelled)
    {
        return;
    }
    
    NSData *myTileData = nil;

    BOOL foundCachedData = NO;
    
    AGSPrecacheTiledServiceLayer *dataSource = nil;
    if ([self.delegate isKindOfClass:[AGSPrecacheTiledServiceLayer class]])
    {
        dataSource = (AGSPrecacheTiledServiceLayer *)self.delegate;
    }
    
//    NSLog(@"Looking for tile data: %@", self.tileKey.uniqueKeyForLayer);

    if (dataSource)
    {
        // This could happen if we've been queued multiple times and in the meantime
        // the data has come back and a cache entry has been created.
        myTileData = [dataSource cachedDataForTileKey:self.tileKey];
        if (myTileData) {
            // There was cached data.
            NSLog(@"Found cached tile: %@", self.tileKey.uniqueKeyForLayer);
            foundCachedData = YES;
            
            [self callDelegateWithData:myTileData forKey:self.tileKey wasLoaded:NO];
        } else {
//            NSLog(@"No cached data for tile %@", self.tileKey.uniqueKeyForLayer);
        }
    }

    if (!foundCachedData)
    {
        // No cached data. Let's load the layer.
        @try {
//            NSLog(@"Getting tile: %@", self.tileKey.uniqueKeyForLayer);
            NSURL *tileUrl = [self.baseLayer urlForTileKey:self.tileKey];
            NSURLRequest *req = [NSURLRequest requestWithURL:tileUrl];
            NSURLResponse *resp = nil;
            NSError *error = nil;
            myTileData = [NSURLConnection sendSynchronousRequest:req
                                               returningResponse:&resp
                                                           error:&error];
            NSLog(@"Loaded uncached tile: %@", self.tileKey.uniqueKeyForLayer);
            if (error)
            {
                NSLog(@"Error getting tile %@ from %@: %@", self.tileKey, tileUrl, error);
                return;
            }
    //        NSLog(@"Got tile: %@", self.tileKey.uniqueKeyForLayer);
            if (self.isCancelled)
            {
                NSLog(@"Cancelled: %@", self.tileKey.uniqueKeyForLayer);
                return;
            }

            if (dataSource)
            {
                [dataSource cacheData:myTileData forTileKey:self.tileKey];
            }
            [self callDelegateWithData:myTileData forKey:self.tileKey wasLoaded:YES];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception getting tile %@: %@", self.tileKey, exception);
        }
    }
    
    if (dataSource && self.getAdjacent)
    {
        NSArray *adjacentTiles = [dataSource adjacentUncachedKeysToKey:self.tileKey];
        for (AGSTileKey *k in adjacentTiles)
        {
            NSLog(@"   Precaching adjacent tile: %@", k.uniqueKeyForLayer);
            AGSPrecachedTileOperation *op =
            [[AGSPrecachedTileOperation alloc] initWithTileKey:k
                                                  forBaseLayer:_baseLayer
                                                   forDelegate:dataSource
                                               alsoGetAdjacent:NO];
            
            [[AGSRequestOperation sharedOperationQueue] addOperation:op];
        }
    }
}
@end

#pragma mark - AGSPrecacheTiledServiceLayer
@implementation AGSPrecacheTiledServiceLayer
-(id)initWithTiledLayer:(AGSTiledServiceLayer *)wrappedTiledLayer
{
    self = [super init];
    if (self) {
        _wrappedTiledLayer = wrappedTiledLayer;
        _wrappedTiledLayer.delegate = self;
        self.cachedTiles = [NSMutableDictionary dictionary];
        self.lodsByLevel = [NSMutableDictionary dictionary];
    }
    return self;
}

-(void)layerDidLoad:(AGSLayer *)layer
{
    if (layer == _wrappedTiledLayer)
    {
        for (AGSLOD *lod in _wrappedTiledLayer.tileInfo.lods) {
            [self.lodsByLevel setObject:lod
                                 forKey:[NSNumber numberWithInteger:lod.level]];
        }
        [self layerDidLoad];
    }
}

-(AGSTileInfo *)tileInfo
{
    return _wrappedTiledLayer.tileInfo;
}

-(AGSEnvelope *)fullEnvelope
{
    return _wrappedTiledLayer.fullEnvelope;
}

-(AGSEnvelope *)initialEnvelope
{
    return _wrappedTiledLayer.initialEnvelope;
}

-(AGSSpatialReference *)spatialReference
{
    return _wrappedTiledLayer.spatialReference;
}

-(void)requestTileForKey:(AGSTileKey *)key
{
    NSLog(@"Map asked for %@", key.uniqueKeyForLayer);
    NSData *tileData = [self cachedDataForTileKey:key];
    if (tileData)
    {
        NSLog(@"Direct return of cached data for %@", key.uniqueKeyForLayer);
        [self setTileData:tileData forKey:key];
    } else {
        NSLog(@"Gotta cache %@", key.uniqueKeyForLayer);
        AGSPrecachedTileOperation *op =
        [[AGSPrecachedTileOperation alloc] initWithTileKey:key
                                              forBaseLayer:_wrappedTiledLayer
                                               forDelegate:self
                                           alsoGetAdjacent:YES];
        NSLog(@"Created operation for %@", key.uniqueKeyForLayer);

        [[AGSRequestOperation sharedOperationQueue] addOperation:op];
        NSLog(@"Added operation to queue for %@", key.uniqueKeyForLayer);
    }
}

-(void)cancelRequestForKey:(AGSTileKey *)key
{
    NSLog(@"Cancel request for key: %@", key);
    for (id op in [AGSRequestOperation sharedOperationQueue].operations)
    {
        if ([op isKindOfClass:[AGSPrecachedTileOperation class]])
        {
            if ([((AGSPrecachedTileOperation *)op).tileKey isEqualToTileKey:key])
            {
                NSLog(@"Found operation. Cancelling…");
                [((AGSPrecachedTileOperation *)op) cancel];
                return;
            }
        }
    }
    [_wrappedTiledLayer cancelRequestForKey:key];
}

-(NSData *)cachedDataForTileKey:(AGSTileKey *)key
{
    @synchronized(self.cachedTiles)
    {
        return [[self.cachedTiles objectForKey:key.uniqueKeyForLayer] tileData];
    }
}

-(void)cacheData:(NSData *)tileData forTileKey:(AGSTileKey *)key
{
    if (tileData)
    {
        @synchronized(self.cachedTiles)
        {
            AGSPrecacheTiledCacheEntry *cacheEntry = self.cachedTiles[key.uniqueKeyForLayer];
            if (!cacheEntry)
            {
                cacheEntry = [AGSPrecacheTiledCacheEntry tiledCacheEntry:tileData forKey:key];
                [self.cachedTiles setObject:cacheEntry forKey:key.uniqueKeyForLayer];
            }
            else
            {
                cacheEntry.tileData = tileData;
            }
        }
    }
}

-(void)precacheTileOperation:(AGSPrecachedTileOperation *)operation
                      loaded:(BOOL)loaded
                    tileData:(NSData *)tileData
                  forTileKey:(AGSTileKey *)tileKey
{
    // Our operation got some tile data
    if (!operation.isCancelled)
    {
        if (loaded)
        {
            [self cacheData:tileData forTileKey:tileKey];
        }

        // And return the tile
        [self setTileData:tileData forKey:tileKey];
    }
}

-(NSArray *)adjacentKeysToKey:(AGSTileKey *)key
{
    NSMutableArray *adjacentKeys = [NSMutableArray array];
    NSInteger lCol = key.column - 1;
    NSInteger rCol = key.column + 1;
    NSInteger bRow = key.row - 1;
    NSInteger tRow = key.row + 1;

    AGSLOD *thisLOD = self.lodsByLevel[[NSNumber numberWithInteger:key.level]];

    if (lCol < (NSInteger)thisLOD.startTileColumn)
    {
        lCol = thisLOD.endTileColumn;
    }
    if (rCol > thisLOD.endTileColumn)
    {
        rCol = thisLOD.startTileColumn;
    }
    if (bRow < (NSInteger)thisLOD.startTileRow)
    {
        bRow = thisLOD.endTileRow;
    }
    if (tRow > thisLOD.endTileRow)
    {
        tRow = thisLOD.startTileRow;
    }
    // Now get a set of keys and add them to the array
    for (NSInteger r = bRow; r <= tRow; r++)
    {
        for (NSInteger c = lCol; c <= rCol; c++)
        {
            if (c != key.column || r != key.row)
            {
                [adjacentKeys addObject:[AGSTileKey tileKeyWithColumn:c row:r level:key.level]];
            }
        }
    }
    return adjacentKeys;
}

-(NSArray *)adjacentUncachedKeysToKey:(AGSTileKey *)key
{
    return [[self adjacentKeysToKey:key] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        AGSTileKey *thisKey = evaluatedObject;
        return ([self cachedDataForTileKey:thisKey] == nil);
    }]];
}
@end
