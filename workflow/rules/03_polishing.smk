#Map long reads
rule minimap2_long:
    input:
        target = "results/assembly/{sample}/assembly.fasta",
        query = "results/trimmed/{sample}_long.fastq.gz"
    output:
        paf = "results/polishing/{sample}/long_reads_mapping.paf"
    params:
        preset = lambda wildcards: config["minimap2_long"]["params"]["PacBio"] if samples.at[wildcards.sample, "long_platform"] == "PacBio" \
                 else (config["minimap2_long"]["params"]["MinION"] if samples.at[wildcards.sample, "long_platform"] == "MinION" \
                 else config["minimap2_long"]["params"]["default"])
    threads: 8
    conda: "../envs/03_polishing.yaml"
    log:
        "results/logs/minimap2/{sample}.log"
    shell:
        "minimap2 -t {threads} -x {params.preset} {input.target} {input.query} > {output.paf} 2> {log}"

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
    log:
        "results/logs/racon/{sample}.log"
    shell:
        "racon -t {threads} {input.reads} {input.paf} {input.assembly} > {output.fasta} 2> {log}"

if ENABLE_SHORT_READS:
    # Create BWA index files explicitly so Snakemake can track them.
    rule bwa_index_short:
        input:
            ref = "results/polishing/{sample}/racon_polished.fasta"
        output:
            multiext("results/polishing/{sample}/racon_polished.fasta", ".amb", ".ann", ".bwt", ".pac", ".sa")
        log:
            "results/logs/bwa_index/{sample}.log"
        conda:
            "../envs/03_polishing.yaml"
        shell:
            "bwa index {input.ref} 2> {log}"

    #Map short reads
    rule bwa_mem_short:
        input:
            reads = lambda wildcards: [
                samples.at[wildcards.sample, "fq1"],
                samples.at[wildcards.sample, "fq2"],
            ],
            index = multiext("results/polishing/{sample}/racon_polished.fasta", ".amb", ".ann", ".bwt", ".pac", ".sa")
        output:
            temp("results/polishing/{sample}/to_polish.bam")
        log:
            "results/logs/bwa_mem/{sample}.log"
        conda:
            "../envs/03_polishing.yaml"
        shell:
            "bwa mem results/polishing/{wildcards.sample}/racon_polished.fasta {input.reads} 2> {log} | samtools view -bS - > {output} 2>> {log}"

    # Sort the polished BAM file
    rule sort_polishing_bam:
        input:
            "results/polishing/{sample}/to_polish.bam"
        output:
            bam = "results/polishing/{sample}/to_polish_sorted.bam",
            bai = "results/polishing/{sample}/to_polish_sorted.bam.bai"
        log:
            "results/logs/sort_polishing_bam/{sample}.log"
        conda:
            "../envs/03_polishing.yaml"
        shell:
            "samtools sort {input} -o {output.bam} 2> {log} && samtools index {output.bam} 2>> {log}"

    #Pilon polishing (with short reads) (after Racon polishing with long reads)
    rule pilon_polishing:
        input:
            assembly = "results/polishing/{sample}/racon_polished.fasta",
            bam = "results/polishing/{sample}/to_polish_sorted.bam"
        output:
            fasta = "results/polishing/{sample}/pilon_polished.fasta"
        log:
            "results/logs/pilon/{sample}.log"
        params:
            java_mem = config["pilon"]["params"]["java_mem"]
        conda:
            "../envs/03_polishing.yaml"
        shell:
            "export _JAVA_OPTIONS=\"-Xmx{params.java_mem}\" && pilon --genome {input.assembly} --frags {input.bam} --outdir results/polishing/{wildcards.sample} --output pilon_polished > {log} 2>&1"