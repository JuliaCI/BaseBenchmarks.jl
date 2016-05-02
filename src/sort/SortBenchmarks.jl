module SortBenchmarks

include(joinpath(Pkg.dir("BaseBenchmarks"), "src", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

const SUITE = BenchmarkGroup()
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

for (group, Alg) in (("quicksort", QuickSort), ("mergesort", MergeSort), ("insertionsort", InsertionSort))
    g = addgroup!(SUITE, group)
    for (kind, list) in LISTS
        ix = collect(1:length(list))
        g["sort forwards", kind] = @benchmarkable sort($list; alg = $Alg)
        g["sort reverse", kind] = @benchmarkable sort($list; alg = $Alg, rev = true)
        g["sortperm forwards", kind] = @benchmarkable sortperm($list; alg = $Alg)
        g["sortperm reverse", kind] = @benchmarkable sortperm($list; alg = $Alg, rev = true)
        g["sort! forwards", kind] = @benchmarkable sort!(x; alg = $Alg) setup=(x = copy($list))
        g["sort! reverse", kind] = @benchmarkable sort!(x; alg = $Alg, rev = true) setup=(x = copy($list))
        g["sortperm! forwards", kind] = @benchmarkable sortperm!(x, $list; alg = $Alg) setup=(x = copy($ix))
        g["sortperm! reverse", kind] = @benchmarkable sortperm!(x, $list; alg = $Alg, rev = true) setup=(x = copy($ix))
    end
end

############
# issorted #
############

g = addgroup!(SUITE, "issorted")

for (kind, list) in LISTS
    g["forwards", kind] = @benchmarkable issorted($list)
    g["reverse", kind] = @benchmarkable issorted($list; rev = true) time_tolerance=0.30
end

end # module
