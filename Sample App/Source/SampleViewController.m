//
//  SampleViewController.m
//
//  Created by Nicholas Furness on 10/24/12.
//  Copyright (c) 2012 Esri. All rights reserved.
//

#import "SampleViewController.h"
#import <ArcGIS/ArcGIS.h>
#import "AGSCIFilteredTiledMapServiceLayer.h"

#pragma mark - Basemap URLs
#define kStreet2DURL @"http://server.arcgisonline.com/ArcGIS/rest/services/ESRI_StreetMap_World_2D/MapServer"
#define kTopoURL @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer"
#define kGreyURL @"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer"
#define kGreyRefURL @"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Reference/MapServer"
#define kImageryUrl @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer"
#define kImageryRefURL @"http://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer"

#pragma mark - Sample Filters
#define sepiaFilter [CIFilter filterWithName:@"CISepiaTone" keysAndValues:kCIInputIntensityKey, [NSNumber numberWithDouble:1], nil]
#define greenFilter [CIFilter filterWithName:@"CIColorMonochrome" keysAndValues:kCIInputColorKey, [CIColor colorWithRed:0 green:1 blue:0], nil]
#define blueFilter [CIFilter filterWithName:@"CIColorMonochrome" keysAndValues:kCIInputColorKey, [CIColor colorWithRed:0 green:0 blue:1], nil]
#define redFilter [CIFilter filterWithName:@"CIColorMonochrome" keysAndValues:kCIInputColorKey, [CIColor colorWithRed:1 green:0 blue:0], nil]
#define pixelFilter [CIFilter filterWithName:@"CIPixellate" keysAndValues:kCIInputScaleKey, [NSNumber numberWithDouble:8], \
                                                                          kCIInputCenterKey, [CIVector vectorWithX:256.0f/2 Y:256.0f/2], nil]
#define blurFilter [CIFilter filterWithName:@"CIGaussianBlur" keysAndValues:kCIInputRadiusKey, [NSNumber numberWithDouble:1], nil]
#define toneFilter [CIFilter filterWithName:@"CIToneCurve" keysAndValues:@"inputPoint4", [CIVector vectorWithX:1 Y:0], nil]

#pragma mark - View Controller
@interface SampleViewController () <AGSMapViewTouchDelegate>
@property (weak, nonatomic) IBOutlet AGSMapView *mapView;

@property (nonatomic, assign) BOOL showUnFilteredLayers;

@property (nonatomic, strong) AGSLayer *greyBasemapLayer;
@property (nonatomic, strong) AGSLayer *greyReferenceLayer;
@property (nonatomic, strong) AGSLayer *filteredBasemapLayer;
@property (nonatomic, strong) AGSLayer *filteredReferenceLayer;
@end

@implementation SampleViewController
#pragma mark - ViewController Entry Point
- (void)viewDidLoad
{
    [super viewDidLoad];
    

    
    /// *******************************

    self.filteredBasemapLayer = [AGSCIFilteredTiledMapServiceLayer tiledLayerWithURL:[NSURL URLWithString:kGreyURL]
                                                                        imageFilters:@[blueFilter, pixelFilter]];
    self.filteredReferenceLayer = [AGSCIFilteredTiledMapServiceLayer tiledLayerWithURL:[NSURL URLWithString:kGreyRefURL]
                                                                           imageFilter:redFilter];
    
    // Add a couple of layers with CIFilters on them.
    [self.mapView addMapLayer:self.filteredBasemapLayer];
    [self.mapView addMapLayer:self.filteredReferenceLayer];

    /// *******************************
    
    
    
    [self.mapView zoomToEnvelope:[AGSEnvelope envelopeWithXmin:167894 ymin:2404569
                                                          xmax:3298754 ymax:7766168
                                              spatialReference:[AGSSpatialReference webMercatorSpatialReference]]
                        animated:NO];
    [self.mapView enableWrapAround];
    
    self.mapView.touchDelegate = self;
}




#pragma mark - Demo App Filter Toggle
-(void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features {
    self.showUnFilteredLayers = !self.showUnFilteredLayers;
}

#pragma mark - Property Setter Override
-(void)setShowUnFilteredLayers:(BOOL)showUnFilteredLayers
{
    _showUnFilteredLayers = showUnFilteredLayers;
    self.filteredBasemapLayer.visible = !showUnFilteredLayers;
    self.filteredReferenceLayer.visible = !showUnFilteredLayers;
    
    if (_showUnFilteredLayers) {
        // Only reference (and hence lazy-load) these when first needed.
        self.greyBasemapLayer.visible = YES;
        self.greyReferenceLayer.visible = YES;
    }
}

#pragma mark - Lazy Load (and add to map) of unfiltered Grey Basemap layers
-(AGSLayer *)greyBasemapLayer {
    if (!_greyBasemapLayer) {
        _greyBasemapLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:[NSURL URLWithString:kGreyURL]];
        AGSLayer *layerToInsertBefore = self.greyReferenceLayer;
        [self.mapView insertMapLayer:_greyBasemapLayer atIndex:[self.mapView.mapLayers indexOfObject:layerToInsertBefore]];
    }
    return _greyBasemapLayer;
}

-(AGSLayer *)greyReferenceLayer {
    if (!_greyReferenceLayer) {
        _greyReferenceLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:[NSURL URLWithString:kGreyRefURL]];
        [self.mapView insertMapLayer:_greyReferenceLayer atIndex:[self.mapView.mapLayers indexOfObject:self.filteredBasemapLayer]];
    }
    return _greyReferenceLayer;
}

#pragma mark - iOS 7 UI
-(BOOL)prefersStatusBarHidden {
    return YES;
}
@end