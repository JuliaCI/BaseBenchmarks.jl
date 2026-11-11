# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org/
#
# Contributed by Daniel Jones
# Fix from David Campbell

const variants = [
      r"agggtaaa|tttaccct",
      r"[cgt]gggtaaa|tttaccc[acg]",
      r"a[act]ggtaaa|tttacc[agt]t",
      r"ag[act]gtaaa|tttac[agt]ct",
      r"agg[act]taaa|ttta[agt]cct",
      r"aggg[acg]aaa|ttt[cgt]ccct",
      r"agggt[cgt]aa|tt[acg]accct",
      r"agggta[cgt]a|t[acg]taccct",
      r"agggtaa[cgt]|[acg]ttaccct"
]

const subs = (
    ("B" => "(c|g|t)"),
    ("D" => "(a|g|t)"),
    ("H" => "(a|c|t)"),
    ("K" => "(g|t)"),
    ("M" => "(a|c)"),
    ("N" => "(a|c|g|t)"),
    ("R" => "(a|g)"),
    ("S" => "(c|g)"),
    ("V" => "(a|c|g)"),
    ("W" => "(a|t)"),
    ("Y" => "(c|t)")
)

function perf_regex_dna()
    infile = joinpath(SHOOTOUT_DATA_PATH, "regexdna-input.txt")
    seq = read(infile, String)
    l1 = length(seq)

    seq = replace(seq, r">.*\n|\n" => "")
    l2 = length(seq)

    kk = 0
    for v in variants
        k = 0
        for m in eachmatch(v, seq)
            k += 1
        end
        kk += k
    end

    try
        # VERSION > 1.7-dev
        seq = replace(seq, subs...)
    catch ex
        ex isa MethodError || rethrow()
        # semi-optimized regex
        r = Regex(join(first.(subs), "|"))
        repl = Dict(subs)
        seq = replace(seq, r => (r -> repl[r]))
        ## multiple passes
        #for sub in subs
        #    seq = replace(seq, sub)
        #end
    end

    seq, kk
end
