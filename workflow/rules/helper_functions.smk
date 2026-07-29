# Generic helper function to get the right path of the polished assembly
def get_final_assembly(wildcards):
    """
    Determines the right path of the polished assembly, depending on the availability of short reads.
    """
    #If there are short reads...
    if ENABLE_SHORT_READS:
        #...final polished assembly should be the Pilon one
        return f"results/polishing/{wildcards.sample}/pilon_polished.fasta"
    else:
        #if there aren't short reads, the final polished assembly should be the Racon one
        return f"results/polishing/{wildcards.sample}/racon_polished.fasta"

# Function to gather the inputs for Panaroo tool (used in 07_comparative_genomics.smk)
def get_panaroo_inputs(wildcards):
    # Get GFFs from all samples in the sample sheet [4]
    gffs = list(expand("results/annotation/{sample}/{sample}.gff3", sample=samples.index))

    # Add the external GFF only if the fasta was provided in config
    if EXTERNAL_FASTA:
        gffs.append("results/annotation/external/external.gff3")
    return gffs

# Aggregation function for ASTRAL (used in 07_comparative_genomics.smk)
def aggregate_gene_trees(wildcards):
    checkpoint_output = checkpoints.run_panaroo.get(**wildcards).output.dir
    import os
    genes = [f.replace(".fas", "") for f in os.listdir(checkpoint_output) if f.endswith(".fas")]
    return expand("results/comparative/gene_trees/{gene}.treefile", gene=genes)