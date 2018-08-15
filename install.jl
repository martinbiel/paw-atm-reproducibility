# Install (Julia 0.6.4)
Pkg.add("JuMP")
Pkg.add("MacroTools")
Pkg.add("Parameters")
Pkg.add("Reexport")
Pkg.add("BenchmarkTools")
Pkg.add("ProgressMeter")
Pkg.add("Plots") # Requires matplotlib
Pkg.add("PlotRecipes")

# Solvers (Gurobi requires license)
Pkg.add("Clp")
Pkg.add("Gurobi")

Pkg.clone("https://github.com/martinbiel/TraitDispatch.jl.git")
Pkg.clone("https://github.com/martinbiel/StochasticPrograms.jl.git")
Pkg.clone("https://github.com/martinbiel/HydroModels.jl.git")
Pkg.clone("https://github.com/martinbiel/LShapedSolvers.jl.git")

using JuMP
using BenchmarkTools
using Clp
using Gurobi
using StochasticPrograms
using HydroModels
using LShapedSolvers
