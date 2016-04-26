addprocs(1)

using JLD
using BaseBenchmarks
using BenchmarkTools

# re-tune the entire suite
BaseBenchmarks.loadall!(tune = false)
warmup(BaseBenchmarks.SUITE)
tune!(BaseBenchmarks.SUITE; seconds = 10, verbose = true)

function rewrite_params_file(paramsgroup)
    jldopen(BaseBenchmarks.PARAMS_PATH, "w") do file
        for (id, suite) in paramsgroup
            write(file, id, suite)
        end
    end
end

function rewrite_params_file(paramsgroup, id)
    old = JLD.load(BaseBenchmarks.PARAMS_PATH)
    jldopen(BaseBenchmarks.PARAMS_PATH, "w") do file
        for (oldid, oldsuite) in old
            if oldid == id
                write(file, oldid, paramsgroup)
            else
                write(file, oldid, oldsuite)
            end
        end
    end
end

rewrite_params_file(params(BaseBenchmarks.SUITE))
