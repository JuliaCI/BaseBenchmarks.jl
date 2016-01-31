module LAPACKBenchmarks

import ..BaseBenchmarks
using ..BenchmarkTrackers

const SIZES = (2^2, 2^4, 2^6, 2^8, 2^10)

#######
# eig #
#######

@track BaseBenchmarks.TRACKER "lapack eig" begin
    @setup begin
        real_arrays = map(n -> BaseBenchmarks.samerand(n, n), SIZES)
        sym_arrays = map(A -> A + A', real_arrays)
        herm_arrays = map(real_arrays) do A
            A = A + im*BaseBenchmarks.samerand(size(A)...)
            return A + A'
        end
        tridiag_arrays = map(SIZES) do n
            d_ = BaseBenchmarks.samerand(n)
            e_ = BaseBenchmarks.samerand(n-1)
            f_ = BaseBenchmarks.samerand(n-1)
            return Tridiagonal(f_,d_,e_)
        end
        symtri_arrays = map(SIZES) do n
            d_ = BaseBenchmarks.samerand(n)
            e_ = BaseBenchmarks.samerand(n-1)
            return SymTridiagonal(d_,e_)
        end
        uptri_arrays = map( A -> UpperTriangular(A), real_arrays)
        lotri_arrays = map( A -> LowerTriangular(A), real_arrays)
        unituptri_arrays = map( A -> Base.LinAlg.UnitUpperTriangular(A), real_arrays)
        unitlotri_arrays = map( A -> Base.LinAlg.UnitLowerTriangular(A), real_arrays)
    end
    @benchmarks begin
        [(:realeig, size(A, 1)) => eig(A) for A in real_arrays]
        [(:symeig, size(A, 1)) => eig(A) for A in sym_arrays]
        [(:hermeig, size(A, 1)) => eig(A) for A in herm_arrays]
        [(:symtrieig, size(A, 1)) => eigfact(A) for A in symtri_arrays]
        [(:uptrieig, size(A, 1)) => eigfact(A) for A in uptri_arrays]
        [(:lotrieig, size(A, 1)) => eigfact(A) for A in lotri_arrays]
        [(:unituptrieig, size(A, 1)) => eigfact(A) for A in unituptri_arrays]
        [(:unitlotrieig, size(A, 1)) => eigfact(A) for A in unitlotri_arrays]
    end
    @tags "array" "lapack" "linalg" "eig" "eigfact" "factorization"
end

#################
# factorization #
#################

@track BaseBenchmarks.TRACKER "lapack svd" begin
    @setup arrays = map(n -> BaseBenchmarks.samerand(n, n), SIZES)
    @benchmarks begin
        [(:svdfact, size(A, 1)) => svdfact(A) for A in arrays]
    end
    @tags "array" "lapack" "linalg" "factorization" "svd" "svdfact"
end

@track BaseBenchmarks.TRACKER "lapack lu" begin
    @setup arrays = map(n -> BaseBenchmarks.samerand(n, n), SIZES)
    @benchmarks begin
        [(:lufact, size(A, 1)) => lufact(A) for A in arrays]
    end
    @tags "array" "lapack" "linalg" "factorization" "lu" "lufact"
end

@track BaseBenchmarks.TRACKER "lapack qr" begin
    @setup arrays = map(n -> BaseBenchmarks.samerand(n, n), SIZES)
    @benchmarks begin
        [(:qrfact, size(A, 1)) => qrfact(A) for A in arrays]
    end
    @tags "array" "lapack" "linalg" "factorization" "qr" "qrfact"
end

@track BaseBenchmarks.TRACKER "lapack schur" begin
    @setup arrays = map(n -> BaseBenchmarks.samerand(n, n), SIZES)
    @benchmarks begin
        [(:schurfact, size(A, 1)) => schurfact(A) for A in arrays]
    end
    @tags "array" "lapack" "linalg" "factorization" "schur" "schurfact"
end

@track BaseBenchmarks.TRACKER "lapack chol" begin
    @setup begin
        arrays = map(SIZES) do n
            A = BaseBenchmarks.samerand(n, n)
            return A'*A
        end
    end
    @benchmarks begin
        [(:cholfact, size(A, 1)) => cholfact(A) for A in arrays]
    end
    @tags "array" "lapack" "linalg" "factorization" "cholesky" "cholfact"
end


end # module
