module SparseBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

import Compat: UTF8String, view

const SUITE = BenchmarkGroup(["array"])

#########
# index #
#########

# Note that some of the "logical" tests are commented
# out because they require resolution of JuliaLang/julia#14717.

g = addgroup!(SUITE, "index")

# vector #
#--------#

sizes = (10^3, 10^4, 10^5)

if VERSION < v"0.5.0-dev+763"
    spvecs = map(s -> samesprand(s, 1, inv(sqrt(s))), sizes)
    splogvecs = map(s -> samesprandbool(s, 1, 1e-5), sizes)
else
    spvecs = map(s -> samesprand(s, inv(sqrt(s))), sizes)
    splogvecs = map(s -> samesprandbool(s, 1e-5), sizes)
end

for (s, v, l) in zip(sizes, spvecs, splogvecs)
    g["spvec", "array",   s] = @benchmarkable getindex($v, $(samerand(1:s, s)))
    g["spvec", "integer", s] = @benchmarkable getindex($v, $(samerand(1:s)))
    g["spvec", "range",   s] = @benchmarkable getindex($v, $(1:s))
    g["spvec", "logical", s] = @benchmarkable getindex($v, $(samerand(Bool, s)))
    # g["spvec", "splogical", s, nnz(v), nnz(l)] = @benchmarkable getindex($v, $l)
end

# matrix #
#--------#

sizes = (10, 10^2, 10^3)
inds = map(s -> samerand(1:s), sizes)
matrices = map(s -> samesprand(s, s, inv(sqrt(s))), sizes)
vectors = map(s -> samerand(1:s, s), sizes)
logvecs = map(s -> samerand(Bool, s), sizes)
splogmats = map(s -> samesprandbool(s, s, 1e-5), sizes)

if VERSION < v"0.5.0-dev+763"
    splogvecs = map(s -> samesprandbool(s, 1, 1e-5), sizes)
else
    splogvecs = map(s -> samesprandbool(s, 1, 1e-5), sizes)
end

for (s, m, v, l, sl, c) in zip(sizes, matrices, vectors, logvecs, splogvecs, inds)
    g["spmat", "col", "array", s] = @benchmarkable getindex($m, $v, $c)
    g["spmat", "col", "range", s] = @benchmarkable getindex($m, $(1:s), $c)
    g["spmat", "col", "logical", s] = @benchmarkable getindex($m, $l, $c)
    # g["spmat", "col", "splogical", s] = @benchmarkable getindex($m, $sl, $c)
end

for (s, m, v, l, sl, r) in zip(sizes, matrices, vectors, logvecs, splogvecs, inds)
    g["spmat", "row", "array", s] = @benchmarkable getindex($m, $r, $v)
    g["spmat", "row", "range", s] = @benchmarkable getindex($m, $r, $(1:s))
    g["spmat", "row", "logical", s] = @benchmarkable getindex($m, $r, $l)
    # g["spmat", "row", "splogical", s] = @benchmarkable getindex($m, $r, $sl)
end

for (s, m, v, l, sl, i) in zip(sizes, matrices, vectors, logvecs, splogmats, inds)
    g["spmat", "array", s] = @benchmarkable getindex($m, $v, $v)
    g["spmat", "integer", s] = @benchmarkable getindex($m, $i, $i)
    g["spmat", "range", s] = @benchmarkable getindex($m, $(1:s), $(1:s))
    g["spmat", "logical", s] = @benchmarkable getindex($m, $l, $l)
    g["spmat", "splogical", s] = @benchmarkable getindex($m, $sl)
end

for b in values(g)
    b.params.time_tolerance = 0.3
end

######################
# transpose (#14631) #
######################

small_sqr = samesprand(600, 600, 0.01)
small_rct = samesprand(600, 400, 0.01)
large_sqr = samesprand(20000, 20000, 0.01)
large_rct = samesprand(20000, 10000, 0.01)

g = addgroup!(SUITE, "transpose", ["ctranspose"])

for m in (small_sqr, small_rct, large_sqr, large_rct)
    cm = m + m*im
    s = size(m)
    g["transpose", s] = @benchmarkable transpose($m)
    g["transpose!", s] = @benchmarkable transpose!($(m.'), $m)
    g["ctranspose", s] = @benchmarkable ctranspose($cm)
    g["ctranspose!", s] = @benchmarkable ctranspose!($(cm.'), $cm)
end

for b in values(g)
    b.params.time_tolerance = 0.3
end

##############
# arithmetic #
##############

g = addgroup!(SUITE, "arithmetic")

# unary minus, julialang repo issue #19503 / fix #19530
g["unary minus", size(small_sqr)] = @benchmarkable -$small_sqr
g["unary minus", size(large_sqr)] = @benchmarkable -$large_sqr

for b in values(g)
    b.params.time_tolerance = 0.3
end

#############
# Backsolve #
#############

g = addgroup!(SUITE, "backsolve")

A = sprand(10^4, 10^4, 1e-4)
A = A + A' + speye(10^4)
@assert ishermitian(A)
b = rand(10^4)

g["hermitiansolve"] = @benchmarkable A \ b

end # module
