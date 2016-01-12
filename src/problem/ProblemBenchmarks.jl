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
        (:imdb_centrality,) => IMDBGraphs.perf_imdb_centrality(50)
    end
    @tags "problem" "example" "kernel" "graph" "centrality" "imdb"
end

###############
# Monte Carlo #
###############

include("MonteCarlo.jl")

@track BaseBenchmarks.TRACKER begin
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

@track BaseBenchmarks.TRACKER begin
    @setup begin
        sparse_size = 8^5
        iter_size = 8^2
    end
    @benchmarks begin
        (:laplace_sparse_matvec,) => Laplacian.perf_laplace_sparse_matvec(sparse_size)
        (:laplace_iter_devec,) => Laplacian.perf_laplace_iter_devec(iter_size)
        (:laplace_iter_vec,) => Laplacian.perf_laplace_iter_vec(iter_size)
        (:laplace_iter_sub,) => Laplacian.perf_laplace_iter_devec(iter_size)
    end
    @tags "problem" "example" "kernel" "laplacian" "iterative" "sparse" "vectorization" "subarray" "linalg" "array"
end

###################################################
# Grigoriadis Khachiyan Matrix Games (Issue #950) #
###################################################

include("GrigoriadisKhachiyan.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks begin
        (:grigoriadis_khachiyan,) => GrigoriadisKhachiyan.perf_gk(350, [0.1])
    end
    @tags "problem" "example" "kernel" "grigoriadis" "khachiyan" "game"
end

####################################
# Go Game Simulation (Issue #1169) #
####################################

include("GoGame.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks begin
        (:go_game,) => GoGame.perf_go_game(10)
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

#############################################
# Correlated Asset Simulation (Issue #445) #
#############################################

include("StockCorr.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks begin
        (:stockcorr,) => StockCorr.perf_stockcorr()
    end
    @tags "problem" "example" "kernel" "finance" "stockcorr"
end

#########################
# Simplex (Issue #3142) #
#########################

include("Simplex.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks begin
        (:simplex,) => Simplex.perf_simplex()
    end
    @tags "problem" "example" "kernel" "simplex"
end

####################################################
# Ziggurat Gaussian Number Generator (Issue #1211) #
####################################################

include("Ziggurat.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks begin
        (:ziggurat,) => Ziggurat.perf_ziggurat(10^6)
    end
    @tags "problem" "example" "kernel" "ziggurat"
end


end # module
