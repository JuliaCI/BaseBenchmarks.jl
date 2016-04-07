module StringBenchmarks

using ..BaseBenchmarks: SUITE
using ..RandUtils
using BenchmarkTools

####################
# replace (#12224) #
####################

str = join(samerand('a':'d', 10^4))

g = newgroup!(SUITE, "string", ["replace", "join"])

g["replace"] = @benchmarkable replace($str, "a", "b")
g["join"] = @benchmarkable join($str, $str)

end # module
