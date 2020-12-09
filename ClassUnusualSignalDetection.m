classdef ClassUnusualSignalDetection
    
    % "ClassBeatDetection.m" class consists functions used during VFib,
    % Noise and VEvent detection.
    %
    % SignalReshape
    % GetSlidingWindows
    % FlagSignal
    % PeakAngleParameters
    % CalculateBlockAngle
    % ClearQRS
    % PacketRun
    % GetNoiseRun
    %
    
    %% PROPERTIES
    
    properties
        
        %
        
    end
    
    
    %% STATIC METHODS
    
    
    methods (Static )
        
        
        %% Signal Reshape
        
        function [ ecgSignals, rawDataLength ] = SignalReshape( ecgSignals, analysisChannel, slidingWindowDuration, recordInfo )
            
            % Signal preparation for the segmentation process.
            % The signal is reshaped to prevent any increment points.
            %
            % [ ecgSignals, channelList, rawDataLength ] = SignalReshape( ecgSignals, analysisChannel, slidingWindowDuration, recordInfo )
            %
            % <<< Function Inputs >>>
            %   struct ecgSignals: ECG records.
            %   string analysisChannel: The ECG channel that selected for the unusual signal period detection.
            %   single slidingWindowDuration: Duration of sliding (sample).
            %   struct recordInfo: ECG recording informations.
            %
            % <<< Function Outputs >>>
            %   struct ecgSignals: Resaheped ECG records.
            %   single rawDataLength: The original data length of each ECG signal channels.
            %
            
            
            % RAW DATA LENGTH
            rawDataLength = length( ecgSignals.( analysisChannel ) );
            
            
            % REMINDER DATA
            reminderOfDivision = double( rem( length( ecgSignals.( analysisChannel ) ), slidingWindowDuration ) );
            
            
            % MAKE THE ALL ECG SIGNALS IN THE SAME LENGTH
            for channelIndex = 1 : numel( recordInfo.ActiveChannels )
                startPoint = double( rawDataLength - reminderOfDivision + 1 );
                endPoint = double( rawDataLength );
                % Reshape each channel
                ecgSignals.( recordInfo.ActiveChannels{ channelIndex } )( startPoint : endPoint ) = [ ];
            end
            
        end
        
        
        %% Sliding Window
        
        function [ slidingWindows ] = GetSlidingWindows( signal, slidingWindowLength, segmentLength, recordInfo )
            
            % Segmentation of the signal to sliding windows whose durations
            % are defined with: segment length. Duration of the sliding is
            % defined with: slidingWindowLength.
            %
            % [ slidingWindows ] = GetSlidingWindows( signal, slidingWindowLength, segmentLength, samplingFreq )
            %
            % <<< Function Inputs >>>
            %   single[ n, 1 ] signal: the signal of the analysis channel that it is going to be segmented.
            %   single slidingWindowLength: duration of sliding (sample).
            %   single segmentLength: duration of a segmented signal (sample).
            %   struct recordInfo: ECG recording informations.
            %
            % << Function Outputs >>>
            %  slidingWindows: Segmented ECG signal of the selected channel.
            
            
            % INITIALIZATION
            % - number of segmented windows
            numberOfWindows = fix( length( signal ) / recordInfo.RecordSamplingFrequency ) - fix( segmentLength / recordInfo.RecordSamplingFrequency );
            % - number of sliding window in a segmented window
            numberOfSlidingWindows = ( segmentLength / recordInfo.RecordSamplingFrequency );
            % - preallocation of the sliding windows
            slidingWindows = zeros( segmentLength, numberOfWindows, 'single' );
            
            % GET DATA
            for segmentIndex = 1 : numberOfWindows + 1
                % - start
                signalStartPoint = double( segmentIndex - 1 ) * double( slidingWindowLength ) + ( 1 );
                % - end
                signalEndPoint = double( segmentIndex - 1 + numberOfSlidingWindows ) * double( slidingWindowLength );
                % - temp signal
                tempSignal = signal( signalStartPoint : signalEndPoint );
                % normalization
                slidingWindows( :, segmentIndex ) = 100 * tempSignal / max( abs( tempSignal ) );
                
            end
            
        end
        
        
        %% Unusual Signal Flag
        
        function [ periodStartPoint, periodEndPoint ] = FlagSignal( slidingWindows, segmentDuration, recordInfo )
            
            % Based on given SignalThreshold, unusual behaviour periods of the ECG
            % signal of the selected channel are determined.
            %
            % [ flags ] = FlagUnusualSignalPeriod( slidingWindows, segmentDuration )
            %
            % <<< Function Inputs >>>
            %   single[ 'signalDuration', 'segmentLength' ] slidingWindows: Segmented ECG signal of the selected channel.
            %   single segmentDuration: Segmented signal duration (sec).
            %
            % <<< Function Outputs >>>
            %   logical[ n, 1 ] flags: Flags that defines unusual signal behavior.
            
            % AFTER SIGNAL THRESHOLD IS APPLIED TO SLIDING WINDOW
            slidingWindows = ( abs( slidingWindows ) >= 25 );
            
            % PREALLOCATION OF THE AMPLITUDE RATIO
            amplitudeRatio = zeros( 1, length( slidingWindows( 1, : ) ), 'single' );
            
            % ASSESMENT
            for segmentIndex = 1 : length( slidingWindows( 1, : ) )
                amplitudeRatio( 1, segmentIndex ) = 100 * ( sum( slidingWindows( :, segmentIndex ) ) / ( segmentDuration * recordInfo.RecordSamplingFrequency ) );
            end
            
            % Flag Unusual Periods
            flags = transpose( amplitudeRatio ) > 40;
            
            % Block Segmentation
            [ periodStartPoint, periodEndPoint ] = BlockSegmentation( flags );
            
            % Block Merge
            [ periodStartPoint, periodEndPoint ] = MergeBlocks( periodStartPoint, periodEndPoint, 10 );
            
            % PARTIAL SEGMENTATION
            if ~isempty( periodStartPoint )
                
                % - max segment duration
                segmentDuration = 5;
                % - new blocks
                newPeriodStartPoint = zeros( length( periodStartPoint ) * 100, 1, 'single' );
                newPeriodEndPoint = zeros( length( periodEndPoint ) * 100, 1, 'single' );
                % - number of new blocks
                numbPeriods = single( 0 );
                % - block durations
                periodDuration = periodEndPoint - periodStartPoint;
                
                % check for long block
                for periodIndex = 1:length( periodStartPoint )
                    
                    if periodDuration( periodIndex ) > segmentDuration
                        % number of segment
                        numbSegment = round( periodDuration( periodIndex ) / segmentDuration );
                        % main segmentation
                        for segmentIndex = 1:numbSegment
                            startPoint = periodStartPoint( periodIndex ) + ( segmentIndex - 1 ) * segmentDuration;
                            endPoint = startPoint + segmentDuration;
                            if endPoint > periodEndPoint( periodIndex )
                                newPeriodEndPoint( numbPeriods ) = periodEndPoint( periodIndex );
                            else
                                % increase number of new blocks
                                numbPeriods = numbPeriods + 1;
                                % save
                                newPeriodStartPoint( numbPeriods ) = startPoint;
                                newPeriodEndPoint( numbPeriods ) = endPoint;
                            end
                        end
                    else
                        % no segmentation
                        numbPeriods = numbPeriods + 1;
                        newPeriodStartPoint( numbPeriods ) = periodStartPoint( periodIndex );
                        newPeriodEndPoint( numbPeriods ) = periodEndPoint( periodIndex );
                    end
                    
                end
                
                % end
                periodStartPoint = newPeriodStartPoint( 1 : numbPeriods );
                periodEndPoint = newPeriodEndPoint( 1 : numbPeriods );
                
            end
            
        end
        
        
        %% Peak Assesment
        
        function [ peakAngles ] = PeakAngleParameters( signal, peakPoints )
            
            % Calculation of the peak angles and their characteristic determinations.
            %
            % [ peakPoints, highAngleRatio, lowAngleRatio ] = PeakAngleParameters( signal, peakPoints, lowAngleValue, highAngleValue)
            %
            % <<< Function Inputs >>>
            %   single[ n, 1 ] signal: the signal of the analysis channel that it is going to be analyzed.
            %   single[ n, 1 ] peakPoints: peak points -possible beats- in the given signal
            %   single lowAngleValue: threshold value for the calculation of the lowAngleRatio
            %   single highAngleValue: threshold value for the calculation of the highAngleRatio
            %
            % <<< Function Outputs >>>
            %   single peakPoints: peak points -possible beats- in the given signal
            %   single highAngleRatio: Ratio of the peaks with high value angle.
            %   single lowAngleRatio: Ratio of the peaks with low value angle.
            %
            
            if ~isempty( peakPoints )
                % get peak angles
                peakAngles = CalculatePeakAngle( signal, peakPoints );
            else
                peakAngles  = [];
            end
            
        end
        
        
        %% Calculate Block Angle
        
        function angle = CalculateBlockAngle( signal, blockStart, blockEnd )
            
            % To calculate the angle between the begining and end of the wave in the block.
            %
            % waveAngle = CalculateBlockAngle( blockStart, blockEnd, signal )
            %
            % <<< Function Inputs >>>
            %   single[ n, 1 ] signal: the signal of the analysis channel that it is going to be analyzed.
            %   single[n,1] blockStart: wave start point.
            %   single[n,1] blockEnd: wave end point
            %
            % <<< Function output >>>
            %   single[n,1] waveAngle: wave angle.
            
            
            % INITIALIZATION
            angle = ones( length( blockStart ), 1, 'single' );
            
            
            % ANGLE CALCULATION
            if ~isempty( blockStart )
                
                waveDuration = blockEnd - blockStart;
                
                for blockIndex = single( 1 : length( blockStart ) )
                    
                    waveEdgeAmplitude = signal( blockEnd( blockIndex) ) - signal( blockStart( blockIndex ) );
                    angle( blockIndex ) = ClassSlope.CalculateAngle( waveEdgeAmplitude, waveDuration( blockIndex ) );
                    
                end
                
            else
                
                angle = single( [ ] );
                
            end
            
        end
        
        
        %% SubFunction : Clear QRS Complexes
        
        function QRSComplexes = ClearQRS( QRSComplexes, beat2Clear )
            
            % check left number of qrs
            leftQRSNumber = length( QRSComplexes.R ) - length( beat2Clear );
            if leftQRSNumber < 5
                beat2Clear = transpose( 1:length( QRSComplexes.R ) );
            end
            
            % add next beat
            beat2Clear = [ ( min(beat2Clear) - 1 ); beat2Clear ];
            beat2Clear( beat2Clear < 1 ) = [ ];
            beat2Clear = [ beat2Clear; ( max(beat2Clear) + 1 ) ];
            beat2Clear( beat2Clear > length( QRSComplexes.R ) ) = [ ];
            
            % clear qrs
            % - qrs fields
            qrsFieldNames = fieldnames( QRSComplexes );
            % - t wave fields
            if any( strcmp( qrsFieldNames, 'T' ) )
                % get fields related to T
                tFieldNames = fieldnames( QRSComplexes.T );
                % clear
                for fieldIndex = 1 : length( tFieldNames )
                    QRSComplexes.T.( tFieldNames{ fieldIndex } )( beat2Clear ) = [ ];
                end
                % clear field
                qrsFieldNames( strcmp( qrsFieldNames, 'T' ) ) = [  ];
            end
            % - p wave fields
            if any( strcmp( qrsFieldNames, 'P' ) )
                % get fields related to P
                pFieldNames = fieldnames( QRSComplexes.P );
                % clear
                for fieldIndex = 1 : length( pFieldNames )
                    QRSComplexes.P.( pFieldNames{ fieldIndex } )( beat2Clear ) = [ ];
                end
                % clear field
                qrsFieldNames( strcmp( qrsFieldNames, 'P' ) ) = [  ];
            end
            % qrs fields
            for fieldIndex = 1 : length( qrsFieldNames )
                QRSComplexes.( qrsFieldNames{ fieldIndex } )( beat2Clear ) = [ ];
            end
            
        end
        
        
        %% Packet Run
        
        function [ run ] = PacketRun( runPoints, rawDataLength, recordInfo, giveBuffer, mergeLength )
            
            % Packet runs.
            %
            % [ run ] = PacketRun( runPoints, rawDataLength, maxInterval, recordInfo )
            %
            % <<< Function Inputs >>>
            %   single runPoints: run points
            %   single rawDataLength: Length of the original signal.
            %   struct recordInfo: ECG recording informations.
            %
            % <<< Function Outputs >>>
            %   struct run: Noise struct that consists its parameters.
            %
            
            % NOISE START/END POINTS
            [ runStart, runEnd ] = BlockSegmentation( runPoints );
            
            % MERGE RUN
            [ runStart, runEnd ] = MergeBlocks( runStart, runEnd, mergeLength * recordInfo.RecordSamplingFrequency );
            if giveBuffer
                if ~isempty( runStart )
                    runStart = double( runStart ) - double( 1 * recordInfo.RecordSamplingFrequency ); runStart( runStart < 1 ) = 1;
                    runEnd = double( runEnd ) + double( 1 * recordInfo.RecordSamplingFrequency ); runEnd( runEnd > rawDataLength ) = rawDataLength;
                end
            end
            
            % FLAGS
            for runIndex = 1 : length( runStart )
                % start/end point
                startPoint = double( runStart( runIndex ) ) + double( 1 );
                endPoint = double( runEnd( runIndex ) );
                points = startPoint : endPoint;
                % rise flag
                runPoints( points ) = true;
            end
            
            % PACKET
            if ~isempty( runStart )
                % - start
                run.Start = runStart;
                run.StartTime = ...
                    ClassDatetimeCalculation.Summation( recordInfo.RecordStartTime, ( run.Start / recordInfo.RecordSamplingFrequency ) );
                % - end
                run.End = runEnd;
                run.EndTime = ...
                    ClassDatetimeCalculation.Summation( recordInfo.RecordStartTime, ( run.End / recordInfo.RecordSamplingFrequency ) );
                % - duration - ms
                run.Duration = fix( 1000 * ( ( run.End - run.Start ) / recordInfo.RecordSamplingFrequency ) ) ;
                % - heart rate
                run.AverageHeartRate = zeros( length( run.Start ), 1, 'single' );
                % - points
                run.Points = runPoints;
            else
                run= [ ];
            end
            
            
        end
        
        
        %% Get Noise Run
        
        function [ qrsComplexes, noiseRuns, asystoleRuns, pauseRuns, analysisParameters ] = GetNoiseRun( ...
                qrsComplexes, asystoleRuns, asysMissingIntervals, pauseRuns, pauseMissingIntervals, noisePoints, analysisParameters, recordInfo )
            
            % NOISE RUN
            % - check for the missing intervals
            if ~isempty( asysMissingIntervals )
                % - add each interval into the noise run
                for intervalIndex = 1 : length( asysMissingIntervals.StartPoint )
                    % - points
                    intervalPoints = double( asysMissingIntervals.StartPoint( intervalIndex ) ) : double( asysMissingIntervals.EndPoint( intervalIndex ) );
                    % - flag
                    noisePoints( intervalPoints ) = true;
                end
            end
            % - check for the missing intervals
            if ~isempty( pauseMissingIntervals )
                % - add each interval into the noise run
                for intervalIndex = 1 : length( pauseMissingIntervals.StartPoint )
                    % - points
                    intervalPoints = double( pauseMissingIntervals.StartPoint( intervalIndex ) ) : double( pauseMissingIntervals.EndPoint( intervalIndex ) );
                    % - flag
                    noisePoints( intervalPoints ) = true;
                end
            end
            
            % PACKET NOISE RUNS
            [ noiseRuns ] = ClassUnusualSignalDetection.PacketRun( noisePoints, length( noisePoints ), recordInfo, true, single( 10 ) );
            
            % CHECK Asystole and Pause Regions
            if ~isempty( noiseRuns )
                % - Asystole
                if ~isempty( asystoleRuns )
                    for asystoleRunIndex = length( asystoleRuns.StartTime ) : - 1 : 1
                        startPoint = seconds( asystoleRuns.StartTime( asystoleRunIndex ) - recordInfo.RecordStartTime ) * recordInfo.RecordSamplingFrequency;
                        endPoint = seconds( asystoleRuns.EndTime( asystoleRunIndex ) - recordInfo.RecordStartTime ) * recordInfo.RecordSamplingFrequency;
                        if any( noiseRuns.Points( startPoint : endPoint ) )
                            asystoleRuns.StartTime( asystoleRunIndex ) = [];
                            asystoleRuns.EndTime( asystoleRunIndex ) = [];
                            asystoleRuns.Duration( asystoleRunIndex ) = [];
                            asystoleRuns.AverageHeartRate( asystoleRunIndex ) = [];
                        end
                    end
                end
                if ~isempty( asystoleRuns )
                    if isempty( asystoleRuns.StartTime )
                        asystoleRuns = [];
                    end
                end
                % - Pause
                if ~isempty( pauseRuns )
                    for pauseRunIndex = length( pauseRuns.StartTime ) : - 1 : 1
                        startPoint = seconds( pauseRuns.StartTime( pauseRunIndex ) - recordInfo.RecordStartTime ) * recordInfo.RecordSamplingFrequency;
                        endPoint = seconds( pauseRuns.EndTime( pauseRunIndex ) - recordInfo.RecordStartTime ) * recordInfo.RecordSamplingFrequency;
                        if any( noiseRuns.Points( startPoint : endPoint ) )
                            pauseRuns.StartTime( pauseRunIndex ) = [];
                            pauseRuns.EndTime( pauseRunIndex ) = [];
                            pauseRuns.Duration( pauseRunIndex ) = [];
                            pauseRuns.AverageHeartRate( pauseRunIndex ) = [];
                        end
                    end
                end
                if ~isempty( pauseRuns )
                    if isempty( pauseRuns.StartTime )
                        pauseRuns = [];
                    end
                end
            end
            
            % CLEAR QRS
            if ~isempty( noiseRuns )
                % - indexes
                [ ~, noiseBeatIndexes ] = intersect( qrsComplexes.R, find( noiseRuns.Points ) );
                % - clear
                qrsComplexes = ClassUnusualSignalDetection.ClearQRS( qrsComplexes, noiseBeatIndexes );
                % - check beat number
                if length( qrsComplexes.R ) < 5
                    qrsComplexes = ClassUnusualSignalDetection.ClearQRS( qrsComplexes, transpose( 1:length( qrsComplexes.R ) ) );
                end
            end
            
            % Clear noise interval
            if ~isempty( noiseRuns )
                % Number of initial interval without signal
                numberIntervalWithoutSignal = int32( numel( analysisParameters.IntervalWithoutSignal ) );
                % Number of noise
                numberNoiseRun = int32( numel( noiseRuns.StartTime(: , 1) ) );
                % Merge with interval without without signal
                for runIndex = 1 : numberNoiseRun
                    % - starttime
                    analysisParameters.IntervalWithoutSignal( numberIntervalWithoutSignal + runIndex ).StartTime = char( noiseRuns.StartTime( runIndex,: ) );
                    % - endtime
                    analysisParameters.IntervalWithoutSignal( numberIntervalWithoutSignal + runIndex ).EndTime = char( noiseRuns.EndTime( runIndex,: ) );
                    % - type
                    analysisParameters.IntervalWithoutSignal( numberIntervalWithoutSignal + runIndex ).Type = deal( 'Noise' );
                end
                
            end
            
            % New Heart Rate
            qrsComplexes.HeartRate = [ 0; ClassRhythmAnalysis.CalculateHeartRate( qrsComplexes.R, 250 ) ];
            % Premature beat assesment based on new heart rate
            % - pvc
            pvcBeats = find( qrsComplexes.VentricularBeats );
            pvcBeats( qrsComplexes.HeartRate( pvcBeats ) < analysisParameters.Bradycardia.ClinicThreshold ) = [ ];
            qrsComplexes.VentricularBeats = zeros( length( qrsComplexes.R ), 1, 'logical' );  qrsComplexes.VentricularBeats( pvcBeats ) = true;
            % - pac
            pacBeats = find( qrsComplexes.AtrialBeats );
            pacBeats( qrsComplexes.HeartRate( pacBeats ) < analysisParameters.Bradycardia.ClinicThreshold ) = [ ];
            qrsComplexes.AtrialBeats = zeros( length( qrsComplexes.R ), 1, 'logical' );  qrsComplexes.AtrialBeats( pacBeats ) = true;
            
        end
        
        
    end % methods
    
    
end % classdef


%% SubFunction: Block Segmentation

function [ blockStart, blockEnd ] = BlockSegmentation( binarySignal )

% - edges
blockEdges = ...
    single( ( abs( diff( [0; binarySignal; 0 ] ) ) > 0 ) > 0 );
blockEdges =...
    single( find(blockEdges == 1) );
% - start
blockStart = ...
    single( blockEdges( 1:2:length( blockEdges ) ) );
% - end
blockEnd = ...
    single( blockEdges( 2:2:length( blockEdges ) ) ) - 1;

end


%% SubFuntion: Merge Blocks

function [ blockStart, blockEnd ] = MergeBlocks( blockStart, blockEnd, maxInterval )

if length( blockStart ) > 1
    % - temp blocks
    tempEnd = blockEnd( 1 : end - 1 );
    tempStart = blockStart( 2 : end );
    % - intervals
    runInterval = tempStart - tempEnd;
    intervals2Delete = find( runInterval <= single( maxInterval ) );
    % - merge
    blockStart( intervals2Delete + 1 ) = [ ];
    blockEnd( intervals2Delete ) = [ ];
end

end


%% SubFunction : Calculate Peak Angle

function [ peakAngles ] = CalculatePeakAngle( signal, peakPoints )

% Calculation of the peak angles.
%
% [ peakAngles ] = CalculatePeakAngle( signal, peakPoints )
%
% <<< Function Inputs >>>
%   single[ n, 1 ] signal: the signal of the analysis channel that it is going to be analyzed.
%   single[ n, 1 ] peakPoints: peak points -possible beats- in the given signal
%
% <<< Function Outputs >>>
%   single[ n, 1 ] peakAngles: angles of the peaks
%

% MARGIN
margin = 5;

% ANTERIOR PEAK POINT
beforePeakPoints = peakPoints - margin;
beforePeakPoints( beforePeakPoints < 1 ) = 1;


% POSTERIOR PEAK POINT
afterPeakPoints = peakPoints + margin;
afterPeakPoints( afterPeakPoints > length( signal ) ) = length( signal );


% PEAK ANGLE
beforePeaksAngle = abs( CalculateBlockAngle( signal, beforePeakPoints, peakPoints ) );
afterPeaksAngle= abs( CalculateBlockAngle( signal, peakPoints, afterPeakPoints ) );
% peakAngles = 0.5 * beforePeaksAngle + 0.5 * afterPeaksAngle;
peakAngles = beforePeaksAngle;
peakAngles( afterPeaksAngle > peakAngles ) = afterPeaksAngle( afterPeaksAngle > peakAngles );


end


%% Calculate Block Angle

function angle = CalculateBlockAngle( signal, blockStart, blockEnd )

% To calculate the angle between the begining and end of the wave in the block.
%
% waveAngle = CalculateBlockAngle( blockStart, blockEnd, signal )
%
% <<< Function Inputs >>>
%   single[ n, 1 ] signal: the signal of the analysis channel that it is going to be analyzed.
%   single[n,1] blockStart: wave start point.
%   single[n,1] blockEnd: wave end point
%
% <<< Function output >>>
%   single[n,1] waveAngle: wave angle.


% INITIALIZATION
angle = ones( length( blockStart ), 1, 'single' );


% ANGLE CALCULATION
if ~isempty( blockStart )
    
    waveDuration = blockEnd - blockStart;
    
    for blockIndex = single( 1 : length( blockStart ) )
        
        waveEdgeAmplitude = signal( blockEnd( blockIndex) ) - signal( blockStart( blockIndex ) );
        angle( blockIndex ) = ClassSlope.CalculateAngle( waveEdgeAmplitude, waveDuration( blockIndex ) );
        
    end
    
else
    
    angle = single( [ ] );
    
end

end

