cat ${snakemake_input[trees]} \
| tr '(),:;' ' ' \
| tr ' ' '\n' \
| sort -u \
| awk -v samples="${snakemake_params[samples]}" '
BEGIN {
    n = split(samples, sample_list, " ")
}
# Values start with a digit, sign or dot. Leaf names start with a letter or underscore
!/^[A-Za-z_]/ { next }
{
    name = $0
    clean = name
    sub(/^_R_/, "", clean)
    # match against the real sample names from the samplesheet. Anything else to "external"
    species = "external"
    for (i = 1; i <= n; i++) {
        s = sample_list[i]
        if (clean == s || index(clean, s "_") == 1) {
            species = s
            break
        }
    }
    print name, species
}' \
> ${snakemake_output[mapping]}