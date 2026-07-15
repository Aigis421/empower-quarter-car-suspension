% SMD Parameters
m = 108;    % 1/2 of front of car mass in kg based on mass distribution
k = 4500;    % spring stiffness 
c = 1000;     % damping force 

    %Speed Bump Profile 
% Road Parameters
a = 0.01; % amplitude
w = 3;    % width
t0 = 2;   % Center 
t = -2:0.001:30; % Plotted Time

% Base displacement
yb_raw = a*(1 -((t - t0)/w).^2);        % Inverted parabola (Speed bump)

% clip so only positive displacement interacts
yb = max(0, yb_raw);

% Transfer function from base displacement to mass displacement
num = [c k];
den = [m c k];
sys = tf(num, den);

% Simulate mass displacement response
x = lsim(sys, yb, t);

% Plot results
figure;
plot(t, yb, '-b', 'DisplayName', 'Speed Bump');
hold on;
plot(t, x, '-', 'DisplayName', 'Car');
title('Speed Bump and Mass Response')
xlabel('Time (s)');
ylabel('Meters');
legend;
grid on;

    %Pothole Profile
% Road parameters
a = 0.01;            % amplitude (m)
w = 3;               % width (s)
t0 = 2;              % center (s)

% time vector (s)
t = -2:0.001:20;    

% Half-sine pothole 
idx = abs(t - t0) <= (w/2);
e = zeros(size(t));
phi = (t(idx) - (t0 - w/2)) / w;          
e(idx) = -a * sin(pi * phi);              

% Transfer function from base displacement to mass displacement
num = [c k];
den = [m c k];
sys = tf(num, den);

% Simulate mass displacement response
ym = lsim(sys, e, t);

% Plot results
figure;
plot(t, e, '-b', 'DisplayName','Road'); 
hold on;
plot(t, ym, '-', 'DisplayName','Car'); 
title('Pothole and Mass Response');
xlabel('Time (s)');
ylabel('Meters');
legend;
grid on;

    % Rough road profile:
% Time vector
t = -1:0.001:1;        
dt = t(2)-t(1);
fs = 1/dt;

% Band-limited roughness parameters
rng(0);                 % reproducible
f_low = 0.5;            % low cut (Hz)
f_high = 6;            % high cut (Hz)
rms_target = 0.005;     % target RMS roughness (m)

% Generate white noise then bandpass filter
wn = randn(size(t));
Wn = [f_low f_high]/(fs/3);    % cutoff
[b,a] = butter(4, Wn, 'bandpass');
road_raw = filtfilt(b, a, wn); % zero-phase filtering

% Scale to desired RMS
rms_raw = sqrt(mean(road_raw.^2));
road = road_raw * (rms_target / rms_raw);

% Transfer function from base (road) to mass displacement
num = [c k];
den = [m c k];
sys = tf(num, den);

% Simulate mass displacement response
ym = lsim(sys, road, t);

% Plot Results
figure;
plot(t, road, '-b', 'DisplayName','Road'); 
hold on;
plot(t, ym, '-', 'DisplayName','Car');
xlabel('Time (s)'); 
ylabel('Meters');
title('Rough Road');
legend;
grid on;

    % Analyze m, k, c relationship
% Ensure arrays are same size
assert(isequal(size(m), size(c), size(k)), 'm, c, k must be same size');

for i = 1:numel(m)
    fn = (1/(2*pi)) * sqrt(k(i)/m(i));    % natural frequency in Hz
    fprintf('Result %d: m=%.4g kg, c=%.4g N·s/m, k=%.4g N/m -> fn = %.4f Hz\n', ...
        i, m(i), c(i), k(i), fn);
    if fn < 1
        fprintf('  Too low, increase k value\n');
    elseif fn > 2
        fprintf('  Too high, decrease k value\n');
    end
end

for i = 1:numel(m)
    zeta = c(i) / (2*sqrt(k(i)*m(i)));
    % Ideal Damping Ratios 0.2 - 0.5 Better Comfort 0.6 - 0.9 Better Handling
    fprintf('Result %d: zeta = %.4f\n', i, zeta);
    if zeta > 1
        fprintf('   Overdamped\n');
    end
    if zeta < 0.1 
        fprintf('   Underdamped\n');
    end
end