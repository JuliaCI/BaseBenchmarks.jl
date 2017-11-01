module RandomBenchmarks

using BenchmarkTools
using Base.Random: RangeGenerator
using Compat

const SUITE = BenchmarkGroup()

const BITINTS = [Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128]
const INTS    = [BITINTS; BigInt; Bool]
const FLOATS  = [Float16, Float32, Float64]
const CFLOATS = [Complex{T} for T in FLOATS]
const NUMS    = [INTS; FLOATS; CFLOATS; [Complex{T} for T in BITINTS];]

const MT = MersenneTwister(0)
const RD = RandomDevice()
const vectint = Vector{Int}(1000)

function set_tolerance!(g, tol=0.25)
    for b in values(g)
        b.params.time_tolerance = tol
    end
end

##########
# Ranges #
##########

g = addgroup!(SUITE, "ranges", ["rand", "rand!", "RangeGenerator"])

g["rand",  "ImplicitRNG",     "Int", "1:1000"] = @benchmarkable rand($(1:1000))
g["rand",  "MersenneTwister", "Int", "1:1000"] = @benchmarkable rand($MT, $(1:1000))
g["rand",  "RandomDevice",    "Int", "1:1000"] = @benchmarkable rand($RD, $(1:1000))
g["rand!", "ImplicitRNG",     "Int", "1:1000"] = @benchmarkable rand!($vectint, $(1:1000))
g["rand!", "MersenneTwister", "Int", "1:1000"] = @benchmarkable rand!($MT, $vectint, $(1:1000))
g["rand!", "RandomDevice",    "Int", "1:1000"] = @benchmarkable rand!($RD, $vectint, $(1:1000))

const b2 = big(2)

for T in INTS
    tstr = string(T)
    onestr = string(one(T))
    for n in T[filter(x -> T === BigInt || x <= typemax(T),
                      [1, 2^32-1, b2^32+1, b2^64-1, b2^64, b2^127, b2^10000]);]
        nstr = n == b2^10000 ? "2^10000" : string(n)
        g["RangeGenerator", tstr, "$onestr:$nstr"] = @benchmarkable RangeGenerator($(T(1):n))
        g["rand", "MersenneTwister", tstr, "RangeGenerator($onestr:$nstr)"] =
            @benchmarkable rand($MT, $(RangeGenerator(T(1):n)))
    end
end

set_tolerance!(g)

#########
# Types #
#########

g = addgroup!(SUITE, "types", ["rand", "rand!", "randn", "randn!", "randexp", "randexp!"])

g["rand",    "ImplicitRNG",     "ImplicitFloat64"] = @benchmarkable rand()
g["rand",    "RandomDevice",    "ImplicitFloat64"] = @benchmarkable rand($RD)
g["rand",    "MersenneTwister", "ImplicitFloat64"] = @benchmarkable rand($MT)
g["randn",   "ImplicitRNG",     "ImplicitFloat64"] = @benchmarkable randn()
g["randn",   "RandomDevice",    "ImplicitFloat64"] = @benchmarkable randn($RD)
g["randn",   "MersenneTwister", "ImplicitFloat64"] = @benchmarkable randn($MT)
g["randexp", "ImplicitRNG",     "ImplicitFloat64"] = @benchmarkable randexp()
g["randexp", "RandomDevice",    "ImplicitFloat64"] = @benchmarkable randexp($RD)
g["randexp", "MersenneTwister", "ImplicitFloat64"] = @benchmarkable randexp($MT)

for T = [Int, Float64]
    tstr = string(T)
    dst = Vector{T}(1000)
    g["rand",     "ImplicitRNG",  tstr] = @benchmarkable rand($T)
    g["rand",     "RandomDevice", tstr] = @benchmarkable rand($RD, $T)
    g["rand!",    "ImplicitRNG",  tstr] = @benchmarkable rand!($dst)
    g["rand!",    "RandomDevice", tstr] = @benchmarkable rand!($RD, $dst)
    T === Float64 && VERSION >= v"0.5.0-pre+5657" || continue
    g["randn",    "ImplicitRNG",  tstr] = @benchmarkable randn($T)
    g["randn",    "RandomDevice", tstr] = @benchmarkable randn($RD, $T)
    g["randn!",   "ImplicitRNG",  tstr] = @benchmarkable randn!($dst)
    g["randn!",   "RandomDevice", tstr] = @benchmarkable randn!($RD, $dst)
    g["randexp",  "ImplicitRNG",  tstr] = @benchmarkable randexp($T)
    g["randexp",  "RandomDevice", tstr] = @benchmarkable randexp($RD, $T)
    g["randexp!", "ImplicitRNG",  tstr] = @benchmarkable randexp!($dst)
    g["randexp!", "RandomDevice", tstr] = @benchmarkable randexp!($RD, $dst)
end

for T in NUMS
    T === BigInt && continue
    tstr = string(T)
    dst = Vector{T}(1000)
    g["rand",     "MersenneTwister", tstr] = @benchmarkable rand($MT, $T)
    g["rand!",    "MersenneTwister", tstr] = @benchmarkable rand!($MT, $dst)
    VERSION >= v"0.5.0-pre+5657" || continue
    T <: AbstractFloat || T in CFLOATS && VERSION >= v"0.7.0-DEV.973" || continue
    g["randn",    "MersenneTwister", tstr] = @benchmarkable randn($MT, $T)
    g["randn!",   "MersenneTwister", tstr] = @benchmarkable randn!($MT, $dst)
    T <: AbstractFloat || continue
    g["randexp",  "MersenneTwister", tstr] = @benchmarkable randexp($MT, $T)
    g["randexp!", "MersenneTwister", tstr] = @benchmarkable randexp!($MT, $dst)
end

set_tolerance!(g)

###############
# Collections #
###############

g = addgroup!(SUITE, "collections", ["rand", "rand!"])

collections = Pair[[1:3;]   => "small Vector",
                   [1:900;] => "large Vector",
                   'a':'z'  => "'a':'z'"]

if VERSION >= v"0.7.0-DEV.973"
    push!(collections,
          Dict(1=>2, 3=>4, 5=>6)  => "small Dict",
          Dict(zip(1:900, 1:900)) => "large Dict",
          Set(1:3)                => "small Set",
          Set(1:900)              => "large Set",
          IntSet(1:3)             => "small IntSet",
          IntSet(1:900)           => "large IntSet",
          "qwèrtï"                => "small String",
          randstring(900)         => "large String")
end

for (collection, collstr) in collections
    dst = Vector{eltype(collection)}(1000)
    g["rand",  "ImplicitRNG",     collstr] = @benchmarkable rand($collection)
    g["rand",  "MersenneTwister", collstr] = @benchmarkable rand($MT, $collection)
    g["rand",  "RandomDevice",    collstr] = @benchmarkable rand($RD, $collection)
    g["rand!", "ImplicitRNG",     collstr] = @benchmarkable rand!($dst, $collection)
    g["rand!", "MersenneTwister", collstr] = @benchmarkable rand!($MT, $dst, $collection)
    g["rand!", "RandomDevice",    collstr] = @benchmarkable rand!($RD, $dst, $collection)
end

set_tolerance!(g)

##############
# randstring #
##############

g = addgroup!(SUITE, "randstring")

qwerty, qwertystr = collect(UInt8, "qwerty"), "collect(UInt8, \"qwerty\""
g["randstring", "MersenneTwister"]                        = @benchmarkable randstring($MT)
g["randstring", "MersenneTwister", 100]                   = @benchmarkable randstring($MT, 100)
if VERSION >= v"0.7.0-DEV.973"
    g["randstring", "MersenneTwister", "\"qwèrtï\""]      = @benchmarkable randstring($MT, "qwèrtï")
    g["randstring", "MersenneTwister", "\"qwèrtï\"", 100] = @benchmarkable randstring($MT, "qwèrtï", 100)
    g["randstring", "MersenneTwister", qwertystr]         = @benchmarkable randstring($MT, $qwerty)
    g["randstring", "MersenneTwister", qwertystr, 100]    = @benchmarkable randstring($MT, $qwerty, 100)
end

set_tolerance!(g)

#############
# sequences #
#############

g = addgroup!(SUITE, "sequences", ["randsubseq!", "shuffle!", "randperm", "randcycle"])

# for randsubseq!, vectint is a big enough vector as output arg to avoid re-allocations
src = [1:1000;]
g["randsubseq!", "MersenneTwister", "0.2"]  = @benchmarkable randsubseq!($MT, $vectint, $src, 0.2)
g["randsubseq!", "MersenneTwister", "0.8"]  = @benchmarkable randsubseq!($MT, $vectint, $src, 0.8)
g["shuffle!",    "MersenneTwister"]         = @benchmarkable shuffle!($MT, $src)
g["randperm",    "MersenneTwister", "5"]    = @benchmarkable randperm($MT, 5)
g["randperm",    "MersenneTwister", "1000"] = @benchmarkable randperm($MT, 1000)
g["randcycle",   "MersenneTwister", "5"]    = @benchmarkable randcycle($MT, 5)
g["randcycle",   "MersenneTwister", "1000"] = @benchmarkable randcycle($MT, 1000)

set_tolerance!(g)

end # module
