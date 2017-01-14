module ThreadedStockCorr

# Threaded implementation of test case from Issue #445

using Base.Threads

# Run paths in parallel (has to be in its own function due to #10718)
function runpath!(n, Wiener, CorrWiener, SA, SB, T, UpperTriangle, k11, k12, k21, k22, rngs)
    @threads for i = 1:n
        randn!(rngs[threadid()], Wiener)
        A_mul_B!(CorrWiener, Wiener, UpperTriangle)
        @simd for j = 2:T
            @inbounds SA[j, i] = SA[j-1, i] * exp(k11 + k12*CorrWiener[j-1, 1])
            @inbounds SB[j, i] = SB[j-1, i] * exp(k21 + k22*CorrWiener[j-1, 2])
        end
    end
end

function perf_pstockcorr(n)
    ## Correlated asset information
    const CurrentPrice = [78. 102.]     # Initial Prices of the two stocks
    const Corr = [1. 0.4; 0.4 1.]       # Correlation Matrix
    const T = 500                       # Number of days to simulate = 2years = 500days
    const dt = 1/250                    # Time step (1year = 250days)
    const Div = [0.01 0.01]               # Dividend
    const Vol = [0.2 0.3]                 # Volatility

    ## Market Information
    const r = 0.03                      # Risk-free rate

    ## Define storages
    SimulPriceA = zeros(T,n)            # Simulated Price of Asset A
    SimulPriceA[1,:] = CurrentPrice[1]
    SimulPriceB = zeros(T,n)            # Simulated Price of Asset B
    SimulPriceB[1,:] = CurrentPrice[2]

    ## Generating the paths of stock prices by Geometric Brownian Motion
    const UpperTriangle = full(chol(Corr))    # UpperTriangle Matrix by Cholesky decomposition

    # Optimization: pre-allocate these for performance
    # NOTE: the new GC will hopefully fix this, but currently GC time
    # kills performance if we don't do in-place computations
    Wiener = Matrix{Float64}(T-1, 2)
    CorrWiener = Matrix{Float64}(T-1, 2)

    # Runtime requirement: need per-thread RNG since it stores state
    rngs = [MersenneTwister(777+x) for x in 1:nthreads()]

    # Optimization: pre-computable factors
    # NOTE: this should be automatically hoisted out of the loop
    k11 = (r-Div[1]-Vol[1]^2/2)*dt
    k12 = Vol[1]*sqrt(dt)
    k21 = (r-Div[2]-Vol[2]^2/2)*dt
    k22 = Vol[2]*sqrt(dt)

    runpath!(n, Wiener, CorrWiener, SimulPriceA, SimulPriceB, T, UpperTriangle, k11, k12, k21, k22, rngs)

    return (SimulPriceA, SimulPriceB)
end

end # module
