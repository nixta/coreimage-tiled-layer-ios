//
//  SampleViewController.m
//
//  Created by Nicholas Furness on 10/24/12.
//  Copyright (c) 2012 Esri. All rights reserved.
//

#import "SampleViewController.h"
#import <ArcGIS/ArcGIS.h>
#import "AGSProcessedTiledMapServiceLayer.h"

#define kStreet2DURL @"http://server.arcgisonline.com/ArcGIS/rest/services/ESRI_StreetMap_World_2D/MapServer"
#define kTopoURL @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer"
#define kGreyURL @"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer"
#define kGreyRefURL @"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Reference/MapServer"
#define kImageryUrl @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer"
#define kImageryRefURL @"http://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer"

#define sepiaFilter [CIFilter filterWithName:@"CISepiaTone" keysAndValues:@"inputIntensity", [NSNumber numberWithDouble:1], nil]
#define blueFilter [CIFilter filterWithName:@"CIColorMonochrome" keysAndValues:@"inputColor", [CIColor colorWithRed:0 green:0 blue:1], nil]
#define redFilter [CIFilter filterWithName:@"CIColorMonochrome" keysAndValues:@"inputColor", [CIColor colorWithRed:1 green:0 blue:0], nil]
#define greenFilter [CIFilter filterWithName:@"CIColorMonochrome" keysAndValues:@"inputColor", [CIColor colorWithRed:0 green:1 blue:0], nil]
#define blurFilter [CIFilter filterWithName:@"CIGaussianBlur" keysAndValues:@"inputRadius", [NSNumber numberWithDouble:1], nil]
#define pixelFilter [CIFilter filterWithName:@"CIPixellate" keysAndValues:@"inputScale", [NSNumber numberWithDouble:8], nil]


@interface SampleViewController () <AGSMapViewLayerDelegate, AGSLayerDelegate>
@property (weak, nonatomic) IBOutlet AGSMapView *mapView;
@end

@implementation SampleViewController
- (void)viewDidLoad
{
    [super viewDidLoad];

    NSArray *sourceLayersAndFilters = @[
        @[[AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:[NSURL URLWithString:kGreyURL]], blueFilter],
        @[[AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:[NSURL URLWithString:kGreyRefURL]], redFilter]
    ];

    for (NSArray *layerAndFilter in sourceLayersAndFilters) {
        if ([layerAndFilter[1] isKindOfClass:[NSArray class]]) {
            [self.mapView addMapLayer:[AGSProcessedTiledMapServiceLayer tiledLayerWithTiledLayer:layerAndFilter[0] imageFilters:layerAndFilter[1]]];
        } else {
            [self.mapView addMapLayer:[AGSProcessedTiledMapServiceLayer tiledLayerWithTiledLayer:layerAndFilter[0] imageFilter:layerAndFilter[1]]];
        }
    }

    [self.mapView zoomToEnvelope:[AGSEnvelope envelopeWithXmin:167894.02290923594
                                                          ymin:2404569.5470481226
                                                          xmax:3298754.7014692225
                                                          ymax:7766168.4590821
                                              spatialReference:[AGSSpatialReference spatialReferenceWithWKID:102100]]
                        animated:NO];
    
    [self.mapView enableWrapAround];
}
@end
