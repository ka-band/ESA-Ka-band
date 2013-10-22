function [BeaconSignal, BeaconSpectrum] = ...
    Load_BeaconFiles(D, Dspec, ip,ips, A, As, TargetStart, TargetEnd, pl, TrackThreshold, F_threshold, location,verbose, receiver, DataDirBeacon, DataDirSpectrum)
%LOADBEACONFILES Read beacon data from R&S FSP receiver from harddisk
%
% Inputs
%   D:  Directory content
%   ip: Indexnumber for files to load
%   A: Start stop matrix for files
%   Target start: Start time for request (datenum format)
%   Target end: end time for request(datenum format)
%   pl: Plot data ('yes','no')
%   verbose: Print results to screen? 'yes' or 'no'
%
% Outputs
%   OLevel: Beacon and noise power reading (dBm)
%   OLevelTime: Timestampes for beacon
%   OSpectrum: Spectrum (dBm)
%   OSpectrumTime: Timestamps for Spectrum
%   OTrack: '1' beacon locked on carrier, '0' out of lock
%   N0: Noise floor estimate
%
% Lars Bråten, 2011-2012
% 2013: modified for binary files
%Modified for ESA project Oct 2013, LEB


%Define time periods widt invalid data for kjeller
if strcmp(location,'Kjeller')
    outliers = ...
        [        ];
elseif strcmp(location,'Vadsø')
    outliers = ...
        [        ];
elseif strcmp(location,'Vadsø')
    outliers = ...
        [ ];
elseif strcmp(location,'Eggemoen')
    outliers = ...
        [ ];
elseif strcmp(location,'Nittedal')
    outliers = ...
        [ ];
elseif strcmp(location,'Svalbard')
    outliers = ...
        [ ];
else
    outliers = [];
end
%Parameters

NoiseTimeThreshold = 100*135e-3; % (secs) After frequency adjustement counter start counting up to 100 again to find average noise floor
SpikeThreshold = 1; %dB, noise spike removal
noisewindow = round(100/0.135);
NoiseDiffThre = 5;%dB Check for large differences in noise levels
%NoiseThreshold = -90;%dBm, assume error is above this level
averagewindow = 100; %Used to average noise samples
ResBW = 30;%Hz, resolution bandwidth on spectrumanalyser

%*************Beacon*******************
cd(DataDirBeacon)
%Define start-stop outlier vector based on time
OLevel        = []; %Beacon + noise power data (dBm)
OLevelTrue    = [];
OLevelTime    = []; %Generated time vector for beacon level
OTrack        = [];%Time vector indicating beacon lock '1' or not in lock '0'
ON0dB         = []; %Nose level
ON02dB         = []; %Noise level marker 2
ON03dB         = []; %Noise level marker 3
OFm1_c        = []; %Carrier freq
OLevelAvg = []; %Averaged level (trace 2)
ON02dBAvg         = []; %Noise level marker 7 (trace 2)
ON03dBAvg         = []; %Noise level marker 8 (trace 2)

for fileno = 1 : length(ip)
    Level        = []; %Beacon + noise power data (dBm)
    LevelTime    = []; %Generated time vector for beacon level
    Track        = [];
    N0dB         = [];
    N02dB         = []; %Marker 2
    N03dB         = []; %Marker 3
    N02dBAvg         = []; %Marker 6
    N03dBAvg         = []; %Marker 7
    LevelAvg = []; %Averaged level (trace 2)
    %Read data from file
    fn = D(ip(fileno)).name;
    if strcmp(verbose,'yes')
        disp(['Reading file ', fn])
    end
    
    %This file is implicitly a Matlab .mat binary file
    A = load(fn); %Please remember that more data is saved here for later retrival and enjoyment :-)
    A=A.D;
    LevelAvg = A(:,10); %Averaged carrier plus noise level (trace 2)
    N02dBAvg         = A(:,12); %Marker 6
    N03dBAvg         = A(:,13); %Marker 7
    
    Fm1_c =A(:,4); %Carrier frequency
    Fm2_n =A(:,5); %BNoise marker 1 freq
    Fm3_n =A(:,6); %Noise marker 2 freq
    
    %Level estimate
    StartDate = fn(5:12);
    MeasureHour = A(:,7);
    MeasureMin = A(:,8);
    MeasureSec = A(:,9);
    
    L = length(A(:,9));
    StartDateNum = datenum(StartDate,'yy-mm-dd');
    Dato = StartDate;
    OldHour = 0;
    et = 100; %Timer used in noise floor cleanup
    N02dB = A(:,2) + A(:,1); %dBm Relative markers
    N03dB = A(:,3) + A(:,1); %dBm Relative markers
    
    %Noise post processing
    if StartDateNum <  734900 %In this period markers 2 and 3 were following an averaged trace 2 (changed 01.02.10.30)
        N02dBc = spikerem(N02dB, SpikeThreshold, noisewindow,'N02dB'); %Remove spikes
        N03dBc = spikerem(N03dB, SpikeThreshold, noisewindow,'N03dB');
    elseif StartDateNum >=  734900 %In this period markers 2 and 3 follow trace 1 and require time
        N02dBc = noiseaverage(N02dB, averagewindow); %Noise averaging
        N03dBc = noiseaverage(N03dB, averagewindow);
        N02dBc = spikerem(N02dBc, SpikeThreshold, noisewindow,'N02dBc'); %Remove spikes
        N03dBc = spikerem(N03dBc, SpikeThreshold, noisewindow,'N03dBc');
    end
    %Check for large differences in noise level on the two markers
    ipnd = find(abs(N02dBc - N03dBc) > NoiseDiffThre);
    if ~isempty(ipnd)   %Set noise to minimum
        disp(['Setting ',num2str(length(ipnd)),' samples to minimum noise marker'])
        N0dBMax = min([N02dBc(ipnd);N03dBc(ipnd)]);
        N02dBc(ipnd) = N0dBMax;
        N03dBc(ipnd) = N0dBMax;
    end
    N0dB = 10*log10((10.^(N02dBc./10)+ 10.^(N03dBc./10))./2); %Average between the two
    Fstable = zeros(size(N0dB));
    for l = 1:L %Ordne med tid
        % Døgnskift?
        ms  = round((MeasureSec(l) - floor(MeasureSec(l)))*1000); %Milliseconds
        MS = num2str(ms);
        if length(MS) == 2
            MS = ['0',MS];
        elseif length(MS) == 1
            MS = ['00',MS];
        end
        if MeasureHour(l) < OldHour;
            Dato = datestr(addtodate(datenum(Dato,'yy-mm-dd'),1,'day'),'yy-mm-dd');
        end
        TimeStr = [Dato,' ',num2str(MeasureHour(l)),'-',num2str(MeasureMin(l)),'-',...
            num2str(floor(MeasureSec(l))),'-',MS];
        LevelTime(l) = datenum(TimeStr,'yy-mm-dd HH-MM-SS-FFF');
        
        OldHour = MeasureHour(l);
        %Tracking status
        if l == 1
            oldfreq =  Fm1_c(l);
        else
            oldfreq = Fm1_c(l-1);
            if LevelTime(l-1) >= LevelTime(l)
                %                 disp(['l = ',num2str(l),', prev: ',datestr(LevelTime(l-1),'dd-mm-yyyy HH:MM:SS:FFF'),', now:',datestr(LevelTime(l),'dd-mm-yyyy HH:MM:SS:FFF')])
                %                 disp(['TimeStr = ',TimeStr,', MeasureHour(l-1) = ',num2str(MeasureHour(l-1)),', MeasureHour(l) = ',num2str(MeasureHour(l))])
                %                 disp(['MS = ',MS,', ms = ',num2str(ms)])
                %                 stop
            end
        end
        if abs(Fm1_c(l) - oldfreq < F_threshold) %Check signal frequency stability
            Fstable(l) = 1;
        end
    end
    
    %     %For some reason time stamping is not working in Vadsø as per jan
    %      %2013. Assume existing timestamps, when incremented, is ok
    %      testsec=diff(LevelTime);
    %      ipt=find(testsec == 0);
    %      if ~isempty(ipt)
    %         disp('Reparing time in ascii file')
    %
    %         %LevelTimeOld=LevelTime;
    %         %Identify location of correct timestamps
    %         ns = [1,find(testsec ~= 0)+1];
    %         for nn = 1:length(ns) - 1
    %             nsb = ns(nn+1) - ns(nn); %Number of samples in between
    %             tbs = LevelTime(ns(nn+1)) - LevelTime(ns(nn));%Time between correct samples
    %             deltat = tbs / nsb;
    %             for m = 1:nsb
    %                 LevelTime(ns(nn)+m)= LevelTime(ns(nn))+deltat*m;
    %             end
    %         end
    %         %Fill up the last segment
    %         if ns(length(ns))< L
    %             nsb = L - ns(length(ns)); %Number of samples in between
    %             tbs = LevelTime(L) - LevelTime(ns(length(ns)));%Time between correct samples
    %             deltat = tbs / nsb;
    %             for m = 1:nsb
    %                 LevelTime(ns(length(ns))+m)= LevelTime(ns(length(ns)))+deltat*m;
    %             end
    %         end
    %      end
    if size(N0dB) ~= size(squeeze(A(:,1)))
        N0dB = N0dB';
    end
    if size(Fstable) ~= size(squeeze(A(:,1)))
        Fstable = Fstable';
    end
    CP= 10.^(A(:,1)./10) - 10.^(N0dB./10); %Carrier power
    ipz=find(CP <0);
    if ~isempty(ipz)
        CP(ipz)=0;
    end
    Level = 10*log10(CP); %dBm Carrier power - noise power  %Bandwidth for noise??
    
    LevelTrue=A(:,1);
    
    if ~isreal(Level)
        A(:,1)
        stop
    end
    %     %ipTr = find(abs(Level - N0dB)) & find(Fstable > 0);
    %     ipTr = find((Level - N0dB > TrackThreshold) & (Fstable > 0));
    ipTr = find(Fstable > 0);
    Track = zeros(size(Level));
    Track(ipTr) = 1;
    
    if strcmp(pl,'yes')
        figure
        plot(LevelTime,Level)
        ylabel('Level (dBm)')
        xlabel('Time')
        title('Beacon + noise power')
        datetick('x','HH:MM:SS')
    end
    %     figure
    %     plot(LevelTime,'b-')
    %     hold on
    %     plot(LevelTimeOld,'r:')
    %     stop
    %disp(['Aggregated samples ',num2str(length(OLevel)),', This file ',num2str(length(Level)),' samples, ',fn])
    %Append new data
    OLevel        = [OLevel, Level']; %Signal level
    OLevelTrue       =[OLevelTrue, LevelTrue'];
    OLevelAvg        = [OLevelAvg, LevelAvg']; %Signal plus noise level, trace 2
    OLevelTime    = [OLevelTime, LevelTime]; %Time stamp
    OTrack        = [OTrack, Track'];
    ON0dB = [ON0dB, N0dB']; %Noise level
    ON02dB = [ON02dB, N02dB']; %Noise level marker 2
    ON03dB = [ON03dB, N03dB']; %Noise level marker 3
    OFm1_c = [OFm1_c, Fm1_c']; %Carrier freq
    ON02dBAvg = [ON02dBAvg, N02dBAvg']; %Noise level marker 7 (trace 2)
    ON03dBAvg = [ON03dBAvg, N03dBAvg']; %Noise level marker 8 (trace 2)
    %     figure
    %     ax(1)=subplot(3,1,1);
    %     plot(N0dB,'r.')
    %     ylabel('No (dBm)')
    %     ax(2)=subplot(3,1,2);
    %     plot(N02dB,'k-')
    %     hold on
    %     plot(N02dBc,'b.')
    %     ylabel('No2 (dBm)')
    %     ax(3)=subplot(3,1,3);
    %     plot(N03dB,'k-')
    %     hold on
    %     plot(N03dBc,'b.')
    %     ylabel('No3 (dBm)')
    %     drawnow
    %     pause(3)
    %     linkaxes(ax,'x');
    %     stop
end

%Discard values outside requested time period
%disp(['Timestart = ',datestr(min(LevelTime)), ', TargetStart = ', datestr(TargetStart), ', Timeend = ',datestr(max(LevelTime)),', TargetEnd = ',datestr(TargetEnd)])
%disp(['Start length = ',num2str(length(Level)),' beacon samples'])

ip = find(OLevelTime < TargetEnd); %Cut end
OLevel = OLevel(ip);
OLevelTrue=OLevelTrue(ip);
OLevelTime = OLevelTime(ip);
OTrack = OTrack(ip);
ON0dB = ON0dB(ip);
ON02dB = ON02dB(ip);
ON03dB = ON03dB(ip);
OFm1_c = OFm1_c(ip);
OLevelAvg = OLevelAvg(ip);
ON02dBAvg = ON02dBAvg(ip);
ON03dBAvg = ON03dBAvg(ip);

ip = find(OLevelTime >= TargetStart); %Cut start
OLevel = OLevel(ip);
OLevelTrue=OLevelTrue(ip);
OLevelAvg = OLevelAvg(ip);
OLevelTime = OLevelTime(ip);
OTrack = OTrack(ip);
ON0dB = ON0dB(ip);
ON02dB = ON02dB(ip);
ON03dB = ON03dB(ip);
OFm1_c = OFm1_c(ip);
ON02dBAvg = ON02dBAvg(ip);
ON03dBAvg = ON03dBAvg(ip);

%Identify invalid data
[R,C] = size(outliers);
invalid=[];
for r = 1:R
    ipiv = find(OLevelTime >= outliers(r,1) & OLevelTime <= outliers(r,2)); %Index to invalid samples
    invalid = [invalid,ipiv];
    if ~isempty(ipiv)
        disp([num2str(length(ipiv)),' invalid sampels for this day, start at ',datestr(outliers(r,1),'yyyy mm dd HH MM SS'),...
            ', end at ',datestr(outliers(r,2),'yyyy mm dd HH MM SS')])
    end
end

%Normalize results to resolution bandwidth of 30 Hz
deltaL = 10*log10(ResBW);
BeaconSignal.Invalid = invalid;
BeaconSignal.Carrier = OLevel - deltaL;%dBm/Hz
BeaconSignal.Timestamp = OLevelTime;
BeaconSignal.N0dB = ON0dB - deltaL;%dBm/Hz
BeaconSignal.N02dB = ON02dB - deltaL;%dBm/Hz
BeaconSignal.N03dB = ON03dB - deltaL;%dBm/Hz
BeaconSignal.Track = OTrack;
BeaconSignal.Frequency = OFm1_c;
BeaconSignal.CarrierNoiseAvg = OLevelAvg; %Trace 2 averaged (normally 30 times), carrier plus noise (N0 not subtracted!!)
BeaconSignal.N02dBAvg = ON02dBAvg; %Trace 2 averaged (normally 30 times)
BeaconSignal.N03dBAvg = ON03dBAvg; %Trace 2 averaged (normally 30 times)

BeaconSignal.CN=OLevelTrue;
BeaconSignal.N02=ON02dB;
BeaconSignal.N03=ON03dB;

%disp(['End length = ',num2str(length(OLevel)),' beacon samples'])

%rett opp i tidsstempling
%eps_time=15;%s, gaps in time
%BeaconSignal = TestAttTime(BeaconSignal, fn, 'no', eps_time)


%*******************************************************
%Spectrum
cd(DataDirSpectrum)
OSpectrumT1     = []; %Power spectrum (dBm/Hz) Trace 1
OSpectrumT2     = []; %Power spectrum (dBm/Hz) Trace 2 Average
OSpectrumF      = []; %SpectrumFreq (Hz)
OSpectrumTime   = []; %Time vector for spectrum
for fileno = 1 : length(ips)
    SpectrumT1     = []; %Power spectrum (dBm/Hz) ??
    SpectrumT2     = []; %
    SpectrumF     = []; %
    SpectrumTime = []; %Time vector for spectrum
    %Read data from file
    fn = Dspec(ips(fileno)).name;
    if strcmp(verbose,'yes')
        disp(['Reading file ', fn])
    end
        Spectrum = load(fn);
        Spectrum=Spectrum.T';
    string = fn(11:27);
    SpectrumTime = datenum(string,'yy-mm-dd HH-MM-SS');
    %Append new data
    OSpectrumT1     = [OSpectrumT1; Spectrum(1,:)];%dBm/30Hz %Dette går feil 23 feb 2012 på Kjeller, bytte av format?
    OSpectrumT2     = [OSpectrumT2; Spectrum(2,:)];%dBm/30Hz
    OSpectrumF      =  [OSpectrumF; Spectrum(3,:)];
    OSpectrumTime   = [OSpectrumTime,SpectrumTime];
    
    if strcmp(pl,'yes')
        f = Spectrum(3,:);
        fm = mean(f);
        figure
        plot(f-fm,Spectrum(1,:)-deltaL,'b-')
        hold on
        plot(f-fm,Spectrum(2,:)-deltaL,'r:')
        xlabel('Frequency (Hz)')
        ylabel('dBm/Hz')
        title(fn)
        legend('Trace 1','Trace 2 (avg)')
        grid on
    end
end
ip = find(OSpectrumTime < TargetEnd); %Cut end
OSpectrumT1 = OSpectrumT1(ip,:);
OSpectrumT2 = OSpectrumT2(ip,:);
OSpectrumF = OSpectrumF(ip,:);
OSpectrumTime = OSpectrumTime(ip);

ip = find(OSpectrumTime >= TargetStart); %Cut start
OSpectrumT1 = OSpectrumT1(ip,:);
OSpectrumT2 = OSpectrumT2(ip,:);
OSpectrumTime = OSpectrumTime(ip);
OSpectrumF = OSpectrumF(ip,:);

BeaconSpectrum.Trace1 = OSpectrumT1-deltaL; %dBm/Hz
BeaconSpectrum.Trace2 = OSpectrumT2-deltaL; %dBm/Hz
BeaconSpectrum.Freq = OSpectrumF;
BeaconSpectrum.Timestamp = OSpectrumTime;

return