##########################
# functions to benchmark #
##########################

function perf_sumelt(A)
    s = zero(eltype(A))
    for a in A
        s += a
    end
    return s
end

# bounds-checking is deliberately on,
# doesn't use `for a in r`
function perf_sumelt_boundscheck(A)
    s = zero(eltype(A))
    for i = 1:length(A)
        s += A[i]
    end
    return s
end

function perf_sumeach(A)
    s = zero(eltype(A))
    for I in eachindex(A)
        val = Base.unsafe_getindex(A, I)
        s += val
    end
    return s
end

function perf_sumlinear(A)
    s = zero(eltype(A))
    for I in 1:length(A)
        val = Base.unsafe_getindex(A, I)
        s += val
    end
    return s
end
function perf_sumcartesian(A)
    s = zero(eltype(A))
    for I in CartesianIndices(size(A))
        val = Base.unsafe_getindex(A, I)
        s += val
    end
    return s
end

function perf_sumcolon(A)
    s = zero(eltype(A))
    nrows = size(A, 1)
    ncols = size(A, 2)
    c = Colon()
    @simd for i = 1:ncols
        val = Base.unsafe_getindex(A, c, i)
        s += first(val)
    end
    return s
end

function perf_sumrange(A)
    s = zero(eltype(A))
    nrows = size(A, 1)
    ncols = size(A, 2)
    r = 1:nrows
    @simd for i = 1:ncols
        val = Base.unsafe_getindex(A, r, i)
        s += first(val)
    end
    return s
end

function perf_sumlogical(A)
    s = zero(eltype(A))
    nrows = size(A, 1)
    ncols = size(A, 2)
    r = falses(nrows)
    r[1:4:end] .= true
    @simd for i = 1:ncols
        val = Base.unsafe_getindex(A, r, i)
        s += first(val)
    end
    return s
end

function perf_sumvector(A)
    s = zero(eltype(A))
    nrows = size(A, 1)
    ncols = size(A, 2)
    r = rand(1:nrows, 5)
    @simd for i = 1:ncols
        val = Base.unsafe_getindex(A, r, i)
        s += first(val)
    end
    return s
end

## Views
function perf_sumeach_view(A)
    s = zero(eltype(A))
    @inbounds @simd for I in eachindex(A)
        val = view(A, I)
        s += val[]
    end
    return s
end

function perf_sumlinear_view(A)
    s = zero(eltype(A))
    @inbounds @simd for I in 1:length(A)
        val = view(A, I)
        s += val[]
    end
    return s
end
function perf_sumcartesian_view(A)
    s = zero(eltype(A))
    @inbounds @simd for I in CartesianIndices(size(A))
        val = view(A, I)
        s += val[]
    end
    return s
end

function perf_sumcolon_view(A)
    s = zero(eltype(A))
    nrows = size(A, 1)
    ncols = size(A, 2)
    c = Colon()
    @inbounds for i = 1:ncols
        val = view(A, c, i)
        s += first(val)
    end
    return s
end

function perf_sumrange_view(A)
    s = zero(eltype(A))
    nrows = size(A, 1)
    ncols = size(A, 2)
    r = 1:nrows
    @inbounds for i = 1:ncols
        val = view(A, r, i)
        s += first(val)
    end
    return s
end

function perf_sumlogical_view(A)
    s = zero(eltype(A))
    nrows = size(A, 1)
    ncols = size(A, 2)
    r = falses(nrows)
    r[1:4:end] .= true
    @inbounds for i = 1:ncols
        val = view(A, r, i)
        s += first(val)
    end
    return s
end

function perf_sumvector_view(A)
    s = zero(eltype(A))
    nrows = size(A, 1)
    ncols = size(A, 2)
    r = rand(1:nrows, 5)
    @inbounds for i = 1:ncols
        val = view(A, r, i)
        s += first(val)
    end
    return s
end


function perf_sub2ind(sz, irange, jrange, krange)
    linear = LinearIndices(sz)
    s = 0
    for k in krange, j in jrange, i in irange
        ind = linear[i, j, k]
        s += ind
    end
    s
end

function perf_ind2sub(sz, lrange)
    cart = CartesianIndices(sz)
    si = sj = sk = 0
    for l in lrange
        i, j, k = cart[l].I  # TODO: change to Tuple(cart[l])
        si += i
        sj += j
        sk += k
    end
    si, sj, sk
end

function setup_mapr_access(A)
    z = zero(eltype(A))
    zz = sum(z -> z * z, [z]) # z = z*z, with any promotion from sum
    n = minimum(size(A))
    B = Vector{typeof(zz)}(undef, n)
    B, zz, n
end
function perf_mapr_access(A, B, zz, n) #20517
    @inbounds for j in 1:n
        B[j] = mapreduce(k -> A[j,k]*A[k,j], +, 1:j; init=zz)
    end
    B
end

##########################
# supporting definitions #
##########################

abstract type MyArray{T,N} <: AbstractArray{T,N} end

struct ArrayLS{T,N} <: MyArray{T,N}  # LinearSlow
    data::Array{T,N}
end

struct ArrayLSLS{T,N} <: MyArray{T,N}  # LinearSlow with LinearSlow similar
    data::Array{T,N}
end

struct ArrayLF{T,N} <: MyArray{T,N}  # LinearFast
    data::Array{T,N}
end

struct ArrayStrides{T,N} <: MyArray{T,N}
    data::Array{T,N}
    strides::NTuple{N,Int}
end

ArrayStrides(A::Array) = ArrayStrides(A, strides(A))

struct ArrayStrides1{T} <: MyArray{T,2}
    data::Matrix{T}
    stride1::Int
end

ArrayStrides1(A::Array) = ArrayStrides1(A, size(A,1))

Base.@propagate_inbounds Base.setindex!(A::ArrayLSLS, v, I::Int...) = A.data[I...] = v

Base.@propagate_inbounds Base.unsafe_setindex!(A::ArrayLSLS, v, I::Int...) = Base.unsafe_setindex!(A.data, v, I...)

Base.first(A::ArrayLSLS) = first(A.data)

Base.size(A::MyArray) = size(A.data)
# To ensure that ArrayLS and ArrayLSLS really are LinearSlow even
# after inlining, let's make the size differ from the parent array
# (ref https://github.com/JuliaLang/julia/pull/17355#issuecomment-231748251)
@inline Base.size(A::ArrayLS{T,1}) where {T}   = (sz = size(A.data); (sz[1]-1,))
@inline Base.size(A::ArrayLSLS{T,1}) where {T} = (sz = size(A.data); (sz[1]-1,))
@inline Base.size(A::ArrayLS{T,2}) where {T}   = (sz = size(A.data); (sz[1]-1,sz[2]-1))
@inline Base.size(A::ArrayLSLS{T,2}) where {T} = (sz = size(A.data); (sz[1]-1,sz[2]-1))
@inline Base.size(A::ArrayLS)   = map(n->n-1, size(A.data))
@inline Base.size(A::ArrayLSLS) = map(n->n-1, size(A.data))

@inline Base.similar(A::ArrayLSLS, ::Type{T}, dims::Tuple{Int}) where {T}     = ArrayLSLS(similar(A.data, T, (dims[1]+1,)))
@inline Base.similar(A::ArrayLSLS, ::Type{T}, dims::Tuple{Int,Int}) where {T} = ArrayLSLS(similar(A.data, T, (dims[1]+1,dims[2]+1)))
@inline Base.similar(A::ArrayLSLS, ::Type{T}, dims::Tuple{Vararg{Int}}) where {T} = ArrayLSLS(similar(A.data, T, map(n->n+1, dims)))

Base.@propagate_inbounds Base.getindex(A::ArrayLF, i::Int) = getindex(A.data, i)
Base.@propagate_inbounds Base.getindex(A::ArrayLS{T,2}, i::Int, j::Int) where {T} = getindex(A.data, i, j)
Base.@propagate_inbounds Base.getindex(A::ArrayLS{T,3}, i::Int, j::Int, k::Int) where {T} = getindex(A.data, i, j, k)
Base.@propagate_inbounds Base.getindex(A::ArrayLSLS{T,2}, i::Int, j::Int) where {T} = getindex(A.data, i, j)
Base.@propagate_inbounds Base.unsafe_getindex(A::ArrayLF, indx::Int) = Base.unsafe_getindex(A.data, indx)
Base.@propagate_inbounds Base.unsafe_getindex(A::ArrayLS{T,2}, i::Int, j::Int) where {T} = Base.unsafe_getindex(A.data, i, j)
Base.@propagate_inbounds Base.unsafe_getindex(A::ArrayLS{T,3}, i::Int, j::Int, k::Int) where {T} = Base.unsafe_getindex(A.data, i, j, k)
Base.@propagate_inbounds Base.unsafe_getindex(A::ArrayLSLS{T,2}, i::Int, j::Int) where {T} = Base.unsafe_getindex(A.data, i, j)

Base.@propagate_inbounds Base.getindex(A::ArrayStrides{T,2}, i::Real, j::Real) where {T} = getindex(A.data, 1+A.strides[1]*(i-1)+A.strides[2]*(j-1))
Base.@propagate_inbounds Base.getindex(A::ArrayStrides1, i::Real, j::Real) = getindex(A.data, i + A.stride1*(j-1))
Base.@propagate_inbounds Base.unsafe_getindex(A::ArrayStrides{T,2}, i::Real, j::Real) where {T} = Base.unsafe_getindex(A.data, 1+A.strides[1]*(i-1)+A.strides[2]*(j-1))
Base.@propagate_inbounds Base.unsafe_getindex(A::ArrayStrides1, i::Real, j::Real) = Base.unsafe_getindex(A.data, i + A.stride1*(j-1))

Base.IndexStyle(::Type{<:ArrayLF}) = IndexLinear()

if !applicable(Base.unsafe_getindex, [1 2], 1:1, 2)
    Base.@propagate_inbounds Base.unsafe_getindex(A::Array, I...) = @inbounds return A[I...]
    Base.@propagate_inbounds Base.unsafe_getindex(A::MyArray, I...) = @inbounds return A[I...]
    Base.@propagate_inbounds Base.unsafe_getindex(A::SubArray, I...) = @inbounds return A[I...]
    Base.@propagate_inbounds Base.unsafe_getindex(A::BitArray, I1::BitArray, I2::Int) = Base.unsafe_getindex(A, Base.to_index(I1), I2)
end

struct PairVals{T}
    a::T
    b::T
end
Base.zero(::Type{PairVals{T}}) where T = PairVals(zero(T), zero(T))
Base.:(+)(p1::PairVals, p2::PairVals) = PairVals(p1.a + p2.a, p1.b + p2.b)
Base.:(*)(p1::PairVals, p2::PairVals) = PairVals(p1.a * p2.a, p1.b * p2.b)

# return the ith array in our set of definition
function makearrays(::Type{T}, r::Integer, c::Integer, i::Int) where T
    A = samerand(T, r, c)
    ((i -= 1) == 0) && return A
    B = similar(A, r+1, c+1)
    B[1:r, 1:c] = A
    AS = ArrayLS(B)
    ((i -= 1) == 0) && return AS
    ((i -= 1) == 0) && return ArrayLSLS(B)
    ((i -= 1) == 0) && return ArrayLF(A)
    #Astrd = ArrayStrides(A)
    #Astrd1 = ArrayStrides1(A)
    B = samerand(T, r+1, c+2)
    # And views thereof
    ((i -= 1) == 0) && return view(B, 1:r, 2:c+1)
    ((i -= 1) == 0) && return view(A, :, :)
    ((i -= 1) == 0) && return view(AS, :, :)
    C = samerand(T, 4, r, c)
    ((i -= 1) == 0) && return view(C, 1, :, :)
    ((i -= 1) == 0) && return view(ArrayLS(C), 1, :, :)
    ((i -= 1) == 0) && return view(reshape(view(C, :, :, :), Val(2)), :, 2:c+1)
    ((i -= 1) == 0) && return view(reshape(view(ArrayLS(C), :, :, :), Val(2)), :, 2:c+1)
    # ReinterpretArrays
    @assert sizeof(T) < 8
    Tw = widen(T)
    Aw = samerand(Tw, r, c)
    ((i -= 1) == 0) && return Aw
    ((i -= 1) == 0) && return reinterpret(PairVals{T}, Aw)  # same size, with fields
    @assert iseven(r)
    ((i -= 1) == 0) && return reinterpret(PairVals{T}, A)  # twice the size, with fields
    if T === Int32
        ((i -= 1) == 0) && return reinterpret(Float32, A)
    end
    return -i
end
