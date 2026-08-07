clear;

M = 54.2237;              % Mass of Car (kg)
m = 22.6796;              % Mass of wheel (kg)
Kt = 114182.6977;         % Tire Stiffness Constant (N/m)
g = 9.81;                 % gravity
staticLoad = (M + m) * g; % overall tire load
a = 8;                    % rough terrain smoothing 
names = {'Smooth Speed Bump','Rough Terrain','Washboards','Rough Terrain + Pothole'};
Data = struct('name', cell(1,4), 'trial', cell(1,4));

%% Optimizing Ks and C
% User picks road profile
disp('(1) Smooth pothole, (2)Rough Terrain, (3) Washboards, (4) Rough Terrain + speed bump')
S = input('Which profile do you want to optimize for? ');
k = input('How many Ks & Cs values do you want to sweep? ');
v = input('Enter car velocity(mph): ');
v = v*0.44704; % mph to m/s

Ks_range = linspace(20000, 40000, k); 
Cs_range = linspace(0, 5000, k);  
travelLimit  = 0.050;  
AcellLimit  = 3.0;    

model = 'Solver_simulink';
open_system(model);

gripScore = inf(numel(Ks_range), numel(Cs_range));

for i = 1:numel(Ks_range)
    for j = 1:(numel(Ks_range))

        Ks = Ks_range(i);
        c  = Cs_range(j);
        Smodel = sim(model);  

        comfort   = rms(Smodel.SprungMassAccel.Data);
        travel    = Smodel.SprungMassPos.Data - Smodel.UnSprungMassPos.Data;
        SusTravel = max(travel) - min(travel);
        tireDefl  = Smodel.UnSprungMassPos.Data - Smodel.RoadProfile.Data;
        tireForce = staticLoad + Kt.*tireDefl;
        rmsFdyn   = rms(Kt.*tireDefl);
        rmsPct    = rmsFdyn / staticLoad * 100;
        liftoff   = any(tireForce <= 0);

        if SusTravel <= travelLimit && comfort <= AcellLimit
            gripScore(i,j) = rmsPct;  % minimize tire-load fluctuation
        end
    end
end

[best, idx] = min(gripScore(:));

% Convert the linear indices [3 4 5 6] to row and column subscripts to
% retrieve best Ks and Cs Values
[idxK, idxC] = ind2sub(size(gripScore), idx);
Ks0 = Ks_range(idxK);
c0  = Cs_range(idxC);

%% Simulate suspension using ks and c values found above
%  Runs 20 trials for each road profile while varying Ks and c by 10 percent
%  as a robustness test

% For counting how many trials pass
passCount = zeros(1,4);

for S = 1:4
    % parameter robustness test
    for trialNum = 1:20

        % variance of params
        Ks = Ks0 + Ks0*(0.005*(trialNum-1));
        c = c0 + c0*(0.005*(trialNum-1));
        Smodel = sim(model);

        % Assigns Data based on road profile simulation to "Data" struct 
        Data(S).name   = names{S};
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
        Data(S).trial(trialNum).susDefl    = Data(S).trial(trialNum).S_pos - Data(S).trial(trialNum).US_pos;
        Data(S).trial(trialNum).maxTravel  = max(Data(S).trial(trialNum).susDefl) - min(Data(S).trial(trialNum).susDefl);
        Data(S).trial(trialNum).tireDefl   = Data(S).trial(trialNum).US_pos - Data(S).trial(trialNum).Zt;

        % Road-holding calculations
        Data(S).trial(trialNum).Fdyn      = Kt .* Data(S).trial(trialNum).tireDefl;    % dynamic tire load (N); + = extra load, - = unloading
        Data(S).trial(trialNum).tireForce = staticLoad + Data(S).trial(trialNum).Fdyn;    % total instantaneous normal force
        Data(S).trial(trialNum).minForce  = min(Data(S).trial(trialNum).tireForce);
        Data(S).trial(trialNum).rmsFdyn   = rms(Data(S).trial(trialNum).Fdyn);
        Data(S).trial(trialNum).rmsPct    = Data(S).trial(trialNum).rmsFdyn / staticLoad * 100;
        Data(S).trial(trialNum).liftoff   = any(Data(S).trial(trialNum).tireForce <= 0);
        Data(S).trial(trialNum).liftoffCount = sum(diff([0; Data(S).trial(trialNum).tireForce <= 0]) == 1);
       
    
            % Comfort
            if Data(S).trial(trialNum).comfort > 2.5
                Data(S).trial(trialNum).Clabel = 'Extremely Uncomfortable'; 
                Data(S).trial(trialNum).CGrade = 5;
                Data(S).trial(trialNum).description = 'Extreme discomfort; risk of injury or severe health effects.';
            elseif Data(S).trial(trialNum).comfort > 1.25
                Data(S).trial(trialNum).Clabel = 'Very Uncomfortable'; 
                Data(S).trial(trialNum).CGrade = 6;
                Data(S).trial(trialNum).description = 'Severe discomfort; likely to cause pain, fatigue, or health issues.';
            elseif Data(S).trial(trialNum).comfort > 0.8
                Data(S).trial(trialNum).Clabel = 'Uncomfortable'; 
                Data(S).trial(trialNum).CGrade = 7;
                Data(S).trial(trialNum).description = 'Significant discomfort; may lead to fatigue, reduced efficiency, or health risks.';
            elseif Data(S).trial(trialNum).comfort > 0.5
                Data(S).trial(trialNum).Clabel = 'Fairly Uncomfortable'; 
                Data(S).trial(trialNum).CGrade = 8;
                Data(S).trial(trialNum).description = 'Moderate discomfort; may cause fatigue or annoyance during prolonged exposure.';
            elseif Data(S).trial(trialNum).comfort > 0.315
                Data(S).trial(trialNum).Clabel = 'A Little Uncomfortable'; 
                Data(S).trial(trialNum).CGrade = 9;
                Data(S).trial(trialNum).description = 'Mild discomfort; noticeable but tolerable for most people.';
            else
                Data(S).trial(trialNum).Clabel = 'Not Uncomfortable'; 
                Data(S).trial(trialNum).CGrade = 10;
                Data(S).trial(trialNum).description = 'Vibrations are barely perceptible; no discomfort.';
            end
            
            % Road Handling Performance
            if Data(S).trial(trialNum).liftoff
                Data(S).trial(trialNum).rhLabel = 'Contact Lost';
                Data(S).trial(trialNum).RHGrade = 6;
            elseif Data(S).trial(trialNum).rmsPct > 40
                Data(S).trial(trialNum).rhLabel = 'Poor Road-Holding'; 
                Data(S).trial(trialNum).RHGrade = 7;  
            elseif Data(S).trial(trialNum).rmsPct > 25
                Data(S).trial(trialNum).rhLabel = 'Fair Road-Holding'; 
                Data(S).trial(trialNum).RHGrade = 8; 
            elseif Data(S).trial(trialNum).rmsPct > 10
                Data(S).trial(trialNum).rhLabel = 'Good Road-Holding'; 
                Data(S).trial(trialNum).RHGrade = 9; 
            else
                Data(S).trial(trialNum).rhLabel = 'Excellent Road-Holding'; 
                Data(S).trial(trialNum).RHGrade = 10;
            end
    gradeLetters = {'F','F','F','F','F','D','C','B','A','A'};

    Data(S).trial(trialNum).scoreLetter = gradeLetters{...
    round((Data(S).trial(trialNum).CGrade + Data(S).trial(trialNum).RHGrade)/2)};
    Data(S).trial(trialNum).scoreNum = (Data(S).trial(trialNum).CGrade + Data(S).trial(trialNum).RHGrade)/2;

        % detects if trial passed
        if Data(S).trial(trialNum).scoreNum >= 7.0
            passCount(S) = passCount(S) + 1;
        end
    end
end

% plots of 1st trial, no percent increase in Ks and c
for S = 1:4
    % Plotting car position
    figure(1)
    set(gcf, 'Name', 'Car position')
    subplot(2,2,S)
    plot(Data(S).trial(1).t, Data(S).trial(1).S_pos)
    title(Data(S).name) 
    
    % Plotting Tire Position
    figure(2)
    set(gcf, 'Name', 'Tire position')
    subplot(2,2,S)
    plot(Data(S).trial(1).t, Data(S).trial(1).US_pos)
    title(Data(S).name)
    
    % Plotting Road Profile and Tire position
    figure(3)
    set(gcf, 'Name', 'Road profile and Tire position')
    subplot(2,2,S)
    hold on
    plot(Data(S).trial(1).t, Data(S).trial(1).US_pos)
    plot(Data(S).trial(1).t, Data(S).trial(1).Zt, '--')
    legend('Tire position','Road Profile')
    hold off
    title(Data(S).name)
end


%% aggregating each profile and displaying results
aggComfort = zeros(1,4);
aggMaxTravel = zeros(1,4);
W_Comfort_trial = zeros(1,4);
W_RHGrade_trial = zeros(1,4);
W_ScoreNum_trial = zeros(1,4);
W_grip_trial = zeros(1,4);
W_ScoreLetter = string(zeros(1,4));
Description = string(zeros(1,4));

for S = 1:4
    [W_Comfort_trial(S), W_Comfort_idx(S)]  = min([Data(S).trial.CGrade]);
    [W_RHGrade_trial(S), W_RHGrade_idx(S)]  = min([Data(S).trial.RHGrade]);
    [W_ScoreNum_trial(S), W_ScoreNUM_idx(S)]= min([Data(S).trial.scoreNum]);
    [W_GripLost_trial(S), W_GripLost_idx(S)]= max([Data(S).trial.liftoffCount]);
    W_ScoreLetter(S) = Data(S).trial(W_ScoreNUM_idx(S)).scoreLetter;
    Description(S) = Data(S).trial(W_ScoreNUM_idx(S)).description;
    aggComfort(S)   = mean([Data(S).trial.comfort]);
    aggMaxTravel(S) = mean([Data(S).trial.maxTravel]) * 1000;
    W_rmsPct(S)     = mean([Data(S).trial.rmsPct]);
    W_GripLostAgg(S) = mean([Data(S).trial.liftoffCount]);
end

Summary = table(names(:), W_ScoreLetter(:), W_ScoreNum_trial(:),passCount(:), Description(:), aggComfort(:), aggMaxTravel(:) ...
    ,W_GripLost_trial(:), W_GripLostAgg(:), W_rmsPct(:)...
    ,'VariableNames', {'Road profile','Worst Trial Grade', 'Worst Trial Score','# Trials that passed', 'Comfort Description', ...
    'Avg. "Comfort" RMS (m/s^2)','Avg. Max Travel of car (mm)', '# Tire loses contact' ...
    ,'Avg contact loses','RMS pct'});
disp(Summary)
