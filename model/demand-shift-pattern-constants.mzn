% --------------------------------------------------------------------------------------- %
%      Demand-driven Delivery Staff Rostering
%
%                 PROBLEM CONSTANTS
%
% Author: Andrea Rendl, 2018 
%         
% Copyright (c) Satalia 2018
% Distributed under the MIT License. Please refer to the LICENSE file at:
% https://github.com/angee/demand-shift-pattern/LICENSE
%
% Only change the figures in this file if you really know what you are doing.
% --------------------------------------------------------------------------------------- %

% M for big-M notation in one of the constraints. This is the minimal value M must take
int: M = maxWorkingHoursPerDay + 1;

% ================ TIME CONSTANTS ======================================================= % 

enum Day = {MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY};
% the days that are available for work in the shift pattern
set of Day: WEEKDAYS = {MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY};

% prints the weekday as a string
function string: toWeekday(Day: day) =
  if     day = MONDAY then "MONDAY"
  elseif day = TUESDAY then "TUESDAY"
  elseif day = WEDNESDAY then "WEDNESDAY"
  elseif day = THURSDAY then "THURSDAY"
  elseif day = FRIDAY then "FRIDAY"
  elseif day = SATURDAY then "SATURDAY"
  elseif day = SUNDAY then "SUNDAY"
  else "UNKNOWN" endif;
  
  
% returns the next day  
function Day: next(Day: day) = 
  if     day = MONDAY then TUESDAY
  elseif day = TUESDAY then WEDNESDAY
  elseif day = WEDNESDAY then THURSDAY
  elseif day = THURSDAY then FRIDAY
  elseif day = FRIDAY then SATURDAY
  elseif day = SATURDAY then SUNDAY
  elseif day = SUNDAY then MONDAY
  else MONDAY endif;

% prints the float version of time in time format.
% EXAMPLE: 16.5 will be printed as 16:30
function string: toTimeString(float: value) = 
   show(floor(value)) ++ ":" ++ 
   if value - floor(value) < 0.01
         then "00"
   elseif 10 > (value - floor(value)) * 60 
       then  "0" ++ show(round((value - floor(value)) * 60))
   else show(round((value - floor(value)) * 60))
   endif
   ;
   
% the factor by which we discretize time and that determines how 'granular' the start
% and end times of the shifts are. For illustration: a factor of 2 divides the hours
% by 2, resulting in 30min time units. A factor of 4 results in 15min time units,
% a factor of 1 results in 1 hour time units. Note that the number of variables
% increases with the timeFactor
int: timeFactor = 2;

% transforms time into discrete values, where each number
% represents the ith quarter hour since midnight. Example:
% 6.30am, represented as 6.5 is transformed into 6*4 + 0.5*4 = 26
function int: discrete(float: time) = 
   round(time*timeFactor);

% transforms the discrete time representation in the model into actual time   
function float: toTime(int: value) =
  value / (timeFactor*1.0);
  
function float: floatToTime(float: value) = 
  value / (timeFactor*1.0);
  
function float: toDiscrete(float: time) = 
   time * timeFactor;

% the earliest time a shift pattern may begin
array[WEEKDAYS] of int: earliestStartTime = [discrete(6.5), % Monday
                                             discrete(6.5), % Tuesday
                                             discrete(6.5), % Wednesday
                                             discrete(6.5), % Thursday
                                             discrete(6.5), % Friday
                                             discrete(6.5), % Saturday
                                             discrete(8.0)  % Sunday
                                             ];
constraint 
   forall (day in WEEKDAYS) (
        assert(earliestStartTime[day] >= discrete(0.0), 
               "earliestStartTime may not be negative on " ++ toWeekday(day) ++ ".\n") 
     /\ assert(earliestStartTime[day] <= discrete(24.0), 
               "earliestStartTime may not be larger than " ++ show(discrete(24.0)) 
                ++ " on " ++ toWeekday(day) ++ ".\n") 
  );
  
int: earliestTime = min(earliestStartTime);
int: latestTime = max(latestEndTime);
set of int: TIME_UNITS = earliestTime..latestTime;  

% the latest time a shift pattern may end
array[WEEKDAYS] of int: latestEndTime = [discrete(21.0),  % Monday
                                         discrete(21.0),  % Tuesday
                                         discrete(21.0),  % Wednesday
                                         discrete(21.0),  % Thursday
                                         discrete(21.0),  % Friday
                                         discrete(21.0),  % Saturday
                                         discrete(18.0)    % Sunday
                                         ];
constraint 
   forall (day in WEEKDAYS) (
        assert(latestEndTime[day] >= discrete(0.0), 
               "latestEndTime may not be negative on " ++ toWeekday(day) ++ ".\n") 
     /\ assert(latestEndTime[day] <= discrete(24.0), 
               "latestEndTime may not be larger than " ++ show(discrete(24.0)) 
                ++ " on " ++ toWeekday(day) ++ ".\n") 
  );
  
constraint 
   forall (day in WEEKDAYS) (
        assert(earliestStartTime[day] <= latestEndTime[day], 
               "earliestStartTime has to be smaller or equal to the latestEndTime on " 
                ++ toWeekday(day) ++ ".\n")
  );

% ================ VANS AND SHIFT_RELATED CONSTANTS ======================================== % 

% the number of vehicles in the fleet
int: vehicles;
set of int: VEHICLES = 1..vehicles;

% the number of hours per week that DFS pays each driver to work 
int: paidWorkingHoursPerWeek = discrete(44.0);
% the legal maximum number of working hours per week
int: maxWorkingHoursPerWeek = maximalWeeklyShiftLength; % discrete(60.0);
% the legal maximal working hours per day
int: maxWorkingHoursPerDay = discrete(12.0);  
% the minimal length of a daily shift
int: minimalDailyShiftLength = discrete(8.0);
% the minimal number of hours drivers should work in each shift weekly
int: minimalWeeklyShiftLength = discrete(33.0); 
% the maximal number of hours drivers should work in each shift weekly
int: maximalWeeklyShiftLength = discrete(48.0);

% the current shift pattern: start times of shifts
% NOTE: if there is no shift on that day, the start times are still set to 8am
array[1..2, WEEKDAYS] of int: currentStartOfShift = 
[| discrete(8.0), discrete(7.0), discrete(7.0), discrete(7.0), discrete(7.0), discrete(7.0), discrete(8.0)
 | discrete(8.0), discrete(8.0), discrete(8.0), discrete(8.0), discrete(8.0), discrete(8.0), discrete(8.0)
 |];
 

% the current shift pattern: end times of shifts
% NOTE: if there is no shift on that day, the end times are set to 8am
array[1..2, WEEKDAYS] of int: currentEndOfShift = 
[| discrete(17.0), discrete(16.0), discrete(16.0), discrete(16.0), discrete(16.0), discrete(16.0), discrete(8.0)
 |  discrete(8.0), discrete(19.0), discrete(19.0), discrete(19.0), discrete(19.0),  discrete(8.0), discrete(8.0)
 |];
 
% the maximal daily vehicle hours: maximalShiftLength * nbVehicles - lunchbreak
int: maxDailyCapacity = (maxWorkingHoursPerDay)*vehicles - vehicles*timeFactor;

% the maximal number of orders that can be delivered per day for the whole fleet
float: maxOrdersServicablePerDay = 1.0*vehicles*maxWorkingHoursPerDay*ordersServicedPerVehiclePerHour;

% ================ DEMAND CONSTANTS ========================================================== % 

int: maxServicableOrdersPerWeek = round((vehicles * (paidWorkingHoursPerWeek - 6*2*stemTime)) 
                                   * ordersServicedPerVehiclePerHour);
array[WEEKDAYS] of int: estimatedOrders = array1d(WEEKDAYS,
   [ round(demandAsPercentage[day] * maxServicableOrdersPerWeek) | day in WEEKDAYS ]
);                              

int: maxDemand = sum (day in WEEKDAYS) (demand[day]);
array[WEEKDAYS] of float: demandAsPercentage = 
    array1d(WEEKDAYS,
       [ demand[day] / maxDemand | day in WEEKDAYS] 
    );

% the number of orders a vehicle can deliver on average per hour
float: ordersServicedPerVehiclePerHour = floatToTime(60/50);


% the stem time is the initial and final driving time to the depot
int: stemTime = discrete(35/60);  % 35 minutes
int: lunchbreak = discrete(60/60);  % 60 minutes