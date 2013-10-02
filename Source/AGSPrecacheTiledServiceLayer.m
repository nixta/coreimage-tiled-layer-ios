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
    AGSTileLoadingStateCached
} AGSTileLoadingState;

#pragma mark - Precache Tile Operation Delegate Potocol
@class AGSPrecachedTileOperation;

@protocol AGSPrecachedTileOperationDelegate <NSObject>
-(void)precacheTileOperation:(AGSPrecachedTileOperation *)operation
              loadedTileData:(NSData *)tileData
                  forTileKey:(AGSTileKey *)tileKey;
@end

@interface AGSPrecacheTiledServiceLayer () <AGSPrecachedTileOperationDelegate, AGSLayerDelegate>
@property (nonatomic, strong) NSMutableDictionary *cachedTiles;
@property (nonatomic, strong) NSMutableDictionary *lodsByLevel;
-(NSData *)cachedDataForTileKey:(AGSTileKey *)key;
@end

@interface AGSPrecacheTiledCacheEntry : NSObject
@property (nonatomic, strong, readonly) NSData *tileData;
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
        _tileData = tileData;
        _tileKey = key;
        _created = [NSDate date];
        _lastAccessed = nil;
        _loadingState = tileData?AGSTileLoadingStateLoaded:AGSTileLoadingStateNone;
    }
    return self;
}

+(AGSPrecacheTiledCacheEntry *)tiledCacheEntry:(NSData *)tileData forKey:(AGSTileKey *)key
{
    AGSPrecacheTiledCacheEntry *entry = [[AGSPrecacheTiledCacheEntry alloc] initWithTileData:tileData forKey:key];
    return entry;
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
         forDelegate:(id<AGSPrecachedTileOperationDelegate>)target;
@property (nonatomic, strong, readonly) AGSTileKey *tileKey;
@property (nonatomic, strong) AGSTiledServiceLayer *baseLayer;
@property (nonatomic, weak) id<AGSPrecachedTileOperationDelegate> delegate;
@end

@implementation AGSPrecachedTileOperation
-(id)initWithTileKey:(AGSTileKey *)tileKey
        forBaseLayer:(AGSTiledServiceLayer *)baseLayer
         forDelegate:(id<AGSPrecachedTileOperationDelegate>)target
{
    self = [super init];
    if (self)
    {
        _tileKey = tileKey;
        _baseLayer = baseLayer;
        self.delegate = target;
        NSLog(@"Created Operation");
    }
    return self;
}

-(void)main
{
    if (self.isCancelled)
    {
        return;
    }
    
    NSData *myTileData = nil;
    
    if ([self.delegate isKindOfClass:[AGSPrecacheTiledServiceLayer class]])
    {
        AGSPrecacheTiledServiceLayer *dataSource = (AGSPrecacheTiledServiceLayer *)self.delegate;
        myTileData = [dataSource cachedDataForTileKey:_tileKey];
        if (myTileData) {
            // There was cached data.
            NSLog(@"Found cached tile: %@", _tileKey.uniqueKeyForLayer);
            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(precacheTileOperation:loadedTileData:forTileKey:)])
            {
                [self.delegate precacheTileOperation:self
                                      loadedTileData:myTileData
                                          forTileKey:_tileKey];
            }
            return;
        }
    }

    // No cached data. Let's load the layer.
    @try {
        NSLog(@"Getting tile: %@", self.tileKey.uniqueKeyForLayer);
        NSURL *tileUrl = [self.baseLayer urlForTileKey:self.tileKey];
        NSURLRequest *req = [NSURLRequest requestWithURL:tileUrl];
        NSURLResponse *resp = nil;
        NSError *error = nil;
        myTileData = [NSURLConnection sendSynchronousRequest:req
                                           returningResponse:&resp
                                                       error:&error];
        if (error)
        {
            NSLog(@"Error getting tile %@ from %@: %@", self.tileKey, tileUrl, error);
            return;
        }
        NSLog(@"Got tile: %@", self.tileKey.uniqueKeyForLayer);
        if (self.isCancelled)
        {
            NSLog(@"Cancelled: %@", self.tileKey.uniqueKeyForLayer);
            return;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception getting tile %@: %@", self.tileKey, exception);
    }
    @finally {
        if (!self.isCancelled)
        {
            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(precacheTileOperation:loadedTileData:forTileKey:)])
            {
                [self.delegate precacheTileOperation:self
                                      loadedTileData:myTileData
                                          forTileKey:_tileKey];
            }
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
    NSLog(@"Requested Key: %@", key.uniqueKeyForLayer);
    AGSPrecachedTileOperation *op =
    [[AGSPrecachedTileOperation alloc] initWithTileKey:key
                                          forBaseLayer:_wrappedTiledLayer
                                           forDelegate:self];
    
    [[AGSRequestOperation sharedOperationQueue] addOperation:op];

    NSArray *adjacentTiles = [self adjacentKeysToKey:key];
    for (AGSTileKey *k in adjacentTiles)
    {
        NSLog(@"   Adjacent Key: %@", k.uniqueKeyForLayer);
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
    return [self.cachedTiles objectForKey:key.uniqueKeyForLayer];
}

-(void)cacheData:(NSData *)tileData forTileKey:(AGSTileKey *)key
{
    if (tileData)
    {
        [self.cachedTiles setObject:tileData forKey:key.uniqueKeyForLayer];
    }
}

-(void)precacheTileOperation:(AGSPrecachedTileOperation *)operation
              loadedTileData:(NSData *)tileData
                  forTileKey:(AGSTileKey *)tileKey
{
    if (!operation.isCancelled)
    {
        // Cache the tile
        if (![self cachedDataForTileKey:tileKey])
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
    NSInteger dRow = key.row - 1;
    NSInteger uRow = key.row + 1;
    AGSLOD *thisLOD = self.lodsByLevel[[NSNumber numberWithInteger:key.level]];
    if (lCol < thisLOD.startTileColumn)
    {
        lCol = thisLOD.endTileColumn;
    }
    if (rCol > thisLOD.endTileColumn)
    {
        rCol = thisLOD.startTileColumn;
    }
    if (dRow < thisLOD.startTileRow)
    {
        dRow = thisLOD.endTileRow;
    }
    if (uRow > thisLOD.endTileRow)
    {
        uRow = thisLOD.startTileRow;
    }
    // Now get a set of keys and add them to the array
    for (NSInteger c = lCol; c < rCol; c++)
    {
        for (NSInteger r = uRow; r > dRow; r--)
        {
            if (c != key.column && r != key.row)
            {
                [adjacentKeys addObject:[AGSTileKey tileKeyWithColumn:c row:r level:key.level]];
            }
        }
    }
    return adjacentKeys;
}
@end
