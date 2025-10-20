import os
import glob
import pandas as pd
import geopandas as gpd
import tqdm
import sys

info = []

ddir = sys.argv[1]
mode = sys.argv[2]
i = int(sys.argv[3])
all_sp = sys.argv[4:]

#ddir = '/home/vanboxel/proj/CoOccExtinction/data/'
base = ddir + '/02_intermediate'
#mode = 'Assemblage'

#if mode == 'Community':
#    input_gdf = pd.concat([gpd.read_file(fname) for fname in glob.glob(f'{base}/01_raw/*/extant/*.shp')])


os.makedirs(ddir + '/case_studies', exist_ok=True)
#for cl in ['Amphibians', 'Mammals', 'Reptiles']:
for cl in all_sp:
    for sp_dir in tqdm.tqdm(glob.glob(base + f'/{cl}_{mode}/*')):
        sp = os.path.split(sp_dir)[1].lower()[:-(len(mode)+1)]
        info.append((i, sp, 0, mode, cl))
        extants = gpd.read_file(sp_dir + '/extant/extant.shp')
        names = extants['sci_name'].apply(lambda s: s.lower().replace(' ', '_'))
        info.extend([(i, n, 1, mode, cl) for n in names])
        with open(sp_dir + '/species.csv','w') as f:
            print('\n'.join([sp] + names.tolist()), file=f)
        del extants
        os.system(f'mv {sp_dir} {ddir}/case_studies/CS_{i:03}')
        i += 1

summary = pd.DataFrame(info, columns=['cs','species', 'extant', 'community', 'class'])
summary.to_csv(ddir + f'/species_{mode}.csv', index=False, header=False)

        


