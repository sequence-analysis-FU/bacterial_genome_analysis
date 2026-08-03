import os
from Bio import SeqIO


def load_fasta(path):
    return {record.id: record for record in SeqIO.parse(path, "fasta")}


def main():
    # Use the blast report filenames as sample names
    sample_names = [os.path.basename(p).removesuffix(".tsv") for p in snakemake.input.blastp_reports]
    sample_to_faa = {s: f for s, f in zip(sample_names, snakemake.input.sample_fastas)}
    os.makedirs(snakemake.output.ortholog_dir, exist_ok=True)

    # Keep the first BLAST hit found, we assume that's the best one
    selected = {}
    seen = set()
    for sample, report in zip(sample_names, snakemake.input.blastp_reports):
        if os.path.getsize(report) == 0:
            continue
        with open(report, encoding="utf-8") as handle:
            for line in handle:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                parts = line.split("\t")
                if len(parts) < 2:
                    continue
                qid, sid = parts[0].split()[0], parts[1].split()[0]
                if (sample, qid) in seen:
                    continue
                seen.add((sample, qid))
                selected.setdefault(qid, {})[sample] = sid

    with open(snakemake.output.summary, "w", encoding="utf-8") as handle:
        handle.write("query\tsample\tsubject\n")
        for qid in sorted(selected):
            for sample, sid in sorted(selected[qid].items()):
                handle.write(f"{qid}\t{sample}\t{sid}\n")

    # Build fasta
    query_by_id = {rec.id: rec for rec in SeqIO.parse(snakemake.input.query_fasta, "fasta")}
    for qid, qrec in query_by_id.items():
        records = [qrec]
        for sample in sample_names:
            sid = selected.get(qid, {}).get(sample)
            if not sid:
                continue
            seqs = load_fasta(sample_to_faa[sample])
            if sid not in seqs:
                continue
            hit = seqs[sid]
            hit.id = f"{sample}|{hit.id}"
            hit.description = ""
            records.append(hit)
        with open(os.path.join(snakemake.output.ortholog_dir, f"{qid}.faa"), "w", encoding="utf-8") as handle:
            SeqIO.write(records, handle, "fasta")


main()