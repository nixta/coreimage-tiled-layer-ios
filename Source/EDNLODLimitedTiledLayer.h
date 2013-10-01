//
//  EDNLODLimitedTiledMapServiceLayer.h
//
//  Created by Nicholas Furness on 3/14/12.
//  Copyright (c) 2012 ESRI. All rights reserved.
//

#import <ArcGIS/ArcGIS.h>

@interface EDNLODLimitedTiledLayer : NSObject
@property (nonatomic, retain, readonly) AGSTiledLayer * wrappedTiledLayer;
@property (nonatomic, assign, readonly) NSInteger minLODLevel;
@property (nonatomic, assign, readonly) NSInteger maxLODLevel;

-(id)initWithBaseTiledMapServiceLayer:(AGSTiledLayer *)baseLayer 
						 fromLODLevel:(NSInteger)min 
						   toLODLevel:(NSInteger)max;

+(EDNLODLimitedTiledLayer *)lodLimitedTiledMapServiceLayer:(AGSTiledLayer *)baseLayer
											  fromLODLevel:(NSInteger)min 
												toLODLevel:(NSInteger)max;
+(EDNLODLimitedTiledLayer *)lodLimitedTiledMapServiceLayerMatchingAppleLODs:(AGSTiledLayer *)baseLayer;

+(EDNLODLimitedTiledLayer *)openStreetMapLayerFromLODLevel:(NSInteger)min 
												toLODLevel:(NSInteger)max;
+(EDNLODLimitedTiledLayer *)openStreetMapLayerMatchingAppleOSMLODS;
@end
