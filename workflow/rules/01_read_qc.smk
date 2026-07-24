# --------------------------------------------------------------------------
# long reads

rule sequali_raw:
    input:
        sample=lambda wildcards: samples.at[wildcards.sample, "long_fq"],
    output:
        json="results/qc/sequali_raw/{sample}.json",
        html="results/qc/sequali_raw/{sample}.html",
    log:
        "results/logs/sequali_raw/{sample}.log"
    threads: 1
    resources:
        mem_mb=1024,
    params:
        extra=config["sequali"]["extra"],
    wrapper:
        "v9.6.0/bio/sequali"

rule fastplong:
    input:
        fq=lambda wildcards: samples.at[wildcards.sample, "long_fq"],
    output:
        trimmed="results/trimmed/{sample}_long.fastq.gz",
        html="results/qc/fastplong/{sample}.html",
        json="results/qc/fastplong/{sample}.json",
    conda:
        "../envs/01_read_qc.yaml"
    log:
        "results/logs/fastplong/{sample}.log"
    threads: 4
    params:
        extra=config["fastplong"]["extra"],
    shell:
        """
        fastplong {params.extra} \
            -i {input.fq} \
            -o {output.trimmed} \
            -h {output.html} \
            -j {output.json} \
            -w {threads} \
            > {log} 2>&1
        """

rule sequali_trimmed:
    input:
        sample="results/trimmed/{sample}_long.fastq.gz",
    output:
        json="results/qc/sequali_trimmed/{sample}.json",
        html="results/qc/sequali_trimmed/{sample}.html",
    log:
        "results/logs/sequali_trimmed/{sample}.log"
    threads: 1
    resources:
        mem_mb=1024,
    params:
        extra=config["sequali"]["extra"],
    wrapper:
        "v9.6.0/bio/sequali"

rule multiqc_long:
    input:
        sequali_raw=expand("results/qc/sequali_raw/{sample}.json", sample=samples.index),
        sequali_trimmed=expand("results/qc/sequali_trimmed/{sample}.json", sample=samples.index),
        fastplong=expand("results/qc/fastplong/{sample}.json", sample=samples.index),
    output:
        report="results/qc/multiqc_long/multiqc_report.html",
        data=directory("results/qc/multiqc_long/multiqc_data"),
    params:
        extra=config["multiqc"]["extra"],
    log:
        "results/logs/multiqc_long.log"
    wrapper:
        "v5.7.0/bio/multiqc"


# --------------------------------------------------------------------------
# short reads (optional)

if ENABLE_SHORT_READS:

    rule fastqc_raw:
        input:
            fq=lambda wildcards: samples.at[wildcards.sample, "fq1" if wildcards.idx == '1' else "fq2"]
        output:
            html="results/qc/fastqc_raw/{sample}_{idx}.html",
            zip="results/qc/fastqc_raw/{sample}_{idx}_fastqc.zip"
        params:
            extra=config["fastqc"]["extra"],
        log:
            "results/logs/fastqc_raw/{sample}_{idx}.log"
        threads: 1
        resources:
            mem_mb=1024
        wrapper:
            "v5.7.0/bio/fastqc"


    rule fastp:
        input:
            sample=lambda wildcards: [
                samples.at[wildcards.sample, 'fq1'],
                samples.at[wildcards.sample, 'fq2'],
            ]
        output:
            trimmed=[
                "results/trimmed/{sample}_1.fastq.gz",
                "results/trimmed/{sample}_2.fastq.gz",
            ],
            html="results/qc/fastp/{sample}.html",
            json="results/qc/fastp/{sample}.json",
        params:
            extra=config["fastp"]["extra"],
        log:
            "results/logs/fastp/{sample}.log"
        threads: 4
        wrapper:
            "v3.3.3/bio/fastp"


    rule fastqc_trimmed:
        input:
            fq="results/trimmed/{sample}_{idx}.fastq.gz"
        output:
            html="results/qc/fastqc_trimmed/{sample}_{idx}.html",
            zip="results/qc/fastqc_trimmed/{sample}_{idx}_fastqc.zip"
        params:
            extra=config["fastqc"]["extra"],
        log:
            "results/logs/fastqc_trimmed/{sample}_{idx}.log"
        threads: 1
        resources:
            mem_mb=1024
        wrapper:
            "v5.7.0/bio/fastqc"


    rule multiqc_short:
        input:
            fastqc_raw=expand("results/qc/fastqc_raw/{sample}_{idx}_fastqc.zip",sample=samples.index, idx=['1','2']),
            fastqc_trimmed=expand("results/qc/fastqc_trimmed/{sample}_{idx}_fastqc.zip",sample=samples.index, idx=['1','2']),
            fastp=expand("results/qc/fastp/{sample}.json", sample=samples.index),
        output:
            report="results/qc/multiqc_short/multiqc_report.html",
            data=directory("results/qc/multiqc_short/multiqc_data"),
        params:
            extra=config["multiqc"]["extra"],
        log:
            "results/logs/multiqc.log"
        wrapper:
            "v5.7.0/bio/multiqc"