module RandUtils

samerand(args...) = rand(MersenneTwister(1), args...)

randvec(T, n) = samerand(T, n)
randvec(n) = samerand(n)

randmat(T, n) = samerand(T, n, n)
randmat(n) = samerand(n, n)

export samerand, randvec, randmat

end
