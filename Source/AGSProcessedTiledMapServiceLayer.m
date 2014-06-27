//
//  AGSTileLayerGeneric.m
//  tiled-layer-generic
//
//  Created by Nicholas Furness on 8/3/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "AGSProcessedTiledMapServiceLayer.h"

#import "AGSGenericTileOperation.h"

#define kWrapperAssociatedObjectKey @"wrappingLayer"

#pragma mark - Generic Tile Operation Delegate Potocol
#pragma mark - Generic Tiled Layer
@interface AGSProcessedTiledMapServiceLayer() <AGSGenericTileOperationDelegate, AGSLayerDelegate>
@property (atomic, strong, readonly) CIContext *context;
@property (nonatomic, copy) AGSCITileProcessingBlock processBlock;
@end

@implementation AGSProcessedTiledMapServiceLayer
@synthesize context = _context;


#pragma mark - Convenience Generators with Block
+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)tiledLayerURL processingTilesWithBlock:(AGSCITileProcessingBlock)block
{
    return [AGSProcessedTiledMapServiceLayer tiledLayerWithURL:tiledLayerURL credential:nil processingTilesWithBlock:block];
}

+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)tiledLayerURL credential:(AGSCredential *)credential processingTilesWithBlock:(AGSCITileProcessingBlock)block
{
    AGSTiledServiceLayer *tiledLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:tiledLayerURL credential:credential];
    return [AGSProcessedTiledMapServiceLayer tiledLayerWithTiledLayer:tiledLayer processingTilesWithBlock:block];
}

+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithTiledLayer:(AGSTiledServiceLayer *)tiledLayer processingTilesWithBlock:(AGSCITileProcessingBlock)block {
    return [[AGSProcessedTiledMapServiceLayer alloc] initWithTiledLayer:tiledLayer processingTilesWithBlock:block];
}



#pragma mark - Convenience Generators with Core Image Filter
+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)tiledLayerURL imageFilter:(CIFilter *)filter
{
    return [AGSProcessedTiledMapServiceLayer tiledLayerWithURL:tiledLayerURL credential:nil imageFilter:filter];
}

+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)tiledLayerURL credential:(AGSCredential *)credential imageFilter:(CIFilter *)filter
{
    AGSTiledServiceLayer *tiledLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:tiledLayerURL credential:credential];
    return [AGSProcessedTiledMapServiceLayer tiledLayerWithTiledLayer:tiledLayer imageFilter:filter];
}

+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithTiledLayer:(AGSTiledServiceLayer *)tiledLayer imageFilter:(CIFilter *)filter {
    return [[AGSProcessedTiledMapServiceLayer alloc] initWithTiledLayer:tiledLayer andCIFilter:filter];
}




#pragma mark - Initializers
-(id)initWithTiledLayer:(AGSTiledServiceLayer *)wrappedTiledLayer processingTilesWithBlock:(AGSCITileProcessingBlock)block
{
    self = [super init];
    if (self) {
        _wrappedTiledLayer = wrappedTiledLayer;
        _wrappedTiledLayer.delegate = self;
        self.processBlock = block;
        if (!self.processBlock)
        {
            self.processBlock = ^(CIContext *context, NSData *inputImageData) {
                NSLog(@"Implement a block to process tile data on the way to the map!");
                return inputImageData;
            };
        }
    }
    return self;
}

-(id)initWithTiledLayer:(AGSTiledServiceLayer *)wrappedTiledLayer andCIFilter:(CIFilter *)filter
{
    self = [self initWithTiledLayer:wrappedTiledLayer processingTilesWithBlock:[AGSProcessedTiledMapServiceLayer blockWithCIFilter:filter]];
    return self;
}



#pragma mark - Overrides for Layer Properties
-(void)layerDidLoad:(AGSLayer *)layer
{
    if (layer == _wrappedTiledLayer)
    {
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

#pragma mark - Overrides for Tile Requests
-(void)requestTileForKey:(AGSTileKey *)key
{
    [[AGSRequestOperation sharedOperationQueue] addOperation:[AGSGenericTileOperation tileOperationWithTileKey:key
                                                                                                 forTiledLayer:_wrappedTiledLayer
                                                                                                   forDelegate:self]];
}

-(void)cancelRequestForKey:(AGSTileKey *)key
{
    NSLog(@"Cancel request for key: %@", key);
    for (id op in [AGSRequestOperation sharedOperationQueue].operations)
    {
        if ([op isKindOfClass:[AGSGenericTileOperation class]])
        {
            if ([((AGSGenericTileOperation *)op).tileKey isEqualToTileKey:key])
            {
                NSLog(@"Found operation. Cancelling…");
                [((AGSGenericTileOperation *)op) cancel];
                return;
            }
        }
    }
    [_wrappedTiledLayer cancelRequestForKey:key];
}


#pragma mark - Tile Operation Delegate Method
-(void)genericTileOperation:(AGSGenericTileOperation *)operation
             loadedTileData:(NSData *)tileData
                 forTileKey:(AGSTileKey *)tileKey
{
    if (!operation.isCancelled)
    {
        [self setTileData:self.processBlock(self.context, tileData) forKey:tileKey];
    }
}


#pragma mark - CIContext Management
-(CIContext *)context
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _context = [CIContext contextWithOptions:@{
            kCIContextUseSoftwareRenderer:[NSNumber numberWithBool:NO]
        }];
    });
    return _context;
}


#pragma mark - Predefined Filter Blocks
+(AGSCITileProcessingBlock)blockWithCIFilter:(CIFilter *)filter
{
    return [^(CIContext *context, NSData *tileData){
        CIImage *i = [CIImage imageWithData:tileData];
        
        CIContext *context_int = [CIContext contextWithOptions:nil];
        
        CIFilter *workingFilter = [filter copy];
        [workingFilter setValue:i forKey:kCIInputImageKey];
        
        CIImage *result = [workingFilter valueForKey:kCIOutputImageKey];
        CGImageRef cgiRef = [context_int createCGImage:result fromRect:[result extent]];
        UIImage *outImage = [UIImage imageWithCGImage:cgiRef];
        CGImageRelease(cgiRef);
        return UIImagePNGRepresentation(outImage);
    } copy];
}
@end
