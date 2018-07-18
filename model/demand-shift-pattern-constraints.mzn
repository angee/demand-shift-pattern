% ================= CONSTRAINTS THAT HAVE TO HOLD ===================== %

% the constraints that are fixed and that cannot be turned on or off
enum Constraint = {
             ShiftsHaveSameNumberOfVehicles,  % each shift must have the same number of vehicles operating in it, otherwise it is not a valid shift pattern
             VehiclesOnlyWorkOnOneShift,      % vehicles may only be assigned to ONE shift
             ShiftStartsAfterOrAtEarliestStartTime,  % start times of shifts must begin at or after the earliest start time
             ShiftEndsBeforeOrAtLatestEndTime,  % the shift must end at or before the latest end time
             AverageWorkingHoursEqualPaidWorkingHours, % the average number of working hours over all shift patterns must equal the number of paid working hours
             TwoDaysBreakAfterEachShift, % there is a 2 day break (45 hours) between two shifts
             CapacityIsLargerThanMinimalDemand, % the vehicle capacity has to meet at least the minimal estimated demand of a day
             CapacityIsSmallerThanMaximalDemand % the vehicle capacity should not exceed the maximal estimated demand of a day
};


% the constraints that are available (and that may be turned on and off) in the model
enum OptionalConstraint = { 
                     ShiftsInWeekStartAtSameTime,  % each week in a shift, the starting times have to be the same except Monday
                     MinimalDailyShiftLength,  % each daily shift has a minimal length
                     NoShiftsOnSunday, % no shift should be scheduled on Sundays
                     MinimalWeeklyShiftLength,  % a daily shift must have a minimal length
                     MaximalWorkingHoursPerWeek, % enforce a maximal number of working hours per week
                     HolidayEveryOtherSaturday % drivers should work only every other Saturday
                   };
   
% printing a constraint enum as string                                   
function string: constraintToString(OptionalConstraint: ct) = 
    if ct = ShiftsInWeekStartAtSameTime then 
       "ShiftsInWeekStartAtSameTime"
    elseif ct = MinimalDailyShiftLength then 
       "MinimalDailyShiftLength"
    elseif ct = NoShiftsOnSunday then
       "NoShiftsOnSunday"
    elseif ct = MinimalWeeklyShiftLength then 
       "MinimalWeeklyShiftLength"
    elseif ct = MaximalWorkingHoursPerWeek then 
       "MaximalWorkingHoursPerWeek"
    elseif ct = HolidayEveryOtherSaturday then
       "HolidayEveryOtherSaturday"
    else "" endif;   
           
                        
% the constraints that have to hold, if a constraint is not part of this set, then it will 
% not be enforced.
set of OptionalConstraint: OPTIONAL_CONSTRAINTS = { 
                                   %%%% ShiftsInWeekStartAtSameTime 
                                   %MinimalDailyShiftLength,
                                   %NoShiftsOnSunday,
                                   %MinimalWeeklyShiftLength,
                                   MaximalWorkingHoursPerWeek,
                                   %HolidayEveryOtherSaturday
                                 };
