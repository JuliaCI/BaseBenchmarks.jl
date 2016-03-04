module RandUtils

const SEED = MersenneTwister(1)
const DEFAULT_ELTYPE = typeof(rand())

# ensures the generated array is always aligned to the page size
function alignedalloc{N}(S, dims::NTuple{N,Int})
    randarr = rand(deepcopy(SEED), S, dims...)
    alignedarr = Mmap.mmap(Array{eltype(S),N}, dims)
    copy!(alignedarr, randarr)
    @assert Int(pointer(alignedarr)) % 64 == 0 # sanity check
    return alignedarr
end

samerand() = rand(deepcopy(SEED))
samerand(S) = rand(deepcopy(SEED), S)
samerand(dims::Int...) = alignedalloc(DEFAULT_ELTYPE, dims)
samerand(S, dims::Int...) = alignedalloc(S, dims)

randvec(T, n) = samerand(T, n)
randvec(n) = samerand(n)

randmat(T, n) = samerand(T, n, n)
randmat(n) = samerand(n, n)

export samerand, randvec, randmat

end
