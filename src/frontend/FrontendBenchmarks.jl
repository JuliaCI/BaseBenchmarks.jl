module FrontendBenchmarks

using BenchmarkTools

const SUITE = BenchmarkGroup(["nestedscopes"])

nested_lets = :(:(()->$(Expr(:let, Expr(:block, Any[ Expr(:(=), Symbol("x$i"), :x1) for i = 1:2000 ]...), Expr(:block)))))

SUITE["nestedscopes"] = @benchmarkable Meta.lower(@__MODULE__, $nested_lets)

end
