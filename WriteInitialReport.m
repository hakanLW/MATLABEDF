% Generate Parameters
ReAnalysisParameters.AlarmButton = AlarmButton;

if ~isempty( ReAnalysisParameters.AlarmButton )
    numberofAlarmButton = int32( numel( ReAnalysisParameters.AlarmButton.StartTime ) );
    ReAnalysisParameters.AlarmButton.StartTime(numberofAlarmButton+1)= deal( '0001-01-01T00:00:00.000Z' );
    ReAnalysisParameters.AlarmButton.StartPoint(numberofAlarmButton+1)= deal(int32(0));
    ReAnalysisParameters.AlarmButton.EndTime(numberofAlarmButton+1)=deal( '0001-01-01T00:00:00.000Z' );
    ReAnalysisParameters.AlarmButton.EndPoint(numberofAlarmButton+1)=deal(int32(0));
    ReAnalysisParameters.AlarmButton.AverageHeartRate(numberofAlarmButton+1)= deal(int32(0));
    ReAnalysisParameters.AlarmButton.Duration(numberofAlarmButton+1)= deal(int32(0));
else
    ReAnalysisParameters.AlarmButton = string(NaN);
    
end

ReAnalysisParameters.AnalysisParametersRequest = AnalysisParametersRequest;

if ~isempty( ReAnalysisParameters.AnalysisParametersRequest.IntervalWithoutSignal )
    numberofIntervalWithoutSignal = int32( numel( ReAnalysisParameters.AnalysisParametersRequest.IntervalWithoutSignal ) );
    ReAnalysisParameters.AnalysisParametersRequest.IntervalWithoutSignal(numberofIntervalWithoutSignal+1).StartTime = deal( '0001-01-01T00:00:00.000Z' );
    ReAnalysisParameters.AnalysisParametersRequest.IntervalWithoutSignal(numberofIntervalWithoutSignal+1).EndTime= deal( '0001-01-01T00:00:00.000Z' );
    ReAnalysisParameters.AnalysisParametersRequest.IntervalWithoutSignal(numberofIntervalWithoutSignal+1).Type=deal( 'Noise' );
end
%duzeltme
ReAnalysisParameters.BeatNoisePoints = single(BeatNoisePoints);
ReAnalysisParameters.HolterRecordInfoRequest = HolterRecordInfoRequest;
ReAnalysisParameters.MatlabAPIConfigRequest = MatlabAPIConfigRequest;
ReAnalysisParameters.QRSComplexes  = QRSComplexes;
%duzeltme
ReAnalysisParameters.QRSComplexes.AtrialBeats = single(QRSComplexes.AtrialBeats);
ReAnalysisParameters.QRSComplexes.VentricularBeats = single(QRSComplexes.VentricularBeats);
ReAnalysisParameters.QRSComplexes.SecondPWave = single(QRSComplexes.SecondPWave);
ReAnalysisParameters.QRSComplexes.NoisyBeat = single(QRSComplexes.NoisyBeat);
%duzeltme
ReAnalysisParameters.SignalNoisePoints = single(SignalNoisePoints);

ReAnalysisParameters.VentricularFibrillationRuns = VentricularFibrillationRuns;

if ~isempty( ReAnalysisParameters.VentricularFibrillationRuns)
    
    numberofVentricularFibrillationRuns= int32( numel( ReAnalysisParameters.VentricularFibrillationRuns.StartTime ) );
    ReAnalysisParameters.VentricularFibrillationRuns.Start(numberofVentricularFibrillationRuns+1)= deal(int32(0));
    ReAnalysisParameters.VentricularFibrillationRuns.StartTime(numberofVentricularFibrillationRuns+1)= deal(( '0001-01-01T00:00:00.000Z') );
    ReAnalysisParameters.VentricularFibrillationRuns.End(numberofVentricularFibrillationRuns+1)= deal(int32(0));
    ReAnalysisParameters.VentricularFibrillationRuns.EndTime(numberofVentricularFibrillationRuns+1)=deal( '0001-01-01T00:00:00.000Z' );
    ReAnalysisParameters.VentricularFibrillationRuns.Duration(numberofVentricularFibrillationRuns+1)=deal(int32(0));
    
    
else
    
    ReAnalysisParameters.VentricularFibrillationRuns = string(NaN);
end


ReAnalysisParameters.AsystoleRuns = AsystoleRuns;
if ~isempty( ReAnalysisParameters.AsystoleRuns )
    numberofAsystoleRuns = int32( numel( ReAnalysisParameters.AsystoleRuns.StartTime ) );
    ReAnalysisParameters.AsystoleRuns.StartTime(numberofAsystoleRuns+1)= deal( '0001-01-01T00:00:00.000Z' );
    ReAnalysisParameters.AsystoleRuns.EndTime(numberofAsystoleRuns+1)=deal( '0001-01-01T00:00:00.000Z' );
    ReAnalysisParameters.AsystoleRuns.Duration(numberofAsystoleRuns+1)=deal(int32(0));
    ReAnalysisParameters.AsystoleRuns.AverageHeartRate(numberofAsystoleRuns+1)= deal(int32(0));
else
    ReAnalysisParameters.AsystoleRuns = string(NaN);
end


ReAnalysisParameters.AsysMissingIntervals = AsysMissingIntervals;
if ~isempty( ReAnalysisParameters.AsysMissingIntervals )
    numberofAsysMissingIntervals = int32( numel( ReAnalysisParameters.AsysMissingIntervals.StartPoint ) );
    ReAnalysisParameters.AsysMissingIntervals.StartPoint(numberofAsysMissingIntervals+1)= deal(int32(0));
    ReAnalysisParameters.AsysMissingIntervals.EndPoint(numberofAsysMissingIntervals+1)=deal(int32(0));
    ReAnalysisParameters.AsysMissingIntervals.Duration(numberofAsysMissingIntervals+1)=deal(int32(0));
    ReAnalysisParameters.AsysMissingIntervals.AveragedHeartRate(numberofAsysMissingIntervals+1)= deal(int32(0));
else
    ReAnalysisParameters.AsysMissingIntervals = string(NaN);
end

ReAnalysisParameters.PauseRuns =  PauseRuns;
if ~isempty( ReAnalysisParameters.PauseRuns )
    numberofPauseRuns = int32( numel( ReAnalysisParameters.PauseRuns.StartTime ) );
    ReAnalysisParameters.PauseRuns.StartTime(numberofPauseRuns+1)= deal(( '0001-01-01T00:00:00.000Z') );
    ReAnalysisParameters.PauseRuns.EndTime(numberofPauseRuns+1)=deal( '0001-01-01T00:00:00.000Z' );
    ReAnalysisParameters.PauseRuns.Duration(numberofPauseRuns+1)=deal(int32(0));
    ReAnalysisParameters.PauseRuns.AverageHeartRate(numberofPauseRuns+1)= deal(int32(0));
else
    ReAnalysisParameters.PauseRuns = string(NaN);
end

ReAnalysisParameters.PauseMissingIntervals = PauseMissingIntervals;
if ~isempty( ReAnalysisParameters.PauseMissingIntervals )
    numberofPauseMissingIntervals = int32( numel( ReAnalysisParameters.PauseMissingIntervals.StartPoint ) );
    ReAnalysisParameters.PauseMissingIntervals.StartPoint(numberofPauseMissingIntervals+1)= deal(int32(0));
    ReAnalysisParameters.PauseMissingIntervals.EndPoint(numberofPauseMissingIntervals+1)=deal(int32(0));
    ReAnalysisParameters.PauseMissingIntervals.Duration(numberofPauseMissingIntervals+1)=deal(int32(0));
    ReAnalysisParameters.PauseMissingIntervals.AveragedHeartRate(numberofPauseMissingIntervals+1)= deal(int32(0));
else
    ReAnalysisParameters.PauseMissingIntervals = string(NaN);
end

ReAnalysisParameters.NoiseRuns = NoiseRuns;
%duzeltme
ReAnalysisParameters.NoiseRuns.Points = single(NoiseRuns.Points);

if ~isempty( ReAnalysisParameters.NoiseRuns )
    
    numberofNoiseRuns = int32( numel( ReAnalysisParameters.NoiseRuns.StartTime ) );
    ReAnalysisParameters.NoiseRuns.Start(numberofNoiseRuns+1)= deal(int32(0));
    ReAnalysisParameters.NoiseRuns.StartTime(numberofNoiseRuns+1)= deal(( '0001-01-01T00:00:00.000Z') );
    ReAnalysisParameters.NoiseRuns.End(numberofNoiseRuns+1)= deal(int32(0));
    ReAnalysisParameters.NoiseRuns.EndTime(numberofNoiseRuns+1)=deal( '0001-01-01T00:00:00.000Z' );
    ReAnalysisParameters.NoiseRuns.Duration(numberofNoiseRuns+1)=deal(int32(0));
    ReAnalysisParameters.NoiseRuns.AverageHeartRate(numberofNoiseRuns+1)= deal(int32(0));
    
else
    
    ReAnalysisParameters.NoiseRuns = string(NaN);
end


% Generate Json
ReAnalysisParameters = jsonencode( ReAnalysisParameters );


% File
% file adress
fileAdress = strrep(MatlabAPIConfigRequest.FileAdress, '_RawSignal.bin' , '_InitialMatlabAPIReport.json' );
% open file
initialReportFile = fopen(fileAdress, 'w');
% write json to file
fwrite(initialReportFile, ReAnalysisParameters);
% close file
fclose(initialReportFile);
% close all
fclose( 'all' );

clear ReAnalysisParameters



