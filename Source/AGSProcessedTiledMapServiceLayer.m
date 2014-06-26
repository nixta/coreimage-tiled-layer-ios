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
@end

@implementation AGSProcessedTiledMapServiceLayer
@synthesize context = _context;

#pragma mark - Predefined Filter Blocks
+(AGSCITileProcessingBlock)sepiaBlockWithIntensity:(double)intensity
{
    return ^(CIContext *context, NSData *tileData){
        CIImage *i = [CIImage imageWithData:tileData];
        
        CIContext *context_int = [CIContext contextWithOptions:nil];
        
        CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"
                                      keysAndValues:kCIInputImageKey, i,
                            @"inputIntensity", [NSNumber numberWithDouble:intensity], nil];
        CIImage *result = [filter valueForKey:kCIOutputImageKey];
        CGImageRef cgiRef = [context_int createCGImage:result fromRect:[result extent]];
        UIImage *outImage = [UIImage imageWithCGImage:cgiRef];
        CGImageRelease(cgiRef);
        return UIImagePNGRepresentation(outImage);
    };
}

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

#pragma mark - Initializers with existing Tiled Layer
-(id)initWithTiledLayer:(AGSTiledServiceLayer *)wrappedTiledLayer
    processingTilesWithBlock:(AGSCITileProcessingBlock)block
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
    self = [super init];
    if (self) {
        _wrappedTiledLayer = wrappedTiledLayer;
        _wrappedTiledLayer.delegate = self;
        self.processBlock = [AGSProcessedTiledMapServiceLayer blockWithCIFilter:filter];
    }
    return self;
}

#pragma mark - Initializers with URLs
-(id)initWithURL:(NSURL *)tiledLayerURL credential:(AGSCredential *)cred processingTilesWithBlock:(AGSCITileProcessingBlock)block
{
    return [self initWithTiledLayer:[AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:tiledLayerURL credential:cred]
           processingTilesWithBlock:block];
}

-(id)initWithURL:(NSURL *)tiledLayerURL processingTilesWithBlock:(AGSCITileProcessingBlock)block
{
    return [self initWithURL:tiledLayerURL credential:nil processingTilesWithBlock:block];
}

+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)tiledLayerURL processingTilesWithBlock:(AGSCITileProcessingBlock)block
{
    return [[AGSProcessedTiledMapServiceLayer alloc] initWithURL:tiledLayerURL
                                          processingTilesWithBlock:block];
}

+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)tiledLayerURL credential:(AGSCredential *)credential processingTilesWithBlock:(AGSCITileProcessingBlock)block
{
    return [[AGSProcessedTiledMapServiceLayer alloc] initWithURL:tiledLayerURL
                                                        credential:credential
                                          processingTilesWithBlock:block];
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
    AGSGenericTileOperation *op =
    [[AGSGenericTileOperation alloc] initWithTileKey:key
                                        forTiledLayer:_wrappedTiledLayer
                                         forDelegate:self];
    
    [[AGSRequestOperation sharedOperationQueue] addOperation:op];
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
@end
