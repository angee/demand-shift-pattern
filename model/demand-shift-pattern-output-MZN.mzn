% --------------------------------------------------------------------------------------- %
%      Demand-driven Delivery Staff Rostering
%
%         MINIZINC OUTPUT SPECIFICATION
%
% Author: Andrea Rendl, 2018 
%         
% Copyright (c) Satalia 2018
% Distributed under the MIT License. Please refer to the LICENSE file at:
% https://github.com/angee/demand-shift-pattern/LICENSE
% --------------------------------------------------------------------------------------- %


function array[int] of string: createMznOutput() = 
     [ printConstants() ]
 ++  [ printStartOfShift() ]   
 ++  [ printEndOfShift() ]
 ++  [ printShiftLength() ]
 ++  [ printDayOff() ]
 ++  [ printVehiclesOnShift() ]
 ++  [ "% objective = " ++ printObjectiveValue() ++ ";\n"]
 ;
 

function string: printStartOfShift() = 
   "startOfShift = \n\t[| " ++
   concat(
     [ show(fix(startOfShift[shift, day])) 
      ++  if day = SUNDAY /\ shift = shifts 
              then " |];\n"
          elseif day = SUNDAY 
              then "\n\t | "
          else ", "
          endif
     | shift in SHIFTS, day in WEEKDAYS ]
   )
;

function string: printEndOfShift() = 
   "endOfShift = \n\t[| " ++
   concat(
     [ show(fix(endOfShift[shift, day])) 
      ++  if day = SUNDAY /\ shift = shifts 
              then " |];\n"
          elseif day = SUNDAY 
              then "\n\t | "
          else ", "
          endif
     | shift in SHIFTS, day in WEEKDAYS ]
   )
;


function string: printShiftLength() = 
   "% shiftLength = \n%\t[| " ++
   concat(
     [ show(fix(shiftLength[shift, day])) 
      ++  if day = SUNDAY /\ shift = shifts 
              then " |];\n"
          elseif day = SUNDAY 
              then "\n%\t | "
          else ", "
          endif
     | shift in SHIFTS, day in WEEKDAYS ]
   )
;

function string: printDayOff() = 
   "% workingDay = \n%\t[| " ++
   concat(
     [ show(fix(workingDay[shift, day])) 
      ++  if day = SUNDAY /\ shift = shifts 
              then " |];\n"
          elseif day = SUNDAY 
              then "\n%\t | "
          else ", "
          endif
     | shift in SHIFTS, day in WEEKDAYS ]
   )
;


function string: printVehiclesOnShift() = 
   "vehiclesOnShift = \n\t[| " ++
   concat(
     [ show(fix(vehiclesOnShift[shift, vehicle])) 
      ++  if  shift = shifts /\ vehicle = vehicles
              then " |];\n"
          elseif vehicle = vehicles
              then "\n\t | "
          else ", "
          endif
     | shift in SHIFTS, vehicle in VEHICLES ]
   )
;

