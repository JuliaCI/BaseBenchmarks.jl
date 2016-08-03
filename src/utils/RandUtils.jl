module RandUtils

using Compat

import Compat: UTF8String, view

const SEED = MersenneTwister(1)
const DEFAULT_ELTYPE = typeof(rand())

samerand(args...) = rand(deepcopy(SEED), args...)
samesprand(args...) = sprand(deepcopy(SEED), args...)

if VERSION >= v"0.5.0-dev+3807"
    samesprandbool(args...) = sprand(deepcopy(SEED), Bool, args...)
else
    samesprandbool(args...) = sprandbool(deepcopy(SEED), args...)
end

randvec(T, n) = samerand(T, n)
randvec(n) = samerand(n)

randmat(T, n) = samerand(T, n, n)
randmat(n) = samerand(n, n)

export samerand, samesprand, samesprandbool, randvec, randmat

end
