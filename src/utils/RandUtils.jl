module RandUtils

const SEED = MersenneTwister(1)
const DEFAULT_ELTYPE = typeof(rand())

samerand(args...) = rand(deepcopy(SEED), args...)
samesprand(args...) = sprand(deepcopy(SEED), args...)
samesprandbool(args...) = sprandbool(deepcopy(SEED), args...)

randvec(T, n) = samerand(T, n)
randvec(n) = samerand(n)

randmat(T, n) = samerand(T, n, n)
randmat(n) = samerand(n, n)

export samerand, samesprand, samesprandbool, randvec, randmat

end
