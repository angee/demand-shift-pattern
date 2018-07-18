% --------------------------------------------------------------------------------------- %
%      Demand-driven Delivery Staff Rostering
%
%                 CORE PROBLEM MODEL
%
% Author: Andrea Rendl, 2018 
%         
% Copyright (c) Satalia 2018
% Distributed under the MIT License. Please refer to the LICENSE file at:
% https://github.com/angee/demand-shift-pattern/LICENSE
% --------------------------------------------------------------------------------------- %

% ===================== CONSTANTS ================================================= %

include "demand-shift-pattern-constants.mzn";

% ===================== PARAMETERS ================================================ %

include "demand-shift-pattern-parameters.mzn";

% ===================== VARIABLES ================================================= %
  
% the number of orders that cannot be met per day, either because there is too little 
% of too high capacity              
array[WEEKDAYS] of var 0.0..maxOrdersServicablePerDay : unmetDemand;

% the variable representing the objective
var 0.0..upperBoundForObjective: obj;
float: upperBoundForObjective = sum (day in WEEKDAYS) ( estimatedOrdersFloat[day] ); 
                              
% variable that represents the offset from the unmet demand                                                              
var 0.0..max(estimatedOrdersFloat): maxUnmetDemand;

% for each day, contains the capacity, in other words, the number of hours vehicles 
% are active on that day with the computed shift pattern)
array[WEEKDAYS] of var 0..maxWorkingHoursPerDay*vehicles: vehicleHours;

% the start time of each shift on each day for each shift
array[SHIFTS,WEEKDAYS] of var min(earliestStartTime)..max(latestEndTime): startOfShift;

% the end time of each shift on each day for each shift
array[SHIFTS,WEEKDAYS] of var min(earliestStartTime)..max(latestEndTime): endOfShift;

% the length of shift s on day d
array[SHIFTS, WEEKDAYS] of var 0..maxWorkingHoursPerDay: shiftLength;

% this  variable is `1' if the day d in shift s is a working day, and `0' otherwise
array[SHIFTS, WEEKDAYS] of var 0..1: workingDay;

% the  average number of orders that can be serviced by the shift pattern
array[WEEKDAYS] of var 0.0..maxWorkingHoursPerDay*vehicles: averageServicedOrders;

% ===================== CONSTRAINTS ================================================= %

% includes the constraint types
include "demand-shift-pattern-constraints.mzn";
        
% ---------------- shift length constraints ------------- %

% shifts may not start before the earliest start time
constraint 
  forall (shift in SHIFTS, day in WEEKDAYS) (
     startOfShift[shift,day] >= earliestStartTime[day]
  );
 
% shifts have to end before the latest end time
constraint 
  forall (shift in SHIFTS, day in WEEKDAYS) (
     endOfShift[shift,day] <= latestEndTime[day]
  );  
  
% the end time of a shift is AFTER (or equal) the start time of the shift
constraint 
  forall (shift in SHIFTS, day in WEEKDAYS) (
     endOfShift[shift,day] >= startOfShift[shift,day]
  );  

% the length of shift s on day d is the end time minus the start time
constraint 
   forall (shift in SHIFTS, day in WEEKDAYS) (
     shiftLength[shift, day] = endOfShift[shift,day] - startOfShift[shift, day]
   );

% if the shift is not empty, it has to have a minimal length
constraint
  if MinimalDailyShiftLength in OPTIONAL_CONSTRAINTS then
   
   forall (shift in SHIFTS, day in WEEKDAYS) (
      shiftLength[shift,day] >= minimalDailyShiftLength * workingDay[shift,day]
   )
   
  else true endif;


% the shift has to start at the same time each day, with the exception of Monday
% (because that is when the depot opens late)
constraint 
  if ShiftsInWeekStartAtSameTime in OPTIONAL_CONSTRAINTS then
  
  forall (shift in SHIFTS, day in WEEKDAYS 
                            where day != MONDAY /\ day != SUNDAY) (
     startOfShift[shift, day] = startOfShift[shift, next(day)]
  )
  
  else true
  endif;


% -------------- general shift constraints -------------- %
   
% no shift on Sunday
constraint 
  if NoShiftsOnSunday in OPTIONAL_CONSTRAINTS then 
  
   sum (shift in SHIFTS) (shiftLength[shift, SUNDAY]) = 0
   
  else true 
  endif;

% ------------- working hours constraints ---------------- %

% each weekly shift should have a minimum of working hours    
constraint 
  if MinimalWeeklyShiftLength in OPTIONAL_CONSTRAINTS then
  
   forall (shift in SHIFTS) (
       sum (day in WEEKDAYS) ( shiftLength[shift, day] ) 
          -  sum(day in WEEKDAYS) ( workingDay[shift,day]*lunchbreak) % minus lunch-hour break per working day
          >= minimalWeeklyShiftLength 
   )
   
   else true
   endif;

% the average working time in shift patterns have to sum up to the number of paid working hours
constraint 
   sum (shift in SHIFTS, day in WEEKDAYS) 
      ( shiftLength[shift, day] ) 
         -  sum(shift in SHIFTS, day in WEEKDAYS) ( workingDay[shift,day]*lunchbreak) % minus lunch-hour break per working day
        = paidWorkingHoursPerWeek * shifts 
;  


% the weekly working hours in every shift may not exceed the legal maximal number of weekly working hours
constraint 
  if MaximalWorkingHoursPerWeek in OPTIONAL_CONSTRAINTS then
  
   forall (shift in SHIFTS) ( 
      sum (day in WEEKDAYS) (shiftLength[shift, day]) 
      -  sum(day in WEEKDAYS) ( workingDay[shift,day]*lunchbreak) % minus lunch-hour break per working day
        <= maxWorkingHoursPerWeek 
   )
   
   else true 
   endif; 


% ------------- days off constraints --------------------- %

% a day is considered a working day if the shiftLength is greater than zero.
constraint
   forall(shift in SHIFTS, day in WEEKDAYS) (
      % workingDay[shift, day] = (shiftLength[shift, day] > 0)
      % bigM formulation instead:
      shiftLength[shift, day] <= M * workingDay[shift,day] 
   );
   
% drivers should only work every other Saturday
constraint 
 if HolidayEveryOtherSaturday in OPTIONAL_CONSTRAINTS then 
    
   forall(shift in SHIFTS where shift != shifts) (
        workingDay[shift, SATURDAY] + workingDay[shift+1,SATURDAY] <= 1 
   )
   /\
   sum (shift in SHIFTS) (workingDay[shift, SATURDAY]) <= shifts div 2
   
 else true 
 endif;
   
% 45 hour break (=2 days) at the end od each working week in a shift pattern
constraint 
   forall(shift in SHIFTS where shift != shifts) (
         ( 
           bool2int(workingDay[shift,SATURDAY] + workingDay[shift,SUNDAY] = 0)
           +
           bool2int(workingDay[shift,SUNDAY] + workingDay[shift+1,MONDAY] = 0)
           +
           bool2int(workingDay[shift+1,MONDAY] + workingDay[shift+1,TUESDAY] = 0)
           = 1
         )
   );
constraint 
   bool2int(workingDay[shifts,SATURDAY] + workingDay[shifts,SUNDAY] = 0)
   + 
   % day off on Sunday of the last shift pattern and on Monday of the first shift pattern
   bool2int(workingDay[shifts,SUNDAY] + workingDay[1,MONDAY] = 0)
    +
   bool2int(workingDay[1,MONDAY] + workingDay[1,TUESDAY] = 0)
   = 1
;


% ---------------- demand-related constraints ----------- %

% setting the number of vehicle hours per day (and subtracting the lunch breaks) 
constraint 
   forall (day in WEEKDAYS) (
      vehicleHours[day] 
         = sum (shift in SHIFTS, vehicle in VEHICLES) (
               vehiclesOnShift[shift, vehicle] * (shiftLength[shift, day]) 
           ) 
           % minus lunch-hour break per working day 
           - sum (shift in SHIFTS) (               
                  workingDay[shift, day] * sum (vehicle in VEHICLES) (vehiclesOnShift[shift,vehicle]) * lunchbreak
                  ) 
   );
  

constraint 
  forall (day in WEEKDAYS) (
  averageServicedOrders[day] = 
    ordersServicedPerVehiclePerHour * 
       (vehicleHours[day] 
         % minus the stem time
         -  2* stemTime * sum(shift in SHIFTS) 
                                 (workingDay[shift, day] 
                                    * sum (vehicle in VEHICLES) (vehiclesOnShift[shift,vehicle]) ) )
  );

% stating that the maximal unmet demand must be larger than each unmet demand.
constraint
forall (day in WEEKDAYS) (
      maxUnmetDemand > unmetDemand[day]
    );

% ===================== OBJECTIVE ================================================= %

% contains the objectives that are sought to be minimised
enum ObjectiveType = { MIN_MAX_UNMET_DEMAND, % minimise the maximial unmet demand
                       MIN_WEIGHTED_UNMET_DEMAND % minimise the sum of all unmet demands, weighted per day
                     };   
              
constraint obj = if objectiveType = MIN_MAX_UNMET_DEMAND then 
                     objectiveNoWeights()
                 else 
                     objective()
                 endif;

array[WEEKDAYS] of float: estimatedOrdersFloat = [ int2float(estimatedOrders[day]) | day in WEEKDAYS ];    
constraint 
   forall(day in WEEKDAYS) (
       unmetDemand[day] = abs(estimatedOrdersFloat[day] - averageServicedOrders[day])
   );
  
                             
                                                                  
function var float: objective() = 
    sum (day in WEEKDAYS) (
        unmetDemand[day] * weight[day]
    );
    
function var float: objectiveNoWeights() = maxUnmetDemand;