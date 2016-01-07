module ArrayBenchmarks

import BaseBenchmarks
using BenchmarkTrackers

############
# indexing #
############

include("indexing.jl")

const SMALL_SIZE = (3,5)
const LARGE_SIZE = (300,500)
const SMALL_N = 10^5
const LARGE_N = 100

# using small Int arrays...
@track BaseBenchmarks.TRACKER begin
    @setup arrays = makearrays(Int, SMALL_SIZE)
    @benchmarks begin
        [(:sumelt, string(typeof(A)), SMALL_N) => sumelt(A, SMALL_N) for A in arrays]
        [(:sumeach, string(typeof(A)), SMALL_N) => sumeach(A, SMALL_N) for A in arrays]
        [(:sumlinear, string(typeof(A)), SMALL_N) => sumlinear(A, SMALL_N) for A in arrays]
        [(:sumcartesian, string(typeof(A)), SMALL_N) => sumcartesian(A, SMALL_N) for A in arrays]
        [(:sumcolon, string(typeof(A)), SMALL_N) => sumcolon(A, SMALL_N) for A in arrays]
        [(:sumrange, string(typeof(A)), SMALL_N) => sumrange(A, SMALL_N) for A in arrays]
        [(:sumlogical, string(typeof(A)), SMALL_N) => sumlogical(A, SMALL_N) for A in arrays]
        [(:sumvector, string(typeof(A)), SMALL_N) => sumvector(A, SMALL_N) for A in arrays]
    end
    @tags "arrays" "int" "sums" "indexing" "fast"
end

# using large Int arrays...
@track BaseBenchmarks.TRACKER begin
    @setup arrays = makearrays(Int, LARGE_SIZE)
    @benchmarks begin
        [(:sumelt, string(typeof(A)), LARGE_N) => sumelt(A, LARGE_N) for A in arrays]
        [(:sumeach, string(typeof(A)), LARGE_N) => sumeach(A, LARGE_N) for A in arrays]
        [(:sumlinear, string(typeof(A)), LARGE_N) => sumlinear(A, LARGE_N) for A in arrays]
        [(:sumcartesian, string(typeof(A)), LARGE_N) => sumcartesian(A, LARGE_N) for A in arrays]
        [(:sumcolon, string(typeof(A)), LARGE_N) => sumcolon(A, LARGE_N) for A in arrays]
        [(:sumrange, string(typeof(A)), LARGE_N) => sumrange(A, LARGE_N) for A in arrays]
        [(:sumlogical, string(typeof(A)), LARGE_N) => sumlogical(A, LARGE_N) for A in arrays]
        [(:sumvector, string(typeof(A)), LARGE_N) => sumvector(A, LARGE_N) for A in arrays]
    end
    @tags "arrays" "int" "sums" "indexing" "slow"
end

# using small Float32 arrays...
@track BaseBenchmarks.TRACKER begin
    @setup arrays = makearrays(Float32, SMALL_SIZE)
    @benchmarks begin
        [(:sumelt, string(typeof(A)), SMALL_N) => sumelt(A, SMALL_N) for A in arrays]
        [(:sumeach, string(typeof(A)), SMALL_N) => sumeach(A, SMALL_N) for A in arrays]
        [(:sumlinear, string(typeof(A)), SMALL_N) => sumlinear(A, SMALL_N) for A in arrays]
        [(:sumcartesian, string(typeof(A)), SMALL_N) => sumcartesian(A, SMALL_N) for A in arrays]
        [(:sumcolon, string(typeof(A)), SMALL_N) => sumcolon(A, SMALL_N) for A in arrays]
        [(:sumrange, string(typeof(A)), SMALL_N) => sumrange(A, SMALL_N) for A in arrays]
        [(:sumlogical, string(typeof(A)), SMALL_N) => sumlogical(A, SMALL_N) for A in arrays]
        [(:sumvector, string(typeof(A)), SMALL_N) => sumvector(A, SMALL_N) for A in arrays]
    end
    @tags "arrays" "float" "sums" "indexing" "fast"
end

# using large Float32 arrays...
@track BaseBenchmarks.TRACKER begin
    @setup arrays = makearrays(Float32, LARGE_SIZE)
    @benchmarks begin
        [(:sumelt, string(typeof(A)), LARGE_N) => sumelt(A, LARGE_N) for A in arrays]
        [(:sumeach, string(typeof(A)), LARGE_N) => sumeach(A, LARGE_N) for A in arrays]
        [(:sumlinear, string(typeof(A)), LARGE_N) => sumlinear(A, LARGE_N) for A in arrays]
        [(:sumcartesian, string(typeof(A)), LARGE_N) => sumcartesian(A, LARGE_N) for A in arrays]
        [(:sumcolon, string(typeof(A)), LARGE_N) => sumcolon(A, LARGE_N) for A in arrays]
        [(:sumrange, string(typeof(A)), LARGE_N) => sumrange(A, LARGE_N) for A in arrays]
        [(:sumlogical, string(typeof(A)), LARGE_N) => sumlogical(A, LARGE_N) for A in arrays]
        [(:sumvector, string(typeof(A)), LARGE_N) => sumvector(A, LARGE_N) for A in arrays]
    end
    @tags "arrays" "float" "sums" "indexing" "slow"
end

####################
# Views vs. Copies #
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
    @tags "lucompletepiv" "arrays" "float" "linalg" "alloc" "copies" "subarrays" "views"
end

end # module
