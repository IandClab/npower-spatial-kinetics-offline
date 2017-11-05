clear all
close all
clc

params = parse_json(fileread('simulation.json'));

tf_minutes = params.tf_minutes; % Simulation runtime in minutes
tf = tf_minutes*60; % Simulation runtime in seconds
rate = params.rate; % Power decrease ramp rate in % of total (42MW)
rate_pct = rate/100; % Conversion to decimal

% Run initializaation script
run SpatialKineticsOpenSourceMain

% Run simulink model
sim('SpatialKineticsOffline')

% Plot PHX Power vs Time
figure
plot(tout, current_demand, tout, current_power)
xlabel('Time')
ylabel('Power (MW)')
legend('Current Demand', 'Current Power')
title('PHX Power vs Time')

% Plot Salt Vault Temperature vs Time
figure
plot(tout, salt_temp)
xlabel('Time')
ylabel('Temperature (deg C)')
legend('Salt Vault Temperature')
title('Salt Vault Temperature vs Time')
