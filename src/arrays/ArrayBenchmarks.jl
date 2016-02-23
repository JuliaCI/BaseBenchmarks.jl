module ArrayBenchmarks

using ..BaseBenchmarks
using ..BenchmarkTools
using ..RandUtils

############
# indexing #
############

# #10525 #
#--------#

include("sumindex.jl")

arrays = (makearrays(Int32, 3, 5)...,
          makearrays(Int32, 300, 500)...,
          makearrays(Float32, 3, 5)...,
          makearrays(Float32, 300, 500)...)

g = addgroup!(ENSEMBLE, "array index sum", ["array", "sum", "index", "simd"])

for A in arrays
    T = string(typeof(A))
    s = size(A)
    g["sumelt", T, s] = @benchmarkable perf_sumelt(copy($A))
    g["sumeach", T, s] = @benchmarkable perf_sumeach(copy($A))
    g["sumelt", T, s] = @benchmarkable perf_sumelt(copy($A))
    g["sumeach", T, s] = @benchmarkable perf_sumeach(copy($A))
    g["sumlinear", T, s] = @benchmarkable perf_sumlinear(copy($A))
    g["sumcartesian", T, s] = @benchmarkable perf_sumcartesian(copy($A))
    g["sumcolon", T, s] = @benchmarkable perf_sumcolon(copy($A))
    g["sumrange", T, s] = @benchmarkable perf_sumrange(copy($A))
    g["sumlogical", T, s] = @benchmarkable perf_sumlogical(copy($A))
    g["sumvector", T, s] = @benchmarkable perf_sumvector(copy($A))
end

# #10301 #
#--------#

include("revloadindex.jl")

n = 10^6

g = addgroup!(ENSEMBLE, "array index load reverse", ["array", "indexing", "load", "reverse"])

g["rev_load_slow!"] = @benchmarkable perf_rev_load_slow!(samerand($n))
g["rev_load_fast!"] = @benchmarkable perf_rev_load_fast!(samerand($n))
g["rev_loadmul_slow!"] = @benchmarkable perf_rev_loadmul_slow!(samerand($n), samerand($n))
g["rev_loadmul_fast!"] = @benchmarkable perf_rev_loadmul_fast!(samerand($n), samerand($n))

# #9622 #
#-------#

perf_setindex!(A, val, inds) = setindex!(A, val, inds...)

g = addgroup!(ENSEMBLE, "array index setindex!", ["array", "indexing", "setindex!"])

for s in (1, 2, 3, 4, 5)
    A = Array(Float64, ntuple(one, s))
    y = one(eltype(A))
    i = length(A)
    g["setindex!", ndims(A)] = @benchmarkable perf_setindex!(copy($A), $y, $i)
end

###############################
# SubArray (views vs. copies) #
###############################

# LU factorization with complete pivoting. These functions deliberately allocate
# a lot of temprorary arrays by working on vectors instead of looping through
# the elements of the matrix. Both a view (SubArray) version and a copy version
# are provided.

include("subarray.jl")

g = addgroup!(ENSEMBLE, "array subarray", ["array", "subarray", "lucompletepiv"])

for s in (100, 250, 500, 1000)
    g["lucompletepivCopy!", s] = @benchmarkable perf_lucompletepivCopy!(samerand($s, $s))
    g["lucompletepivSub!", s] = @benchmarkable perf_lucompletepivCopy!(samerand($s, $s))
end

#################
# concatenation #
#################

include("cat.jl")

g = addgroup!(ENSEMBLE, "array cat", ["array", "indexing", "cat", "hcat", "vcat", "hvcat", "setindex"])

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

g = addgroup!(ENSEMBLE, "array growth", ["array", "growth", "push!", "append!", "prepend!"])

for s in (8, 256, 2048)
    v = samerand(s)
    g["push_single!", s] = @benchmarkable push!(copy($v), samerand())
    g["push_multiple!", s] = @benchmarkable perf_push_multiple!(copy($v), $v)
    g["append!", s] = @benchmarkable append!(copy($v), $v)
    g["prerend!", s] = @benchmarkable prepend!(copy($v), $v)
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

g = addgroup!(ENSEMBLE, "array comprehension", ["array", "comprehension", "iteration",
                                                "indexing", "linspace", "collect", "range"])

for i in (ls, rg, arr)
    T = string(typeof(i))
    g["collect", T] = @benchmarkable collect($i)
    g["comprehension_collect", T] = @benchmarkable perf_compr_collect($i)
    g["comprehension_iteration", T] = @benchmarkable perf_compr_iter($i)
    g["comprehension_indexing", T] = @benchmarkable perf_compr_index($i)
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

g = addgroup!(ENSEMBLE, "array bool", ["array", "indexing", "load", "bool", "bitarray", "fill!"])

g["bitarray_bool_load!"] = @benchmarkable perf_bool_load!($bitarr, $a, $b)
g["boolarray_bool_load!"] = @benchmarkable perf_bool_load!($boolarr, $a, $b)
g["bitarray_true_load!"] = @benchmarkable perf_true_load!($bitarr)
g["boolarray_true_load!"] = @benchmarkable perf_true_load!($boolarr)
g["bitarray_true_fill!"] = @benchmarkable fill!($bitarr, true)
g["boolarray_true_fill!"] = @benchmarkable fill!($boolarr, true)

end # module
