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
    @tags "problem" "graph" "kernel" "centrality" "imdb" "movies"
end

end # module
