import pandas as pd
import numpy as np
import geopandas as gpd
import topojson
import glob
import tqdm
import shapely as sh

eps = .001 # about .1km in lat, variable in lon
chunksize = 10
base = '/home/vanboxel/proj/CoOccExtinction/data/01_raw'

#for cwd in ['Amphibians', 'Reptiles', 'Mammals']:
for cwd in ['Birds']:
    output_gdf = []
    for fname in glob.glob(f'{base}/{cwd}/extant/*.shp') + glob.glob(f'{base}/{cwd}/extant/*.gpkg'):
        # Read the shapefile
        #print(f'Reading {fname}')
        start = 0
        while True:
            if start % 100 == 0:
                print(start, end=' ')
            sql = f'select * from "BOTW_2025" where fid >= {start} and fid < {start+chunksize}' 
            input_gdf = gpd.read_file(fname, sql=sql)
            output_gdf.append(input_gdf.simplify(eps))
            start += chunksize

            #input_gdf = input_gdf.head(chunksize)
            #nchunks = len(input_gdf)//chunksize
            #if len(input_gdf) % chunksize:
            #    nchunks += 1

            # Convert to topology, simplify and convert back to GeoDataFrame
            ## For safety, loop through chunks of these
            #for rows in tqdm.tqdm(np.array_split(input_gdf, nchunks)): 
                #print(f'Topologizing {fname}')
                #topo = topojson.Topology(rows, prequantize=False)
                #print(f'Simplifying {fname}')
                #topo_simpl = topo.toposimplify(eps)
                #print(f'GDFing {fname}')
                #simpl_gdf = topo_simpl.to_gdf()
                # Fix any invalid geometries (self-intersections)
                #print(f'Validating {fname}')
                #simpl_gdf.geometry = simpl_gdf.geometry.make_valid()
                #output_gdf.append(input_gdf.simplify(eps))
    output_gdf = pd.concat(output_gdf, ignore_index=True)

    # Write to output file, class combined for ease of use
    output_path = fname[:-4] + f'.eps{eps:3.1}.shp'
    print(f'Saving {output_path}')
    output_gdf.to_file(output_path)

# just for interactive use
if False:
    fname = '/home/vanboxel/proj/CoOccExtinction/data/01_raw/Amphibians/Craugastor omoaensis.gpkg'
    gdf = gpd.read_file(fname)
    gdf_simp = gdf.simplify(eps)
    res = [0.001, 0.01, 0.1, 1]
    cols = ['orange', 'blue', 'green', 'red']
    res = [0.001, 0.01]#, 0.1, 1]
    cols = ['orange', 'blue']#, 'green', 'red']

    import matplotlib.pyplot as plt
    plt.ion()

    for i in gdf['geometry']:
        for p in i.geoms:
            plt.plot(*p.exterior.xy, '.-', alpha=.3, color='gray', label='Original')
    for eps,c in zip(res,cols):
        cur_gdf = gdf.simplify(eps)
        for i in cur_gdf:
            if isinstance(i, sh.geometry.Polygon):
                geoms = sh.geometry.MultiPolygon([i])
            else:
                geoms = i
            for p in geoms.geoms:
                plt.plot(*p.exterior.xy, 'o--', alpha=.5, color=c, label=f'Simplified {eps/0.01:2.1f} km')
    plt.legend()

    plt.ylabel('Latitude')
    plt.xlabel('Longitude')
    plt.title('Simplified ranges of Craugastor omoaensis')
    plt.tight_layout()
    plt.savefig('craugastor_omoaensis_simplified.png')
