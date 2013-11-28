function y = spikerem(x, threshold, windowsize, str)
%SPIKEREM Remove spike is signals
%   Inputs:
%       x: signal in dB
%       threshold: signal difference threshold from one sample to next for
%       spike identification
%   Outputs:
%       y: signal without spikes
%
%   Lars Erling Bråten Jan 2012
%close all
%disp('------------------------')

%Moving average approach
a = ones(1,windowsize)./windowsize;
b = 1;
MA = filter(a,b,x)';%Running average
%Fix delay
D = round(windowsize/2);
if length(MA) > D
    MA(1:D) = [];
    [m,n]=size(MA);
    if n > m
        MA = [MA, MA(length(MA))*ones(1,D)];
    else
        MA = [MA; MA(length(MA))*ones(D,1)];
    end
    MA(1:D+1) = ones(D+1,1)*MA(D+1); %Remove first transient
    
    %Identify outliers
    ips = find(abs(x - MA') > threshold);
    y = x;
    if strcmp(str,'PTR')
        %y(ips) = y(ips-1); Does not work well
        %y(ips) = MA(ips);%Set ouliers to average, does not work well
        y = MA; %Use moving average directly
        disp(['Applying moving average on ',str,' , MA window of ',num2str(windowsize),' samples'])
    else %Spectrum analyser approach
        y(ips) = MA(ips);%Set ouliers to average
        if ~isempty(ips)
            disp(['Replacing ',num2str(length(ips)),' outliers from ',str,', total of ',num2str(length(x)),' samples, (',...
                num2str(100*length(ips)/length(x)),'%)'])
        end
    end
else
    y = x;%Too short sequence
end
% figure
% ax = 1:length(x);
% title('spikerem')
% plot(ax,x,'k:d','linewidth',2)
% hold on
% if ~isempty(ips)
%     plot(ax(ips),x(ips),'rx')
% end
% %plot(ax(ip_row),x(ip_row),'mo')
% plot(ax,y,'bo-')
% plot(ax,MA,'y+--')
% if ~isempty(ips)
%     legend('x','outliers','y','MA')
% else
%     legend('x','y','MA')
% end
% figure
% plot(ax,x,'k:','linewidth',2)
% hold on
% plot(ax,y,'b-')
%  legend('x','y')
% stop
% return
%d = diff(x); %Derivate
%ips = find(abs(d) > threshold) +1; %Find spikes

% disp(['ips=',num2str(ips')])
% %y = x;
% ax = 1:length(x);
% if ~isempty(ips) %Replace spikes
%     ipss = diff(ips); %Check length of spike problem
%     disp(['spike length check ipss=',num2str(ipss')])
%     [ips_row, p1] = find(ipss == 1);    %Spikes in a row
%     disp(['spikes in row ips_row=',num2str(ips_row')])
%
%     %Check for number in a row
%     nr_d  =diff(ipss);
%     nr = find(nr_d == 0);
%     disp(['ip number of spikes in an event nr_d=',num2str(nr_d')])
%     disp(['number of spikes in an event nr = ',num2str(nr')])
%     if isempty(nr) %just two spikes in a row
%         ip_row = ips(ips_row)':ips(ips_row)'+1; %Actual index vector
%     else
%         stop
%     end
%     disp(['ip_row=',num2str(ip_row)])
%     ips_single = find(ipss > 1);%Single spikes
%     disp(['ips_single=',num2str(ips_single')])
%     ip_single = ips(ips_single); %Actual index vector
%     ip_single(ips_row)=[];%Remove any index pointing to double spikes
%     %Add last spike
%     ip_single = [ip_single;ips(length(ips))]';
%     disp(['ip_single=',num2str(ip_single)])
%
%     %Remove spikes single spikes
%     y(ip_single) = 10*log10((10.^(y(ip_single-1)./10) + 10.^(y(ip_single+1)./10))./2);
%     %Remove row spikes
%
%     figure
%     title('spikerem')
%     plot(ax,x,'k-')
%     hold on
%     plot(ax(ip_single),x(ip_single),'rx')
%     plot(ax(ip_row),x(ip_row),'mo')
%     plot(ax,y,'r-.')
%     plot(ax(ips),x(ips),'ys')
%     legend('x','single spikes','row spikes','y','all spikes')
% end
%

[m,n]=size(y);
if m > n
    y = y';
end
end
