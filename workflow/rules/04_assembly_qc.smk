#Quast quality control
rule quast_qc:
    input:
        fasta = get_final_assembly  #get the right polished assembly with the function
    output:
        dir = directory("results/qc/quast/{sample}"),
        summary = "results/qc/quast/{sample}/report.txt"
    threads: 4
    conda: "../envs/assembly_qc.yaml"
    shell:
        """
        quast.py {input.fasta} -o {output.dir} --threads {threads} --bacteria
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
        out_name = "{sample}",
        out_path = "results/qc/busco"
    threads: 8
    conda: "../envs/assembly_qc.yaml"
    shell:
        """
        busco -i {input.fasta} -o {params.out_name} --out_path {params.out_path} -m genome -l {params.lineage} --cpu {threads} --force
        """

#MultiQC for the single QCs of the single assemblies
rule multiqc_assembly:
    input:
        quast = expand("results/qc/quast/{sample}/report.txt", sample=samples.index),
        busco = expand("results/qc/busco/{sample}/short_summary.specific.bacteria_odb10.{sample}.txt", sample=samples.index)
    output:
        report = "results/qc/multiqc/multiqc_assembly_report.html"
    conda: "../envs/assembly_qc.yaml"
    shell:
        "multiqc results/qc/quast results/qc/busco -o results/qc/multiqc -n multiqc_assembly_report.html"