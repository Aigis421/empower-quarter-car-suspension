clear;

Ks = 30647.196473; % Suspension spring constant
c = 700;           % Suspension damping constant
M = 108;           % Mass of Car
m = 50;            % Mass of wheel
Kt = 114182.69772; % Tire Spring Constant
select = 0;        % Initializing constant to run through Road profiles

% Simulate suspension system and opens simulink
while select < 4
    select = select + 1';
    
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

%plotting Sprung Mass Position
subplot(2,2,select)
plot(t,S_pos)

if select == 1
    title('Smooth Speed bump')
elseif select == 2
    title('Rough Terrain')
elseif select == 3
    title('Smooth Median Strip')
else 
    title('Rough Terrain + Pothole')
end


end
