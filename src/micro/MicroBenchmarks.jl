module MicroBenchmarks

# This module contains the Julia microbenchmarks shown in the language
# comparison table at http://julialang.org/.

using ..BaseBenchmarks: SUITE
using BenchmarkTools

include("methods.jl")

g = newgroup!(SUITE, "micro", ["recursion", "fibonacci", "fib",  "parse", "parseint",
                                  "mandel", "mandelbrot", "sort", "quicksort", "pi", "π", "sum",
                                  "pisum", "πsum", "rand", "randmatstat", "rand", "randmatmul"])

g["fib"] = @benchmarkable perf_micro_fib(20)
g["parseint"] = @benchmarkable perf_micro_parseint(1000)
g["mandel"] = @benchmarkable perf_micro_mandel()
g["quicksort"] = @benchmarkable perf_micro_quicksort(5000)
g["pisum"] = @benchmarkable perf_micro_pisum()
g["randmatstat"] = @benchmarkable perf_micro_randmatstat(1000)
g["randmatmul"] = @benchmarkable perf_micro_randmatmul(1000)

end # module
