module BLASBenchmarks

import ..BaseBenchmarks
using ..BenchmarkTrackers

const SIZES = (2^2, 2^4, 2^6, 2^8, 2^10)

###########
# level 1 #
###########

@track BaseBenchmarks.TRACKER "blas 1" begin
    @setup vectors = map(rand, SIZES)
    @benchmarks begin
        [(:dot, length(v)) => dot(v, v) for v in vectors]
        [(:scal!, length(v)) => BLAS.scal!(length(v), BaseBenchmarks.samerand(), v, 1) for v in vectors]
        [(:blascopy!, length(v)) => BLAS.blascopy!(length(v), v, 1, zeros(v), 1) for v in vectors]
        [(:axpy!, length(v)) => BLAS.axpy!(BaseBenchmarks.samerand(), v, zeros(v)) for v in vectors]
        [(:nrm2, length(v)) => BLAS.nrm2(v) for v in vectors]
        [(:asum, length(v)) => BLAS.asum(v) for v in vectors]
        [(:iamax, length(v)) => BLAS.iamax(v) for v in vectors]
    end
    @tags "array" "linalg" "blas" "mul" "level1" "dot" "axpy!" "scal!" "blascopy!" "nrm2" "asum" "iamax"
end

###########
# level 2 #
###########

@track BaseBenchmarks.TRACKER  "blas 2" begin
    @setup begin
        As = map(n -> BaseBenchmarks.samerand(n, n), SIZES)
        arrays = map(n -> (BaseBenchmarks.samerand(n, n), BaseBenchmarks.samerand(n)), SIZES)
        symAs = map(A -> A + A.', As)
        symarrays = zip(symAs, map(n -> BaseBenchmarks.samerand(n), SIZES))
        hemmAs = map(A -> A + im*triu(A,1)', As)
        hemmarrays = zip(hemmAs, map(n -> BaseBenchmarks.samerand(n), SIZES))
        triAs = map(A -> triu(A), As)
        triarrays = zip(triAs, map(n -> BaseBenchmarks.samerand(n), SIZES))
    end
    @benchmarks begin
        [(:gemv, length(x)) => *(A, x) for (A, x) in arrays]
        [(:symv, length(x)) => *(A, x) for (A, x) in symarrays]
        [(:hemv, length(x)) => *(A, x) for (A, x) in hemmarrays]
        [(:trmv, length(x)) => *(A, x) for (A, x) in triarrays]
        [(:trsv, length(x)) => \(A, x) for (A, x) in triarrays]
        [(:syr!, length(x)) => BLAS.syr!('U',1.,x,A) for (A, x) in symarrays]
    end
    @tags "array" "linalg" "blas" "mul" "level2" "gemv" "symv" "hemv" "trmv" "trsv" "syr!" "her!"
end

###########
# level 3 #
###########

@track BaseBenchmarks.TRACKER "blas 3" begin
    @setup begin
        arrays = map(n -> BaseBenchmarks.samerand(n, n), SIZES)
        symmAs = map(A -> A + A.', arrays)
        hemmAs = map(A -> A + im*triu(A,1)', arrays)
        trmmAs = map(A -> triu(A), arrays)
    end
    @benchmarks begin
        [(:A_mul_B!, size(A, 1)) => A_mul_B!(zeros(A), A, A) for A in arrays]
        [(:symm!, size(A, 1)) => BLAS.symm!('L','U',1., A, B,1.,zeros(B)) for (A,B) in zip(symmAs,arrays)]
        [(:hemm!, size(A, 1)) => BLAS.hemm!('L','U',complex(1.,0.), A, A,complex(1.,0.),zeros(A)) for A in hemmAs]
        [(:syrk, size(A, 1)) => BLAS.syrk('U','N',A) for A in symmAs]
        [(:herk, size(A, 1)) => BLAS.herk('U','N',A) for A in hemmAs]
        [(:trmm!, size(A, 1)) => BLAS.trmm!('L','U','N','N',1.,A,B) for (A,B) in zip(trmmAs,arrays)]
        [(:trsm!, size(A, 1)) => BLAS.trsm!('L','U','N','N',1.,A,B) for (A,B) in zip(trmmAs,arrays)]
    end
    @tags "array" "linalg" "blas" "mul" "level3" "matmul" "symm!" "hemm!" "syrk" "herk" "trmm!"
end

end # module
