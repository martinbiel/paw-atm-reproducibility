module DayAheadBenchmarks

using HydroModels
using BenchmarkTools
using RecipesBase
using Colors

export
    DayAheadBenchmark,
    load_model,
    save_benchmark,
    load_benchmark,
    warmup_benchmarks!,
    run_benchmarks!,
    save_results!,
    load_results!,
    load_results,
    TimePlot,
    ScalingPlot

mutable struct DayAheadBenchmark
    names::Vector{String}
    ncores::Vector{Int}
    medians::Matrix{Float64}
    means::Matrix{Float64}
    strong_scaling::Matrix{Float64}
    benchmarks::BenchmarkGroup
    results::BenchmarkGroup

    function (::Type{DayAheadBenchmark})(names::Vector{String},ncores::Vector{Int},benchmarks::BenchmarkGroup)
        medians = zeros(length(ncores),length(names))
        means = zeros(length(ncores),length(names))
        strong_scaling = zeros(length(ncores),length(names))
        return new(names,ncores,medians,means,strong_scaling,benchmarks,BenchmarkGroup())
    end
end

function DayAheadBenchmark(ncores::Vector{Int},solvernames::Vector{String},solvers::Vector)
    length(solvernames) == length(solvers) || error("Inconsistent number of solvernames/solvers")
    benchmarks = BenchmarkGroup()
    for nscenario in ncores
        b = benchmarks[string(nscenario)] = BenchmarkGroup(solvernames)
        for (solvername,solver) in zip(solvernames,solvers)
            solve_time = @elapsed run_solver(nscenario,solver)
            max_time = min(100*solve_time,5000)
            b[solvername] = @benchmarkable plan!(da,optimsolver=$solver) seconds=max_time samples=100 setup=(da = load_model($nscenario))
        end
    end
    return DayAheadBenchmark(solvernames,ncores,benchmarks)
end

function load_model(ncores::Integer)
    dayahead_data = HydroModels.NordPoolDayAheadData("data/plantdata.csv","data/spotprices.csv",1,35.0,60.0)
    sampler = DayAheadSampler(dayahead_data)
    dayahead_model = DayAheadModel(dayahead_data,sampler,ncores,[:Skellefteälven])
    return dayahead_model
end

function run_solver(ncores::Integer,solver)
    dayahead_model = load_model(ncores)
    plan!(dayahead_model,optimsolver=solver)
end

function collect_estimates!(da_benchmark::DayAheadBenchmark)
    medians = time(median(da_benchmark.results))
    means = time(mean(da_benchmark.results))
    for (i,ncores) in enumerate(da_benchmark.ncores)
        for (j,solvername) in enumerate(da_benchmark.names)
            da_benchmark.medians[i,j] = medians[string(ncores)][solvername] / 1e9
            da_benchmark.means[i,j] = means[string(ncores)][solvername] / 1e9
            da_benchmark.strong_scaling[i,j] = da_benchmark.medians[1,j]/(ncores*da_benchmark.medians[i,j])*100
        end
    end
end

function save_benchmark(da_benchmark::DayAheadBenchmark, filename::String)
    BenchmarkTools.save(filename, da_benchmark.benchmarks)
end

function load_benchmark(filename::String)
    benchmarks = BenchmarkTools.load(filename)[1]
    ncores = [parse(key) for key in keys(benchmarks)]
    sort!(ncores)
    solvernames = [key for key in keys(first(benchmarks)[2])]
    da_benchmark = DayAheadBenchmark(solvernames,ncores,benchmarks)
    return da_benchmark
end

function warmup_benchmarks!(da_benchmark::DayAheadBenchmark)
    warmup(da_benchmark.benchmarks)
    nothing
end

function run_benchmarks!(da_benchmark::DayAheadBenchmark)
    da_benchmark.results = run(da_benchmark.benchmarks, verbose=true)
    collect_estimates!(da_benchmark)
    return da_benchmark.results
end

function save_results!(da_benchmark::DayAheadBenchmark, filename::String)
    BenchmarkTools.save(filename, da_benchmark.results)
    nothing
end

function load_results!(da_benchmark::DayAheadBenchmark, filename::String)
    da_benchmark.results = BenchmarkTools.load(filename)[1]
    collect_estimates!(da_benchmark)
    return da_benchmark.results
end

function load_results(filename::String)
    results = BenchmarkTools.load(filename)[1]
    ncores = [parse(key) for key in keys(results)]
    sort!(ncores)
    solvernames = [key for key in keys(first(results)[2])]
    da_benchmark = DayAheadBenchmark(solvernames,ncores,BenchmarkGroup())
    load_results!(da_benchmark, filename)
    return da_benchmark
end

struct TimePlot
    benchmark
end
@recipe function f(p::TimePlot)
    bresults = p.benchmark
    tmin = 0
    tmax = maximum(bresults.medians)
    increment = std(bresults.medians)

    linewidth --> 2
    tickfontsize := 10
    tickfontfamily := "sans-serif"
    guidefontsize := 10
    guidefontfamily := "sans-serif"
    legend := :topleft
    xticks := bresults.ncores
    xlabel := "Number of Scenarios N"
    ylabel := "Computation Time T [s]"
    ylims --> (tmin,tmax)
    yticks --> tmin:increment:tmax
    yformatter := (d) -> @sprintf("%.1f",d)

    colors = distinguishable_colors(length(bresults.names)+1,RGB(1,1,1))[2:end]
    for (i,solver) in enumerate(bresults.names)
        @series begin
            label --> solver
            seriescolor --> colors[i]
            bresults.ncores, bresults.medians[:,i]
        end
    end
end
struct ScalingPlot
    benchmark
end
@recipe function f(p::ScalingPlot)
    bresults = p.benchmark
    linewidth --> 2
    tickfontsize := 10
    tickfontfamily := "sans-serif"
    guidefontsize := 10
    guidefontfamily := "sans-serif"
    legend := :topright
    xticks := bresults.ncores
    xlabel := "Number of Cores P"
    ylabel := "Parallel Efficiency E [% of linear scaling]"
    ylims --> (0,100)
    yticks --> 0:10:100
    yformatter := (d) -> @sprintf("%.1f",d)

    colors = distinguishable_colors(length(bresults.names)+1,RGB(1,1,1))[2:end]
    for (i,solver) in enumerate(bresults.names)
        @series begin
            label --> solver
            seriescolor --> colors[i]
            bresults.ncores, bresults.strong_scaling[:,i]
        end
    end
end

end#module

srand(1) # Random seed

using DayAheadBenchmarks
using LShapedSolvers
using Gurobi
using Clp

prepare_sbenchmark() = prepare_sbenchmark([5, 10, 50, 100, 200, 300])
function prepare_sbenchmark(nscenarios::Vector{Int})
    # Create solvers (To use Clp instead, Switch out GurobiSolver calls to ClpSolver(PreSolve=2))
    gurobi = GurobiSolver(OutputFlag=0)
    ls = LShapedSolver(:ls,GurobiSolver(OutputFlag=0),log=false)
    rd = LShapedSolver(:rd,GurobiSolver(OutputFlag=0),crash=Crash.EVP(),log=false,autotune=true,linearize=true)
    tr = LShapedSolver(:tr,GurobiSolver(OutputFlag=0),log=false,autotune=true)
    lv = LShapedSolver(:lv,GurobiSolver(OutputFlag=0),log=false,linearize=true)
    solvers = [gurobi,ls,rd,tr,lv]
    solvernames = ["Gurobi","L-shaped","Linearized Regularized","Trust-region","Linearized Level set"]
    # Create Day-ahead benchmark
    return DayAheadBenchmark(nscenarios,solvernames,solvers)
end

function prepare_dbenchmark()
    # Create solvers (To use Clp instead, Switch out GurobiSolver calls to ClpSolver(PreSolve=2))
    gurobi = GurobiSolver(OutputFlag=0)
    dls = LShapedSolver(:dls,GurobiSolver(OutputFlag=0),log=false,κ=1.0)
    drd = LShapedSolver(:drd,GurobiSolver(OutputFlag=0),crash=Crash.EVP(),log=false,autotune=true,linearize=true,κ=1.0)
    dtr = LShapedSolver(:dtr,GurobiSolver(OutputFlag=0),log=false,autotune=true,κ=1.0)
    dlv = LShapedSolver(:dlv,GurobiSolver(OutputFlag=0),log=false,linearize=true,κ=1.0)
    solvers = [dls,drd,dtr,dlv]
    solvernames = ["Distributed L-shaped","Distributed RD","Distributed TR","Distributed LV"]
    # Create Day-ahead benchmark
    return DayAheadBenchmark([1000],solvernames,solvers)
end
