module ArrayBenchmarks

import ..BaseBenchmarks
using ..BenchmarkTrackers
using ..BaseBenchmarks.samerand

############
# indexing #
############

# #10525 #
#--------#

include("sumindex.jl")

@track BaseBenchmarks.TRACKER "array index sum" begin
    @setup begin
        int_arrs = (makearrays(Int32, 3, 5)..., makearrays(Int32, 300, 500)...)
        float_arrs = (makearrays(Float32, 3, 5)..., makearrays(Float32, 300, 500)...)
        arrays = (int_arrs..., float_arrs...)
    end
    @benchmarks begin
        [(:sumelt, string(typeof(A)), size(A)) => perf_sumelt(A) for A in arrays]
        [(:sumeach, string(typeof(A)), size(A)) => perf_sumeach(A) for A in arrays]
        [(:sumlinear, string(typeof(A)), size(A)) => perf_sumlinear(A) for A in arrays]
        [(:sumcartesian, string(typeof(A)), size(A)) => perf_sumcartesian(A) for A in arrays]
        [(:sumcolon, string(typeof(A)), size(A)) => perf_sumcolon(A) for A in arrays]
        [(:sumrange, string(typeof(A)), size(A)) => perf_sumrange(A) for A in arrays]
        [(:sumlogical, string(typeof(A)), size(A)) => perf_sumlogical(A) for A in arrays]
        [(:sumvector, string(typeof(A)), size(A)) => perf_sumvector(A) for A in arrays]
    end
    @tags "array" "sum" "indexing" "simd"
end

# #10301 #
#--------#

include("revloadindex.jl")

@track BaseBenchmarks.TRACKER "array index load reverse" begin
    @setup n = 10^6
    @benchmarks begin
        (:rev_load_slow!,) => perf_rev_load_slow!(samerand(n))
        (:rev_load_fast!,) => perf_rev_load_fast!(samerand(n))
        (:rev_loadmul_slow!,) => perf_rev_loadmul_slow!(samerand(n), samerand(n))
        (:rev_loadmul_fast!,) => perf_rev_loadmul_fast!(samerand(n), samerand(n))
    end
    @tags "array" "indexing" "load" "reverse"
end

# #9622 #
#-------#

perf_setindex!(A, val, inds) = setindex!(A, val, inds...)

@track BaseBenchmarks.TRACKER "array index setindex!" begin
    @setup arrays = map(n -> Array(Float64, ntuple(one, n)), (1,2,3,4,5))
    @benchmarks begin
        [(:setindex!, ndims(A)) => perf_setindex!(A, one(eltype(A)), size(A)) for A in arrays]
    end
    @constraints gc=>false
    @tags "array" "indexing" "setindex!"
end

###############################
# SubArray (views vs. copies) #
###############################

include("subarray.jl")

# LU factorization with complete pivoting. These functions deliberately allocate
# a lot of temprorary arrays by working on vectors instead of looping through
# the elements of the matrix. Both a view (SubArray) version and a copy version
# are provided.
@track BaseBenchmarks.TRACKER "array subarray" begin
    @setup sizes = (100, 250, 500, 1000)
    @benchmarks begin
        [(:lucompletepivCopy!, n) => perf_lucompletepivCopy!(samerand(n, n)) for n in sizes]
        [(:lucompletepivSub!, n) => perf_lucompletepivSub!(samerand(n, n)) for n in sizes]
    end
    @tags "lucompletepiv" "array" "linalg" "copy" "subarray" "factorization"
end

#################
# concatenation #
#################

include("cat.jl")

@track BaseBenchmarks.TRACKER "array cat" begin
    @setup begin
        sizes = (5, 500)
        arrays = map(n -> samerand(n, n), sizes)
    end
    @benchmarks begin
        [(:hvcat, size(A, 1)) => perf_hvcat(A, A) for A in arrays]
        [(:hvcat_setind, size(A, 1)) => perf_hvcat_setind(A, A) for A in arrays]
        [(:hcat, size(A, 1)) => perf_hcat(A, A) for A in arrays]
        [(:hcat_setind, size(A, 1)) => perf_hcat_setind(A, A) for A in arrays]
        [(:vcat, size(A, 1)) => perf_vcat(A, A) for A in arrays]
        [(:vcat_setind, size(A, 1)) => perf_vcat_setind(A, A) for A in arrays]
        [(:catnd, n) => perf_catnd(n) for n in sizes]
        [(:catnd_setind, n) => perf_catnd_setind(n) for n in sizes]
    end
    @tags "array" "indexing" "cat" "hcat" "vcat" "hvcat" "setindex"
end

############################
# in-place growth (#13977) #
############################

function push_multiple!(collection, items)
    for item in items
        push!(collection, item)
    end
    return collection
end

@track BaseBenchmarks.TRACKER "array growth" begin
    @setup begin
        sizes = (8, 256, 2048)
        vectors = map(samerand, sizes)
    end
    @benchmarks begin
        [(:push_single!, length(v)) => push!(copy(v), samerand()) for v in vectors]
        [(:push_multiple!, length(v)) => push_multiple!(copy(v), v) for v in vectors]
        [(:append!, length(v)) => append!(copy(v), v) for v in vectors]
        [(:prerend!, length(v)) => prepend!(copy(v), v) for v in vectors]
    end
    @tags "array" "growth" "push!" "append!" "prepend!"
end

##########################
# comprehension (#13401) #
##########################

perf_compr_collect(X) = [x for x in X]
perf_compr_iter(X) = [sin(x) + x^2 - 3 for x in X]
perf_compr_index(X) = [sin(X[i]) + (X[i])^2 - 3 for i in eachindex(X)]

@track BaseBenchmarks.TRACKER "array comprehension" begin
    @setup begin
        order = 7
        ls = linspace(0,1,10^order)
        rg = 0.0:(10.0^(-order)):1.0
        arr = collect(ls)
        iters = (ls, arr, rg)
    end
    @benchmarks begin
        [(:collect, string(typeof(i))) => collect(i) for i in iters]
        [(:comprehension_collect, string(typeof(i))) => perf_compr_collect(i) for i in iters]
        [(:comprehension_iteration, string(typeof(i))) => perf_compr_iter(i) for i in iters]
        [(:comprehension_indexing, string(typeof(i))) => perf_compr_index(i) for i in iters]
    end
    @tags "array" "comprehension" "iteration" "indexing" "linspace" "collect" "range"
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

@track BaseBenchmarks.TRACKER "array bool" begin
    @setup begin
        n, range = 10^6, -3:3
        a, b = samerand(range, n), samerand(range)
        boolarr, bitarr = Vector{Bool}(n), BitArray(n)
    end
    @benchmarks begin
        (:bitarray_bool_load!,) => perf_bool_load!(bitarr, a, b)
        (:boolarray_bool_load!,) => perf_bool_load!(boolarr, a, b)
        (:bitarray_true_load!,) => perf_true_load!(bitarr)
        (:boolarray_true_load!,) => perf_true_load!(boolarr)
        (:bitarray_true_fill!,) => fill!(bitarr, true)
        (:boolarray_true_fill!,) => fill!(boolarr, true)
    end
    @tags "array" "indexing" "load" "bool" "bitarray" "fill!"
end

end # module
