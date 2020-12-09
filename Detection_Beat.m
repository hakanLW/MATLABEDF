
% Beat Detection Algorithm.
%
% [ qrsComplexes ] = Detection_Beat( ecgSignal2Analyze, recordInfo, analysisParameters, matlabAPIConfig )
%
% <<< Function Inputs >>>
%   single ecgSignal2Analyze
%   struct recordInfo
%   struct analysisParameters
%   struct matlabAPIConfig
%
% <<< Function outputs >>>
%   struct qrsComplexes


function [ qrsComplexes ] = Detection_Beat( ecgRaw, recordInfo, analysisParameters, matlabAPIConfig )


%% plot_r PARAMETERS

% MeanNoise_smoothed  = [ ];
% MeanSignal_smoothed  = [ ];
% MeanNoise_bandpassed = [ ];
% MeanSignal_bandpassed  = [ ];


%% FLAG INTERVALS TO ANALYZE

% Given intervals that are not going to be analyzed are logged.
% Given intervals' points are changed to zero which is false in logical
% state. During further analysis, those points are skipped.

if ~isempty( analysisParameters.IntervalWithoutSignal )
    
    for intervalIndex = 1 : int32( numel( analysisParameters.IntervalWithoutSignal ) )
        
        % Start
        startPoint = ...
            ClassDatetimeCalculation.Substraction( analysisParameters.IntervalWithoutSignal( intervalIndex ).StartTime, recordInfo.RecordStartTime );
        startPoint = ...
            double( ( ClassTypeConversion.ConvertDuration2Miliseconds( startPoint ) / 1000 ) * recordInfo.RecordSamplingFrequency + 1 - recordInfo.RecordSamplingFrequency );
        if startPoint < 1; startPoint = 1; end
        % End
        endPoint = ...
            ClassDatetimeCalculation.Substraction( analysisParameters.IntervalWithoutSignal( intervalIndex ).EndTime, recordInfo.RecordStartTime );
        endPoint = ...
            double( ( ClassTypeConversion.ConvertDuration2Miliseconds( endPoint ) / 1000 ) * recordInfo.RecordSamplingFrequency + recordInfo.RecordSamplingFrequency );
        if endPoint > length( ecgRaw ); endPoint = length( ecgRaw ); end
        % Store
        ecgRaw( int32( startPoint ) : int32( endPoint ) ) = single( 0 );
        
    end
    
end; clear intervalIndex startPoint endPoint signal2Analyze


%% SIGNAL NOISE

% Get Signal Noise Points
% - ignore first 1 sec
ecgRaw( 1 : recordInfo.RecordSamplingFrequency ) = 0;
% - ignore last 1 sec
ecgRaw( length( ecgRaw ) - recordInfo.RecordSamplingFrequency : end ) = 0;
% noise detection
signalNoise = ClassBeatDetection.SignalPeakNoiseDetection( ecgRaw, recordInfo );
% clear noise
ecgRaw = ecgRaw .* ~signalNoise; clear signalNoise;

%% SIGNAL CONDITIONING

% ECG BandPassed and Powered signals are generated for furter analysis.
[ ...
    ecgBandPassed, ...
    ecgPowered ...
    ] = ClassBeatDetection.FilterSignal( ecgRaw, recordInfo.RecordSamplingFrequency );

% Disp log
if matlabAPIConfig.IsLogWriteToConsole; disp( ' - Signal is filtered. ' ); end


%% THRESHOLDs

% Find the first point that is higher than
% the minimum signal amplitude threshold
% ERROR:     If the signal begins with a low amplitude and continues with that range for a
%                 long time, the initial threshold values gets very low amplitudes such that false
%                 qrs points are detected.
analysisStartPoint = single( find( ecgBandPassed > analysisParameters.MinimumSignalAmplitude * 0.5, 1, 'first' ) );

% CHECK:    If an analysisStartPoint cant be found, the signal is either
%               an asystole signal or during recording the ecg signal of the patient
%               couldnt be recorded.
if ~isempty( analysisStartPoint )
    
    if ( length( ecgRaw ) - analysisStartPoint ) > single( 2 )*recordInfo.RecordSamplingFrequency
        
        % Thresholds - Powered
        [...
            poweredSignalThreshold, ...
            poweredSignalLevel,...
            poweredNoiseThreshold,...
            poweredNoiseLevel...
            ] = ClassBeatDetection.InitialThresholds( ecgPowered ( double( analysisStartPoint ) : double( analysisStartPoint + single( 2 )*recordInfo.RecordSamplingFrequency ) ) );
        
        % Thresholds - BandPassed
        [...
            bandPassedSignalThreshold, ...
            bandPassedSignalLevel,...
            bandPassedNoiseThreshold,...
            bandPassedNoiseLevel ...
            ] = ClassBeatDetection.InitialThresholds( ecgBandPassed ( double( analysisStartPoint ) : double( analysisStartPoint + single( 2 )*recordInfo.RecordSamplingFrequency ) ) );
        
    else
        
        analysisStartPoint = [];
        
    end
    
    % Disp log
    if matlabAPIConfig.IsLogWriteToConsole; disp( ' - Initial thresholds are calculated. ' ); end
    
end


%% PEAK POINTS


if ~isempty( analysisStartPoint )
    
    % Detection of the powered signal peaks.
    % These peak points are possible peak points of the beats in the
    % recorded ecg signal.
    
    % In the further assessment, each peak points are analyzed by comparing
    % the threshold values
    [pPeakValue, pPeakIndex] = findpeaks( ecgPowered );
    
    % Disp log
    if matlabAPIConfig.IsLogWriteToConsole; disp( ' - Powered signal peak points are detected. ' ); end
    
else
    
    % If the signal does not have any analysisStartPoint, there is no need
    % for further assesment. Therefore, the peak detection is not required.
    pPeakValue = single( [ ] );
    pPeakIndex = single( [ ] );
    
end


%% INITIALIZATION

% If the peak array is empty:
% (1) no peak is found during the detection
% (2) the peak detection algorithm did not run because of the signal
% amplitude range
% Therefore, beat detection algorithm is not needed to be run.

if ~isempty( pPeakIndex )
    
    % PREALLOCATIONS
    % - keep detected r points
    rPoints = ...
        ones( 3 * ceil( length( ecgRaw ) / recordInfo.RecordSamplingFrequency ), 1, 'single' );
    % - keep powered signal index of the detected r points
    rPointsPoweredIndexes =  ...
        ones( length( rPoints ), 1, 'single' );
    % - point direction
    rPointDirections = ...
        zeros( length( rPoints ), 1, 'single' );
    
    % COUNTERS
    % - beat counter in the signal
    allSignalDetectedBeatIndex = single( 1 );
    % - beat counter in an interval
    periodSignalDetectedBeatIndex = single( 1 );
    
    % PARAMETERS
    % - get the threshold change time
    getThresholdChangedTime = single( 1 );
    minuteCounter = single( 0 );
    % - flag if thresholds are changed due to the long interval without a beat
    isThresoldDecreasedDue2BeatlessInterval = false;
    % - interval without signal is meet
    isSignallessIntervalMet = false;
    waitUntil = 1;
    
else
    
    % BEATLESS SIGNAL
    rPoints = single( [ ] );
    rPointDirections = single( [ ] );
    
end


%% BEAT DETECTION

% If peaks could be found in the powered signal, then start the detection.
if ~isempty( pPeakIndex )
    
    % Disp log
    if matlabAPIConfig.IsLogWriteToConsole; disp( ' - Beats are being detected.' ); end
    
    % Analyze each powered peak
    for peakIndex = double( 2 : ( length( pPeakIndex ) - 2 ) )
        
        % For each peak point in the powered signal,
        % a window to analyze is determined for the beat detection.
        % windowStartPoint : point in the signal where the search window starts
        % windowEndPoint : point in the signal where the search window ends
        % Start Point
        windowStartPoint = double( pPeakIndex( peakIndex ) - round( 0.175 *  recordInfo.RecordSamplingFrequency) );
        if windowStartPoint < 1; windowStartPoint = 1; end
        % Start Point
        windowEndPoint = double( pPeakIndex( peakIndex ) );
        
        % Peak point index and value of the bandpassed search window
        [ bpPeakValue, bpPeakIndex ] = max( abs( ecgBandPassed( double( windowStartPoint ) : double( windowEndPoint ) ) ) );
        bpPeakIndex = windowStartPoint + bpPeakIndex - 1;
        
        %         % plot_r PARAMETERS
        %         MeanNoise_smoothed  = [MeanNoise_smoothed;  poweredNoiseThreshold];
        %         MeanSignal_smoothed  = [MeanSignal_smoothed;  poweredSignalThreshold];
        %         MeanNoise_bandpassed = [MeanNoise_bandpassed;  bandPassedNoiseThreshold];
        %         MeanSignal_bandpassed  = [MeanSignal_bandpassed;  bandPassedSignalThreshold];
        %         % plot_r
        %         if windowStartPoint > 16.5 * recordInfo.RecordSamplingFrequency
        %             plot_r;
        %         end
        
        % Before go any further
        % Check Peak Values
        if pPeakValue( peakIndex ) < poweredSignalThreshold * 0.50
            % Changing powered bandband passed noise level
            bandPassedNoiseLevel = ...
                0.125 * bpPeakValue + 0.875 * bandPassedNoiseLevel;
            poweredNoiseLevel = ...
                0.125 * pPeakValue( peakIndex ) + 0.875 * poweredNoiseLevel;
            % Changing thresholds
            [ bandPassedSignalThreshold, bandPassedNoiseThreshold ] = ...
                ClassBeatDetection.ChangeThresholds( bandPassedSignalLevel, bandPassedNoiseLevel );
            [ poweredSignalThreshold, poweredNoiseThreshold ] = ...
                ClassBeatDetection.ChangeThresholds( poweredSignalLevel, poweredNoiseLevel );
            % Next loop
            continue;
        else
            if bpPeakValue < bandPassedSignalThreshold * 0.50
                % Changing powered signal level
                poweredSignalLevel = ...
                    0.125 * pPeakValue( peakIndex ) + 0.875 * poweredSignalLevel;
                % Changing thresholds
                [ bandPassedSignalThreshold, bandPassedNoiseThreshold ] = ...
                    ClassBeatDetection.ChangeThresholds( bandPassedSignalLevel, bandPassedNoiseLevel );
                [ poweredSignalThreshold, poweredNoiseThreshold ] = ...
                    ClassBeatDetection.ChangeThresholds( poweredSignalLevel, poweredNoiseLevel );
                % Next loop
                continue;
            end
        end
        
        if fix( windowStartPoint / ( 60 * recordInfo.RecordSamplingFrequency ) ) > minuteCounter
            % New Threshold Values
            % Thresholds - Powered
            [...
                new_poweredSignalThreshold, ...
                new_poweredSignalLevel,...
                new_poweredNoiseThreshold,...
                new_poweredNoiseLevel...
                ] = ClassBeatDetection.InitialThresholds( ecgPowered ( double( windowStartPoint ) : ...
                min( double( windowStartPoint + single( 2 )*recordInfo.RecordSamplingFrequency ), length( ecgPowered ) ) ) );
            % Thresholds - BandPassed
            [...
                new_bandPassedSignalThreshold, ...
                new_bandPassedSignalLevel,...
                new_bandPassedNoiseThreshold,...
                new_bandPassedNoiseLevel ...
                ] = ClassBeatDetection.InitialThresholds( ecgBandPassed ( double( windowStartPoint ) : ...
                min( double( windowStartPoint + single( 2 )*recordInfo.RecordSamplingFrequency ), length( ecgBandPassed ) ) ) );
            
            % Threshold change control
            % - If thresholds are increased significantly ( > 2* ) then,
            % dont change the thresholds
            % - Threshold change control boolean:
            initializeThreshold = false;
            % Check threshold change
            % - Powered # Signal Level
            if ~initializeThreshold
                change_pSignalLevel = ...
                    new_poweredSignalLevel / poweredSignalLevel;
                if change_pSignalLevel > 1.5; initializeThreshold = true; end
            end
            % - Bandpassed # Signal Level
            if ~initializeThreshold
                change_bpSignalLevel = ...
                    new_bandPassedSignalLevel / bandPassedSignalLevel;
                if change_bpSignalLevel > 1.5; initializeThreshold = true; end
            end
            
            % Initializing the thresholds
            if ~initializeThreshold
                % - Powered
                poweredSignalThreshold = new_poweredSignalThreshold;
                poweredSignalLevel = new_poweredSignalLevel;
                poweredNoiseThreshold = new_poweredNoiseThreshold;
                poweredNoiseLevel = new_poweredNoiseLevel;
                % - Bandpassed
                bandPassedSignalThreshold = new_bandPassedSignalThreshold;
                bandPassedSignalLevel = new_bandPassedSignalLevel;
                bandPassedNoiseThreshold = new_bandPassedNoiseThreshold;
                bandPassedNoiseLevel = new_bandPassedNoiseLevel;
            end
            
            % new counter
            minuteCounter = minuteCounter + 1;
            
        end
        
        % If sample can/cannot be analyzed
        if ~ecgRaw( windowStartPoint )
            
            % - Interval without signal.
            % - Threshold value change is forced not to change until the
            % point where analysis is started again.
            isSignallessIntervalMet = true;
            
        else
            
            % CHECK:   Wait  3 seconds after the signalles interval is
            %               ended in order to prevent the detection of the false beats.
            if isSignallessIntervalMet
                % Determine the waitUntil point.
                % If there is no signalless interval, waitUntil point is pre-determined as 1
                waitUntil = pPeakIndex( peakIndex ) + 3 * recordInfo.RecordSamplingFrequency;
                % Fall the flag
                isSignallessIntervalMet = false;
            end
            
            % RR Interval Evaluation
            if bpPeakIndex > waitUntil
                
                [rrInterval, poweredSignalThreshold, bandPassedSignalThreshold ] = ClassBeatDetection.RRIntervalEvalulation ( ...
                    recordInfo.RecordSamplingFrequency, ...
                    periodSignalDetectedBeatIndex, ...  % number of detected beats
                    rPointsPoweredIndexes, ...                    % beat powered index
                    pPeakIndex(peakIndex), ...   % current powered index
                    pPeakValue(peakIndex), ...   % current powered value
                    poweredSignalThreshold, ...              % powered signal threshold
                    bandPassedSignalThreshold );         % bandpassed signal threshold
                
                % R Detection: Search Back Detection Algorithm
                if ( periodSignalDetectedBeatIndex > 2 ) && rrInterval % && ( rrInterval > 0.5 * recordInfo.RecordSamplingFrequency )
                    % if there is a long period (1.6*meanRR) without a detected r point, search back;
                    if (pPeakIndex(peakIndex) - rPointsPoweredIndexes(allSignalDetectedBeatIndex) ) >= round(1.60*rrInterval)
                        
                        [ rPoint, rPointDirection, tempPoweredPeakIndex, bandPassedSignalLevel, poweredSignalLevel ] = ClassBeatDetection.BeatDetection_SearchBack(  ...
                            ecgBandPassed, ...                                                   % band passed signal
                            ecgPowered,...                                                          % powered signal
                            pPeakIndex(peakIndex),...                        % current powered index
                            rPointsPoweredIndexes(allSignalDetectedBeatIndex), ...    % last beat powered index
                            poweredNoiseThreshold, ...                                   % powered noise threshold
                            poweredSignalLevel, ...                                           % powered signal level
                            bandPassedNoiseThreshold, ...                            % bandpassed noise threshold
                            bandPassedSignalLevel, ...                                    % bandpassed signal level
                            recordInfo.RecordSamplingFrequency);                                                         % recordInfo.RecordSamplingFrequency
                        
                        % Annotation of the R Point
                        [rPoints, rPointDirections, rPointsPoweredIndexes, allSignalDetectedBeatIndex, periodSignalDetectedBeatIndex] = ClassBeatDetection.RPoint_Store ...
                            ( ecgPowered, ...                           % powered signal
                            rPoint, ...                                        % detected r point time in sample
                            rPoints, ...                                      % detected r points storage
                            rPointDirection, ...
                            rPointDirections, ...
                            tempPoweredPeakIndex, ...        % detected r point powered index
                            rPointsPoweredIndexes, ...            % detected r point powered indexes storage
                            allSignalDetectedBeatIndex, ...                          % detected r point index
                            periodSignalDetectedBeatIndex, ...                  % last detected r point index
                            recordInfo.RecordSamplingFrequency );                                    % recordInfo.RecordSamplingFrequency
                        
                    end % if (peakPoweredIndex(peakIndex) - rPointsPoweredIndex(end)) >= round(1.6*rrInterval)
                    
                end % if rrInterval
                
            end
            
            % R Detection: Main Detection Algorithm
            
            [ rPoint, rPointDirection, poweredSignalLevel, poweredNoiseLevel, bandPassedSignalLevel, bandPassedNoiseLevel ] = ClassBeatDetection.BeatDetection_Main( ...
                ecgBandPassed, ...                                   % bandpassed signal
                pPeakValue(peakIndex), ...       % current peak powered value
                pPeakValue(peakIndex + 1), ... % next peak powered value
                ( pPeakIndex( peakIndex + 1 ) - pPeakIndex( peakIndex ) ), ...
                poweredSignalThreshold, ...                  % powered signal threshold
                poweredSignalLevel, ...                           % powered signal level
                poweredNoiseLevel, ...                            % powered noise level
                bpPeakValue, ...                      % current bandpassed value
                windowStartPoint, ...                 % bandpassed window start
                windowEndPoint, ...                   % bandpassed window end
                bandPassedSignalThreshold, ...           % bandpassed signal threshold
                bandPassedSignalLevel, ...                    % bandpassed signal level
                bandPassedNoiseLevel, ...                     % bandpassed noise level
                recordInfo.RecordSamplingFrequency );   % recordInfo.RecordSamplingFrequency
            
            % Annotation of the R Point
            [rPoints, rPointDirections, rPointsPoweredIndexes, allSignalDetectedBeatIndex, periodSignalDetectedBeatIndex ] = ClassBeatDetection.RPoint_Store( ...
                ecgPowered, ...                                      % powered signal
                rPoint, ...                                                % detected r point time in sample
                rPoints, ...                                              % detected r points storage
                rPointDirection, ...
                rPointDirections, ...
                pPeakIndex(peakIndex), ...   % detected r point powered index
                rPointsPoweredIndexes, ...                    % detected r point powered indexes storage
                allSignalDetectedBeatIndex, ...                          % detected r point index
                periodSignalDetectedBeatIndex, ...                  % last detected r point index
                recordInfo.RecordSamplingFrequency );                                    % recordInfo.RecordSamplingFrequency
            
            % Threshold Adjustment
            SecondsToWaitUntil = single( 20 );
            if windowStartPoint < ( analysisStartPoint + SecondsToWaitUntil * recordInfo.RecordSamplingFrequency )
                
                % - BandPassed Thresholds
                [ bandPassedSignalThreshold, bandPassedNoiseThreshold ] = ...
                    ClassBeatDetection.ChangeThresholds( bandPassedSignalLevel, bandPassedNoiseLevel );
                
                % - Powered Thresholds
                [ poweredSignalThreshold, poweredNoiseThreshold ] = ...
                    ClassBeatDetection.ChangeThresholds( poweredSignalLevel, poweredNoiseLevel );
                
            else
                
                % Check if beats can not be detected.
                % - last detected beat
                lastDetectedBeatTime = rPoints( allSignalDetectedBeatIndex );
                % - beat detection time control
                lastDetectedBeatSearchInterval = windowStartPoint - SecondsToWaitUntil * recordInfo.RecordSamplingFrequency;
                % check if last detected beat in range
                if ( lastDetectedBeatTime > lastDetectedBeatSearchInterval )
                    
                    % - BandPassed Thresholds
                    [ bandPassedSignalThreshold, bandPassedNoiseThreshold ] = ...
                        ClassBeatDetection.ChangeThresholds( bandPassedSignalLevel, bandPassedNoiseLevel );
                    
                    % - Powered Thresholds
                    [ poweredSignalThreshold, poweredNoiseThreshold ] = ...
                        ClassBeatDetection.ChangeThresholds( poweredSignalLevel, poweredNoiseLevel );
                    
                else
                    
                    % Check amplitudes
                    for minuteInterval = 1 : ( SecondsToWaitUntil - 1 )
                        % The begining and the end of signal interval to check for signal
                        minuteIntervalSignalStart = windowStartPoint - recordInfo.RecordSamplingFrequency * ( minuteInterval );
                        minuteIntervalSignalEnd = windowStartPoint - recordInfo.RecordSamplingFrequency * ( minuteInterval - 1 );
                        % Signal interval
                        minuteIntervalSignal = ecgRaw( double( minuteIntervalSignalStart ) : double( minuteIntervalSignalEnd ) );
                        % Amplitude of the signal
                        minuteIntervalSignalAmp = max( minuteIntervalSignal ) - min( minuteIntervalSignal );
                        % If the amplitude is larger then 0.2 mv, then there are possible missed beats
                        % else patient is in asystole
                        if minuteIntervalSignalAmp >= analysisParameters.MinimumSignalAmplitude
                            isBeatMissed = true;
                            break;
                        else
                            isBeatMissed = false;
                        end
                    end
                    
                    % If there are missed beats
                    if isBeatMissed
                        
                        % Check if thresholds are being changed before,
                        % If thresholds changed before, wait for a minute for test new thresholds.
                        if ( ~isThresoldDecreasedDue2BeatlessInterval ) ||...
                                ( isThresoldDecreasedDue2BeatlessInterval && ( windowStartPoint > ( getThresholdChangedTime + recordInfo.RecordSamplingFrequency ) ) )
                            
                            % Get the time when thresholds are changed
                            getThresholdChangedTime = minuteIntervalSignalEnd;
                            % Rise flag for changed thresholds.
                            isThresoldDecreasedDue2BeatlessInterval = true;
                            
                            if length( ecgBandPassed ) >= ( minuteIntervalSignalEnd + single( 2 )*recordInfo.RecordSamplingFrequency )
                                
                                % Thresholds - Powered
                                [poweredSignalThreshold, ...
                                    poweredSignalLevel,...
                                    poweredNoiseThreshold,...
                                    poweredNoiseLevel] = ClassBeatDetection.InitialThresholds ...
                                    ( ecgPowered ( double( minuteIntervalSignalEnd ) : double( minuteIntervalSignalEnd + single( 2 )*recordInfo.RecordSamplingFrequency ) ) );
                                
                                % Thresholds - BandPassed
                                [bandPassedSignalThreshold, ...
                                    bandPassedSignalLevel,...
                                    bandPassedNoiseThreshold,...
                                    bandPassedNoiseLevel] = ClassBeatDetection.InitialThresholds ...
                                    ( ecgBandPassed ( double( minuteIntervalSignalEnd ) : double( minuteIntervalSignalEnd + single( 2 )*recordInfo.RecordSamplingFrequency ) ) );
                                
                            else
                                
                                [poweredSignalThreshold, ...
                                    poweredSignalLevel,...
                                    poweredNoiseThreshold,...
                                    poweredNoiseLevel] = ClassBeatDetection.InitialThresholds ...
                                    ( ecgPowered ( double( minuteIntervalSignalEnd ) : double( end ) ) );
                                
                                % Thresholds - BandPassed
                                [bandPassedSignalThreshold, ...
                                    bandPassedSignalLevel,...
                                    bandPassedNoiseThreshold,...
                                    bandPassedNoiseLevel] = ClassBeatDetection.InitialThresholds ...
                                    ( ecgBandPassed ( double( minuteIntervalSignalEnd ) : double( end ) ) );
                                
                            end
                            
                        end
                        
                    end
                    
                end
                
            end
            
        end
        
    end
    
    % remove unnecessary indexes
    rPoints( rPoints == 1 ) = [ ];
    rPointDirections( abs( rPointDirections ) < 1 ) = [ ];
    
end


%% OUTPUTS

qrsComplexes.R = rPoints;
qrsComplexes.Type = rPointDirections;


end
