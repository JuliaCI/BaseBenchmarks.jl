module MicroBenchmarks

# This module contains the Julia microbenchmarks shown in the language
# comparison table at http://julialang.org/.

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))
include("methods.jl")

using .RandUtils
using BenchmarkTools
using Compat

const SUITE = BenchmarkGroup(["recursion", "fibonacci", "fib",  "parse", "parseint",
                              "mandel", "mandelbrot", "sort", "quicksort", "pi", "π", "sum",
                              "pisum", "πsum", "rand", "randmatstat", "rand", "randmatmul"])

SUITE["fib"] = @benchmarkable perf_micro_fib(20)
SUITE["parseint"] = @benchmarkable perf_micro_parseint(1000)
SUITE["mandel"] = @benchmarkable perf_micro_mandel()
SUITE["quicksort"] = @benchmarkable perf_micro_quicksort(5000)
SUITE["pisum"] = @benchmarkable perf_micro_pisum()
SUITE["randmatstat"] = @benchmarkable perf_micro_randmatstat(1000)
SUITE["randmatmul"] = @benchmarkable perf_micro_randmatmul(1000)

end # module
