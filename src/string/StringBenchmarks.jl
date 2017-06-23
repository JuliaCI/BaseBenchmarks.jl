module StringBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

import Compat: UTF8String, view

const SUITE = BenchmarkGroup()

####################
# replace (#12224) #
####################

str = join(samerand('a':'d', 10^4))

SUITE["replace"] = @benchmarkable replace($str, "a", "b")
SUITE["join"] = @benchmarkable join($str, $str) time_tolerance=0.40

str = "Gf6FPPWevqer3di13haDSzrRrSiThqmV3k02dALLu7OHdYRR0dfrKf4iCMcDvgZBawx"

g = addgroup!(SUITE, "search")
g["Char"] = @benchmarkable search($str,  $('x'))
g["String"] = @benchmarkable search($str, $("x"))

g = addgroup!(SUITE, "searchindex")
g["Char"] = @benchmarkable searchindex($str,  $('x'))
g["String"] = @benchmarkable searchindex($str, $("x"))

end # module
