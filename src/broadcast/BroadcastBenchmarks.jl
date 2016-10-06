module BroadcastBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

const SUITE = BenchmarkGroup()

# work around lack of Compat support for .= (Compat.jl issue #285)
if VERSION < v"0.5.0-dev+5575" #17510
    macro dotcompat(ex)
        if Meta.isexpr(ex, :comparison, 3) && ex.args[2] == :.=
            :(copy!($(ex.args[1]), $(ex.args[3])))
        else
            ex
        end
    end
else
    macro dotcompat(ex)
        ex
    end
end

###########################################################################

g = addgroup!(SUITE, "fusion", ["broadcast!", "array"])

f(x,y) = 3x - 4y^2
h(x) = 6x + 2x^2 - 5
perf_bcast!(r, x) = @dotcompat r .= @compat h.(f.(x, h.(x)))
perf_bcast!(R, x, y) = @dotcompat R .= @compat h.(f.(x, h.(y)))
perf_bcast!(R, x, y, z) = @dotcompat R .= @compat f.(X, f.(x, y))

x = randvec(10^3)
y = randvec(10^3)'
z = randvec(10^6)
X = randmat(10^3)
R = Array(Float64, length(x),length(y))
r = similar(z)

g["fusion", "Float64", size(r), 1] = @benchmarkable perf_bcast!($r, $z)
g["fusion", "Float64", size(R), 2] = @benchmarkable perf_bcast!($R, $x, $y)
g["fusion", "Float64", size(R), 3] = @benchmarkable perf_bcast!($R, $X, $x, $y)
g["fusion", "Float64", size(r), 2] = @benchmarkable perf_bcast!($r, $z, 17.3)

###########################################################################

g = addgroup!(SUITE, "dotop", ["broadcast!", "array"])

perf_op_bcast!(r, x) = @dotcompat r .= 3 .* x .- 4 .* x.^2 .+ x .* x .- x .^ 3
perf_op_bcast!(R, x, y) = @dotcompat R .= 3 .* x .- 4 .* y.^2 .+ x .* y .- x .^ 3

g["dotop", "Float64", size(r), 1] = @benchmarkable perf_op_bcast!($r, $z)
g["dotop", "Float64", size(R), 2] = @benchmarkable perf_op_bcast!($R, $x, $y)
g["dotop", "Float64", size(r), 2] = @benchmarkable perf_op_bcast!($r, $z, 17.3)

###########################################################################

g = addgroup!(SUITE, "sparse", ["broadcast", "array"])

s = samesprand(10^7, 1e-3, randn)
perf_sparse_op(s) = sqrt.(abs.(s .* 2))
perf_sparse_op(s,t) = f.(s,t)
g["sparse", size(s), 1] = @benchmarkable perf_sparse_op($s)
g["sparse", size(s), 2] = @benchmarkable perf_sparse_op($s, $s)

###########################################################################

end # module
