module ProblemBenchmarks

# This module contains benchmarks that test against general problem cases taken
# from real-world examples (as opposed to microbenchmarks, language-agnostic
# benchmark suites, or benchmarks that stress specific implementation details).

# A lot of the benchmarks here originated from JuliaLang/julia/test/perf/kernel,
# where much of the code was naively translated to Julia from other languages,
# and thus is written non-idiomatically.

import ..BaseBenchmarks
using ..BenchmarkTrackers
using ..RandUtils

const PROBLEM_DATA_DIR = joinpath(Pkg.dir("BaseBenchmarks"), "src", "problem", "data")

#######################################
# IMDB Actor Centrality (Issue #1163) #
#######################################

include("IMDBGraphs.jl")

@track BaseBenchmarks.TRACKER "problem imdb graphs" begin
    @benchmarks begin
        (:imdb_centrality,) => IMDBGraphs.perf_imdb_centrality(50)
    end
    @tags "problem" "example" "kernel" "graph" "centrality" "imdb"
end

###############
# Monte Carlo #
###############

include("MonteCarlo.jl")

@track BaseBenchmarks.TRACKER "problem monte carlo" begin
    @setup n = 10^4
    @benchmarks begin
        (:euro_option_devec,) => MonteCarlo.perf_euro_option_devec(n)
        (:euro_option_vec,) => MonteCarlo.perf_euro_option_vec(n)
    end
    @tags "problem" "example" "kernel" "monte carlo" "finance" "vectorization" "random" "inplace"
end

###################################
# Laplacian (Issues #1168, #4707) #
###################################

include("Laplacian.jl")

@track BaseBenchmarks.TRACKER "problem laplacian" begin
    @setup begin
        sparse_size = 8^5
        iter_size = 8^2
    end
    @benchmarks begin
        (:laplace_sparse_matvec,) => Laplacian.perf_laplace_sparse_matvec(sparse_size)
        (:laplace_iter_devec,) => Laplacian.perf_laplace_iter_devec(iter_size)
        (:laplace_iter_vec,) => Laplacian.perf_laplace_iter_vec(iter_size)
        (:laplace_iter_sub,) => Laplacian.perf_laplace_iter_sub(iter_size)
    end
    @tags "problem" "example" "kernel" "laplacian" "iterative" "sparse" "vectorization" "subarray" "linalg" "array"
end

###################################################
# Grigoriadis Khachiyan Matrix Games (Issue #950) #
###################################################

include("GrigoriadisKhachiyan.jl")

@track BaseBenchmarks.TRACKER "problem grigoriadis khachiyan" begin
    @benchmarks begin
        (:grigoriadis_khachiyan,) => GrigoriadisKhachiyan.perf_gk(350, [0.1])
    end
    @tags "problem" "example" "kernel" "grigoriadis" "khachiyan" "game"
end

####################################
# Go Game Simulation (Issue #1169) #
####################################

include("GoGame.jl")

@track BaseBenchmarks.TRACKER "problem go game" begin
    @benchmarks begin
        (:go_game,) => GoGame.perf_go_game(10)
    end
    @tags "problem" "example" "kernel" "go" "game"
end

################
# JSON Parsing #
################

include("JSONParse.jl")

@track BaseBenchmarks.TRACKER "problem json parse" begin
    @setup begin
        json_path = joinpath(PROBLEM_DATA_DIR, "test.json")
        json_str = readall(json_path)
    end
    @benchmarks begin
        (:parse_json,) => JSONParse.perf_parse_json(json_str)
    end
    @tags "problem" "example" "kernel" "json" "parse" "closure"
end

############################
# Raytracing (Issue #3811) #
############################

include("Raytracer.jl")

@track BaseBenchmarks.TRACKER "problem raytrace" begin
    @benchmarks begin
        (:raytrace,) => Raytracer.perf_raytrace(5, 256, 4)
    end
    @tags "problem" "example" "kernel" "raytrace"
end

############################################
# Correlated Asset Simulation (Issue #445) #
############################################

include("StockCorr.jl")

@track BaseBenchmarks.TRACKER "problem stockcorr" begin
    @benchmarks begin
        (:stockcorr,) => StockCorr.perf_stockcorr()
    end
    @tags "problem" "example" "kernel" "finance" "stockcorr"
end

#########################
# Simplex (Issue #3142) #
#########################

include("Simplex.jl")

@track BaseBenchmarks.TRACKER "problem simplex" begin
    @benchmarks begin
        (:simplex,) => Simplex.perf_simplex()
    end
    @tags "problem" "example" "kernel" "simplex"
end

####################################################
# Ziggurat Gaussian Number Generator (Issue #1211) #
####################################################

include("Ziggurat.jl")

@track BaseBenchmarks.TRACKER "problem ziggurat" begin
    @benchmarks begin
        (:ziggurat,) => Ziggurat.perf_ziggurat(10^6)
    end
    @tags "problem" "example" "kernel" "ziggurat"
end

######################
# Seismic Simulation #
######################

include("SeismicSimulation.jl")

@track BaseBenchmarks.TRACKER "problem seismic simulation" begin
    @setup Ts = (Float32, Float64)
    @benchmarks begin
        [(:seismic, string(T)) => SeismicSimulation.perf_seismic_sim(T) for T in Ts]
    end
    @tags "problem" "example" "kernel" "seismic" "simd"
end

############################
# Sparse FEM (Issue #9668) #
############################

include("SparseFEM.jl")

@track BaseBenchmarks.TRACKER "problem sparse fem" begin
    @benchmarks begin
        (:sparse_fem,) => SparseFEM.perf_sparse_fem(256)
    end
    @tags "problem" "example" "kernel" "sparse" "fem"
end

###############
# Spell Check #
###############

include("SpellCheck.jl")

@track BaseBenchmarks.TRACKER "problem spellcheck" begin
    @benchmarks begin
        (:spellcheck,) => SpellCheck.perf_spellcheck(SpellCheck.TEST_DATA)
    end
    @tags "problem" "example" "kernel" "spell" "check" "spellcheck" "string"
end


end # module
