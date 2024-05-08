/*******************************************************************************
Program to create time to treat
*******************************************************************************/

cap program drop create_time_to_treat

program define create_time_to_treat
    syntax, period(integer) [period_label(string)]

    gen event_date = date("$metoo", "DMY")

    // Calculate the months_to_treat var, 0 is first period after MeToo, -1 is pre-period 
    gen months_to_treat_`period' = floor((common_file_date - event_date) / (`period' * 30.4375))
    
    // Label the time_to_treat variable
    if "`period_label'" != "" {
        label var months_to_treat_`period' "`period_label'"
    }
    else {
        label var months_to_treat_`period' "Periods relative to MeToo"
    }
	drop event_date
end
