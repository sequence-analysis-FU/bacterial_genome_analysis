rule fastqc_raw:
    input:
        fq=lambda wildcards: samples.at[wildcards.sample, "fq1" if wildcards.idx == '1' else "fq2"]
    output:
        html="results/qc/fastqc_raw/{sample}_{idx}.html",
        zip="results/qc/fastqc_raw/{sample}_{idx}_fastqc.zip"
    params:
        extra="--quiet"
    log:
        "results/logs/fastqc_raw/{sample}_{idx}.log"
    threads: 1
    resources:
        mem_mb=1024
    wrapper:
        "v5.7.0/bio/fastqc"


rule trimmomatic:
    input:
        r1=lambda wildcards: samples.at[wildcards.sample, 'fq1'],
        r2=lambda wildcards: samples.at[wildcards.sample, 'fq2'],
    output:
        r1="results/trimmed/{sample}_1.fastq.gz",
        r2="results/trimmed/{sample}_2.fastq.gz",
        r1_unpaired="results/trimmed/{sample}_1_unpaired.fastq.gz",
        r2_unpaired="results/trimmed/{sample}_2_unpaired.fastq.gz",
    params:
        adapters=config["trimmomatic"]["adapters"],
        illuminaclip=config["trimmomatic"]["illuminaclip"],
        extra=config["trimmomatic"]["extra"],
    log:
        "results/logs/trimmomatic/{sample}.log"
    conda:
        "../envs/qc.yaml"
    threads: 4
    shell:
        """
        trimmomatic PE -threads {threads} \
            {input.r1} {input.r2} \
            {output.r1} {output.r1_unpaired} \
            {output.r2} {output.r2_unpaired} \
            ILLUMINACLIP:{params.adapters}:{params.illuminaclip} \
            {params.extra} 2> {log}
        """


rule fastqc_trimmed:
    input:
        fq="results/trimmed/{sample}_{idx}.fastq.gz"
    output:
        html="results/qc/fastqc_trimmed/{sample}_{idx}.html",
        zip="results/qc/fastqc_trimmed/{sample}_{idx}_fastqc.zip"
    params:
        extra="--quiet"
    log:
        "results/logs/fastqc_trimmed/{sample}_{idx}.log"
    threads: 1
    resources:
        mem_mb=1024
    wrapper:
        "v5.7.0/bio/fastqc"


rule multiqc:
    input:
        raw_fastqc=expand("results/qc/fastqc_raw/{sample}_{idx}_fastqc.zip",sample=samples.index, idx=['1','2']),
        trimmed_fastqc=expand("results/qc/fastqc_trimmed/{sample}_{idx}_fastqc.zip",sample=samples.index, idx=['1','2']),
        trimmomatic=expand("results/logs/trimmomatic/{sample}.log", sample=samples.index),
    output:
        report="results/qc/multiqc/multiqc_report.html",
        data=directory("results/qc/multiqc/multiqc_data"),
    params:
        extra="",
    log:
        "results/logs/multiqc.log"
    conda:
        "../envs/qc.yaml"
    wrapper:
        "v5.7.0/bio/multiqc"


# run seperately before main workflow
rule run_raw_qc:
    input:
        expand("results/qc/fastqc_raw/{sample}_{idx}_fastqc.zip", sample=samples.index, idx=['1','2'])
    output:
        report="results/qc/multiqc_raw/multiqc_report.html",
        data=directory("results/qc/multiqc_raw/multiqc_data"),
    params:
        extra="",
    log:
        "results/logs/multiqc_raw.log"
    conda:
        "../envs/qc.yaml"
    wrapper:
        "v5.7.0/bio/multiqc"