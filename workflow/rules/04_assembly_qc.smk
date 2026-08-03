# -------------------------------------------------------------------
# prepolishing

rule quast_qc_prepolish:
    input:
        fasta = "results/assembly/{sample}/assembly.fasta"
    output:
        dir = directory("results/qc/quast_pre/{sample}"),
        summary = "results/qc/quast_pre/{sample}/report.txt"
    log:
        "results/logs/quast_pre/{sample}.log"
    threads: 4
    conda: "../envs/04_assembly_qc.yaml"
    shell:
        """
        quast.py {input.fasta} -o {output.dir} --threads {threads} --label {wildcards.sample} > {log} 2>&1
        """

rule busco_qc_prepolish:
    input:
        fasta = "results/assembly/{sample}/assembly.fasta"
    output:
        dir = directory("results/qc/busco_pre/{sample}"),
        short_summary = "results/qc/busco_pre/{sample}/short_summary.specific.bacteria_odb10.{sample}.txt"
    params:
        lineage = "bacteria_odb10",
        out_name = lambda wildcards: wildcards.sample,
        out_path = "results/qc/busco_pre",
        download_path = "resources/busco_downloads"
    threads: 8
    conda: "../envs/04_assembly_qc.yaml"
    log:
        "results/logs/busco_pre/{sample}.log"
    shell:
        """
        busco -i {input.fasta} -o {params.out_name} --out_path {params.out_path} -m genome -l {params.lineage} --download_path {params.download_path} --cpu {threads} --force > {log} 2>&1
        """



# -------------------------------------------------------------------
# postpolishing

#Quast quality control
rule quast_qc:
    input:
        fasta = get_final_assembly  #get the right polished assembly with the function
    output:
        dir = directory("results/qc/quast/{sample}"),
        summary = "results/qc/quast/{sample}/report.txt"
    threads: 4
    conda: "../envs/04_assembly_qc.yaml"
    log:
        "results/logs/quast/{sample}.log"
    shell:
        """
        quast.py {input.fasta} -o {output.dir} --threads {threads} --label {wildcards.sample} > {log} 2>&1
        """

#BUSCO quality control for consistency
rule busco_qc:
    input:
        fasta = get_final_assembly
    output:
        dir = directory("results/qc/busco/{sample}"),
        short_summary = "results/qc/busco/{sample}/short_summary.specific.bacteria_odb10.{sample}.txt"
    params:
        lineage = "bacteria_odb10",
        out_name = lambda wildcards: wildcards.sample,
        out_path = "results/qc/busco",
        download_path = "resources/busco_downloads"
    threads: 8
    conda: "../envs/04_assembly_qc.yaml"
    log:
        "results/logs/busco/{sample}.log"
    shell:
        """
        busco -i {input.fasta} -o {params.out_name} --out_path {params.out_path} -m genome -l {params.lineage} --download_path {params.download_path} --cpu {threads} --force > {log} 2>&1
        """

#MultiQC for the single QCs of the single assemblies
rule multiqc_assembly:
    input:
        quast = expand("results/qc/quast/{sample}/report.txt", sample=samples.index),
        busco = expand("results/qc/busco/{sample}/short_summary.specific.bacteria_odb10.{sample}.txt", sample=samples.index),
        quast_pre = expand("results/qc/quast_pre/{sample}/report.txt", sample=samples.index),
        busco_pre = expand("results/qc/busco_pre/{sample}/short_summary.specific.bacteria_odb10.{sample}.txt", sample=samples.index),
    output:
        report = "results/qc/multiqc_assembly/multiqc_assembly_report.html",
        data = directory("results/qc/multiqc_assembly/multiqc_data")
    params:
        extra = config["multiqc_assembly"]["extra"],
    log:
        "results/logs/multiqc_assembly.log"
    wrapper:
        "v5.7.0/bio/multiqc"