//
//  EDNLODLimitedTiledMapServiceLayer.m
//
//  Created by Nicholas Furness on 3/14/12.
//  Copyright (c) 2012 ESRI. All rights reserved.
//

#import "EDNLODLimitedTiledLayer.h"

@implementation EDNLODLimitedTiledLayer
@synthesize minLODLevel = _minLODLevel;
@synthesize maxLODLevel = _maxLODLevel;
@synthesize wrappedTiledLayer = _wrappedTiledLayer;

AGSTileInfo *_myTileInfo = nil;

const NSUInteger appleMinLODLevel = 3;
const NSUInteger appleMaxLODLevel = 14;

#pragma -mark Initialization
-(id)initWithBaseTiledMapServiceLayer:(AGSTiledLayer *)baseLayer fromLODLevel:(NSInteger)min toLODLevel:(NSInteger)max
{
	if (self = [super init])
	{
		_wrappedTiledLayer = baseLayer;
		_minLODLevel = min;
		_maxLODLevel = max;
	}
	
    return self;
}

- (void)dealloc
{
    _myTileInfo = nil;
	_wrappedTiledLayer = nil;
}

#pragma -mark Overrides
-(AGSTileInfo *)tileInfo
{
    if (_myTileInfo == nil && 
		_wrappedTiledLayer != nil && 
		_wrappedTiledLayer.loaded)
    {
        AGSTileInfo *originalTileInfo = [_wrappedTiledLayer tileInfo];
        
		if (originalTileInfo != nil)
		{
			NSInteger minLOD = self.minLODLevel;
			NSInteger maxLOD = self.maxLODLevel;
			
			NSMutableArray *newLODs = [NSMutableArray arrayWithArray:originalTileInfo.lods];

			// Remove the LODs that we're not interested in.
			for (int i = newLODs.count -1; i>=0; i--)
			{
				AGSLOD *tmpLod = [newLODs objectAtIndex:i];
				if (tmpLod.level > maxLOD ||
					tmpLod.level < minLOD)
				{
					[newLODs removeObjectAtIndex:i];
				}
			}
			
			// We're just duplicating everything here...
			_myTileInfo = [[AGSTileInfo alloc] initWithDpi:originalTileInfo.dpi
													format:originalTileInfo.format
													  lods:newLODs // ...except the LODs
													origin:originalTileInfo.origin
										  spatialReference:originalTileInfo.spatialReference
												  tileSize:CGSizeMake(originalTileInfo.tileSize.width, originalTileInfo.tileSize.height)];        
		}
    }
    
    return _myTileInfo;
}

#pragma mark - Generic Passthrough
// Step 1: We have to pretend to be whatever AGSTiledLayer we contain. Neat!
-(BOOL)isKindOfClass:(Class)aClass
{
	// Why not just inherit from AGSTiledLayer? Well, then the call to inherited methods go 
	// direct to the super instance rather than through the dynamic "forwardInvocation" 
	// framework (see below).
	if (_wrappedTiledLayer != nil && [_wrappedTiledLayer isKindOfClass:aClass])
	{
//		NSLog(@"I (%@) am a kind of %@", [self class], aClass);
		return YES;
	}
	else 
	{
		return [super isKindOfClass:aClass];
	}
}

// Step 2: We now have to return a valid method signature for objects we pretend to be.
-(NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
//	NSLog(@"Method signature for selector: %@", NSStringFromSelector(aSelector));
	if (_wrappedTiledLayer != nil && [_wrappedTiledLayer respondsToSelector:aSelector])
	{
		return [_wrappedTiledLayer methodSignatureForSelector:aSelector];
	}
	else
	{
		return [super methodSignatureForSelector:aSelector];
	}
}

// Step 3: Since we provided a method signature, we need to handle the invocation.
-(void)forwardInvocation:(NSInvocation *)anInvocation
{
	if (_wrappedTiledLayer != nil && [_wrappedTiledLayer respondsToSelector:[anInvocation selector]])
	{
		// Our wrapped AGSTiledLayer subclass handles this particular message, so let's do it.
//		NSLog(@"Forwarding invocation: %@", NSStringFromSelector([anInvocation selector]));
		[anInvocation invokeWithTarget:_wrappedTiledLayer];
	}
	else 
	{
		// Well, really, we should never get here, but we'll be nice just in case.
		[super forwardInvocation:anInvocation];
	}
}

#pragma -mark Static members
// Convenience methods for getting LOD Limited layers.
+(EDNLODLimitedTiledLayer *)lodLimitedTiledMapServiceLayer:(AGSTiledLayer *)baseLayer fromLODLevel:(NSInteger)min toLODLevel:(NSInteger)max
{
	return [[EDNLODLimitedTiledLayer alloc] initWithBaseTiledMapServiceLayer:baseLayer 
																fromLODLevel:min 
																  toLODLevel:max];
}

+(EDNLODLimitedTiledLayer *)lodLimitedTiledMapServiceLayerMatchingAppleLODs:(AGSTiledLayer *)baseLayer
{
	return [EDNLODLimitedTiledLayer lodLimitedTiledMapServiceLayer:baseLayer 
													  fromLODLevel:appleMinLODLevel 
														toLODLevel:appleMaxLODLevel];
}

+(EDNLODLimitedTiledLayer *)openStreetMapLayerFromLODLevel:(NSInteger)min toLODLevel:(NSInteger)max
{
    return [EDNLODLimitedTiledLayer lodLimitedTiledMapServiceLayer:[AGSOpenStreetMapLayer openStreetMapLayer] 
													  fromLODLevel:min
														toLODLevel:max];
}

+(EDNLODLimitedTiledLayer *)openStreetMapLayerMatchingAppleOSMLODS
{
    return [EDNLODLimitedTiledLayer openStreetMapLayerFromLODLevel:appleMinLODLevel 
														toLODLevel:appleMaxLODLevel];
}
@end
