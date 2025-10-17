import os
import glob
import pandas as pd
import geopandas as gpd
import tqdm

info = []

ddir = '/home/vanboxel/proj/CoOccExtinction/data/'
base = ddir + '02_intermediate'
comm = 'Assemblage'

i = 0
os.makedirs(ddir + 'case_studies', exist_ok=True)
for cl in ['Amphibians', 'Mammals', 'Reptiles']:
    for sp_dir in tqdm.tqdm(glob.glob(base + f'/{cl}/*')):
        sp = os.path.split(sp_dir)[1].lower()
        info.append((i, sp, 0, comm, cl))
        extants = gpd.read_file(sp_dir + '/extant/extant.shp')
        names = extants['sci_name'].apply(lambda s: s.lower().replace(' ', '_'))
        info.extend([(i, n, 1, comm, cl) for n in names])
        with open(sp_dir + '/species.csv','w') as f:
            print('\n'.join([sp] + names.tolist()), file=f)
        del extants
        os.system(f'mv {sp_dir} {ddir}case_studies/CS_{i:03}')
        i += 1

summary = pd.DataFrame(info, columns=['cs','species', 'extant', 'community', 'class'])
summary.to_csv(ddir + 'species.csv')

        


