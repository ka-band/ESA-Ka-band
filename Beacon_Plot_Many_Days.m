%Filename: Beacon_plot_many_day
%
% Purpose:
%   Read in one several days of beacon and weather data and plot results.
%   Save plots to file in .fig format
%
% Inputs:
%   None
% Example
%   1. Run Beacon_Plot_Many_days.m to extract ascii values from files and save
%   in Matlab binary format
%   2. Run Postprocess days
%   3. Run process months
%   4. Run Plot_Monthly_data
%
% Lars E Bråten Aug 2011, Mod jan 2012 Mod 12. mars for Eggemoen
%Modified for ESA project Oct 2013, LEB


close all
clear all
format long e

addpath c:\Prosjekter\Satellitt\Beacon\ESA-Ka-band\

%Parameters
YYYY_start = '2013'; %Year start
MM_Start = '10'; %Month start
DD_Start = '04'; %Day start
YYYY_end = '2013';%Year end
MM_End = '10'; %Month end
DD_End = '15'; %Day end
TrackThreshold = 3; %dB carrrier above noise threshold for Track
F_threshold = 5;% Hz idf carrier freq changes more than this compared to last freq out of synch is decleared (Track = 0)

% location = 'Eggemoen';
receiver='EXA';
%location = 'Vadsø';
location = 'Nittedal';
%location = 'Røst';
%location = 'Isfjord';
%location = 'Kjeller'

proc_beacon = 'no'; %Analayze (preprocess) beacon only
proc_weather = 'yes'; %Analyse (preprocess) weather only
fix_weather_dates='yes'; %Add timestamp to filenames and copy the original files to new ones

pl_temp = 'no';%Plot data during reading of files (beacon)
verbose = 'no'; %Plot beacontime series uring reading
pl_tempW = 'no';%Plot data during reading of files (weather)
verboseW = 'no'; %Weather
pl_ts = 'yes';%Plot time series of beacon level
pl_comb = 'yes'; %Plot beacon and weather in same figure
saveplot = 'yes';
plot_spectrum = 'yes';
savefiles = 'yes'; %Save processed files
ple = 'yes';%Plot Ebem results when reading files
%Initial stuff
StartDir = pwd;
StartTimeStr = strcat(YYYY_start,'-',MM_Start,'-',DD_Start,'-','00-00-00-000');
EndTimeStr = strcat(YYYY_end,'-',MM_End,'-',DD_End,'-','23-59-59-999');

if strcmp(location,'Kjeller')
    stop
elseif strcmp(location,'Eggemoen')
    DataDirBeacon = 'c:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Server 192.168.1.10\Beacon';
    DataDirSpectrum = 'C:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Server 192.168.1.10\Signal';
    DataDirWeatherWXT = 'c:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Server 192.168.1.10\WXT';
    DataDirWeatherTB = 'C:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Server 192.168.1.10\TB';
    PlotDir = 'c:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Eggemoen\DayPlots';
    ResDir = 'c:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Eggemoen\ProcessedData';
elseif strcmp(location,'Vadsø')
    DataDirBeacon = 'c:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Server 192.168.3.10\Beacon';
    DataDirSpectrum = 'C:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Server 192.168.3.10\Signal';
    DataDirWeatherWXT = 'c:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Server 192.168.3.10\WXT';
    DataDirWeatherTB = 'C:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Server 192.168.3.10\TB';
    PlotDir = 'c:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Vadsø\Dayplots';
    ResDir = 'c:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Vadsø\ProcessedData';
elseif strcmp(location,'Nittedal')
     DataDirBeacon = 'c:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Server 10.47.62.13\Beacon';
    DataDirSpectrum = 'C:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Server 10.47.62.13\Signal';
    DataDirWeatherWXT = 'c:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Server 10.47.62.13\WXT';
    DataDirWeatherTB = 'C:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Server 10.47.62.13\TB';
    PlotDir = 'c:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Nittedal\Dayplots';
    ResDir = 'c:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Nittedal\ProcessedData';
elseif strcmp(location,'Røst')
    stop
elseif strcmp(location,'Isfjord')
     DataDirBeacon = 'c:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Server 10.47.249.17\Beacon';
    DataDirSpectrum = 'C:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Server 10.47.249.17\Signal';
    DataDirWeatherWXT = 'c:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Server 10.47.249.17\WXT';
    DataDirWeatherTB = 'C:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Server 10.47.249.17\TB';
    PlotDir = 'c:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Isfjord\Dayplots';
    ResDir = 'c:\Prosjekter\Satellitt\Beacon\Målinger\ESA\Isfjord\ProcessedData';
else
    disp('Loacation not defined')
    stop
end
ipp = 1:10;
numberofdays = daysact(StartTimeStr(ipp),EndTimeStr(ipp)) + 1;
disp(['Number of days to process ',num2str(numberofdays)])


if strcmp(proc_weather,'yes')
    %***********************************
    %Read weather file data (directory list)
    %***********************************
    cd(DataDirWeatherWXT)%Change directory
    if strcmp(fix_weather_dates,'yes')
        dummy=FixTimeStamp([location(1),'*_WXT*.dat']);
    end
    % Get an overview of existing files
    StartNameW = ['y*_WXT*.dat'];
    DW = dir(StartNameW);
    cd(DataDirWeatherTB)%Change directory
    if strcmp(fix_weather_dates,'yes')
        dummy=FixTimeStamp([location(1),'*_TB*.dat']);
    end
    StartNameTB = ['y*_TB*.dat']; %TB instrument
    DTB = dir(StartNameTB);
    %Generate start and stop matrix A (3 columns) using datenum (start, stop, samples)
    AW = StartStopMatrix(DW,'WXT',location,receiver);
    ATB =  StartStopMatrix(DTB,'TB',location,receiver);
end

%****************************************
%Read beacon file data (directory list)
%***************************************
if strcmp(proc_beacon,'yes')
    cd(DataDirBeacon)%Change directory
    % Get an overview of existing AGC files
    %Files from EXA
    StartName = ['EXA*.mat']; %beacon Files from FSP spectrum analyzer
    StartNameSpec = ['EXA_TRACE*.mat']; %spectrum Files from FSP spectrum analyzer
    D = dir(StartName);
    cd(DataDirSpectrum)
    Dspec = dir(StartNameSpec);
    %Generate start and stop matrix A (3 columns) using datenum (start, stop, samples)
    A = StartStopMatrix(D, 'Beacon',location,receiver);
    As = StartStopMatrix(Dspec, 'Spectrum',location,receiver);
end

%Main loop
for daycount = 0 : numberofdays - 1 %Traverse the days
    close all
    %Locate relevant files in matrix AW for WXT520
    TargetStart = datenum(StartTimeStr,'yyyy-mm-dd-HH-MM-SS-FFF') + daycount;
    TargetEnd = TargetStart + 1;
    %TargetEnd = datenum(EndTimeStr,'yyyy-mm-dd-HH-MM-SS-FFF') +1;%daycount; %TargetStart + 1;
    disp(['Processing day ',datestr(TargetStart)])
    
    %********* Read weather data **************************************
    if strcmp(proc_weather,'yes')
        % Whole file within timelimits or cross at beginning or cross at end
        ipW = find(((AW(:,1) >= TargetStart) & (AW(:,2) <= TargetEnd)) ...
            | ((AW(:,1) < TargetStart) & (AW(:,2) > TargetStart)) ...
            | ((AW(:,2) > TargetEnd) & (AW(:,1) < TargetEnd))); %WXT520
if ~isempty(ATB)        
            ipTB = find(((ATB(:,1) >= TargetStart) & (ATB(:,2) <= TargetEnd)) ...
                | ((ATB(:,1) < TargetStart) & (ATB(:,2) > TargetStart)) ...
                | ((ATB(:,2) > TargetEnd) & (ATB(:,1) < TargetEnd))); %TB
            if ~isempty(ipTB)
                disp(['Load ',num2str(length(ipTB)), ' TB weather file(s) for day ',datestr(TargetStart)])
            else
                disp(['No TB weather files for day ',datestr(TargetStart)])
            end
else
    ipTB=[];
    disp('No TB data available')
end
        if ~isempty(ipW)
            disp(['Load ',num2str(length(ipW)), ' WXT520 weather file(s) for day ',datestr(TargetStart)])
        else
            disp(['No WXT520 weather files for day ',datestr(TargetStart)])
        end
        
        Weather = LoadWeatherFiles(DW, ipW, AW,DTB, ipTB, ATB ,TargetStart, TargetEnd, pl_tempW, location, verboseW, DataDirWeatherWXT,  DataDirWeatherTB);
        
        %Plot WXT 520 data
        if strcmp(pl_ts,'yes') && ~isempty(ipW) && ~isempty(Weather.WXT.Time)
            scrsz=get(0,'ScreenSize');
            m=figure('Position',[1 0 scrsz(3) scrsz(4)]);
            set(gcf,'papertype','A4','PaperPositionMode', 'auto','PaperOrientation','landscape','PaperUnits', ...
                'centimeters','papersize',[ 2.098404194812001e+001, 2.967743169791000e+001])
            subplot(7,1,1)
            plot(Weather.WXT.Time,Weather.WXT.RainAcc,'b-')
            if ~isempty(Weather.WXT.Invalid)
                hold on
                plot(Weather.WXT.Time(Weather.WXT.Invalid),Weather.WXT.RainAcc(Weather.WXT.Invalid),'r-.')
            end
            ylabel('RA (mm)')
            %xlabel('Time')
            title(['WXT520 sensor, ',datestr(Weather.WXT.Time(1))])
            datetick2('x')%,'HH:MM:SS')
            grid on
            subplot(7,1,2)
            plot(Weather.WXT.Time,Weather.WXT.RainInt)
            if ~isempty(Weather.WXT.Invalid)
                hold on
                plot(Weather.WXT.Time(Weather.WXT.Invalid),Weather.WXT.RainInt(Weather.WXT.Invalid),'r-.')
            end
            ylabel('RI (mm/h)')
            datetick2('x')%,'HH:MM:SS')
            grid on
            subplot(7,1,3)
            plot(Weather.WXT.Time,Weather.WXT.Temp)
            if ~isempty(Weather.WXT.Invalid)
                hold on
                plot(Weather.WXT.Time(Weather.WXT.Invalid),Weather.WXT.Temp(Weather.WXT.Invalid),'r-.')
            end
            ylabel('T (C)')
            datetick2('x')%,'HH:MM:SS')
            grid on
            subplot(7,1,4)
            plot(Weather.WXT.Time,Weather.WXT.HailInt)
            if ~isempty(Weather.WXT.Invalid)
                hold on
                plot(Weather.WXT.Time(Weather.WXT.Invalid),Weather.WXT.HailInt(Weather.WXT.Invalid),'r-.')
            end
            ylabel('H (hits/cm^2)')
            datetick2('x')%,'HH:MM:SS')
            subplot(7,1,5)
            plot(Weather.WXT.Time,Weather.WXT.MaxWindSpeed)
            if ~isempty(Weather.WXT.Invalid)
                hold on
                plot(Weather.WXT.Time(Weather.WXT.Invalid),Weather.WXT.MaxWindSpeed(Weather.WXT.Invalid),'r-.')
            end
            ylabel('MW (m/s)')
            datetick2('x')%,'HH:MM:SS')
            subplot(7,1,6)
            plot(Weather.WXT.Time,Weather.WXT.RelHumidity)
            if ~isempty(Weather.WXT.Invalid)
                hold on
                plot(Weather.WXT.Time(Weather.WXT.Invalid),Weather.WXT.RelHumidity(Weather.WXT.Invalid),'r-.')
            end
            ylabel('RH (%)')
            datetick2('x')%,'HH:MM:SS')
            subplot(7,1,7)
            plot(Weather.WXT.Time,Weather.WXT.Pressure)
            if ~isempty(Weather.WXT.Invalid)
                hold on
                plot(Weather.WXT.Time(Weather.WXT.Invalid),Weather.WXT.Pressure(Weather.WXT.Invalid),'r-.')
            end
            ylabel('P (hPa)')
            datetick2('x')%,'HH:MM:SS')
            xlabel('Time')
            if strcmp(saveplot,'yes')
                drawnow
                cd(PlotDir)
                fn = ['Weather_WXT_',datestr(TargetStart,'yy-mm-dd')];
                saveas(m,[fn,'.fig'],'fig')
                %print(m,'-depsc','-tiff','-r300',[fn,'.eps']) %Eps with tiff preview
                %print(m,'-djpeg90',[fn,'.jpg']) %jpeg
                %close
            end
        end
        %Plot logger data with TB
        if strcmp(pl_ts,'yes') && ~isempty(ipTB)
            scrsz=get(0,'ScreenSize');
            m=figure('Position',[1 0 scrsz(3) scrsz(4)]);
            set(gcf,'papertype','A4','PaperPositionMode', 'auto','PaperOrientation','landscape','PaperUnits', 'centimeters','papersize',[ 2.098404194812001e+001, 2.967743169791000e+001])
            subplot(9,1,1)
            if isfield(Weather,'Logger')%Period when logger did not record rain
                if length(Weather.Logger.Time)== length(Weather.Logger.RainInt)
                    plot(Weather.Logger.Time,Weather.Logger.RainInt)
                    if ~isempty(Weather.Logger.Invalid)
                        hold on
                        plot(Weather.Logger.Time(Weather.Logger.Invalid),Weather.Logger.RainInt(Weather.Logger.Invalid),'r-.')
                    end
                end
            else
                plot(Weather.WXT.Time,Weather.WXT.RainInt)
                if ~isempty(Weather.WXT.Invalid)
                    hold on
                    plot(Weather.WXT.Time(Weather.WXT.Invalid),Weather.WXT.RainInt(Weather.WXT.Invalid),'r-.')
                end
            end
            ylabel('RI (mm/h)')
            datetick2('x')%,'HH:MM:SS')
            grid on
            if isfield(Weather,'Logger')
                title(['TB and WXT sensors from logger, ',datestr(Weather.Logger.Time(1))])
            elseif isfield(Weather,'WXT')
                if ~isempty(Weather.WXT.Time)
                    title(['WXT sensor from logger, ',datestr(Weather.WXT.Time(1))])
                else
                    title('??')
                end
            end
            datetick2('x')%,'HH:MM:SS')
            grid on
            subplot(9,1,2)
            if isfield(Weather,'Logger') %Period when logger did not record rain
                if length(Weather.Logger.Time)== length(Weather.Logger.RainAcc)
                    plot(Weather.Logger.Time,Weather.Logger.RainAcc,'b-')
                    if ~isempty(Weather.Logger.Invalid)
                        hold on
                        plot(Weather.Logger.Time(Weather.Logger.Invalid),Weather.Logger.RainAcc(Weather.Logger.Invalid),'r-.')
                    end
                end
            else
                plot(Weather.WXT.Time,Weather.WXT.RainAcc)
                if ~isempty(Weather.WXT.Invalid)
                    hold on
                    plot(Weather.WXT.Time(Weather.WXT.Invalid),Weather.WXT.RainAcc(Weather.WXT.Invalid),'r-.')
                end
            end
            ylabel('RA (mm)')
            subplot(9,1,3)
            if isfield(Weather,'Logger')
                ipsnow  = 1:length(Weather.Logger.SnowIncr);
                plot(Weather.Logger.Time(ipsnow),cumsum(Weather.Logger.SnowIncr))
                if ~isempty(Weather.Logger.Invalid)
                    hold on
                    plot(Weather.Logger.Time(Weather.Logger.Invalid),cumsum(Weather.Logger.SnowIncr(Weather.Logger.Invalid)),'r-.')
                end
            end
            ylabel('AS (mm)')
            datetick2('x')%,'HH:MM:SS')
            subplot(9,1,4)
            if isfield(Weather,'Logger')
                if length(Weather.Logger.Time)== length(Weather.Logger.HailInt)
                    plot(Weather.Logger.Time,Weather.Logger.HailInt)
                    if ~isempty(Weather.Logger.Invalid)
                        hold on
                        plot(Weather.Logger.Time(Weather.Logger.Invalid),Weather.Logger.HailInt(Weather.Logger.Invalid),'r-.')
                    end
                end
            else
                plot(Weather.WXT.Time,Weather.WXT.HailInt)
                if ~isempty(Weather.WXT.Invalid)
                    hold on
                    plot(Weather.WXT.Time(Weather.WXT.Invalid),Weather.WXT.HailInt(Weather.WXT.Invalid),'r-.')
                end
            end
            ylabel('HI (hi/cm2)')
            datetick2('x')%,'HH:MM:SS')
            subplot(9,1,5)
            if isfield(Weather,'Logger')
                ipwater = 1:length(Weather.Logger.WaterIncrement);
                plot(Weather.Logger.Time(ipwater),Weather.Logger.WaterIncrement)
                if ~isempty(Weather.Logger.Invalid)
                    hold on
                    plot(Weather.Logger.Time(Weather.Logger.Invalid),Weather.Logger.WaterIncrement(Weather.Logger.Invalid),'r-.')
                end
            end
            ylabel('WAI (mm)')
            datetick2('x')%,'HH:MM:SS')
            grid on
            subplot(9,1,6)
            if isfield(Weather,'Logger')
                plot(Weather.Logger.Time(ipwater),Weather.Logger.WaterAcc)
                if ~isempty(Weather.Logger.Invalid)
                    hold on
                    plot(Weather.Logger.Time(Weather.Logger.Invalid),Weather.Logger.WaterAcc(Weather.Logger.Invalid),'r-.')
                end
            end
            ylabel('WAA (mm)')
            datetick2('x')%,'HH:MM:SS')
            grid on
            subplot(9,1,7)
            if isfield(Weather,'Logger')
                ipwind = 1:length(Weather.Logger.WindSpeed);
                plot(Weather.Logger.Time(ipwind),Weather.Logger.WindSpeed)
                if ~isempty(Weather.Logger.Invalid)
                    hold on
                    plot(Weather.Logger.Time(Weather.Logger.Invalid),Weather.Logger.WindSpeed(Weather.Logger.Invalid),'r-.')
                end
            end
            ylabel('WS (m/s)')
            datetick2('x')%,'HH:MM:SS')
            subplot(9,1,8)
            if isfield(Weather,'Logger')
                iphum  = 1:length(Weather.Logger.RelHumidity);
                plot(Weather.Logger.Time(iphum),Weather.Logger.RelHumidity)
                if ~isempty(Weather.Logger.Invalid)
                    hold on
                    plot(Weather.Logger.Time(Weather.Logger.Invalid),Weather.Logger.RelHumidity(Weather.Logger.Invalid),'r-.')
                end
            end
            ylabel('RH (%)')
            datetick2('x')%,'HH:MM:SS')
            subplot(9,1,9)
            if isfield(Weather,'Logger')
                
                plot(Weather.Logger.Time(iphum),Weather.Logger.Pressure)
                if ~isempty(Weather.Logger.Invalid)
                    hold on
                    plot(Weather.Logger.Time(Weather.Logger.Invalid),Weather.Logger.Pressure(Weather.Logger.Invalid),'r-.')
                end
            end
            ylabel('P (hPa)')
            datetick2('x')%,'HH:MM:SS')
            xlabel('Time')
            if strcmp(saveplot,'yes')
                drawnow
                cd(PlotDir)
                fn = ['Weather_Logger',datestr(TargetStart,'yy-mm-dd')];
                saveas(m,[fn,'.fig'],'fig')
%                 print(m,'-depsc','-tiff','-r300',[fn,'.eps']) %Eps with tiff preview
%                 print(m,'-djpeg90',[fn,'.jpg']) %jpeg
                %close
            end
        end
        if strcmp(location,'Kjeller') && isfield(Weather,'Logger')
            if any(Weather.Logger.SnowIncr > 0)
                disp('Snow detected !!!!')
                scrsz=get(0,'ScreenSize');
                figure('Position',[1 0 scrsz(3) scrsz(4)]);
                set(gcf,'papertype','A4','PaperPositionMode', 'auto','PaperOrientation','landscape','PaperUnits', 'centimeters','papersize',[ 2.098404194812001e+001, 2.967743169791000e+001])
                plot(Weather.Logger.Time,cumsum(Weather.Logger.SnowIncr))
                if ~isempty(Weather.Logger.Invalid)
                    hold on
                    plot(Weather.Logger.Time(Weather.Logger.Invalid),sumsum(Weather.Logger.SnowInce(Weather.Logger.Invalid)),'r-.')
                end
                xlabel('Time')
                ylabel('Accumulated snow (mm)')
                datetick2('x')%,'HH:MM:SS')
                if strcmp(saveplot,'yes')
                    drawnow
                    cd(PlotDir)
                    fn = ['Snow_',datestr(TargetStart,'yy-mm-dd')];
                    saveas(m,[fn,'.fig'],'fig')
%                     print(m,'-depsc','-tiff','-r300',[fn,'.eps']) %Eps with tiff preview
%                     print(m,'-djpeg90',[fn,'.jpg']) %jpeg
                    %close
                end
            end
        end
        if strcmp(savefiles,'yes')
            cd(ResDir)
            fn = ['Weather_',datestr(TargetStart,'yy-mm-dd'),'.mat'];
            save(fn, 'Weather')
        end
    end
    
    if strcmp(proc_beacon,'yes') && ~isempty(A)
        
        %*********Beacon
        %Locate relevant files in matrix A
        ip = find(((A(:,1) >= TargetStart) & (A(:,2) <= TargetEnd)) ... %In the middle
            | ((A(:,1) < TargetStart) & (A(:,2) > TargetStart)) ... %At the start
            | ((A(:,2) > TargetEnd) & (A(:,1) < TargetEnd))); %At the end
        
        if ~isempty(ip)
            disp(['Load ',num2str(length(ip)), ' beacon files'])
            if length(ip) > 50
                disp(['For mange filer i Beacon_Plot_Many_Days! (',num2str(length(ip)),')'])
                %stop
            end
        else
            disp('No beacon files for this period')
        end
%         cd(DataDirBeacon)%Change directory
        ips = find(((As(:,1) >= TargetStart) & (As(:,2) <= TargetEnd)) ...
            | ((As(:,1) < TargetStart) & (As(:,2) > TargetStart)) ...
            | ((As(:,2) > TargetEnd) & (As(:,1) < TargetEnd)));
        
        if ~isempty(ips)
            disp(['Load ',num2str(length(ips)), ' spectrum files'])
            if length(ips) > 50
                disp(['For mange spektrumfiler i Beacon_Plot_Many_Days! (',num2str(length(ips)),')'])
            end
        else
            disp('No spectrum files for this period')
        end
        
        [BeaconSignal, BeaconSpectrum] = ...
            Load_BeaconFiles_simple(D,Dspec, ip, ips, A, As, TargetStart, TargetEnd, pl_temp, TrackThreshold, F_threshold, location, verbose, receiver, DataDirBeacon, DataDirSpectrum);

        if strcmp(pl_ts,'yes') && ~isempty(ip)
            if ~strcmp(location,'Kjeller')
                scrsz=get(0,'ScreenSize');
                k=figure('Position',[1 0 scrsz(3) scrsz(4)]);
                subplot(3,1,1)
                set(gcf,'papertype','A4','PaperPositionMode', 'auto','PaperOrientation','landscape','PaperUnits', 'centimeters','papersize',[ 2.098404194812001e+001, 2.967743169791000e+001])
                plot(BeaconSignal.Timestamp,BeaconSignal.Carrier,'b.')
                hold on
                ipT = find(BeaconSignal.Track == 0);
                if ~isempty(ipT)
                    BeaconSignal.Level(ipT) = NaN;
                    plot(BeaconSignal.Timestamp(ipT),BeaconSignal.Carrier(ipT),'ro')
                end
                if ~isempty(BeaconSignal.Invalid)
                    plot(BeaconSignal.Timestamp(BeaconSignal.Invalid),BeaconSignal.Carrier(BeaconSignal.Invalid),'ks')
                end
                %legend('Signal','Track','Invalid')
                ylabel('Level (dBm)')
                title(['Beacon and noise, ',datestr(BeaconSignal.Timestamp(1))])
                datetick('x')%,'HH:MM:SS')
                %grid on
                subplot(3,1,2)
                set(gcf,'papertype','A4','PaperPositionMode', 'auto','PaperOrientation','landscape','PaperUnits', 'centimeters','papersize',[ 2.098404194812001e+001, 2.967743169791000e+001])
                plot(BeaconSignal.Timestamp,BeaconSignal.N0dB)
                ylabel('N_0 (dBm/Hz)')
                datetick('x')%,'HH:MM:SS')
                subplot(3,1,3)
                plot(BeaconSignal.Timestamp,BeaconSignal.Frequency-mean(BeaconSignal.Frequency),'b-')
                ylabel('Rel freq (Hz)')
                datetick('x')%,'HH:MM:SS')
                xlabel('Time')
            else %Kjeller
                scrsz=get(0,'ScreenSize');
                k=figure('Position',[1 0 scrsz(3) scrsz(4)]);
                set(gcf,'papertype','A4','PaperPositionMode', 'auto','PaperOrientation','landscape','PaperUnits', 'centimeters','papersize',[ 2.098404194812001e+001, 2.967743169791000e+001])
                subplot(3,1,1)
                plot(BeaconSignal.Timestamp,BeaconSignal.Carrier,'b-')
                ipT = find(BeaconSignal.Track < 1);
                if ~isempty(ipT)
                    hold on
                    plot(BeaconSignal.Timestamp(ipT),BeaconSignal.Carrier(ipT),'ro')
                end
                if ~isempty(BeaconSignal.Invalid)
                    hold on
                    plot(BeaconSignal.Timestamp(BeaconSignal.Invalid),BeaconSignal.Carrier(BeaconSignal.Invalid),'r.')
                end
                ylabel('Carrier (dBm/Hz)')
                title(['Beacon and noise, ',datestr(BeaconSignal.Timestamp(1))])
                datetick('x')%,'HH:MM:SS')
                grid on
                subplot(3,1,2)
                plot(BeaconSignal.Timestamp,BeaconSignal.N0dB,'r-')
                hold on
                plot(BeaconSignal.Timestamp,BeaconSignal.N02dB,'b-.')
                plot(BeaconSignal.Timestamp,BeaconSignal.N03dB,'m:')
                %legend('N0 estimate','Marker 2','Marker 3')
                ylabel('Noise (dBm/Hz)')
                datetick('x')%,'HH:MM:SS')
                grid on
                subplot(3,1,3)
                plot(BeaconSignal.Timestamp,BeaconSignal.Frequency,'b-')
                ylabel('Freq (Hz)')
                datetick('x')%,'HH:MM:SS')
                grid on
                
                
                
            end
            if strcmp(saveplot,'yes')
                drawnow
                if ~isdir(PlotDir)
                    mkdir(PlotDir)
                end
                cd(PlotDir)
                fn = ['Beacon_Noise_',datestr(TargetStart,'yy-mm-dd')];
                saveas(k,[fn,'.fig'],'fig')
                
                %start beacononly
                
                k2=figure;
                
                plot(BeaconSignal.Timestamp,BeaconSignal.Carrier)
                ipT = find(BeaconSignal.Track < 1);
                if ~isempty(ipT)
                    hold on
                    plot(BeaconSignal.Timestamp(ipT),BeaconSignal.Carrier(ipT),'ro')
                end
                if ~isempty(BeaconSignal.Invalid)
                    hold on
                    plot(BeaconSignal.Timestamp(BeaconSignal.Invalid),BeaconSignal.Carrier(BeaconSignal.Invalid),'r.')
                end
                ylabel('Beacon level (dBm)')
                
                datetick('x')%,'HH:MM:SS')
                grid on
                  
                %%% end beacon only
                fn2 = ['Beacon_',datestr(TargetStart,'yy-mm-dd')];
                saveas(k2,[fn2,'.fig'],'fig')
%                 print(k,'-depsc','-tiff','-r300',[fn,'.eps']) %Eps with tiff preview
%                 print(k,'-djpeg90',[fn,'.jpg']) %jpeg
                %close(k)
            end
        end
        if strcmp(plot_spectrum,'yes') %Plot spectrum
            if ~isempty(BeaconSpectrum.Freq)
                First = 1;
                f = BeaconSpectrum.Freq(First,:);
                fm = mean(f);
                scrsz=get(0,'ScreenSize');
                h=figure('Position',[1 0 scrsz(3) scrsz(4)]);
                set(gcf,'papertype','A4','PaperPositionMode', 'auto','PaperOrientation','landscape','PaperUnits', 'centimeters','papersize',[ 2.098404194812001e+001, 2.967743169791000e+001])
                plot(f-fm,BeaconSpectrum.Trace1(First,:),'b-')
                hold on
                plot(f-fm,BeaconSpectrum.Trace2(First,:),'r:')
                xlabel('Frequency (Hz)')
                ylabel('dBm/Hz')
                title([datestr(BeaconSpectrum.Timestamp(First)),', Fc = ',num2str(fm/1e6),' MHz'])
                if strcmp(location,'Kjeller')
                    legend('Trace 1','Trace 2 (avg)')
                end
                grid on
                if strcmp(saveplot,'yes')
                    drawnow
                    cd(PlotDir)
                    fn = ['Spectrum_',datestr(TargetStart,'yy-mm-dd'),' Fc = ',num2str(fm/1e6),' MHz'];
                    saveas(h,[fn,'.fig'],'fig')
%                     print(h,'-depsc','-tiff','-r300',[fn,'.eps']) %Eps with tiff preview
%                     print(h,'-djpeg90',[fn,'.jpg']) %jpeg
                    %close(h)
                end
            end
        end
    end
    if strcmp(proc_weather,'yes') & strcmp(proc_beacon,'yes')
        %Combine beacon level and weather
        if isfield(Weather,'Logger') %Check if wheather data exist
            if ~isempty(Weather.Logger.Time)
                wel = 1;
            else
                wel=0;
            end
        else
            wel=1;
        end
        if isfield(Weather,'WXT')
            if ~isempty(Weather.WXT.Time)
                wew = 1;
            else
                wew=0;
            end
        else
            wew=1;
        end
        weatherexist = wel*wew;
        if strcmp(pl_comb,'yes') && (~isempty(ipW) || ~isempty(ipTB)) && ~isempty(ip) && weatherexist
            scrsz=get(0,'ScreenSize');
            g=figure('Position',[1 0 scrsz(3) scrsz(4)]);
            set(gcf,'papertype','A4','PaperPositionMode', 'auto','PaperOrientation','landscape','PaperUnits', 'centimeters','papersize',[ 2.098404194812001e+001, 2.967743169791000e+001])
            subplot(6,1,1)
            plot(BeaconSignal.Timestamp,BeaconSignal.Carrier,'b-')
            ip = find(BeaconSignal.Track < 1);
            if ~isempty(ip)
                hold on
                plot(BeaconSignal.Timestamp(ip),BeaconSignal.Carrier(ip),'ro')
            end
            if ~isempty(BeaconSignal.Invalid)
                hold on
                plot(BeaconSignal.Timestamp(BeaconSignal.Invalid),BeaconSignal.Carrier(BeaconSignal.Invalid),'r.')
            end
            if isfield(Weather,'Logger')
                title(['Beacon and weather, ',datestr(Weather.Logger.Time(1))])
                ylabel('Carrier (dBm/Hz)')
            else
                title(['Beacon and weather, ',datestr(Weather.WXT.Time(1))])
                ylabel('Carrier (dBm)')
            end
            datetick('x')%,'HH:MM:SS')
            grid on
            subplot(6,1,2)
            plot(BeaconSignal.Timestamp,BeaconSignal.N0dB,'b-')
            %hold on
            %plot(BeaconSignal.Timestamp,BeaconSignal.N02dB,'b-.')
            %plot(BeaconSignal.Timestamp,BeaconSignal.N03dB,'m:')
            %legend('N0 estimate','Marker 2','Marker 3')
            ylabel('Noise (dBm/Hz)')
            datetick('x')%,'HH:MM:SS')
            grid on
            subplot(6,1,3)
            if isfield(Weather,'Logger')
                plot(Weather.Logger.Time,Weather.Logger.RainInt)
                if ~isempty(Weather.Logger.Invalid)
                    hold on
                    plot(Weather.Logger.Time(Weather.Logger.Invalid),Weather.Logger.RainInt(Weather.Logger.Invalid),'r-.')
                end
            else
                plot(Weather.WXT.Time,Weather.WXT.RainInt)
                if ~isempty(Weather.WXT.Invalid)
                    hold on
                    plot(Weather.WXT.Time(Weather.WXT.Invalid),Weather.WXT.RainInt(Weather.WXT.Invalid),'r-.')
                end
            end
            ylabel('RI (mm/h)')
            datetick('x')%,'HH:MM:SS')
            grid on
            subplot(6,1,4)
            if isfield(Weather,'Logger')
                ml = min([length(Weather.Logger.Time) length(Weather.Logger.SnowIncr)]);
                plot(Weather.Logger.Time(1:ml),cumsum(Weather.Logger.SnowIncr(1:ml)))
                if ~isempty(Weather.Logger.Invalid)
                    hold on
                    plot(Weather.Logger.Time(Weather.Logger.Invalid),cumsum(Weather.Logger.SnowIncr(Weather.Logger.Invalid)),'r-.')
                end
            end
            ylabel('AS (mm)')
            datetick('x')%,'HH:MM:SS')
            subplot(6,1,5)
            if isfield(Weather,'Logger')
                plot(Weather.Logger.Time,Weather.Logger.Temp)
                if ~isempty(Weather.Logger.Invalid)
                    hold on
                    plot(Weather.Logger.Time(Weather.Logger.Invalid),Weather.Logger.Temp(Weather.Logger.Invalid),'r-.')
                end
            else
                plot(Weather.WXT.Time,Weather.WXT.Temp)
                if ~isempty(Weather.WXT.Invalid)
                    hold on
                    plot(Weather.WXT.Time(Weather.WXT.Invalid),Weather.WXT.Temp(Weather.WXT.Invalid),'r-.')
                end
            end
            ylabel('T (C)')
            datetick('x')%,'HH:MM:SS')
            grid on
            subplot(6,1,6)
            if isfield(Weather,'Logger')
                plot(Weather.Logger.Time(1:ml),Weather.Logger.WindSpeed(1:ml))
                if ~isempty(Weather.Logger.Invalid)
                    hold on
                    plot(Weather.Logger.Time(Weather.Logger.Invalid),Weather.Logger.WindSpeed(Weather.Logger.Invalid),'r-.')
                end
            else
                plot(Weather.WXT.Time,Weather.WXT.MaxWindSpeed)
                if ~isempty(Weather.WXT.Invalid)
                    hold on
                    plot(Weather.WXT.Time(Weather.WXT.Invalid),Weather.WXT.MaxWindSpeed(Weather.WXT.Invalid),'r-.')
                end
            end
            ylabel('MW (m/s)')
            xlabel('Time')
            datetick('x')%,'HH:MM:SS')
            grid on
            if strcmp(saveplot,'yes')
                drawnow
                cd(PlotDir)
                fn = ['Combined_',datestr(TargetStart,'yy-mm-dd')];
                saveas(g,[fn,'.fig'],'fig')
%                 print(g,'-depsc','-tiff','-r300',[fn,'.eps']) %Eps with tiff preview
%                 print(g,'-djpeg90',[fn,'.jpg']) %jpeg
                %close(g)
            end
        end
    end
    if strcmp(location,'CXA-test')
        figure
        subplot(2,1,1)
        plot(BeaconSignal.Timestamp, BeaconSignal.Carrier,'b-x')
        datetick2('x')
        ylabel('Carrier (dBm)')
        title('Samples should be 10 per second')
        subplot(2,1,2)
        plot(diff(BeaconSignal.Timestamp)*24*3600,'b-x')
        ylabel('Seconds between samples')
    end
    %Save daily results for beacon and weather
    if strcmp(savefiles,'yes')
        if ~isdir(ResDir)
            mkdir(ResDir)
        end
        cd(ResDir)
        if strcmp(proc_weather,'yes')
            fn = ['Weather_',datestr(TargetStart,'yy-mm-dd'),'.mat'];
            save(fn, 'Weather')
        end
        if strcmp(proc_beacon,'yes') && ~isempty(A)
            fn = ['BeaconSignal_',datestr(TargetStart,'yy-mm-dd'),'.mat'];
            save(fn, 'BeaconSignal')
            fn = ['Spectrum_',datestr(TargetStart,'yy-mm-dd'),'.mat'];
            %Spectrum = [BeaconSpectrumTime; BeaconSpectrum'];
            save(fn, 'BeaconSpectrum')
        end
    end
    if numberofdays > 1
        disp(['Drawing figures, cleaning and up memory - ', datestr(clock)])
        drawnow
        pause(3)
        close all
        clear BeaconSignal BeaconSpectrum Weather
        pause(5)
    end
end %Day loop

%Change back to original directory
cd(StartDir)