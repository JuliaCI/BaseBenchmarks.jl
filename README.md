# BaseBenchmarks.jl

This package is a collection of Julia benchmarks available for CI performance tracking from the JuliaLang/julia repository.

#### Contributing

Our performance tracker could always benefit from more benchmarks! If you have a benchmark that depends only on `Base` Julia code, it is welcome here.

Here are some contribution tips:

- You'll need to use [BenchmarkTrackers.jl](https://github.com/JuliaCI/BenchmarkTrackers.jl) to write the benchmarks (feel free to open a WIP PR if you'd like help with this).
- Newly defined functions whose calls are measured should have `perf_` prepended to their name. This makes it easier to find a given benchmark's "entry point" in the code.
- Try to reuse existing tags when possible. Tags should be lowercase and singular.
- If your benchmark requires a significant amount of code, wrap it in a module.

#### Versioning

The `master` branch holds benchmarks written for Julia v0.5, while the `release-0.4` branch holds benchmarks written for Julia v0.4. These branches should differ as little as possible - they only exist separately to avoid breakage between versions.

To see what versions of this package are currently deployed on our CI tracking hardware, simply refer to the git tags: the latest version tagged `vA.B.C` is currently deployed to test Julia `vA.B`. For example, BaseBenchmarks `v0.5.x` runs against Julia v0.5, while BaseBenchmarks `v0.4.x` runs against Julia v0.4.
