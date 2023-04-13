module BaseBenchmarks

using BenchmarkTools
using Pkg

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 1.0
BenchmarkTools.DEFAULT_PARAMETERS.samples = 10000
BenchmarkTools.DEFAULT_PARAMETERS.time_tolerance = 0.15
BenchmarkTools.DEFAULT_PARAMETERS.memory_tolerance = 0.01

const PARAMS_PATH = joinpath(dirname(@__FILE__), "..", "etc", "params.json")
const SUITE = BenchmarkGroup()
const MODULES = Dict("array" => :ArrayBenchmarks,
                     "alloc" => :AllocBenchmarks,
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
                     "frontend" => :FrontendBenchmarks,
                     )
@static VERSION ≥ v"1.8-DEV" && push!(MODULES, "inference" => :InferenceBenchmarks)

load!(id::AbstractString; kwargs...) = load!(SUITE, id; kwargs...)

function load!(group::BenchmarkGroup, id::AbstractString; tune::Bool = true)
    modsym = MODULES[id]
    modpath = joinpath(@__DIR__, id, "$(modsym).jl")

    # We allow our individual benchmark groups to have their own Project.toml file
    # but each of those should have the top-level `BaseBenchmarks` project dev'ed
    # out to a relative path of `../..`.
    version_specific_path = joinpath(@__DIR__, id, "$(VERSION.major).$(VERSION.minor)", "Project.toml")
    general_path = joinpath(@__DIR__, id, "Project.toml")
    if isfile(version_specific_path)
        needs_instantiate = true
        project_path = version_specific_path
    elseif isfile(general_path)
        needs_instantiate = true
        project_path = general_path
    else
        project_path = Base.active_project()
        needs_instantiate = false
    end

    Pkg.activate(project_path) do
        # If you're running into dependency problems when loading a benchmark,
        # try uncommenting this, it can help you to understand what's going on.
        # Pkg.status()
        needs_instantiate && Pkg.instantiate()

        Core.eval(Main, :(include($modpath)))
        modsuite = Core.eval(Main, modsym).SUITE
        group[id] = modsuite
        if tune
            results = BenchmarkTools.load(PARAMS_PATH)[1]
            haskey(results, id) && loadparams!(modsuite, results[id], :evals)
        end
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
