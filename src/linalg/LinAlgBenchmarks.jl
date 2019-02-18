module LinAlgBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat
using Compat.Iterators

if VERSION >= v"0.7.0-DEV.3449"
    using LinearAlgebra
    using LinearAlgebra: UnitUpperTriangular
else
    using Base.LinAlg
    using Base.LinAlg: UnitUpperTriangular
    const LinearAlgebra = Base.LinAlg
end

const SUITE = BenchmarkGroup(["array"])

const SIZES = (2^8, 2^10)
const MATS = (Matrix, Diagonal, Bidiagonal, Tridiagonal, SymTridiagonal, UpperTriangular, LowerTriangular)
const DIVMATS = Iterators.filter(x -> !(in(x, (Bidiagonal, Tridiagonal, SymTridiagonal))), MATS)

typename(::Type{T}) where {T} = string(isa(T,DataType) ? T.name : Base.unwrap_unionall(T).name)
typename(::Type{M}) where {M<:Matrix} = "Matrix"
typename(::Type{V}) where {V<:Vector} = "Vector"

const UPLO = VERSION >= v"0.7.0-DEV.884" ? :U : true

linalgmat(::Type{Matrix}, s) = randmat(s)
linalgmat(::Type{Diagonal}, s) = Diagonal(randvec(s))
linalgmat(::Type{Bidiagonal}, s) = Bidiagonal(randvec(s), randvec(s-1), UPLO)
linalgmat(::Type{Tridiagonal}, s) = Tridiagonal(randvec(s-1), randvec(s), randvec(s-1))
linalgmat(::Type{SymTridiagonal}, s) = SymTridiagonal(randvec(s), randvec(s-1))
linalgmat(::Type{UpperTriangular}, s) = UpperTriangular(randmat(s))
linalgmat(::Type{LowerTriangular}, s) = LowerTriangular(randmat(s))
linalgmat(::Type{UnitUpperTriangular}, s) = UnitUpperTriangular(randmat(s))

function linalgmat(::Type{Hermitian}, s)
    A = randmat(s)
    A = A + im*A
    return Hermitian(A + A')
end

# Non-positive-definite upper-triangular matrix
mutable struct NPDUpperTriangular
end
function linalgmat(::Type{NPDUpperTriangular}, s)
    A = linalgmat(UpperTriangular, s)
    rr = samerand(s)
    for i in 1:s
        A[i,i] = (2*rr[i]-1)*A[i,i]
    end
    return A
end
typename(::Type{NPDUpperTriangular}) = "NPDUpperTriangular"

# Hermitian Sparse Matrix With Nonzero Pivots
mutable struct HermitianSparseWithNonZeroPivots
end
function linalgmat(::Type{HermitianSparseWithNonZeroPivots}, s)
    A = samesprand(s, s, 1/s)
    A = A + A' + I
    A
end
typename(::Type{HermitianSparseWithNonZeroPivots}) = "HermitianSparseWithNonZeroPivots"


############################
# matrix/vector arithmetic #
############################

g = addgroup!(SUITE, "arithmetic")

for s in SIZES
    v = randvec(s)
    vstr = typename(Vector)
    g["-", vstr, vstr, s] = @benchmarkable -($v, $v)
    g["+", vstr, vstr, s] = @benchmarkable +($v, $v)
    for M in MATS
        mstr = typename(M)
        m = linalgmat(M, s)
        g["*", mstr, vstr, s]  = @benchmarkable *($m, $v)
        g["\\", mstr, vstr, s] = @benchmarkable \($m, $v)
        g["+", mstr, mstr, s]  = @benchmarkable +($m, $m)
        g["-", mstr, mstr, s]  = @benchmarkable -($m, $m)
        g["*", mstr, mstr, s]  = @benchmarkable *($m, $m)
    end
    for M in DIVMATS
        mstr = typename(M)
        m = linalgmat(M, s)
        g["/", mstr, mstr, s]  = @benchmarkable /($m, $m)
        g["\\", mstr, mstr, s] = @benchmarkable \($m, $m)
    end
    # Issue #14722
    C = zeros(Float32, s, s)
    A = randmat(s)
    B = randmat(s)
    if VERSION >= v"0.7.0-DEV.3204"
        g["mul!", "Matrix{Float32}", "Matrix{Float64}", "Matrix{Float64}", s] = @benchmarkable LinearAlgebra.mul!($C, $A, $B)
    else
        g["mul!", "Matrix{Float32}", "Matrix{Float64}", "Matrix{Float64}", s] = @benchmarkable A_mul_B!($C, $A, $B)
    end

    for T in [Int32, Int64, Float32, Float64]
        arr = samerand(T, s)
        g["cumsum!", T, s] = @benchmarkable cumsum!($arr, $(arr.÷length(arr)))
    end

    for M in (UpperTriangular, UnitUpperTriangular, NPDUpperTriangular, Hermitian)
        mstr = typename(M)
        m = linalgmat(M, s)
        if VERSION >= v"0.7.0-DEV.1599"
            g["sqrt", mstr, s] = @benchmarkable sqrt($m)
        else
            g["sqrt", mstr, s] = @benchmarkable sqrtm($m)
        end
        if M == Hermitian
            if VERSION >= v"0.7.0-DEV.1597"
                g["log", mstr, s] = @benchmarkable log($m)
            else
                g["log", mstr, s] = @benchmarkable logm($m)
            end
            if VERSION >= v"0.7.0-DEV.1486"
                g["exp", mstr, s] = @benchmarkable exp($m)
            else
                g["exp", mstr, s] = @benchmarkable expm($m)
            end
        end
    end

    # PR 21165
    for M in (HermitianSparseWithNonZeroPivots,)
        mstr = typename(M)
        m = linalgmat(M, s)
        g["\\", mstr, vstr, s] = @benchmarkable \($m, $v)
    end

end

# Julia PR 31100
begin
    mf4 = randmat(4)
    mc4 = randmat(Complex{Float64}, 4)

    if VERSION >= v"0.7.0-DEV.1599"
        g["sqrt", "LinearAlgebra.UpperTriangular{Float64} (#31100)", 4] = @benchmarkable sqrt($mf4)
        g["sqrt", "LinearAlgebra.UpperTriangular{ComplexF64} (#31100)", 4] = @benchmarkable sqrt($mc4)
    else
        g["sqrt", "LinearAlgebra.UpperTriangular{Float64} (#31100)", 4] = @benchmarkable sqrtm($mf4)
        g["sqrt", "LinearAlgebra.UpperTriangular{ComplexF64} (#31100)", 4] = @benchmarkable sqrtm($mc4)
    end
end

for b in values(g)
    b.params.time_tolerance = 0.45
    b.params.samples = 100
    b.params.seconds = 20
end

##################
# factorizations #
##################

g = addgroup!(SUITE, "factorization", ["eig", "svd", "lu", "qr", "schur", "chol"])

for M in (Matrix, Diagonal, Bidiagonal, SymTridiagonal, UpperTriangular, LowerTriangular)
    mstr = typename(M)
    for s in SIZES
        m = linalgmat(M, s)
        if VERSION < v"0.7.0-DEV.5211"
            g["eigen", mstr, s] = @benchmarkable eigfact($m)
        else
            g["eigen", mstr, s] = @benchmarkable eigen($m)
        end
    end
end

for M in (Matrix, Diagonal, Bidiagonal, UpperTriangular, LowerTriangular)
    mstr = typename(M)
    for s in SIZES
        m = linalgmat(M, s)
        if VERSION < v"0.7.0-DEV.5211"
            g["svd", mstr, s] = @benchmarkable svdfact($m)
        else
            g["svd", mstr, s] = @benchmarkable svd($m)
        end
    end
end

for M in (Matrix, Tridiagonal)
    mstr = typename(M)
    for s in SIZES
        m = linalgmat(M, s)
        if VERSION < v"0.7.0-DEV.5211"
            g["lu", mstr, s] = @benchmarkable lufact($m)
        else
            g["lu", mstr, s] = @benchmarkable lu($m)
        end
    end
end

for s in SIZES
    mstr = typename(Matrix)
    m = randmat(s)
    arr = m' * m
    if VERSION < v"0.7.0-DEV.5211"
        g["cholesky", mstr, s] = @benchmarkable cholfact($arr)
        g["schur",    mstr, s] = @benchmarkable schurfact($m)
        g["qr",       mstr, s] = @benchmarkable qrfact($m)
    else
        g["cholesky", mstr, s] = @benchmarkable cholesky($arr)
        g["schur",    mstr, s] = @benchmarkable schur($m)
        g["qr",       mstr, s] = @benchmarkable qr($m)
    end
end

for b in values(g)
    b.params.time_tolerance = 0.45
end

########
# BLAS #
########

g = addgroup!(SUITE, "blas")

s = 1024
C = Complex{Float64}
n = samerand()
cn = samerand(C)
v = randvec(s)
cv = randvec(C, s)
m = randmat(s)
cm = randmat(C, s)

g["dot"]       = @benchmarkable BLAS.dot($s, $v, 1, $v, 1)
g["dotu"]      = @benchmarkable BLAS.dotu($s, $cv, 1, $cv, 1)
g["dotc"]      = @benchmarkable BLAS.dotc($s, $cv, 1, $cv, 1)
g["blascopy!"] = @benchmarkable BLAS.blascopy!($s, $v, 1, $v, 1)
g["nrm2"]      = @benchmarkable BLAS.nrm2($s, $v, 1)
g["asum"]      = @benchmarkable BLAS.asum($s, $v, 1)
g["axpy!"]     = @benchmarkable BLAS.axpy!($n, $v, fill!($v, $n))
g["scal!"]     = @benchmarkable BLAS.scal!($s, $n, fill!($v, $n), 1)
g["scal"]      = @benchmarkable BLAS.scal($s, $n, $v, 1)
g["ger!"]      = @benchmarkable BLAS.ger!($n, $v, $v, fill!($m, $n))
g["syr!"]      = @benchmarkable BLAS.syr!('U', 1.0, $v, fill!($m, $n))
g["syrk!"]     = @benchmarkable BLAS.syrk!('U', 'N', $n, $m, $n, fill!($m, $n))
g["syrk"]      = @benchmarkable BLAS.syrk('U', 'N', $n, $m)
g["her!"]      = @benchmarkable BLAS.her!('U', $n, $cv, fill!($cm, $cn))
g["herk!"]     = @benchmarkable BLAS.herk!('U', 'N', $n, $cm, $n, fill!($cm, $cn))
g["herk"]      = @benchmarkable BLAS.herk('U', 'N', $n, $cm)
g["gbmv!"]     = @benchmarkable BLAS.gbmv!('N', $s, 500, 500, $n, $m, $v, $n, fill!($v, $n))
g["gbmv"]      = @benchmarkable BLAS.gbmv('N', $s, 500, 500, $n, $m, $v)
g["sbmv!"]     = @benchmarkable BLAS.sbmv!('U', $s-1, $n, $m, $v, $n, fill!($v, $n))
g["sbmv"]      = @benchmarkable BLAS.sbmv('U', $s-1, $n, $m, $v)
g["gemm!"]     = @benchmarkable BLAS.gemm!('N', 'N', $n, $m, $m, $n, fill!($m, $n))
g["gemm"]      = @benchmarkable BLAS.gemm('N', 'N', $n, $m, $m)
g["gemv!"]     = @benchmarkable BLAS.gemv!('N', $n, $m, $v, $n, fill!($v, $n))
g["gemv"]      = @benchmarkable BLAS.gemv('N', $n, $m, $v)
g["symm!"]     = @benchmarkable BLAS.symm!('L', 'U', $n, $m, $m, $n, fill!($m, $n))
g["symm"]      = @benchmarkable BLAS.symm('L', 'U', $n, $m, $m)
g["symv!"]     = @benchmarkable BLAS.symv!('U', $n, $m, $v, $n, fill!($v, $n))
g["symv"]      = @benchmarkable BLAS.symv('U', $n, $m, $v)
g["trmm!"]     = @benchmarkable BLAS.trmm!('L', 'U', 'N', 'N', $n, $m, fill!($m, $n))
g["trmm"]      = @benchmarkable BLAS.trmm('L', 'U', 'N', 'N', $n, $m, $m)
g["trsm!"]     = @benchmarkable BLAS.trsm!('L', 'U', 'N', 'N', $n, $m, fill!($m, $n))
g["trsm"]      = @benchmarkable BLAS.trsm('L', 'U', 'N', 'N', $n, $m, $m)
g["trmv!"]     = @benchmarkable BLAS.trmv!('L', 'N', 'U', $m, fill!($v, $n))
g["trmv"]      = @benchmarkable BLAS.trmv('L', 'N', 'U', $m, $v)
g["trsv!"]     = @benchmarkable BLAS.trsv!('U', 'N', 'N', $m, fill!($v, $n))
g["trsv"]      = @benchmarkable BLAS.trsv('U', 'N', 'N', $m, $v)

for b in values(g)
    b.params.time_tolerance = 0.40
end

#############
# small exp #
#############

SUITE["small exp #29116"] = @benchmarkable exp([1. 0; 2 0])


end # module
