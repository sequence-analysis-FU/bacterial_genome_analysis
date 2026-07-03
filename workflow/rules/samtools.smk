rule sam_to_bam:
    input:
        "results/sam/{sample}.sam"
    output:
        "results/bam/{sample}.raw.bam"
    conda:
        "../envs/samtools.yaml"
    log:
        "results/logs/sam_to_bam/{sample}.log"
    shell:
        "samtools view -bS {input} > {output} 2> {log}"

rule sort_bam:
    input:
        "results/bam/{sample}.raw.bam"
    output:
        "results/bam_sorted/{sample}_sorted.bam"
    threads: 4 
    conda:
        "../envs/samtools.yaml"
    log: "results/logs/sort_bam/{sample}.log"
    shell:
        "samtools sort -@ {threads} {input} -o {output} 2> {log}"

rule index_bam:
    input:
        "results/bam_sorted/{sample}_sorted.bam"
    output:
        "results/bam_sorted/{sample}_sorted.bam.bai"
    conda:
        "../envs/samtools.yaml"
    log: "results/logs/index_bam/{sample}.log"
    shell:
        "samtools index {input} 2> {log}"

rule generate_idxstats:
    input:
        bam = "results/bam_sorted/{sample}_sorted.bam",
        bai = "results/bam_sorted/{sample}_sorted.bam.bai"
    output:
        "results/stats/{sample}.stats"
    conda:
        "../envs/samtools.yaml"
    log: "results/logs/generate_idxstats/{sample}.log"
    shell:
        "samtools idxstats {input.bam} > {output} 2> {log}"

rule filter:
    input:
        bam = "results/bam_sorted/{sample}_sorted.bam",
        bai = "results/bam_sorted/{sample}_sorted.bam.bai"
    output:
        "results/filtered/{sample}_filtered.bam"
    conda:
        "../envs/samtools.yaml"
    log: "results/logs/filter/{sample}.log"
    shell:
        "samtools view -b {input.bam} NZ_AMKI01000040.1 NZ_AMKI01000041.1 > {output} 2> {log}"
