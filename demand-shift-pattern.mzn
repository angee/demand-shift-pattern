% --------------------------------------------------------------------------------------- %
%      Demand-driven Delivery Staff Rostering
%
% Author: Andrea Rendl, 2018 
%         
% Copyright (c) Satalia 2018
% Distributed under the MIT License. Please refer to the LICENSE file at:
% https://github.com/angee/demand-shift-pattern/LICENSE
% --------------------------------------------------------------------------------------- %

OutputType: outputType = TEXT;   % choose from TEXT and MZN

% includes the basic constants, parameters, variables and constraints
include "model/demand-shift-pattern-core.mzn";

% ---------------- objective ------------------- %

solve minimize obj;

% ---------------- output ---------------------- %

include "model/demand-shift-pattern-output.mzn";
output createOutput();