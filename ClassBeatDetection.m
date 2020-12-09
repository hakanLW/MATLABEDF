classdef ClassBeatDetection
    
    % "ClassBeatDetection.m" class consists beat detection functions.
    %
    % function:   SignalNoiseDetection
    % function:   FilterSignal
    % function:   InitialThresholds
    % function:   ChangeThresholds
    % function:   GetWindow
    % function:   RRIntervalEvalulation
    % function:   BeatDetection_Main
    % function:   BeatDetection_SearchBack
    % function:   RPoint_Store
    
    %% PROPERTIES
    
    properties
        
        %
        
    end
    
    %% STATIC METHODS
    
    
    methods (Static)
        
        
        %% Signal Noise Detection
        
        function [ noiseFlag ] = SignalPeakNoiseDetection( signal, recordInfo )
            
            % Detection of the high amplitude noises casued by electrode
            % movement.
            %
            % [ noiselessSignal, signalNoise, noiseFlag ] = SignalNoiseDetection( signal, usualPeriodStart, , recordInfo )
            %
            % <<< Function Inputs >>>
            %   single[ n, 1 ] signal: the signal of the analysis channel that it is going to be analyzed.
            %   single[ n, 1 ] usualPeriodStart: Start point of the predetermined usual ecg period.
            %   single[ n, 1 ] usualPeriodEnd: End point of the predetermined usual ecg period.
            %   struct recordInfo: ECG recording informations.
            %
            % <<< Function Outputs >>>
            %   single[ n, 1 ] noiselessSignal: Signal that is purged from detected noises.
            %   struct signalNoise: Struct that gives informations about detected noises.
            %   logical[ n, 1 ] noiseFlag: Flags that defines noist signal points.
            %
            
            % PREALLOCATION OF THE NOISE FLAG
            noiseFlag = zeros( length( signal ), 1, 'logical' );
            
            % BASELINE FILTER
            MoveAveragedSignal = abs( movmean( signal, 2 * recordInfo.RecordSamplingFrequency ) );
            %             MoveAveragedSignal( 120 * recordInfo.RecordSamplingFrequency : end ) = 0;
            
            % SIGNAL THRESHOLD
            signalThreshold = sqrt( mean( MoveAveragedSignal .^2 ) ) * 7.5; 
            signalThreshold( signalThreshold > 0.33 ) = 0.33;
            signalThreshold( signalThreshold < 0.10 ) = 0.10;
            
            % BASELINE ABERRATION
            BaselineAberrationFlag = abs( MoveAveragedSignal ) > signalThreshold;
            BaselineAberrationFlag(1) = false;
            BaselineAberrationFlag(end) = false;
            
            %             % PLOT
            %             close all; figure;
            %             blockEdges = single( ( abs( diff( [0; BaselineAberrationFlag; 0 ] ) ) > 0 ) > 0 );
            %             blockEdges = single( find(blockEdges == 1) );
            %             noiseStart = single( blockEdges( 1:2:length( blockEdges ) ) );
            %             noiseEnd = single( blockEdges( 2:2:length( blockEdges ) ) );
            %             plotNoiseSignal = zeros( length( signal ), 1, 'logical' );
            %             for plotNoiseIndex = 1 : length( noiseStart )
            %                 plotNoiseSignal( noiseStart( plotNoiseIndex ) : noiseEnd( plotNoiseIndex ) ) = true;
            %             end
            %             plots( 1 ) = subplot( 2,1,1 );
            %             plot( signal );
            %             xlim( [ 0 length( signal ) ] );
            %             grid on;
            %             axis tight;
            %             plots( 2 ) =  subplot( 2,1,2 );
            %             plot( MoveAveragedSignal ); hold on;
            %             plot( signalThreshold * ones( length( signal ), 1, 'single' ), 'r:', 'LineWidth', 2  );
            %             plot( plotNoiseSignal );
            %             grid on;
            %             ylim( [ 0 1 ] )
            %             xlim( [ 0 length( MoveAveragedSignal ) ] );
            %             linkaxes([plots], 'x');
            %             zoom on;
            %
            % NOISE DETECTION
            if ~all( ~BaselineAberrationFlag )
                
                
                % NOISE START/END POINTS                
                blockEdges = single( ( abs( diff( [0; BaselineAberrationFlag; 0 ] ) ) > 0 ) > 0 );
                blockEdges = single( find(blockEdges == 1) );
                noiseStart = single( blockEdges( 1:2:length( blockEdges ) ) );
                noiseEnd = single( blockEdges( 2:2:length( blockEdges ) ) );
                
                
                % PREALLOCATION OF THE NOISE STRUCT
                signalNoise.Start = zeros( length( noiseStart ), 1, 'single' );
                signalNoise.End = zeros( length( noiseStart ), 1, 'single' );
                
                
                % NOISE FLAGS AND STORE
                for blockIndex = 1 : length( noiseStart )
                    
                    % Packet
                    signalNoise.Start( blockIndex ) = max( double( 1 ), double( noiseStart( blockIndex ) - recordInfo.RecordSamplingFrequency ) );
                    signalNoise.End( blockIndex ) = min( double( length( signal ) ), double( noiseEnd( blockIndex ) + recordInfo.RecordSamplingFrequency ) );
                    % Flag
                    noiseFlag( signalNoise.Start( blockIndex ) : signalNoise.End( blockIndex ) ) = true;
                    
                end
                
            end
            
        end
        
        
        %% R Detection Filters
        
        function [ bandPassedZeroPhase, powered ] = FilterSignal(signal, samplingFreq)
            
            % Filters used for the detection of the beats.
            %
            % [ bandPassedZeroPhase, powered ] = SignalFilter(signal, minAmplitudeRange, samplingFreq)
            %
            % <<< Function Inputs >>>
            %   single signal
            %   single samplingFreq
            %
            % <<< Function Outputs >>>
            %   single bandPassedZeroPhase
            %   single powered
            
            % band passed signal with zero phase
            bandPassedZeroPhase = ClassFilter.BandPassFilter(signal, [5 15], 1, samplingFreq, 'filtfilt');
            
            %- band passed signal
            powered = ClassFilter.BandPassFilter(signal, [5 15], 1, samplingFreq, 'filter');
            %- derivatived
            powered = ClassFilter.DerivativeFilter(powered, [-1 -2 0 2 1] / 8, 1, 'filter');
            %- square
            powered = powered.^2;
            %- moving averaged
            powered = ClassFilter.MovingAverageFilter(powered, round(0.175* samplingFreq), false);
            % length of the powered signal correction
            powered( double( length( bandPassedZeroPhase ) + 1 ) : double( end ) ) = [ ];
            
            %             close all
            %             figure
            %             plots(1) = subplot(3,1,1); plot( signal ); title('Raw'); grid on;
            %             plots(2) = subplot(3,1,2); plot( bandPassedZeroPhase ); title('Band Passed'); grid on;
            %             plots(3) = subplot(3,1,3); plot( powered ); title('Powered'); grid on;
            %             linkaxes([plots], 'x');
            %             zoom on;
            
        end
        
        
        %% R Detection Thresholds : Initial Thresholds
        
        function [signalThreshold, signalLevel, noiseThreshold, noiseLevel] = InitialThresholds( signal )
            
            % Determination of the initial thresholds of the Pan-Thomkins algorithm.
            %
            % [signalThreshold, signalLevel, noiseThreshold, noiseLevel] = InitialThresholds( signal )
            %
            % <<< Function Inputs >>>
            %  single signal
            %
            % <<< Function Outputs >>>
            %   single signalThreshold
            %   single signalLevel
            %   single noiseThreshold
            %   single noiseLevel
            
            
            % Signal threshold
            signalThreshold = single( max( signal ) ) * 0.5;
            signalLevel = signalThreshold;
            
            % Noise threshold
            noiseThreshold = single( mean( signal ) ) * 0.5;
            noiseLevel = noiseThreshold;
            
            
        end
        
        
        %% R Detection Thresholds : Change Thresholds
        
        function [ signalThreshold, noiseThreshold ] = ChangeThresholds( signalLevel, noiseLevel )
            
            % Changing the thresholds of the Pan-Thomkins algorithm.
            %
            % [ signalThreshold, noiseThreshold ] = ChangeThresholds( signalLevel, noiseLevel )
            %
            % <<< Function Inputs >>>
            %   single signalLevel
            %   single noiseLevel
            %
            % <<< Function Outputs >>>
            %   single signalThreshold
            %   single noiseThreshold
            
            
            %  change band passed signal/noise level
            signalThreshold = noiseLevel + 0.25 * ( abs( signalLevel - noiseLevel ) );
            noiseThreshold = 0.5 * ( signalThreshold );
            
        end
        
        
        %% Get Window 
        
        function  [ startPoint, endPoint ] = GetWindow( signalLength, refPoint, msBefore, msAfter, samplingFreq )
            
            % Determination of the searching limits.
            %
            % [ startPoint, endPoint ] = GetWindow( signalLength, refPoint, msBefore, msAfter, samplingFreq )
            %
            % <<< Function Inputs >>>
            %   single signalLength
            %   single refPoint
            %   single msBefore
            %   single msAfter
            %   single samplingFreq
            %
            % <<< Function Outputs >>>
            %   single startPoint
            %   single endPoint
            
            
            % Start Point
            if msBefore ~= 0
                startPoint = max( double( refPoint - round( (msBefore / 1000) * samplingFreq) ), double( 1 ) );
            else
                startPoint = refPoint;
            end
            
            % End Point
            if msAfter ~= 0
                endPoint = min( double( refPoint - round( (msAfter / 1000) * samplingFreq) ), double( signalLength ) );
            else
                endPoint = refPoint;
            end
            
        end
        
        
        %% RR Interval Evaluation
        
        function [ rrInterval, pThreshold, bpThreshold ] = RRIntervalEvalulation...
                ( samplingFreq, numbBeat, rPoweredIndexes, currentPoweredIndex, currentPoweredValue, pThreshold, bpThreshold )
            
            % RR interval evaluation.
            %
            % [ rrInterval, pThreshold, bpThreshold ] = RRIntervalEvalulation...
            %                 ( samplingFreq, numbBeat, rPoweredIndexes, currentPoweredIndex, currentPoweredValue, pThreshold, bpThreshold )
            %
            % <<< Function Inputs >>>
            %   single samplingFreq
            %   single numbBeat
            %   single rPoweredIndexes
            %   single currentPoweredIndex
            %   single currentPoweredValue
            %   single pThreshold
            %   single bpThreshold
            %
            % <<< Function Outputs >>>
            %   single rrInterval
            %   single pThreshold
            %   single bpThreshold
            
            
            % QRS Limits
            if numbBeat < 6
                qrsLimit = 2;
            else
                qrsLimit = 6;
            end
            
            % RR Interval Evaluation
            if numbBeat > qrsLimit
                
                % calculate the intervals of last 8 peak
                rrInterval = diff( rPoweredIndexes( double( numbBeat - qrsLimit + 1 ) : double( numbBeat ) ) );
                rrInterval( rrInterval > samplingFreq * 5 ) = [ ];
                % calculate the mean of 8 previous R waves interval
                if ~isempty( rrInterval )
                    rrMean = mean( rrInterval );
                else
                    rrMean = samplingFreq;
                end
                % last RR
                rrComparison = currentPoweredIndex - rPoweredIndexes( numbBeat );
                
                % if there is a irregularity in rr interval;
                if  ~( currentPoweredValue < 1e-3 )
                    
                    if ( rrComparison <= 0.92* rrMean ) || ( rrComparison >= 1.16* rrMean )
                        
                        % Adjusting threshold values: Lowering down thresholds to detect better
                        pThreshold = 0.5 * ( pThreshold );
                        bpThreshold = 0.5 * ( bpThreshold );
                        
                    end
                    
                end
                % if there are more than 8 detected r points
                rrInterval = rrMean;
                
            else
                
                % if there are less than 8 detected r points
                rrInterval = 0;
                
            end
            
            rrInterval = single( rrInterval );
            
        end
        
        
        %% Beat Detection : Main
        
        function [ rPoint, pointDirection, pSignalLevel, pNoiseLevel, bpSignalLevel, bpNoiseLevel ] = BeatDetection_Main...
                ( bpSignal, ...
                currentPoweredPeakValue, ...
                nextPoweredPeakValue, ...
                poweredPeakInterval, ...
                pSignalThreshold, ...
                pSignalLevel, ...
                pNoiseLevel, ...
                bpPeakValue, ...
                bpWindowStart, ...
                bpWindowEnd, ...
                bpSignalThreshold, ...
                bpSignalLevel, ...
                bpNoiseLevel, ...
                samplingFreq )
            
            % Main beat detection based on pan-thomkins algorithm.
            %
            % [ rPoint, pointDirection, pSignalLevel, pNoiseLevel, bpSignalLevel, bpNoiseLevel ] = BeatDetection_Main...
            %                 ( bpSignal, ...
            %                 currentPoweredPeakValue, ...
            %                 nextPoweredPeakValue, ...
            %                 pSignalThreshold, ...
            %                 pSignalLevel, ...
            %                 pNoiseLevel, ...
            %                 bpPeakValue, ...
            %                 bpWindowStart, ...
            %                 bpWindowEnd, ...
            %                 bpSignalThreshold, ...
            %                 bpSignalLevel, ...
            %                 bpNoiseLevel, ...
            %                 samplingFreq )
            %
            % <<< Function Inputs >>>
            %   single bpSignal
            %   single currentPoweredPeakValue
            %   single nextPoweredPeakValue
            %   single pSignalThreshold
            %   single pSignalLevel
            %   single pNoiseLevel
            %   single bpPeakValue
            %   single bpWindowStart
            %   single bpWindowEnd
            %   single bpSignalThreshold
            %   single bpSignalLevel
            %   single bpNoiseLevel
            %   single samplingFreq
            %
            % <<< Function Outputs >>>
            %   single rPoint
            %   single pointDirection
            %   single pSignalLevel
            %   single pNoiseLevel
            %   single bpSignalLevel
            %   single bpNoiseLevel
            
            % Initilization
            rPoint = single( 1 );
            pointDirection = single( 1 );
            
            % Save initial threshold values
            initial_pSignalLevel = pSignalLevel;
            initial_pNoiseLevel = pNoiseLevel;
            initial_bpSignalLevel = bpSignalLevel;
            initial_bpNoiseLevel = bpNoiseLevel;
            
            % Check next peak interval
            if poweredPeakInterval > 0.200 * samplingFreq
                nextPoweredPeakValue = currentPoweredPeakValue - 1;
            end
            
            % CHECK STEP:
            % Powered Signal Threshold
            if ...
                    ( currentPoweredPeakValue >= ( pSignalThreshold * 0.90 ) ) ...  % If current value is larger than threshold
                    && ...
                    ( currentPoweredPeakValue > nextPoweredPeakValue )            % If current value is larger than the following peak
                
                % CHECK STEP:
                % Bandpassed Signal Threshold
                if bpPeakValue >= ( bpSignalThreshold * 0.50 )  % If current value is larger than threshold
                    
                    % In order to define the detected beat type, two max
                    % points are detected:
                    %       [1] Normal QRS: In normal beat, max point of
                    %       the bandpassed signal refers to the R point
                    %       [2] Reversed QRS: In reversed beat, max point
                    %       of the bandpassed signal refers to the S point
                    % - (ref: type 1) Max point in the bandpassed signal
                    [ absValue, possibleRPointReferenceAbs ] = max ( abs( bpSignal( double( bpWindowStart ) : double( bpWindowEnd ) ) ) );
                    % - (ref: type 2) Max point in the absolute bandpassed signal
                    [rawValue, possibleRPointReferenceRaw ] = max ( bpSignal( double( bpWindowStart ) : double( bpWindowEnd ) ) );
                    
                    % Based on the comparsion between abs and raw value,
                    % type of the beat is pre-determined:
                    if ( rawValue / absValue ) < 0.90
                        % - (ref: type 2) Reversed beat type
                        refPoint = bpWindowStart + possibleRPointReferenceAbs - 1;
                        % If the currently detected beat is reversed, then
                        % the r' point of the beat is needed to be
                        % detected. Therefore a max point in bandpassed
                        % signal is searched in sub-window
                        
                        % - Determination of the sub-window range
                        [subWindowStartPoint, subWindowEndPoint] = ClassBeatDetection.GetWindow( length( bpSignal ), refPoint, single(80), single(0), samplingFreq);
                        % - Detection of the max point in the sub window
                        [~, possibleRPoint] = max (  bpSignal( double( subWindowStartPoint ) : double( subWindowEndPoint ) ) );
                        % - Signal point of the max point in the sub window
                        rPoint = subWindowStartPoint + possibleRPoint - 1;
                        % point direction 
                        pointDirection = single( -1 );
                    else
                        % - (ref: type 1) Normal beat type
                        rPoint = bpWindowStart + possibleRPointReferenceRaw - 1;
                    end
                    
                    % Changing bandpassed signal level
                    bpSignalLevel = ...
                        0.125 * bpPeakValue + 0.875 * bpSignalLevel;
                    
                end
                
                % Changing powered signal level
                pSignalLevel = ...
                    0.125 * currentPoweredPeakValue + 0.875 * pSignalLevel ;
                
            else
                
                % Changing powered andband passed noise level
                bpNoiseLevel = ...
                    0.125 * bpPeakValue + 0.875 * bpNoiseLevel;
                pNoiseLevel = ...
                    0.125 * currentPoweredPeakValue + 0.875 * pNoiseLevel;
                
            end
            
            % Threshold change control
            % - If thresholds are increased significantly ( > 2* ) then,
            % dont change the thresholds
            % - Threshold change control boolean:
            initializeThreshold = false;
            % Check threshold change
            % - Powered # Signal Level
            if ~initializeThreshold
                change_pSignalLevel = ...
                    pSignalLevel / initial_pSignalLevel;
                if change_pSignalLevel > 1.5; initializeThreshold = true; end
            end
            % - Bandpassed # Signal Level
            if ~initializeThreshold
                change_bpSignalLevel = ...
                    bpSignalLevel / initial_bpSignalLevel;
                if change_bpSignalLevel > 1.5; initializeThreshold = true; end
            end
            
            % Initializing the thresholds
            if initializeThreshold
                % - Powered # Signal Level
                pSignalLevel = initial_pSignalLevel;
                % - Powered # Noise Level
                pNoiseLevel = initial_pNoiseLevel;
                % - Bandpassed # Signal Level
                bpSignalLevel = initial_bpSignalLevel;
                % - Bandpassed # Noise Level
                bpNoiseLevel = initial_bpNoiseLevel;
            end
            
        end
        
        
        %% Beat Detection : Search Back
        
        function [ rPoint, pointDirection, pPeakIndex, bpSignalLevel, pSignalLevel ] = BeatDetection_SearchBack ...
                ( bpSignal, ...
                pSignal, ...
                currentPoweredIndex, ...
                lastBeatPoweredIndex, ...
                pNoiseThreshold, ...
                pSignalLevel, ...
                bpNoiseThreshold, ...
                bpSignalLevel, ...
                samplingFreq )
            
            % Search back beat detection algorithm based on pan-thomkins algorithm.
            % If there is a long period (1.6*meanRR) without a detected r point, search back is in run.
            %
            % [ rPoint, pointDirection, pPeakIndex, bpSignalLevel, pSignalLevel ] = BeatDetection_SearchBack ...
            %                 ( bpSignal, ...
            %                 pSignal, ...
            %                 currentPoweredIndex, ...
            %                 lastBeatPoweredIndex, ...
            %                 pNoiseThreshold, ...
            %                 pSignalLevel, ...
            %                 bpNoiseThreshold, ...
            %                 bpSignalLevel, ...
            %                 samplingFreq )
            %
            % <<< Function Inputs >>>
            %   single bpSignal
            %   single pSignal
            %   single currentPoweredIndex
            %   single lastBeatPoweredIndex
            %   single pNoiseThreshold
            %   single pSignalLevel
            %   single bpNoiseThreshold
            %   single bpSignalLevel
            %   single samplingFreq
            %
            % <<< Function Outputs >>>
            %   single rPoint
            %   single pointDirection
            %   single pPeakIndex
            %   single bpSignalLevel
            %   single pSignalLevel
            
            % Initilization
            rPoint = single( 1 );
            pPeakIndex = single( 0 );
            pointDirection = single( 1 );
            
            % Save initial threshold values
            initial_pSignalLevel = pSignalLevel;
            initial_bpSignalLevel = bpSignalLevel;
            
            % Defining the window to search for the possiblly missed beat.
            % Start of the range: Since minimum 200 ms interval is needed
            %                             for another fire in the ventriculars, the start point is
            %                             determined as 200 ms away from the lastly detected beat.
            %               // windowStartPoint
            % End of the range: End of the range is determined from the
            %                           current powered peak index.
            %               // windowEndPoint
            windowStartPoint = ...
                lastBeatPoweredIndex + round( 0.200 * samplingFreq );
            windowEndPoint = ...
                currentPoweredIndex - round( 0.100 * samplingFreq );
            % Powered signal window for the possiblly missed beat.
            searchBackWindowPowered = pSignal( double( windowStartPoint ) : double( windowEndPoint ) );
            
            % If such a window range can not be defined due to the narrow
            % end points, then assign the powered peak value as zero in
            % order to make a fail during the threshold comparison
            if ~isempty( searchBackWindowPowered )
                % pPeakValue
                [pPeakValue, pPeakIndex] = max( searchBackWindowPowered );
                % pPeakIndex
                pPeakIndex = windowStartPoint + pPeakIndex -1;
            else
                % pPeakValue
                pPeakValue = 0;
            end
            
            % CHECK STEP 1 - Powered Signal
            if pPeakValue >= ( pNoiseThreshold * 0.90 )
                
                % For each peak point in the powered signal,
                % a window to analyze is determined for the beat detection.
                % bpWindowStartPoint : point in the signal where the search window starts
                % bpWindowEndPoint : point in the signal where the search window ends
                [bpWindowStartPoint, bpWindowEndPoint] = ...
                    ClassBeatDetection.GetWindow( length( bpSignal ), pPeakIndex, single(150), single(0), samplingFreq);
                % Peak point value of the bandpassed search window
                bpPeakValue = ...
                    max( bpSignal( double( bpWindowStartPoint ) : double( bpWindowEndPoint ) ) );
                
                % CHECK STEP 2 - Filtered Signal
                if bpPeakValue >= ( bpNoiseThreshold * 0.90 )
                    
                    % In order to define the detected beat type, two max
                    % points are detected:
                    %       [1] Normal QRS: In normal beat, max point of
                    %       the bandpassed signal refers to the R point
                    %       [2] Reversed QRS: In reversed beat, max point
                    %       of the bandpassed signal refers to the S point
                    % - (ref: type 1) Max point in the bandpassed signal
                    [absValue, possibleRPointReferenceAbs] = max ( abs( bpSignal( double( bpWindowStartPoint ) : double( bpWindowEndPoint ) ) ) );
                    % - (ref: type 2) Max point in the absolute bandpassed signal
                    [rawValue, possibleRPointReferenceRaw] = max ( bpSignal( double( bpWindowStartPoint ) : double( bpWindowEndPoint ) ) );
                    % Based on the comparsion between abs and raw value,
                    % type of the beat is pre-determined:
                    if ( rawValue / absValue ) < 0.95
                        % - (ref: type 2) Reversed beat type
                        refPoint = bpWindowStartPoint + possibleRPointReferenceAbs - 1;
                        % If the currently detected beat is reversed, then
                        % the r' point of the beat is needed to be
                        % detected. Therefore a max point in bandpassed
                        % signal is searched in sub-window
                        
                        % - Determination of the sub-window range
                        [subWindowStartPoint, subWindowEndPoint] = ClassBeatDetection.GetWindow( length( bpSignal ), refPoint, single(80), single(0), samplingFreq);
                        % - Detection of the max point in the sub window
                        [~, possibleRPoint] = max (  bpSignal( double( subWindowStartPoint ) : double( subWindowEndPoint ) ) );
                        % - Signal point of the max point in the sub window
                        rPoint = subWindowStartPoint + possibleRPoint - 1;
                        % point direction 
                        pointDirection = single( -1 );
                    else
                        % - (ref: type 1) Normal beat type
                        rPoint = bpWindowStartPoint + possibleRPointReferenceRaw - 1;
                    end
                    
                    % Changing bandpassed signal level
                    bpSignalLevel = ...
                        0.25 * bpPeakValue + 0.75 * bpSignalLevel;
                    
                end
                
                
                % Changing powered signal level
                pSignalLevel = ...
                    0.25 * pPeakValue + 0.75 * pSignalLevel ;
                
            end
            
            % Threshold change control
            % - If thresholds are increased significantly ( > 2* ) then,
            % dont change the thresholds
            % - Threshold change control boolean:
            initializeThreshold = false;
            % Check threshold change
            % - Powered # Signal Level
            if ~initializeThreshold
                change_pSignalLevel = ...
                    pSignalLevel / initial_pSignalLevel;
                if change_pSignalLevel > 1.5; initializeThreshold = true; end
            end
            % - Bandpassed # Signal Level
            if ~initializeThreshold
                change_bpSignalLevel = ...
                    bpSignalLevel / initial_bpSignalLevel;
                if change_bpSignalLevel > 1.5; initializeThreshold = true; end
            end
            
            % Initializing the thresholds
            if initializeThreshold
                % - Powered # Signal Level
                pSignalLevel = initial_pSignalLevel;
                % - Bandpassed # Signal Level
                bpSignalLevel = initial_bpSignalLevel;
            end
            
        end
        
        
        %% R Point : Store
        
        function [rPoints, rPointDirections, rPointsPoweredIndexes, numberOfBeats, lastDetectedBeatIndex ] = RPoint_Store...
                ( ecgPowered, ...
                currentRPoint, ...
                rPoints, ....
                rPointDirection, ...
                rPointDirections, ...
                currentRPointPoweredIndex, ...
                rPointsPoweredIndexes, ...
                numberOfBeats, ...
                lastDetectedBeatIndex, ...
                samplingFreq )
            
            % Annotation and storing the last detected r point.
            %
            % [rPoints, rPointDirections, rPointsPoweredIndexes, numberOfBeats, lastDetectedBeatIndex ] = RPoint_Store...
            %                 ( ecgPowered, ...
            %                 currentRPoint, ...
            %                 rPoints, ....
            %                 rPointDirection, ...
            %                 rPointDirections, ...
            %                 currentRPointPoweredIndex, ...
            %                 rPointsPoweredIndexes, ...
            %                 numberOfBeats, ...
            %                 lastDetectedBeatIndex, ...
            %                 samplingFreq )
            %
            % <<< Function Inputs >>>
            %   single ecgPowered
            %   single currentRPoint
            %   single rPoints
            %   single rPointDirection
            %   single rPointDirections
            %   single currentRPointPoweredIndex
            %   single rPointsPoweredIndexes
            %   single numberOfBeats
            %   single lastDetectedBeatIndex
            %   single samplingFreq
            %
            % <<< Function Outputs >>>
            %   single rPoints
            %   single rPointDirections
            %   single rPointsPoweredIndexes
            %   single numberOfBeats
            %   single lastDetectedBeatIndex
            
            
            % if rPoint is detected
            if currentRPoint ~= 1
                
                % if rr interval is larger than 200 ms
                if ( currentRPoint - rPoints( numberOfBeats ) ) >= ( 0.200 * samplingFreq )
                    
                    % save the r point index
                    rPoints( numberOfBeats + 1 ) = currentRPoint;
                    % save the direction of the r point
                    rPointDirections( numberOfBeats + 1 ) = rPointDirection;
                    % save the r point powered index
                    rPointsPoweredIndexes( numberOfBeats + 1 ) = currentRPointPoweredIndex;
                    % increase the number of beats
                    numberOfBeats = numberOfBeats + 1;
                    lastDetectedBeatIndex = lastDetectedBeatIndex + 1;
                    
                    % if rr interval is not larger than 200 ms, check the
                    % previous one
                else
                    
                    % if last detected point's powered value larger than
                    % last annotated,
                    if ecgPowered(currentRPointPoweredIndex) >= ecgPowered( rPointsPoweredIndexes(numberOfBeats) )
                        
                        % save the last detected point over
                        rPoints( numberOfBeats ) = currentRPoint;
                        % save the direction of the r point
                        rPointDirections( numberOfBeats ) = rPointDirection;
                        % save the last detected point over
                        rPointsPoweredIndexes( numberOfBeats ) = currentRPointPoweredIndex;
                        
                    end
                    
                end
                
            end
            
        end
        
        
    end
    
    
end