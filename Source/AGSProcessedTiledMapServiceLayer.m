//
//  AGSTileLayerGeneric.m
//  tiled-layer-generic
//
//  Created by Nicholas Furness on 8/3/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "AGSProcessedTiledMapServiceLayer.h"
#import <ArcGIS/AGSTiledServiceLayer+Subclass.h>
#import <objc/runtime.h>

#define kWrapperAssociatedObjectKey @"wrappingLayer"

#pragma mark - Generic Tile Operation Delegate Potocol
@class AGSCIProcessedTileOperation;

@protocol AGSCIProcessedTileOperationDelegate <NSObject>
-(void)genericTileOperation:(AGSCIProcessedTileOperation *)operation
             loadedTileData:(NSData *)tileData
                 forTileKey:(AGSTileKey *)tileKey;
@end

#pragma mark - Generic Tile Operation 
@interface AGSCIProcessedTileOperation : NSOperation
-(id)initWithTileKey:(AGSTileKey *)tileKey
        forBaseLayer:(AGSTiledLayer *)baseLayer
         forDelegate:(id<AGSCIProcessedTileOperationDelegate>)target;
@property (nonatomic, strong, readonly) AGSTileKey *tileKey;
@property (nonatomic, strong) AGSTiledServiceLayer *baseLayer;
@property (nonatomic, weak) id<AGSCIProcessedTileOperationDelegate> delegate;
@end

@implementation AGSCIProcessedTileOperation
-(id)initWithTileKey:(AGSTileKey *)tileKey
        forBaseLayer:(AGSTiledServiceLayer *)baseLayer
         forDelegate:(id<AGSCIProcessedTileOperationDelegate>)target
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
    
    @try {
        NSLog(@"Getting tile: %@", self.tileKey);
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
        NSLog(@"Got tile: %@", self.tileKey);
        if (self.isCancelled)
        {
            NSLog(@"Cancelled: %@", self.tileKey);
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
                [self.delegate respondsToSelector:@selector(genericTileOperation:loadedTileData:forTileKey:)])
            {
                [self.delegate genericTileOperation:self
                                     loadedTileData:myTileData
                                         forTileKey:self.tileKey];
            }
        }
    }
}
@end


#pragma mark - Generic Tiled Layer
@interface AGSProcessedTiledMapServiceLayer() <AGSCIProcessedTileOperationDelegate, AGSLayerDelegate>
@property (atomic, strong, readonly) CIContext *context;
@end

@implementation AGSProcessedTiledMapServiceLayer
@synthesize context = _context;

+(AGSCITileProcessingBlock)sepiaBlockWithIntensity:(double)intensity
{
    return [^(CIContext *context, NSData *tileData){
//        NSLog(@"tileData is nil: %@", tileData == nil?@"YES":@"NO");
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
    } copy];
}

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

-(void)cancelRequestForKey:(AGSTileKey *)key
{
    NSLog(@"Cancel request for key: %@", key);
    for (id op in [AGSRequestOperation sharedOperationQueue].operations)
    {
        if ([op isKindOfClass:[AGSCIProcessedTileOperation class]])
        {
            if ([((AGSCIProcessedTileOperation *)op).tileKey isEqualToTileKey:key])
            {
                NSLog(@"Found operation. Cancelling…");
                [((AGSCIProcessedTileOperation *)op) cancel];
                return;
            }
        }
    }
    [_wrappedTiledLayer cancelRequestForKey:key];
}

-(void)requestTileForKey:(AGSTileKey *)key
{
    NSLog(@"RequestTileForKey: %@", key);
    AGSCIProcessedTileOperation *op =
        [[AGSCIProcessedTileOperation alloc] initWithTileKey:key
                                            forBaseLayer:_wrappedTiledLayer
                                             forDelegate:self];
    
    [[AGSRequestOperation sharedOperationQueue] addOperation:op];
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

-(void)genericTileOperation:(AGSCIProcessedTileOperation *)operation
             loadedTileData:(NSData *)tileData
                 forTileKey:(AGSTileKey *)tileKey
{
    if (!operation.isCancelled)
    {
        [self setTileData:self.processBlock(self.context, tileData) forKey:tileKey];
    }
}
@end
