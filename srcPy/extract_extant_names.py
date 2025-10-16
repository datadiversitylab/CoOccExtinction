import pandas as pd
import numpy as np
import geopandas as gpd
import topojson
import glob
import tqdm
import os

#eps = .001 # about .1km in lat, variable in lon
#chunksize = 10
base = '/home/vanboxel/proj/CoOccExtinction/data'

for cwd in ['Amphibians', 'Reptiles', 'Mammals']:
    out_path = f'{base}/02_intermediate/{cwd}'
    for sp in glob.glob(out_path + '/*/extant/extant.shp'):
        extinct_name = sp.split('/')[8]
        extant_gdf = gpd.read_file(sp)
        tmp = [extinct_name] + extant_gdf['sci_name'].tolist()
        tmp = [e.lower().replace(' ','_') for e in tmp]
        with open(sp[:-17] + 'species.csv','w') as f:
            print('\n'.join(tmp), file=f)

