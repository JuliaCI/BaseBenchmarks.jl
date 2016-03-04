module RandUtils

const SEED = MersenneTwister(1)
const ALIGN = 64

# ensures the generated array always has the same alignment (at least ALIGN-byte aligned)
function samerand(args...)
    v = rand(deepcopy(SEED), args...)
    if Int(pointer(v)) % ALIGN == 0
       return v
    else
       return samerand(args...)
    end
end

randvec(T, n) = samerand(T, n)
randvec(n) = samerand(n)

randmat(T, n) = samerand(T, n, n)
randmat(n) = samerand(n, n)

export samerand, randvec, randmat

end
