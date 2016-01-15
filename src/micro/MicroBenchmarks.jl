module MicroBenchmarks

# This module contains the Julia microbenchmarks shown in the language
# comparison table at http://julialang.org/.

import BaseBenchmarks
using BenchmarkTrackers

include("methods.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks "micro" begin
        (:fib,) => perf_micro_fib(20)
        (:parseint,) => perf_micro_parseint(1000)
        (:mandel,) => perf_micro_mandel()
        (:quicksort,) => perf_micro_quicksort(5000)
        (:πsum,) => perf_micro_πsum()
        (:randmatstat,) => perf_micro_randmatstat(1000)
        (:randmatmul,) => perf_micro_randmatmul(1000)
    end
    @tags("micro", "recursion", "fibonacci", "fib",  "parse", "parseint",
          "mandel", "mandelbrot", "sort", "quicksort", "pi", "π", "sum",
          "pisum", "πsum", "rand", "randmatstat", "rand", "randmatmul")
end

end # module
