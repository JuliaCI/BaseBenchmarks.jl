# BaseBenchmarks.jl

[![Build Status](https://github.com/JuliaCI/BaseBenchmarks.jl/workflows/CI/badge.svg)](https://github.com/JuliaCI/BaseBenchmarks.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![codecov](https://codecov.io/gh/JuliaCI/BaseBenchmarks.jl/branch/master/graph/badge.svg?label=codecov&token=ZETWYEXlbE)](https://codecov.io/gh/JuliaCI/BaseBenchmarks.jl)

This package is a collection of Julia benchmarks used to track the performance of [the Julia language](https://github.com/JuliaLang/julia).

BaseBenchmarks is written using the
[BenchmarkTools](https://github.com/JuliaCI/BenchmarkTools.jl) package. I
highly suggest at least skimming the [BenchmarkTools
manual](https://juliaci.github.io/BenchmarkTools.jl/dev/manual/)
before using BaseBenchmarks locally.

#### Loading and running benchmarks

BaseBenchmarks contains a large amount of code, not all of which is suitable
for precompilation. Loading all of this code at once can take an annoyingly
long time if you only need to run one or two benchmarks. To solve this problem,
BaseBenchmarks allows you to dynamically load benchmark suites when you need
them:

```julia
julia> using BaseBenchmarks

# This is the top-level BenchmarkGroup. It's empty until you load child groups into it.
julia> BaseBenchmarks.SUITE
0-element BenchmarkTools.BenchmarkGroup:
  tags: []

# Here's an example of how to load the "linalg" group into BaseBenchmarks.SUITE. You can
# optionally pass in a different BenchmarkGroup as the first argument to load "linalg"
# into it.
julia> BaseBenchmarks.load!("linalg")
  1-element BenchmarkTools.BenchmarkGroup:
    tags: []
    "linalg" => 3-element BenchmarkGroup(["array"])

# Here's an example of how to load all the benchmarks into BaseBenchmarks.SUITE. Once again,
# you can pass in a different BenchmarkGroup as the first argument to load the benchmarks
# there instead.
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
run(BaseBenchmarks.SUITE[@tagged ("array" || "linalg") && !("simd")]);

# run a specific benchmark group
run(BaseBenchmarks.SUITE["linalg"]["arithmetic"]);

# run a single benchmark
run(BaseBenchmarks.SUITE["scalar"]["fastmath"]["add", "Complex{Float64}"])

# equivalent to the above, but this form makes it
# easy to copy and paste IDs from benchmark reports
run(BaseBenchmarks.SUITE[["scalar", "fastmath", ("add", "Complex{Float64}")]]);
```

See the [`BenchmarkTools`]((https://github.com/JuliaCI/BenchmarkTools.jl))
repository for documentation of `BenchmarkTools.BenchmarkGroup` features (e.g.
regression classification and filtering, parameter tuning, leaf iteration,
higher order mapping/filtering, etc.).

#### Recipe for testing a Julia PR locally

If you're a collaborator, [you can trigger Julia's @nanosoldier
bot](https://github.com/JuliaCI/Nanosoldier.jl) to automatically test the performance of
your PR vs. Julia's master branch. However, this bot's purpose isn't to have the final
say on performance matters, but rather to identify areas which require local performance
testing. Here's a procedure for testing your Julia PR locally:

1. Run benchmarks and save results using master Julia build
2. Run benchmarks and save results using PR Julia build
3. Load and compare the results, looking for regressions
4. Profile any regressions to find opportunities for performance improvements

For steps 1 and 2, first build Julia on the appropriate branch. Then, you can run the
following code to execute all benchmarks and save the results (replacing `filename` with
an actual unique file name):

```julia
using BenchmarkTools, BaseBenchmarks
BaseBenchmarks.loadall!() # load all benchmarks
results = run(BaseBenchmarks.SUITE; verbose = true) # run all benchmarks
BenchmarkTools.save("filename.json", results) # save results to JSON file
```

Next, you can load the results and check for regressions (once again replacing the JSON file
names used here with the actual file names):

```julia
using BenchmarkTools, BaseBenchmarks
master = BenchmarkTools.load("master.json")[1]
pr = BenchmarkTools.load("pr.json")[1]
regs = regressions(judge(minimum(pr), minimum(master))) # a BenchmarkGroup containing the regressions
pairs = leaves(regs) # an array of (ID, `TrialJudgement`) pairs
```

This will show which tests resulted in regressions and to what magnitude. Here's an
example showing what `pairs` might look like:

```julia
2-element Array{Any,1}:
 (Any["string","join"],BenchmarkTools.TrialJudgement:
  time:   +41.13% => regression (1.00% tolerance)
  memory: +0.00% => invariant (1.00% tolerance))
 (Any["io","read","readstring"],BenchmarkTools.TrialJudgement:
  time:   +13.85% => regression (3.00% tolerance)
  memory: +0.00% => invariant (1.00% tolerance))
```

Each pair above is structured as `(benchmark ID, TrialJudgement for benchmark)`. You can
now examine these benchmarks in detail and try to fix the regressions. Let's use the
`["io","read","readstring"]` ID shown above as an example.

To examine this benchmark on your currently-built branch, first make sure you've loaded
the benchmark's parent group (the first element in the ID, `"io"`):

```julia
julia> using BenchmarkTools, BaseBenchmarks

julia> showall(BaseBenchmarks.load!("io"))
1-element BenchmarkTools.BenchmarkGroup:
  tags: []
  "io" => 1-element BenchmarkTools.BenchmarkGroup:
	  tags: []
	  "read" => 2-element BenchmarkTools.BenchmarkGroup:
		  tags: ["buffer", "stream", "string"]
		  "readstring" => BenchmarkTools.Benchmark...
		  "read" => BenchmarkTools.Benchmark...
```

You can now run the benchmark by calling
`run(BaseBenchmarks.SUITE[["io","read","readstring"]])`, or profile it using `@profile`:

```julia
@profile run(BaseBenchmarks.SUITE[["io","read","readstring"]])
```

After profiling the benchmark, you can use `Profile.print()` or `ProfileView.view()` to
analyze the bottlenecks that led to that regression.

#### Contributing

Our performance tracker could always benefit from more benchmarks! If you have
a benchmark that depends only on `Base` Julia code, it is welcome here - just
open a PR against the master branch.

Here are some contribution tips and guidelines:

- All benchmarks should only depend on base Julia.
- You'll need to use [BenchmarkTools](https://github.com/JuliaCI/BenchmarkTools.jl) to write the benchmarks (feel free to open a WIP PR if you'd like help with this).
- Newly defined functions whose calls are measured should have `perf_` prepended to their name. This makes it easier to find a given benchmark's "entry point" in the code.
- Try to reuse existing tags when possible. Tags should be lowercase and singular.
- If your benchmark requires a significant amount of code, wrap it in a module.

#### Which version of BaseBenchmarks is being used in CI?

New benchmarks added to BaseBenchmarks won't be present via CI right away, as
their execution parameters must be [tuned and
cached](https://juliaci.github.io/BenchmarkTools.jl/stable/manual/#Caching-Parameters)
on [Nanosoldier](https://github.com/JuliaCI/Nanosoldier.jl) (our benchmark
cluster) before they are suitable for running. This process is performed
periodically and upon request, after which the `master` branch is merged into
the [`nanosoldier`](https://github.com/JuliaCI/BaseBenchmarks.jl/tree/nanosoldier)
branch. Nanosoldier pulls down the `nanosoldier` branch before running every
benchmark job, so whatever's currently on the `nanosoldier` branch is what's
being used in CI.
