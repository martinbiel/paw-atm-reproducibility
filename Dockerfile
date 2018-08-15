FROM  julia:0.6.4
RUN   apt-get update
RUN   apt-get install -y g++ libopenblas-base make python3
COPY  data results dayahead_benchmark.jl reproducibility.jl $HOME/
RUN   julia --eval 'Pkg.add("JuMP");\
		    Pkg.add("MacroTools");\
		    Pkg.add("Parameters");\
		    Pkg.add("Reexport");\
		    Pkg.add("BenchmarkTools");\
		    Pkg.add("ProgressMeter");\
		    Pkg.add("Plots");\
		    Pkg.add("PlotRecipes");\
		    Pkg.add("Clp")'
RUN   julia --eval 'Pkg.clone("https://github.com/martinbiel/TraitDispatch.jl.git");\
		    Pkg.clone("https://github.com/martinbiel/StochasticPrograms.jl.git");\
		    Pkg.clone("https://github.com/martinbiel/HydroModels.jl.git");\
		    Pkg.clone("https://github.com/martinbiel/LShapedSolvers.jl.git")'
RUN   julia --eval 'include("dayahead_benchmark.jl")'
