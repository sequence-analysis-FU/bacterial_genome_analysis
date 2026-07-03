import pandas as pd

combined_df = None

for sample_file in snakemake.input:
    #extract sample name from filename
    sample_name = sample_file.split("/")[-1].replace(".stats", "")
    
    df = pd.read_csv(sample_file, sep='\t', header=None, 
                     names=['ref_name', 'ref_length', sample_name, 'unmapped'])
    
    #keep only needed columns 
    df = df[['ref_name', 'ref_length', sample_name]]
    
    if combined_df is None: #first iteration
        combined_df = df
    else:
        #merge on reference name and length
        combined_df = pd.merge(combined_df, df[['ref_name', sample_name]], on='ref_name')

combined_df.to_csv(snakemake.output[0], sep='\t', index=False)