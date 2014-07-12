//
//  AGSProcessedTiledMapServiceLayer.h
//  tiled-layer-generic
//
//  Created by Nicholas Furness on 8/3/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@interface AGSCIFilteredTiledMapServiceLayer : AGSTiledServiceLayer
#pragma mark - Factory methods using a single CIFilter
+(AGSCIFilteredTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)url imageFilter:(CIFilter *)filter;
+(AGSCIFilteredTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)url credential:(AGSCredential *)cred imageFilter:(CIFilter *)filter;
+(AGSCIFilteredTiledMapServiceLayer *)tiledLayerWithTiledLayer:(AGSTiledServiceLayer *)tiledLayer imageFilter:(CIFilter *)filter;

#pragma mark - Factory methods using an array of CIFilters applied in order
+(AGSCIFilteredTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)url imageFilters:(NSArray *)filters;
+(AGSCIFilteredTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)url credential:(AGSCredential *)cred imageFilters:(NSArray *)filters;
+(AGSCIFilteredTiledMapServiceLayer *)tiledLayerWithTiledLayer:(AGSTiledServiceLayer *)tiledLayer imageFilters:(NSArray *)filters;

#pragma mark - Factory methods using a fully custom AGSCITileProcessingBlock
// Return Processed PNG NSData for a UIImage (as output by UIImagePNGRepresentation())
typedef NSData *(^AGSCITileProcessingBlock)(NSData*);

+(AGSCIFilteredTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)url processBlock:(AGSCITileProcessingBlock)block;
+(AGSCIFilteredTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)url credential:(AGSCredential *)cred processBlock:(AGSCITileProcessingBlock)block;
+(AGSCIFilteredTiledMapServiceLayer *)tiledLayerWithTiledLayer:(AGSTiledServiceLayer *)tiledLayer processBlock:(AGSCITileProcessingBlock)block;
@end
