module RandUtils

using Random
using StableRNGs
using SparseArrays

samerand(args...) = rand(StableRNG(1), args...)
samesprand(args...) = sprand(StableRNG(1), args...)

samesprandbool(args...) = sprand(StableRNG(1), Bool, args...)

samerandstring(n) = randstring(StableRNG(1), n)

randvec(T, n) = samerand(T, n)
randvec(n) = samerand(n)

randmat(T, n) = samerand(T, n, n)
randmat(n) = samerand(n, n)

export samerand, samesprand, samesprandbool, samerandstring, randvec, randmat, StableRNGs

end
