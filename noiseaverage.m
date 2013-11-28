function y = noiseaverage(x, windowsize)
%NOISEAVERAGE Average noise markers 2 and 3
%   Inputs:
%       x: signal in dB
%       threshold: signal difference threshold from one sample to next for
%   Outputs:
%       y: averaged noise signal
%
%   Lars Erling Bråten Jan 2012
%close all
%disp('------------------------')

%Moving average approach
a = ones(1,windowsize)./windowsize;
b = 1;
y = filter(a,b,x)';%Running average
%Fix delay
D = round(windowsize/2);
if length(y) > D
    y(1:D) = [];
    y = [y, y(length(y))*ones(1,D)];
    y(1:D+1) = ones(D+1,1)*y(D+1); %Remove first transient
    y=y';
else
    y = x;
end
% figure
% ax = 1:length(x);
% title('spikerem')
% plot(ax,x,'k-.')
% hold on
% plot(ax,MA,'b-')
% legend('x','y')
% stop
return
