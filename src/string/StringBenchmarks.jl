module StringBenchmarks

include(joinpath(Pkg.dir("BaseBenchmarks"), "src", "utils", "RandUtils.jl"))

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
SUITE["join"] = @benchmarkable join($str, $str) time_tolerance = 0.40

end # module
