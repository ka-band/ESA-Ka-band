function y = FixTimeStamp(fna)
%Modified for ESA project Oct 2013, LEB


if ~isempty(strfind(fna,'_WXT')) %WXTdata, assume in correct directory
    D = dir(fna);
    form = '%s';% %'%u %u %u %u %u %u %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f';
    for fileno = 1 : length(D)
        fn = D(fileno).name;
        
        [fid, message] = fopen(fn, 'r');%,'ieee-be');
        if fid == -1
            disp(['Error opening file ', fn,', message: ', message])
        end
        Cfl = fscanf(fid, form,2); %Start
        
        fseek(fid, -130, 'eof');
        Cf = fscanf(fid, form);%End
        k=strfind(Cf,'2013');
        if isempty(k)
            k=strfind(Cf,'2014');
        end
        if isempty(k)
            k=strfind(Cf,'2015');
        end
        Cf2 = Cf(k:length(Cf));
        st = fclose(fid);
        if st ~= 0
            disp(['Error closing file ', fn])
        end
        %Start
        ys = Cfl(2:5);
        ms=Cfl(7:8);
        ds=Cfl(10:11);
        hs= Cfl(12:13);
        mis=Cfl(15:16);
        ss = Cfl(18:19);
        %End
        if ~isempty(Cf2)
            ye = Cf2(1:4);
            me=Cf2(6:7);
            de=Cf2(9:10);
            he= Cf2(11:12);
            mie=Cf2(14:15);
            se = Cf2(17:18);
            fnn = ['y',ys,'m',ms,'d',ds,'h',hs,'m',mis,'s',ss,'y',ye,'m',me,'d',de,'h',he,'m',mie,'s',se,' ',fn];
            if ~exist(fnn,'file')
                [st] = copyfile(fn,fnn);
                if st ~= 1
                    disp(['Error copying weatherfile ', fn,' to ', fnn])
                    stop
                else
                    disp(['Copying weatherfile ', fn,' to ', fnn])
                end
            end
        else
            disp(['Empty file ',fn])
        end
    end
    
elseif ~isempty(strfind(fna,'_TB'))%Tipping bucket data, assume in correct directory
    D = dir(fna);
    form = '%s';% %'%u %u %u %u %u %u %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f';
    for fileno = 1 : length(D)
        fn = D(fileno).name;
        
        [fid, message] = fopen(fn, 'r');%,'ieee-be');
        if fid == -1
            disp(['Error opening file ', fn,', message: ', message])
        end
        Cfl = fscanf(fid, form,2); %Start
        ys = Cfl(2:5);
        ms=Cfl(7:8);
        ds=Cfl(10:11);
        hs= Cfl(12:13);
        mis=Cfl(15:16);
        ss = Cfl(18:19);
        %End
        fseek(fid, -1, 'eof');
        Cf = fscanf(fid, form);%End
        if strcmp(Cf,'') %Only one line
            Cf = Cfl;
        end
        st = fclose(fid);
        if st ~= 0
            disp(['Error closing file ', fn])
        end
        %Identify last number to find endtime and enddate
        ip=strfind(Cf,',');
        if ~isempty(ip)
            Cf2 = Cf(ip(end)+1:length(Cf));
            secs = str2num(Cf2)/1000;
            %Find end time
            tstart=datenum([ys,'-',ms,'-',ds,'-',hs,'-',mis,'-',ss],'yyyy-mm-dd-HH-MM-SS');
            tend = tstart+secs/24/3600;
            Tend = datestr(tend,'yyyy-mm-dd-HH-MM-SS');
            fnn = ['y',ys,'m',ms,'d',ds,'h',hs,'m',mis,'s',ss,'y',Tend,' ',fn];
            if ~exist(fnn,'file')
                [st] = copyfile(fn,fnn);
                if st ~= 1
                    disp(['Error copying weatherfile ', fn,' to ', fnn])
                    stop
                else
                    disp(['Copying weatherfile ', fn,' to ', fnn])
                end
            end
        else
            disp(['Empty file ',fn])
        end
    end
end
y=[];
return