module ArrayBenchmarks

using ..BaseBenchmarks: SUITE
using ..RandUtils
using BenchmarkTools

############
# indexing #
############

# #10525 #
#--------#

include("sumindex.jl")

s = 500
arrays = (makearrays(Int32, s, s)..., makearrays(Float32, s, s)..., trues(s, s))

g = newgroup!(SUITE, "array index sum", ["array", "sum", "index", "simd"])

tol = 0.2
for A in arrays
    T = string(typeof(A))
    g["sumelt", T] = @benchmarkable perf_sumelt($A) time_tolerance = tol
    g["sumeach", T] = @benchmarkable perf_sumeach($A) time_tolerance = tol
    g["sumlinear", T] = @benchmarkable perf_sumlinear($A) time_tolerance = tol
    g["sumcartesian", T] = @benchmarkable perf_sumcartesian($A) time_tolerance = tol
    g["sumcolon", T] = @benchmarkable perf_sumcolon($A) time_tolerance = tol
    g["sumrange", T] = @benchmarkable perf_sumrange($A) time_tolerance = tol
    g["sumlogical", T] = @benchmarkable perf_sumlogical($A) time_tolerance = tol
    g["sumvector", T] = @benchmarkable perf_sumvector($A) time_tolerance = tol
end

# #10301 #
#--------#

include("revloadindex.jl")

v = samerand(10^6)
n = samerand()

g = newgroup!(SUITE, "array index load reverse", ["array", "indexing", "load", "reverse"])

g["rev_load_slow!"] = @benchmarkable perf_rev_load_slow!(fill!($v, $n))
g["rev_load_fast!"] = @benchmarkable perf_rev_load_fast!(fill!($v, $n))
g["rev_loadmul_slow!"] = @benchmarkable perf_rev_loadmul_slow!(fill!($v, $n), $v)
g["rev_loadmul_fast!"] = @benchmarkable perf_rev_loadmul_fast!(fill!($v, $n), $v)

# #9622 #
#-------#

perf_setindex!(A, val, inds) = setindex!(A, val, inds...)

g = newgroup!(SUITE, "array index setindex!", ["array", "indexing", "setindex!"])

for s in (1, 2, 3, 4, 5)
    A = samerand(Float64, ntuple(one, s)...)
    y = one(eltype(A))
    i = length(A)
    g["setindex!", ndims(A)] = @benchmarkable perf_setindex!(fill!($A, $y), $y, $i)
end

###############################
# SubArray (views vs. copies) #
###############################

# LU factorization with complete pivoting. These functions deliberately allocate
# a lot of temprorary arrays by working on vectors instead of looping through
# the elements of the matrix. Both a view (SubArray) version and a copy version
# are provided.

include("subarray.jl")

n = samerand()

g = newgroup!(SUITE, "array subarray", ["array", "subarray", "lucompletepiv"])

for s in (100, 250, 500, 1000)
    m = samerand(s, s)
    g["lucompletepivCopy!", s] = @benchmarkable perf_lucompletepivCopy!(fill!($m, $n))
    g["lucompletepivSub!", s] = @benchmarkable perf_lucompletepivCopy!(fill!($m, $n))
end

#################
# concatenation #
#################

include("cat.jl")

g = newgroup!(SUITE, "array cat", ["array", "indexing", "cat", "hcat", "vcat", "hvcat", "setindex"])

for s in (5, 500)
    A = samerand(s, s)
    g["hvcat", s] = @benchmarkable perf_hvcat($A, $A)
    g["hcat", s] = @benchmarkable perf_hcat($A, $A)
    g["vcat", s] = @benchmarkable perf_vcat($A, $A)
    g["catnd", s] = @benchmarkable perf_catnd($s)
    g["hvcat_setind", s] = @benchmarkable perf_hvcat_setind($A, $A)
    g["hcat_setind", s] = @benchmarkable perf_hcat_setind($A, $A)
    g["vcat_setind", s] = @benchmarkable perf_vcat_setind($A, $A)
    g["catnd_setind", s] = @benchmarkable perf_catnd_setind($s)
end

############################
# in-place growth (#13977) #
############################

function perf_push_multiple!(collection, items)
    for item in items
        push!(collection, item)
    end
    return collection
end

g = newgroup!(SUITE, "array growth", ["array", "growth", "push!", "append!", "prepend!"])

for s in (8, 256, 2048)
    v = samerand(s)
    g["push_single!", s] = @benchmarkable push!(x, samerand()) setup=(x = copy($v))
    g["push_multiple!", s] = @benchmarkable perf_push_multiple!(x, $v) setup=(x = copy($v))
    g["append!", s] = @benchmarkable append!(x, $v) setup=(x = copy($v))
    g["prerend!", s] = @benchmarkable prepend!(x, $v) setup=(x = copy($v))
end

##########################
# comprehension (#13401) #
##########################

perf_compr_collect(X) = [x for x in X]
perf_compr_iter(X) = [sin(x) + x^2 - 3 for x in X]
perf_compr_index(X) = [sin(X[i]) + (X[i])^2 - 3 for i in eachindex(X)]

ls = linspace(0,1,10^7)
rg = 0.0:(10.0^(-7)):1.0
arr = collect(ls)

g = newgroup!(SUITE, "array comprehension", ["array", "comprehension", "iteration", "indexing", "linspace", "collect", "range"])

for X in (ls, rg, arr)
    T = string(typeof(X))
    g["collect", T] = @benchmarkable collect($X)
    g["comprehension_collect", T] = @benchmarkable perf_compr_collect($X)
    g["comprehension_iteration", T] = @benchmarkable perf_compr_iter($X)
    g["comprehension_indexing", T] = @benchmarkable perf_compr_index($X)
end

###############################
# BoolArray/BitArray (#13946) #
###############################

function perf_bool_load!(result, a, b)
    for i in eachindex(result)
        result[i] = a[i] != b
    end
    return result
end

function perf_true_load!(result)
    for i in eachindex(result)
        result[i] = true
    end
    return result
end

n, range = 10^6, -3:3
a, b = samerand(range, n), samerand(range)
boolarr, bitarr = Vector{Bool}(n), BitArray(n)

g = newgroup!(SUITE, "array bool", ["array", "indexing", "load", "bool", "bitarray", "fill!"])

g["bitarray_bool_load!"] = @benchmarkable perf_bool_load!($bitarr, $a, $b)
g["boolarray_bool_load!"] = @benchmarkable perf_bool_load!($boolarr, $a, $b)
g["bitarray_true_load!"] = @benchmarkable perf_true_load!($bitarr)
g["boolarray_true_load!"] = @benchmarkable perf_true_load!($boolarr)
g["bitarray_true_fill!"] = @benchmarkable fill!($bitarr, true)
g["boolarray_true_fill!"] = @benchmarkable fill!($boolarr, true)

end # module
