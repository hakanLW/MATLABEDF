
% Unusual Signal Detection
%
% [ VFibRun, VEcpRun, NoiseRun ]  = Detection_VFib( ECGSignals, RecordInfo, AnalysisChannel )
%
% <<< Function Inputs >>>
%   struct ECGSignals
%   struct RecordInfo
%   string AnalysisChannel
% 
% <<< Function outputs >>>
%   struct VFibRun
%   struct VEcpRun
%   struct NoiseRun
%

function [ QRSComplexes, VFibRun, AnalysisParameters ]  = ...
    Detection_VFib( ECGSignals, QRSComplexes, NoiseSample, RecordInfo, AnalysisParameters, AnalysisChannel )

%  SIGNAL RESHAPE: Removing the reminder of one second of sliding window
[ ECGSignals, RawDataLength ] = ClassUnusualSignalDetection.SignalReshape...
    ( ECGSignals, ... % ecg signals
    AnalysisChannel, ... % analysis channel
    single( single( 1 ) * RecordInfo.RecordSamplingFrequency ), ... % sliding window duration : 1 sec.
    RecordInfo ); % record info

% SEGMENTATION: Generating sliding windows
% ( sliding window duration: 1 sec )
% ( segment window duration: 3 sec )
SlidingWindows = ClassUnusualSignalDetection.GetSlidingWindows...
    ( ECGSignals.( AnalysisChannel ), ... % ecg signal to analyse
    single( single( 1 ) * RecordInfo.RecordSamplingFrequency ), ... % sliding window duration : 1 sec.
    single( single( 3 ) * RecordInfo.RecordSamplingFrequency ), ... % segment duration : 3 sec.
    RecordInfo ); % record info

% SEGMENT ASSESMENT: Determination of the unusual/usual signal periods
% unusual
[ UnusualECGPeriodStart, UnusualECGPeriodEnd ] = ClassUnusualSignalDetection.FlagSignal...
    ( SlidingWindows, ... % sliding windows
    single( 3 ), ... % segment duration : 3 sec.
    RecordInfo ...
    );

% Amplitude Distribution
if ~isempty( QRSComplexes ) && ~isempty( QRSComplexes.R )
    qrsAmplitudeThreshold = fitdist( double( QRSComplexes.QRSAmplitude ), 'normal' );
else
    qrsAmplitudeThreshold.mu = inf;
end
% UNUSUAL SIGNAL ASSESMENT
% Preallocation #Ventricular Fibrillation
VFibInterval =  zeros( RawDataLength, 1, 'logical' );

% - Unusual Signal Assesment
if ~isempty( UnusualECGPeriodStart )
    
    % Active Channel Change Points
    ActiveChannelChangePoints = zeros( RecordInfo.CableConfigurationCount, 1, 'single' );
    for i = 1 : RecordInfo.CableConfigurationCount
        ActiveChannelChangePoints( i, 1 ) = RecordInfo.CableConfigurations( i ).StartPoint;
        if i == RecordInfo.CableConfigurationCount
            ActiveChannelChangePoints( i, 2 ) = length( ECGSignals.( AnalysisChannel ) );
        else
            ActiveChannelChangePoints( i, 2 ) = RecordInfo.CableConfigurations( i + 1 ).StartPoint - 1;
        end
    end; clear i;
    
    % Period by Period Assesment
    for periodIndex = 1 :  length( UnusualECGPeriodStart )
        
        % Unusual Period Points
        unusualPeriodStartPoint = double( UnusualECGPeriodStart( periodIndex ) ) * double( RecordInfo.RecordSamplingFrequency ) + double( 1 );
        unusualPeriodEndPoint = double( UnusualECGPeriodEnd( periodIndex ) ) * double( RecordInfo.RecordSamplingFrequency );
        unusualPeriodPoints = transpose( double( unusualPeriodStartPoint ) : double( unusualPeriodEndPoint ) );
        % Signal Range
        signalRange = ECGSignals.( AnalysisChannel )( double( unusualPeriodStartPoint ) : double( unusualPeriodEndPoint ) );
        if ~isempty( signalRange ); signalRange = max( signalRange ) - min( signalRange ); else; signalRange = 0; end
                        
        % Initial signal noise control
        if ...  
                .... Asistole control
                logical( signalRange > 0.20 ) && ...
                ... Noise control
                ~logical( sum( NoiseSample( unusualPeriodPoints ) ) ) && ...
                ... Peak control
                logical( signalRange < 2 * qrsAmplitudeThreshold.mu )
            
            % SIGNAL RECORDING ACTICE CHANNEL LIST CONTROL
            [ ~, ActiveChannelChangeIndex ] = intersect( ActiveChannelChangePoints( :, 1 ), unusualPeriodPoints );
            if ActiveChannelChangeIndex
                % unusual points and channel change has an intersected point
                ActiveChannelChangeIndex = sort( unique( [ ActiveChannelChangeIndex ( ActiveChannelChangeIndex - 1 ) ] ) );
                ActiveChannelChangeIndex( ActiveChannelChangeIndex < 1 ) = [ ];
                % find the minimum
                ActiveChannelCount = zeros( length( ActiveChannelChangeIndex ), 1, 'uint16' );
                for ChannelChangeIndex = 1 : length( ActiveChannelChangeIndex )
                    ActiveChannelCount( ChannelChangeIndex ) = length( RecordInfo.CableConfigurations( ActiveChannelChangeIndex( ChannelChangeIndex ) ).ActiveChannelList );
                end
                [ ~, ActiveChannelChangeIndex ] = min( ActiveChannelCount );
                % Active Channels List
                if isempty( ActiveChannelChangeIndex )
                    ActiveChannelList = [ ];
                else
                    ActiveChannelList = RecordInfo.CableConfigurations( ActiveChannelChangeIndex ).ActiveChannelList;
                end
            else
                % Unusual points and channel change has no intersected points
                ActiveChannelChangeIndex = find( ( ( ActiveChannelChangePoints( :, 1 )  <= unusualPeriodStartPoint ) & (  ActiveChannelChangePoints( :, 2 ) >= unusualPeriodEndPoint ) ), true );
                % Active Channels List
                if isempty( ActiveChannelChangeIndex )
                    ActiveChannelList = [ ];
                else
                    ActiveChannelList = RecordInfo.CableConfigurations( ActiveChannelChangeIndex ).ActiveChannelList;
                end
            end
            
            % SIGNAL QUALITY CHANNEL LIST CONTROL
            if isempty( ActiveChannelList )
                ActiveChannelList = [ ];
            else
                % Channel Selection
                for channelIndex = numel( ActiveChannelList ) : -1 : 1
                    % Check Channel
                    if strcmp( ActiveChannelList( channelIndex ), string( AnalysisChannel ) )
                        isActive = false;
                    else
                        isActive = ClassChangeChannel.ControlChannel4Activity...
                            ( ECGSignals.( ActiveChannelList{ channelIndex } )( unusualPeriodPoints ), RecordInfo.RecordSamplingFrequency );
                    end
                    if ( ~isActive ); ActiveChannelList( channelIndex ) = [ ]; end
                end
            end
            
            % CROSS CORRELATION
            if isempty( ActiveChannelList )
                CrossCorrelation = 0;
            else
                CrossCorrelation = zeros( numel( ActiveChannelList ), 1, 'double' );
                for channelIndex = 1 : numel( ActiveChannelList )
                    CrossCorrelation( channelIndex ) = CrossCorr( ...
                        ECGSignals.( AnalysisChannel )( double( unusualPeriodPoints ) ), ...
                        ECGSignals.( ActiveChannelList{ channelIndex } )( double( unusualPeriodPoints ) ) );
                end
            end
            
            % UNUSUAL PERIOD BEATS
            [ ~, unusualPeriodBeatIndexes ] = intersect( QRSComplexes.R, unusualPeriodPoints );
            unusualPeriodBeatIndexes( unusualPeriodBeatIndexes > ( length( QRSComplexes.R ) - 1 ) ) = [];
            unusualPeriodBeat_R = QRSComplexes.R( unusualPeriodBeatIndexes );
            unusualPeriodBeat_S = QRSComplexes.S( unusualPeriodBeatIndexes );
            % check period points
            if min( unusualPeriodBeat_R ) < unusualPeriodStartPoint; ...
                    unusualPeriodStartPoint = min( unusualPeriodBeat_R ) - round( double( RecordInfo.RecordSamplingFrequency ) * 0.5 ); end
            if max( unusualPeriodBeat_S ) > ...
                    unusualPeriodEndPoint; unusualPeriodEndPoint = max( unusualPeriodBeat_S ) + round( double( RecordInfo.RecordSamplingFrequency ) * 0.5 ); end
            unusualPeriodPoints = transpose( double( unusualPeriodStartPoint ) : double( unusualPeriodEndPoint ) );
            % updated unusual period beats
            unusualPeriodBeat_R = ...
                QRSComplexes.R( unusualPeriodBeatIndexes ) - unusualPeriodStartPoint + 1;
            unusualPeriodBeat_S = ....
                QRSComplexes.S( unusualPeriodBeatIndexes ) - unusualPeriodStartPoint + 1;
            unusualPeriodBeatsType = ...
                QRSComplexes.Type( unusualPeriodBeatIndexes );
            unusualPeriodBeatPeaks = ...
                sort( [ unusualPeriodBeat_R( unusualPeriodBeatsType > 0 ); unusualPeriodBeat_S( unusualPeriodBeatsType < 0 ) ] );
            % beat peaks
            unusualPeriodBeatPeaksAngle = ClassUnusualSignalDetection.PeakAngleParameters( ...
                ECGSignals.( AnalysisChannel )( double( unusualPeriodStartPoint ) : double( unusualPeriodEndPoint ) ), unusualPeriodBeatPeaks );
            
            % ASSESSMENT : VFib
            if ...          Ventricular Fibrillation Conditions.
                    ... initial condition
                    ( mean( unusualPeriodBeatPeaksAngle ) < 80 ) && ...
                    ( ...
                    ... condition 1
                    all( CrossCorrelation > 92.5 ) || ...
                    ... condition 2
                    ( mean( CrossCorrelation ) > 92.5 ) ...
                    )
                
                % Check signal regularity
                isSignalVFibSignal = ECGSignals.( AnalysisChannel )( double( unusualPeriodPoints ) );
                isSignalVFibSignal = isSignalVFibSignal / max( abs( isSignalVFibSignal ) );
                isSignalRangeRegular = sum( abs( isSignalVFibSignal ) > 0.25 ) / length( isSignalVFibSignal ) > 0.25;
                % Check peak regular
                [ ~, isSignalVFibPeakRegular ] = ...
                    findpeaks( isSignalVFibSignal, 'MinPeakHeight', 0.50, 'MinPeakDistance', 0.200 * RecordInfo.RecordSamplingFrequency );
                isSignalVFibPeakRegular = std( diff( isSignalVFibPeakRegular ) ) > ( 0.500 *  RecordInfo.RecordSamplingFrequency );
                % Assesment based on signal regularity
                if isSignalRangeRegular && isSignalVFibPeakRegular
                    VFibInterval( unusualPeriodPoints ) = true;
                end
                                
            end
            
        end
        
    end
    
end % for channelIndex = 1 : length( ActiveChannelList )


%% PACKET

% - ventricular fibrillation
VFibRun = ClassUnusualSignalDetection.PacketRun( VFibInterval, RawDataLength, RecordInfo, true, single( 1 ) );


%% CLEAR QRS COMPLEXES
beatlessSignal = zeros( RawDataLength, 1, 'logical' );
if ~isempty( VFibRun )
    beatlessSignal = beatlessSignal | VFibRun.Points;
end
if sum( beatlessSignal )
    [ ~, beats2Remove ] = intersect( QRSComplexes.R, find( beatlessSignal == true ) );
    QRSComplexes = ClassUnusualSignalDetection.ClearQRS( QRSComplexes, beats2Remove );
end
% Check remaining beats
if length( QRSComplexes.R ) < 6
    QRSComplexes = ClassUnusualSignalDetection.ClearQRS( QRSComplexes, transpose( 1:length( QRSComplexes.R ) ) );
end

%% LOG THE SIGNALLESS INTERVALS

% Given signalless intervals
intervalWithoutSignal = AnalysisParameters.IntervalWithoutSignal;

% Clear VFib interval
if ~isempty( VFibRun )
    % Number of initial interval without signal
    numberIntervalWithoutSignal = int32( numel( intervalWithoutSignal ) );
    % Number of vFib
    numberVFibRun = int32( numel( VFibRun.StartTime(: , 1) ) );
    % Merge with interval without without signal
    for runIndex = 1 : numberVFibRun
        % - starttime
        intervalWithoutSignal( numberIntervalWithoutSignal + runIndex ).StartTime = char( VFibRun.StartTime( runIndex,: ) );
        % - endtime
        intervalWithoutSignal( numberIntervalWithoutSignal + runIndex ).EndTime = char( VFibRun.EndTime( runIndex,: ) );
        % - type
        intervalWithoutSignal( numberIntervalWithoutSignal + runIndex ).Type = deal( 'VFib' );
    end
end

% Give updated interval without signal
AnalysisParameters.IntervalWithoutSignal = intervalWithoutSignal;

end


%% SubFunction: CROSS CORRELATION

function [ corr ] = CrossCorr( signal1, signal2 )

Ex   = sum(signal1);
Ey   = sum(signal2);
Exy = sum(signal1.*signal2);
Exx = sum(signal1.*signal1);
Eyy = sum(signal2.*signal2);
n = numel(signal1);
corr = (n*Exy - Ex*Ey) / sqrt((n*Exx -Ex*Ex)*(n*Eyy -Ey*Ey));
corr = round(corr, 4)*100;

end



