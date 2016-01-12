module ProblemBenchmarks

# This module contains benchmarks that test against general problem cases taken
# from real-world examples (as opposed to microbenchmarks, or benchmarks that
# stress specific implementation details). A lot of the benchmarks here
# originated from JuliaLang/julia/test/perf/kernel.

# Some of these benchmarks are not written idiomatically, but instead follow
# a MATLAB-like style. These kinds of benchmarks usually originate from people
# sharing MATLAB code that runs faster than a direct Julia translation. Since
# one of Julia's target audiences is the MATLAB crowd, we've kept some of
# MATLABiness of the original code to make sure we cover this common case.

import BaseBenchmarks
using BenchmarkTrackers

#######################################
# IMDB Actor Centrality (Issue #1163) #
#######################################

include("IMDBGraphs.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks begin
        [(:imdb_centrality, n) => IMDBGraphs.perf_imdb_centrality(n) for n in (5, 50)]
    end
    @tags "problem" "example" "kernel" "graph" "centrality" "imdb"
end

###############
# Monte Carlo #
###############

include("MonteCarlo.jl")

@track BaseBenchmarks.TRACKER begin
    @setup npaths = (10, 10^2, 10^3, 10^4)
    @benchmarks begin
        [(:euro_option_devec, n) => MonteCarlo.perf_euro_option_devec(n) for n in npaths]
        [(:euro_option_vec, n) => MonteCarlo.perf_euro_option_vec(n) for n in npaths]
    end
    @tags "problem" "example" "kernel" "monte carlo" "finance" "vectorization" "random" "inplace"
end

###################################
# Laplacian (Issues #1168, #4707) #
###################################

include("Laplacian.jl")

@track BaseBenchmarks.TRACKER begin
    @setup begin
        sparse_sizes = (8^4, 8^5)
        iter_sizes = (8, 8^2)
    end
    @benchmarks begin
        [(:laplace_sparse_matvec, n) => Laplacian.perf_laplace_sparse_matvec(n) for n in sparse_sizes]
        [(:laplace_iter_devec, n) => Laplacian.perf_laplace_iter_devec(n) for n in iter_sizes]
        [(:laplace_iter_vec, n) => Laplacian.perf_laplace_iter_vec(n) for n in iter_sizes]
        [(:laplace_iter_sub, n) => Laplacian.perf_laplace_iter_devec(n) for n in iter_sizes]
    end
    @tags "problem" "example" "kernel" "laplacian" "iterative" "sparse" "vectorization" "subarray" "linalg" "array"
end

###################################################
# Grigoriadis Khachiyan Matrix Games (Issue #950) #
###################################################

include("GrigoriadisKhachiyan.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks begin
        [(:grigoriadis_khachiyan, n) => GrigoriadisKhachiyan.perf_gk(n, [0.1]) for n in (10, 10^2, 10^3)]
    end
    @tags "problem" "example" "kernel" "grigoriadis" "khachiyan" "game"
end

####################################
# Go Game Simulation (Issue #1169) #
####################################

include("GoGame.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks begin
        [(:go_game, n) => GoGame.perf_go_game(n) for n in (10, 20)]
    end
    @tags "problem" "example" "kernel" "go" "game"
end

################
# JSON Parsing #
################

include("JSONParse.jl")

@track BaseBenchmarks.TRACKER begin
    @setup begin
        json_path = joinpath(Pkg.dir("BaseBenchmarks"), "src", "problem", "data", "test.json")
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

@track BaseBenchmarks.TRACKER begin
    @benchmarks begin
        (:raytrace,) => Raytracer.perf_raytrace(5, 256, 4)
    end
    @tags "problem" "example" "kernel" "raytrace"
end

end # module
