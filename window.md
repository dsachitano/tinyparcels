A window into old New York
============

This project is an extension of Chris Whong's [tiny parcels map](http://chriswhong.github.io/tinyparcels/), which he used in his [search for Hess' Triangle](http://chriswhong.com/local/in-search-of-hess-triangle-part-2/).  I created a tile layer using the Bromley Atlas from 1911 that could be displayed over the modern day basemap layer, to give some of the historical context that Chris [dives into on his blog](http://chriswhong.com/open-data/in-search-of-hess-triangle-part-1/).

What you see here is a small window around the cursor showing New York from 1911, laid on top of a base map of modern New York.  You can use this small window to explore what has changed by panning and zooming.

## Bromley Atlas Layer Processing

Reading Hess' Triangle blog post, Chris linked to some [NYPL Digital Collections](http://digitalcollections.nypl.org/items/510d47e2-0961-a3d9-e040-e00a18064a99) maps from Bromley's Atlases.  I wanted to use this raster data in my map, but it was not clear to me how to even get that data from the NYPL.  So I opened up my chrome developer console, and looked at what network requests were being made when viewing the map through their interactive viewer.  

I saw that the image was tiled, and each image tile had a url that looked like this:

```
http://access.nypl.org/image.php/510d47e2-0961-a3d9-e040-e00a18064a99/tiles/0/13/7_5.png
```

This url suggested that I'd be able to download all of the tiles that make up the atlas image, and I decided on a plan:

1. Write a script to pull down all of the tiles.
2. Stitch the tiles together into one large image, using the ImageMagick `montage` tool.
3. Use [QGIS to georeference the raster data](http://www.qgistutorials.com/en/docs/georeferencing_basics.html) using points on the map that still exist today.
4. Export the georeferenced raster data as a GeoTIFF.
5. Import the GeoTIFF data into geoserver, and serve it as a tile layer.


I wrote a [simple ruby script](scripts/fetch_tiles.rb) to fetch the atlas imagery from the NYPL.  The command to stitch them together was something along the lines of `montage *.png full_map.png`.  I did not use an xml file and the REST api to import the GeoTIFF data to geoserver, although with a bit of documentation reading I easily could have.  Instead I just used the web UI.

Once the raster layer with the Bromley Atlas was in place, all I had to do was add the layer to the leaflet map as a wms tile layer.  Copy and paste the code below to add this layer to your own map!

```javascript
L.tileLayer.wms("http://data.getnycinfo.com/geoserver/tiger/wms",
      {service: 'WMS',
       version: '1.1.0',
       format: 'image/png',
       transparent: 'true',
       tiled: 'true',
       layers: 'tiger:transparent_geo_map'}
).addTo(map);
```

