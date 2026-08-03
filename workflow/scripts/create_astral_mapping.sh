cat ${snakemake_input[trees]} \
| tr '(),:;' ' ' \
| tr ' ' '\n' \
| grep -E '^_?R?_?sample[0-9]+' \
| sort -u \
| awk '
{
    name=$0
    clean=name
    sub(/^_R_/, "", clean)
    split(clean,a,"_")
    species=a[1]
    print name, species
}' \
> ${snakemake_output[mapping]}