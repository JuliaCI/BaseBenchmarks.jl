module SparseBenchmarks

using ..BaseBenchmarks
using ..BenchmarkTools
using ..RandUtils

samesprand(args...) = sprand(MersenneTwister(1), args...)
samesprandbool(args...) = sprandbool(MersenneTwister(1), args...)

############
# indexing #
############

# Note that some of the "sparse logical" tests are commented
# out because they requires resolution of JuliaLang/julia#14717.

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

g = addgroup!(ENSEMBLE, "sparse vector indexing", ["sparse", "indexing", "array",
                                                   "getindex", "vector"])

for (s, v, l) in zip(sizes, spvecs, splogvecs)
    g["array", s, nnz(v)] = @benchmarkable getindex($v, $(samerand(1:s, s)))
    g["integer", s, nnz(v)] = @benchmarkable getindex($v, $(samerand(1:s)))
    g["range", s, nnz(v)] = @benchmarkable getindex($v, $(1:s))
    g["dense logical", s, nnz(v)] = @benchmarkable getindex($v, $(samerand(Bool, s)))
    # g["sparse logical", s, nnz(v), nnz(l)] = @benchmarkable getindex($v, $l)
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

g = addgroup!(ENSEMBLE, "sparse matrix row indexing", ["sparse", "indexing", "array",
                                                       "getindex", "matrix", "row"])

for (s, m, v, l, sl, c) in zip(sizes, matrices, vectors, logvecs, splogvecs, inds)
    g["array", s, nnz(m), c] = @benchmarkable getindex($m, $v, $c)
    g["range", s, nnz(m), c] = @benchmarkable getindex($m, $(1:s), $c)
    g["dense logical", s, nnz(m), c] = @benchmarkable getindex($m, $l, $c)
    # g["sparse logical", s, nnz(m), nnz(sl), c] = @benchmarkable getindex($m, $sl, $c)
end

g = addgroup!(ENSEMBLE, "sparse matrix column indexing", ["sparse", "indexing", "array",
                                                          "getindex", "matrix", "column"])

for (s, m, v, l, sl, r) in zip(sizes, matrices, vectors, logvecs, splogvecs, inds)
    g["array", s, nnz(m), r] = @benchmarkable getindex($m, $r, $v)
    g["range", s, nnz(m), r] = @benchmarkable getindex($m, $r, $(1:s))
    g["dense logical", s, nnz(m), r] = @benchmarkable getindex($m, $r, $l)
    # g["sparse logical", s, nnz(m), nnz(sl), r] = @benchmarkable getindex($m, $r, $sl)
end

g = addgroup!(ENSEMBLE, "sparse matrix row + column indexing", ["sparse", "indexing", "array",
                                                                "getindex", "matrix", "row",
                                                                "column"])

for (s, m, v, l, sl, i) in zip(sizes, matrices, vectors, logvecs, splogmats, inds)
    g["array", s, nnz(m)] = @benchmarkable getindex($m, $v, $v)
    g["integer", s, nnz(m), i] = @benchmarkable getindex($m, $i, $i)
    g["range", s, nnz(m)] = @benchmarkable getindex($m, $(1:s), $(1:s))
    g["dense logical", s, nnz(m)] = @benchmarkable getindex($m, $l, $l)
    g["sparse logical", s, nnz(m), nnz(sl)] = @benchmarkable getindex($m, $sl)
end

######################
# transpose (#14631) #
######################

small_sqr = samesprand(600, 600, 0.01)
small_rct = samesprand(600, 400, 0.01)
large_sqr = samesprand(20000, 20000, 0.01)
large_rct = samesprand(20000, 10000, 0.01)

g = addgroup!(ENSEMBLE, "sparse matrix transpose", ["sparse", "array", "ctranspose", "transpose", "matrix"])

for m in (small_sqr, small_rct, large_sqr, large_rct)
    cm = m + m*im
    s = size(m)
    g["transpose", s] = @benchmarkable transpose($m)
    g["transpose!", s] = @benchmarkable transpose!($(m.'), $m)
    g["ctranspose", s] = @benchmarkable ctranspose($cm)
    g["ctranspose!", s] = @benchmarkable ctranspose!($(cm.'), $cm)
end

end # module
