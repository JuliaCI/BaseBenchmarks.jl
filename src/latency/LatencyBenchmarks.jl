module LatencyBenchmarks

using BenchmarkTools
using Random
using Pkg

const SUITE = BenchmarkGroup()

pwd = @__DIR__

function julia_cmd()
    julia_path = joinpath(Sys.BINDIR, Base.julia_exename())
    cmd = `$julia_path --startup-file=no --project=$pwd`
end

temp_depot = nothing

function clean_env(reset_compiled=false)
    global temp_depot
    if temp_depot==nothing
        temp_depot = mktempdir()
        ENV["JULIA_DEPOT_PATH"] = temp_depot
        # Instantiate in the new depot path
        run(`$(julia_cmd()) -e 'using Pkg; Pkg.instantiate()'`)
    end
    if reset_compiled
        rm(joinpath(temp_depot, "compiled"); recursive=true, force=true)
    end
end

function compile_if_stale(pkg)
    pkgid = pkg == "DataFrames" ? Base.PkgId(Base.UUID("a93c6f00-e57d-5684-b7b6-d8193f3e46c0"), "DataFrames") :
            pkg == "Plots"      ? Base.PkgId(Base.UUID("91a5bcdd-55d7-5caf-9e0b-520d859cae80"), "Plots") :
            pkg == "CSV"        ? Base.PkgId(Base.UUID("336ed68f-0bac-5ca0-87d4-7b16caf5d00b"), "CSV") :
            error("unknown package")
    code = """
    import Base: UUID
    pkg = Base.PkgId($(repr(pkgid.uuid)), $(repr(pkgid.name)))
    paths = Base.find_all_in_cache_path(pkg)
    sourcepath = Base.locate_package(pkg)
    stale = true
    for path_to_try in paths
        staledeps = Base.stale_cachefile(sourcepath, path_to_try)
        staledeps === true && continue
        stale = false
        break
    end
    if stale
        Base.compilecache(pkg, sourcepath)
    end
    """
    run(`$(julia_cmd()) -e $code`)
end


# Julia startup time
SUITE["julia startup"] = @benchmarkable run(`$(julia_cmd()) -e ''`)

# Precompile DataFrames
for pkg in ["DataFrames", "CSV", "Plots"]
    s = "using $pkg"
    cmd = `$(julia_cmd()) -e $s`
    SUITE["precompile $pkg"] = @benchmarkable run($cmd) setup=(clean_env(true)) evals=1
    SUITE["load $pkg"] = @benchmarkable run($cmd) setup=(clean_env(); compile_if_stale($pkg))
end

SUITE["first plot"] = @benchmarkable run(`$(julia_cmd()) -e 'using Plots; p = plot(rand(5)); 
    savefig(p, tempname() *  ".png")'`) setup=(clean_env(); compile_if_stale("Plots"))
SUITE["first csv"] = @benchmarkable run(`$(julia_cmd()) -e 'using CSV;
    CSV.read("test.csv", silencewarnings=true)'`) setup=(clean_env(); compile_if_stale("CSV"))

end
