function beatPoints = ReportGenarator( DataName, ~, QRSComplexes )

% Get DataName
DataName = split( DataName, '\' );
DataName = DataName{ end };
DataName = regexprep(DataName,'[_RawSignal.bin]','');

beatPoints = zeros( numel( QRSComplexes.R ), 1 );
% time = transpose( 1 : numel( Signal ) );

for beatIndex = 1 : numel( QRSComplexes.R )
    
    if QRSComplexes.Type( beatIndex ) == -3
        beatPoints(beatIndex) = QRSComplexes.S( beatIndex );
    else
        beatPoints(beatIndex) = QRSComplexes.R( beatIndex );
    end
    
end


generateANNtext( DataName, beatPoints, QRSComplexes );
% generateSIGNALcsv(DataName, Signal );
% 
cd('C:\Users\is97016\Desktop\MatlabAPI Developer');


end

%% subFunctions : generateANNtext

function generateANNtext(data, rpoints, qrsComplexes )

cd('C:\Users\is97016\Desktop\Output Files')

qrsComplexes.VentricularBeats( qrsComplexes.FlutterBeats == 1 ) = false;

openFileName=[num2str(data) '_atr.txt'];
fileID = fopen(openFileName,'W');
for writeIndex = 1:numel(rpoints)
    Min = fix(((rpoints(writeIndex))/250)/60);
    Sec =  fix((rpoints(writeIndex) - Min*250*60)/250);
    MSec = round(((rpoints(writeIndex) - Min*250*60 - Sec*250)/250)*1000);
%     Time = ([ sprintf('%02d',Min) ':'  sprintf('%02d',Sec) ':'  sprintf('%03d',MSec)]);
    
    if ~qrsComplexes.VentricularBeats( writeIndex )
        if ~qrsComplexes.FlutterBeats( writeIndex )
        type = 'N';
        else
            type = '!';
        end
    else
        type = 'V';
    end
    
        fprintf(fileID,'\t%02d:%02d.%03d\t%5d\t%s\t0\t1\t0\t0\n',Min,Sec,MSec, rpoints( writeIndex ), type );
    
%     fprintf(fileID,'\t%02d:%02d.%03d\t%5d\t%s\t0\t0\t0\t0\n', ...
%         Min,Sec,MSec,rpoints(writeIndex), type, '0', '1', '0', '0' );

%     fprintf(fileID,'\t%5s \t%5s \t%3s \t%4s \t%4s \t%4s\n',Time,num2str(rpoints(writeIndex)), type, '0', '1', '0' );
    
end

fclose(fileID);

end

%% subFunctions : generateSIGNALcsv

% function generateSIGNALcsv(data, signal)
% 
% cd('C:\Users\is97016\Desktop\Output Files')
% 
% [signal] = changeFormat(signal);
% 
% openFileName = [num2str(data) '_sgn.csv'];
% File = fopen(openFileName, 'w') ;
% fprintf(File, '%s,%s,%s\n', 'INDEX', 'CH1', 'CH2');
% 
% m = [ transpose( 0: ( numel( signal ) - 1)  ), signal, zeros( numel( signal ), 1 ) ];
% csvwrite(openFileName,m);
% 
% fclose(File);
% 
% end
% 
% % Format Change
% function [output] = changeFormat(input)
% 
% input( input > 5 ) = 5;
% input( input < -5 ) = -5;
% input = input - ( - 5 );
% input = round( ( 2048 * input ) / 10 );
% input( input > 2047 ) = 2047;
% output = input;
% 
% end