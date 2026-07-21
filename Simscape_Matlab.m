clear;

Ks = 30647.196473; % Suspension spring constant
c = 700;           % Suspension damping constant
M = 108;           % Mass of Car
m = 50;            % Mass of wheel
Kt = 114182.69772; % Tire Spring Constant


% Simulate each road profile and opens simulink
for select = 1:4
    
model = 'MassSpringDamper_simulink';
open_system(model);
Smodel = sim(model);
    
names = {'Smooth Speed Bump','Rough Terrain','Smooth Median Strip','Rough Terrain + Pothole'};
Data(select).name   = names{select};
Data(select).t      = Smodel.tout;
Data(select).S_pos  = Smodel.SprungMassPos.Data;
Data(select).US_pos = Smodel.UnSprungMassPos.Data;
Data(select).Zt     = Smodel.RoadProfile.Data;
Data(select).S_vel  = Smodel.SprungMassVel.Data;
Data(select).US_vel = Smodel.UnSprungMassVel.Data;
Data(select).S_Acc  = Smodel.SprungMassAccel.Data;
Data(select).US_Acc = Smodel.UnSprungMassAccel.Data;

% analysis, for each road profile
Data(select).comfort    = rms(Data(select).S_Acc);
Data(select).maxTravel  = max(Data(select).S_pos);
Data(select).deflection = Data(select).US_pos - Data(select).Zt;

subplot(2,2,select)
plot(Data(select).t, Data(select).S_pos)
title(Data(select).name)
end
