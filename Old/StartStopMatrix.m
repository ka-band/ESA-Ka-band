function A = StartStopMatrix(D, type, location, receiver)
% Generate start , stop and samples matrix
%
% LEB 16.07.04, Modified Aug 2011 and jan 2012
% Modified for ESA project October 2013

if ~isempty(D)
    for fileno = 1 : length(D)
        fname = D(fileno).name;
        if strcmp(type,'Beacon') && strcmp(receiver,'EXA')
            %FSP-12-01-05 09-31-28 - 10-01-28 s 13846
            ip = 5:21;
            StartTime = fname(ip);
            A(fileno, 1) = datenum(StartTime,'yy-mm-dd HH-MM-SS'); %Serial date number for start of file
            ipe = 25:32;
            %t1 = datenum(fn(13:20),'HH-MM-SS')
            %t2 = datenum(fn(25:32),'HH-MM-SS'
            %e = etime(t2,t1)
            StartHour = str2num(fname(14:15));
            EndHour = str2num(fname(25:26));
            if EndHour < StartHour %Nytt døgn
                dummy = fname(5:12);
                dummy = datenum(dummy,'yy-mm-dd');
                dummy = addtodate(dummy,1,'day');
                dummy = datestr(dummy,'yy-mm-dd');
                EndTime = [dummy,' ',fname(ipe)];
            else
                EndTime = [fname(5:12),' ',fname(ipe)];
            end
            %EndTime = datenum(StartTime,'yy-mm-dd HH-MM-SS');
            %EndTime = datestr(EndTime,'yy-mm-dd HH-MM-SS'); %
            A(fileno, 2) = datenum(EndTime,'yy-mm-dd HH-MM-SS'); %Serial date number for end of file
        elseif strcmp(type,'Spectrum') && strcmp(receiver,'EXA')%FSP or CXA
            %FSP_TRACE-12-01-05 10-01-28
            %fname
            ip = 11:27;
            StartTime = fname(ip);
            A(fileno, 1) = datenum(StartTime,'yy-mm-dd HH-MM-SS'); %Serial date number for start of file
            EndTime = datenum(StartTime,'yy-mm-dd HH-MM-SS');
            EndTime = datestr(EndTime + 1/24,'yy-mm-dd HH-MM-SS'); % <= +1 hour
            A(fileno, 2) = datenum(EndTime,'yy-mm-dd HH-MM-SS'); %Serial date number for end of file
        elseif strcmp(type,'WXT') %WXT520
            year = fname(2:5);
            month = fname(7:8);
            day = fname(10:11);
            hour=fname(13:14);
            minute=fname(16:17);
            second=fname(19:20);
            StartTime = [year,'_',month,'_',day,'_',hour,'_',minute,'_',second]; %Start time (UTC clock)
            year = fname(22:25);
            month = fname(27:28);
            day = fname(30:31);
            hour=fname(33:34);
            minute=fname(36:37);
            second=fname(39:40);
            EndTime = [year,'_',month,'_',day,'_',hour,'_',minute,'_',second]; %Start time (UTC clock)
            A(fileno, 1) = datenum(StartTime,'yyyy_mm_dd_HH_MM_SS'); %Serial date number for start of file
            A(fileno, 2) = datenum(EndTime,'yyyy_mm_dd_HH_MM_SS'); %Serial date number for start of file
        elseif strcmp(type,'TB') %TB
            year = fname(2:5);
            month = fname(7:8);
            day = fname(10:11);
            hour=fname(13:14);
            minute=fname(16:17);
            second=fname(19:20);
            StartTime = [year,'_',month,'_',day,'_',hour,'_',minute,'_',second]; %Start time (UTC clock)
            year = fname(22:25);
            month = fname(27:28);
            day = fname(30:31);
            hour=fname(33:34);
            minute=fname(36:37);
            second=fname(39:40);
            EndTime = [year,'_',month,'_',day,'_',hour,'_',minute,'_',second]; %Start time (UTC clock)
            A(fileno, 1) = datenum(StartTime,'yy_mm_dd_HH_MM_SS'); %Serial date number for start of file
            A(fileno, 2) = datenum(EndTime,'yy_mm_dd_HH_MM_SS'); %Serial date number for start of file
        else
            stop
        end
    end
else
    A=[];
end