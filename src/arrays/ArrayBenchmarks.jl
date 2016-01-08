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
        [(:sumelt, string(typeof(A)), size(A)) => sumelt(A) for A in arrays]
        [(:sumeach, string(typeof(A)), size(A)) => sumeach(A) for A in arrays]
        [(:sumlinear, string(typeof(A)), size(A)) => sumlinear(A) for A in arrays]
        [(:sumcartesian, string(typeof(A)), size(A)) => sumcartesian(A) for A in arrays]
        [(:sumcolon, string(typeof(A)), size(A)) => sumcolon(A) for A in arrays]
        [(:sumrange, string(typeof(A)), size(A)) => sumrange(A) for A in arrays]
        [(:sumlogical, string(typeof(A)), size(A)) => sumlogical(A) for A in arrays]
        [(:sumvector, string(typeof(A)), size(A)) => sumvector(A) for A in arrays]
    end
    @tags "arrays" "sums" "indexing" "simd"
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
        [(:lucompletepivCopy!, n) => lucompletepivCopy!(rand(n,n)) for n in sizes]
        [(:lucompletepivSub!, n) => lucompletepivSub!(rand(n,n)) for n in sizes]
    end
    @tags "lucompletepiv" "arrays" "linalg" "copy" "subarrays" "factorization"
end

end # module
