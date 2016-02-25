trialserr = open("trials.err", "w")
redirect_stderr(trialserr)

trialsout = open("trials.out", "w")
redirect_stdout(trialsout)

trialslog = open("trials.log", "w")

using BaseBenchmarks
using JLD

const times = (5.0,)
const group = ENSEMBLE["factorization eig"]
const trials = 50

println(trialslog, now(), " | WARMING UP BENCHMARKS..."); flush(trialslog)
ntrials(group, 1, 1e-6; verbose = true)

for t in times
    println(trialslog, now(), " | RUNNING $(trials) TRIALS AT T = $(t)..."); flush(trialslog)
    jldopen("trials$(Int(t)).jld", "w") do file
        write(file, "trials", ntrials(group, trials, t; verbose = true))
    end
end

println(trialslog, now(), " | BENCHMARKING COMPLETE!"); flush(trialslog)

close(trialslog)
close(trialsout)
close(trialserr)
