function Time = Sample2Miliseconds(sampleList, Freq)

msecArray = ( sampleList / Freq )*1000;
stringArray = strings( length( msecArray ), 1);
            
            
            % PARTIAL 
            % - day
            days = floor(msecArray / 86400000);
            msecArray = msecArray - days * 86400000;
            % - hour
            hours = floor(msecArray / 3600000 );
            msecArray = msecArray - hours * 3600000;
            % - minute
            mins = floor(msecArray / 60000);
            msecArray = msecArray - mins * 60000;
            % second
            secs = floor( msecArray / 1000 );
            msecArray = msecArray - secs * 1000;
            
            msecs = floor( msecArray);
            msecArray = msecs;
            
         % PARS
            for i = 1:length( msecArray )
                stringArray(i,:) = sprintf('%02d:%02d:%02d:%02d,%03d', days(i), hours(i), mins(i), secs(i), msecs(i) );
            end
            timeList=cellstr(stringArray);

            
            Time = cellfun(@(x) str2num(x(1:2))*86400 + str2num(x(4:5))*3600 + str2num(x(7:8))*60 +  str2num(x(10:11)) + str2num(x(12:14))/1000,timeList) ;  
            
%             Time = Time - Time(1) ;

end