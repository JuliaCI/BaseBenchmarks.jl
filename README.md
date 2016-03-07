# BaseBenchmarks.jl

[![Build Status](https://travis-ci.org/JuliaCI/BaseBenchmarks.jl.svg?branch=master)](https://travis-ci.org/JuliaCI/BaseBenchmarks.jl)

This package is a collection of Julia benchmarks available for CI performance tracking from the JuliaLang/julia repository.

#### Executing Benchmarks

```julia
julia> using BaseBenchmarks

julia> execute(BaseBenchmarks.GROUPS[@tagged ("array" || "linalg") && !("simd")])
```

Documentation regarding benchmark execution and result analysis can be found in [BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl).

#### Contributing

Our performance tracker could always benefit from more benchmarks! If you have a benchmark that depends only on `Base` Julia code, it is welcome here.

Here are some contribution tips:

- You'll need to use [BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl) to write the benchmarks (feel free to open a WIP PR if you'd like help with this).
- Newly defined functions whose calls are measured should have `perf_` prepended to their name. This makes it easier to find a given benchmark's "entry point" in the code.
- Try to reuse existing tags when possible. Tags should be lowercase and singular.
- If your benchmark requires a significant amount of code, wrap it in a module.

#### Versioning

Each tagged release of BaseBenchmarks.jl aims to support the most recent v0.4 and v0.5 builds of Julia, with an emphasis on forward compatibility.

Note that each new tagged version corresponds to a deployment to our CI tracking infrastructure. Thus, to see which benchmarks are currently available on the CI tracker, just look at the most recently tagged version of this package.
