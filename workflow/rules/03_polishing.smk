#Map long reads
rule minimap2_long:
    input:
        target = "results/assembly/{sample}/assembly.fasta",
        query = "results/trimmed/{sample}_long.fastq.gz"
    output:
        paf = "results/polishing/{sample}/long_reads_mapping.paf"
    threads: 8
    conda: "../envs/03_polishing.yaml"
    shell: "minimap2 -t {threads} -x map-ont {input.target} {input.query} > {output.paf}"

#Racon polishing (with long reads)
rule racon_polishing:
    input:
        reads = "results/trimmed/{sample}_long.fastq.gz",
        paf = "results/polishing/{sample}/long_reads_mapping.paf",
        assembly = "results/assembly/{sample}/assembly.fasta"
    output:
        fasta = "results/polishing/{sample}/racon_polished.fasta"
    threads: 8
    conda: "../envs/03_polishing.yaml"
    shell: "racon -t {threads} {input.reads} {input.paf} {input.assembly} > {output.fasta}"

if ENABLE_SHORT_READS:
    #Map short reads
    rule bwa_mem_short:
        input:
            ref = "results/polishing/{sample}/racon_polished.fasta", #--> polish with short reads on the already polished assembly with long reads
            r1 = "results/trimmed/{sample}_1.fastq.gz",
            r2 = "results/trimmed/{sample}_2.fastq.gz"
        output:
            bam = "results/polishing/{sample}/short_reads_mapped.bam"
        threads: 8
        conda: "../envs/03_polishing.yaml"
        log: "results/logs/bwa/{sample}.log"
        shell:
            """
            bwa index {input.ref}
            bwa mem -t {threads} {input.ref} {input.r1} {input.r2} 2> {log} | \
            samtools view -Sb - | samtools sort -o {output.bam}
            samtools index {output.bam}
            """

    #Pilon polishing (with short reads) (after Racon polishing with long reads)
    rule pilon_polishing:
        input:
            genome = "results/polishing/{sample}/racon_polished.fasta",
            bam = "results/polishing/{sample}/short_reads_mapped.bam"
        output:
            fasta = "results/polishing/{sample}/pilon_polished.fasta"
        params:
            outdir = "results/polishing/{sample}"
        conda: "../envs/03_polishing.yaml"
        shell:
            "pilon --genome {input.genome} --bam {input.bam} --outdir {params.outdir} --output pilon_polished"