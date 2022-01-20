module AllocBenchmarks

using BenchmarkTools

const SUITE = BenchmarkGroup()

function perf_alloc_many_arrays()
  a = nothing
  for _ in 1:10000000
      a = []
  end
end

function perf_alloc_many_strings()
  a = nothing
  for i in 1:10000000
      a = "hello $(i)"
  end
end

SUITE["arrays"] = @benchmarkable perf_alloc_many_arrays()
SUITE["strings"] = @benchmarkable perf_alloc_many_strings()

end # module
