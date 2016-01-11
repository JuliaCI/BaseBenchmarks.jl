module ProblemBenchmarks

# This module contains benchmarks that test against general problem cases taken
# from real-world examples (as opposed to microbenchmarks, or benchmarks that
# stress specific implementation details). A lot of the benchmarks here
# originated from JuliaLang/julia/test/perf/kernel.

import BaseBenchmarks
using BenchmarkTrackers

#########################
# IMDB Actor Centrality #
#########################

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

end # module
