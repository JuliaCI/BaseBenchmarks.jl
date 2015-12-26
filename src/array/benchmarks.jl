include("definitions.jl")

small_size = (3,5)
large_size = (300,500)
small_n = 10^5
large_n = 100

# using small Int arrays...
@track TRACKER begin
    @setup arrays = makearrays(Int, small_size)
    @benchmarks begin
        ["sumelt $(summary(A))" => sumelt(A, small_n) for A in arrays]
        ["sumeach $(summary(A))" => sumeach(A, small_n) for A in arrays]
        ["sumlinear $(summary(A))" => sumlinear(A, small_n) for A in arrays]
        ["sumcartesian $(summary(A))" => sumcartesian(A, small_n) for A in arrays]
        ["sumcolon $(summary(A))" => sumcolon(A, small_n) for A in arrays]
        ["sumrange $(summary(A))" => sumrange(A, small_n) for A in arrays]
        ["sumlogical $(summary(A))" => sumlogical(A, small_n) for A in arrays]
        ["sumvector $(summary(A))" => sumvector(A, small_n) for A in arrays]
    end
    @tags "small" "arrays" "Int" "sums" "indexing"
end

# using large Int arrays...
@track TRACKER begin
    @setup arrays = makearrays(Int, large_size)
    @benchmarks begin
        ["sumelt $(summary(A))" => sumelt(A, large_n) for A in arrays]
        ["sumeach $(summary(A))" => sumeach(A, large_n) for A in arrays]
        ["sumlinear $(summary(A))" => sumlinear(A, large_n) for A in arrays]
        ["sumcartesian $(summary(A))" => sumcartesian(A, large_n) for A in arrays]
        ["sumcolon $(summary(A))" => sumcolon(A, large_n) for A in arrays]
        ["sumrange $(summary(A))" => sumrange(A, large_n) for A in arrays]
        ["sumlogical $(summary(A))" => sumlogical(A, large_n) for A in arrays]
        ["sumvector $(summary(A))" => sumvector(A, large_n) for A in arrays]
    end
    @tags "large" "arrays" "Int" "sums" "indexing"
end

# using small Float32 arrays...
@track TRACKER begin
    @setup arrays = makearrays(Float32, small_size)
    @benchmarks begin
        ["sumelt $(summary(A))" => sumelt(A, small_n) for A in arrays]
        ["sumeach $(summary(A))" => sumeach(A, small_n) for A in arrays]
        ["sumlinear $(summary(A))" => sumlinear(A, small_n) for A in arrays]
        ["sumcartesian $(summary(A))" => sumcartesian(A, small_n) for A in arrays]
        ["sumcolon $(summary(A))" => sumcolon(A, small_n) for A in arrays]
        ["sumrange $(summary(A))" => sumrange(A, small_n) for A in arrays]
        ["sumlogical $(summary(A))" => sumlogical(A, small_n) for A in arrays]
        ["sumvector $(summary(A))" => sumvector(A, small_n) for A in arrays]
    end
    @tags "small" "arrays" "Float" "sums" "indexing"
end

# using large Float32 arrays...
@track TRACKER begin
    @setup arrays = makearrays(Float32, large_size)
    @benchmarks begin
        ["sumelt $(summary(A))" => sumelt(A, large_n) for A in arrays]
        ["sumeach $(summary(A))" => sumeach(A, large_n) for A in arrays]
        ["sumlinear $(summary(A))" => sumlinear(A, large_n) for A in arrays]
        ["sumcartesian $(summary(A))" => sumcartesian(A, large_n) for A in arrays]
        ["sumcolon $(summary(A))" => sumcolon(A, large_n) for A in arrays]
        ["sumrange $(summary(A))" => sumrange(A, large_n) for A in arrays]
        ["sumlogical $(summary(A))" => sumlogical(A, large_n) for A in arrays]
        ["sumvector $(summary(A))" => sumvector(A, large_n) for A in arrays]
    end
    @tags "large" "arrays" "Float" "sums" "indexing"
end
