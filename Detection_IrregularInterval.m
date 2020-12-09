
% Atrial Fibrillation Detection Algorithm.
%
% function [ AFib ] = Detection_AFib( ecgSignals, qrsComplexes, vEctopics, analysisParameters, recordInfo )
%
% <<< Function Inputs >>>
%   struct ecgSignals
%   struct qrsComplexes
%   struct vEctopics
%   struct analysisParameters
%   struct recordInfo
%
% <<< Function outputs >>>
%   struct AFib

function [ AFibRuns, SinusArrhythmiaRuns, sinTachyRuns, qrsComplexes ] = Detection_IrregularInterval( ...
    ~, ...
    qrsComplexes, ...
    sinTachyRuns, ...
    analysisParameters, ...
    recordInfo )

% Initial Control
if ( length( qrsComplexes.R ) < 5 )
    
    % Output
    AFibRuns = single( [ ] );
    SinusArrhythmiaRuns = single( [ ] );
    
else % ( length( qrsComplexes.R ) < 5 )
    
    % Initialization
    irregularThreshold = single( 0.10 );
    
    % Heart Rate
    heartRate = ClassRhythmAnalysis.CalculateHeartRate( qrsComplexes.R, recordInfo.RecordSamplingFrequency );
    heartRate = [ heartRate( 1 ); heartRate ];
    
    % RR Interval Change Calculation
    [ rrIntervalChange ] = RRIntervalChangeCalculation( qrsComplexes, heartRate, analysisParameters );
        
    % Get Possible AFib Periods
    [ AFibRuns, SinusArrhythmiaRuns, qrsComplexes ] = IrregularIntervalDetection ...
        ( 'ecgSignals', qrsComplexes, heartRate, rrIntervalChange, irregularThreshold, analysisParameters, recordInfo );
    
    % Sin Tachy in AFib
    if ~isempty( AFibRuns )
        % check sin tachy
        if ~isempty( sinTachyRuns )
        % remove sintachy in afib
            for runIndex = length( sinTachyRuns.StartBeat ) : -1 : 1
                runBeatIndexes = sinTachyRuns.StartBeat( double( runIndex ) ) :  sinTachyRuns.EndBeat( double( runIndex ) );
                if any( AFibRuns.BeatFlag( runBeatIndexes ) )
                    % delete
                    % // start
                    sinTachyRuns.StartBeat( runIndex ) = [ ];
                    sinTachyRuns.StartTime( runIndex ) = [ ];
                    % // end
                    sinTachyRuns.EndBeat( runIndex ) = [ ];
                    sinTachyRuns.EndTime( runIndex ) = [ ];
                    % // duration
                    sinTachyRuns.Duration( runIndex ) = [ ];
                    % // bpm
                    sinTachyRuns.AverageHeartRate( runIndex ) = [ ];
                    % // down flag
                    sinTachyRuns.BeatFlag( runBeatIndexes ) = false;
                end
            end
            % last check
            if isempty( sinTachyRuns.StartBeat )
                sinTachyRuns = [ ];
            end
        end
    end
    
end % ( length( qrsComplexes.R ) < 5 )


end % function


%% SubFunction : RR Interval Change Calculation

function [ rrIntervalChange ] = RRIntervalChangeCalculation( qrsComplexes, heartRate, analysisParameters )

% Initialization
numberBeat2Compare = single( 5 );
indexes2CalculateMean = ones( numberBeat2Compare, 1 );

% rr interval
rrInterval = diff( qrsComplexes.R );
rrInterval = [ rrInterval( 1 ); rrInterval ];

% rr interval change
rrIntervalChange = zeros( length( rrInterval ), 1, 'single' );

% Heart rate change
for beatIndex = 2 : length( qrsComplexes.R )
    
    if ... RR INTERVAL CHANGE
            ... Condition 1 : beat heart rate should be greater than the clinical bradycardia threshold
            ( heartRate( beatIndex ) >= analysisParameters.Bradycardia.ClinicThreshold )  && ...
            ... Condition 2 : beat should not be initiated from the ventriculars
            ( qrsComplexes.QRSInterval( beatIndex ) <= single( 0.120 ) ) && ...
            ( ~qrsComplexes.VentricularBeats( beatIndex ) ) && ...
            ... Condition 2 : beat should not have the compensatory pause
            ( ~qrsComplexes.VentricularBeats( beatIndex - 1 ) )
        
        % RR INTERVAL MEAN VALUE
        %_ rr intervals to be included in the mean calculation
        indexes2CalculateMean = circshift(indexes2CalculateMean,-1);
        indexes2CalculateMean( end ) = beatIndex - 1;
        %_ mean value
        rrIntervalMean = mean( rrInterval( indexes2CalculateMean ) );
        
        % RR INTERVAL CHAGE
        rrIntervalChange( beatIndex ) = round( abs( 1 - ( rrInterval( beatIndex ) / rrIntervalMean ) ), 4 );
        
    else
        
        % RR INTERVAL CHAGE
        rrIntervalChange( beatIndex ) = 0;
        
    end
    
end

end


%% SubFunction : Atrial Fibrillation Assesment
% Detection AFib Periods
%
% function [ AFibPeriods ] = UnusualECGPeriodDetection ( ecgSignals, qrsComplexes, heartRate, rrIntervalChange, rrThreshold, analysisParameters, recordInfo )
%
% <<< Function Inputs >>>
%   struct ecgSignals
%   struct qrsComplexes
%   single heartRate
%   single rrIntervalChange
%   single rrThreshold
%   struct analysisParameters
%   struct recordInfo
%
% <<< Function Outputs >>>
%   struct AFibPeriods

function [ AFibPeriods, SinusArrhythmiaPeriods, qrsComplexes ] = IrregularIntervalDetection ( ~, qrsComplexes, heartRate, rrIntervalChange, irregularThreshold, analysisParameters, recordInfo )

% Unusual intervals
[ intervalStart, intervalEnd ] = GetInterval(rrIntervalChange >= irregularThreshold );

% Assesment Parameters
afibInterval = zeros( length( intervalStart ), 1, 'logical' );
sinusArrhythmiaInterval = zeros( length( intervalStart ), 1, 'logical' );

% Interval by interval assesment
for intervalIndex = 1 : length( intervalStart )
    
    % Interval Beat Indexes
    intervalBeatIndexes = ( double( intervalStart( intervalIndex ) ) : double( intervalEnd( intervalIndex ) ) );
    
    % - Heart Rate Change
    intervalHeartRate = heartRate( intervalBeatIndexes );
    intervalHeartRate( intervalHeartRate < ( 60 / ( analysisParameters.Pause.ClinicThreshold / 1000 ) ) ) = [ ];
    % - successive beat ratio
    bpmChangeRatio = sum( abs( 1 - ( intervalHeartRate(1:end-1) ./ intervalHeartRate(2:end) ) ) > 0.10 ) / length( intervalBeatIndexes );
    if length( intervalBeatIndexes ) > 10; bpmChangeCondition = bpmChangeRatio > 0.33; else; bpmChangeCondition = bpmChangeRatio > 0.50; end
    % - std condition
    bpmSTDChangeCondition = std( abs( ( intervalHeartRate( 2:end ) ./ intervalHeartRate ( 1:end-1 ) ) -1 ) );
    bpmRangeChangeCondition = ( max( intervalHeartRate ) - min( intervalHeartRate ) );
   
    % - Ventricular Beat
    ventricularBeatCondition = sum( 2 * qrsComplexes.VentricularBeats( intervalBeatIndexes ) ) / length( intervalHeartRate );
    
    % - QRS Interval
    qrsIntervalCondition = mean( qrsComplexes.QRSInterval( intervalBeatIndexes ) ) < 0.120;
    
    % - P Wave Condition
    segmentPWaveAmplitudes = qrsComplexes.P.Amplitude( intervalBeatIndexes );
    segmentPWaveAmplitudes( qrsComplexes.VentricularBeats( intervalBeatIndexes ) ) = 1;
    pWaveCondition = round( sum( segmentPWaveAmplitudes > 0 ) / length( intervalBeatIndexes  ), 2 );
    
    % - Low heart rate caused by noise etc.
    lowHeartRateThreshold = round( 60 / ( analysisParameters.Asystole.ClinicThreshold / 1000 ) );
    lowHeartRateCondition = ( sum( intervalHeartRate < lowHeartRateThreshold ) / length( intervalBeatIndexes ) ) < 0.05;
                
    % - Assessment
    if ...
            ... RR Interval Change Condition Control
            ( bpmSTDChangeCondition > 0.15 ) && ...
            ... qrs interval condition
            ( qrsIntervalCondition ) && ...
            ... no beat with heart rate lower than asystole limit
            lowHeartRateCondition 
        
        if ... P Wave Condition
                ( ...
                ( ( length( intervalBeatIndexes ) < 60 ) && ( pWaveCondition <= single( 0.33 ) ) ) || ...
                ( ( length( intervalBeatIndexes ) >= 60 ) && ( pWaveCondition <= single( 0.50 ) ) ) ...
                ) ...
                ... BPM Change Condition
                && bpmChangeCondition
            
            %             plot_IrregularInterval
            % Flag
            afibInterval( intervalIndex ) = true;
            % Erase the atrial premature beats
            qrsComplexes.AtrialBeats( intervalBeatIndexes ) = false;
            
        elseif ... If ventricular beat ratio is low
                ( ventricularBeatCondition < 0.20 )
            
            % Flag
            % sinusArrhythmiaInterval( intervalIndex ) = true;
            
        end
        
    elseif ...
            ... Range of the BPM Change
            ( bpmRangeChangeCondition > 10) && ...
            ... If ventricular beat ratio is low
            ( ventricularBeatCondition < 0.20 )
        
        % Flag
        % sinusArrhythmiaInterval( intervalIndex ) = true;
        
    end
    
    %     if ~afibInterval( intervalIndex );
    %         plot_IrregularInterval
    %     end
       
end

% Packet
[AFibPeriods] = PacketIrregularHeartBeatRun...
    ( qrsComplexes, ...
    heartRate, ...
    recordInfo.RecordStartTime,...
    recordInfo.RecordSamplingFrequency, ...
    intervalStart( afibInterval == true ), ...
    intervalEnd( afibInterval == true ) );

% Packet
[SinusArrhythmiaPeriods] = PacketIrregularHeartBeatRun...
    ( qrsComplexes, ...
    heartRate, ...
    recordInfo.RecordStartTime,...
    recordInfo.RecordSamplingFrequency, ...
    intervalStart( sinusArrhythmiaInterval == true ), ...
    intervalEnd( sinusArrhythmiaInterval == true ) );

end


%% Packet Run : Irregular Heart Beat

% Packeting the irregular run info.
%
% function [run] = PacketIrregularHeartBeatRun( qrsComplexes, heartRate, recordStartTime, samplingFreq, runStartBeat, runEndBeat, runDuration)
%
% <<< Function Inputs >>>
%   struct qrsComplexes
%   single heartRate
%   string recordStartTime
%   single samplingFreq
%   single runStartBeat
%   single runEndBeat
%   single runDuration
%
% <<< Function Outputs >>>
%   struct run

function [run] = PacketIrregularHeartBeatRun( qrsComplexes, heartRate, recordStartTime, samplingFreq, runStartBeat, runEndBeat )

% Merge consecutive intervals that have 5 beats and less interval
if length( runStartBeat ) > 1
    % - temp blocks
    tempRunEnd = runEndBeat( 1 : end - 1 );
    tempRunStart = runStartBeat( 2 : end );
    % - intervals
    blockSegment = tempRunStart - tempRunEnd;
    segments2Delete = find( blockSegment <= 10 );
    % - merge
    runStartBeat( segments2Delete + 1 ) = [ ];
    runEndBeat( segments2Delete ) = [ ];
end

% heart rate time
% - start time
initialRunStartBeat = runStartBeat;
runStartBeat = double( runStartBeat - 1 );
runStartBeat( runStartBeat < 1 ) = 1;
beatStartTime = ( qrsComplexes.EndPoint(1:end) / samplingFreq );
% - end time
qrsComplexes.T.EndPoint( qrsComplexes.T.EndPoint == 1 ) = qrsComplexes.EndPoint( qrsComplexes.T.EndPoint == 1 );
beatEndTime = ( qrsComplexes.T.EndPoint(1:end) / samplingFreq );

% Run Characteristics
if ~isempty(runStartBeat)
    run.StartTime = ClassDatetimeCalculation.Summation( recordStartTime, beatStartTime(runStartBeat) );
    run.StartBeat = initialRunStartBeat;
    run.EndTime = ClassDatetimeCalculation.Summation( recordStartTime, beatEndTime(runEndBeat) );
    run.EndBeat = runEndBeat;
    run.Duration = ( runEndBeat - runStartBeat + 1 );
    run.AverageHeartRate = PeriodAverageHeartRate( heartRate, runStartBeat, runEndBeat );
else
    run = single( [ ] );
    
end

% Check if afib is detected
if ~isempty( run )
    % Flags
    run.BeatFlag = zeros( length( qrsComplexes.R ), 1, 'logical' );
    % Rise Flag
    for runIndex = 1 : length( run.StartBeat )
        % beat indexes
        beatIndex = double( run.StartBeat( runIndex ) ) : double( run.EndBeat( runIndex ) );
        % flag
        run.BeatFlag( beatIndex ) = true;
    end
end

end


%% Average Heart Rate Calculation

% Calculation of the averaged heart rate in a run.
%
% function [runHeartRate] = PeriodAverageHeartRate( heartRate, runStartTime, runEndTime )
%
% <<< Function Inputs >>>
%   single heartRate
%   single runStartTime
%   single runEndTime
%
% <<< Function Outputs >>>
%   single runHeartRate

function [runHeartRate] = PeriodAverageHeartRate( heartRate, runStartTime, runEndTime )

% Initialization
runHeartRate = single( zeros( length( runStartTime ), 1 ) );
% Calculation
for runIndex = single( 1 : numel(runStartTime) )
    runHeartRate(runIndex) = round( mean( heartRate( double( runStartTime(runIndex) ) : double( runEndTime( runIndex ) ) ) ) );
end

end


%% SubFunction : Get intervals

function [ intervalStart, intervalEnd ] = GetInterval( BinarySignal )

% Block segmentation
blockEdges = single( ( abs( diff( [ BinarySignal; 0 ] ) ) > 0 ) > 0 );
blockEdges = single( find(blockEdges == 1) );
intervalStart = single( blockEdges( 1:2:length( blockEdges ) ) ) + 1;
intervalEnd = single( blockEdges( 2:2:length( blockEdges ) ) );

% Check limits
if length( intervalStart ) ~= length( intervalEnd )
    intervalStart( end ) = [ ];
end

% Merge consecutive intervals that have 2 beats and less interval
if length( intervalStart ) > 1
    
    % - temp blocks
    tempintervalEnd = intervalEnd( 1 : end - 1 );
    tempintervalStart = intervalStart( 2 : end );
    % - intervals
    blockSegment = tempintervalStart - tempintervalEnd;
    segments2Delete = find( blockSegment <= 10 );
    % - merge
    intervalStart( segments2Delete + 1 ) = [ ];
    intervalEnd( segments2Delete ) = [ ];
    
end

% Duration based elimination
intervalDuration = intervalEnd - intervalStart + 1;
intervalStart( intervalDuration <= 5 ) = [ ];
intervalEnd( intervalDuration <= 5 ) = [ ];

end