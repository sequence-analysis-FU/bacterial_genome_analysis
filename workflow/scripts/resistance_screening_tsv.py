import os
import pandas as pd

frames = []
for report in snakemake.input.resistance_reports:
    sample = os.path.basename(os.path.dirname(report))
    frame = pd.read_csv(report, sep="\t", comment="#")
    frame.insert(0, "sample", sample)
    frames.append(frame)

pd.concat(frames, ignore_index=True).to_csv(snakemake.output.tsv, sep="\t", index=False)