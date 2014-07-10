//
//  AGSProcessedTiledMapServiceLayer.m
//  tiled-layer-generic
//
//  Created by Nicholas Furness on 8/3/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "AGSCIFilteredTiledMapServiceLayer.h"


@interface AGSCIFilteredTiledMapServiceLayer() <AGSLayerDelegate>
@property (nonatomic, strong) AGSTiledServiceLayer * wrappedTiledLayer;
@property (nonatomic, copy) AGSCITileProcessingBlock processBlock;
@end


@implementation AGSCIFilteredTiledMapServiceLayer
#pragma mark - Initializer
-(id)initWithTiledLayer:(AGSTiledServiceLayer *)wrappedTiledLayer processBlock:(AGSCITileProcessingBlock)block
{
    self = [super init];
    if (self) {
        self.wrappedTiledLayer = wrappedTiledLayer;
        self.processBlock = block;
        if (!self.processBlock) {
            self.processBlock = ^(NSData *inputImageData) {
                NSLog(@"Implement a block to process tile data on the way to the map!");
                return inputImageData;
            };
        }
    }
    return self;
}

#pragma mark - Layer Status Control
-(void)setMapView:(AGSMapView *)mapView {
    [super setMapView:mapView];
    if (self.wrappedTiledLayer.loaded) {
        [self layerDidLoad];
    } else {
        self.wrappedTiledLayer.delegate = self;
    }
}

-(void)layerDidLoad:(AGSLayer *)layer
{
    if (layer == self.wrappedTiledLayer) {
        [self layerDidLoad];
    }
}



#pragma mark - Impersonation Overrides for Contained Layer Properties
// See https://developers.arcgis.com/ios/api-reference/category_a_g_s_tiled_layer_07_for_subclass_eyes_only_08.html
-(AGSTileInfo *)tileInfo
{
    return self.wrappedTiledLayer.tileInfo;
}

-(AGSEnvelope *)fullEnvelope
{
    return self.wrappedTiledLayer.fullEnvelope;
}

-(AGSEnvelope *)initialEnvelope
{
    return self.wrappedTiledLayer.initialEnvelope;
}

-(AGSSpatialReference *)spatialReference
{
    return self.wrappedTiledLayer.spatialReference;
}



#pragma mark - Impersonation Overrides for Tile Requests on Contained Layer
// See https://developers.arcgis.com/ios/api-reference/category_a_g_s_tiled_layer_07_for_subclass_eyes_only_08.html
-(void)requestTileForKey:(AGSTileKey *)key
{
    NSURL *tileURL = [self.wrappedTiledLayer urlForTileKey:key];
    NSURLRequest *req = [NSURLRequest requestWithURL:tileURL];
    NSError *error = nil;
    NSData *data = [AGSRequest dataForRequest:req error:&error];
    if (!error) {
        [self setTileData:self.processBlock(data) forKey:key];
    } else {
        NSLog(@"Error getting tile %@ from %@: %@", key, tileURL, error);
        [self setTileData:nil forKey:key];
    }
}



#pragma mark - Convenience Generators with Core Image Filter
+(AGSCIFilteredTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)tiledLayerURL imageFilter:(CIFilter *)filter
{
    return [AGSCIFilteredTiledMapServiceLayer tiledLayerWithURL:tiledLayerURL imageFilters:@[filter]];
}

+(AGSCIFilteredTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)tiledLayerURL credential:(AGSCredential *)credential imageFilter:(CIFilter *)filter
{
    return [AGSCIFilteredTiledMapServiceLayer tiledLayerWithURL:tiledLayerURL credential:credential imageFilters:@[filter]];
}

+(AGSCIFilteredTiledMapServiceLayer *)tiledLayerWithTiledLayer:(AGSTiledServiceLayer *)tiledLayer imageFilter:(CIFilter *)filter
{
    return [AGSCIFilteredTiledMapServiceLayer tiledLayerWithTiledLayer:tiledLayer imageFilters:@[filter]];
}



#pragma mark - Convenience Generators with Array of Core Image Filters
+(AGSCIFilteredTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)tiledLayerURL imageFilters:(NSArray *)filters
{
    return [AGSCIFilteredTiledMapServiceLayer tiledLayerWithURL:tiledLayerURL credential:nil imageFilters:filters];
}

+(AGSCIFilteredTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)tiledLayerURL credential:(AGSCredential *)credential imageFilters:(NSArray *)filters
{
    AGSCITileProcessingBlock block = [AGSCIFilteredTiledMapServiceLayer blockWithCIFilters:filters];
    return [AGSCIFilteredTiledMapServiceLayer tiledLayerWithURL:tiledLayerURL credential:credential processBlock:block];
}

+(AGSCIFilteredTiledMapServiceLayer *)tiledLayerWithTiledLayer:(AGSTiledServiceLayer *)tiledLayer imageFilters:(NSArray *)filters
{
    AGSCITileProcessingBlock block = [AGSCIFilteredTiledMapServiceLayer blockWithCIFilters:filters];
    return [AGSCIFilteredTiledMapServiceLayer tiledLayerWithTiledLayer:tiledLayer processBlock:block];
}



#pragma mark - Convenience Generators with Block
+(AGSCIFilteredTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)tiledLayerURL processBlock:(AGSCITileProcessingBlock)block
{
    return [AGSCIFilteredTiledMapServiceLayer tiledLayerWithURL:tiledLayerURL credential:nil processBlock:block];
}

+(AGSCIFilteredTiledMapServiceLayer *)tiledLayerWithURL:(NSURL *)tiledLayerURL credential:(AGSCredential *)credential processBlock:(AGSCITileProcessingBlock)block
{
    AGSTiledServiceLayer *tiledLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:tiledLayerURL credential:credential];
    return [AGSCIFilteredTiledMapServiceLayer tiledLayerWithTiledLayer:tiledLayer processBlock:block];
}

+(AGSCIFilteredTiledMapServiceLayer *)tiledLayerWithTiledLayer:(AGSTiledServiceLayer *)tiledLayer processBlock:(AGSCITileProcessingBlock)block
{
    return [[AGSCIFilteredTiledMapServiceLayer alloc] initWithTiledLayer:tiledLayer processBlock:block];
}



#pragma mark - Predefined Filter Blocks
+(AGSCITileProcessingBlock)blockWithCIFilters:(NSArray *)filters
{
    return ^(NSData *tileData){
        CIContext *context = [CIContext contextWithOptions:nil];

        CIImage *workingFilterResult = [CIImage imageWithData:tileData];
        CGRect initialExtent = workingFilterResult.extent;
        for (CIFilter *filter in filters) {
            CIFilter *workingFilter = [filter copy]; // CIFilter is not threadsafe
            [workingFilter setValue:workingFilterResult forKey:kCIInputImageKey];
            workingFilterResult = workingFilter.outputImage;
        }
        CGImageRef cgiRef = [context createCGImage:workingFilterResult fromRect:[workingFilterResult extent]];
        UIImage *outImage = [UIImage imageWithCGImage:cgiRef];
        CGImageRelease(cgiRef);
        
        if (initialExtent.size.width < outImage.size.width) {
            // Experimental - in the case where images grow, crop them
            UIImage *inImage = [UIImage imageWithData:tileData];
            CGRect newFrame = CGRectMake(2, 6, inImage.size.width, inImage.size.height);
            CGImageRef newRef = CGImageCreateWithImageInRect(outImage.CGImage, newFrame);
            outImage = [UIImage imageWithCGImage:newRef];
        }
        return UIImagePNGRepresentation(outImage);
    };
}
@end
