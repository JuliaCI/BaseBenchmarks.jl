module BaseBenchmarks

using BenchmarkTools
using JLD
using Compat

BenchmarkTools.DEFAULT_PARAMETERS.time_tolerance = 0.10
BenchmarkTools.DEFAULT_PARAMETERS.memory_tolerance = 0.01

const SUITE = BenchmarkGroup()
const TUNED_EVALS = JLD.load(joinpath(Pkg.dir("BaseBenchmarks"), "etc", "evals.jld"), "suite")

const MODULES = Dict("array" => :ArrayBenchmarks,
                     "io" => :IOBenchmarks,
                     "linalg" => :LinAlgBenchmarks,
                     "micro" => :MicroBenchmarks,
                     "parallel" => :ParallelBenchmarks,
                     "problem" => :ProblemBenchmarks,
                     "scalar" => :ScalarBenchmarks,
                     "shootout" => :ShootoutBenchmarks,
                     "simd" => :SIMDBenchmarks,
                     "sort" => :SortBenchmarks,
                     "sparse" => :SparseBenchmarks,
                     "string" => :StringBenchmarks,
                     "tuple" => :TupleBenchmarks)

load!(id::AbstractString) = load!(SUITE, id)

function load!(group::BenchmarkGroup, id::AbstractString, tune::Bool = true)
    modsym = MODULES[id]
    modpath = joinpath(Pkg.dir("BaseBenchmarks"), "src", id, "$(modsym).jl")
    eval(BaseBenchmarks, :(include($modpath)))
    modsuite = eval(BaseBenchmarks, modsym).SUITE
    group[id] = modsuite
    tune && loadevals!(modsuite, TUNED_EVALS[id])
    return group
end

loadall!(verbose::Bool = true) = loadall!(SUITE, verbose)

function loadall!(group::BenchmarkGroup, verbose::Bool = true)
    for id in keys(MODULES)
        verbose && print("loading group $(repr(id))..."); tic();
        load!(group, id, false)
        verbose && println("done (took $(toq()) seconds)")
    end
    loadevals!(group, TUNED_EVALS)
end

end # module
