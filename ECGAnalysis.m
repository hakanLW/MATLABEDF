
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


%% Initialization


JsonResponsePackets = [ ];


%% Matlab API Info


% Format
format longG

% Versions
ResponseInfo.Version.Major = int32( 9 );
ResponseInfo.Version.Minor = int32( 0 );
ResponseInfo.Version.Build = int32( 5);

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
    


% %%%%%%%%%%%%%%%%%%%%%%%%%
% % PREMATURE BEAT CLASSIFICATION
% %%%%%%%%%%%%%%%%%%%%%%%%%
if MatlabAPIConfigRequest.IsLogWriteToConsole
    disp( 'Premature beat classifications are being extracted: ' )
    tic
end
QRSComplexes = PrematureBeatClassification(QRSComplexes, ...
    AnalysisParametersRequest );
if MatlabAPIConfigRequest.IsLogWriteToConsole
    disp('# Completed...')
    toc
    disp( ' ' )
end
    



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

%  clear BeatNoisePoints SignalNoisePoints MissingIntervals


% %% RE-ANALYSIS 
% %   Write and Read Initial Matlab API Report
% 
% 
% if ~MatlabAPIConfigRequest.ReAnalysis
%     if MatlabAPIConfigRequest.IsLogWriteToConsole
%         disp( 'Creating Initial Matlab API Report :' )
%         tic
%     end
%     WriteInitialReport;
%     if MatlabAPIConfigRequest.IsLogWriteToConsole
%         disp('# Completed...')
%         toc
%         disp( ' ' )
%     end
%     
% else
%     
%     if MatlabAPIConfigRequest.IsLogWriteToConsole
%         disp( 'Reading  Initial Matlab API Report:' )
%         tic
%     end
%     ReadInitialReport;
%     if MatlabAPIConfigRequest.IsLogWriteToConsole
%         disp('# Completed...')
%         toc
%         disp( ' ' )
%     end
%     
% end


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

% 
% %% Rhythm Analysis
% 
% 
% if MatlabAPIConfigRequest.IsLogWriteToConsole
%     disp('Rhythm Analysis:')
%     tic
% end
% [BradycardiaRuns, TachycardiaRuns, ActivityBasedTachycardiaRuns] = RhythmAnalysis( ...
%     QRSComplexes, ...
%     HolterRecordInfoRequest, ...
%     AnalysisParametersRequest, ...
%     MatlabAPIConfigRequest );
% if MatlabAPIConfigRequest.IsLogWriteToConsole
%     disp('- General rhythm analysis is completed.')
% end
% 
% if MatlabAPIConfigRequest.IsLogWriteToConsole
%     disp('# Completed...')
%     toc
%     disp(' ')
% end


% %% Tachycardia Type Detection
% 
% 
% if MatlabAPIConfigRequest.IsLogWriteToConsole
%     disp('Tachycardia Type Detection Analysis:')
%     tic
% end
% 
% [ SinusTachyRuns, SupraventricularTachyRuns, VentricularTachyRuns, VentricularFlutterRuns ] = TachycardiaTypeSegmentation( ...
%     QRSComplexes, ...
%     TachycardiaRuns, ...
%     HolterRecordInfoRequest, ...
%     AnalysisParametersRequest ...
%     );
% 
% if MatlabAPIConfigRequest.IsLogWriteToConsole
%     disp('# Completed...')
%     toc
%     disp(' ')
% end


% %% Bradycardia Type Detection
% 
% 
% if MatlabAPIConfigRequest.IsLogWriteToConsole
%     disp('Bradycardia Type Detection Analysis:')
%     tic
% end
% 
% [ BradycardiaRuns, AVBlockDegree1, AVBlockDegree2_Type1, AVBlockDegree2_Type2, AVBlockDegree3 ] = BradycardiaTypeSegmentation( ...
%     QRSComplexes, ...
%     BradycardiaRuns, ....
%     HolterRecordInfoRequest, ...
%     AnalysisParametersRequest ...
%     );
% 
% if MatlabAPIConfigRequest.IsLogWriteToConsole
%     disp('# Completed...')
%     toc
%     disp(' ')
% end


% %% Irregular Rhythm Analysis
% 
% 
% if MatlabAPIConfigRequest.IsLogWriteToConsole
%     disp('Atrial Fibrillation Detection :')
%     tic
% end
% [ AFibRuns, SinusArrhythmiaRuns, SinusTachyRuns, QRSComplexes ] = Detection_IrregularInterval( ...
%     ECGSignals, ...
%     QRSComplexes, ...
%     SinusTachyRuns, ...
%     AnalysisParametersRequest, ...
%     HolterRecordInfoRequest );
% if MatlabAPIConfigRequest.IsLogWriteToConsole
%     toc
%     disp(' ')
% end


% Premature Beats


% if MatlabAPIConfigRequest.IsLogWriteToConsole
%     tic
%     disp('Premature Ventricular Run Detection : ')
% end
% 
% [ QRSComplexes, PVCRuns, VentricularTachyRuns] = ClassPrematureBeats.FindPrematureBeatRuns( ...
%     QRSComplexes, ...
%     VentricularTachyRuns, ...
%     'V', ...
%     HolterRecordInfoRequest );
% 
% if MatlabAPIConfigRequest.IsLogWriteToConsole
%     disp('# Completed...')
%     toc
%     disp(' ')
% end

% if MatlabAPIConfigRequest.IsLogWriteToConsole
%     tic
%     disp('Premature Atrial Run Detection : ')
% end
% % 
% [ QRSComplexes, PACRuns, SupraventricularTachyRuns ] = ClassPrematureBeats.FindPrematureBeatRuns( ...
%     QRSComplexes, ...
%     SupraventricularTachyRuns, ...
%     'A', ...
%     HolterRecordInfoRequest );
% 
% if MatlabAPIConfigRequest.IsLogWriteToConsole
%     disp('# Completed...')
%     toc
%     disp(' ')
% end
[QRSComplexes] = MorphBasedRecognition( QRSComplexes ,  ECGSignals.( MatlabAPIConfigRequest.AnalysisChannel ));
% [QRSComplexes] = PrematureBeatEvaulation2( QRSComplexes );


% Beat Type

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
    QRSComplexes, .... % Total Beats
    NoiseRuns ... % Noise Runs
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

% % - Ventricular Events
% JsonResponsePackets.VentricularEventsResponse = ClassPackageOutput.VentricularEventsPacket( QRSComplexes, PVCRuns );
% 
% % - Supraventricular Events
% JsonResponsePackets.SupraventricularEventsResponse = ClassPackageOutput.SupraventricularEventsPacket( QRSComplexes, PACRuns );
% 
% % - Tachycardia
% JsonResponsePackets.TachycardiaResponse = ClassPackageOutput.TachycardiaPacket( ...
%     SinusTachyRuns, ... % SinusTachyRuns Runs
%     ActivityBasedTachycardiaRuns, ... % Activity BasedHigh Heart Rate Runs
%     VentricularTachyRuns, ... % VentricularTachyRuns Runs
%     SupraventricularTachyRuns, ... % Supraventricular Tachycardia Runs
%     length( QRSComplexes.R ), ... % Total Beats
%     GeneralPeriod ... % Heart rate summary of the all the signal round
%     );
% 
% % - Bradycardia
% JsonResponsePackets.BradycardiaResponse = ClassPackageOutput.BradycardiaPacket( ...
%     BradycardiaRuns, ... % Bradycardia Runs
%     PauseRuns, ... % Pause Runs
%     AVBlockDegree1, ... % av block degree I
%     AVBlockDegree2_Type1, ... % av block degree II type 1
%     AVBlockDegree2_Type2, ... % av block degree II type 2
%     AVBlockDegree3, ... % av block degree III
%     single( [ ] ), ... % activity based
%     length( QRSComplexes.R ), ... % Total Beats
%     round( numel( ECGSignals.( MatlabAPIConfigRequest.AnalysisChannel ) ) / HolterRecordInfoRequest.RecordSamplingFrequency ), ... % Total Duration
%     GeneralPeriod ... % Heart rate summary of the all the signal round
%     );
% 
% % - Atrial Fibrillation
% JsonResponsePackets.AtrialFibrillationResponse = ClassPackageOutput.AtrialFibPacket( ...
%     AFibRuns, ... % AFib Runs
%     length( QRSComplexes.R ) ... % Total Beats
%     );
% 
% % - Sinus Arrhythmia
% JsonResponsePackets.SinusArrhythmiaResponse = ClassPackageOutput.SinusArythmiaPacket( ...
%     SinusArrhythmiaRuns, ... % Sinus Arrhythmia Runs
%     length( QRSComplexes.R ) ... % Total Beats
%     );
% 
% % - Atrial Flutter
% JsonResponsePackets.AtrialFlutterResponse = ClassPackageOutput.AtrialFlutterPacket( [ ] ); % Under development...

% - Ventricular Fibrillation
JsonResponsePackets.VentricularFibrillationResponse = ClassPackageOutput.VentricularFibPacket( ...
    VentricularFibrillationRuns, ... % VFib Runs
    round( numel( ECGSignals.( MatlabAPIConfigRequest.AnalysisChannel ) ) / HolterRecordInfoRequest.RecordSamplingFrequency ) ... % Total Duration
    );

% % - Ventricular Flutter
% JsonResponsePackets.VentricularFlutterResponse = ClassPackageOutput.VentricularFlutterPacket( ...
%     VentricularFlutterRuns, ... % VFlutter Runs
%     length( QRSComplexes.R ) ... % Total Duration
%     );

% - Asystole
JsonResponsePackets.AsystoleResponse = ClassPackageOutput.AsystolePacket( ...
    AsystoleRuns,... % Asystole Runs
    ( length( ECGSignals.( MatlabAPIConfigRequest.AnalysisChannel ) ) / HolterRecordInfoRequest.RecordSamplingFrequency ) ... % Total Beats
    );

% - AlarmButton
JsonResponsePackets.AlarmButtonResponse = ClassPackageOutput.AlarmButtonPacket( AlarmButton, QRSComplexes, HolterRecordInfoRequest );

% - Beat Details
JsonResponsePackets.BeatDetailsResponse = ClassPackageOutput.BeatDetailsPacket( QRSComplexes, HolterRecordInfoRequest.RecordSamplingFrequency );

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
disp( [ 'Analysis is completed: *** cross correlation VA KARISIMI***' ...
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

