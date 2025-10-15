import pandas as pd
import numpy as np
import geopandas as gpd
import topojson
import glob
import tqdm

eps = .001 # about .1km in lat, variable in lon
chunksize = 10
base = '/home/vanboxel/proj/CoOccExtinction/data/01_raw'

for cwd in ['Amphibians', 'Reptiles', 'Mammals']:
    output_gdf = []
    for fname in glob.glob(f'{base}/{cwd}/extant/*.shp'):
        # Read the shapefile
        print(f'Reading {fname}')
        input_gdf = gpd.read_file(fname)

        #input_gdf = input_gdf.head(chunksize)
        nchunks = len(input_gdf)//chunksize
        if len(input_gdf) % chunksize:
            nchunks += 1

        # Convert to topology, simplify and convert back to GeoDataFrame
        ## For safety, loop through chunks of these
        for rows in tqdm.tqdm(np.array_split(input_gdf, nchunks)): 
            print(f'Topologizing {fname}')
            topo = topojson.Topology(rows, prequantize=False)
            print(f'Simplifying {fname}')
            topo_simpl = topo.toposimplify(eps)
            print(f'GDFing {fname}')
            simpl_gdf = topo_simpl.to_gdf()
            # Fix any invalid geometries (self-intersections)
            print(f'Validating {fname}')
            simpl_gdf.geometry = simpl_gdf.geometry.make_valid()
            output_gdf.append(simpl_gdf)
    output_gdf = pd.concat(output_gdf, ignore_index=True)

    # Write to output file, class combined for ease of use
    output_path = fname[:-4] + f'.eps{eps:3.1}.shp'
    print(f'Saving {output_path}')
    output_gdf.to_file(output_path)

# just for interactive use
if False:
    import matplotlib.pyplot as plt
    plt.ion()
    for i,o in zip(input_gdf['geometry'][:10], output_gdf['geometry'][:10]):
        plt.plot(*i.exterior.xy, '.-', alpha=.5)
        plt.plot(*o.exterior.xy, 'o--', alpha=.8)
    # TODO: demonstrate how we do this in a figure

