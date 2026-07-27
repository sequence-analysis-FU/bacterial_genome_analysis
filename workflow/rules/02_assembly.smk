rule flye_assembly:
    input:
        reads = "results/trimmed/{sample}_long.fastq.gz"
    output:
        fasta = "results/assembly/{sample}/assembly.fasta",
        gfa = "results/assembly/{sample}/assembly_graph.gfa"
    params:
        # use the 'long_platform' column from the sample sheet to identify which kind of long reads is being used
        mode = lambda wildcards: config["flye"]["params"]["PacBio"] if samples.at[wildcards.sample, "long_platform"] == "PacBio" \
               else (config["flye"]["params"]["MinION"] if samples.at[wildcards.sample, "long_platform"] == "MinION" \
               else config["flye"]["params"]["default"]),
        outdir = "results/assembly/{sample}"
    log:
        "results/logs/assembly/{sample}.log"
    threads: 8
    conda:
        "../envs/02_assembly.yaml"
    shell:
        """
        flye {params.mode} {input.reads} --out-dir {params.outdir} --threads {threads} > {log} 2>&1
        """