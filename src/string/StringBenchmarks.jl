module StringBenchmarks

using ..BaseBenchmarks
using ..BenchmarkTools
using ..RandUtils

####################
# replace (#12224) #
####################

str = join(samerand('a':'d', 10^4))

g = addgroup!(ENSEMBLE, "string replace", ["string", "replace"])

g["replace"] = @benchmarkable replace($str, "a", "b")

end # module
