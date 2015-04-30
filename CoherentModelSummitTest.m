% Test the coherent model on summit
% Compare the Tb results with MEMLS

clear
Runs=3;
Num_real = 400; % Number of realizations
%% 1 Get data
%1.1 Temperature data: from Ken's "resampled GISP temps, 1 meter" on the site
%    The data's unit is C
Temps.Data=load('SummitData/GISP1m.txt');
Temps.z=Temps.Data(:,1);
Temps.T=Temps.Data(:,2);

%1.2 Get grid 
%    for 0-100m, layer thickness is 1cm
%    for 100-1000m, layer thickness is 0.5m
%    for the rest,layer thickness is 1m

Grid=CoherentGrid(Temps.z(end));

%1.3 Density data: using the Twickler and Morris data 
load('DecayDensityModel/DensityModel.mat');
S=load('DecayDensityModel/RandState.mat');
density=GetRealizations_v2(RhoMod,Grid,Num_real,S);


%1.4 Get Sensor data
cd SensorData
UWBRADAntennaConstant
cd ../
 
%1.5 % Interpolate temperature to grid and convert to K
T=interp1(Temps.z,Temps.T,Grid.Z)+273.16;

%% 2 Put together inputs
%2.1 theta, frequency, depth and temperature
theta=[0 40 50];
Input_param.frequency=fGhz.*1e9;
Input_param.theta=theta;
Input_param.depth = Grid.Z;
Input_param.Temp_profile =T;

%Density
% ESL density model for comparing. If using this density as input, please
% comment 1.2
% alpha_d=30; % Damping Coefficient
% Delta = 0.040; % Standard Deviation
% lc = 0.03;   % Correlation Length, it can be an array


cd Coherent_model
Tb_V=zeros(Num_real,length(theta),length(fGhz));
Tb_H=zeros(Num_real,length(theta),length(fGhz));
Tb_c=zeros(Num_real,length(theta),length(fGhz));

tic
for n=1:Num_real
    Input_param.density_profile = density(n,:);
    %ESL density model,if using,comment last line
    %density = density_profile(Grid.Z,Delta,lc,alpha_d);
    %Input_param.density_profile = density  ;
    if mod(n,5)==0,
        disp(['Running realization #' num2str(n) '/' num2str(Num_real)])
    end
    [Tb_V(n,:,:),Tb_H(n,:,:),Tb_c(n,:,:)] = coherent_model(Input_param);
end
    
    %Tb_V_m, Tb_H_m, Tb_m are matrix N*F where N is the number of incidence angles
    %and F the number of frequencies
    %The Tb is finally stored in a N*F*M matrix, with each page for a
    %point, each column for a frequency and each row for a incidence angle
    Tb_V_m =squeeze(mean(Tb_V,1));
    Tb_H_m =squeeze(mean(Tb_H,1));
    Tb_c_m=squeeze(mean(Tb_c,1));      
toc   

RunName=['CMTb' num2str(Runs)];
InputName=['Input_param' num2str(Runs)];
cd ../Runs/;
save (RunName,'Tb_V_m','Tb_H_m','Tb_c_m')
save (InputName,'Input_param')

cd ../
PlotInput
%% 3. plot the results
    figure
    plot(fGhz, Tb_V_m,'linewidth',3)
    set(gca,'fontsize',14)
    title('Brightness Temperature Vertical Polarization')
    xlabel('Frequency (GHz)')
    ylabel('Brightness Temperature (K)')
    legend('0', '40', '50')
    
    figure
    plot(fGhz, Tb_H_m,'linewidth',3)
    set(gca,'fontsize',14)
    title('Brightness Temperature Horizontal Polarization' )
    xlabel('Frequency (GHz)')
    ylabel('Brightness Temperature (K)')
    legend('0', '40', '50')
    
    figure
    plot(fGhz, Tb_c_m,'linewidth',3)
    set(gca,'fontsize',14)
    title('Brightness Temperature')
    xlabel('Frequency (GHz)')
    ylabel('Brightness Temperature (K)')
    legend('0', '40', '50')