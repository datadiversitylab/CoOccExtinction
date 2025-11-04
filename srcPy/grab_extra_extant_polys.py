import pandas as pd
import numpy as np
import geopandas as gpd
import topojson
import glob
import tqdm
import os
import shapely as sh
import sys

#eps = .001 # about .1km in lat, variable in lon
#chunksize = 10
#base = '/home/vanboxel/proj/CoOccExtinction/data'
base = sys.argv[1]
mode = sys.argv[2]
all_sp = sys.argv[3:]
eps = .001 # about .1km in lat, variable in lon

cached = True

if mode == 'Community':
    input_gdf_names = glob.glob(f'{base}/01_raw/*/extant/*.shp')
    #input_gdf = pd.concat([gpd.read_file(fname) for fname in glob.glob(f'{base}/01_raw/*/extant/*.shp')])

#for cwd in ['Amphibians', 'Reptiles', 'Mammals']:
for cwd in all_sp:
    print(f'Reading {cwd} Extant Shapes')
    if mode == 'Assemblage':
        #input_gdf = pd.concat([gpd.read_file(fname) for fname in glob.glob(f'{base}/01_raw/{cwd}/extant/*.shp')])
        input_gdf_names = glob.glob(f'{base}/01_raw/{cwd}/extant/*.shp') + glob.glob(f'{base}/01_raw/{cwd}/extant/*.gpkg')

    out_path = f'{base}/02_intermediate/{cwd}_{mode}'
    exts = glob.glob(f'{base}/02_intermediate/{cwd}_{mode}/*/extant/extant.shp')
    for ex in tqdm.tqdm(exts):
        sp_gdf = gpd.read_file(ex)
        species = set(sp_gdf['sci_name'])
        all_info = []
        for sp in tqdm.tqdm(species):
            # NB: change sp_gdf to input_gdf for actual run
            #rows = input_gdf[input_gdf['sci_name'] == sp]
            rows = pd.concat([gpd.read_file(fname, where=f"sci_name='{sp}'") for fname in input_gdf_names])
            # different format for birds
            if cwd == 'Birds':
                # based on possibly extinct or worse
                category = 'ex' if min(rows['presence']) > 3 else 'lc'
            else:
                category = rows['category'].iloc[0].lower()
            if 'ex' in category or 'ew' in category:
                continue # skip as extinct
            if len(rows) == 1:
                all_info.append(rows.iloc[0].tolist())
            else:
                poly = sh.ops.unary_union(rows['geometry'].tolist())
                info = rows.iloc[0].tolist()
                info[-1] = poly # overwrite with combined
                all_info.append(info)
        new_sp_gdf = gpd.GeoDataFrame(all_info, columns=sp_gdf.columns, crs=sp_gdf.crs)

        extant_out = ex[:-10]
        os.makedirs(extant_out, exist_ok=True)
        new_sp_gdf['geometry'] = new_sp_gdf.simplify(eps)
        new_sp_gdf.to_file(f'{extant_out}/extant_new.shp')

