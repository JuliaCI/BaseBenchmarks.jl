module BaseBenchmarks

using BenchmarkTools

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 1.0
BenchmarkTools.DEFAULT_PARAMETERS.samples = 10000
BenchmarkTools.DEFAULT_PARAMETERS.time_tolerance = 0.15
BenchmarkTools.DEFAULT_PARAMETERS.memory_tolerance = 0.01

const PARAMS_PATH = joinpath(dirname(@__FILE__), "..", "etc", "params.json")
const SUITE = BenchmarkGroup()
const MODULES = Dict("array" => :ArrayBenchmarks,
                     "broadcast" => :BroadcastBenchmarks,
                     "collection" => :CollectionBenchmarks,
                     "dates" => :DatesBenchmarks,
                     "find" => :FindBenchmarks,
                     "io" => :IOBenchmarks,
                     "linalg" => :LinAlgBenchmarks,
                     "micro" => :MicroBenchmarks,
                     "misc" => :MiscellaneousBenchmarks,
                     "union" => :UnionBenchmarks,
                     "parallel" => :ParallelBenchmarks,
                     "problem" => :ProblemBenchmarks,
                     "random" => :RandomBenchmarks,
                     "scalar" => :ScalarBenchmarks,
                     "shootout" => :ShootoutBenchmarks,
                     "simd" => :SIMDBenchmarks,
                     "sort" => :SortBenchmarks,
                     "sparse" => :SparseBenchmarks,
                     "string" => :StringBenchmarks,
                     "tuple" => :TupleBenchmarks,
                     "frontend" => :FrontendBenchmarks)

load!(id::AbstractString; kwargs...) = load!(SUITE, id; kwargs...)

function load!(group::BenchmarkGroup, id::AbstractString; tune::Bool = true)
    modsym = MODULES[id]
    modpath = joinpath(dirname(@__FILE__), id, "$(modsym).jl")
    Core.eval(BaseBenchmarks, :(include($modpath)))
    modsuite = Core.eval(BaseBenchmarks, modsym).SUITE
    group[id] = modsuite
    if tune
        results = BenchmarkTools.load(PARAMS_PATH)[1]
        haskey(results, id) && loadparams!(modsuite, results[id], :evals)
    end
    return group
end

loadall!(; kwargs...) = loadall!(SUITE; kwargs...)

function loadall!(group::BenchmarkGroup; verbose::Bool = true, tune::Bool = true)
    for id in keys(MODULES)
        if verbose
            print("loading group $(repr(id))... ")
            time = @elapsed load!(group, id, tune=false)
            println("done (took $time seconds)")
        else
            load!(group, id, tune=false)
        end
    end
    if tune
        results = BenchmarkTools.load(PARAMS_PATH)[1]
        for (id, suite) in group
            haskey(results, id) && loadparams!(suite, results[id], :evals)
        end
    end
    return group
end

end # module
