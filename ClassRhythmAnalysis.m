classdef ClassRhythmAnalysis
    
    %"ClassRhythmAnalysis.m" class consists rhythm analysis functions.
    %
    % > CalculateHeartRate
    % > AbnormalRhythmRunDetection
    % > TimeBasedAnalysis
    % > ActivityBasedAnalysis
    % > PauseDetection
    % > AsystoleDetection
    
    %% PROPERTIES
    
    properties
        
        %
        
    end
    
    
    %% STATIC METHODS
    
    methods (Static)
        
        
        
        %% Heart Rate Calculation
        
        function [heartRateBPM] = CalculateHeartRate(rPoints, samplingFreq)
            
            % Heart rate calculation.
            %
            % [heartRateBPM] = CalculateHeartRate(rPoints, samplingFreq)
            %
            % <<< Function Inputs >>>
            %   single[n,1] rPoints
            %   single[n,1] samplingFre
            %
            % <<< Function Outputs >>>
            %   single[n,1] heartRateBPM
            
            % heart rate calculation
            heartRateBPM = single ( 60 ./ (diff(rPoints) / samplingFreq) );
            % rounding results
            heartRateBPM = round(heartRateBPM);
            
        end
        
        
        %% Tachycardia / Bradycardia Run Detection
        
        function [bradyRun, tachyRun] = AbnormalRhythmRunDetection( heartRateBPM, qrsComplexes, bradyLimit, tachyLimit, asystoleLimit, recordStartTime, samplingFreq )
            
            % Bradycardia and Tachycardia run detection.
            %
            % [bradyRun, tachyRun] = AbnormalRhythmRunDetection( heartRateBPM, qrsComplexes, bradyLimit, tachyLimit, recordStartTime, samplingFreq )
            %
            % <<< Function Inputs >>>
            %   single[n,1] heartRateBPM
            %   struct qrsComplexes
            %   single bradyLimit
            %   single tachyLimit
            %   datetime recordStartTime
            %   single samplingFreq
            %
            % <<< Function Outputs >>>
            %   struct bradyRun
            % - run.1 = start time of the run in sample
            % - run.2 = end time of the run in sample
            % - run.3 = duration of the run in beats
            %-  run.4 = heart rate of the run
            %   struct tachyRun
            % - run.1 = start time of the run in sample
            % - run.2 = end time of the run in sample
            % - run.3 = duration of the run in beats
            %-  run.4 = heart rate of the run
            %
            
            % beats
            rPoints = qrsComplexes.R;
            
            %- Bradycardia Run Info Storage
            bradyRunCounter = single( 0 );
            bradyRunArrayStart = zeros( fix( 0.2 * length( rPoints ) ), 1 );
            bradyRunArrayEnd = zeros( fix( 0.2 * length( rPoints ) ), 1 );
            bradycardiaRunBeatDuration = zeros( fix( 0.2 * length( rPoints ) ), 1 );
            
            %- Tachycardia Run Info Storage
            tachyRunCounter = single( 0 );
            tachyRunArrayStart = zeros( fix( 0.2 * length( rPoints ) ), 1 );
            tachyRunArrayEnd = zeros( fix( 0.2 * length( rPoints ) ), 1 );
            tachycardiaRunBeatDuration = zeros( fix( 0.2 * length( rPoints ) ), 1 );
            
            % Flags for detected runs
            tachyRunStarted = false;
            bradyRunStarted = false;
            
            %- Search Parameters
            minRhythmChangeCount = single( 4 );
            
            % Bradycardia / Tachycardia Run Detection Algorithm
            for beatIndex = minRhythmChangeCount : 1 : numel(heartRateBPM)
                
                % calculation of mean qrs interval
                meanQRS = mean ( heartRateBPM ( double( beatIndex - (minRhythmChangeCount - 1 ) ) : double( 1 ) : double ( beatIndex ) ) );
                
                % irregular condition
                irregularCondition = ( meanQRS <= bradyLimit ) || ( meanQRS >= tachyLimit );
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % DETECTION OF THE END OF THE RUN AT THE END OF THE SIGNAL
                % IF THERE IS NON-COMPLETED RUN
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                % if run did not end until the end of the signal
                %- check if the sample is the end of the signal
                if ( beatIndex == numel(heartRateBPM) )
                    
                    % search for the end of the run
                    for searchEnd = beatIndex: -1: 1
                        
                        %- brady run end detection
                        if bradyRunStarted
                            if heartRateBPM(searchEnd) <= bradyLimit
                                if ( searchEnd - bradyRunArrayStart( bradyRunCounter ) + 1) >= minRhythmChangeCount
                                    bradyRunArrayEnd( bradyRunCounter ) = searchEnd;
                                    bradycardiaRunBeatDuration( bradyRunCounter ) = ( searchEnd - bradyRunArrayStart( bradyRunCounter ) + 1);
                                    break;
                                else
                                    if bradyRunStarted
                                        bradyRunArrayStart( bradyRunCounter ) = 0;
                                        bradyRunCounter = bradyRunCounter - 1;
                                        bradyRunStarted= false;
                                    end
                                    break;
                                end
                            end
                            
                            %- tachy run end detection
                        elseif tachyRunStarted
                            if heartRateBPM(searchEnd) >= tachyLimit
                                if ( searchEnd - tachyRunArrayStart( tachyRunCounter ) + 1) >= minRhythmChangeCount
                                    tachyRunArrayEnd( tachyRunCounter ) = searchEnd;
                                    tachycardiaRunBeatDuration( tachyRunCounter ) = ( searchEnd - tachyRunArrayStart( tachyRunCounter ) + 1);
                                    break;
                                else
                                    if tachyRunStarted
                                        tachyRunArrayStart( tachyRunCounter ) = 0;
                                        tachyRunCounter = tachyRunCounter - 1;
                                        tachyRunStarted= false;
                                    end
                                    break;
                                end
                            end
                        end
                        
                        
                    end % for searchStart = beatIndex: -1: 1
                    
                end % if ( beatIndex == numel(heartRateBPM) )
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % DETECTION OF THE BEGINING OF THE RUN
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                % condition 1: irregularity
                % condition 2 : a run is not started
                % condition 3 : current beat is not the last beat
                if irregularCondition &&...
                        ~bradyRunStarted && ...
                        ~tachyRunStarted && ...
                        ( beatIndex ~= numel(heartRateBPM) )
                    
                    % run type determination | rise flag
                    % bradycardia
                    if (meanQRS <= bradyLimit) && all ( heartRateBPM( double( beatIndex - ( minRhythmChangeCount - 1 ) ) : double( beatIndex ) ) <= bradyLimit )
                        bradyRunStarted = true;
                    end
                    % tachycardia
                    if (meanQRS >= tachyLimit) && all ( heartRateBPM( double( beatIndex - ( minRhythmChangeCount - 1 ) ) : double( beatIndex ) ) >= tachyLimit )
                        tachyRunStarted = true;
                    end
                    
                    % search for the begining of the run
                    for searchStart = beatIndex : -1: 1
                        
                        %- brady run detection
                        if bradyRunStarted
                            if ( heartRateBPM( searchStart ) > bradyLimit ) ...
                                    || any( heartRateBPM( double( beatIndex - 2 ) : double( beatIndex ) ) <= asystoleLimit ) % gürültü | asistol olmasý durumunda
                                % annotation of the begining
                                bradyRunCounter = bradyRunCounter + 1;
                                if ( heartRateBPM( searchStart + 1 ) <= asystoleLimit )
                                    bradyRunArrayStart( bradyRunCounter ) = searchStart + 2;
                                    if bradyRunArrayStart( bradyRunCounter ) > length( qrsComplexes.R ); bradyRunArrayStart( bradyRunCounter ) = length( qrsComplexes.R ); end
                                else
                                    bradyRunArrayStart( bradyRunCounter ) = searchStart + 1;
                                    if bradyRunArrayStart( bradyRunCounter ) > length( qrsComplexes.R ); bradyRunArrayStart( bradyRunCounter ) = length( qrsComplexes.R ); end
                                end
                                % if the difference between the begining of
                                % the new run and the previous one is lower
                                % than the minComplexDuration; it means
                                % that previous run is continuing
                                if ~all( ~bradyRunArrayEnd )
                                    if ( ( searchStart + 1) -  bradyRunArrayEnd( bradyRunCounter - 1 ) ) <= minRhythmChangeCount - 1
                                        if all( heartRateBPM( double( bradyRunArrayEnd( bradyRunCounter - 1 ) ) : double( bradyRunArrayStart( bradyRunCounter ) ) ) > asystoleLimit )
                                            bradyRunArrayStart( bradyRunCounter ) = 0;
                                            bradyRunArrayEnd( bradyRunCounter - 1 ) = 0;
                                            bradycardiaRunBeatDuration( bradyRunCounter - 1 ) = 0;
                                            bradyRunCounter = bradyRunCounter - 1;
                                        end
                                    end
                                end
                                break; % annotate the begining
                            elseif (searchStart == 1) && all( ~bradyRunArrayStart)
                                bradyRunCounter = bradyRunCounter + 1;
                                bradyRunArrayStart( bradyRunCounter ) = 1;
                            end
                            
                            %- tachy run detection
                        elseif tachyRunStarted
                            if heartRateBPM( searchStart ) < tachyLimit
                                % annotation of the begining
                                tachyRunCounter = tachyRunCounter + 1;
                                tachyRunArrayStart( tachyRunCounter ) = searchStart + 1;
                                if tachyRunArrayStart( tachyRunCounter ) > length( qrsComplexes.R ); tachyRunArrayStart( tachyRunCounter ) = length( qrsComplexes.R ); end
                                % if the difference between the begining of
                                % the new run and the previous one is lower
                                % than the minComplexDuration; it means
                                % that previous run is continuing
                                if ~all( ~tachyRunArrayEnd )
                                    if ( ( searchStart + 1) -  tachyRunArrayEnd( tachyRunCounter - 1 ) ) <= minRhythmChangeCount - 1
                                        if all( heartRateBPM( double( tachyRunArrayEnd( tachyRunCounter - 1 ) ) : double( tachyRunArrayStart( tachyRunCounter ) ) ) > asystoleLimit )
                                            tachyRunArrayStart( tachyRunCounter ) = 0;
                                            tachyRunArrayEnd( tachyRunCounter - 1 ) = 0;
                                            tachycardiaRunBeatDuration( tachyRunCounter - 1 ) = 0;
                                            tachyRunCounter = tachyRunCounter - 1;
                                        end
                                    end
                                end
                                break; % annotate the begining
                            elseif (searchStart == 1) && all( ~tachyRunArrayStart)
                                tachyRunCounter = tachyRunCounter + 1;
                                tachyRunArrayStart( tachyRunCounter ) = 1;
                            end
                        end % bradyRunStarted | tachyRunStarted
                        
                    end % for searchStart = beatIndex: -1: 1
                    
                end % if irregularCondition
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % DETECTION OF THE END OF THE RUN
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                % condition 1: irregularity
                % condition 2 : a run is started and current bpm value is off the limits
                % condition 3 : current beat is not the last beat
                checkBeatStart = beatIndex - 2; if checkBeatStart < minRhythmChangeCount; checkBeatStart = minRhythmChangeCount; end
                checkBeatEnd = beatIndex + 2; if checkBeatEnd > length( rPoints ); checkBeatEnd = length( rPoints ); end
                
                % check if any run is ended
                % - 1
                runEndCondition = ~irregularCondition && ...
                    ( ( ( bradyRunStarted ) && ( sum ( heartRateBPM( double( checkBeatStart ) : double( checkBeatEnd ) ) > bradyLimit ) >= minRhythmChangeCount ) ) ...
                    ||...
                    ( ( tachyRunStarted ) && ( sum ( heartRateBPM( double( checkBeatStart ) : double( checkBeatEnd ) ) < tachyLimit ) >= minRhythmChangeCount ) ) );
                % -2
                runEndCondition = runEndCondition || ( heartRateBPM( beatIndex ) < asystoleLimit );
                
                if runEndCondition
                    
                    % search for the end of the run
                    for searchEnd = ( beatIndex - 1 ) : -1: 1
                        %- brady run end detection
                        if bradyRunStarted
                            if heartRateBPM(searchEnd) <= bradyLimit
                                if ( searchEnd - bradyRunArrayStart(bradyRunCounter) + 1 ) >= minRhythmChangeCount
                                    bradyRunArrayEnd( bradyRunCounter ) = searchEnd;
                                    bradycardiaRunBeatDuration( bradyRunCounter ) = ( searchEnd - bradyRunArrayStart(bradyRunCounter) + 1);
                                    break;
                                else
                                    if bradyRunStarted
                                        bradyRunArrayStart( bradyRunCounter ) = 0;
                                        bradyRunCounter = bradyRunCounter - 1;
                                        bradyRunStarted= false;
                                    end
                                end
                            end
                            
                            %- tachy run end detection
                        elseif tachyRunStarted
                            if heartRateBPM(searchEnd) >= tachyLimit
                                if ( searchEnd - tachyRunArrayStart(tachyRunCounter) + 1) >= minRhythmChangeCount
                                    tachyRunArrayEnd( tachyRunCounter ) = searchEnd;
                                    tachycardiaRunBeatDuration( tachyRunCounter ) = ( searchEnd - tachyRunArrayStart(tachyRunCounter) + 1);
                                    break;
                                else
                                    if tachyRunStarted
                                        tachyRunArrayStart( tachyRunCounter ) = 0;
                                        tachyRunCounter = tachyRunCounter - 1;
                                        tachyRunStarted= false;
                                    end
                                end
                            end
                        end
                    end % for searchStart = beatIndex: -1: 1
                    
                    tachyRunStarted = false;
                    bradyRunStarted = false;
                    
                end % ~irregularCondition &&...
                
            end % for beatIndex = meanComplexAmount : 1 : numel(heartRateBPM)
            
            % TACHYCARDIA PACKET
            [tachyRun] = PacketRegularHeartBeatRun( heartRateBPM, ...
                qrsComplexes, ...
                recordStartTime, ...
                samplingFreq, ...
                tachyRunArrayStart( double( 1 ) : double( tachyRunCounter ) ), ...
                tachyRunArrayEnd( double( 1 ) : double( tachyRunCounter ) ), ...
                tachycardiaRunBeatDuration( double( 1 ) : double( tachyRunCounter ) ) );
            
            % BRADYCARDIA PACKET
            [bradyRun] = PacketRegularHeartBeatRun( heartRateBPM, ...
                qrsComplexes, ...
                recordStartTime, ...
                samplingFreq, ...
                bradyRunArrayStart( double( 1 ) : double( bradyRunCounter ) ), ...
                bradyRunArrayEnd( double( 1 ) : double( bradyRunCounter ) ), ...
                bradycardiaRunBeatDuration( double( 1 ) : double( bradyRunCounter ) ) );
            
        end % [bradyRun, tachyRun] = DetectRuns(heartRateBPM, heartRateTime, bradyLimit, tachyLimit)
        
        
        %% Time Based Rhythm Analysis
        
        function [ GeneralPeriod, ActivePeriod, PassivePeriod  ] = TimeBasedAnalysis( qrsComplexes, recordInfo, analysisParameters )
            
            % Time based rhythm analysis.
            %
            % [ GeneralPeriod, ActivePeriod, PassivePeriod  ] = TimeBasedAnalysis( signal, rPoints, recordInfo, analysisParameters )
            %
            % <<< Function Inputs >>>
            %   single signal
            %   single rPoints
            %   struct recordInfo
            %   struct analysisParameters
            %
            % <<< Function Outputs >>>
            %   struct GeneralPeriod
            %   struct ActivePeriod
            %   struct PassivePeriod
            %   - period.MinimumHeartRate
            %   - period.MinimumHeartRateTime
            %   - period.MaximumHeartRate
            %   - period.MaximumHeartRateTime
            %   - period.AverageHeartRate
            
            if isempty(qrsComplexes.R)
                
                GeneralPeriod = [ ];
                ActivePeriod = [ ];
                PassivePeriod = [ ];
                
            else
                
                % Initialization
                % - recordInfo
                recordStartTime = recordInfo.RecordStartTime;
                samplingFreq = recordInfo.RecordSamplingFrequency;
                % - analysis parameters
                activePeriod = analysisParameters.ActivePeriod;
                % - mean heart rate based on morphology
                normalQRSHeartRate = qrsComplexes.HeartRate( qrsComplexes.BeatMorphology == min( qrsComplexes.BeatMorphology ) );
                normalQRSHeartRate = mean( normalQRSHeartRate( 2:end ) );
                
                % Heart Rate Calculation
                heartRate = qrsComplexes.HeartRate;
                
                % Noise BPM
                if ~isempty( analysisParameters.IntervalWithoutSignal )
                    for intervalIndex = 1 : int32( numel( analysisParameters.IntervalWithoutSignal ) )
                        % End
                        startPoint = ...
                            ClassDatetimeCalculation.Substraction( analysisParameters.IntervalWithoutSignal( intervalIndex ).StartTime, recordInfo.RecordStartTime );
                        startPoint = ...
                            double( ( ClassTypeConversion.ConvertDuration2Miliseconds( startPoint ) / 1000 ) * recordInfo.RecordSamplingFrequency );
                        % End
                        endPoint = ...
                            ClassDatetimeCalculation.Substraction( analysisParameters.IntervalWithoutSignal( intervalIndex ).EndTime, recordInfo.RecordStartTime );
                        endPoint = ...
                            double( ( ClassTypeConversion.ConvertDuration2Miliseconds( endPoint ) / 1000 ) * recordInfo.RecordSamplingFrequency );
                        % beat after the noise
                        firstBeatAfterNoise = find( ( qrsComplexes.R > round( mean( [ startPoint; endPoint ] ) ) ) , 1, 'first' );
                        % give that beat previous heart rate
                        if firstBeatAfterNoise > 1
                            heartRate( firstBeatAfterNoise ) = normalQRSHeartRate;
                        end
                    end
                end; clear intervalIndex endPoint firstBeatAfterNoise
                
                % HEART RATE CHANGE
                % - initialization
                heartRateChange = zeros( length( heartRate ), 1, 'single' );
                % - assessment
                for beatIndex = 2 : length( qrsComplexes.R )                
                    % - current beat bpm
                    currentHeartRate = heartRate( beatIndex );
                    % - mean heart rate
                    heartRateChange( beatIndex ) = currentHeartRate / normalQRSHeartRate;
                    % - absolute heart rate change
                    currentHeartRateChange = abs( heartRateChange( beatIndex ) - 1 );
                    % normal heart rate calculation
                    if ( currentHeartRateChange < 0.25 ) || ( ( beatIndex > 5 ) && all( abs( heartRateChange( beatIndex - 5 : beatIndex ) - 1 ) > 0.25 ) )
                        % normal qrs heart rate change
                        normalQRSHeartRate = normalQRSHeartRate * 0.25 + currentHeartRate * 0.75;
                    end
                    
                end; clear absHeartRateChange beatIndex currentHeartRate normalQRSHeartRate
                                
                % Beat Analysis
                DetailedBeatAnalysis = BeatAnalysis(qrsComplexes.R, heartRate, heartRateChange, recordStartTime, activePeriod.StartTime, activePeriod.EndTime, samplingFreq);
                % Active Period
                ActivePeriod = PeriodBasedRhythmAnalysis( DetailedBeatAnalysis, 'ActivePeriod' );
                % General Period
                GeneralPeriod = PeriodBasedRhythmAnalysis( DetailedBeatAnalysis, 'GeneralPeriod' );
                % Passive Period
                PassivePeriod = PeriodBasedRhythmAnalysis( DetailedBeatAnalysis, 'PassivePeriod' );
                
            end
            
        end
        
        
        %% Activity Based Rhythm Analysis
        
        function [ activityBasedHighHeartRate, tachycardiaRuns ] = ActivityBasedAnalysis( tachycardiaRuns, activityPeriods, tachycardiaThresholds )
            
            % Activity based rhythm analysis.
            %
            % [ activityBasedHighHeartRate, tachycardiaRuns ] = ActivityBasedAnalysis( tachycardiaRuns, activityPeriods, tachycardiaThresholds )
            %
            % <<< Function Inputs >>>
            %   struct tachycardiaRuns
            %   struct activityPeriods
            %   struct tachycardiaThresholds
            %
            % <<< Function Outputs >>>
            %   struct ActivityBasedHighHeartRate
            %   struct tachycardiaRuns
            
            % determination of the number of detected activities
            numberActivityPeriods = single( numel( activityPeriods ) );
            
            % datetime conversion
            tachycardiaRunsStartTime = tachycardiaRuns.StartTime;
            
            % error margin for activity detection
            errorMargin = minutes(0.5);
            
            % store overlap
            overlapTachycardiaRuns = false( numel( tachycardiaRuns.Duration ),1 );
            
            % determination of the overlap
            for searchForOverlap = 1 : numberActivityPeriods
                
                % determination of activity interval
                activityStartDatetime = ClassTypeConversion.ConvertChar2Datetime( activityPeriods(searchForOverlap,1).StartTime ) - errorMargin;
                activityEndDatetime  = ClassTypeConversion.ConvertChar2Datetime( activityPeriods(searchForOverlap,1).EndTime ) + errorMargin;
                
                % overlaped runs
                overlapedRuns = isbetween(tachycardiaRunsStartTime, activityStartDatetime, activityEndDatetime) & ...
                    ( tachycardiaRuns.AverageHeartRate <= tachycardiaThresholds.ActivityThreshold );
                
                overlapTachycardiaRuns = overlapTachycardiaRuns | overlapedRuns;
                
            end
            
            if ~isempty( find( overlapTachycardiaRuns, true )  )
                
                % packet activityBasedHighHeartRate
                activityBasedHighHeartRate.StartTime = tachycardiaRuns.StartTime( overlapTachycardiaRuns, : );
                activityBasedHighHeartRate.EndTime = tachycardiaRuns.EndTime( overlapTachycardiaRuns, : );
                activityBasedHighHeartRate.Duration = tachycardiaRuns.Duration( overlapTachycardiaRuns );
                activityBasedHighHeartRate.AverageHeartRate = tachycardiaRuns.AverageHeartRate( overlapTachycardiaRuns );
                
                % packet new tachycardiaRuns
                tachycardiaRuns.StartTime( overlapTachycardiaRuns, : ) = [ ];
                tachycardiaRuns.EndTime( overlapTachycardiaRuns, : ) = [ ];
                tachycardiaRuns.Duration( overlapTachycardiaRuns ) = [ ];
                tachycardiaRuns.AverageHeartRate( overlapTachycardiaRuns ) = [ ];
                
                if isempty(tachycardiaRuns.Duration)
                    tachycardiaRuns = [ ];
                end
                
            else
                
                activityBasedHighHeartRate = [ ];
                
            end
            
        end
        
        
        %% Pause Detection
        
        function [ pauseRun, missingInterval ] = PauseDetection( ecgSignal, qrsComplexes, signalLength, recordInfo, analysisParameters, analysisChannel )
            
            % Pause detection.
            %
            % [ pauseRun] = PauseDetection(rPoints, recordInfo, analysisParameters)
            %
            % <<< Function Inputs >>>
            %   single[n,1] rPoints
            %   struct recordInfo
            %   struct analysisParameters
            %
            % <<< Function Outputs >>>
            %   struct pauseRun
            %   - .StartTime
            %   - .EndTime
            %   - .Duration
            
            %RR Interval Calculation
            % adjust
            if ~isempty( qrsComplexes.R )
                rPoints = [ 1; qrsComplexes.R ];
            else
                rPoints = [ ];
            end
            
            % Interval Without Signal Addition
            if ~isempty( qrsComplexes.R )
                if ~isempty( analysisParameters.IntervalWithoutSignal )
                    % Put an temp r point at the end of the interval without signal
                    for withoutSignalIndex = 1 : numel( analysisParameters.IntervalWithoutSignal )
                        % start time > start point
                        startPoint = seconds( analysisParameters.IntervalWithoutSignal( withoutSignalIndex ).StartTime - recordInfo.RecordStartTime );
                        startPoint = max( double( round( ( startPoint ) * recordInfo.RecordSamplingFrequency ) - recordInfo.RecordSamplingFrequency ), double( 1 ) );
                        % end time > end point
                        endPoint = seconds( analysisParameters.IntervalWithoutSignal( withoutSignalIndex ).EndTime - recordInfo.RecordStartTime );
                        endPoint = min( double( round( ( endPoint ) * recordInfo.RecordSamplingFrequency ) + recordInfo.RecordSamplingFrequency ), double( signalLength ) );
                        % random r points
                        randomRPoints = transpose( double( startPoint ) : double( recordInfo.RecordSamplingFrequency ) : double( endPoint ) );
                        % import temp r Point
                        numbRPoint = length( rPoints );
                        rPoints( double( numbRPoint + 1 ) : double( numbRPoint + length( randomRPoints ) ) ) = randomRPoints;
                    end
                    rPoints = sort( unique( rPoints ) );
                end
            else
                rPoints = [ ];
            end
            
            % RR Intervals
            rrIntervals = diff( rPoints );
            
            % Asystole / Pause Threshold in terms of BPM
            lowbpmThresholdSample =  ( 60 / analysisParameters.Bradycardia.ClinicThreshold ) * recordInfo.RecordSamplingFrequency;
            asystoleThresholdSample = fix ( single( analysisParameters.Asystole.ClinicThreshold ) * recordInfo.RecordSamplingFrequency * 0.001 );
            
            % Pause Condition
            LowBPMCondition = ~isempty( find( ( rrIntervals >= lowbpmThresholdSample ) & ( rrIntervals < asystoleThresholdSample ), 1 ) );
            
            % Pause Runs
            if LowBPMCondition
                
                % detection pause beat
                lowbpmBeat = 1 + find( ( rrIntervals >= lowbpmThresholdSample ) & ( rrIntervals < asystoleThresholdSample ) );
                lowbpmBeat( lowbpmBeat < 2 ) = [ ];
                lowbpmBeatPoints = rPoints( lowbpmBeat );
                
                % real paused beat points
                [ ~, ~, lowbpmBeat ] = intersect( lowbpmBeatPoints, qrsComplexes.R );
                lowbpmBeat( lowbpmBeat < 2 ) = [ ];
                
                % noise beat
                noiseBased = zeros( length( lowbpmBeat ), 1, 'logical' );
                
                % pause signal
                for runIndex = length( lowbpmBeat ) : - 1 : 1
                    % signal points
                    lowbpmSignalStartPoint = qrsComplexes.EndPoint( lowbpmBeat( runIndex ) -1 ) + recordInfo.RecordSamplingFrequency * 0.5;
                    lowbpmSignalEndPoint = qrsComplexes.StartPoint( lowbpmBeat( runIndex ) ) -  recordInfo.RecordSamplingFrequency * 0.5;
                    % get signal
                    lowbpmSignal = ecgSignal.( analysisChannel )( double( lowbpmSignalStartPoint ) : double( lowbpmSignalEndPoint ) );
                    % ref qrs amplitudes
                    if lowbpmBeat( runIndex ) > 3
                        refQRSAmplitude = mean( qrsComplexes.QRSAmplitude( lowbpmBeat( runIndex ) -  3 : lowbpmBeat( runIndex ) -  1 ) ) * 0.75;
                    else
                        refQRSAmplitude = qrsComplexes.QRSAmplitude( lowbpmBeat( runIndex ) ) * 0.75;
                    end
                    if refQRSAmplitude > 0.25; refQRSAmplitude = 0.25; end
                    % the evaluation
                    if ( max( lowbpmSignal ) - min( lowbpmSignal ) ) > refQRSAmplitude
                        %                         close all; plot( lowbpmSignal )
                        noiseBased( runIndex ) = true;
                    else
                        %                         close all; plot( lowbpmSignal )
                        %                         pause(0.1)
                    end
                end
                
                % missingBeat
                missingBeat = lowbpmBeat( noiseBased );
                lowbpmBeat = lowbpmBeat( ~noiseBased );
                
                if ~isempty(missingBeat)
                    % initialization
                    qrsComplexes.R( length( qrsComplexes.R ) + 1 ) = length( ecgSignal.( analysisChannel ) );
                    % packet
                    % - start
                    missingInterval.StartPoint = double( qrsComplexes.R( missingBeat - 1 ) );
                    missingInterval.StartPoint( missingInterval.StartPoint > length( ecgSignal.( analysisChannel ) ) ) = length( ecgSignal.( analysisChannel ) );
                    % - end
                    missingInterval.EndPoint = double( qrsComplexes.R( missingBeat + 1 ) );
                    missingInterval.EndPoint( missingInterval.EndPoint > length( ecgSignal.( analysisChannel ) ) ) = length( ecgSignal.( analysisChannel ) );
                    % - duration
                    missingInterval.Duration = qrsComplexes.R( missingBeat ) - qrsComplexes.R( missingBeat - 1 );
                    % - heart rate / initialization
                    missingInterval.AveragedHeartRate = single( zeros( numel(missingInterval.Duration), 1 ) );
                    
                else
                    missingInterval = [ ];
                end
                
                % packet
                if ~isempty( lowbpmBeat )
                    % get pause beats from low bpms
                    lowbpmHeartRates = qrsComplexes.HeartRate( lowbpmBeat );
                    pauseBeats = lowbpmBeat( lowbpmHeartRates <= 60 / ( analysisParameters.Pause.ClinicThreshold / 1000 ) );
                    % packet
                    if ~isempty( pauseBeats )
                        % - start
                        pauseRun.StartTime = ClassDatetimeCalculation.Summation( recordInfo.RecordStartTime, qrsComplexes.R( pauseBeats - 1 ) / recordInfo.RecordSamplingFrequency );
                        % - end
                        pauseRun.EndTime = ClassDatetimeCalculation.Summation( recordInfo.RecordStartTime, qrsComplexes.R( pauseBeats ) / recordInfo.RecordSamplingFrequency );
                        % - duration
                        pauseRun.Duration = fix( ( ( qrsComplexes.R( pauseBeats ) - qrsComplexes.R( pauseBeats - 1 ) ) * 1000 ) / recordInfo.RecordSamplingFrequency );
                        % - bpm
                        pauseRun.AverageHeartRate = qrsComplexes.HeartRate( pauseBeats );
                    else
                        pauseRun = [ ];
                    end
                else
                    pauseRun = [ ];
                end
                
            else
                
                missingInterval = [ ];
                pauseRun = [ ];
                
            end
            
        end
        
        
        %% Asystole Detection
        
        function [ asystoleRun, missingInterval ] = AsystoleDetection( ecgSignal, rPoints, recordInfo, analysisParameters, analysisChannel )
            
            % Asystole detection.
            %
            % [ asystoleRun, missingInterval ] = AsystoleDetection( ecgSignal, rPoints, recordInfo, analysisParameters )
            %
            % <<< Function Inputs >>>
            %   struct ecgSignal
            %   single[n,1] rPoints
            %   struct recordInfo
            %   struct analysisParameters
            %
            % <<< Function Outputs >>>
            %   struct asystoleRun
            %   - .StartTime
            %   - .EndTime
            %   - .Duration
            %   struct missingInterval
            %   - .StartTime
            %   - .EndTime
            %   - .Duration
            %
            
            %RR Interval Calculation
            if ~isempty( rPoints )
                rPoints = [ 1; rPoints ];
            end
            
            % Interval Without Signal Addition
            if ~isempty( rPoints )
                if ~isempty( analysisParameters.IntervalWithoutSignal )
                    % Put an temp r point at the end of the interval without signal
                    for withoutSignalIndex = 1 : numel( analysisParameters.IntervalWithoutSignal )
                        % start time > start point
                        startPoint = seconds( analysisParameters.IntervalWithoutSignal( withoutSignalIndex ).StartTime - recordInfo.RecordStartTime );
                        startPoint = max( double( round( ( startPoint ) * recordInfo.RecordSamplingFrequency ) - recordInfo.RecordSamplingFrequency ), double( 1 ) );
                        % end time > end point
                        endPoint = seconds( analysisParameters.IntervalWithoutSignal( withoutSignalIndex ).EndTime - recordInfo.RecordStartTime );
                        endPoint = min( double( round( ( endPoint ) * recordInfo.RecordSamplingFrequency ) + recordInfo.RecordSamplingFrequency ), double( length( ecgSignal.( analysisChannel ) ) ) );
                        % random r points
                        randomRPoints = transpose( double( startPoint ) : double( recordInfo.RecordSamplingFrequency ) : double( endPoint ) );
                        % import temp r Point
                        numbRPoint = length( rPoints );
                        rPoints( double( numbRPoint + 1 ) : double( numbRPoint + length( randomRPoints ) ) ) = randomRPoints;
                    end
                    rPoints = sort( unique( rPoints ) );
                end
            end
            
            % RR Intervals
            rrIntervals = diff( rPoints );
            
            % Asystole Threshold in terms of BPM
            asystoleThresholdSample = fix ( single(analysisParameters.Asystole.ClinicThreshold) * recordInfo.RecordSamplingFrequency * 0.001 );
            
            % Asystole Condition
            AsystoleCondition = ~isempty( find( (rrIntervals >= asystoleThresholdSample), 1 ) );
            
            % Asystole Runs
            if AsystoleCondition
                % detection asysyole beat
                asystoleBeat = find(rrIntervals >= asystoleThresholdSample);
                
                % check other channels
                [asystoleBeat, missingBeat] = CheckChannelsForAsystole( ecgSignal, rPoints, asystoleBeat, recordInfo, analysisChannel );
                
                if ~isempty(missingBeat)
                    % packet
                    % - start
                    missingInterval.StartPoint = double( rPoints( missingBeat ) );
                    missingInterval.StartPoint( missingInterval.StartPoint > length( ecgSignal.( analysisChannel ) ) ) = length( ecgSignal.( analysisChannel ) );
                    % - end
                    missingInterval.EndPoint = double( rPoints( missingBeat + 1 ) );
                    missingInterval.EndPoint( missingInterval.EndPoint > length( ecgSignal.( analysisChannel ) ) ) = length( ecgSignal.( analysisChannel ) );
                    % - duration
                    missingInterval.Duration = rPoints( missingBeat + 1) - rPoints( missingBeat);
                    % - heart rate / initialization
                    missingInterval.AveragedHeartRate = single( zeros( numel(missingInterval.Duration), 1 ) );
                    
                else
                    missingInterval = [ ];
                end
                
                if ~isempty(asystoleBeat)
                    % time
                    rPointTimes = ( rPoints / recordInfo.RecordSamplingFrequency );
                    % packet
                    asystoleRun.StartTime = ClassDatetimeCalculation.Summation(recordInfo.RecordStartTime, rPointTimes( asystoleBeat ) );
                    asystoleRun.EndTime = ClassDatetimeCalculation.Summation(recordInfo.RecordStartTime, rPointTimes( asystoleBeat + 1) );
                    asystoleRun.Duration = fix( ( rPointTimes( asystoleBeat + 1) - rPointTimes( asystoleBeat) ) * 1000 );
                    asystoleRun.AverageHeartRate = single( zeros( numel(asystoleRun.Duration), 1 ) );
                else
                    asystoleRun = [ ];
                end
                
            else
                
                missingInterval = [ ];
                asystoleRun = [ ];
                
            end
            
        end
        
        
    end
    
    
end


%% Packet Run : Regular Heart Beat

% Packeting the abnormal heart rate run.
%
% [run] = PacketRegularHeartBeatRun(heartRate, qrsComplexes, recordStartTime, samplingFreq, runStartBeat, runEndBeat, runBeatDuration)
%
% <<< Function Inputs >>>
%   single[n,1] heartRate
%   struct qrsComplexes
%   string recordStartTime
%   single samplingFreq
%   single[n,1] runStartBeat
%   single[n,1] runEndBeat
%   single[n,1] runBeatDuration
%
% <<< Function Outputs >>>
%   struct run

function [run] = PacketRegularHeartBeatRun(heartRate, qrsComplexes, recordStartTime, samplingFreq, runStartBeat, runEndBeat, runBeatDuration)


% heart rate time
% - start time
initialRunStartBeat = runStartBeat;
runStartBeat = double( runStartBeat - 1 );
runStartBeat( runStartBeat < 1 ) = 1;
beatStartTime = ( qrsComplexes.EndPoint( double( 1 ) : double( end ) ) / samplingFreq );
% - end time
qrsComplexes.T.EndPoint( qrsComplexes.T.EndPoint == 1 ) = qrsComplexes.EndPoint( qrsComplexes.T.EndPoint == 1 );
beatEndTime = ( qrsComplexes.T.EndPoint( double( 1 ) : double( end ) ) / samplingFreq );

% Run Characteristics
if ~isempty(runStartBeat)
    
    % fields
    run.StartTime = ClassDatetimeCalculation.Summation( recordStartTime, beatStartTime(runStartBeat) );
    run.StartBeat = initialRunStartBeat;
    run.EndTime = ClassDatetimeCalculation.Summation( recordStartTime, beatEndTime(runEndBeat) );
    run.EndBeat = runEndBeat;
    run.Duration = runBeatDuration;
    run.AverageHeartRate = PeriodAverageHeartRate( heartRate, initialRunStartBeat, runEndBeat );
    % beat flags
    run.BeatFlag = zeros( length( qrsComplexes.R ), 1, 'logical' );
    for i = 1 : length( run.StartBeat )
        run.BeatFlag( double( run.StartBeat( i ) ) : double( run.EndBeat( i ) ) ) = true;
    end
else
    run = [ ];
    
end

end


%% Average Heart Rate Calculation

% Calculation of the averaged heart rate in a run.
%
% [runHeartRate] = PeriodAveragedHeartRate( heartRate, runStartTime, runEndTime )
%
% <<< Function Inputs >>>
%   single[n,1]  heartRate
%   single[n,1]  runStartTime
%   single[n,1]  runEndTime
%
% <<< Function Outputs >>>
%   single[n,1]  runHeartRate

function [runHeartRate] = PeriodAverageHeartRate( heartRate, runStartTime, runEndTime )

% Initialization
runHeartRate = single( zeros( length( runStartTime ), 1 ) );
% Calculation
for runIndex = single( 1 : numel(runStartTime) )
    runHeartRate(runIndex) = ceil( mean(heartRate( double( runStartTime(runIndex) ) : double( runEndTime(runIndex) ) ) ) );
end

end


%% Detailed Beat Analysis

% Detailed beat analysis.
%
% DetailedBeatAnalysis = BeatAnalysis(beatPoints, heartRateBPM, recordStartTime, activePeriodStart, activePeriodEnd, samplingFreq)
%
% <<< Function Inputs >>>
%   single[n,1]  beatPoints
%   single[n,1]  heartRateBPM
%   string recordStartTime
%   single[n,1]  activePeriodStart
%   single[n,1]  activePeriodEnd
%   single samplingFreq
%
% <<< Function Outputs >>>
%   struct DetailedBeatAnalysis

function DetailedBeatAnalysis = BeatAnalysis(beatPoints, heartRate, heartRateChange, recordStartTime, activePeriodStart, activePeriodEnd, samplingFreq)

% Origin time of the beats in seconds of a day. First beat is
% determined according to the recordStartTime
rPointsTimeSeconds = GetBeatTimeInSecondsofDay(beatPoints, recordStartTime, samplingFreq);

% Determination of day change indexes and new days
% dayChange.Indexes = dayChangeIndex;
% dayChange.DateTime = dayChangeDatetime;
[dayChangeIndex, dayChangeDatetime] = GetDayChange(rPointsTimeSeconds, recordStartTime);

% Determination of beats in active & passive period
[activePeriodFlag, passivePeriodFlag] = GetActivePassivePeriodFlags(activePeriodStart, activePeriodEnd, rPointsTimeSeconds);

% packet beat analysis
DetailedBeatAnalysis.HeartRate = heartRate;
DetailedBeatAnalysis.HeartRateChange = heartRateChange;
DetailedBeatAnalysis.BeatTime = rPointsTimeSeconds;
DetailedBeatAnalysis.DayChangeIndex = dayChangeIndex;
DetailedBeatAnalysis.DayChangeNewDate = dayChangeDatetime;
DetailedBeatAnalysis.ActivePeriod = activePeriodFlag;
DetailedBeatAnalysis.PassivePeriod = passivePeriodFlag;
DetailedBeatAnalysis.GeneralPeriod = ones( length( DetailedBeatAnalysis.HeartRate ), 1, 'logical' );

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Origin time of the beats in seconds of a day
%
% rPointsTimeSeconds = GetBeatTimeInSecondsofDay(beatPoints, recordStartTime, samplingFreq)
%
% <<< Function Inputs >>>
%   single[n,1]  beatPoints
%   string recordStartTime
%   single samplingFreq
%
% <<< Function Outputs >>>
%   single[n,1]  rPointsTimeSeconds
%

function rPointsTimeSeconds = GetBeatTimeInSecondsofDay(beatPoints, recordStartTime, samplingFreq)

% R Points in time for local
rPointsTimeSeconds = ( beatPoints / samplingFreq );

% Record start time in seconds
recordStartSecondofDay = hour( datetime( recordStartTime ) ) * single( 60 ) * single( 60 ) + ...
    minute( datetime( recordStartTime ) ) * single( 60 ) + ...
    second( datetime( recordStartTime ) );
% R Points for real time
rPointsTimeSeconds = rPointsTimeSeconds + recordStartSecondofDay * ones( numel( rPointsTimeSeconds, 1 ) );

% Shifting time
oneDaySeconds = single( 24 * 60 * 60 );
timeShift = ~isempty( rPointsTimeSeconds( rPointsTimeSeconds >= oneDaySeconds ) );
while timeShift
    shiftCondition =  ( rPointsTimeSeconds >= oneDaySeconds ) ;
    rPointsTimeSeconds ( shiftCondition ) = rPointsTimeSeconds ( shiftCondition ) - oneDaySeconds * ones( numel ( rPointsTimeSeconds( shiftCondition ) ), 1 );
    if isempty( rPointsTimeSeconds( rPointsTimeSeconds >= oneDaySeconds ) )
        timeShift = false;
    end
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Determination of day change iIndexes andnew days
%
% [dayChangeIndex, dayChangeDatetime] = GetDayChange(rPointsTimeSeconds, recordStartTime)
%
% <<< Function Inputs >>>
%   single[n,1]  rPointsTimeSeconds
%   string recordStartTime
%
% <<< Function Outputs >>>
%   datetime dayChangeIndex
%   datetime dayChangeDatetime
%

function [dayChangeIndex, dayChangeDatetime] = GetDayChange(rPointsTimeSeconds, recordStartTime)

% day change detection
dayChangeIndex = single( find ( abs ( diff(rPointsTimeSeconds) ) > 80000 ) + 1 );
dayChangeIndex = [1; dayChangeIndex];
dayChangeDatetime = dateshift( datetime( recordStartTime ), 'start', 'day');

% determination of the new day
for dayChangeCount = double( 2 : numel(dayChangeIndex) )
    dayChangeDatetime(dayChangeCount,:) = dateshift( dayChangeDatetime( dayChangeCount - 1), 'start', 'day', 'next' );
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Determination of beats in active and passive period
%
% [activePeriodFlag, passivePeriodFlag] = GetActivePassivePeriodFlags(activePeriodStart, activePeriodEnd, rPointsTimeSeconds)
%
% <<< Function Inputs >>>
%   single[n,1]  activePeriodStart
%   single[n,1]  activePeriodEnd
%   single[n,1]  rPointsTimeSeconds
%
% <<< Function Outputs >>>
%   bolean[n,1] activePeriodFlag
%   bolean[n,1] passivePeriodFlag
%

function [activePeriodFlag, passivePeriodFlag] = GetActivePassivePeriodFlags(activePeriodStart, activePeriodEnd, rPointsTimeSeconds)

% active period interval
activePeriodStartSecond = activePeriodStart * 60 * 60;
if activePeriodEnd == 0; activePeriodEnd = 24; end
activePeriodEndSecond = activePeriodEnd * 60 * 60 - 1;

% passive period interval
if activePeriodEnd == 24; activePeriodEnd = 0; end
passivePeriodStartSecond = activePeriodEnd * 60 * 60;
passivePeriodEndSecond = activePeriodStartSecond - 1;

% rise flag
activePeriodFlag = ( rPointsTimeSeconds <= activePeriodEndSecond) & ( rPointsTimeSeconds >= activePeriodStartSecond);
passivePeriodFlag = ( rPointsTimeSeconds >= passivePeriodStartSecond) & ( rPointsTimeSeconds <= passivePeriodEndSecond);

end


%% Period Based Rhythm Analysis

% Period based rhythm analysis.
%
% selectedPeriod =  PeriodBasedRhythmAnalysis( beatAnalysis, type )
%
% <<< Function Inputs >>>
%   struct beatAnalysis
%   string type
%
% <<< Function Outputs >>>
%   stuct selectedPeriod
%

function selectedPeriod =  PeriodBasedRhythmAnalysis( beatAnalysis, type )


% Interested Heart Rates
switch type
    case 'GeneralPeriod'
        selectedPeriodHeartRate = beatAnalysis.HeartRate .* beatAnalysis.GeneralPeriod;
        selectedPeriodHeartRateChange = beatAnalysis.HeartRateChange .* beatAnalysis.GeneralPeriod;
        selectedPeriodHeartRateChange = abs( 1 - selectedPeriodHeartRateChange );
    case 'ActivePeriod'
        selectedPeriodHeartRate = beatAnalysis.HeartRate .* beatAnalysis.ActivePeriod;
        selectedPeriodHeartRateChange = beatAnalysis.HeartRateChange .* beatAnalysis.ActivePeriod;
        selectedPeriodHeartRateChange = abs( 1 - selectedPeriodHeartRateChange );
    case 'PassivePeriod'
        selectedPeriodHeartRate = beatAnalysis.HeartRate .* beatAnalysis.PassivePeriod;
        selectedPeriodHeartRateChange = beatAnalysis.HeartRateChange .* beatAnalysis.PassivePeriod;
        selectedPeriodHeartRateChange = abs( 1 - selectedPeriodHeartRateChange );
end

if sum( selectedPeriodHeartRate ) ~= 0
    
    % General
    average = round( sum( selectedPeriodHeartRate ) / sum( selectedPeriodHeartRate > 0 ) );
        
    % Min Heart Rate
    [minHeartRate] = min (selectedPeriodHeartRate ( selectedPeriodHeartRate > min( selectedPeriodHeartRate ) ) );
    minHeartRateTime = find(selectedPeriodHeartRate == minHeartRate, 1, 'last');
    dayChange = max ( ( beatAnalysis.DayChangeIndex ~= 1 ) & ( beatAnalysis.DayChangeIndex <= minHeartRateTime ) ) + 1;
    minHeartRateTime = ClassDatetimeCalculation.Summation( beatAnalysis.DayChangeNewDate(dayChange), beatAnalysis.BeatTime(minHeartRateTime) );
    
    % Heart Rate Assessment
    selectedPeriodHeartRate = selectedPeriodHeartRate .* ( selectedPeriodHeartRateChange < 0.20 );
    
    % Max Heart Rate
    [maxHeartRate] = max( selectedPeriodHeartRate );
    maxHeartRateTime = find(selectedPeriodHeartRate == maxHeartRate, 1, 'last');
    dayChange = max ( ( beatAnalysis.DayChangeIndex ~= 1 ) & ( beatAnalysis.DayChangeIndex <= maxHeartRateTime ) ) + 1;
    maxHeartRateTime = ClassDatetimeCalculation.Summation( beatAnalysis.DayChangeNewDate(dayChange), beatAnalysis.BeatTime(maxHeartRateTime) );
    
    % Packet
    selectedPeriod.LowestHeartRate = minHeartRate;
    selectedPeriod.LowestHeartRateTime = minHeartRateTime;
    selectedPeriod.HighestHeartRate = maxHeartRate;
    selectedPeriod.HighestHeartRateTime = maxHeartRateTime;
    selectedPeriod.AverageHeartRate = average;
    
else
    
    selectedPeriod = [ ];
    
end

end


%% Maximum Heart Rate Detection

function newHeartRate = MaximumHeartRateDetection( qrsComplexes, heartRate )

% Plot
% close all; figure; plot( heartRate );
% Preallocation of the indexes to calculate the mean heart rate
firstIndex = find( ( heartRate > 0 ), 1, 'first' );
MeanHeartRateIndexes = [ firstIndex; firstIndex; firstIndex + 1; firstIndex + 2; firstIndex + 3 ];
% Mean heart rate
MeanHeartRate = mean( heartRate( MeanHeartRateIndexes ) );
% Heart rate characterization
HeartRateChar = fitdist( double( heartRate ), 'ev' );
HeartRateChangeThreshold = round( ( HeartRateChar.mean / HeartRateChar.mu ), 2 );
HeartRateChangeThreshold = min( HeartRateChangeThreshold, 0.33 );
% new heart rate
newHeartRate = heartRate;
% ignored heart rate
ignoredCounter = 0;
ignoredHeartRate = zeros( length( MeanHeartRateIndexes ), 1 );

for index = 5 : length( heartRate ) - 1
    
    if ... DONT INCLUDE BEATS IN NOISE
            ( qrsComplexes.NoisyBeat( index + 0 ) ) || ... önceki atým gürültü ise
            ( qrsComplexes.NoisyBeat( index + 1 ) ) || ... mevcut atým gürültü ise
            ( qrsComplexes.NoisyBeat( index + 2 ) ) ...   sonraki atým gürültü ise
            || ... DONT INCLUDE FLUTTER BEATS
            ( contains( qrsComplexes.BeatFormType( index + 0 ), 'U' ) ) || ...
            ( contains( qrsComplexes.BeatFormType( index + 1 ), 'U' ) ) || ...
            ( contains( qrsComplexes.BeatFormType( index + 2 ), 'U' ) ) ...
            || ...
            ( ...
            ( contains( qrsComplexes.BeatFormType( index + 0 ), 'N' ) ) && ...
            ( contains( qrsComplexes.BeatFormType( index + 1 ), 'V' ) ) && ...
            ( contains( qrsComplexes.BeatFormType( index + 2 ), 'N' ) )  ...
            ) ...
            || ...
            ( ...
            ~( contains( qrsComplexes.BeatFormType( index + 1 ), 'V' ) ) && ...
            ( contains( qrsComplexes.BeatFormType( index + 2 ), 'V' ) ) ...
            ) ...
            || ...
            ( ...
            ~( contains( qrsComplexes.BeatFormType( index + 1 ), 'A' ) ) && ...
            ( contains( qrsComplexes.BeatFormType( index + 2 ), 'A' ) ) ...
            )
        
        % new Heart Rate
        newHeartRate( index ) = MeanHeartRate;
        
    else
        
        % Heart rate change
        HeartRateChange = abs( round( ( heartRate( index ) / MeanHeartRate ), 2 ) - 1 );
        
        if HeartRateChange < HeartRateChangeThreshold
            % Igonered heart rate counter
            if any( ignoredHeartRate )
                ignoredCounter = 0; ignoredHeartRate = zeros( length( MeanHeartRateIndexes ), 1 );
            end
            % Indexes to consider for finding the maximum heart rate
            MeanHeartRateIndexes = circshift( MeanHeartRateIndexes, -1 );
            MeanHeartRateIndexes( end ) = index;
            % Mean
            MeanHeartRate = round( mean( heartRate( MeanHeartRateIndexes ) ) );
        else
            % new Heart Rate
            newHeartRate( index ) = MeanHeartRate;
            % Igonered heart rate counter
            ignoredCounter = ignoredCounter + 1;
            if ignoredCounter > length( ignoredHeartRate )
                ignoredHeartRate = circshift( ignoredHeartRate, -1 );
                ignoredHeartRate( end ) = heartRate( index );
            else
                ignoredHeartRate( ignoredCounter ) = heartRate( index );
            end
            % If ignored heart rates are very close add those in tho the
            % new heart rate
            if any( ignoredHeartRate ) && ( std( ignoredHeartRate ) < 5 )
                if heartRate( index ) < 300
                    newHeartRate( index ) = heartRate( index );
                end
            end
        end
        
    end
    
end

% hold on; plot( newHeartRate );
% ylim( [ 0 250 ] )
% disp( num2str( max( newHeartRate ) ) )

end


%% Check Channels For Detected Asystole

% Control of the intervals that are found as asystole.
%
% [ validatedBeats, lostConnectionBeat ] = CheckChannelsForAsystole( ecgSignal, rPoints, asystoleBeat, channelList, samplingFreq )
%
% <<< Function Inputs >>>
%   struct ecgSignal
%   single[n,1] rPoints
%   bolean[n,1] asystoleBeat
%   string[n,1] channelList
%   single samplingFreq
%
% <<< Function Outputs >>>
%   single[n,1] validatedAsystoleBeats
%   single[n,1] lostConnectionBeat
%

function [ validatedAsystole, missingBeat ] = CheckChannelsForAsystole( ecgSignal, rPoints, asystoleBeat, recordInfo, analysisChannel )

% Asystole Beats in Time
% - start time
runStartTime = double( round( rPoints( asystoleBeat) + recordInfo.RecordSamplingFrequency * 0.5 ) );
runStartTime( runStartTime < 1 ) = 1;
% - end time
runEndTime = double( round( rPoints( asystoleBeat + 1) - recordInfo.RecordSamplingFrequency * 0.5 ) );
runEndTime( runEndTime > length( ecgSignal.( analysisChannel ) ) ) = length( ecgSignal.( analysisChannel ) );
% Check Asystole Runs Time
% runStartTime( double( runEndTime - runStartTime ) < double( recordInfo.RecordSamplingFrequency ) ) = [ ];
% runEndTime( double( runEndTime - runStartTime ) < double( recordInfo.RecordSamplingFrequency ) ) = [ ];
% Store beats
validatedAsystole = single( zeros( length( runStartTime ), 1 ) );
missingBeat = single( zeros( length( runStartTime ), 1 ) );

% Active Channel Change Points
ActiveChannelChangePoints = zeros( recordInfo.CableConfigurationCount, 1, 'single' );
for i = 1 : recordInfo.CableConfigurationCount
    ActiveChannelChangePoints( i, 1 ) = recordInfo.CableConfigurations( i ).StartPoint;
    if i == recordInfo.CableConfigurationCount
        ActiveChannelChangePoints( i, 2 ) = length( ecgSignal.( analysisChannel ) );
    else
        ActiveChannelChangePoints( i, 2 ) = recordInfo.CableConfigurations( i + 1 ).StartPoint - 1;
    end
end

for run = 1 : numel( runStartTime )
    
    % Initialize flag
    checkConectionLost = false;
    % run points
    runPoints = transpose( double( runStartTime( run ) ) : double( runEndTime( run ) ) );
    
    % Active Channel List
    [ ~, ActiveChannelChangeIndex ] = intersect( ActiveChannelChangePoints( :, 1 ), runPoints );
    if ActiveChannelChangeIndex
        % unusual points and channel change has an intersected point
        ActiveChannelChangeIndex = sort( unique( [ ActiveChannelChangeIndex ( ActiveChannelChangeIndex - 1 ) ] ) );
        ActiveChannelChangeIndex( ActiveChannelChangeIndex < 1 ) = [ ];
        % find the minimum
        ActiveChannelCount = zeros( length( ActiveChannelChangeIndex ), 1, 'uint16' );
        for ChannelChangeIndex = 1 : length( ActiveChannelChangeIndex )
            ActiveChannelCount( ChannelChangeIndex ) = length( recordInfo.CableConfigurations( ActiveChannelChangeIndex( ChannelChangeIndex ) ).ActiveChannelList );
        end
        [ ~, ActiveChannelChangeIndex ] = max( ActiveChannelCount );
        % Active Channels List
        if isempty( ActiveChannelChangeIndex )
            ActiveChannelList = [ ];
        else
            ActiveChannelList = recordInfo.CableConfigurations( ActiveChannelChangeIndex ).ActiveChannelList;
        end
    else
        % unusual points and channel change has no intersected points
        ActiveChannelChangeIndex = find( ( ( ActiveChannelChangePoints( :, 1 )  <= runStartTime( run ) ) & (  ActiveChannelChangePoints( :, 2 ) >= runEndTime( run ) ) ), true );
        % Active Channels List
        if isempty( ActiveChannelChangeIndex )
            ActiveChannelList = [ ];
        else
            ActiveChannelList = recordInfo.CableConfigurations( ActiveChannelChangeIndex ).ActiveChannelList;
        end
    end
    
    % - Get ECG Signals
    for channel = 1 : length( ActiveChannelList )
        
        checkConectionLost = checkConectionLost || ...
            ClassChangeChannel.ControlChannel4Activity( ecgSignal.( ActiveChannelList{ channel } )( double( runStartTime(run) ) : double( runEndTime(run) ) ), recordInfo.RecordSamplingFrequency );
        
        if checkConectionLost
            missingBeat( run ) = asystoleBeat(run);
            break;
        end
        
    end
    
    % Flag if it is an asystole
    if ( ~checkConectionLost && ~isempty( ActiveChannelList ) ) || isempty( ActiveChannelList )
        validatedAsystole( run ) = asystoleBeat(run);
    end
    
end

% clear matrixes
missingBeat( missingBeat == 0 ) = [ ];
validatedAsystole( validatedAsystole == 0 ) = [ ];

end

