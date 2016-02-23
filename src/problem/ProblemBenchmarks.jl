module ProblemBenchmarks

# This module contains benchmarks that test against general problem cases taken
# from real-world examples (as opposed to microbenchmarks, language-agnostic
# benchmark suites, or benchmarks that stress specific implementation details).

# A lot of the benchmarks here originated from JuliaLang/julia/test/perf/kernel,
# where much of the code was naively translated to Julia from other languages,
# and thus is written non-idiomatically.

using ..BaseBenchmarks
using ..BenchmarkTools
using ..RandUtils

const PROBLEM_DATA_DIR = joinpath(Pkg.dir("BaseBenchmarks"), "src", "problem", "data")

#######################################
# IMDB Actor Centrality (Issue #1163) #
#######################################

include("IMDBGraphs.jl")

g = addgroup!(ENSEMBLE, "problem imdb graphs", ["problem", "example", "kernel", "graph", "centrality", "imdb"])

g["imdb_centrality"] = @benchmarkable IMDBGraphs.perf_imdb_centrality(50)

###############
# Monte Carlo #
###############

include("MonteCarlo.jl")

g = addgroup!(ENSEMBLE, "problem monte carlo", ["problem", "example", "kernel", "monte carlo",
                                                "finance", "vectorization", "random", "inplace"])

g["euro_option_devec"] = @benchmarkable MonteCarlo.perf_euro_option_devec(10^4)
g["euro_option_vec"] = @benchmarkable MonteCarlo.perf_euro_option_vec(10^4)

###################################
# Laplacian (Issues #1168, #4707) #
###################################

include("Laplacian.jl")

g = addgroup!(ENSEMBLE, "problem laplacian", ["problem", "example", "kernel", "laplacian", "iterative",
                                              "sparse", "vectorization", "subarray", "array"])

g["laplace_sparse_matvec"] = @benchmarkable Laplacian.perf_laplace_sparse_matvec(8^5)
g["laplace_iter_devec"] = @benchmarkable Laplacian.perf_laplace_iter_devec(8^2)
g["laplace_iter_vec"] = @benchmarkable Laplacian.perf_laplace_iter_vec(8^2)
g["laplace_iter_sub"] = @benchmarkable Laplacian.perf_laplace_iter_sub(8^2)

###################################################
# Grigoriadis Khachiyan Matrix Games (Issue #950) #
###################################################

include("GrigoriadisKhachiyan.jl")

g = addgroup!(ENSEMBLE, "problem grigoriadis khachiyan", ["problem", "example", "kernel",
                                                          "grigoriadis", "khachiyan", "game"])

g["grigoriadis_khachiyan"] = @benchmarkable GrigoriadisKhachiyan.perf_gk(350, [0.1])

####################################
# Go Game Simulation (Issue #1169) #
####################################

include("GoGame.jl")

g = addgroup!(ENSEMBLE, "problem go game", ["problem", "example", "kernel", "go", "game"])

g["grigoriadis_khachiyan"] = @benchmarkable GoGame.perf_go_game(10)

################
# JSON Parsing #
################

include("JSONParse.jl")

g = addgroup!(ENSEMBLE, "problem json parse", ["problem", "example", "kernel", "json", "parse", "closure"])

jstr = readstring(joinpath(PROBLEM_DATA_DIR, "test.json"))

g["parse_json"] = @benchmarkable JSONParse.perf_parse_json($(jstr))

############################
# Raytracing (Issue #3811) #
############################

include("Raytracer.jl")

g = addgroup!(ENSEMBLE, "problem raytrace", ["problem", "example", "kernel", "raytrace"])

g["raytrace"] = @benchmarkable Raytracer.perf_raytrace(5, 256, 4)

############################################
# Correlated Asset Simulation (Issue #445) #
############################################

include("StockCorr.jl")

g = addgroup!(ENSEMBLE, "problem stockcorr", ["problem", "example", "kernel", "finance", "stockcorr"])

g["stockcorr"] = @benchmarkable StockCorr.perf_stockcorr()

#########################
# Simplex (Issue #3142) #
#########################

include("Simplex.jl")

g = addgroup!(ENSEMBLE, "problem simplex", ["problem", "example", "kernel", "simplex"])

g["simplex"] = @benchmarkable Simplex.perf_simplex()

####################################################
# Ziggurat Gaussian Number Generator (Issue #1211) #
####################################################

include("Ziggurat.jl")

g = addgroup!(ENSEMBLE, "problem ziggurat", ["problem", "example", "kernel", "ziggurat"])

g["ziggurat"] = @benchmarkable Ziggurat.perf_ziggurat(10^6)

######################
# Seismic Simulation #
######################

include("SeismicSimulation.jl")

g = addgroup!(ENSEMBLE, "problem seismic simulation", ["problem", "example", "kernel", "seismic", "simd"])

for T in (Float32, Float64)
    g["seismic", string(T)] = @benchmarkable SeismicSimulation.perf_seismic_sim($T)
end

############################
# Sparse FEM (Issue #9668) #
############################

include("SparseFEM.jl")

g = addgroup!(ENSEMBLE, "problem sparse fem", ["problem", "example", "kernel", "sparse", "fem"])

g["sparse_fem"] = @benchmarkable SparseFEM.perf_sparse_fem(256)

###############
# Spell Check #
###############

include("SpellCheck.jl")

g = addgroup!(ENSEMBLE, "problem spellcheck", ["problem", "example", "kernel", "spell",
                                               "check", "spellcheck", "string"])

g["spellcheck"] = @benchmarkable SpellCheck.perf_spellcheck()

end # module
