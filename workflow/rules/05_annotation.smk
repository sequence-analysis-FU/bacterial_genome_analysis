rule bakta_annotation:
    input:
        fasta = get_final_assembly
    output:
        gff = "results/annotation/{sample}/{sample}.gff3", #main annotation file
        faa = "results/annotation/{sample}/{sample}.faa",  #predicted protein sequences
        fna = "results/annotation/{sample}/{sample}.fna"   #nucleotide sequences for predicted genes
    params:
        outdir = "results/annotation/{sample}",
        prefix = "{sample}",
        db = config["bakta"]["db_path"] 
    log:
        "results/logs/bakta/{sample}.log"
    threads: 8
    conda:
        "../envs/annotation.yaml"
    shell:
        """
        bakta --db {params.db} \
              --output {params.outdir} \
              --prefix {params.prefix} \
              --threads {threads} \
              --force \
              {input.fasta} > {log} 2>&1
        """