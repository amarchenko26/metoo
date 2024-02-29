#plot counts

import pandas as pd
import matplotlib.pyplot as plt 

clean_cases = pd.read_csv("data/clean/clean_cases.csv")


# Assuming 'cases' is already loaded and 'Court Filing Date' is in datetime format
clean_cases['Court Filing Date'] = pd.to_datetime(clean_cases['Court Filing Date'])


clean_cases = clean_cases[clean_cases['Court Filing Date'] > '2004-01-01']


# Group by 'sh' and 'Court Filing Date' (by month), then count the number of cases
monthly_counts = clean_cases.groupby(['sh', pd.Grouper(key='Court Filing Date', freq='M')]).size().reset_index(name='counts')

# Split the data based on 'sh' values
monthly_counts_sh_1 = monthly_counts[monthly_counts['sh'] == 1]
monthly_counts_sh_0 = monthly_counts[monthly_counts['sh'] == 0]

# Plotting
plt.figure(figsize=(10, 6))
plt.plot(monthly_counts_sh_1['Court Filing Date'], monthly_counts_sh_1['counts'], label='SH = 1')
plt.plot(monthly_counts_sh_0['Court Filing Date'], monthly_counts_sh_0['counts'], label='SH = 0')

# Adding plot details
plt.title('Number of Observations Over Time')
plt.xlabel('Court Filing Date')
plt.ylabel('Number of Observations')
plt.axvline(pd.to_datetime('2017-10-01'), color='red', linestyle='--', linewidth=2)
plt.legend()
plt.grid(True)

# Assuming 'figures_dir' is defined elsewhere in your script
full_path = f'{figures_dir}counts_over_time.png'
plt.savefig(full_path, format='png')

# Show the plot
plt.show()

