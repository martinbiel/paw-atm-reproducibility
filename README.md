Artifact Description: Distributed L-shaped Algorithms in Julia
==============================================================

Abstract
--------

The following appendix describes the dependencies and experimental setup
used to generate the numerical results presented in the work titled **Distributed L-shaped Algorithms in Julia**.
Specifically, the generation of
Fig. 2, Fig. 3 and Fig. 4 is outlined to an extent where it should be possible to reproduce the
results, assuming similar hardware is available. The dependencies can either be installed by following the instructions outlined here, or by mounting a predefined docker file.

Description
-----------

### Check-list (artifact meta information)

-   **Algorithm: L-shaped**

-   **Program: Julia**

-   **Data set: `plantdata.csv`, `spotprices.csv`**

-   **Run-time environment: Archlinux**

-   **Hardware: 32-core machine**

-   **Execution: Serial, Parallel**

-   **Output: Serial and distributed benchmarks**

-   **Publicly available?: [Github](https://github.com/martinbiel)**

### How software can be obtained

All implemented code is available freely on
[Github](https://github.com/martinbiel):

-   HydroModels.jl: https://github.com/martinbiel/HydroModels.jl

-   StochasticPrograms.jl:
    https://github.com/martinbiel/StochasticPrograms.jl

-   LShapedSolvers.jl: https://github.com/martinbiel/LShapedSolvers.jl

-   TraitDispatch.jl: https://github.com/martinbiel/TraitDispatch.jl

The most convenient approach for reproducing results is to fetch the
modules directly into Julia, as shown in the installation section below.

### Hardware dependencies

The numerical experiments were performed on a server node (32 processing
cores in total) with the following specifications.

-   **Processor:** Two Intel Xeon E5-2687W (Eight Core, 3.10GHz Turbo,
    20MB, 8.0 GT/s)

-   **Memory:** 128GB (16x8GB) 1600MHz DDR3 ECC RDIMM

### Software dependencies

-   Julia v0.6.4

-   g++

-   make

-   Python 3.6.6 with matplotlib 2.2.2

-   Gurobi 7.0.2

-   Docker (optionally)

### Datasets

Two datasets were used. First, `plantdata.csv` contains physical
specifications for the hydroplants in the river Skellefteälven. This
data was first published in the following [Master thesis](http://kth.diva-portal.org/smash/record.jsf?pid=diva2%3A1215858&dswid=8071), in Table 1 and Table 2. Second, `spotprices.csv` should contain the hourly market price of electricity in the
Nordic region during 2017. This data is available at [NordPool](https://www.nordpoolgroup.com/globalassets/marketdata-excel-files/elspot-prices_2017_hourly_eur.xls). Note, that line 2022 has no price data. Either remove this line or interpolate from the surrounding data. Alternatively, the `spotprices.csv` in this repository contains dummy data that can be used instead.

Installation (Docker)
------------

A docker image with all necessary binaries is available named `mbiel/paw-atm-reproducibility`. To use it, install docker. Next, run

```
docker run --interactive --tty mbiel/paw-atm-reproducibility
```

After fetching the binaries a Julia prompt with all necessary libraries should appear, and one can proceed to follow the instructions in `reproducibility.jl`, i.e. the experiment workflow. Note, that it is not possible to redistribute Gurobi in docker, so the premade environment uses Clp instead. See the notes at the end of the document for a discussion of the consequences of using Clp.


Installation (Manual)
------------

The numerical experiments were performed on Julia version v0.6.4,
available at
[Github](https://github.com/JuliaLang/julia/releases/tag/v0.6.4). For
best performance, it is recommended to build Julia from source,
according to the instructions at the [Julia Github
page](https://github.com/JuliaLang/julia#source-download-and-compilation).
The required Julia packages are installed in Julia as follows:

``` julia
Pkg.add("JuMP")
Pkg.add("MacroTools")
Pkg.add("Parameters")
Pkg.add("Reexport")
Pkg.add("BenchmarkTools")
Pkg.add("ProgressMeter")
Pkg.add("PlotRecipes")
Pkg.add("Plots")
# Requires matplotlib
Pkg.add("PyPlot")
Pkg.add("Clp")
# Requires Gurobi to be installed with a valid license
Pkg.add("Gurobi")

```

The plots in this work were generated with the PyPlot backend, which
requires matplotlib to be installed. A Clp binary will be installed
automatically by the above command. However, all results in this work
were generated using Gurobi version 7.0.2, which needs to be installed
separately along with a valid license. Gurobi has free licenses available
for academic users. The user made Julia modules used
to generate the results in this work are installed as follows:

``` julia
Pkg.clone(
"https://github.com/martinbiel/TraitDispatch.jl.git")
Pkg.clone(
"https://github.com/martinbiel/StochasticPrograms.jl.git")
Pkg.clone(
"https://github.com/martinbiel/HydroModels.jl.git")
Pkg.clone(
"https://github.com/martinbiel/LShapedSolvers.jl.git")

```

which fetches and install the packages from Github. Before starting, it
is advised to precompile the installed packages as follows:

``` julia
using JuMP
using BenchmarkTools
using Clp
using Gurobi
using StochasticPrograms
using HydroModels
using LShapedSolvers

```

The full installation procedure of Julia and all the required packages
can be expected to take a while, up to a couple of hours on a bare
setup. This repository contains auxilliary files to simplify the reproducibility process.

Experiment workflow
-------------------

To reproduce the results presented in Fig. 2, Fig. 3 and Fig. 4, run the code blocks in `reproducibility.jl`. In summary, the workflow is as follows:

``` julia
include("dayahead_benchmark.jl")

```

to load auxilliary functions for benchmarking the day-ahead test
problems. The functions expect a `data` folder in the same directory
where `plantdata.csv` and `spotprices.csv` are located. Next,

``` julia
serial_benchmark = prepare_sbenchmark()
warmup_benchmarks!(serial_benchmark)

```

The above prepares the serial benchmarks. This runs through all
benchmarks to ensure they are compiled and to get a sense of how long
time they require. Finally,

``` julia
run_benchmarks!(serial_benchmark)
save_results!(serial_benchmark,"serial_benchmarks.json")

```

runs the benchmark and saves the results. This is a lengthy process
which typically takes hours. For each problem size, the benchmark has
each algorithm solving the problem about 100 times and samples the
required computation time. For distributed benchmarks, Julia processes
have to be added to create worker cores through `addprocs`. For example,

``` julia
addprocs(2)
include("dayahead_benchmark.jl")
distributed_benchmark = prepare_dbenchmark()
warmup_benchmarks!(distributed_benchmark)
run_benchmarks!(distributed_benchmark)
save_results!(distributed_benchmark,"scaling_2.json")

```

runs benchmarks of the distributed algorithms with two worker cores.

Evaluation and expected result
------------------------------

Following the instructions in `reproducibility.jl` should produce results akin to the ones
presented in Fig. 2, Fig. 3, and Fig. 4. These results are available as JSON files in the results folder as well. The presented results can be regenerated as follows
``` julia
using Plots
pyplot()
serial_benchmark = load_results("results/serial_benchmarks.json")
plot(TimePlot(serial_benchmark)) # Produces Fig. 2
distributed_benchmark = load_results("results/distributed_benchmarks.json")
plot(TimePlot(serial_benchmark)) # Produces Fig. 3
plot(ScalingPlot(serial_benchmark)) # Produces Fig. 4

```

Experiment customization
------------------------

The serial and distributed L-shaped algorithms evaluated in the
benchmarks are created in the functions `prepare_sbenchmark` and `prepare_dbenchmark`. The keyword arguments
supplied to the solver calls can be changed for experiment
customization. For example, removing the `linearize=true` in the `lv` creation will revert to
using a 2-norm term in the level-set solver. Use `?LShapedSolver` in the Julia prompt
after `using LShapedSolvers` for helper documentation that explains how to create and
parametrize L-shaped solvers. For information about the the tunable
parameters, and their default values, each algorithm has a separate
docstring accessible through `?`. For example, run `?LShaped`. All available docstrings
are listed by `?LShapedSolver`.

Notes
-----

If a Gurobi license is not available, the open-source Clp solver could
be used as a subsolver instead. However, convergence issues have been
observed if it is used as is. Successful results were obtained by
choosing a lower presolve level in Clp. The reason for this is not
known. To use Clp instead, replace each `GurobiSolver(OutputFlag=0)` in `dayahead_benchmark.jl`to `ClpSolver(Presolve=2)`. This yields a
significant decrease in performance, so the presented computational
results are not expected to be reproduced.
