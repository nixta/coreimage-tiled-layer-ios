//
//  AGSGenericTileOperation.h
//  tiled-layer-generic
//
//  Created by Nicholas Furness on 10/9/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@class AGSGenericTileOperation;

@protocol AGSGenericTileOperationDelegate <NSObject>
-(void)genericTileOperation:(AGSGenericTileOperation *)operation
             loadedTileData:(NSData *)tileData
                 forTileKey:(AGSTileKey *)tileKey;
@end


#pragma mark - Generic Tile Operation
@interface AGSGenericTileOperation : NSOperation
-(id)initWithTileKey:(AGSTileKey *)tileKey
        forTiledLayer:(AGSTiledServiceLayer *)sourceTiledLayer
         forDelegate:(id<AGSGenericTileOperationDelegate>)delegate;

@property (nonatomic, strong, readonly) AGSTileKey *tileKey;
@property (nonatomic, strong, readonly) AGSTiledServiceLayer *sourceTiledLayer;
@property (nonatomic, weak, readonly) id<AGSGenericTileOperationDelegate> delegate;
@end