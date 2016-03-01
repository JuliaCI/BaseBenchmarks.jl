module SortBenchmarks

using ..BaseBenchmarks: GROUPS
using ..RandUtils
using BenchmarkTools

const LIST_SIZE = 50000
const LISTS = (
    ("ascending", collect(1:LIST_SIZE)),
    ("descending", collect(LIST_SIZE:-1:1)),
    ("ones", ones(LIST_SIZE)),
    ("random", samerand(LIST_SIZE))
)

#####################################
# QuickSort/MergeSort/InsertionSort #
#####################################

for (tag, T) in (("quicksort", QuickSort), ("mergesort", MergeSort), ("insertionsort", InsertionSort))
    sortgroup = addgroup!(GROUPS, "sort $tag", ["sort", "sort!", tag])
    sortpermgroup = addgroup!(GROUPS, "sort sortperm $tag", ["sort", "sort!", "sortperm", "sortperm!", tag])
    for (kind, list) in LISTS
        ix = collect(1:length(list))
        sortgroup["sort", tag, kind] = @benchmarkable sort($list; alg = $T)
        sortgroup["sort reverse", tag, kind] = @benchmarkable sort($list; alg = $T, rev = true)
        sortgroup["sort!", tag, kind] = @benchmarkable sort!(copy($list); alg = $T)
        sortgroup["sort! reverse", tag, kind] = @benchmarkable sort!(copy($list); alg = $T, rev = true)
        sortpermgroup["sortperm", tag, kind] = @benchmarkable sortperm($list; alg = $T)
        sortpermgroup["sortperm reverse", tag, kind] = @benchmarkable sortperm($list; alg = $T, rev = true)
        sortpermgroup["sortperm!", tag, kind] = @benchmarkable sortperm!(copy($ix), $list; alg = $T)
        sortpermgroup["sortperm! reverse", tag, kind] = @benchmarkable sortperm!(copy($ix), $list; alg = $T, rev = true)
    end
end

############
# issorted #
############

g = addgroup!(GROUPS, "sort issorted", ["sort", "issorted"])

for (kind, list) in LISTS
    g["issorted", kind] = @benchmarkable issorted($list)
    g["issorted reverse", kind] = @benchmarkable issorted($list; rev = true)
end

end # module
