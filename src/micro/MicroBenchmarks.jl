module MicroBenchmarks

# This module contains the Julia microbenchmarks shown in the language
# comparison table at http://julialang.org/.

import BaseBenchmarks
using BenchmarkTrackers

include("methods.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks begin
        (:micro, :fib) => perf_micro_fib(20)
        (:micro, :parseint) => perf_micro_parseint(1000)
        (:micro, :mandel) => perf_micro_mandel()
        (:micro, :quicksort) => perf_micro_quicksort(5000)
        (:micro, :πsum) => perf_micro_πsum()
        (:micro, :randmatstat) => perf_micro_randmatstat(1000)
        (:micro, :randmatmul) => perf_micro_randmatmul(1000)
    end
    @tags("micro", "recursion", "fibonacci", "fib",  "parse", "parseint",
          "mandel", "mandelbrot", "sort", "quicksort", "pi", "π", "sum",
          "pisum", "πsum", "rand", "randmatstat", "rand", "randmatmul")
end

end # module
