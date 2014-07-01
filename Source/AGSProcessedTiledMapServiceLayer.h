//
//  AGSProcessedTiledMapServiceLayer.h
//  tiled-layer-generic
//
//  Created by Nicholas Furness on 8/3/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>


// Return PNG NSData for a UIImage as returned by UIImagePNGRepresentation(). Pass in NSData for a UIImage.
typedef NSData *(^AGSCITileProcessingBlock)(NSData*);


@interface AGSProcessedTiledMapServiceLayer : AGSTiledServiceLayer
@property (nonatomic, strong, readonly) AGSTiledServiceLayer * wrappedTiledLayer;

#pragma mark - Generators with CIFilter
+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)url imageFilter:(CIFilter *)filter;
+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)url credential:(AGSCredential *)cred imageFilter:(CIFilter *)filter;
+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithTiledLayer:(AGSTiledServiceLayer *)tiledLayer imageFilter:(CIFilter *)filter;

#pragma mark - Generators with array of CIFilters
+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)url imageFilters:(NSArray *)filters;
+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)url credential:(AGSCredential *)cred imageFilters:(NSArray *)filters;
+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithTiledLayer:(AGSTiledServiceLayer *)tiledLayer imageFilters:(NSArray *)filters;

#pragma mark - Generators with fully custom AGSCITileProcessingBlock
+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)url processingTilesWithBlock:(AGSCITileProcessingBlock)block;
+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)url credential:(AGSCredential *)cred processingTilesWithBlock:(AGSCITileProcessingBlock)block;
+(AGSProcessedTiledMapServiceLayer *)tiledLayerWithTiledLayer:(AGSTiledServiceLayer *)tiledLayer processingTilesWithBlock:(AGSCITileProcessingBlock)block;
@end