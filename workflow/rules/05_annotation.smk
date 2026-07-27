rule download_bakta_db:
    output:
        directory(config["bakta"]["db_path"])
    params:
        db_type = config["bakta"].get("db_type", "light") #default is 'light' db
    conda:
        "../envs/05_annotation.yaml"
    log:
        "results/logs/bakta_db_setup.log"
    shell:
        """
        bakta_db download --output {output} --type {params.db_type} > {log} 2>&1
        """

rule bakta_annotation:
    input:
        fasta = get_final_assembly,
        db = rules.download_bakta_db.output  #execute rule for creating the bakta db before executing this rule for annotation
    output:
        gff = "results/annotation/{sample}/{sample}.gff3", #main annotation file
        faa = "results/annotation/{sample}/{sample}.faa",  #predicted protein sequences
        fna = "results/annotation/{sample}/{sample}.fna"   #nucleotide sequences for predicted genes
    params:
        outdir = "results/annotation/{sample}",
        prefix = "{sample}",
        db = lambda wildcards: f"{config['bakta']['db_path']}/db-{config['bakta'].get('db_type', 'light')}" 
    log:
        "results/logs/bakta/{sample}.log"
    threads: 8
    conda:
        "../envs/05_annotation.yaml"
    shell:
        """
        bakta --db {params.db} \
              --output {params.outdir} \
              --prefix {params.prefix} \
              --threads {threads} \
              --force \
              {input.fasta} > {log} 2>&1
        """