module ProblemBenchmarks

# This module contains benchmarks that test against general problem cases taken
# from real-world examples (as opposed to microbenchmarks, language-agnostic
# benchmark suites, or benchmarks that stress specific implementation details).
# A lot of the benchmarks here originated from JuliaLang/julia/test/perf/kernel.

# Many of these benchmarks are not written idiomatically. Usually, this is the
# result of users sharing a naive Julia translation of code written in a
# different language which demonstrates a notable performance difference in
# comparison with the original langauge implementation..

import BaseBenchmarks
using BenchmarkTrackers

const PROBLEM_PREFIX = "problem"

#######################################
# IMDB Actor Centrality (Issue #1163) #
#######################################

include("IMDBGraphs.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks PROBLEM_PREFIX begin
        (:imdb_centrality,) => IMDBGraphs.perf_imdb_centrality(50)
    end
    @tags PROBLEM_PREFIX "example" "kernel" "graph" "centrality" "imdb"
end

###############
# Monte Carlo #
###############

include("MonteCarlo.jl")

@track BaseBenchmarks.TRACKER begin
    @setup n = 10^4
    @benchmarks PROBLEM_PREFIX begin
        (:euro_option_devec,) => MonteCarlo.perf_euro_option_devec(n)
        (:euro_option_vec,) => MonteCarlo.perf_euro_option_vec(n)
    end
    @tags PROBLEM_PREFIX "example" "kernel" "monte carlo" "finance" "vectorization" "random" "inplace"
end

###################################
# Laplacian (Issues #1168, #4707) #
###################################

include("Laplacian.jl")

@track BaseBenchmarks.TRACKER begin
    @setup begin
        sparse_size = 8^5
        iter_size = 8^2
    end
    @benchmarks PROBLEM_PREFIX begin
        (:laplace_sparse_matvec,) => Laplacian.perf_laplace_sparse_matvec(sparse_size)
        (:laplace_iter_devec,) => Laplacian.perf_laplace_iter_devec(iter_size)
        (:laplace_iter_vec,) => Laplacian.perf_laplace_iter_vec(iter_size)
        (:laplace_iter_sub,) => Laplacian.perf_laplace_iter_devec(iter_size)
    end
    @tags PROBLEM_PREFIX "example" "kernel" "laplacian" "iterative" "sparse" "vectorization" "subarray" "linalg" "array"
end

###################################################
# Grigoriadis Khachiyan Matrix Games (Issue #950) #
###################################################

include("GrigoriadisKhachiyan.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks PROBLEM_PREFIX begin
        (:grigoriadis_khachiyan,) => GrigoriadisKhachiyan.perf_gk(350, [0.1])
    end
    @tags PROBLEM_PREFIX "example" "kernel" "grigoriadis" "khachiyan" "game"
end

####################################
# Go Game Simulation (Issue #1169) #
####################################

include("GoGame.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks PROBLEM_PREFIX begin
        (:go_game,) => GoGame.perf_go_game(10)
    end
    @tags PROBLEM_PREFIX "example" "kernel" "go" "game"
end

################
# JSON Parsing #
################

include("JSONParse.jl")

@track BaseBenchmarks.TRACKER begin
    @setup begin
        json_path = joinpath(Pkg.dir("BaseBenchmarks"), "src", PROBLEM_PREFIX, "data", "test.json")
        json_str = readall(json_path)
    end
    @benchmarks PROBLEM_PREFIX begin
        (:parse_json,) => JSONParse.perf_parse_json(json_str)
    end
    @tags PROBLEM_PREFIX "example" "kernel" "json" "parse" "closure"
end

############################
# Raytracing (Issue #3811) #
############################

include("Raytracer.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks PROBLEM_PREFIX begin
        (:raytrace,) => Raytracer.perf_raytrace(5, 256, 4)
    end
    @tags PROBLEM_PREFIX "example" "kernel" "raytrace"
end

#############################################
# Correlated Asset Simulation (Issue #445) #
#############################################

include("StockCorr.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks PROBLEM_PREFIX begin
        (:stockcorr,) => StockCorr.perf_stockcorr()
    end
    @tags PROBLEM_PREFIX "example" "kernel" "finance" "stockcorr"
end

#########################
# Simplex (Issue #3142) #
#########################

include("Simplex.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks PROBLEM_PREFIX begin
        (:simplex,) => Simplex.perf_simplex()
    end
    @tags PROBLEM_PREFIX "example" "kernel" "simplex"
end

####################################################
# Ziggurat Gaussian Number Generator (Issue #1211) #
####################################################

include("Ziggurat.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks PROBLEM_PREFIX begin
        (:ziggurat,) => Ziggurat.perf_ziggurat(10^6)
    end
    @tags PROBLEM_PREFIX "example" "kernel" "ziggurat"
end

######################
# Seismic Simulation #
######################

include("SeismicSimulation.jl")

@track BaseBenchmarks.TRACKER begin
    @setup Ts = (Float32, Float64)
    @benchmarks PROBLEM_PREFIX begin
        [(:seismic, string(T)) => SeismicSimulation.perf_seismic_sim(T) for T in Ts]
    end
    @tags PROBLEM_PREFIX "example" "kernel" "seismic" "simd"
end

end # module
