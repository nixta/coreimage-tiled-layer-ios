//
//  SampleViewController.m
//
//  Created by Nicholas Furness on 10/24/12.
//  Copyright (c) 2012 Esri. All rights reserved.
//

#import "SampleViewController.h"
#import <ArcGIS/ArcGIS.h>
#import "AGSProcessedTiledMapServiceLayer.h"
#import "AGSPrecacheTiledServiceLayer.h"

@interface SampleViewController () <AGSMapViewLayerDelegate>
@property (weak, nonatomic) IBOutlet AGSMapView *mapView;
@end

#define kStreet2DURL @"http://server.arcgisonline.com/ArcGIS/rest/services/ESRI_StreetMap_World_2D/MapServer"
#define kTopoURL @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer"
#define kGreyURL @"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer"
#define kGreyRefURL @"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Reference/MapServer"
#define kImageryUrl @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer"
#define kImageryRefURL @"http://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer"

@implementation SampleViewController
- (void)viewDidLoad
{
    [super viewDidLoad];

    NSArray *sourceLayers = @[
        [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:[NSURL URLWithString:kGreyURL]],
        [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:[NSURL URLWithString:kGreyRefURL]]
    ];

    CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"
                                  keysAndValues:@"inputIntensity", [NSNumber numberWithDouble:1], nil];
    
    for (id sourceLayer in sourceLayers) {
        AGSTiledServiceLayer *wrappedLayer = [AGSProcessedTiledMapServiceLayer tiledLayerWithTiledLayer:sourceLayer imageFilter:filter];
        [self.mapView addMapLayer:wrappedLayer];
    }

    [self.mapView enableWrapAround];

    self.mapView.layerDelegate = self;
}

-(void)mapViewDidLoad:(AGSMapView *)mapView {
    [self.mapView zoomToScale:100458509.498688 animated:NO];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mapExtentChanged:)
                                                 name:AGSMapViewDidEndZoomingNotification
                                               object:self.mapView];
}

-(void)mapExtentChanged:(NSNotificationCenter *)notification
{
    NSLog(@"%f %@",self.mapView.mapScale, self.mapView.visibleAreaEnvelope);
}
@end