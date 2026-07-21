clear;

Ks = 30647.196473; % Suspension spring constant
c = 700;           % Suspension damping constant
M = 108;           % Mass of Car
m = 50;            % Mass of wheel
Kt = 114182.69772; % Tire Spring Constant

disp('1. Smooth speed bump')
disp('2. Rough terrain')
disp('3. Smooth median strip')
disp('4. Rough terrain + Pothole')
%select = input("Select Road Profile: ");
select = 1;

% Simulate suspension system and opens simulink
model = 'MassSpringDamper_simulink';
open_system(model);
Smodel = sim(model);

% Extracts data from Simulink
t = Smodel.tout;
S_pos = Smodel.SprungMassPos.Data;
US_pos = Smodel.UnSprungMassPos.Data;
Zt = Smodel.RoadProfile.Data;

S_vel = Smodel.SprungMassVel.Data;
US_vel = Smodel.UnSprungMassVel.Data;

S_Accel = Smodel.SprungMassAccel.Data;
US_Accel = Smodel.UnSprungMassAccel.Data;

% Ride Analysis
Comfort_m = rms(S_Accel);
max_travel = max(S_pos);
deflection = US_pos - Zt;

plot(t,S_pos)
