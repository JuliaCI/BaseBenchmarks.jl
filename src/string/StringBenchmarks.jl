module StringBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools

const SUITE = BenchmarkGroup()

####################
# replace (#12224) #
####################

str = join(samerand('a':'d', 10^4))

SUITE["replace"] = @benchmarkable replace($str, "a" => "b")
SUITE["join"] = @benchmarkable join($str, $str) time_tolerance=0.40

str = "Gf6FPPWevqer3di13haDSzrRrSiThqmV3k02dALLu7OHdYRR0dfrKf4iCMcDvgZBawx"

# The searchindex deprecation target makes the updated searchindex group
# redundant with the updated search group, so they've been combined here
g = addgroup!(SUITE, "findfirst")
g["Char"] = @benchmarkable findfirst(isequal($('x')), $str)
g["String"] = @benchmarkable findfirst($("x"), $str)

######################
# readuntil (#20621) #
######################

buffer = IOBuffer("A" ^ 50000)

g = addgroup!(SUITE, "readuntil")
for len in (1, 2, 1000, 50000)
    g["target length $len"] = @benchmarkable readuntil(seekstart($buffer), $("A" ^ len))
end

buffer = IOBuffer(("A" ^ 50000) * "B")
target = ("A" ^ 5000) * "Z"
g["backtracking"] = @benchmarkable readuntil(seekstart($buffer), $target)

buffer = IOBuffer(String(rand(RandUtils.SEED, 'A':'X', 40000)) * target)
target = "Y" * ("Z" ^ 999)
g["no backtracking"] = @benchmarkable readuntil(seekstart($buffer), $target)

buffer = IOBuffer(("bar" ^ 20000) * "ians")
target = ("bar" ^ 300) * "ian"
g["barbarian backtrack"] = @benchmarkable readuntil(seekstart($buffer), $target)

#################
# repeat #22462 #
#################

g = addgroup!(SUITE, "repeat")
g["repeat str len 1"] = @benchmarkable repeat(" ", 500)
g["repeat str len 16"] = @benchmarkable repeat("repeatmerepeatme", 500)
g["repeat char 1"] = @benchmarkable repeat(' ', 500)
g["repeat char 2"] = @benchmarkable repeat('α', 500)

###################################################
# ==(::AbstractString, ::AbstractString) (#37192) #
###################################################

str = "A" ^ 1000

g = addgroup!(SUITE, "==(::AbstractString, ::AbstractString)")

g["identical"] = @benchmarkable invoke(==, Tuple{AbstractString, AbstractString}, $"ABC", $"ABC")
g["different length"] = @benchmarkable $(SubString("ABC")) == $"ABCD"
g["equal"] = @benchmarkable $(SubString("ABC")) == $"ABC"
g["different"] = @benchmarkable $(SubString("ABC")) == $"DEF"
g["long equal"] = @benchmarkable $(SubString(str)) == $str

end # module
