addprocs(1)

using JLD
using BaseBenchmarks
using BenchmarkTools

# re-tune the entire suite

function rewrite_params_file(paramsgroup)
    jldopen(BaseBenchmarks.PARAMS_PATH, "w") do file
        for (id, suite) in paramsgroup
            write(file, id, suite)
        end
    end
end

function rewrite_params_file(paramsgroup, id)
    old = BenchmarkTools.load(BaseBenchmarks.PARAMS_PATH)
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

# retune the whole suite #
#------------------------#
BaseBenchmarks.loadall!(tune = false)
warmup(BaseBenchmarks.SUITE)
tune!(BaseBenchmarks.SUITE; verbose = true)
rewrite_params_file(params(BaseBenchmarks.SUITE))

# retune an individual group (using "linalg" as an example) #
#-----------------------------------------------------------#
# id = "linalg"
# BaseBenchmarks.load!(id; tune = false)
# group = BaseBenchmarks.SUITE[id]
# warmup(group)
# tune!(group; verbose = true)
# rewrite_params_file(params(group), id)
