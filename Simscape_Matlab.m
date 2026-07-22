clear;

Ks = 30647.196473; % Suspension spring constant
c = 700;           % Suspension damping constant
M = 108;           % Mass of Car
m = 50;            % Mass of wheel
Kt = 114182.69772; % Tire Spring Constant

names = {'Smooth Speed Bump','Rough Terrain','Washboards','Rough Terrain + Pothole'};
% 1 = Smooth speed bump
% 2 = Rough Terrain
% 3 = Washboards
% 4 = Rough Terrain + Pothole

% Simulate suspension system and opens simulink
for S = 1:4

model = 'MassSpringDamper_simulink';
open_system(model);
Smodel = sim(model);

% Assigns Data based on road profile simulation to "Data" struct 
Data(S).name   = names{S};
Data(S).t      = Smodel.tout;
Data(S).Zt     = Smodel.RoadProfile.Data;
Data(S).S_pos  = Smodel.SprungMassPos.Data;
Data(S).US_pos = Smodel.UnSprungMassPos.Data;
Data(S).S_vel  = Smodel.SprungMassVel.Data;
Data(S).US_vel = Smodel.UnSprungMassVel.Data;
Data(S).S_Acc  = Smodel.SprungMassAccel.Data;
Data(S).US_Acc = Smodel.UnSprungMassAccel.Data;

% analysis, for each road profile
Data(S).comfort    = rms(Data(S).S_Acc);
Data(S).maxTravel  = max(Data(S).S_pos);
Data(S).deflection = Data(S).US_pos - Data(S).Zt;

% Plotting car position
figure(1)
set(gcf, 'Name', 'Car position')
subplot(2,2,S)
plot(Data(S).t, Data(S).S_pos)
title(Data(S).name) 

% Plotting Tire Position
figure(2)
set(gcf, 'Name', 'Tire position')
subplot(2,2,S)
plot(Data(S).t, Data(S).US_pos)
title(Data(S).name)

end
