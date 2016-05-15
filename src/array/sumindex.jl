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
    for I in CartesianRange(size(A))
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
    r[1:4:end] = true
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

function perf_sub2ind(sz, irange, jrange, krange)
    s = 0
    for k in krange, j in jrange, i in irange
        ind = sub2ind(sz, i, j, k)
        s += ind
    end
    s
end

function perf_ind2sub(sz, lrange)
    si = sj = sk = 0
    for l in lrange
        i, j, k = ind2sub(sz, l)
        si += i
        sj += j
        sk += k
    end
    si, sj, sk
end

##########################
# supporting definitions #
##########################

abstract MyArray{T,N} <: AbstractArray{T,N}

immutable ArrayLS{T,N} <: MyArray{T,N}  # LinearSlow
    data::Array{T,N}
end

immutable ArrayLSLS{T,N} <: MyArray{T,N}  # LinearSlow with LinearSlow similar
    data::Array{T,N}
end

immutable ArrayLF{T,N} <: MyArray{T,N}  # LinearFast
    data::Array{T,N}
end

immutable ArrayStrides{T,N} <: MyArray{T,N}
    data::Array{T,N}
    strides::NTuple{N,Int}
end

ArrayStrides(A::Array) = ArrayStrides(A, strides(A))

immutable ArrayStrides1{T} <: MyArray{T,2}
    data::Matrix{T}
    stride1::Int
end

ArrayStrides1(A::Array) = ArrayStrides1(A, size(A,1))

Base.similar{T}(A::ArrayLSLS, ::Type{T}, dims::Tuple{Vararg{Int}}) = ArrayLSLS(similar(A.data, T, dims))

@inline Base.setindex!(A::ArrayLSLS, v, I::Int...) = A.data[I...] = v

@inline Base.unsafe_setindex!(A::ArrayLSLS, v, I::Int...) = Base.unsafe_setindex!(A.data, v, I...)

Base.first(A::ArrayLSLS) = first(A.data)

Base.size(A::MyArray) = size(A.data)

@inline Base.getindex(A::ArrayLF, i::Int) = getindex(A.data, i)
@inline Base.getindex(A::ArrayLF, i::Int, i2::Int) = getindex(A.data, i, i2)
@inline Base.getindex(A::Union{ArrayLS, ArrayLSLS}, i::Int, j::Int) = getindex(A.data, i, j)
@inline Base.unsafe_getindex(A::ArrayLF, indx::Int) = Base.unsafe_getindex(A.data, indx)
@inline Base.unsafe_getindex(A::Union{ArrayLS, ArrayLSLS}, i::Int, j::Int) = Base.unsafe_getindex(A.data, i, j)

@inline Base.getindex{T}(A::ArrayStrides{T,2}, i::Real, j::Real) = getindex(A.data, 1+A.strides[1]*(i-1)+A.strides[2]*(j-1))
@inline Base.getindex(A::ArrayStrides1, i::Real, j::Real) = getindex(A.data, i + A.stride1*(j-1))
@inline Base.unsafe_getindex{T}(A::ArrayStrides{T,2}, i::Real, j::Real) = Base.unsafe_getindex(A.data, 1+A.strides[1]*(i-1)+A.strides[2]*(j-1))
@inline Base.unsafe_getindex(A::ArrayStrides1, i::Real, j::Real) = Base.unsafe_getindex(A.data, i + A.stride1*(j-1))

# Using the qualified Base.LinearFast() in the linearindexing definition
# requires looking up the symbol in the module on each call.
Base.linearindexing{T<:ArrayLF}(::Type{T}) = Base.LinearFast()

if !applicable(Base.unsafe_getindex, [1 2], 1:1, 2)
    @inline Base.unsafe_getindex(A::Array, I...) = @inbounds return A[I...]
    @inline Base.unsafe_getindex(A::MyArray, I...) = @inbounds return A[I...]
    @inline Base.unsafe_getindex(A::SubArray, I...) = @inbounds return A[I...]
    @inline Base.unsafe_getindex(A::BitArray, I1::BitArray, I2::Int) = Base.unsafe_getindex(A, Base.to_index(I1), I2)
end

function makearrays{T}(::Type{T}, r::Integer, c::Integer)
    A = samerand(T, r, c)
    AS = ArrayLS(A)
    ASS = ArrayLSLS(A)
    AF = ArrayLF(A)
    Astrd = ArrayStrides(A)
    Astrd1 = ArrayStrides1(A)
    B = samerand(T, r+1, c+2)
    Asub = sub(B, 1:r, 2:c+1)
    return (A, AF, AS, ASS, Asub)
end
