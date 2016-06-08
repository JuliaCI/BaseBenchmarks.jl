# BaseBenchmarks.jl

[![Build Status](https://travis-ci.org/JuliaCI/BaseBenchmarks.jl.svg?branch=master)](https://travis-ci.org/JuliaCI/BaseBenchmarks.jl)

This package is a collection of Julia benchmarks using to track the performance of [the Julia language](https://github.com/JuliaLang/julia).

BaseBenchmarks is written using the [BenchmarkTools](https://github.com/JuliaCI/BenchmarkTools.jl) package.

#### Loading and running benchmarks

BaseBenchmarks contains a large amount of code, not all of which is suitable for precompilation. Loading all of this code at once can take an annoyingly long time if you only need to run one or two benchmarks. To solve this problem, BaseBenchmarks allows you to dynamically load benchmark suites when you need them:

```julia
julia> using BaseBenchmarks

# This is the top-level BenchmarkGroup. It's empty until you load child groups into it.
julia> BaseBenchmarks.SUITE
0-element BenchmarkTools.BenchmarkGroup:
  tags: []

# Load the "linalg" group into BaseBenchmarks.SUITE. You can optionally pass in a different
# BenchmarkGroup as the first argument to load "linalg" into it.
julia> BaseBenchmarks.load!("linalg")
  1-element BenchmarkTools.BenchmarkGroup:
    tags: []
    "linalg" => 3-element BenchmarkGroup(["array"])

# Load all the benchmarks into BaseBenchmarks.SUITE. Once again, you can pass in a different
# BenchmarkGroup as the first argument to load the benchmarks there instead.
julia> BaseBenchmarks.loadall!();
loading group "string"...done (took 0.379868963 seconds)
loading group "linalg"...done (took 5.4598628 seconds)
loading group "parallel"...done (took 0.086358304 seconds)
loading group "tuple"...done (took 0.651417342 seconds)
loading group "micro"...done (took 0.377109301 seconds)
loading group "io"...done (took 0.068647882 seconds)
loading group "scalar"...done (took 16.922505539 seconds)
loading group "sparse"...done (took 3.750095955 seconds)
loading group "simd"...done (took 2.542815776 seconds)
loading group "problem"...done (took 2.002920499 seconds)
loading group "array"...done (took 6.072152907 seconds)
loading group "sort"...done (took 3.308745574 seconds)
loading group "shootout"...done (took 0.72022176 seconds)
```

Now that the benchmarks are loaded, you can run them just like any other `BenchmarkTools.BenchmarkGroup`:

```julia
# run benchmarks matching a tag query
julia> run(BaseBenchmarks.SUITE[@tagged ("array" || "linalg") && !("simd")]);

# run a specific benchmark group
julia> run(BaseBenchmarks.SUITE["linalg"]["arithmetic"]);

# run a single benchmark
julia> run(BaseBenchmarks.SUITE["scalar"]["fastmath"]["add", "Complex{Float64}"])

# equivalent to the above, but this form makes it
# easy to copy and paste IDs from benchmark reports
julia> run(BaseBenchmarks.SUITE[["scalar", "fastmath", ("add", "Complex{Float64}")]]);
```

See the [`BenchmarkTools`]((https://github.com/JuliaCI/BenchmarkTools.jl)) repository for documentation of `BenchmarkTools.BenchmarkGroup` features (e.g. regression classification and filtering, parameter tuning, leaf iteration, higher order mapping/filtering, etc.).

#### Recipe for testing a julia PR locally

You can use the Nanosoldier framework to test the performance of your
PR, using `@nanosoldier runbenchmarks("array", vs = ":master")` or similar.
However, if you'd like to test your PR locally first, the
following procedure can be used:

- Build master
- Run benchmarks & save results
- Build PR
- Run benchmarks & save results
- Load and compare the results, looking for regressions
- Profile any regressions to find opportunities for performance improvements

Here's how you run benchmarks & save results:
```jl
using BenchmarkTools, BaseBenchmarks, JLD
BaseBenchmarks.loadall!()
results = run(BaseBenchmarks.SUITE)
save(filename, "results", results)
```
The `filename` should end in `".jld"`.

To load and compare results, use something like this:
```jl
using BenchmarkTools, BaseBenchmarks, JLD
master = load(filename_master, "results")
pr = load(filename_pr, "results")
df = regressions(judge(median(pr), median(master)))
for p in df
    @show p
end
```
This will show the tests that resulted in regressions; you can examine
those benchmarks in detail and try to fix the regressions.

To profile a benchmark on your currently-built branch, you'll need to
understand how to read the tags. The "top level" tags are printed
aligned with a "p = " starting at left margin; from there, look for
any `BenchmarkGroup` lines for additional nesting. Within those,
you'll find single strings or tuples that specify parameters. For
example, here we'll "highlight" the key tags of the output using
all-caps (in reality it is lowercase):

```
p = Pair{Any,Any}("PROBLEM",3-element BenchmarkTools.BenchmarkGroup:
  tags: ["example", "kernel"]
  "LAPLACIAN" => 1-element BenchmarkTools.BenchmarkGroup:
  tags: ["iterative", "sparse", "vectorization", "subarray", "array"]
  "LAPLACE_ITER_VEC" => BenchmarkTools.TrialJudgement:
  time:   +42.61% => regression (15.00% tolerance)
  memory: +0.93% => invariant (1.00% tolerance)
```

Note the indicated regression on `"laplace_iter_vec"`.  To re-run this
benchmark, use the following procedure:

```jl
using BenchmarkTools, BaseBenchmarks
BaseBenchmarks.loadall!()
run(BaseBenchmarks.SUITE[["problem","laplacian","laplace_iter_vec"]])
```

where those tags come from the all-caps highlighted output above.

Once you've run it once, stick a `@profile` in front of the `run`
command and execute it again. Then you can use `Profile.print()` or
`ProfileView.view()` to analyze the bottlenecks that led to that
regression.

#### Contributing

Our performance tracker could always benefit from more benchmarks! If you have a benchmark that depends only on `Base` Julia code, it is welcome here - just open a PR against the master branch.

Here are some contribution tips and guidelines:

- All benchmarks should only depend on base Julia.
- You'll need to use [BenchmarkTools](https://github.com/JuliaCI/BenchmarkTools.jl) to write the benchmarks (feel free to open a WIP PR if you'd like help with this).
- Newly defined functions whose calls are measured should have `perf_` prepended to their name. This makes it easier to find a given benchmark's "entry point" in the code.
- Try to reuse existing tags when possible. Tags should be lowercase and singular.
- If your benchmark requires a significant amount of code, wrap it in a module.

#### Which version of BaseBenchmarks is being used in CI?

New benchmarks added to BaseBenchmarks won't be present via CI right away, as their execution parameters must be [tuned and cached](https://github.com/JuliaCI/BenchmarkTools.jl/blob/master/doc/manual.md#caching-parameters) on [Nanosoldier](https://github.com/JuliaCI/Nanosoldier.jl) (our benchmark cluster) before they are suitable for running. This process is performed periodically and upon request, after which the `master` branch is merged into the [`nanosoldier`](https://github.com/JuliaCI/BaseBenchmarks.jl/tree/nanosoldier) branch. Nanosoldier pulls down the `nanosoldier` branch before running every benchmark job, so whatever's currently on the `nanosoldier` branch is what's being used in CI.
