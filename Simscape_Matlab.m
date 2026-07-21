clear;

Ks = 30647.196473;
c = 800;
M = 108;
m = 50;
Kt = 114182.69772;

disp('1. Smooth speed bump')
disp('2. Rough terrain')
disp('3. Smooth median strip')
disp('4. Rough terrain + Pothole')
%select = input("Select Road Profile: ");
select = 4;

model = 'MassSpringDamper_simulink';
open_system(model);
Smodel = sim(model);

t = Smodel.tout;
S_pos = Smodel.SprungMassPos.Data;

plot(t,S_pos)