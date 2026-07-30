# Workflow Overview

The pipeline performs bacterial genome analysis from raw sequencing reads to genome assembly, annotation, comparative genomics, antibiotic resistance screening, and optional protein phylogenetic analysis.

<p align="center">
  <img src="https://github.com/user-attachments/assets/f4cec2c2-3e85-459f-8a40-6dd814be9210"
       alt="Workflow overview"
       width="700">
</p>


## Running the Pipeline

Run the workflow with Snakemake:

```bash
snakemake --use-conda --cores <N>
```

## Configuration

Specify the sample sheet:

```yaml
samples: "config/samples.tsv"
```

All settings are configured in `config/config.yaml`.

Enable or disable optional workflow modules:

```yaml
short_reads:
  enabled: true

resistance_screening:
  enabled: true

protein_analysis:
  enabled: true
```

Tool-specific parameters (e.g. `fastp`, `Flye`, `Bakta`, `BLAST`) and database locations can also be configured in `config.yaml`.

For optional protein analysis, specify the input protein FASTA:

```yaml
protein_set:
  path: "resources/protein_set.faa"
```

## Repository Structure

```text
.
├── config
│   ├── config.yaml
│   └── samples.tsv
├── resources
│   └── protein_set.faa
├── results
│   ├── annotation
│   ├── assembly
│   ├── comparative
│   ├── polishing
│   ├── protein_analysis
│   ├── qc
│   ├── resistance_screening
│   ├── trimmed
│   └── logs
├── workflow
│   ├── Snakefile
│   ├── envs
│   ├── rules
│   └── scripts
└── README.md
```
