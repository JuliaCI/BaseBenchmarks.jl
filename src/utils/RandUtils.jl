module RandUtils

const SEED = MersenneTwister(1)

samerand(args...) = rand(deepcopy(SEED), args...)

randvec(T, n) = samerand(T, n)
randvec(n) = samerand(n)

randmat(T, n) = samerand(T, n, n)
randmat(n) = samerand(n, n)

export samerand, randvec, randmat

end
