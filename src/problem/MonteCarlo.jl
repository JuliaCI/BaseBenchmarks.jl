module MonteCarlo

using Compat
if VERSION >= v"0.7.0-DEV.3406"
    using Random
end
if VERSION >= v"0.7.0-beta.85"
    using Statistics
end

# European Option Calculation from
# https://groups.google.com/forum/?hl=en&fromgroups=#!topic/julia-dev/ImhGsqX_IHc

function perf_euro_option_devec(npaths)
    steps = 250
    r = 0.05
    sigma = .4
    T = 1
    dt = T/steps
    K = 100
    S = fill(100.0, npaths)
    t1 = (r - 0.5*sigma^2)*dt
    t2 = sigma*sqrt(dt)

    for i=1:steps
        for j=1:npaths
            S[j] *= exp(t1 + t2 * randn())
        end
    end

    return mean(exp(-r*T) .* max.(K .- S, 0))
end

function perf_euro_option_vec(npaths)
    steps = 250
    r = 0.05
    sigma = .4
    T = 1
    dt = T/steps
    K = 100
    S = fill(100.0, npaths)
    t1 = (r - 0.5*sigma^2)*dt
    t2 = sigma*sqrt(dt)
    R = Array{Float64}(undef, npaths)

    for i=1:steps
        S .*= exp.(t2 .* randn!(R) .+ t1)
    end

    return mean(exp(-r*T) .* max.(K .- S, 0))
end

end # module
