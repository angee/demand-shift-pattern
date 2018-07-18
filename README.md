# demand-shift-pattern

This repository provides a MiniZinc model for demand-driven delivery staff rostering.
To run and solve the models, see the instructions below.

### Demand-driven delivery staff rostering

Demand-driven delivery staff rostering deals with finding a roster (or shift pattern)
for drivers in a delivery company. The objective is to find shift patterns that maximally
align with the expected demand to avoid over- and under-employment of staff.

### Files

This repository provides the following files:

      LICENSE                      license file (MIT license)
      demand-shift-pattern.mzn     the main model file
      model/                       directory with further model parts
      data/                        directory with benchmarks
      
### How to run the model

To run and solve the problem, install MiniZinc from [http://minizinc.org](http://minizinc.org),
where we recommend the bundled version. Then start the MiniZincIDE, and open the main model
file `demand-shift-pattern.mzn` and a data file from the `/data` directory. To solve that
problem, click on "Run" and select the respective data file when queried.

Another option is to solve the problem on the command line, after installing MiniZinc.
For instance, by typing the following into your terminal:

      mzn-cbc -Glinear demand-shift-pattern.mzn data/v12_s2_linear.dzn
      
which will run the MIP solver COIN-OR cbc on the problem with the `v12_s2_linear.dzn`
data file.