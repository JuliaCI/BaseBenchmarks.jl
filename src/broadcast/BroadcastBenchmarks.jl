module BroadcastBenchmarks

include(joinpath("..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

const SUITE = BenchmarkGroup()

###########################################################################

g = addgroup!(SUITE, "fusion", ["broadcast!", "array"])

f(x,y) = 3x - 4y^2
h(x) = 6x + 2x^2 - 5
perf_bcast!(r, x) = @compat r .= @compat h.(f.(x, h.(x)))
perf_bcast!(R, x, y) = @compat R .= @compat h.(f.(x, h.(y)))
perf_bcast!(R, x, y, z) = @compat R .= @compat f.(X, f.(x, y))

x = randvec(10^3)
y = randvec(10^3)'
z = randvec(10^6)
X = randmat(10^3)
R = Array(Float64, length(x),length(y))
r = similar(z)

g["Float64", size(r), 1] = @benchmarkable perf_bcast!($r, $z)
g["Float64", size(R), 2] = @benchmarkable perf_bcast!($R, $x, $y)
g["Float64", size(R), 3] = @benchmarkable perf_bcast!($R, $X, $x, $y)
g["Float64", size(r), 2] = @benchmarkable perf_bcast!($r, $z, 17.3)

###########################################################################

g = addgroup!(SUITE, "dotop", ["broadcast!", "array"])

perf_op_bcast!(r, x) = @compat r .= 3 .* x .- 4 .* x.^2 .+ x .* x .- x .^ 3
perf_op_bcast!(R, x, y) = @compat R .= 3 .* x .- 4 .* y.^2 .+ x .* y .- x .^ 3

g["Float64", size(r), 1] = @benchmarkable perf_op_bcast!($r, $z)
g["Float64", size(R), 2] = @benchmarkable perf_op_bcast!($R, $x, $y)
g["Float64", size(r), 2] = @benchmarkable perf_op_bcast!($r, $z, 17.3)

###########################################################################

g = addgroup!(SUITE, "sparse", ["broadcast", "array"])

perf_sparse_op(s) = @compat sqrt.(abs.(s .* 2))
perf_sparse_op(s,t) = @compat f.(s,t)

if VERSION < v"0.5.0-dev+763"
    s = samesprand(10^7, 1, 1e-3, randn)
else
    s = samesprand(10^7, 1e-3, randn)
end
S = samesprand(10^3, 10^3, 1e-3, randn)

g[size(s), 1] = @benchmarkable perf_sparse_op($s)
g[size(s), 2] = @benchmarkable perf_sparse_op($s, $s)
g[size(S), 1] = @benchmarkable perf_sparse_op($S)
g[size(S), 2] = @benchmarkable perf_sparse_op($S, $S)

###########################################################################

end # module
