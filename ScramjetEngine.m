function EnginePerf = ScramjetEngine(InletMap,DynamicPressure,FreestreamMach,AngleofAttack, SI_Flag)
    %Constants
    gamma = 1.4;
    %R_BTU_lbmolR = 1.986;
    %R_ftlbf_lbmolR = 1545;
    R_J_kmolK = 8314; 
    MW_air = 28.965;
    %Cp_air_BTUlbmR = (R_BTU_lbmolR/MW_air)*gamma/(gamma-1);
    CP_air_j_kmolK = (R_J_kmolK/MW_air)*gamma/(gamma-1);

    % get inlet performance data
    Inlet = getGHV(InletMap,FreestreamMach,AngleofAttack,DynamicPressure,SI_Flag);
    
    % Station 0 - Freestream
    Station0=Station;
    Station0.Mach = FreestreamMach;
    Station0.Velocity_ms = Inlet.FreestreamVelocity_ms;
    Station0.Pressure_Pa = Inlet.FreestreamPressure_Pa;
    Station0.TotalPressure_Pa = Inlet.FreestreamTotalPressure_Pa;
    Station0.Temperature_K = Inlet.FreestreamTemperature_K;
    Station0.TotalTemperature_K = Inlet.FreestreamTotalTemperature_K;
    Station0.MassFlowRate_kgs = Inlet.MassFlowRate_kgs;
    Station0.Area_m2 = Inlet.EffectiveStreamtubeCapture_m2;
    EnginePerf.Station0 = Station0;
    
    % Station 1 - Isolator Entrance
    Station1=Station;
    Station1.Mach = Inlet.ThroatMachNumber;
    Station1.Velocity_ms = Inlet.ThroatVelocity_ms;
    Station1.Pressure_Pa = Inlet.ThroatPressure_Pa;
    Station1.TotalPressure_Pa = Inlet.ThroatTotalPressure_Pa;
    Station1.Temperature_K = Inlet.ThroatTemperature_K;
    Station1.TotalTemperature_K = Inlet.ThroatTotalTemperature_K;
    Station1.MassFlowRate_kgs = Inlet.MassFlowRate_kgs;
    Station1.Area_m2 = Inlet.ThroatArea_m2;
    EnginePerf.Station1 = Station1;
    
    %Station 2 - Isolator Exit / Combustor Entrance
    Station2 = Station;
    Station2.Mach = Inlet.IsolatorExitMach;
    Station2.Velocity_ms = Inlet.IsolatorExitMach*sqrt(gamma*(R_J_kmolK/MW_air)*Inlet.IsolatorExitTemperature_K);
    Station2.Pressure_Pa = Inlet.IsolatorExitPressure_Pa;
    Station2.TotalPressure_Pa = Inlet.IsolatorExitTotalPressure_Pa;
    Station2.Temperature_K = Inlet.IsolatorExitTemperature_K;
    Station2.TotalTemperature_K = Inlet.IsolatorExitTotalTemperature_K;
    Station2.MassFlowRate_kgs = Inlet.MassFlowRate_kgs;
    Station2.Area_m2 = Inlet.IsolatorEffectiveExitArea_m2;
    EnginePerf.Station2 = Station2;

    %get combustor data
    Station4 = getCombustorOutlet(Station2);
    EnginePerf.Station4 = Station4;
    
    % get Nozzle data
    Station9 = getNozzle(Station4,Station0);
    EnginePerf.Station9 = Station9;
    
    
    % Calculate total Thrust
    
    
    %Calculate total Lift
    
    
    %Calculate total engine Drag


end


function S4 = getCombustorOutlet(S2)
    gamma = 1.4;
    R_J_kmolK = 8314; 
    MW_air = 28.965;
    CP_air_J_kgK = (R_J_kmolK/MW_air)*gamma/(gamma-1);
    H_f_J_kg = 43.5e6; %heating value of Fuel
    T_f_K = 298; %initial Temperature of Fuel
    H_vap_J_kg = 446e3; % Heat of vaporization
    Cp_f_J_kgK = 480*4.1868; % Specific heat from cal/kgK to J/kgK

    S4 = Station;
    S4.Mach = 1; % adaptive geometry and fuel flow ensures flow is choked
    Tt4 = 2600;
    S4.TotalTemperature_K = Tt4; % adaptive fuel flow will maximize stagnation temperature
    S4.Temperature_K = S4.TotalTemperature_K / (1+0.5*(gamma-1)*S4.Mach^2); % solve for exit Temperature
    S4.Velocity_ms = S4.Mach *sqrt(gamma*(R_J_kmolK/MW_air)*S4.Temperature_K); % Solve for exit velocity
    
    % Solve for Fuel Flow Rate to hit Tt4
    Tt2 = S2.TotalTemperature_K;
    mdot_air = S2.MassFlowRate_kgs;
    dH_air = mdot_air*CP_air_J_kgK*(Tt4-Tt2); % Joules/sec
    mdot_f = dH_air /(H_f_J_kg - Cp_f_J_kgK*(Tt4-T_f_K)- H_vap_J_kg); %kg/sec
    S4.MassFlowRate_kgs = mdot_air + mdot_f;
    
    %Solve for Pressure at exit - This is an estimate... Cal's model is
    %real model
    S4.Pressure_Pa = S2.Pressure_Pa*((1+0.5*(gamma-1)*S2.Mach^2)/(1+0.5*(gamma-1))); % Estimate of pressure gain for supersonic combustion
    S4.TotalPressure_Pa = S4.Pressure_Pa*(1+0.5*(gamma-1)*S4.Mach^2)^(gamma/(gamma-1)); % Results in stagnation Pressure loss
    
    %Solve for variable throat Area
    S4.Area_m2 = S4.MassFlowRate_kgs * (R_J_kmolK/MW_air) * S4.Temperature_K / (S4.Pressure_Pa*S4.Velocity_ms); % m^2
end

function S9 = getNozzle(S4,S0)
%Constants
    gamma = 1.4;
    R_J_kmolK = 8314; 
    MW_air = 28.965;
% conservation of mass
    S9.MassFlowRate_kgs = S4.MassFlowRate_kgs;
    
% For now, assume perfect expansion - update with Marks Nozzle model later
    Pt9 = S4.TotalPressure_Pa;
    P9 = S0.Pressure_Pa;
    S9.Pressure_Pa = P9;
    S9.TotalPressure_Pa = Pt9;
   
    Tt9 = S4.TotalTemperature_K;
    S9.TotalTemperature_K = Tt9;
    T9 = Tt9 * (P9/Pt9)^((gamma-1)/gamma);
    S9.Temperature_K = T9;
    
    M9 = (((Pt9/P9)^((gamma-1)/gamma) -1)*2/(gamma-1))^0.5;
    S9.Mach = M9;
    S9.Velocity_ms = S9.Mach *sqrt(gamma*(R_J_kmolK/MW_air)*S9.Temperature_K); % Solve for exit velocity

    %Solve for variable final flow Area
    S9.Area_m2 = S9.MassFlowRate_kgs * (R_J_kmolK/MW_air) * S9.Temperature_K / (S9.Pressure_Pa*S9.Velocity_ms); % m^2

end