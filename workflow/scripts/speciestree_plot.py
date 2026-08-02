from pathlib import Path
import matplotlib.pyplot as plt
from Bio import Phylo


def main():
    tree_input = Path(snakemake.input.tree)
    if tree_input.is_dir():
        tree_files = sorted(tree_input.glob("*.treefile"))
        if not tree_files:
            raise FileNotFoundError("No tree files found in the tree directory")
        tree_file = tree_files[0]
    else:
        tree_file = tree_input

    tree = Phylo.read(str(tree_file), "newick")

    fig = plt.figure(figsize=(12, 8), dpi=300)
    ax = fig.add_subplot(1, 1, 1)
    Phylo.draw(
        tree,
        axes=ax,
        do_show=False)

    ax.set_title("Species Tree (ASTRAL/ASTER)", fontsize=14, pad=20)
    ax.set_xlabel("Coalescent units", fontsize=10)
    ax.set_ylabel("Species", fontsize=10)
    plt.tight_layout()
    plt.savefig(snakemake.output.plot, bbox_inches="tight")


main()