//
//  AGSGenericTileOperation.m
//  tiled-layer-generic
//
//  Created by Nicholas Furness on 10/9/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "AGSGenericTileOperation.h"

@implementation AGSGenericTileOperation
-(id)initWithTileKey:(AGSTileKey *)tileKey
       forTiledLayer:(AGSTiledServiceLayer *)sourceTiledLayer
         forDelegate:(id<AGSGenericTileOperationDelegate>)delegate;
{
    self = [super init];
    if (self)
    {
        _tileKey = tileKey;
        _sourceTiledLayer = sourceTiledLayer;
        _delegate = delegate;
        NSLog(@"Created Operation");
    }
    return self;
}

-(void)main
{
    if (self.isCancelled)
    {
        return;
    }
    
    NSData *myTileData = nil;
    
    @try {
        NSLog(@"Getting tile: %@", self.tileKey);
        NSURL *tileUrl = [self.sourceTiledLayer urlForTileKey:self.tileKey];
        NSURLRequest *req = [NSURLRequest requestWithURL:tileUrl];
        NSURLResponse *resp = nil;
        NSError *error = nil;
        myTileData = [NSURLConnection sendSynchronousRequest:req
                                           returningResponse:&resp
                                                       error:&error];
        if (error)
        {
            NSLog(@"Error getting tile %@ from %@: %@", self.tileKey, tileUrl, error);
            return;
        }
        NSLog(@"Got tile: %@", self.tileKey);
        if (self.isCancelled)
        {
            NSLog(@"Cancelled: %@", self.tileKey);
            return;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception getting tile %@: %@", self.tileKey, exception);
    }
    @finally {
        if (!self.isCancelled)
        {
            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(genericTileOperation:loadedTileData:forTileKey:)])
            {
                [self.delegate genericTileOperation:self
                                     loadedTileData:myTileData
                                         forTileKey:self.tileKey];
            }
        }
    }
}
@end
