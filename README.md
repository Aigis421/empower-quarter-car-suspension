<table>
<td><img src="https://gist.githubusercontent.com/robertogl/e0115dc303472a9cfd52bbbc8edb7665/raw/suspension.png"  width=500 /></td>
<td><p><h1>Quarter-Car Suspension Modeling and Simulation with Simscape Multibody</h1></p>
<p>The Car Bois model and tune a Simscape Multibody quarter-car suspension model using an automated road test suite.</p>
</table>

## Project Hub Link

https://drive.google.com/drive/folders/1Rf73Mk84F7ZP1KKvAoLgGcYQYsR3elV3

## Team Name

Car Bois

##Problem Statement

This project addresses the need for force dissipation in moving systems. Anything that moves, wiggles, or bounces needs some sort of suspension to keep it intact over its useful lifetime. By designing using simulation models these systems can be quickly subjected to different scenarios to judge their efficacy in diverse situations before prototyping. To keep things manageable, this team will be simulating only ¼ of a car’s full suspension.

##Approach 

We followed the suggested steps on the Github project page to divide the workload and create the separate recommended deliverables to be used all together in the final project (Scripts, Models, Simulations). We used the reference Mass-Spring-Damper in Simulink and the Simscape simulation for our models. Based on our results, we continued to iterate and improve on our models and come up with theoretical cases and testing.

### Suggested Steps:
Open the "QuarterCarSuspension_StudentProjectTemplate.mlx" Live Script in MATLAB as a starting point for your project. The Live Script contains more detailed information for each of the suggested steps.

1. Start with a baseline quarter-car multibody model
   - Build two rigid bodies:
        - **Sprung mass** (vehicle body corner)
        - **Unsprung mass** (wheel assembly)
    - Connect them with:
        - Suspension spring + damper (parameterized)
        - Tire vertical compliance element (parameterized or fixed)
    - Provide a road displacement input (e.g., a vertically moving “road plate” or equivalent road excitation subsystem)

2. Create a road test suite (3–5 cases)
    - Implement a set of road displacement profiles such as:
        - **Speed bump** (smooth hump)
        - **Pothole** (smooth dip)
        - **Rough road** (band-limited noise)
        - (optional) **Washboards** (sinusoidal corrugation)
        - (optional) **Two bumps** (repeatability / transient recovery)
    - Deliverable: `roadSuite.m` (or `roadSuite.mat`) that produces named road inputs, plus a short note explaining how each profile was made.

3. Log signals and define objective metrics
    - Log at minimum:
        - Sprung-mass vertical acceleration
        - Suspension travel (relative displacement)
        - Tire deflection (relative wheel-to-road displacement) or normal-force proxy
    - Compute metrics per road case, such as:
        - **Comfort metric:** RMS sprung acceleration (and/or peak)
        - **Packaging metric:** max suspension travel
        - **Road-holding metric:** max tire deflection (or variability)
    - Deliverable: a function like:
        - `results = scoreSuspension(simout, roadName)`
        - returning a struct/table of metrics and a single “score”

4. Build an automated test runner (easy “difference maker”)
    - Create a script/function that:
        - Runs all road cases automatically
        - Logs results to a table
        - Outputs a clear **pass/fail** for each requirement
        - Generates a single summary figure (or a brief report)
    - Example deliverable: `runAllTests.m` → returns `summaryTable` and saves plots to `/results`
    - This makes your project notably more “industry-like” while staying low difficulty.

5. Tune suspension parameters
    - Tune at least:
        - Suspension spring stiffness `Ks`
        - Suspension damping `Cs`
    - Two tuning options:
        - **Option A — Parameter sweep (recommended for beginners)**
            - Sweep `Ks` and `Cs` across small ranges
            - Score each design across all road cases
            - Select a design that meets constraints and minimizes score      
        - **Option B — Lightweight optimization (recommended for intermediate-level users)**
            - Use a simple search (pattern search / constrained minimization / custom heuristic)
            - Minimize comfort subject to travel/deflection limits
    - Deliverable: chosen parameter values + justification using plots/tables.

6. Validate robustness with one simple variation
    - Pick one low-effort robustness test:
      - **Payload change:** increase sprung mass by +25% and rerun the suite
      - **Component tolerance:** apply ±10% variation to `Ks` and `Cs` for a small Monte Carlo set (e.g., 20 trials)
  - Deliverable: a robustness summary (worst-case metrics and pass rate).

  
## Road Profiles
### Our four road profiles and brief descriptions of how each was made and operates.

- Profile 1 (Speed Bump)
    - 
- Profile 2 (Rough Terrain)
    - 
- Profile 3 (Washboards)
    -
- Profile 4 (Rough Terrain + Pothole)
    -


## Reference Material
- [Mass-Spring-Damper in Simulink and Simscape](https://www.mathworks.com/help/simscape/ug/mass-spring-damper-in-simulink-and-simscape.html) 
- [MATLAB Onramp](https://matlabacademy.mathworks.com/details/matlab-onramp/gettingstarted)
- [Simscape Onramp](https://matlabacademy.mathworks.com/details/simscape-onramp/simscape)
- [Interactive Mass-Spring-Damper Tutorial](https://www.mathworks.com/matlabcentral/fileexchange/94585-mass-spring-damper-systems)
- [Technical Guide to Optimizing Vehicle Suspension Design Through System-Level Simulation](https://www.mathworks.com/company/technical-articles/optimizing-vehicle-suspension-design-through-system-level-simulation.html)
- [Video Tutorial on Analyzing the Ride Quality of a Car Suspension](https://www.youtube.com/watch?v=aEPcyBqubb8)
- [Simulink Onramp](https://matlabacademy.mathworks.com/details/simulink-onramp/simulink)
- [Simscape Multibody Documentation](https://www.mathworks.com/help/sm/)
- [Simscape Physical Modeling Documentation](https://www.mathworks.com/help/simscape/)
- [Mass-Spring-Damper in Simulink and Simscape (reference example)](https://www.mathworks.com/help/simscape/ug/mass-spring-damper-in-simulink-and-simscape.html) 