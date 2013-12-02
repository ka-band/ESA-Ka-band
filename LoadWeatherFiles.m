function Weather = LoadWeatherFiles(D, ip, A, DPWD, ipPWD, APWD, TargetStart, TargetEnd, pl_temp, location, verbose, DataDirWeatherWXT,  DataDirWeatherTB)
% LoadWeatherFiles Load WXT520 data from disk
%
% Inputs
%   D:  Directory content
%   ip: Indexnumber for files to load
%   A: Start stop matrix for files
   Target start: Start time for request (datenum format)
%   Target end: end time for request(datenum format)
%   pl: Plot data ('yes','no')
%   verbose: Print results to screen? 'yes' or 'no'
%
% Outputs
%   ORainInt: Rain intensity (mm/h) every 10 sec
%   ORainAcc: Cumulative tain amount, NB! some automatic resetting?
%   OTemp: Air temperature
%   OHailInt: Hail intensity (hits/cm^2)
%   OMaxWindSpeed: Maximum wind speed
%   OWeatherTime: Timestamp for weaherdata
%
% Lars Bråten 2011
%Modified for ESA project Oct 2013, LEB

%*************WXT 520*********************
%                            
%YYYY MM DD HH MM SS  index --Dn ---Dm -Dx -Sn ---Sm -Sx  ---Ta -Tp --Ua ----Pa ---Rc ---Rd --Ri -Hc -Hd --Hi - Rp   Hp -Th --Vh -Vs    -Vr
%"2013-10-01 00:00:10",40425, 196, 315, 90, 0.1, 0.6, 1.6, -0.6, 1.8, 89.5, 1001, 11.89, 7999, 0,  0,  0,  0,   14.2, 0,  4,  12, 12.3, 3.549
form = ' %s             %u    %u   %u   %u  %f   %f   %f    %f    %f   %f    %f     %f    %f   %f  %f  %f  %f     %f  %f %f    %f  %f    %f';

OWeatherTime    = []; %Generated time vector for beacon level
OTemp = []; %Air termp
ORainInt = []; %Rain intensity
ORainAcc = []; %Accumulated amount of rain
ORainPeak = [];
OHailInt = []; %Hail intensity
OHailPeak = [];
OMaxWindSpeed = []; %Max wind speed
OMaxWindDirection = []; %Wind direction maximum
OHumidity = []; %Humidity
OPressure = []; %Pressure
ORainDur = [];
OHailDur = [];
OHailAcc = [];
OHeatingTemp = [];
OInternalTemp = [];

cd(DataDirWeatherWXT)
for fileno = 1 : length(ip)
    fn = D(ip(fileno)).name;
    [fid, message] = fopen(fn, 'r');%,'ieee-be');
    if fid == -1
        disp(['Error opening file ', fn,', message: ', message])
    end
    C=readtable(fn,'ReadRowNames',0,'FileType','text','ReadVariableNames',0,'Format',form);
    %C=textscan(fn,form)
    st = fclose(fid);
    if st ~= 0
        disp(['Error closing file ', fn])
    end
    Time = char(C{:,1});
    year = str2num(Time(:,2:5));
    month = str2num(Time(:,7:8));
    day = str2num(Time(:,10:11));
    hour = str2num(Time(:,13:14));
    minute = str2num(Time(:,16:17));
    second = str2num(Time(:,19:20));
    Dn = C{:,3}; % Wind direction minimum
    Dm = C{:,4};% Average wind direction
    Dx = C{:,5}; %Wind direction maximum
    Sn = C{:,6}; %Minimum wind speed
    Sm = C{:,7}; %Speed average wind
    Sx = C{:,8}; %Maximum wind speed
    Ta = C{:,9}; %Air temperature
    Tp = C{:,10}; %Internal temperature
    Ua = C{:,11}; %Air humidity relative
    Pa = C{:,12}; %Air pressure
    Rc = C{:,13}; %Rain aumunt **************
    Rd = C{:,14}; %Rain duration
    Ri = C{:,15}; %Rain intensity **************
    Hc = C{:,16}; %Hail amount ***************
    Hd = C{:,17}; %Hail duration
    Hi = C{:,18}; %Hail intensity ****************
    Rp = C{:,19}; %Peak rain
    Hp = C{:,20}; %Peak Hail
    Th = C{:,21}; %Heating temperature
    Vh = C{:,22}; %Heating voltage
    Vs = C{:,23}; %Supply voltage
    Vr = C{:,24}; %Reference voltage
    
    WeatherTime    = datenum(double([year,month,day,hour,minute,second])); %Serial date number for for weather data
    OWeatherTime = [OWeatherTime; WeatherTime];
    OTemp = [OTemp; Ta];
    ORainInt = [ORainInt; Ri];
    ORainPeak = [ORainPeak; Rp];
    ORainAcc = [ORainAcc; Rc];
    OHailInt = [OHailInt; Hi];
     OHailPeak = [OHailPeak; Hp];
    OMaxWindSpeed = [OMaxWindSpeed; Sx];
    ORainDur = [ORainDur; Rd];
    OHailDur = [OHailDur;Hd];
    OHailAcc = [OHailAcc;Hc];
    OHeatingTemp = [OHeatingTemp;Th];
    OInternalTemp = [OInternalTemp;Tp];    
    OPressure = [OPressure; Pa];
    OHumidity = [OHumidity; Ua];
    OMaxWindDirection = [OMaxWindDirection;Dx];
    
end %Fileno
% Identify invalid numbers
%ipvalid                  = find(ORainInt >= 0 & OMaxWindSpeed >= 0);
if ~isempty(ip)
    ipinvalid                = find(ORainInt < 0 | OMaxWindSpeed < 0 | OHailInt < 0);
    Weather.WXT.RainInt          = ORainInt;
    Weather.WXT.RainAcc          = ORainAcc;
    Weather.WXT.RainPeak          = ORainPeak;    
    Weather.WXT.Temp             = OTemp;
    Weather.WXT.HailInt          = OHailInt;
        Weather.WXT.HailPeak          = OHailPeak;
    Weather.WXT.MaxWindSpeed     = OMaxWindSpeed;
    Wetaher.WXT.MaxWindDirection = OMaxWindDirection;
    Weather.WXT.Time             = OWeatherTime;
    Weather.WXT.RelHumidity      = OHumidity;
    Weather.WXT.Pressure         = OPressure;
    Weather.WXT.Invalid          = ipinvalid;
    Weather.WXT.RainDur          = ORainDur;
    Weather.WXT.HailDur = OHailDur;
    Weather.WXT.HailAcc = OHailAcc;
    Weather.WXT.HeatingTemp = OHeatingTemp;
    Weather.WXT.InternalTemp = OInternalTemp;
end

%Tipping bucket
%[TBD]

if exist('Weather')~= 1
    Weather = [];
end
return %Function

