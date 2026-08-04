Ks = 30647.196473              % Suspension spring stiffness constant
Ks0 = 30647.196473;            % Simulation reset to baseline
c = 700;                       % Suspension damping constant
c0 = 700;                      % Simulation reset to baseline
M = 108;                       % Mass of Car
m = 50;                        % Mass of wheel
Kt = 114182.69772;             % Tire Stiffness Constant
g = 9.81;                      % gravity
staticLoad = (M + m) * g;      % overall tire load
a = 8;                         % rough terrain smoothing 

names = {'Smooth Speed Bump','Rough Terrain','Washboards','Rough Terrain + Pothole'};
% 1 = Smooth speed bump
% 2 = Rough Terrain
% 3 = Washboards
% 4 = Rough Terrain + Pothole


%% Simulate suspension system and opens simulink
model = 'MassSpringDamper_simulink';
open_system(model);

% For counting how many trials pass
passCount = zeros(1,4);

for S = 1:4
    s = S;
    
    % parameter robustness test
    for trialNum = 1:20

         % variance of params
        Ks = Ks0 + Ks0*(0.005*trialNum);
        c = c0 + c0*(0.005*trialNum);

        Smodel = sim(model);

        % Assigns Data based on road profile simulation to "Data" struct 
        Data(S).name   = names{S};
        Data(S).trial(trialNum).Ks = Ks; 
        Data(S).trial(trialNum).c = c;
        Data(S).trial(trialNum).t      = Smodel.tout;
        Data(S).trial(trialNum).Zt     = Smodel.RoadProfile.Data;
        Data(S).trial(trialNum).S_pos  = Smodel.SprungMassPos.Data;
        Data(S).trial(trialNum).US_pos = Smodel.UnSprungMassPos.Data;
        Data(S).trial(trialNum).S_vel  = Smodel.SprungMassVel.Data;
        Data(S).trial(trialNum).US_vel = Smodel.UnSprungMassVel.Data;
        Data(S).trial(trialNum).S_Acc  = Smodel.SprungMassAccel.Data;
        Data(S).trial(trialNum).US_Acc = Smodel.UnSprungMassAccel.Data;
        
        % analysis for each road profile
        Data(S).trial(trialNum).comfort    = rms(Data(S).trial(trialNum).S_Acc);
        Data(S).trial(trialNum).maxTravel  = max(Data(S).trial(trialNum).S_pos);
        Data(S).trial(trialNum).deflection = Data(S).trial(trialNum).US_pos - Data(S).trial(trialNum).Zt;
        
        % Road-holding calculations
        Data(S).trial(trialNum).Fdyn      = -Kt .* Data(S).trial(trialNum).deflection;    % dynamic tire load (N); + = extra load, - = unloading
        Data(S).trial(trialNum).tireForce = staticLoad + Data(S).trial(trialNum).Fdyn;    % total instantaneous normal force
        Data(S).trial(trialNum).minForce  = min(Data(S).trial(trialNum).tireForce);
        Data(S).trial(trialNum).rmsFdyn   = rms(Data(S).trial(trialNum).Fdyn);
        Data(S).trial(trialNum).rmsPct    = Data(S).trial(trialNum).rmsFdyn / staticLoad * 100;
        Data(S).trial(trialNum).liftoff   = any(Data(S).trial(trialNum).tireForce <= 0);
        Data(S).trial(trialNum).liftoffCount = sum(diff([0; Data(S).trial(trialNum).tireForce <= 0]) == 1);
        
        % Plotting car position
        figure(1)
        set(gcf, 'Name', 'Car position')
        subplot(2,2,S)
        plot(Data(S).trial(trialNum).t, Data(S).trial(trialNum).S_pos)
        title(Data(S).name) 
        
        % Plotting Tire Position
        figure(2)
        set(gcf, 'Name', 'Tire position')
        subplot(2,2,S)
        plot(Data(S).trial(trialNum).t, Data(S).trial(trialNum).US_pos)
        title(Data(S).name)
    
            % Comfort
            if Data(S).trial(trialNum).comfort > 2.5
                Data(S).trial(trialNum).Clabel = 'Extremely Uncomfortable'; 
                Data(S).trial(trialNum).CGrade = 0;
                Data(S).trial(trialNum).description = 'Extreme discomfort; risk of injury or severe health effects.';
            elseif Data(S).trial(trialNum).comfort > 1.25
                Data(S).trial(trialNum).Clabel = 'Very Uncomfortable'; 
                Data(S).trial(trialNum).CGrade = 0;
                Data(S).trial(trialNum).description = 'Severe discomfort; likely to cause pain, fatigue, or health issues.';
            elseif Data(S).trial(trialNum).comfort > 0.8
                Data(S).trial(trialNum).Clabel = 'Uncomfortable'; 
                Data(S).trial(trialNum).CGrade = 1;
                Data(S).trial(trialNum).description = 'Significant discomfort; may lead to fatigue, reduced efficiency, or health risks.';
            elseif Data(S).trial(trialNum).comfort > 0.5
                Data(S).trial(trialNum).Clabel = 'Fairly Uncomfortable'; 
                Data(S).trial(trialNum).CGrade = 2;
                Data(S).trial(trialNum).description = 'Moderate discomfort; may cause fatigue or annoyance during prolonged exposure.';
            elseif Data(S).trial(trialNum).comfort > 0.315
                Data(S).trial(trialNum).Clabel = 'A Little Uncomfortable'; 
                Data(S).trial(trialNum).CGrade = 3;
                Data(S).trial(trialNum).description = 'Mild discomfort; noticeable but tolerable for most people.';
            else
                Data(S).trial(trialNum).Clabel = 'Not Uncomfortable'; 
                Data(S).trial(trialNum).CGrade = 4;
                Data(S).trial(trialNum).description = 'Vibrations are barely perceptible; no discomfort.';
            end
            
            % Road Handling Performance
            if Data(S).trial(trialNum).liftoff
                Data(S).trial(trialNum).rhLabel = 'Contact Lost';
                Data(S).trial(trialNum).RHGrade = 0;
            elseif Data(S).trial(trialNum).rmsPct > 40
                Data(S).trial(trialNum).rhLabel = 'Poor Road-Holding'; 
                Data(S).trial(trialNum).RHGrade = 1;  
            elseif Data(S).trial(trialNum).rmsPct > 25
                Data(S).trial(trialNum).rhLabel = 'Fair Road-Holding'; 
                Data(S).trial(trialNum).RHGrade = 2;  
            elseif Data(S).trial(trialNum).rmsPct > 10
                Data(S).trial(trialNum).rhLabel = 'Good Road-Holding'; 
                Data(S).trial(trialNum).RHGrade = 3; 
            else
                Data(S).trial(trialNum).rhLabel = 'Excellent Road-Holding'; 
                Data(S).trial(trialNum).RHGrade = 4;
            end
    gradeLetters = {'F','D','C','B','A','A+'};

    Data(S).trial(trialNum).scoreLetter = gradeLetters{...
    round((Data(S).trial(trialNum).CGrade + Data(S).trial(trialNum).RHGrade)/2) + 1};
    Data(S).trial(trialNum).scoreNum = round((Data(S).trial(trialNum).CGrade + Data(S).trial(trialNum).RHGrade)/2) + 1;

        % detects if trial passed
        if Data(S).trial(trialNum).scoreNum >= 3.5
            passCount(S) = passCount(S) + 1;
        end
    end
end

%% aggregating each profile and displaying results
aggComfort = zeros(1,4);

for S = 1:4
    for T = 1:20
        aggComfort(S) = aggComfort(S) + Data(S).trial(T).comfort;
        

    end
end

worstComfort = max(aggComfort);

Summary = table(names(:), aggComfort(:),'VariableNames', {'Road profile', 'Avg, "Comfort"'});
disp(Summary)
