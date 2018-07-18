% --------------------------------------------------------------------------------------- %
%      Demand-driven Delivery Staff Rostering
%
%                PROBLEM PARAMETERS
%
% Author: Andrea Rendl, 2018 
%         
% Copyright (c) Satalia 2018
% Distributed under the MIT License. Please refer to the LICENSE file at:
% https://github.com/angee/demand-shift-pattern/LICENSE
%
%
% Only change the figures in this file if you really know what you are doing.
% --------------------------------------------------------------------------------------- %

% ================ SHIFT PATTERNS ==================================================== %

% the number of weeks the shift pattern may take (or the number of shiftpatterns)
int: shifts;
set of int: SHIFTS = 1..shifts; 

% is 1 if driver d is assigned to work in the first week in shift s
array[VEHICLES] of SHIFTS: vehiclesShift = [ ((v-1) div (vehicles div shifts) + 1)
                                             | v in VEHICLES];
array[SHIFTS, VEHICLES] of 0..1: vehiclesOnShift = array2d(SHIFTS, VEHICLES, 
                                                   [ if vehiclesShift[v] == s 
                                                       then 1 
                                                     else 0 endif  
                                                         | s in SHIFTS, v in VEHICLES]);

constraint 
   assert(shifts > 0, "shifts must be greater than zero.\n");

% ============== DEMAND =============================================================== %

% this is the estimated demand per day in number of orders
array[WEEKDAYS] of int: demand;

% ======================= OBJECTIVE =================================================== %

% the type of objective to use. Choose from: MIN_MAX_UNMET_DEMAND and MIN_WEIGHTED_UNMET_DEMAND
ObjectiveType: objectiveType; 

% The weights are used to reflect the importance of each day. The higher the factor for day d,
% the more improving the objective for day d will add to the overall objective. Improving the
% days with lower factors will result in less overall improvement, this way, high factor days
% will be improved MORE than low factor days. This has been added to incorporate the wish to 
% put particular emphasis on Thursday, Friday and Saturday.
% NOTE: Only the weighted objective considers the weights.
% NOTE: the sum of the weights should be equal to 1.

int: sumOfEstimatedOrders = sum (day in WEEKDAYS) (estimatedOrders[day]);
array[WEEKDAYS] of float: weight = [  0.1666666667 % the same for every day from Mon-Sat
                                      | day in WEEKDAYS ];
constraint
  forall (day in WEEKDAYS) ( 
     assert(weight[day] >= 0.0,
            "weight for day " ++ toWeekday(day) ++ " must be greater than zero instead of " 
            ++ show(weight[day]) ++ ".\n")
  );
constraint
  forall (day in WEEKDAYS) ( 
     assert(weight[day] <= 1.0,
            "weight for day " ++ toWeekday(day) ++ " must be smaller or equal 1 instead of " 
            ++ show(weight[day]) ++ ".\n")
  );

% ============== FLAG THAT MUST BE SET WHEN VALIDATING CURRENT SHIFT PATTERN =========== % 
  
% set this constant to 'true' if you are validating the original solution
% NOTE: this must be set to 'false' if you are trying to compute new solutions!
bool: validatingOriginalSolution = false;  
