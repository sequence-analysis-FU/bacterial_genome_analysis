if ENABLE_RESISTANCE_SCREENING:

    rule download_card_db:
        output:
            db_path=config["card"]["db_path"]
        log:
            "results/logs/install_card_db.log"
        conda:
            "../envs/06_resistance_genes.yaml"
        shell:
            """
            rgi load --local {output.db_path} > {log} 2>&1
            """
    
    rule resistance_screening:
        input:
            predicted_genes="results/annotation/{sample}/{sample}.faa",
            db = rules.download_card_db.output.db_path
        output:
            report="results/resistance_screening/{sample}/{sample}.txt"
        params:
            extra=config["screening"]["extra"],
        log:
            "results/logs/resistance_screening/{sample}.log"
        conda:
            "../envs/06_resistance_genes.yaml"
        threads: 4
        shell:
            "rgi {params.extra} -i {input.predicted_genes} -o {output.report} > {log} 2>&1"


    rule multiqc_resistance:
        input:
            resistance_reports=expand("results/resistance_screening/{sample}/{sample}.txt", sample=samples.index),
        output:
            report="results/qc/multiqc_resistance/multiqc_report.html",
            data=directory("results/qc/multiqc_resistance/multiqc_data")
        params:
            extra=config["multiqc"]["extra"],
        log:
            "results/logs/multiqc_resistance.log"
        wrapper:
            "v5.7.0/bio/multiqc"


    rule resistance_screening_tsv:
        input:
            resistance_reports=expand("results/resistance_screening/{sample}/{sample}.txt", sample=samples.index)
        output:
            tsv="results/resistance_screening/all_samples.tsv"
        run:
            import os
            import pandas as pd

            frames = []
            for report in input.resistance_reports:
                sample = os.path.basename(os.path.dirname(report))
                frame = pd.read_csv(report, sep="\t", comment="#")
                frame.insert(0, "sample", sample)
                frames.append(frame)

            pd.concat(frames, ignore_index=True).to_csv(output.tsv, sep="\t", index=False)