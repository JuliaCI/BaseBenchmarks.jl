module SortBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using Random
using BenchmarkTools

const SUITE = BenchmarkGroup()

################################################
# Default algorithms at various sizes  (≈162s) #
################################################

for LENGTH in [3, 10, 100, 1000, 10000]
    g = addgroup!(SUITE, "length = $LENGTH")

    g["sort!(fill(missing, length), rev=true)"] = @benchmarkable sort!(x, rev=true) setup=(x=fill(missing, $LENGTH))
    g["sort!(fill(missing, length))"] = @benchmarkable sort!(x) setup=(x=fill(missing, $LENGTH))
    g["sort!(rand(Int, length))"] = @benchmarkable sort!(rand!(x)) setup=(x=rand(Int, $LENGTH)) # 47474
    g["sort(randn(length))"] = @benchmarkable sort(x) setup=(x=randn($LENGTH))

    g["sortperm(rand(length))"] = @benchmarkable sortperm(x) setup=(x=rand($LENGTH))

    g["mixed eltype with by order"] = @benchmarkable sort(x; by=x -> x isa Symbol ? (0, x) : (1, x)) setup=(x=[rand() < .5 ? randstring() : Symbol(randstring()) for _ in 1:$LENGTH])

    # 27781
    g["Float64 unions with missing"] = @benchmarkable sort(x) setup=(x=shuffle!(vcat(fill(missing, $(LENGTH÷10)), rand($(LENGTH*9÷10)))))
    g["Int unions with missing"] = @benchmarkable sort(x) setup=(x=shuffle!(vcat(fill(missing, $(LENGTH÷10)), rand(Int, $(LENGTH*9÷10)))))

    n = ceil(Int, cbrt(LENGTH/4))
    for i in 1:3 # 47538, 45326
        g["sort(rand(2n, 2n, n); dims=$i)"] = @benchmarkable sort(rand(2*$n,2*$n,$n); dims=$i)
        g["sort!(rand(2n, 2n, n); dims=$i)"] = @benchmarkable sort!(rand(2*$n,2*$n,$n); dims=$i)
    end

    g["ascending"] = @benchmarkable sort!(x) setup=(x=sort(rand($LENGTH)))
    g["descending"] = @benchmarkable sort(x) setup=(x=sort(rand($LENGTH)))
    g["all same"] = @benchmarkable sort!(x) setup=(x=fill(rand(), $LENGTH))

    for b in values(g)
        b.params.time_tolerance = 0.20
    end
end

##################
# Issues  (≈56s) #
##################

let g = addgroup!(SUITE, "issues")

    # 939
    g["sortperm(collect(1000000:-1:1))"] = @benchmarkable sortperm(x) setup=(x=collect(1000000:-1:1))
    g["sortperm(rand(10^5))"] = @benchmarkable sortperm(x) setup=(x=rand(10^5))
    g["sortperm(rand(10^7))"] = @benchmarkable sortperm(x) setup=(x=rand(10^7))

    # 9832
    a_9832 = rand(Int, 30_000_000, 2)
    g["sortslices sorting very short slices"] = @benchmarkable sortslices($a_9832, dims=2)

    # 36546
    xv_36546 = view(rand(1000), 1:1000)
    g["sortperm on a view (Float64)"] = @benchmarkable sortperm($xv_36546)
    xs_36546 = rand(1:10^3, 10^4, 2)
    g["sortperm on a view (Int)"] = @benchmarkable sortperm(view($xs_36546,:,1))

    # 39864
    v2_39864 = samerand(2000)
    g["inplace sorting of a view"] = @benchmarkable sort!(vv) setup = (vv1 = deepcopy($v2_39864); vv = @view vv1[500:1499]) evals = 1

    # 46149
    g["Float16"] = @benchmarkable sort!(x) setup=(x=rand(Float16, 10^6)) evals=1

    # 47152
    g["small Int view"] = @benchmarkable sort!(view(x,2:4)) setup=(x = [2,1,10,15,20])
    g["small Float64 view"] = @benchmarkable sort!(view(x,2:4)) setup=(x = [2.0,1.0,10.0,15.0,20.0])

    # 47191
    g["partialsort(rand(10_000), 10_000)"] = @benchmarkable partialsort(x, 10_000) setup=(x=rand(10_000))

    # 47715
    g["sort(rand(10^8))"] = @benchmarkable sort(x) setup=(x=rand(10^8))

    # 47766
    g["partialsort!(rand(10_000), 1:3, rev=true)"] = @benchmarkable partialsort!(x, 1:3; rev=true) setup=(x=rand(10_000)) evals=1
    for b in values(g)
        b.params.time_tolerance = 0.20
    end
end

#############################################
# QuickSort/MergeSort/InsertionSort  (≈47s) #
#############################################

for (group, Alg, len) in (("quicksort", QuickSort, 50_000), ("mergesort", MergeSort, 50_000), ("insertionsort", InsertionSort, 100))
    list = samerand(len)
    g = addgroup!(SUITE, group)

    ix = collect(1:length(list))
    g["sort forwards"] = @benchmarkable sort($list; alg = $Alg)
    g["sortperm forwards"] = @benchmarkable sortperm($list; alg = $Alg)
    g["sort! reverse"] = @benchmarkable sort!(x; alg = $Alg, rev = true) setup=(x = copy($list)) evals=1
    g["sortperm! reverse"] = @benchmarkable sortperm!(x, $list; alg = $Alg, rev = true) setup=(x = copy($ix))

    for b in values(g)
        b.params.time_tolerance = 0.20
    end
end

####################
# issorted  (≈10s) #
####################

g = addgroup!(SUITE, "issorted")

const LIST_SIZE = 50_000
const LISTS = (
    ("ascending", collect(1:LIST_SIZE)),
    ("descending", collect(LIST_SIZE:-1:1)),
    ("ones", ones(LIST_SIZE)),
    ("random", samerand(LIST_SIZE))
)

for (kind, list) in LISTS
    g["forwards", kind] = @benchmarkable issorted($list)
    g["reverse", kind] = @benchmarkable issorted($list; rev = true)
end

for b in values(g)
    b.params.time_tolerance = 0.20
end

end # module
