from pathlib import Path
import matplotlib.pyplot as plt
from Bio import Phylo


def plot_tree(tree_file, output_path):
    tree = Phylo.read(str(tree_file), "newick")

    fig = plt.figure(figsize=(12, 8), dpi=300)
    ax = fig.add_subplot(1, 1, 1)
    Phylo.draw(tree, axes=ax, do_show=False)

    ax.set_title(f"Maximum-Likelihood Phylogenetic Tree: {tree_file.stem}", fontsize=14, pad=20)
    ax.set_xlabel("Substitution distance", fontsize=10)
    ax.set_ylabel("Samples", fontsize=10)
    plt.tight_layout()
    plt.savefig(output_path, bbox_inches="tight")
    plt.close(fig)


def main():
    tree_dir = Path(snakemake.input.tree)
    out_dir = Path(snakemake.output.plot_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    tree_files = sorted(tree_dir.glob("*.treefile"))
    if not tree_files:
        raise FileNotFoundError("No tree files found in the tree directory")

    for tree_file in tree_files:
        protein = tree_file.stem
        out_path = out_dir / f"{protein}.png"
        plot_tree(tree_file, out_path)


main()