tiled-layer-generic-ios
=======================

This sample includes a couple of examples of custom Tiled Layers based off core runtime AGSTiledLayer classes.

* A generic ArcGIS Runtime for iOS layer that applies Core Image effects to tiles. Comes with a sample processing block that applies a sepia tint to the tiles.
* A layer that pre-caches tiles around the tiles requested by the `AGSMapView` so that they're (hopefully) loaded and ready to display when the user pans the map.