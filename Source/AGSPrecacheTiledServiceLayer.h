//
//  AGSPrecacheTiledServiceLayer.h
//  tiled-layer-generic
//
//  Created by Nicholas Furness on 10/1/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <ArcGIS/ArcGIS.h>

@interface AGSPrecacheTiledServiceLayer : AGSTiledServiceLayer
@property (nonatomic, strong, readonly) AGSTiledServiceLayer * wrappedTiledLayer;
-(id)initWithTiledLayer:(AGSTiledServiceLayer *)wrappedTiledLayer;
@end
