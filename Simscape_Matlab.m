clear;

Ks = 30647.196473; % Suspension spring stiffness constant
c = 700;           % Suspension damping constant
M = 108;           % Mass of Car
m = 50;            % Mass of wheel
Kt = 114182.69772; % Tire Stiffness Constant
g = 9.81;          % gravity
staticLoad = (M + m) * g;   % overall tire load
a = 8;              % rough terrain smoothing

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

% analysis for each road profile
Data(S).comfort    = rms(Data(S).S_Acc);
Data(S).maxTravel  = max(Data(S).S_pos);
Data(S).deflection = Data(S).US_pos - Data(S).Zt;

% Road-holding calculations
Data(S).Fdyn      = -Kt .* Data(S).deflection;   % dynamic tire load (N); + = extra load, - = unloading
Data(S).tireForce = staticLoad + Data(S).Fdyn;    % total instantaneous normal force
Data(S).minForce  = min(Data(S).tireForce);
Data(S).rmsFdyn   = rms(Data(S).Fdyn);
Data(S).rmsPct    = Data(S).rmsFdyn / staticLoad * 100;
Data(S).liftoff   = any(Data(S).tireForce <= 0);
Data(S).liftoffCount = sum(diff([0; Data(S).tireForce <= 0]) == 1);

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

% Comfort
if Data(S).comfort > 2.5
    Data(S).label = 'Extremely Uncomfortable'; Data(S).CGrade = 0;
    Data(S).description = 'Extreme discomfort; risk of injury or severe health effects.';
elseif Data(S).comfort > 1.25
    Data(S).label = 'Very Uncomfortable'; Data(S).CGrade = 0;
    Data(S).description = 'Severe discomfort; likely to cause pain, fatigue, or health issues.';
elseif Data(S).comfort > 0.8
    Data(S).label = 'Uncomfortable'; Data(S).CGrade = 1;
    Data(S).description = 'Significant discomfort; may lead to fatigue, reduced efficiency, or health risks.';
elseif Data(S).comfort > 0.5
    Data(S).label = 'Fairly Uncomfortable'; Data(S).CGrade = 2;
    Data(S).description = 'Moderate discomfort; may cause fatigue or annoyance during prolonged exposure.';
elseif Data(S).comfort > 0.315
    Data(S).label = 'A Little Uncomfortable'; Data(S).CGrade = 3;
    Data(S).description = 'Mild discomfort; noticeable but tolerable for most people.';
else
    Data(S).label = 'Not Uncomfortable'; Data(S).CGrade = 4;
    Data(S).description = 'Vibrations are barely perceptible; no discomfort.';
end

% Road Handling Performance

if Data(S).liftoff
    Data(S).rhLabel = 'Contact Lost'; Data(S).RHGrade = 0;
    Data(S).rhDescription = 'Tire load reaches zero at least once; wheel skips / loses contact with the road.';
elseif Data(S).rmsPct > 40
    Data(S).rhLabel = 'Poor Road-Holding'; Data(S).RHGrade = 1;
    Data(S).rhDescription = 'Large load fluctuations; grip is significantly reduced.';
elseif Data(S).rmsPct > 25
    Data(S).rhLabel = 'Fair Road-Holding'; Data(S).RHGrade = 2;
    Data(S).rhDescription = 'Noticeable load fluctuations; reduced grip on the rough surface.';
elseif Data(S).rmsPct > 10
    Data(S).rhLabel = 'Good Road-Holding'; Data(S).RHGrade = 3;
    Data(S).rhDescription = 'Moderate load fluctuations; tire grip is mostly preserved.';
else
    Data(S).rhLabel = 'Excellent Road-Holding'; Data(S).RHGrade = 4;
    Data(S).rhDescription = 'Tire load stays close to static; grip barely affected.';
end

gradeLetters = {'F','D','C','B','A'};
Data(S).score = gradeLetters{round((Data(S).CGrade + Data(S).RHGrade)/2) + 1};

end

Summary = table(string(names(:)), string({Data.score}'), [Data.comfort]', ...
    string({Data.label}'), [Data.maxTravel]', [Data.rmsPct]', ...
    string({Data.rhLabel}'), [Data.liftoffCount]', [Data.minForce]', ...
    'VariableNames', {'Profile','Score','Comfort Data','Comfort Desc.','Max Travel', ...
    'RMS pct','Road Holding','Liftoffs','Min Load'});
disp(Summary)
