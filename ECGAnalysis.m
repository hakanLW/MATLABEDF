
% ECG Analysis Main
%
% [JsonResponsePackets] = ECGAnalysis ( FileAdress, JsonRequestPackets)
%
% <<< Function Inputs >>>
%   string FileAdress
%   string JsonRequestPackets
%
% <<< Function outputs >>>
%   string JsonResponsePackets
%   file _FilteredSignal.bin
%   file _MatlabAPIReport.json

function [JsonResponsePackets] = ECGAnalysis ( FileAdress, JsonRequestPackets)

hakan =5;
%% Initialization


JsonResponsePackets = [ ];


%% Matlab API Info



% Format
format longG

% Versions
ResponseInfo.Version.Major = int32( 11 );
ResponseInfo.Version.Minor = int32( 0 );
ResponseInfo.Version.Build = int32( 5);

disp('VERSION 1.0.4')


% Analysis Info
disp(' ')
disp( 'Analysis is started...' )
disp(' ')
ResponseInfo.Analysis.StartDateTime = datetime('now','TimeZone','UTC','Format','d-MMM-y HH:mm:ss');


%% Decode Request Packets


% - Request Packets
[ HolterRecordInfoRequest, AnalysisParametersRequest, AlarmButton, MatlabAPIConfigRequest ] = ...
    DecodeRequestJson( JsonRequestPackets, FileAdress );
clear JsonRequestPackets;
clear FileAdress;
if MatlabAPIConfigRequest.IsLogWriteToConsole
    disp('Request packets are imported...')
    disp(' ')
end



%% Get ECG Signal


    
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp('ECG Signal is being imported...')
        tic
    end
    % Get ECG for each channel.
    ECGSignals = ECGBinary2Structure( MatlabAPIConfigRequest, HolterRecordInfoRequest );
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp('# Completed...')
        toc
        disp(' ')
    end
    



%% Resample ECG Signal


    
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp('ECG Signal is resampling...')
        tic
    end
    % Get ECG for each channel.
    [ECGSignals, HolterRecordInfoRequest]= ReSampleECG( ECGSignals, HolterRecordInfoRequest);
    
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp('# Completed...')
        toc
        disp(' ')
    end
    

%Pace Detection
if MatlabAPIConfigRequest.PaceMaker
[ECGSignals.(MatlabAPIConfigRequest.AnalysisChannel), Pace] = ...
PaceDetector(ECGSignals.(MatlabAPIConfigRequest.AnalysisChannel),...
HolterRecordInfoRequest.RecordSamplingFrequency);
else
Pace=[ ];   
end

    

%% ECG Signal Filtering


    
    % Report and Analysis filter operations
    [ ECGSignals ] = ...
        ECGFilterSignal( ECGSignals, HolterRecordInfoRequest, MatlabAPIConfigRequest );

 % % Signal Control for 12 Channel Analysis
% disp( 'Signal Control for 12 Channel Analysis:' )
% tic
% fields =string(fieldnames(ECGSignals));
% if ~ismember(MatlabAPIConfigRequest.AnalysisChannel,fields)
%   disp( '#There is no signal in this channel.  Analysis cnannel is changing ...' )
%   if ismember("Lead2",fields)
%   MatlabAPIConfigRequest.AnalysisChannel = char("Lead2");
%    disp( 'Analysis channel is Lead2' )
%   else
%   MatlabAPIConfigRequest.AnalysisChannel =char(fields(1));
%   disp( 'Analysis channel is:')
%   disp(MatlabAPIConfigRequest.AnalysisChannel)
%   end
%   
% end
% disp('# Completed...')
%   toc
%   disp( ' ' )   


%% Beat Detection & Characterization


%%%%%%%%%%%%%%%%%%%%%%%%%
% Beat Detection
%%%%%%%%%%%%%%%%%%%%%%%%%

    
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp( 'Beat Detection: ' )
        tic
    end
    [ QRSComplexes ] = Detection_Beat( ...
        ECGSignals.( MatlabAPIConfigRequest.AnalysisChannel ), ...
        HolterRecordInfoRequest, ...
        AnalysisParametersRequest, ...
        MatlabAPIConfigRequest );
    QRSComplexes.NoisyBeat=zeros(length(QRSComplexes.R),1);
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp('# Completed...')
        toc
        disp( ' ' )
    end
  


%%%%%%%%%%%%%%%%%%%%%%%%%
% Q and S Detection
%%%%%%%%%%%%%%%%%%%%%%%%%

    
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp( 'Q and S Detection: ' )
        tic
    end
    [ QRSComplexes ] = Detection_QS( ...
        ECGSignals.( MatlabAPIConfigRequest.AnalysisChannel ), ...
        QRSComplexes, ...
        HolterRecordInfoRequest );
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp('# Completed...')
        toc
        disp( ' ' )
    end
    


% %%%%%%%%%%%%%%%%%%%%%%%%%
% % NOISE BEAT CLASSIFICATION
% %%%%%%%%%%%%%%%%%%%%%%%%%

    
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp( 'Noise beat classifications are being extracted: ' )
        tic
    end
    [ QRSComplexes, SignalNoisePoints ] = NoiseBeatClassification(  ...
        ECGSignals.( MatlabAPIConfigRequest.AnalysisChannel ), ...
        QRSComplexes, ...
        HolterRecordInfoRequest );
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp('# Completed...')
        toc
        disp( ' ' )
    end
    



%%%%%%%%%%%%%%%%%%%%%%%%%
% % Ventricular Fibrillation Detection
%%%%%%%%%%%%%%%%%%%%%%%%%

    
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp( 'Ventricular Fibrillation / Noise Detection: ' )
        tic
    end
    [ QRSComplexes, VentricularFibrillationRuns, AnalysisParametersRequest ]  = Detection_VFib( ...
        ECGSignals, ...
        QRSComplexes, ...
        SignalNoisePoints, ...
        HolterRecordInfoRequest, ...
        AnalysisParametersRequest, ...
        MatlabAPIConfigRequest.AnalysisChannel );
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp('# Completed...')
        toc
        disp( ' ' )
    end
    




% %%%%%%%%%%%%%%%%%%%%%%%%%
% % BEAT MORPHOLOGY
% %%%%%%%%%%%%%%%%%%%%%%%%%

    
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp( 'Beat morphologies are being extracted: ' )
        tic
    end
    [ QRSComplexes, QRSMorphologies, BeatNoisePoints ] = BeatMorphology( ...
        ECGSignals.( MatlabAPIConfigRequest.AnalysisChannel ), ...
        QRSComplexes, ...
        HolterRecordInfoRequest );
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp('# Completed...')
        toc
        disp( ' ' )
    end
    



% %%%%%%%%%%%%%%%%%%%%%%%%%
% % BEAT CLASSIFICATION
% %%%%%%%%%%%%%%%%%%%%%%%%%

    
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp( 'Beat classifications are being extracted: ' )
        tic
    end
    [ QRSComplexes, AnalysisParametersRequest.NormalQRSInterval] = BeatClassification( ...
        ECGSignals.( MatlabAPIConfigRequest.AnalysisChannel ), ...
        QRSComplexes, ...
        QRSMorphologies, ...
        HolterRecordInfoRequest, ...
        MatlabAPIConfigRequest );
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp('# Completed...')
        toc
        disp( ' ' )
    end
    



% %%%%%%%%%%%%%%%%%%%%%%%%%
% % P and T Detection
% %%%%%%%%%%%%%%%%%%%%%%%%%

    
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp( 'P and T Detection: ' )
        tic
    end
    [ QRSComplexes ]  = Detection_PT( ...
        ECGSignals.( MatlabAPIConfigRequest.AnalysisChannel ), ...
        MatlabAPIConfigRequest.AnalysisChannel, ...
        QRSComplexes, ...
        HolterRecordInfoRequest, ...
        AnalysisParametersRequest );
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp('# Completed...')
        toc
        disp( ' ' )
    end
    


% % %%%%%%%%%%%%%%%%%%%%%%%%%
% % % PREMATURE BEAT CLASSIFICATION
% % %%%%%%%%%%%%%%%%%%%%%%%%%
% if MatlabAPIConfigRequest.IsLogWriteToConsole
%     disp( 'Premature beat classifications are being extracted: ' )
%     tic
% end
% QRSComplexes = PrematureBeatClassification(QRSComplexes, ...
%     AnalysisParametersRequest );
% if MatlabAPIConfigRequest.IsLogWriteToConsole
%     disp('# Completed...')
%     toc
%     disp( ' ' )
% end
%     



%% Asystole, Pause and Noise Detection

%%%%%%%%%%%%%%%%%%%%%%%%%
% Asystole and Pause
%%%%%%%%%%%%%%%%%%%%%%%%%

    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp('Asystole and Pause Detection: ')
        tic
    end
    
    [AsystoleRuns, AsysMissingIntervals ] = ClassRhythmAnalysis.AsystoleDetection(ECGSignals, ...
        QRSComplexes.R, ...
        HolterRecordInfoRequest, ...
        AnalysisParametersRequest, ...
        MatlabAPIConfigRequest.AnalysisChannel );
    
    [PauseRuns, PauseMissingIntervals ] = ClassRhythmAnalysis.PauseDetection( ECGSignals,...
        QRSComplexes, ...
        length( ECGSignals.( MatlabAPIConfigRequest.AnalysisChannel ) ), ...
        HolterRecordInfoRequest, ...
        AnalysisParametersRequest, ...
        MatlabAPIConfigRequest.AnalysisChannel );
    
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp('# Completed...')
        toc
        disp(' ')
    end


%%%%%%%%%%%%%%%%%%%%%%%%%
% Noise Runs
%%%%%%%%%%%%%%%%%%%%%%%%%

if MatlabAPIConfigRequest.IsLogWriteToConsole
    disp('Lost Connection Control: ')
    tic
end

    
    % Missing Interval Assessment
    [ QRSComplexes, NoiseRuns, AsystoleRuns, ~, AnalysisParametersRequest ] = ClassUnusualSignalDetection.GetNoiseRun( ...
        QRSComplexes, ...
        AsystoleRuns, ...
        AsysMissingIntervals, ...
        PauseRuns, ...
        PauseMissingIntervals, ...
        ( BeatNoisePoints | SignalNoisePoints ), ...
        AnalysisParametersRequest, ...
        HolterRecordInfoRequest );
    
    if MatlabAPIConfigRequest.IsLogWriteToConsole
        disp('# Completed...')
        toc
        disp(' ')
    end




%% Remove Unneeded Channels

ECGSignals = ClassChangeChannel.RemoveChannel( ECGSignals, HolterRecordInfoRequest, MatlabAPIConfigRequest );


%% Interval and Segment Calculation


if MatlabAPIConfigRequest.IsLogWriteToConsole
    disp( 'Intervals and Segments are being calculated' )
    tic
end
[ QRSComplexes ] = ECGIntervalSegmentCalculation( ...
    ECGSignals.( MatlabAPIConfigRequest.AnalysisChannel ), ...
    QRSComplexes, ...
    HolterRecordInfoRequest );
if MatlabAPIConfigRequest.IsLogWriteToConsole
    disp('# Completed...')
    toc
    disp( ' ' )
end


%% Morphology Based Premature Beat Classification

if MatlabAPIConfigRequest.IsLogWriteToConsole
    tic
    disp('Morph and Template Based Premature Beat Detection ')
end

[ QRSComplexes,similarity, NormalSample ] = MorphBasedRecognition( QRSComplexes ,  ECGSignals.( MatlabAPIConfigRequest.AnalysisChannel));


if MatlabAPIConfigRequest.IsLogWriteToConsole
    disp('# Completed...')
    toc
    disp(' ')
end



%% Beat Type

if MatlabAPIConfigRequest.IsLogWriteToConsole
    tic
    disp('Beat Type Recoginition: ')
end
QRSComplexes = BeatTypeRecognition( QRSComplexes );
if MatlabAPIConfigRequest.IsLogWriteToConsole
    disp('# Completed...')
    toc
    disp(' ')
end


%% Heart Rate Analysis

if MatlabAPIConfigRequest.IsLogWriteToConsole
    tic
    disp('Heart Rate Analysis:')
end

[ GeneralPeriod, ActivePeriod, PassivePeriod] = ClassRhythmAnalysis.TimeBasedAnalysis( ...
    QRSComplexes, ...
    HolterRecordInfoRequest ,...
    AnalysisParametersRequest );

if MatlabAPIConfigRequest.IsLogWriteToConsole
    disp('- Time based rhythm analysis is completed.')
end

HRVAnalysisResults = ...
    HRVAnalysis( QRSComplexes, length( ECGSignals.(MatlabAPIConfigRequest.AnalysisChannel ) ), AnalysisParametersRequest, HolterRecordInfoRequest );
if MatlabAPIConfigRequest.IsLogWriteToConsole
    disp('- Heart Rate Variability analysis is completed.')
end

if MatlabAPIConfigRequest.IsLogWriteToConsole
    disp('# Completed...')
    toc
    disp(' ')
end



%% Generate Response Packets
% - Analysis Summary Response
JsonResponsePackets.AnalysisSummaryResponse = ClassPackageOutput.AnalysisSummaryPacket ( ...
    MatlabAPIConfigRequest.AnalysisChannel, ... % Main analysis channel
    HolterRecordInfoRequest, ... % Holter Record Info
    length( ECGSignals.( MatlabAPIConfigRequest.AnalysisChannel ) ), ... % Signal Duration
    QRSComplexes, ...  % Total Beats
    NoiseRuns, ... % Noise Runs
    NormalSample ...
    );

% - Heart Rate Summary
JsonResponsePackets.HeartRateSummaryResponse = ClassPackageOutput.HeartRateSummaryPacket( ....
    GeneralPeriod, ... % Heart rate summary of the all the signal round
    ActivePeriod, ... % Heart rate summary of the active hours
    PassivePeriod ... % Heart rate summary of the passive hours
    );

% - Heart Rate Variablity
if ResponseInfo.Version.Major > 6
    JsonResponsePackets.HRVariabilityResponseV2 = ClassPackageOutput.HRVariabilityPacket( ...
        HRVAnalysisResults, ...
        ResponseInfo ...
        ); % Under development...
else
    JsonResponsePackets.HRVariabilityResponse = ClassPackageOutput.HRVariabilityPacket( ...
        HRVAnalysisResults, ...
        ResponseInfo ...
        ); % Under development...
end


% - ST Segment Analysis
if ResponseInfo.Version.Major > 6
    JsonResponsePackets.STSegmentAnalysisResponseV2 = ClassPackageOutput.STSegmentAnalysisPacket( ...
        QRSComplexes, ...
        HolterRecordInfoRequest, ...
        ResponseInfo ...
        );
else
    JsonResponsePackets.STSegmentAnalysisResponse = ClassPackageOutput.STSegmentAnalysisPacket( ...
        QRSComplexes, ...
        HolterRecordInfoRequest, ...
        ResponseInfo ...
        );
end


% Noise
JsonResponsePackets.NoiseResponse = ClassPackageOutput.NoisePacket( ...
    NoiseRuns,... % Noise Runs
    ( length( ECGSignals.( MatlabAPIConfigRequest.AnalysisChannel ) ) / HolterRecordInfoRequest.RecordSamplingFrequency ) ... % Total Duration
    );


% - Ventricular Fibrillation
JsonResponsePackets.VentricularFibrillationResponse = ClassPackageOutput.VentricularFibPacket( ...
    VentricularFibrillationRuns, ... % VFib Runs
    round( numel( ECGSignals.( MatlabAPIConfigRequest.AnalysisChannel ) ) / HolterRecordInfoRequest.RecordSamplingFrequency ) ... % Total Duration
    );



% - Asystole
JsonResponsePackets.AsystoleResponse = ClassPackageOutput.AsystolePacket( ...
    AsystoleRuns,... % Asystole Runs
    ( length( ECGSignals.( MatlabAPIConfigRequest.AnalysisChannel ) ) / HolterRecordInfoRequest.RecordSamplingFrequency ) ... % Total Beats
    );

% - AlarmButton
JsonResponsePackets.AlarmButtonResponse = ClassPackageOutput.AlarmButtonPacket( AlarmButton, QRSComplexes, HolterRecordInfoRequest );

% - Beat Details
JsonResponsePackets.BeatDetailsResponse = ClassPackageOutput.BeatDetailsPacket( QRSComplexes, HolterRecordInfoRequest.RecordSamplingFrequency,similarity);

%-PaceMakerResponse
JsonResponsePackets.PaceMakerResponse = ClassPackageOutput.PaceMakerPacket( Pace,SignalNoisePoints );

%% Json Encode

if MatlabAPIConfigRequest.IsLogWriteToConsole
    disp('Json Model is being generated.')
    tic
end
JsonResponsePackets = ClassPackageOutput.JsonPacket( JsonResponsePackets, MatlabAPIConfigRequest.FileAdress, ResponseInfo );
if MatlabAPIConfigRequest.IsLogWriteToConsole
    disp('# Completed...')
    toc
    disp(' ')
end


%% Measure Total Analysis Duration

% Analysis Finish Datetime
MatlabAPIConfigRequest.AnalysisFinishDateTime = datetime('now');
% Display
disp( [ 'Analysis is completed: *** NOISE RUNS ARE REMOVED ***  10.08.2022'  ...
    char(datetime('now') ) ] );
disp( [ 'Total Analysis Duration: ' ...
    num2str( seconds( MatlabAPIConfigRequest.AnalysisFinishDateTime - MatlabAPIConfigRequest.AnalysisStartDateTime ) ) ' seconds.' ] )
disp( [ 'MatlabAPI Version: ' ...
    num2str( ResponseInfo.Version.Major ) '.' num2str( ResponseInfo.Version.Minor ) '.' num2str( ResponseInfo.Version.Build ) ] )


% %%Plot
% 
% %%%%%%%%%
% %% Analysis Result
% disp(' ')
% disp('Plotting is in progress:')
% PlotWaves( ECGSignals.( MatlabAPIConfigRequest.AnalysisChannel ), QRSComplexes, JsonResponsePackets );
% disp('# Completed...')
% disp(' ')


%% End of the Analysis

fclose( 'all' );
clearvars -except JsonResponsePackets


end

