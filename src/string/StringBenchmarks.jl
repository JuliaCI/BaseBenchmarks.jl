module StringBenchmarks

using ..BaseBenchmarks: GROUPS
using ..RandUtils
using BenchmarkTools

####################
# replace (#12224) #
####################

str = join(samerand('a':'d', 10^4))

g = addgroup!(GROUPS, "string replace", ["string", "replace"])

g["replace"] = @benchmarkable replace($str, "a", "b")

end # module
