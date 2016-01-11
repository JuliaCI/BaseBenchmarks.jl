module ArrayBenchmarks

import BaseBenchmarks
using BenchmarkTrackers

############
# indexing #
############

include("indexing.jl")

@track BaseBenchmarks.TRACKER begin
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

####################
# views vs. copies #
####################

include("lucompletepiv.jl")

# LU factorization with complete pivoting. These functions deliberately allocate
# a lot of temprorary arrays by working on vectors instead of looping through
# the elements of the matrix. Both a view (SubArray) version and a copy version
# are provided.
@track BaseBenchmarks.TRACKER begin
    @setup sizes = (100, 250, 500, 1000)
    @benchmarks begin
        [(:lucompletepivCopy!, n) => perf_lucompletepivCopy!(rand(n,n)) for n in sizes]
        [(:lucompletepivSub!, n) => perf_lucompletepivSub!(rand(n,n)) for n in sizes]
    end
    @tags "lucompletepiv" "array" "linalg" "copy" "subarray" "factorization"
end

#################
# concatenation #
#################

include("cat.jl")

@track BaseBenchmarks.TRACKER begin
    @setup begin
        sizes = (5, 500)
        arrays = map(n -> rand(n, n), sizes)
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

end # module
