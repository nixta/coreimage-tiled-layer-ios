//
//  AGSProcessedTiledMapServiceLayer.h
//  tiled-layer-generic
//
//  Created by Nicholas Furness on 8/3/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

// Return Processed PNG NSData for a UIImage as returned by UIImagePNGRepresentation()
typedef NSData *(^AGSCITileProcessingBlock)(NSData*);

@interface AGSCoreImageFilteredTiledMapServiceLayer : AGSTiledServiceLayer
#pragma mark - Generators with CIFilter
+(AGSCoreImageFilteredTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)url imageFilter:(CIFilter *)filter;
+(AGSCoreImageFilteredTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)url credential:(AGSCredential *)cred imageFilter:(CIFilter *)filter;
+(AGSCoreImageFilteredTiledMapServiceLayer *)tiledLayerWithTiledLayer:(AGSTiledServiceLayer *)tiledLayer imageFilter:(CIFilter *)filter;

#pragma mark - Generators with array of CIFilters
+(AGSCoreImageFilteredTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)url imageFilters:(NSArray *)filters;
+(AGSCoreImageFilteredTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)url credential:(AGSCredential *)cred imageFilters:(NSArray *)filters;
+(AGSCoreImageFilteredTiledMapServiceLayer *)tiledLayerWithTiledLayer:(AGSTiledServiceLayer *)tiledLayer imageFilters:(NSArray *)filters;

#pragma mark - Generators with fully custom AGSCITileProcessingBlock
+(AGSCoreImageFilteredTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)url processBlock:(AGSCITileProcessingBlock)block;
+(AGSCoreImageFilteredTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)url credential:(AGSCredential *)cred processBlock:(AGSCITileProcessingBlock)block;
+(AGSCoreImageFilteredTiledMapServiceLayer *)tiledLayerWithTiledLayer:(AGSTiledServiceLayer *)tiledLayer processBlock:(AGSCITileProcessingBlock)block;
@end
