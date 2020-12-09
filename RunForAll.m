
% Run ECG Analysis for specified database 
%
% RunForAll(database, firstData, lastData)
%
% <<< Function Inputs >>>
%   char database
%   single firstData
%   single lastData
%

function RunForAll(database, firstData, lastData)


% profile -memory on

%% Run Program

if firstData > lastData
    increment = -1;
else
    increment = 1;
end

for data = firstData : increment : lastData
    
    switch database
        
        case 'Simulator'
            
            cd('C:\Users\Lenovo\Desktop\Database\EKG Kayýtlarý - Simulator\mat')
            isFile = exist( [num2str(data) '_RawSignal.bin'] );
            
        case 'MIT'
            
            cd('C:\Users\Lenovo\Desktop\Database\MIT Database')
            isFile = exist(num2str(data));
                   
        case 'MIT Long Term'
            
            cd('C:\Users\Lenovo\Desktop\Database\MIT Long Term Database')
            isFile = exist(num2str(data));
            
        case 'OneDay'
            
            cd('C:\Users\Lenovo\Desktop\Database\One Day Data')
            isFile = exist( [ num2str(data) '.mat' ] );
            
        case 'QT_sel'
            cd('C:\Users\Lenovo\Desktop\Database\QT Database\')
            isFile = exist( [ 'sel' num2str(data) 'm' ] );
            
        case 'CU'
            cd('C:\Users\Lenovo\Desktop\Database\CU Database\')
            if length( num2str(data) ) == 1
                isFile = exist( [ 'cu0' num2str(data) ] );
            else
                isFile = exist( [ 'cu' num2str(data) ] );
            end
                  
        case 'AHA'
            cd('C:\Users\Lenovo\Desktop\Database\AHA Database\')
            isFile = exist( [ num2str(data) '.txt' ] );
            
        case 'AHA Short'
            cd('C:\Users\Lenovo\Desktop\Database\AHA Database Short\')
            isFile = exist( [ num2str(data) '_RawSignal.bin' ] );
            
        case 'NST'
             MatlabAPI( 'NST', '118e_6', false );
             MatlabAPI( 'NST', '118e00', false );
             MatlabAPI( 'NST', '118e06', false );
             MatlabAPI( 'NST', '118e12', false );
             MatlabAPI( 'NST', '118e18', false );
             MatlabAPI( 'NST', '118e24', false );
             MatlabAPI( 'NST', '119e_6', false );
             MatlabAPI( 'NST', '119e00', false );
             MatlabAPI( 'NST', '119e06', false );
             MatlabAPI( 'NST', '119e12', false );
             MatlabAPI( 'NST', '119e18', false );
             MatlabAPI( 'NST', '119e24', false );
            
    end
    
    % Is file exists
    if isFile
        display(num2str(data))
        % Go to main algorithm adress
        cd('C:\Users\Lenovo\Desktop\MatlabAPI Developer');
        % Main Algorithm
        MatlabAPI(database, data, false);
            
        disp('-----------------------------')
        close all;
        
    end
    
end

cd('C:\Users\Lenovo\Desktop\MatlabAPI Developer');

% profreport

end
