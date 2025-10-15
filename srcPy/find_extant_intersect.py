import pandas as pd
import numpy as np
import geopandas as gpd
import topojson
import glob
import tqdm
import os

eps = .001 # about .1km in lat, variable in lon
chunksize = 10
base = '/home/vanboxel/proj/CoOccExtinction/data'

cached = False

for cwd in ['Amphibians', 'Reptiles', 'Mammals']:
    print(f'Reading {cwd} Extant Shapes')
    input_gdf = pd.concat([gpd.read_file(fname) for fname in glob.glob(f'{base}/01_raw/{cwd}/extant/*.shp')])

    out_path = f'{base}/02_intermediate/{cwd}'
    extinct = glob.glob(f'{base}/01_raw/{cwd}/extinct/*.gpkg')
    for sp in extinct:
        sp_gdf = gpd.read_file(sp)
        sp_name = sp_gdf['SCI_NAME'].iloc[0].replace(' ','_')
        sp_out = f'{out_path}/{sp_name}/extinct'
        extant_out = f'{out_path}/{sp_name}/extant'
        if cached and os.path.exists(f'{extant_out}/extant.shp'):
            continue

        print(sp)
        mask = None
        for g in sp_gdf['geometry']:
            ints = input_gdf.intersects(g)
            if mask is None:
                mask = ints
            else:
                mask = mask | ints
        os.makedirs(sp_out, exist_ok=True)
        sp_gdf.to_file(f'{sp_out}/{sp_name}.shp')

        os.makedirs(extant_out, exist_ok=True)
        extant_shp = input_gdf[mask]
        extant_shp.to_file(f'{extant_out}/extant.shp')


    print(extinct,out_path)

