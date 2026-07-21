function sliderApp()

%% Initial Parameters
m = 108;      % 1/2 of front of car mass in kg based on mass distribution
k = 4500;      % spring stiffness, N/m
c = 1000;       % damping force, Ns/m

%% Create Figure
fig = uifigure('Name','Quarter Car Suspension','Position',[100 100 1100 850]);

%fig grid dimensions
g = uigridlayout(fig,[10 2]);
g.RowHeight = {25,25,25,220,220,220,40,40,'1x'};
g.ColumnWidth = {250,'1x'};

%% Sliders
% Mass Slider
mLabel = uilabel(g); %define mLabel for transformations to mass slider
mLabel.Layout.Row = 1;
mLabel.Layout.Column = 1;

% create ui element for slider m
mSlider = uislider(g,...
    Limits=[50 3000],... % defined limits on mass
    Value=m); % set to default defined value
mSlider.Layout.Row = 1;
mSlider.Layout.Column = [2 3];

% Spring Slider
kLabel = uilabel(g); %define kLabel for transformations to spring slider
kLabel.Layout.Row = 2;
kLabel.Layout.Column = 1;

%create ui element on slider k
kSlider = uislider(g,...
    Limits=[1000 300000],... % defined limits on spring force, k
    Value=k); %set to defined value for k
kSlider.Layout.Row = 2;
kSlider.Layout.Column = [2 3];

% Damper Slider
cLabel = uilabel(g);  %define mLabel for transformations to damper slider
cLabel.Layout.Row = 3;
cLabel.Layout.Column = 1;

%create ui element on slider c
cSlider = uislider(g,...
    Limits=[0 100000],... % defined limits on spring force, c
    Value=c); %set to defined value for c
cSlider.Layout.Row = 3;
cSlider.Layout.Column = [2 3];

%% Three Plots

ax1 = uiaxes(g);
ax1.Layout.Row = 4;
ax1.Layout.Column = [1 3];
title(ax1,'Speed Bump')

ax2 = uiaxes(g);
ax2.Layout.Row = 5;
ax2.Layout.Column = [1 3];
title(ax2,'Pothole')

ax3 = uiaxes(g);
ax3.Layout.Row = 6;
ax3.Layout.Column = [1 3];
title(ax3,'Rough Road')

%% Results

freqLabel = uilabel(g);
freqLabel.Layout.Row = 7;
freqLabel.Layout.Column = [1 2];

zetaLabel = uilabel(g);
zetaLabel.Layout.Row = 7;
zetaLabel.Layout.Column = [2 3];

%% Slider Callbacks

mSlider.ValueChangingFcn = @(src,event)updatePlot();
kSlider.ValueChangingFcn = @(src,event)updatePlot();
cSlider.ValueChangingFcn = @(src,event)updatePlot();

updatePlot();

%%%%

    function updatePlot()

        % Read Slider Values

        m = mSlider.Value;
        k = kSlider.Value;
        c = cSlider.Value;

        % Update Labels

        mLabel.Text = sprintf('Mass (kg): %.1f',m);
        kLabel.Text = sprintf('Spring k (N/m): %.0f',k);
        cLabel.Text = sprintf('Damping c (Ns/m): %.0f',c);

        % Transfer function from base (road) to mass displacement
        num = [c k];
        den = [m c k];
        sys = tf(num,den);
        
        %% Test Cases
        % ============================================================
        % Speed Bump
        % ============================================================
        
        % Road Parameters
        a = 0.01; % amplitude
        w = 3; % width
        t0 = 2; % Center
        t = -2:0.001:30; % Plotted Time

        % Base displacement
        yb_raw = a*(1-((t-t0)/w).^2); % Inverted parabola (Speed bump)

        % clip so only positive displacement interacts
        yb = max(0,yb_raw);

        % Simulate mass displacement response
        x = lsim(sys,yb,t);

        % Plot results
        cla(ax1)
        plot(ax1,t,yb,'-b','DisplayName','Road')
        hold(ax1,'on')
        plot(ax1,t,x,'-r','LineWidth',1.5,'DisplayName','Car')
        hold(ax1,'off')
        xlabel(ax1,'Time (s)')
        ylabel(ax1,'Meters')
        legend(ax1)
        grid(ax1,'on')

        % ============================================================
        % Pothole
        % ============================================================

        % Road parameters
        a = 0.01;
        w = 3;
        t0 = 2;

        % time vector (s)
        t = -2:0.001:20;

        % Half-sine pothole 
        idx = abs(t-t0)<=w/2;
        e = zeros(size(t));
        phi = (t(idx)-(t0-w/2))/w;
        e(idx) = -a*sin(pi*phi);

        % Simulate mass displacement response
        ym = lsim(sys,e,t);

        % Plot results
        cla(ax2)
        plot(ax2,t,e,'-b','DisplayName','Road')
        hold(ax2,'on')
        plot(ax2,t,ym,'-r','LineWidth',1.5,'DisplayName','Car')
        hold(ax2,'off')
        xlabel(ax2,'Time (s)')
        ylabel(ax2,'Meters')
        legend(ax2)
        grid(ax2,'on')

        % ============================================================
        % Rough Road
        % ============================================================
        
        % Time vector
        t = -1:0.001:1;
        dt = t(2)-t(1);
        fs = 1/dt;
        
        % Band-limited roughness parameters
        rng(0)
        f_low = 0.5;
        f_high = 6;
        rms_target = 0.005;

        % Generate white noise then bandpass filter
        wn = randn(size(t));
        Wn = [f_low f_high]/(fs/3);
        [b,a] = butter(4,Wn,'bandpass');
        road_raw = filtfilt(b,a,wn);
        
        % Scale to desired RMS
        rms_raw = sqrt(mean(road_raw.^2));
        road = road_raw*(rms_target/rms_raw);
        
        % Simulate mass displacement response
        ym = lsim(sys,road,t);
        
        % Plot results
        cla(ax3)
        plot(ax3,t,road,'-b','DisplayName','Road')
        hold(ax3,'on')
        plot(ax3,t,ym,'-r','LineWidth',1.5,'DisplayName','Car')
        hold(ax3,'off')
        xlabel(ax3,'Time (s)')
        ylabel(ax3,'Meters')
        legend(ax3)
        grid(ax3,'on')

        %% Test Cases

        % ============================================================
        % Suspension Analysis
        % ============================================================
        
        % Analyze m, k, c relationship
            % Ensure arrays are same size

        fn = (1/(2*pi))*sqrt(k/m);  % natural frequency in Hz
        % Ideal Damping Ratios 0.2 - 0.5 Better Comfort 0.6 - 0.9 Better Handling
        zeta = c/(2*sqrt(k*m));

        freqLabel.Text = sprintf('Natural Frequency = %.2f Hz',fn);

        if fn < 1
            freqLabel.Text = sprintf('%s   (Too Low)',freqLabel.Text);
        elseif fn > 2
            freqLabel.Text = sprintf('%s   (Too High)',freqLabel.Text);
        else
            freqLabel.Text = sprintf('%s   (Acceptable)',freqLabel.Text);
        end

        zetaLabel.Text = sprintf('Damping Ratio = %.3f',zeta);

        if zeta > 1
            zetaLabel.Text = sprintf('%s   Overdamped',zetaLabel.Text);
        elseif zeta < 0.1
            zetaLabel.Text = sprintf('%s   Underdamped',zetaLabel.Text);
        else
            zetaLabel.Text = sprintf('%s   Acceptable',zetaLabel.Text);
        end

    end

end