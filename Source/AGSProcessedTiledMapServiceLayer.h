//
//  AGSTileLayerGeneric.h
//  tiled-layer-generic
//
//  Created by Nicholas Furness on 8/3/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

typedef NSData *(^AGSCITileProcessingBlock)(CIContext *context, NSData*);

@interface AGSProcessedTiledMapServiceLayer : AGSTiledServiceLayer
@property (nonatomic, strong, readonly) AGSTiledServiceLayer * wrappedTiledLayer;
@property (nonatomic, copy) AGSCITileProcessingBlock processBlock;

+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)tiledLayerURL
                              processingTilesWithBlock:(AGSCITileProcessingBlock)block;
+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)tiledLayerURL
                                            credential:(AGSCredential *)credential
                              processingTilesWithBlock:(AGSCITileProcessingBlock)block;

-(id)initWithURL:(NSURL *)tiledLayerURL processingTilesWithBlock:(AGSCITileProcessingBlock)block;
-(id)initWithURL:(NSURL *)tiledLayerURL credential:(AGSCredential *)credential processingTilesWithBlock:(AGSCITileProcessingBlock)block;

-(id)initWithTiledLayer:(AGSTiledServiceLayer *)wrappedTiledLayer processingTilesWithBlock:(AGSCITileProcessingBlock)block;
-(id)initWithTiledLayer:(AGSTiledServiceLayer *)wrappedTiledLayer andCIFilter:(CIFilter *)filter;

+(AGSCITileProcessingBlock)sepiaBlockWithIntensity:(double)intensity;
+(AGSCITileProcessingBlock)blockWithCIFilter:(CIFilter *)filter;
@end
