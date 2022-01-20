module AllocBenchmarks

using BenchmarkTools

const SUITE = BenchmarkGroup()

function perf_alloc_many_arrays()
    for _ in 1:10000000
        # global to ensure that this is heap allocated
        global a = []
    end
end

function perf_alloc_many_strings()
    for i in 1:10000000
        # global to ensure that this is heap allocated
        global b = "hello $(i)"
    end
end

SUITE["arrays"] = @benchmarkable perf_alloc_many_arrays()
SUITE["strings"] = @benchmarkable perf_alloc_many_strings()

end # module
