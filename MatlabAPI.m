
% Run ECG Analysis for specified data 
%
% [ JsonResponsePackets,  JsonRequestPackets ] = MatlabAPI( databaseName, dataName )
%
% <<< Function Inputs >>>
%   char databaseName
%   single dataName
%
% <<< Function Outputs >>>
%   string JsonResponsePackets
%   string JsonRequestPackets
%

function [ JsonResponsePackets,  JsonRequestPackets ] = MatlabAPI( databaseName, dataName, getReport )

%% ECG Signal

switch databaseName
    
    case 'Online Simulator'
        
        fileAdress = 'C:\Users\Lenovo\Desktop\Database\Online Simulator\';
        currentAdress = pwd; cd( fileAdress );
        RealData2Bin( currentAdress, dataName )
        fileAdress =[ fileAdress dataName '_RawSignal.bin' ];
        
    case 'Simulator'
        
        fileAdress = 'C:\Users\Lenovo\Desktop\Database\EKG Kayýtlarý - Simulator\mat\';
        fileAdress =[ fileAdress num2str(dataName) '_RawSignal.bin' ];
        
    case 'MIT'
        
        fileAdress = 'C:\Users\Lenovo\Desktop\Database\MIT Database\';
        fileAdress = [ fileAdress num2str(dataName) '\'  num2str(dataName) '_RawSignal.bin' ];
        
    case 'MIT Long Term'
        
        fileAdress = 'C:\Users\Lenovo\Desktop\Database\MIT Long Term Database\';
        fileAdress = [ fileAdress num2str(dataName) '\'  num2str(dataName) '_RawSignal.bin' ];
        
    case 'OneDay'
        
        fileAdress = 'C:\Users\Lenovo\Desktop\Database\One Day Data\';
        fileAdress = [ fileAdress num2str(dataName) '_RawSignal.bin' ];
        
    case 'QT_sel'
        fileAdress =  'C:\Users\Lenovo\Desktop\Database\QT Database\';
        fileAdress = [ fileAdress 'sel' num2str(dataName) 'm\'  num2str(dataName) '_RawSignal.bin' ];
         
    case 'QT_sele'
        fileAdress =  'C:\Users\Lenovo\Desktop\Database\QT Database\';
        fileAdress = [ fileAdress 'sele0' num2str(dataName) 'm\'  num2str(dataName) '_RawSignal.bin' ];
        
    case 'RealData'
        fileAdress = 'C:\Users\Lenovo\Desktop\Database\Real Data\';
        currentAdress = pwd; cd( fileAdress ); 
        RealData2Bin( currentAdress, dataName )
        fileAdress =[ fileAdress dataName '_RawSignal.bin' ];
        
    case 'CU'
        fileAdress = 'C:\Users\Lenovo\Desktop\Database\CU Database\';
        if length( num2str(dataName) ) == 1
            fileAdress = [ fileAdress 'cu0' num2str(dataName) '\' num2str(dataName) '_RawSignal.bin' ];
        else
            fileAdress = [ fileAdress 'cu' num2str(dataName) '\'  num2str(dataName) '_RawSignal.bin' ];
        end
        
    case 'MIT Ventricular Database'
        
        fileAdress = 'C:\Users\Lenovo\Desktop\Database\MIT Ventricular Arrhythmia\';
        fileAdress = [ fileAdress num2str(dataName) '\'  num2str(dataName) '_RawSignal.bin' ];
        
    case 'MIT Atrial Fibrillation'
        
        fileAdress = 'C:\Users\Lenovo\Desktop\Database\MIT Atrial Fibrillation\';
        fileAdress = [ fileAdress num2str(dataName) '\'  num2str(dataName) '_RawSignal.bin' ];
        
    case 'Livewell Holter'
        
        fileAdress = 'C:\Users\Lenovo\Desktop\Database\LiveWell Holter\';
        fileAdress = [ fileAdress  num2str(dataName) '_RawSignal.bin' ];
        
    case 'NST'
        
        fileAdress = 'C:\Users\Lenovo\Desktop\Database\NST\';
        fileAdress = [ fileAdress  num2str(dataName) '_RawSignal.bin' ];
        
    case 'AHA'
        
        fileAdress = 'C:\Users\Lenovo\Desktop\Database\AHA Database\';
        fileAdress = [ fileAdress  num2str(dataName) '_RawSignal.bin' ];
        
    case 'AHA Short'
        
        fileAdress = 'C:\Users\Lenovo\Desktop\Database\AHA Database Short\';
        fileAdress = [ fileAdress  num2str(dataName) '_RawSignal.bin' ];
        
    case 'VivaLNK'
        
        fileAdress = 'C:\Users\Lenovo\Desktop\Database\VivaLNK\';
        fileAdress = [ fileAdress  num2str(dataName) '_RawSignal.bin' ];
        
    case '3Channel'
        
        fileAdress = 'C:\Users\Lenovo\Desktop\Database\3Channel\';
        fileAdress = [ fileAdress dataName '_RawSignal.bin' ];
        
    otherwise
        fileAdress = 'D:\NoDataFolder';
        
end

fileAdress = string( fileAdress );

%% Json Input

% New request packet with active ecg channels

% 12 Channel

%JsonRequestPackets = '{"HolterRecordInfoRequest":{"RecordStartTime":"2019-01-01T00:00:00.000Z","RecordEndTime":"2019-01-02T00:00:00.000Z","RecordSamplingFrequency":250,"ChannelList":["V1","V2","V3","V4","V5","V6","Lead1","Lead2","Lead3","aVR","aVL","aVF"],"EcgElectrodeStateList":[{"MeasurementDateTime":"2019-01-01T00:00:00.000Z","CableSetType":6,"ProbeStatus":{"V1":false,"V2":false,"V3":false,"V4":false,"V5":true,"V6":false,"RA":true,"LA":true,"LL":true,"None":false}},{"MeasurementDateTime":"0001-01-01T00:00:00.000Z","CableSetType":0,"ProbeStatus":{"V1":false,"V2":false,"V3":false,"V4":false,"V5":false,"V6":false,"RA":false,"LA":false,"LL":false,"None":true}}]},"AnalysisParametersRequest":{"Bradycardia":{"ClinicThreshold":50,"AlarmThreshold":50,"ActivityThreshold":50},"Tachycardia":{"ClinicThreshold":100,"AlarmThreshold":100,"ActivityThreshold":100},"Pause":{"ClinicThreshold":2000},"Asystole":{"ClinicThreshold":3500},"RRInterval":{"Variability":null,"BeatNumber":null},"ActivePeriod":{"StartTime":6,"EndTime":0},"ActivityPeriod":[],"IntervalWithoutSignal":null},"MatlabAPIConfigRequest":{"IsLogWriteToConsole":true},"AlarmButtonRequest ":null}';
% - ReAnalysis
JsonRequestPackets = '{"HolterRecordInfoRequest":{"RecordStartTime":"2019-01-01T00:00:00.000Z","RecordEndTime":"2019-01-02T00:00:00.000Z","RecordSamplingFrequency":250,"ChannelList":["V1","V2","V3","V4","V5","V6","Lead1","Lead2","Lead3","aVR","aVL","aVF"],"EcgElectrodeStateList":[{"MeasurementDateTime":"2019-01-01T00:00:00.000Z","CableSetType":6,"ProbeStatus":{"V1":false,"V2":false,"V3":false,"V4":false,"V5":true,"V6":false,"RA":true,"LA":true,"LL":true,"None":false}},{"MeasurementDateTime":"0001-01-01T00:00:00.000Z","CableSetType":0,"ProbeStatus":{"V1":false,"V2":false,"V3":false,"V4":false,"V5":false,"V6":false,"RA":false,"LA":false,"LL":false,"None":true}}]},"AnalysisParametersRequest":{"Bradycardia":{"ClinicThreshold":50,"AlarmThreshold":50,"ActivityThreshold":50},"Tachycardia":{"ClinicThreshold":100,"AlarmThreshold":100,"ActivityThreshold":100},"Pause":{"ClinicThreshold":2000},"Asystole":{"ClinicThreshold":3500},"RRInterval":{"Variability":null,"BeatNumber":null},"ActivePeriod":{"StartTime":6,"EndTime":0},"ActivityPeriod":[],"IntervalWithoutSignal":null},"MatlabAPIConfigRequest":{"IsLogWriteToConsole":true},"AlarmButtonRequest ":null,"ReAnalysis":true}';

% 3 Channel

% JsonRequestPackets = '{"HolterRecordInfoRequest":{"RecordStartTime":"2019-01-01T00:00:00.000Z","RecordEndTime":"2019-01-02T00:00:00.000Z","RecordSamplingFrequency":250,"ChannelList":["V5","Lead1","Lead2"],"EcgElectrodeStateList":[{"MeasurementDateTime":"2019-01-01T00:00:00.000Z","CableSetType":6,"ProbeStatus":{"V1":false,"V2":false,"V3":false,"V4":false,"V5":true,"V6":false,"RA":true,"LA":true,"LL":true,"None":false}},{"MeasurementDateTime":"0001-01-01T00:00:00.000Z","CableSetType":0,"ProbeStatus":{"V1":false,"V2":false,"V3":false,"V4":false,"V5":false,"V6":false,"RA":false,"LA":false,"LL":false,"None":true}}]},"AnalysisParametersRequest":{"Bradycardia":{"ClinicThreshold":50,"AlarmThreshold":50,"ActivityThreshold":50},"Tachycardia":{"ClinicThreshold":100,"AlarmThreshold":100,"ActivityThreshold":100},"Pause":{"ClinicThreshold":2000},"Asystole":{"ClinicThreshold":3500},"RRInterval":{"Variability":10,"BeatNumber":5},"ActivePeriod":{"StartTime":6,"EndTime":24},"ActivityPeriod":[],"IntervalWithoutSignal":null},"MatlabAPIConfigRequest":{"IsLogWriteToConsole":true},"AlarmButtonRequest":null,"EnvironmentConfig":{"Environment":null,"ChannelDataPath":"21265\\"}}';

%% ECG Analysis

if getReport
    profile on
    [ JsonResponsePackets ] = ECGAnalysis ( fileAdress, JsonRequestPackets);
    profile viewer
else
    [ JsonResponsePackets ] = ECGAnalysis ( fileAdress, JsonRequestPackets);
end

end












