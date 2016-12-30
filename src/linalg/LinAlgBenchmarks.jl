module LinAlgBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

import Compat: UTF8String, view

const SUITE = BenchmarkGroup(["array"])

const SIZES = (2^8, 2^10)
const MATS = (Matrix, Diagonal, Bidiagonal, Tridiagonal, SymTridiagonal, UpperTriangular, LowerTriangular)
const DIVMATS = filter(x -> !(in(x, (Bidiagonal, Tridiagonal, SymTridiagonal))), MATS)

typename{T}(::Type{T}) = string(T.name)
typename{M<:Matrix}(::Type{M}) = "Matrix"
typename{V<:Vector}(::Type{V}) = "Vector"

linalgmat(::Type{Matrix}, s) = randmat(s)
linalgmat(::Type{Diagonal}, s) = Diagonal(randvec(s))
linalgmat(::Type{Bidiagonal}, s) = Bidiagonal(randvec(s), randvec(s-1), true)
linalgmat(::Type{Tridiagonal}, s) = Tridiagonal(randvec(s-1), randvec(s), randvec(s-1))
linalgmat(::Type{SymTridiagonal}, s) = SymTridiagonal(randvec(s), randvec(s-1))
linalgmat(::Type{UpperTriangular}, s) = UpperTriangular(randmat(s))
linalgmat(::Type{LowerTriangular}, s) = LowerTriangular(randmat(s))

function linalgmat(::Type{Hermitian}, s)
    A = randmat(s)
    A = A + im*A
    return Hermitian(A + A')
end

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
    g["A_mul_B!", "Matrix{Float32}", "Matrix{Float64}", "Matrix{Float64}", s] = @benchmarkable A_mul_B!($C, $A, $B)

    for T in [Int32, Int64, Float32, Float64]
        arr = samerand(T, s)
        g["cumsum!", T, s] = @benchmarkable cumsum!($arr, $arr)
    end

end

for b in values(g)
    b.params.time_tolerance = 0.45
end

##################
# factorizations #
##################

g = addgroup!(SUITE, "factorization", ["eig", "svd", "lu", "qr", "schur", "chol"])

for M in (Matrix, Diagonal, Bidiagonal, SymTridiagonal, UpperTriangular, LowerTriangular)
    mstr = typename(M)
    for s in SIZES
        m = linalgmat(M, s)
        g["eig", mstr, s]     = @benchmarkable eig($m)
        g["eigfact", mstr, s] = @benchmarkable eigfact($m)
    end
end

for M in (Matrix, Diagonal, Bidiagonal, UpperTriangular, LowerTriangular)
    mstr = typename(M)
    for s in SIZES
        m = linalgmat(M, s)
        g["svd", mstr, s]     = @benchmarkable svd($m)
        g["svdfact", mstr, s] = @benchmarkable svdfact($m)
    end
end

for M in (Matrix, Tridiagonal)
    mstr = typename(M)
    for s in SIZES
        m = linalgmat(M, s)
        g["lu", mstr, s]     = @benchmarkable lu($m)
        g["lufact", mstr, s] = @benchmarkable lufact($m)
    end
end

for s in SIZES
    mstr = typename(Matrix)
    m = randmat(s)
    arr = m' * m
    g["chol", mstr, s]      = @benchmarkable chol($arr)
    g["cholfact", mstr, s]  = @benchmarkable cholfact($arr)
    g["schur", mstr, s]     = @benchmarkable schur($m)
    g["schurfact", mstr, s] = @benchmarkable schurfact($m)
    g["qr", mstr, s]        = @benchmarkable qr($m)
    g["qrfact", mstr, s]    = @benchmarkable qrfact($m)
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

end # module
