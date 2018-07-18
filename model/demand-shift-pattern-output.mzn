% --------------------------------------------------------------------------------------- %
%      Demand-driven Delivery Staff Rostering
%
%               OUTPUT SPECIFICATION
%
% Author: Andrea Rendl, 2018 
%         
% Copyright (c) Satalia 2018
% Distributed under the MIT License. Please refer to the LICENSE file at:
% https://github.com/angee/demand-shift-pattern/LICENSE
% --------------------------------------------------------------------------------------- %

% -------- helper functions for output --------- %

include "demand-shift-pattern-output-MZN.mzn";

% there are two output types:
% TEXT: normal readable text format
%  MZN: MiniZinc format for solution validation
enum OutputType = {TEXT, MZN};

% the standard separator in CSV files
string: separator = "\t";

% ---------------- output ---------------------- %

function array[int] of string: createOutput() = 
   if outputType = TEXT 
      then createTextOutput()
   elseif outputType = MZN
      then createMznOutput()
   else [""] 
   endif;


function array[int] of string: createTextOutput() =
 [ printConstants() ++ "\n"]
 ++
 [ printShift(shift) | shift in SHIFTS ]
  ++ ["\n"] ++
 [ printDriversPerShift(shift) | shift in SHIFTS]
 ++ ["\n"] ++ 
 [ printVehicleHours(day) | day in WEEKDAYS ]
 ++ ["\n"] ++
 [printObjective() ]
 ++
 ["\n=====================================================================================\n"]
;



% ================================================================================ %

% prints the shift start and end time for each day for a given shift
function string: printShift(int: shift) = 
 concat(  ["\nShift" ++ show(shift) ++ ":\n"] ++
          [ toWeekday(day) ++ ":   \t" ++
            if fix(startOfShift[shift,day]) = fix(endOfShift[shift,day]) then
               "    ---     "
            else    toTimeString(toTime(fix(startOfShift[shift,day]))) 
                    ++ " - " ++ toTimeString(toTime(fix(endOfShift[shift,day])))
            endif
            ++ "\t-> " ++ show(toTime(fix(shiftLength[shift,day]))) ++ " hours\n"
            | day in WEEKDAYS ] ++
          [ "--------------------------------------------------\nWORKING HOURS per week = " 
             ++ show(sum (day in WEEKDAYS) (toTime(fix(shiftLength[shift,day])))
                      - toTime(sum(day in WEEKDAYS) ( (fix(workingDay[shift,day]))*timeFactor)))  
             ++ " hours\n--------------------------------------------------\n"]
 );


function string: printDriversPerShift(int: shift) =
  "Vehicles on Shift " ++ show(shift) ++ ": " 
                       ++ show( sum(vehicle in VEHICLES) (fix(vehiclesOnShift[shift,vehicle])) ) ++ "\n";
                       
                    
function string: printDaysOff(int: shift) = 
  "\nDays off on Shift " ++ show(shift) ++ ":\n"
                       ++ concat([ toWeekday(day) ++ ":    \t" 
                                   ++ if fix(workingDay[shift,day]) = 0 then 
                                         "off\n"
                                      else "working\n"
                                      endif
                                  | day in WEEKDAYS])
;

function string: printVehicleHours(Day: day) = 
   toWeekday(day) ++ ":    \t" 
                  ++ show( fix(vehicleHours[day] / timeFactor))
                  ++ " vehicle-hours (excl. lunch breaks)," 
                  ++ "\t servicing " ++ show_float(1,2, getAverageNumberOfServicedCustomers(day))                                                  
                                                    ++ " orders on average. Difference in demand: " ++
                                                    show(fix(averageServicedOrders[day]) - estimatedOrders[day])
                                                    ++ "\n"                
;

function float: getAverageNumberOfServicedCustomers(Day: day) = 
ordersServicedPerVehiclePerHour * 
   (fix(vehicleHours[day])
    -  2* stemTime * sum(shift in SHIFTS) (fix(workingDay[shift, day] 
                  * sum (vehicle in VEHICLES) (vehiclesOnShift[shift,vehicle]) )) 
);
  
         
function string: printObjective() = 
      "\nobjective = " ++ printObjectiveValue()
                     ++ 
      "\n\nobjective in detail = \n" ++ 
       concat([ printObjectiveDetails(day) | day in WEEKDAYS where day != SUNDAY ]);
         
function string: printObjectiveValue() = 
      show_float(1,7,obj);                 
                        
function string: printObjectiveDetails(Day: day) =
      toWeekday(day) ++ "   \t" 
                    ++ if objectiveType = MIN_WEIGHTED_UNMET_DEMAND 
                         then 
                           "= " ++ show_float(1,6, getObjectiveValueForDay(day)) 
                           ++ "\t(weight: " ++ show(weight[day]) 
                           ++ " *  unmetDemand " ++ show((fix(unmetDemand[day])))
                           ++ ")"
                       else "unmetDemand = " ++ show((fix(unmetDemand[day])))
                       endif               
                    ++ ";\n"                                    
 ;  

% returns the objective value for a single day
function float: getObjectiveValueForDay(Day: day) = 
   if objectiveType = MIN_MAX_UNMET_DEMAND then
      fix(maxUnmetDemand)
   else 
       weight[day] * (fix(unmetDemand[day])) 
   endif;


% returns the value of the objective obj for day 
function float: getObjectivePartValue(ObjectiveType: obj, Day: day) =
   if objectiveType = MIN_MAX_UNMET_DEMAND then 
       fix(maxUnmetDemand)
   else
           weight[day] * (fix(unmetDemand[day])) 
   endif;

% prints the objective value for a given objective for a given day
function string: printObjectivePart(ObjectiveType: obj, Day: day) =
   if objectiveType = MIN_MAX_UNMET_DEMAND then 
           show(fix(maxUnmetDemand)) ++ " > " ++ show((fix(unmetDemand[day])))
   else
           show(weight[day]) ++ " * " ++ show((fix(unmetDemand[day])))
   endif;
      
   
function string: printShiftTable() = 
  concat([ "vehicles-shift-" ++ show(shift) ++ separator | shift in SHIFTS]) ++ "\n"
  ++ concat([ show(sum(vehicle in VEHICLES) (fix(vehiclesOnShift[shift,vehicle]))) ++ separator
              | shift in SHIFTS])
  ++ "\n"
;

function string: printConstants() = 
  if outputType = TEXT then 
       "shifts = " ++ show(shifts) ++ ";\n"
    ++ "weights = " ++ show(weight) ++ ";\n"
    ++ "timeFactor = " ++ show(timeFactor) ++ ";\n"
    ++ "dayWeights = [" ++ concat([ show_float(1,2,fix(weight[day])) ++ ", " | day in WEEKDAYS])  ++ "];\n"
    ++ "estimatedOrders = [" ++ concat([ show(estimatedOrders[day]) ++ ", " | day in WEEKDAYS ]) ++ "];\n"
    ++ "demandAsPercentage = [" ++ concat([ show(demandAsPercentage[day]) ++ ", " | day in WEEKDAYS ]) ++ "];\n"
  elseif outputType = MZN then 
    "shifts = " ++ show(shifts) ++ ";\n"
    ++ "OPTIONAL_CONSTRAINTS = " ++ "{"++ concat([ constraintToString(ct) ++ ", " 
                                               | ct in OPTIONAL_CONSTRAINTS]) ++ "};\n"
    ++ "% weight = " ++ show(weight) ++ ";\n"
    ++ "% timeFactor = " ++ show(timeFactor) ++ ";\n"
    ++ "% weights = [" ++ concat([ show_float(1,2,fix(weight[day]))
                                    ++ if day = SUNDAY then "" else ", " endif
                                    | day in WEEKDAYS])  ++ "];\n"
    ++ "estimatedOrders = [" ++ concat([ show(estimatedOrders[day]) 
                                ++ if day = SUNDAY then "" else ", " endif 
                                | day in WEEKDAYS ]) ++ "];\n"
    ++ "stemTime = " ++ show(stemTime) ++ ";\n"
    ++ "lunchbreak = " ++ show(lunchbreak) ++ ";\n" 
    ++ "ordersServicedPerVehiclePerHour = " ++ show_float(1,4,ordersServicedPerVehiclePerHour) ++ ";\n" 
  else ""
  endif
;


