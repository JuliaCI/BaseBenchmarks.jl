# BaseBenchmarks.jl

This package is a collection of Julia benchmarks available for CI tracking from the JuliaLang/julia repository.

The `master` branch holds benchmarks written for Julia v0.5, while the `release-0.4` branch holds benchmarks written for Julia v0.4. These branches should differ as little as possible - they only exist separately to avoid breakage between versions. To see what versions of this package are currently deployed on our CI tracking hardware, simply refer to the tags: the latest version tagged `vA.B.C` is currently deployed to test Julia `vA.B` (e.g. BaseBenchmarks.jl version `v0.5.x` runs against Julia `v0.5`, and BaseBenchmarks.jl version `v0.4.x` runs against Julia `v0.4`).