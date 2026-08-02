import csv
import html
import os
from collections import Counter


def table_rows(counter_obj, top_n):
    rows = []
    for key, count in counter_obj.most_common(top_n):
        rows.append(
            "<tr><td>{}</td><td>{}</td></tr>".format(
                html.escape(str(key)),
                count,
            )
        )
    if not rows:
        rows.append("<tr><td colspan='2'>No entries</td></tr>")
    return "\n".join(rows)


def main():
    input_tsv = snakemake.input.resistance_reports
    output_report = snakemake.output.report
    output_data_dir = snakemake.output.data
    log_file = snakemake.log[0]

    total_hits = 0
    hits_by_sample = Counter()
    hits_by_gene = Counter()
    hits_by_drug_class = Counter()

    with open(input_tsv, newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        for row in reader:
            total_hits += 1

            sample = (row.get("sample") or "").strip() or "unknown"
            hits_by_sample[sample] += 1

            gene = (row.get("Best_Hit_ARO") or "").strip()
            if gene:
                hits_by_gene[gene] += 1

            drug_classes = (row.get("Drug Class") or "").strip()
            if drug_classes:
                for drug_class in drug_classes.split(";"):
                    cleaned = drug_class.strip()
                    if cleaned:
                        hits_by_drug_class[cleaned] += 1

    os.makedirs(output_data_dir, exist_ok=True)

    summary_tsv = os.path.join(output_data_dir, "resistance_summary.tsv")
    with open(summary_tsv, "w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle, delimiter="\t")
        writer.writerow(["metric", "name", "count"])
        writer.writerow(["all_hits", "all_samples", total_hits])
        for sample, count in hits_by_sample.most_common():
            writer.writerow(["hits_by_sample", sample, count])
        for gene, count in hits_by_gene.most_common(20):
            writer.writerow(["top_gene", gene, count])
        for drug_class, count in hits_by_drug_class.most_common(20):
            writer.writerow(["top_drug_class", drug_class, count])

    html_report = """<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"UTF-8\" />
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />
  <title>Resistance Screening Summary</title>
  <style>
    body {{ font-family: Helvetica, Arial, sans-serif; margin: 2rem; color: #1f2937; }}
    h1, h2 {{ margin-bottom: 0.5rem; }}
    .meta {{ margin-bottom: 1.2rem; color: #4b5563; }}
    .cards {{ display: flex; gap: 1rem; flex-wrap: wrap; margin-bottom: 1.5rem; }}
    .card {{ border: 1px solid #d1d5db; border-radius: 8px; padding: 0.8rem 1rem; min-width: 180px; }}
    .card .label {{ font-size: 0.9rem; color: #6b7280; }}
    .card .value {{ font-size: 1.4rem; font-weight: 700; }}
    table {{ border-collapse: collapse; width: 100%; margin-bottom: 1.5rem; }}
    th, td {{ border: 1px solid #e5e7eb; padding: 0.45rem 0.55rem; text-align: left; }}
    th {{ background: #f9fafb; }}
  </style>
</head>
<body>
  <h1>Resistance Screening Summary</h1>
  <div class=\"meta\">Generated from RGI consolidated output: results/resistance_screening/all_samples.tsv</div>

  <div class=\"cards\">
    <div class=\"card\"><div class=\"label\">Total Hits</div><div class=\"value\">{total_hits}</div></div>
    <div class=\"card\"><div class=\"label\">Samples with Hits</div><div class=\"value\">{num_samples}</div></div>
    <div class=\"card\"><div class=\"label\">Unique ARO Hits</div><div class=\"value\">{num_genes}</div></div>
    <div class=\"card\"><div class=\"label\">Unique Drug Classes</div><div class=\"value\">{num_drug_classes}</div></div>
  </div>

  <h2>Hits by Sample</h2>
  <table>
    <thead><tr><th>Sample</th><th>Hits</th></tr></thead>
    <tbody>
      {sample_rows}
    </tbody>
  </table>

  <h2>Top ARO Hits</h2>
  <table>
    <thead><tr><th>Best_Hit_ARO</th><th>Count</th></tr></thead>
    <tbody>
      {gene_rows}
    </tbody>
  </table>

  <h2>Top Drug Classes</h2>
  <table>
    <thead><tr><th>Drug Class</th><th>Count</th></tr></thead>
    <tbody>
      {drug_rows}
    </tbody>
  </table>
</body>
</html>
""".format(
        total_hits=total_hits,
        num_samples=len(hits_by_sample),
        num_genes=len(hits_by_gene),
        num_drug_classes=len(hits_by_drug_class),
        sample_rows=table_rows(hits_by_sample, 1000),
        gene_rows=table_rows(hits_by_gene, 20),
        drug_rows=table_rows(hits_by_drug_class, 20),
    )

    with open(output_report, "w", encoding="utf-8") as handle:
        handle.write(html_report)

    with open(log_file, "w", encoding="utf-8") as handle:
        handle.write("Created resistance summary report from all_samples.tsv\n")
        handle.write("Total hits: {}\n".format(total_hits))


main()
