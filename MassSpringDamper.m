% SMD Parameters
m = 2600;    % mass in kg
k = 120000;          % spring stiffness 
c = 30000;         % damping force

% Road Parameters
a = 0.01; % amplitude
w = 3;    % width
t0 = 2;   % Center 
t = -2:0.001:30; % Plotted Time

% Transfer function from base displacement to mass displacement
num = [c k];
den = [m c k];
sys = tf(num, den);

% Base displacement
yb_raw = a*(1 -((t - t0)/w).^2);        % Inverted parabola (Speedbump)

% clip so only positive displacement interacts
yb = max(0, yb_raw);

% Simulate response
x = lsim(sys, yb, t);

% Plot
figure
plot(t, yb, '--', 'DisplayName', 'base y_b(parabolic, clipped)')
hold on
plot(t, x, 'DisplayName', 'mass x(t)')
xlabel('Time (s)')
legend
grid on
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