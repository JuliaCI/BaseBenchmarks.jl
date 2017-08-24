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
    @inbounds @simd for I in CartesianRange(size(A))
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
    r[1:4:end] = true
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

function setup_mapr_access(A)
    z = zero(eltype(A))
    zz = mapreduce(z -> z*z, +, [z]) # z = z*z, with any promotion from mapreduce
    n = minimum(size(A))
    B = Vector{typeof(zz)}(n)
    B, zz, n
end
function perf_mapr_access(A, B, zz, n) #20517
    @inbounds for j in 1:n
        B[j] = mapreduce(k -> A[j,k]*A[k,j], +, zz, 1:j)
    end
    B
end

##########################
# supporting definitions #
##########################

@compat abstract type MyArray{T,N} <: AbstractArray{T,N} end

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

Base.@propagate_inbounds Base.setindex!(A::ArrayLSLS, v, I::Int...) = A.data[I...] = v

Base.@propagate_inbounds Base.unsafe_setindex!(A::ArrayLSLS, v, I::Int...) = Base.unsafe_setindex!(A.data, v, I...)

Base.first(A::ArrayLSLS) = first(A.data)

Base.size(A::MyArray) = size(A.data)
# To ensure that ArrayLS and ArrayLSLS really are LinearSlow even
# after inlining, let's make the size differ from the parent array
# (ref https://github.com/JuliaLang/julia/pull/17355#issuecomment-231748251)
@inline Base.size{T}(A::ArrayLS{T,1})   = (sz = size(A.data); (sz[1]-1,))
@inline Base.size{T}(A::ArrayLSLS{T,1}) = (sz = size(A.data); (sz[1]-1,))
@inline Base.size{T}(A::ArrayLS{T,2})   = (sz = size(A.data); (sz[1]-1,sz[2]-1))
@inline Base.size{T}(A::ArrayLSLS{T,2}) = (sz = size(A.data); (sz[1]-1,sz[2]-1))
@inline Base.size(A::ArrayLS)   = map(n->n-1, size(A.data))
@inline Base.size(A::ArrayLSLS) = map(n->n-1, size(A.data))

@inline Base.similar{T}(A::ArrayLSLS, ::Type{T}, dims::Tuple{Int})     = ArrayLSLS(similar(A.data, T, (dims[1]+1,)))
@inline Base.similar{T}(A::ArrayLSLS, ::Type{T}, dims::Tuple{Int,Int}) = ArrayLSLS(similar(A.data, T, (dims[1]+1,dims[2]+1)))
@inline Base.similar{T}(A::ArrayLSLS, ::Type{T}, dims::Tuple{Vararg{Int}}) = ArrayLSLS(similar(A.data, T, map(n->n+1, dims)))

Base.@propagate_inbounds Base.getindex(A::ArrayLF, i::Int) = getindex(A.data, i)
Base.@propagate_inbounds Base.getindex{T}(A::ArrayLS{T,2}, i::Int, j::Int) = getindex(A.data, i, j)
Base.@propagate_inbounds Base.getindex{T}(A::ArrayLS{T,3}, i::Int, j::Int, k::Int) = getindex(A.data, i, j, k)
Base.@propagate_inbounds Base.getindex{T}(A::ArrayLSLS{T,2}, i::Int, j::Int) = getindex(A.data, i, j)
Base.@propagate_inbounds Base.unsafe_getindex(A::ArrayLF, indx::Int) = Base.unsafe_getindex(A.data, indx)
Base.@propagate_inbounds Base.unsafe_getindex{T}(A::ArrayLS{T,2}, i::Int, j::Int) = Base.unsafe_getindex(A.data, i, j)
Base.@propagate_inbounds Base.unsafe_getindex{T}(A::ArrayLS{T,3}, i::Int, j::Int, k::Int) = Base.unsafe_getindex(A.data, i, j, k)
Base.@propagate_inbounds Base.unsafe_getindex{T}(A::ArrayLSLS{T,2}, i::Int, j::Int) = Base.unsafe_getindex(A.data, i, j)

Base.@propagate_inbounds Base.getindex{T}(A::ArrayStrides{T,2}, i::Real, j::Real) = getindex(A.data, 1+A.strides[1]*(i-1)+A.strides[2]*(j-1))
Base.@propagate_inbounds Base.getindex(A::ArrayStrides1, i::Real, j::Real) = getindex(A.data, i + A.stride1*(j-1))
Base.@propagate_inbounds Base.unsafe_getindex{T}(A::ArrayStrides{T,2}, i::Real, j::Real) = Base.unsafe_getindex(A.data, 1+A.strides[1]*(i-1)+A.strides[2]*(j-1))
Base.@propagate_inbounds Base.unsafe_getindex(A::ArrayStrides1, i::Real, j::Real) = Base.unsafe_getindex(A.data, i + A.stride1*(j-1))

@compat Base.IndexStyle(::Type{<:ArrayLF}) = IndexLinear()

if !applicable(Base.unsafe_getindex, [1 2], 1:1, 2)
    Base.@propagate_inbounds Base.unsafe_getindex(A::Array, I...) = @inbounds return A[I...]
    Base.@propagate_inbounds Base.unsafe_getindex(A::MyArray, I...) = @inbounds return A[I...]
    Base.@propagate_inbounds Base.unsafe_getindex(A::SubArray, I...) = @inbounds return A[I...]
    Base.@propagate_inbounds Base.unsafe_getindex(A::BitArray, I1::BitArray, I2::Int) = Base.unsafe_getindex(A, Base.to_index(I1), I2)
end
# Add support for views with CartesianIndex in a comparable method to how indexing works
if v"0.5-" < VERSION < v"0.6-"
    @eval Base.@propagate_inbounds Base.view(A::AbstractArray, I::Union{AbstractArray,Colon,Real,CartesianIndex}...) =
        view(A, Base.IteratorsMD.flatten(I)...)
elseif v"0.4-" < VERSION < v"0.5-"
    @generated function Base.slice(A::AbstractArray, I::Union{AbstractVector,Colon,Int,CartesianIndex}...)
        :($(Expr(:meta, :inline)); slice(A, $(Base.cartindex_exprs(I, :I)...)))
    end
end

function makearrays{T}(::Type{T}, r::Integer, c::Integer)
    A = samerand(T, r, c)
    B = similar(A, r+1, c+1)
    B[1:r, 1:c] = A
    AS = ArrayLS(B)
    ASS = ArrayLSLS(B)
    AF = ArrayLF(A)
    Astrd = ArrayStrides(A)
    Astrd1 = ArrayStrides1(A)
    B = samerand(T, r+1, c+2)
    # And views thereof
    Asub = view(B, 1:r, 2:c+1)
    Asub2 = view(A, :, :)
    Asub3 = view(AS, :, :)
    C = samerand(T, 4, r, c)
    Asub4 = view(C, 1, :, :)
    Asub5 = view(ArrayLS(C), 1, :, :)
    Asub6 = view(reshape(view(C, :, :, :), Val(2)), :, 2:c+1)
    Asub7 = view(reshape(view(ArrayLS(C), :, :, :), Val(2)), :, 2:c+1)

    return (A, AF, AS, ASS, Asub, Asub2, Asub3, Asub4, Asub5, Asub6, Asub7)
end
