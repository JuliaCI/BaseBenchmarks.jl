addprocs(1)

using JLD
using BaseBenchmarks
using BenchmarkTools

# re-tune the entire suite
BaseBenchmarks.loadall!(tune = false)
@warmup BaseBenchmarks.SUITE
tune!(BaseBenchmarks.SUITE; seconds = 10, verbose = true)

jldopen(BaseBenchmarks.PARAMS_PATH, "w") do file
    for (id, suite) in BaseBenchmarks.SUITE
        write(file, id, params(suite))
    end
end
