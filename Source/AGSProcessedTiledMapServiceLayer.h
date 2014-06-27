//
//  AGSTileLayerGeneric.h
//  tiled-layer-generic
//
//  Created by Nicholas Furness on 8/3/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>


// Return PNG NSData for a UIImage as returned by UIImagePNGRepresentation()
typedef NSData *(^AGSCITileProcessingBlock)(CIContext *context, NSData*);



@interface AGSProcessedTiledMapServiceLayer : AGSTiledServiceLayer
@property (nonatomic, strong, readonly) AGSTiledServiceLayer * wrappedTiledLayer;

#pragma mark - Generators with CIFilter
+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)tiledLayerURL
                                           imageFilter:(CIFilter *)filter;
+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)tiledLayerURL
                                            credential:(AGSCredential *)credential
                                           imageFilter:(CIFilter *)filter;
+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithTiledLayer:(AGSTiledServiceLayer *)tiledLayer
                                                  imageFilter:(CIFilter *)filter;

#pragma mark - Generators with full processing block
+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)tiledLayerURL
                              processingTilesWithBlock:(AGSCITileProcessingBlock)block;
+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)tiledLayerURL
                                            credential:(AGSCredential *)credential
                              processingTilesWithBlock:(AGSCITileProcessingBlock)block;
+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithTiledLayer:(AGSTiledServiceLayer *)tiledLayer
                                     processingTilesWithBlock:(AGSCITileProcessingBlock)block;
@end