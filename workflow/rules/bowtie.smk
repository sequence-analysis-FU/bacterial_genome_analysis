#Here there are only the rules for running bowtie
rule bowtie2_index:
    input:
        ref = config["ref"]
    output:
        multiext("results/index/genome", ".1.bt2", ".2.bt2", ".3.bt2", ".4.bt2", ".rev.1.bt2", ".rev.2.bt2")
    conda:
        "../envs/bowtie.yaml"
    threads: 4
    log: "results/logs/bowtie2_index.log"
    params:
      prefix = "results/index/genome"
    shell:
        "bowtie2-build --threads {threads} {input.ref} {params.prefix} 2> {log}" 

rule bowtie2_map:
    input:
        r1=lambda wildcards: samples.at[wildcards.sample, 'fq1'] if config.get("skip_trimming", False)
            else f"results/trimmed/{wildcards.sample}_1.fastq.gz",
        r2=lambda wildcards: samples.at[wildcards.sample, 'fq2'] if config.get("skip_trimming", False)
            else f"results/trimmed/{wildcards.sample}_2.fastq.gz",
        index=multiext("results/index/genome", ".1.bt2", ".2.bt2", ".3.bt2", ".4.bt2", ".rev.1.bt2", ".rev.2.bt2")
    output:
        "results/sam/{sample}.sam"
    conda:
        "../envs/bowtie.yaml"
    threads: 4 
    log: "results/logs/bowtie2_map/{sample}.log"
    params:
        index_prefix="results/index/genome",
        N = config["bowtie2"]["N"],
        L = config["bowtie2"]["L"],
        D = config["bowtie2"]["D"],
        R = config["bowtie2"]["R"],
        X = config["bowtie2"]["X"],
        sensitivity = config["bowtie2"]["sensitivity"],
        extra = config["bowtie2"]["extra"]
    shell:
        """
        bowtie2 -p {threads} -1 {input.r1} -2 {input.r2} -S {output} -x {params.index_prefix} -N {params.N} -L {params.L} -D {params.D} -R {params.R} -X {params.X} {params.sensitivity} {params.extra} 2> {log}
        """
