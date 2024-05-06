/*******************************************************************************
Program to create time to treat
*******************************************************************************/

cap program drop create_time_to_treat

program define create_time_to_treat
    syntax, period(integer) [period_label(string)]

    gen event_date = date("$metoo", "DMY")

    * Generate the time_to_treat variable
    gen months_to_treat_`period' = ceil((common_file_date - event_date) / (`period' * 30.4375))
    replace months_to_treat_`period' = 0 if common_file_date < event_date & common_file_date >= event_date - `period' * 30.4375
    replace months_to_treat_`period' = -1 if common_file_date < event_date - `period' * 30.4375 & common_file_date >= event_date - 2 * `period' * 30.4375
    replace months_to_treat_`period' = -2 if common_file_date < event_date - 2 * `period' * 30.4375 & common_file_date >= event_date - 3 * `period' * 30.4375
    replace months_to_treat_`period' = -3 if common_file_date < event_date - 3 * `period' * 30.4375 & common_file_date >= event_date - 4 * `period' * 30.4375
    replace months_to_treat_`period' = -4 if common_file_date < event_date - 4 * `period' * 30.4375 & common_file_date >= event_date - 5 * `period' * 30.4375
    replace months_to_treat_`period' = -5 if common_file_date < event_date - 5 * `period' * 30.4375 & common_file_date >= event_date - 6 * `period' * 30.4375
    replace months_to_treat_`period' = -6 if common_file_date < event_date - 6 * `period' * 30.4375 & common_file_date >= event_date - 7 * `period' * 30.4375
    replace months_to_treat_`period' = -7 if common_file_date < event_date - 7 * `period' * 30.4375 & common_file_date >= event_date - 8 * `period' * 30.4375
    replace months_to_treat_`period' = -8 if common_file_date < event_date - 8 * `period' * 30.4375 & common_file_date >= event_date - 9 * `period' * 30.4375
    replace months_to_treat_`period' = -9 if common_file_date < event_date - 9 * `period' * 30.4375 & common_file_date >= event_date - 10 * `period' * 30.4375

    * Label the time_to_treat variable
    if "`period_label'" != "" {
        label var months_to_treat_`period' "`period_label'"
    }
    else {
        label var months_to_treat_`period' "Periods relative to MeToo"
    }
	drop event_date
end
