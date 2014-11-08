Small Parcels of NYC
============

This project is an extension of Chris Whong's [tiny parcels map](http://chriswhong.github.io/tinyparcels/), which he used in his [search for Hess' Triangle](http://chriswhong.com/local/in-search-of-hess-triangle-part-2/).  I wanted to use his map as a starting point, but build it on the geostack I've started developing in [another repo of mine](https://github.com/dsachitano/routingserver).  My plan was roughly to maintain the same featureset (small parcel polygons, and markers at their centroids displaying select fields from the PLUTO dataset), but do it using my app server and pull live data from postgis instead of using static hardcoded files.  I then wanted to create a tile layer using the Bromley Atlas that could be displayed over the modern day basemap layer, to give some of the historical context that Chris [dives into on his blog](https://github.com/dsachitano/routingserver/blob/master/java_app/application/src/main/java/com/thebaseballrun/webui/resources/HelloWorldResource.java).

## PLUTO Data Processing

Here are the steps I followed for preparing my data for use in the map.

1. Use my [drag and drop file uploader](https://github.com/dsachitano/routingserver/blob/master/static/upload.html) to upload the [MapPLUTO](http://www.nyc.gov/html/dcp/html/bytes/applbyte.shtml) shapefile.  My [backend java app](https://github.com/dsachitano/routingserver/blob/master/java_app/application/src/main/java/com/thebaseballrun/webui/resources/HelloWorldResource.java) then uses `shp2pgsql` and `psql` to load that data into PostGIS.
2. Once the data is loaded into PostGIS, a layer can be added to geoserver using a custom SQL query to get what we want: all parcels under 100 sqft.  I created [a file](geoserver_configs/small+parcel+centroids.xml) that defines how this should work, which can be added to geoserver using their REST api, with a command like this:

> curl -v -u admin -XPOST -H 'Content-Type: text/xml' -d @small+parcel+centroids.xml "http://geoserver:8080/geoserver/rest/workspaces/tiger/datastores/Uploaded+Data/featuretypes"

Then all that was left is to change the ajax call that was loading the local json file to point at my geoserver url corresponding to the query layer we added in the last step.

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

## Putting it all together

To actually deploy this code, I used an Amazon Linux EC2 instance.  Once it was booted, I cloned my baseballrouter repo, then cloned this repo into the `/static` dir of the baseballrouter repo, so that the html with this map could be loaded via the `/static/tinyparcels/` path.  With the data in place, I just had to run `fig up` to start the geostack, and then perform the data importing procedures mentioned above.

This code is currently deployed on my own server and can be viewed at: [http://data.getnycinfo.com/static/tinyparcels/](http://data.getnycinfo.com/static/tinyparcels/)
