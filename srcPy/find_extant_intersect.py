import pandas as pd
import numpy as np
import geopandas as gpd
import topojson
import glob
import tqdm
import os
import sys

#eps = .001 # about .1km in lat, variable in lon
#chunksize = 10
#base = '/home/vanboxel/proj/CoOccExtinction/data'
#mode = 'Assemblage'
base = sys.argv[1]
mode = sys.argv[2]
all_sp = sys.argv[3:]
eps = .01 # about 1km in lat, variable in lon

cached = True

if mode == 'Community':
    input_gdf_names = glob.glob(f'{base}/01_raw/*/extant/*.shp')
    #input_gdf = pd.concat([gpd.read_file(fname) for fname in ])

#for cwd in ['Amphibians', 'Reptiles', 'Mammals']:
#for cwd in ['Birds']:
for cwd in all_sp:
    print(f'Reading {cwd} Extant Shapes')
    if mode == 'Assemblage':
        input_gdf_names = glob.glob(f'{base}/01_raw/{cwd}/extant/*.shp') + glob.glob(f'{base}/01_raw/{cwd}/extant/*.gpkg')
        #input_gdf = pd.concat([gpd.read_file(fname) for fname in glob.glob(f'{base}/01_raw/{cwd}/extant/*.shp')] +
        #                      [gpd.read_file(fname) for fname in glob.glob(f'{base}/01_raw/{cwd}/extant/*.gpkg')])

    out_path = f'{base}/02_intermediate/{cwd}_{mode}'
    extinct = glob.glob(f'{base}/01_raw/{cwd}/extinct/*.gpkg')
    # need to restart on 7/Numenius_tenuirostris.gpkg
    for sp in tqdm.tqdm(extinct):
        sp_gdf = gpd.read_file(sp)
        sp_name = sp_gdf['SCI_NAME'].iloc[0].replace(' ','_')
        sp_out = f'{out_path}/{sp_name}/extinct'
        extant_out = f'{out_path}/{sp_name}/extant'
        if cached and os.path.exists(f'{extant_out}/extant.shp'):
            continue

        print(sp)
        #mask = None
        big_ints = []
        for g in sp_gdf['geometry']:
            #ints = input_gdf.intersects(g)
            all_ints = [gpd.read_file(fname, mask=g) for fname in input_gdf_names]
            big_ints.extend(all_ints)
            #if mask is None:
            #    mask = ints
            #else:
            #    mask = mask | ints
        os.makedirs(sp_out, exist_ok=True)
        sp_gdf['geometry'] = sp_gdf.simplify(eps)
        sp_gdf.to_file(f'{sp_out}/{sp_name}.shp')

        os.makedirs(extant_out, exist_ok=True)
        #extant_shp = input_gdf[mask]
        extant_shp = pd.concat(big_ints)
        extant_shp['geometry'] = extant_shp.simplify(eps)
        extant_shp.to_file(f'{extant_out}/extant.shp')

