#If an external genome is given in input, need to annotate it to add it to the core genome analysis
EXTERNAL_FASTA = config.get("comparative_genomics", {}).get("external_genome_fasta", "")
if EXTERNAL_FASTA:
    rule annotate_external_genome:
        input:
            fasta = EXTERNAL_FASTA,
            db = config["bakta"]["db_path"]
        output:
            gff = "results/annotation/external/external.gff3"
        params:
            outdir = "results/annotation/external",
            prefix = "external"
        threads: 8
        conda: "../envs/05_annotation.yaml"
        shell:
            """
            bakta --db {input.db} --output {params.outdir} --prefix {params.prefix} \
                  --threads {threads} --force {input.fasta}
            """

# Panaroo tool as checkpoint 
checkpoint run_panaroo:
    input:
        gffs = get_panaroo_inputs
    output:
        dir = directory("results/comparative/panaroo/aligned_gene_sequences")
    params:
        outdir = "results/comparative/panaroo",
        threshold = config["comparative_genomics"].get("core_threshold", "0.95")
    threads: 8
    conda: "../envs/07_comparative.yaml"
    log:
        "results/logs/panaroo.log"
    shell:
        """
        panaroo -i {input.gffs} -o {params.outdir} --clean-mode strict --remove-invalid-genes \
                -t {threads} --core_threshold {params.threshold} -a core --aligner mafft > {log} 2>&1
        """

# Build individual gene trees
rule iqtree_gene_tree:
    input:
        aln = "results/comparative/panaroo/aligned_gene_sequences/{gene}.fas"
    output:
        tree = "results/comparative/gene_trees/{gene}.treefile"
    threads: 2
    conda: "../envs/07_comparative.yaml"
    shell:
        "iqtree -s {input.aln} -m AUTO -nt {threads} -pre results/comparative/gene_trees/{wildcards.gene}"


# ASTRAL to collect all trees and do the species core genome tree
rule astral_species_tree:
    input:
        trees = aggregate_gene_trees
    output:
        species_tree = "results/comparative/final_species_tree.tre"
    log: "results/logs/astral.log"
    conda: "../envs/07_comparative.yaml"
    shell:
        """
        cat {input.trees} > results/comparative/all_gene_trees.txt
        astral -i results/comparative/all_gene_trees.txt -o {output.species_tree} > {log} 2>&1
        """