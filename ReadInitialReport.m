% Initial Parameters
tempRecordInfo = HolterRecordInfoRequest;

% File
% file adress
targetFileAdress = strrep(MatlabAPIConfigRequest.FileAdress, '_RawSignal.bin' , '_InitialMatlabAPIReport.json' );
% read file
ReAnalysisParameters = jsondecode( fileread( char( targetFileAdress ) ) );

% Decode ReAnalysisParameters
% - AlarmButton
AlarmButton = ReAnalysisParameters.AlarmButton;
% - AnalysisParametersRequest
AnalysisParametersRequest = ReAnalysisParameters.AnalysisParametersRequest;
% - BeatNoisePoints
BeatNoisePoints = logical(ReAnalysisParameters.BeatNoisePoints);
% - HolterRecordInfoRequest
%     HolterRecordInfoRequest = ReAnalysisParameters.HolterRecordInfoRequest;
HolterRecordInfoRequest.RecordStartTime = tempRecordInfo.RecordStartTime;
HolterRecordInfoRequest.RecordEndTime = tempRecordInfo.RecordEndTime;

% - MatlabAPIConfigRequest
MatlabAPIConfigRequest.AnalysisStartDateTime =  datetime('now');
% - QRSComplexes
QRSComplexes = ReAnalysisParameters.QRSComplexes;
%duzeltme
QRSComplexes.AtrialBeats=logical(ReAnalysisParameters.QRSComplexes.AtrialBeats);
QRSComplexes.VentricularBeats = logical(ReAnalysisParameters.QRSComplexes.VentricularBeats);
QRSComplexes.SecondPWave = logical(ReAnalysisParameters.QRSComplexes.SecondPWave);
QRSComplexes.NoisyBeat = logical(ReAnalysisParameters.QRSComplexes.NoisyBeat);
%duzeltme

% - SignalNoisePoints
SignalNoisePoints = logical(ReAnalysisParameters.SignalNoisePoints);

% - VentricularFibrillationRuns
if ~isempty(ReAnalysisParameters.VentricularFibrillationRuns)
    VentricularFibrillationRuns = ReAnalysisParameters.VentricularFibrillationRuns;
    VentricularFibrillationRuns.StartTime = datetime(char(ReAnalysisParameters.VentricularFibrillationRuns.StartTime), 'Format','uuuu-MM-dd''T''HH:mm:ss.SSSXXX','TimeZone','UTC');
    VentricularFibrillationRuns.EndTime =  datetime(char(ReAnalysisParameters.VentricularFibrillationRuns.EndTime), 'Format','uuuu-MM-dd''T''HH:mm:ss.SSSXXX','TimeZone','UTC');
    
    
    %         VentricularFibrillationRuns.StartTime=string(char(ReAnalysisParameters.VentricularFibrillationRuns.StartTime));
    %         VentricularFibrillationRuns.EndTime=string(char(ReAnalysisParameters.VentricularFibrillationRuns.EndTime));
else
    VentricularFibrillationRuns = [ ];
end

%Noise
if ~isempty(  ReAnalysisParameters.AsystoleRuns)
    AsystoleRuns= ReAnalysisParameters.AsystoleRuns;
    AsystoleRuns.StartTime = datetime(char(ReAnalysisParameters.AsystoleRuns.StartTime), 'Format','uuuu-MM-dd''T''HH:mm:ss.SSSXXX','TimeZone','UTC');
    AsystoleRuns.EndTime =  datetime(char(ReAnalysisParameters.AsystoleRuns.EndTime), 'Format','uuuu-MM-dd''T''HH:mm:ss.SSSXXX','TimeZone','UTC');
    
    %         AsystoleRuns.StartTime=string(char(ReAnalysisParameters.AsystoleRuns.StartTime));
    %         AsystoleRuns.EndTime=string(char(ReAnalysisParameters.AsystoleRuns.EndTime));
else
    AsystoleRuns= [ ];
end

if ~isempty(  ReAnalysisParameters.AsysMissingIntervals)
    AsysMissingIntervals=ReAnalysisParameters.AsysMissingIntervals;
else
    AsysMissingIntervals= [ ];
end

if ~isempty(  ReAnalysisParameters.PauseRuns)
    PauseRuns=ReAnalysisParameters.PauseRuns;
    
    %         datetime( charArray, 'Format','uuuu-MM-dd''T''HH:mm:ss.SSSXXX','TimeZone','UTC');
    
    PauseRuns.StartTime = datetime(char(ReAnalysisParameters.PauseRuns.StartTime), 'Format','uuuu-MM-dd''T''HH:mm:ss.SSSXXX','TimeZone','UTC');
    PauseRuns.EndTime =  datetime(char(ReAnalysisParameters.PauseRuns.EndTime), 'Format','uuuu-MM-dd''T''HH:mm:ss.SSSXXX','TimeZone','UTC');
    %         PauseRuns.StartTime=string(char(ReAnalysisParameters.PauseRuns.StartTime));
    %         PauseRuns.EndTime=string(char(ReAnalysisParameters.PauseRuns.EndTime));
else
    PauseRuns = [ ];
end

if ~isempty(  ReAnalysisParameters.PauseMissingIntervals)
    PauseMissingIntervals= ReAnalysisParameters.PauseMissingIntervals;
else
    PauseMissingIntervals = [ ];
end


if ~isempty(  ReAnalysisParameters.NoiseRuns)
    NoiseRuns= ReAnalysisParameters.NoiseRuns;
    NoiseRuns.StartTime = datetime(char(ReAnalysisParameters.NoiseRuns.StartTime), 'Format','uuuu-MM-dd''T''HH:mm:ss.SSSXXX','TimeZone','UTC');
    NoiseRuns.EndTime =  datetime(char(ReAnalysisParameters.NoiseRuns.EndTime), 'Format','uuuu-MM-dd''T''HH:mm:ss.SSSXXX','TimeZone','UTC');
    
    % NoiseRuns.StartTime=string(char(ReAnalysisParameters.NoiseRuns.StartTime));
    % NoiseRuns.EndTime=string(char(ReAnalysisParameters.NoiseRuns.EndTime));
else
    NoiseRuns = [ ];
end


% ECG File
temp.FileAdress = char( strrep(MatlabAPIConfigRequest.FileAdress, '_RawSignal.bin' , '_FilteredSignal.bin' ) );
[ ECGSignals ] = ECGBinary2Structure( temp, HolterRecordInfoRequest );

clear ReAnalysisParameters