if ENABLE_PROTEIN_ANALYSIS:

    rule build_sample_blast_db:
        input:
            predicted_genes="results/annotation/{sample}/{sample}.faa"
        output:
            pin="results/protein_analysis/blast_db/{sample}.pin",
            phr="results/protein_analysis/blast_db/{sample}.phr",
            psq="results/protein_analysis/blast_db/{sample}.psq"
        log:
            "results/logs/build_blast_db/{sample}.log"
        conda:
            "../envs/08_protein_analysis.yaml"
        shell:
            """
            makeblastdb -in {input.predicted_genes} -dbtype prot -out results/protein_analysis/blast_db/{wildcards.sample} > {log} 2>&1
            """


    rule blastp_search:
        input:
            protein_set=config["protein_set"]["path"],
            db= rules.build_sample_blast_db.output
        output:
            report="results/protein_analysis/blast/{sample}.tsv"
        params:
            extra=config["blastp"]["extra"],
            max_target_seqs=config["blastp"]["max_target_seqs"],
        log:
            "results/logs/blastp_search/{sample}.log"
        conda:
            "../envs/08_protein_analysis.yaml"
        threads: 4
        shell:
        #output format needs to be readable by python script.
            "blastp {params.extra} -query {input.protein_set} -db results/protein_analysis/blast_db/{wildcards.sample} -outfmt '6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore' -num_threads {threads} -max_target_seqs {params.max_target_seqs} -out {output.report} > {log} 2>&1"


    rule prepare_ortholog_fastas:
        input:
            blastp_reports=expand("results/protein_analysis/blast/{sample}.tsv", sample=samples.index),
            query_fasta=config["protein_set"]["path"],
            sample_fastas=expand("results/annotation/{sample}/{sample}.faa", sample=samples.index)
        output:
            ortholog_dir=directory("results/protein_analysis/orthologs"),
            summary="results/protein_analysis/ortholog_summary.tsv"
        log:
            "results/logs/prepare_ortholog_fastas.log"
        conda:
            "../envs/08_protein_analysis.yaml"
        script:
            "../scripts/collect_orthologs.py"

    # if we dont want to loop threw the directory, we could also use checkpoints and then do specific for each fasta.
    rule msa:
        input:
            ortholog_dir=rules.prepare_ortholog_fastas.output.ortholog_dir
        output:
            alignment_dir=directory("results/protein_analysis/alignments"),
            done="results/protein_analysis/alignments/.done"
        params:
            extra=config["msa"]["extra"],
        log:
            "results/logs/build_alignments.log"
        conda:
            "../envs/08_protein_analysis.yaml"
        threads: 4
        shell:
            r"""
            shopt -s nullglob
            for fasta in {input.ortholog_dir}/*.faa; do
                protein=$(basename "$fasta" .faa)
                seq_count=$(grep -c '^>' "$fasta")
                if [[ "$seq_count" -lt 3 ]]; then
                    continue
                fi

                aln="{output.alignment_dir}/$protein.aln.faa"
                mafft {params.extra} --thread {threads} --auto --reorder --amino "$fasta" > "$aln" 2>> {log}
            done
            touch {output.done}
            """


    rule trees:
        input:
            alignment_dir=rules.msa.output.alignment_dir
        output:
            tree_dir=directory("results/protein_analysis/trees"),
            done="results/protein_analysis/trees/.done"
        params:
            iqtree_extra=config["phylogenetic_tree"]["extra"],
        log:
            "results/logs/build_trees.log"
        conda:
            "../envs/08_protein_analysis.yaml"
        threads: 4
        shell:
            r"""
            shopt -s nullglob
            for aln in {input.alignment_dir}/*.aln.faa; do
                protein=$(basename "$aln" .aln.faa)
                iqtree2 {params.iqtree_extra} -s "$aln" -nt {threads} -pre "{output.tree_dir}/$protein" >> {log} 2>&1
            done
            touch {output.done}
            """


    rule plot_phylogenetic_tree:
        input:
            tree=rules.trees.output.tree_dir,
            done=rules.trees.output.done
        output:
            plot_dir=directory("results/protein_analysis/phylogenetic_tree_plots")
        log:
            "results/logs/plot_phylogenetic_tree.log"
        conda:
            "../envs/08_protein_analysis.yaml"
        script:
            "../scripts/phylotree_plot.py"