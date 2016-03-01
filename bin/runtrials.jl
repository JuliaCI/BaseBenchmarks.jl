trialserr = open("trials.err", "w")
redirect_stderr(trialserr)

trialsout = open("trials.out", "w")
redirect_stdout(trialsout)

trialslog = open("trials.log", "w")

const times = (5.0, 5.0)
const group = "factorization eig"
const trials = 50

for i in 1:length(times)
    t = times[i]
    print(trialslog, now(), " | RUNNING $(trials) TRIALS AT T = $(t)..."); flush(trialslog)
    cmd = """
          using BaseBenchmarks;
          using JLD;
          t = $(t);
          trials = $(trials);
          group = GROUPS[\"$(group)\"];
          ntrials(group, 1, 1e-6; verbose = true);
          file = jldopen(\"trials_$(Int(t))_$(i).jld\", \"w\");
          write(file, \"trials\", ntrials(group, trials, t; verbose = true));
          close(file);
          """
    run(`$(homedir())/julia-dev/julia-0.5/julia -e $(cmd)`)
    println(trialslog, now(), "done."); flush(trialslog)
    sleep(60 * 30)
end

println(trialslog, now(), " | BENCHMARKING COMPLETE!"); flush(trialslog)

close(trialslog)
close(trialsout)
close(trialserr)
