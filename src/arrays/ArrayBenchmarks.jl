module ArrayBenchmarks

import BaseBenchmarks
using BenchmarkTrackers

############
# indexing #
############

include("indexing.jl")

const SMALL_SIZE = (3,5)
const SMALL_SIZE_ITERS = 10^5

const LARGE_SIZE = (300,500)
const LARGE_SIZE_ITERS = 100

# using small Int arrays...
@track BaseBenchmarks.TRACKER begin
    @setup arrays = makearrays(Int, SMALL_SIZE)
    @benchmarks begin
        [(:sumelt, string(typeof(A)), SMALL_SIZE_ITERS) => sumelt(A, SMALL_SIZE_ITERS) for A in arrays]
        [(:sumeach, string(typeof(A)), SMALL_SIZE_ITERS) => sumeach(A, SMALL_SIZE_ITERS) for A in arrays]
        [(:sumlinear, string(typeof(A)), SMALL_SIZE_ITERS) => sumlinear(A, SMALL_SIZE_ITERS) for A in arrays]
        [(:sumcartesian, string(typeof(A)), SMALL_SIZE_ITERS) => sumcartesian(A, SMALL_SIZE_ITERS) for A in arrays]
        [(:sumcolon, string(typeof(A)), SMALL_SIZE_ITERS) => sumcolon(A, SMALL_SIZE_ITERS) for A in arrays]
        [(:sumrange, string(typeof(A)), SMALL_SIZE_ITERS) => sumrange(A, SMALL_SIZE_ITERS) for A in arrays]
        [(:sumlogical, string(typeof(A)), SMALL_SIZE_ITERS) => sumlogical(A, SMALL_SIZE_ITERS) for A in arrays]
        [(:sumvector, string(typeof(A)), SMALL_SIZE_ITERS) => sumvector(A, SMALL_SIZE_ITERS) for A in arrays]
    end
    @tags "arrays" "int" "sums" "indexing" "fast"
end

# using large Int arrays...
@track BaseBenchmarks.TRACKER begin
    @setup arrays = makearrays(Int, LARGE_SIZE)
    @benchmarks begin
        [(:sumelt, string(typeof(A)), LARGE_SIZE_ITERS) => sumelt(A, LARGE_SIZE_ITERS) for A in arrays]
        [(:sumeach, string(typeof(A)), LARGE_SIZE_ITERS) => sumeach(A, LARGE_SIZE_ITERS) for A in arrays]
        [(:sumlinear, string(typeof(A)), LARGE_SIZE_ITERS) => sumlinear(A, LARGE_SIZE_ITERS) for A in arrays]
        [(:sumcartesian, string(typeof(A)), LARGE_SIZE_ITERS) => sumcartesian(A, LARGE_SIZE_ITERS) for A in arrays]
        [(:sumcolon, string(typeof(A)), LARGE_SIZE_ITERS) => sumcolon(A, LARGE_SIZE_ITERS) for A in arrays]
        [(:sumrange, string(typeof(A)), LARGE_SIZE_ITERS) => sumrange(A, LARGE_SIZE_ITERS) for A in arrays]
        [(:sumlogical, string(typeof(A)), LARGE_SIZE_ITERS) => sumlogical(A, LARGE_SIZE_ITERS) for A in arrays]
        [(:sumvector, string(typeof(A)), LARGE_SIZE_ITERS) => sumvector(A, LARGE_SIZE_ITERS) for A in arrays]
    end
    @tags "arrays" "int" "sums" "indexing" "slow"
end

# using small Float32 arrays...
@track BaseBenchmarks.TRACKER begin
    @setup arrays = makearrays(Float32, SMALL_SIZE)
    @benchmarks begin
        [(:sumelt, string(typeof(A)), SMALL_SIZE_ITERS) => sumelt(A, SMALL_SIZE_ITERS) for A in arrays]
        [(:sumeach, string(typeof(A)), SMALL_SIZE_ITERS) => sumeach(A, SMALL_SIZE_ITERS) for A in arrays]
        [(:sumlinear, string(typeof(A)), SMALL_SIZE_ITERS) => sumlinear(A, SMALL_SIZE_ITERS) for A in arrays]
        [(:sumcartesian, string(typeof(A)), SMALL_SIZE_ITERS) => sumcartesian(A, SMALL_SIZE_ITERS) for A in arrays]
        [(:sumcolon, string(typeof(A)), SMALL_SIZE_ITERS) => sumcolon(A, SMALL_SIZE_ITERS) for A in arrays]
        [(:sumrange, string(typeof(A)), SMALL_SIZE_ITERS) => sumrange(A, SMALL_SIZE_ITERS) for A in arrays]
        [(:sumlogical, string(typeof(A)), SMALL_SIZE_ITERS) => sumlogical(A, SMALL_SIZE_ITERS) for A in arrays]
        [(:sumvector, string(typeof(A)), SMALL_SIZE_ITERS) => sumvector(A, SMALL_SIZE_ITERS) for A in arrays]
    end
    @tags "arrays" "float" "sums" "indexing" "fast"
end

# using large Float32 arrays...
@track BaseBenchmarks.TRACKER begin
    @setup arrays = makearrays(Float32, LARGE_SIZE)
    @benchmarks begin
        [(:sumelt, string(typeof(A)), LARGE_SIZE_ITERS) => sumelt(A, LARGE_SIZE_ITERS) for A in arrays]
        [(:sumeach, string(typeof(A)), LARGE_SIZE_ITERS) => sumeach(A, LARGE_SIZE_ITERS) for A in arrays]
        [(:sumlinear, string(typeof(A)), LARGE_SIZE_ITERS) => sumlinear(A, LARGE_SIZE_ITERS) for A in arrays]
        [(:sumcartesian, string(typeof(A)), LARGE_SIZE_ITERS) => sumcartesian(A, LARGE_SIZE_ITERS) for A in arrays]
        [(:sumcolon, string(typeof(A)), LARGE_SIZE_ITERS) => sumcolon(A, LARGE_SIZE_ITERS) for A in arrays]
        [(:sumrange, string(typeof(A)), LARGE_SIZE_ITERS) => sumrange(A, LARGE_SIZE_ITERS) for A in arrays]
        [(:sumlogical, string(typeof(A)), LARGE_SIZE_ITERS) => sumlogical(A, LARGE_SIZE_ITERS) for A in arrays]
        [(:sumvector, string(typeof(A)), LARGE_SIZE_ITERS) => sumvector(A, LARGE_SIZE_ITERS) for A in arrays]
    end
    @tags "arrays" "float" "sums" "indexing" "slow"
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
    @tags "lucompletepiv" "arrays" "float" "linalg" "copy" "subarrays" "factorization"
end

end # module
