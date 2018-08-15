# Install Julia 0.6.4 and then run
# include("install.jl") (Only once)
# to install all required packages.

# It is not advised to run this file directly. Rather, start a fresh
# Julia session and run the code between the "================================"
# delimeters. Afterwards, start a fresh Julia session and run the next block.
# This is to ensure that the number of worker processes is correct. Also,
# each block will require a couple of hours to finish.

# For customization, the parameter arguments can be changed/supplied in the
# of the L-shaped solvers in dayahead_benchmark.jl. Use `?LShapedSolver`
# in Julia prompt after `using LShapedSolvers` for a docstring on its usage.
# The parameters and default value of each algorithm is accessed by for example
# `?LShaped`.

# Serial benchmarks. Used to generate Fig. 2
# ================================ #
include("dayahead_benchmark.jl")
serial_benchmark = prepare_sbenchmark()
warmup_benchmarks!(serial_benchmark)
run_benchmarks!(serial_benchmark) # Takes a couple of hours
save_results!(serial_benchmark,"serial_benchmarks.json")
# Plotting
using Plots
pyplot()
p = plot(TimePlot(serial_benchmark)) # Creates Fig. 2
savefig(p,"serial_benchmarks.pdf")
# ================================ #

# Distributed benchmarks. Used to generate Fig. 3 and Fig. 4
# ================================ #
# No worker cores (serial)
include("dayahead_benchmark.jl")
distributed_benchmark = prepare_dbenchmark()
warmup_benchmarks!(distributed_benchmark)
run_benchmarks!(distributed_benchmark) # Takes a couple of hours
save_results!(distributed_benchmark,"scaling_1.json")
# ================================ #
# 2 worker cores
addprocs(2)
include("dayahead_benchmark.jl")
distributed_benchmark = prepare_dbenchmark()
warmup_benchmarks!(distributed_benchmark)
run_benchmarks!(distributed_benchmark) # Takes a couple of hours
save_results!(distributed_benchmark,"scaling_2.json")
# ================================ #
# 4 worker cores
addprocs(4)
include("dayahead_benchmark.jl")
distributed_benchmark = prepare_dbenchmark()
warmup_benchmarks!(distributed_benchmark)
run_benchmarks!(distributed_benchmark) # Takes a couple of hours
save_results!(distributed_benchmark,"scaling_4.json")
# ================================ #
# 8 worker cores
addprocs(8)
include("dayahead_benchmark.jl")
distributed_benchmark = prepare_dbenchmark()
warmup_benchmarks!(distributed_benchmark)
run_benchmarks!(distributed_benchmark) # Takes a couple of hours
save_results!(distributed_benchmark,"scaling_8.json")
# ================================ #
# 16 worker cores
addprocs(16)
include("dayahead_benchmark.jl")
distributed_benchmark = prepare_dbenchmark()
warmup_benchmarks!(distributed_benchmark)
run_benchmarks!(distributed_benchmark) # Takes a couple of hours
save_results!(distributed_benchmark,"scaling_16.json")
# ================================ #
# Collect all distributed benchmarks and plot
distributed_benchmark = load_results!("scaling_1.json")
distributed_benchmark.results["1"] = copy(distributed_benchmark.results["1000"])
delete!(distributed_benchmark.results, "1000")
scaling_2 = load_results!("scaling_2.json")
distributed_benchmark.results["2"] = copy(scaling_2.results["1000"])
scaling_4 = load_results!("scaling_4.json")
distributed_benchmark.results["4"] = copy(scaling_4.results["1000"])
scaling_8 = load_results!("scaling_8.json")
distributed_benchmark.results["8"] = copy(scaling_8.results["1000"])
scaling_16 = load_results!("scaling_16.json")
distributed_benchmark.results["16"] = copy(scaling_16.results["1000"])
using Plots
pyplot()
p = plot(TimePlot(distributed_benchmark)) # Creates Fig. 3
savefig(p,"strong_scaling_comptime.pdf")
p = plot(ScalingPlot(distributed_benchmark)) # Creates Fig. 4
savefig(p,"strong_scaling_efficiency.pdf")
# ================================ #
