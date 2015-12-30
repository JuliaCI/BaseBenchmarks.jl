module ArrayBenchmarks

using BaseBenchmarks, BenchmarkTrackers

include("definitions.jl")

const SMALL_SIZE = (3,5)
const LARGE_SIZE = (300,500)
const SMALL_N = 10^5
const LARGE_N = 100

# using small Int arrays...
@track BaseBenchmarks.TRACKER begin
    @setup arrays = makearrays(Int, SMALL_SIZE)
    @benchmarks begin
        [(:sumelt, typeof(A), SMALL_N) => sumelt(A, SMALL_N) for A in arrays]
        [(:sumeach, typeof(A), SMALL_N) => sumeach(A, SMALL_N) for A in arrays]
        [(:sumlinear, typeof(A), SMALL_N) => sumlinear(A, SMALL_N) for A in arrays]
        [(:sumcartesian, typeof(A), SMALL_N) => sumcartesian(A, SMALL_N) for A in arrays]
        [(:sumcolon, typeof(A), SMALL_N) => sumcolon(A, SMALL_N) for A in arrays]
        [(:sumrange, typeof(A), SMALL_N) => sumrange(A, SMALL_N) for A in arrays]
        [(:sumlogical, typeof(A), SMALL_N) => sumlogical(A, SMALL_N) for A in arrays]
        [(:sumvector, typeof(A), SMALL_N) => sumvector(A, SMALL_N) for A in arrays]
    end
    @tags "small" "arrays" "Int" "sums" "indexing"
end

# using large Int arrays...
@track BaseBenchmarks.TRACKER begin
    @setup arrays = makearrays(Int, LARGE_SIZE)
    @benchmarks begin
        [(:sumelt, typeof(A), LARGE_N) => sumelt(A, LARGE_N) for A in arrays]
        [(:sumeach, typeof(A), LARGE_N) => sumeach(A, LARGE_N) for A in arrays]
        [(:sumlinear, typeof(A), LARGE_N) => sumlinear(A, LARGE_N) for A in arrays]
        [(:sumcartesian, typeof(A), LARGE_N) => sumcartesian(A, LARGE_N) for A in arrays]
        [(:sumcolon, typeof(A), LARGE_N) => sumcolon(A, LARGE_N) for A in arrays]
        [(:sumrange, typeof(A), LARGE_N) => sumrange(A, LARGE_N) for A in arrays]
        [(:sumlogical, typeof(A), LARGE_N) => sumlogical(A, LARGE_N) for A in arrays]
        [(:sumvector, typeof(A), LARGE_N) => sumvector(A, LARGE_N) for A in arrays]
    end
    @tags "large" "arrays" "Int" "sums" "indexing"
end

# using small Float32 arrays...
@track BaseBenchmarks.TRACKER begin
    @setup arrays = makearrays(Float32, SMALL_SIZE)
    @benchmarks begin
        [(:sumelt, typeof(A), SMALL_N) => sumelt(A, SMALL_N) for A in arrays]
        [(:sumeach, typeof(A), SMALL_N) => sumeach(A, SMALL_N) for A in arrays]
        [(:sumlinear, typeof(A), SMALL_N) => sumlinear(A, SMALL_N) for A in arrays]
        [(:sumcartesian, typeof(A), SMALL_N) => sumcartesian(A, SMALL_N) for A in arrays]
        [(:sumcolon, typeof(A), SMALL_N) => sumcolon(A, SMALL_N) for A in arrays]
        [(:sumrange, typeof(A), SMALL_N) => sumrange(A, SMALL_N) for A in arrays]
        [(:sumlogical, typeof(A), SMALL_N) => sumlogical(A, SMALL_N) for A in arrays]
        [(:sumvector, typeof(A), SMALL_N) => sumvector(A, SMALL_N) for A in arrays]
    end
    @tags "small" "arrays" "Float" "sums" "indexing"
end

# using large Float32 arrays...
@track BaseBenchmarks.TRACKER begin
    @setup arrays = makearrays(Float32, LARGE_SIZE)
    @benchmarks begin
        [(:sumelt, typeof(A), LARGE_N) => sumelt(A, LARGE_N) for A in arrays]
        [(:sumeach, typeof(A), LARGE_N) => sumeach(A, LARGE_N) for A in arrays]
        [(:sumlinear, typeof(A), LARGE_N) => sumlinear(A, LARGE_N) for A in arrays]
        [(:sumcartesian, typeof(A), LARGE_N) => sumcartesian(A, LARGE_N) for A in arrays]
        [(:sumcolon, typeof(A), LARGE_N) => sumcolon(A, LARGE_N) for A in arrays]
        [(:sumrange, typeof(A), LARGE_N) => sumrange(A, LARGE_N) for A in arrays]
        [(:sumlogical, typeof(A), LARGE_N) => sumlogical(A, LARGE_N) for A in arrays]
        [(:sumvector, typeof(A), LARGE_N) => sumvector(A, LARGE_N) for A in arrays]
    end
    @tags "large" "arrays" "Float" "sums" "indexing"
end

end # module
