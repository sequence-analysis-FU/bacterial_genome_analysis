if ENABLE_RESISTANCE_SCREENING:

    rule download_card_db:
        output:
            done=config["card"]["db_path"] + "/.done"
        params:
            db_path=config["card"]["db_path"]
        log:
            "results/logs/install_card_db.log"
        conda:
            "../envs/06_resistance_genes.yaml"
        shell:
            """
            mkdir -p {params.db_path}
            (cd {params.db_path} && rgi load --local) > {log} 2>&1
            touch {params.db_path}/.done
            """
    
    rule resistance_screening:
        input:
            predicted_genes="results/annotation/{sample}/{sample}.faa",
            db = rules.download_card_db.output.done
        output:
            report="results/resistance_screening/{sample}/{sample}.txt"
        params:
            extra=config["screening"]["extra"],
            prefix="results/resistance_screening/{sample}/{sample}"
        log:
            "results/logs/resistance_screening/{sample}.log"
        conda:
            "../envs/06_resistance_genes.yaml"
        threads: 4
        shell:
            "rgi main {params.extra} --input_type protein -i {input.predicted_genes} -o {params.prefix} > {log} 2>&1"


    rule resistance_screening_tsv:
        input:
            resistance_reports=expand("results/resistance_screening/{sample}/{sample}.txt", sample=samples.index)
        output:
            tsv="results/resistance_screening/all_samples.tsv"
        log:
            "results/logs/resistance_screening_tsv.log"
        script:
            "../scripts/resistance_screening_tsv.py"

    rule multiqc_resistance:
        input:
            resistance_reports= "results/resistance_screening/all_samples.tsv"
        output:
            report="results/qc/multiqc_resistance/multiqc_report.html",
            data=directory("results/qc/multiqc_resistance/multiqc_data")
        log:
            "results/logs/multiqc_resistance.log"
        script:
            "../scripts/resistance_summary.py"