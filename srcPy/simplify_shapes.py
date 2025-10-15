import geopandas as gpd
import topojson
import glob

for fname in glob.glob('*.shp'):
    # Read the shapefile
    input_gdf = gpd.read_file(fname)

    # Reproject to UTM
    input_gdf = input_gdf.to_crs(32633)

    # Convert to topology, simplify and convert back to GeoDataFrame
    topo = topojson.Topology(input_gdf, prequantize=False)
    topo_simpl = topo.toposimplify(0.5)
    simpl_gdf = topo_simpl.to_gdf()

    # Fix any invalid geometries (self-intersections)
    simpl_gdf.geometry = simpl_gdf.geometry.make_valid()

    # Reproject back to WGS84
    simpl_gdf = simpl_gdf.to_crs(4326)

    # Write to output file
    output_path = fname[:-4] + '.5eps.shp'
    simpl_gdf.to_file(output_path)

