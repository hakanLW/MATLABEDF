
% PVC Detection Algorithm
%
% [ PVCRuns ] = Detection_PrematureBeats( ecgSignals, qrsComplexes, recordInfo )
%
%  <<< Function Inputs >>>
%   struct ecgSignals
%   struct qrsComplexes
%   struct atrialFib
%   struct recordInfo
%   single noisySample
%
% <<< Function outputs >>>
%   struct  PVCRuns
%   .SalvoRun
%   .TripletRun
%   .CoupletRun
%   .QuadrigeminyRun
%   .TrigeminyRun
%   .BigeminyRun
%   .IsolatedRun

function [ PrematureVentricularBeats, PrematureAtrialBeats ] = ...
    Detection_PrematureBeats( ecgSignals, qrsComplexes, analysisParameters, recordInfo, matlabAPIConfig )

% Check for detected beats
if isempty( qrsComplexes.R )
    
    PrematureVentricularBeats = [ ];
    PrematureAtrialBeats = [ ];
    
else
    
    %   --------------------------------
    %   Initialization
    %   ---------------------------------
    
    % - heart rate calculation / store heart rate changke
    HeartRate = ClassRhythmAnalysis.CalculateHeartRate( qrsComplexes.R, recordInfo.RecordSamplingFrequency );
    HeartRate = [ HeartRate( 1 ) ; HeartRate ];
    HeartRateChange = zeros( length( HeartRate ), 1, 'single' );
    
    % - store premature beats
    PrematureVentricularBeats = zeros( length( qrsComplexes.R ), 1, 'logical' );
    PrematureAtrialBeats = zeros( length( qrsComplexes.R ), 1, 'logical' );
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %   --------------------------------
    %   Normal Beat Detection
    %   --------------------------------
    
    % - qrs interval
    possibleNormalBeat = ( ( qrsComplexes.QRSInterval< single( 0.120 ) ) & ( qrsComplexes.R <= ( 10 *  recordInfo.RecordSamplingFrequency ) ) );
    %     % - p amplitudes
    possibleNormalBeat = possibleNormalBeat & ( qrsComplexes.PTInterval > ( 0 ) );
    % - t amplitude
    possibleNormalBeat = possibleNormalBeat & ( qrsComplexes.T.Amplitude >= single( 0.05 ) );
    % - t amplitude
    possibleNormalBeat = possibleNormalBeat & ( qrsComplexes.P.Amplitude >= single( 0.05 ) );
    % - heartRate
    possibleNormalBeat = possibleNormalBeat & ( HeartRate > analysisParameters.Bradycardia.ClinicThreshold ) & ( HeartRate < analysisParameters.Tachycardia.ClinicThreshold );
    
    %   --------------------------------
    %  Normal Beat Paremeters
    %   --------------------------------
    
    if any( possibleNormalBeat )
        
        % - heart rate
        normalBeatHeartRate = mean( HeartRate( possibleNormalBeat ) );
        
    else
        
        if length( qrsComplexes.R ) < 10
            lastBeat = length( qrsComplexes.R );
        else
            lastBeat = 10;
        end
        
        % - heart rate
        normalBeatHeartRate = mean( HeartRate( double( 1 ) : double( lastBeat ) ) );
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    for BeatIndex = 1 : ( length( qrsComplexes.R ) - 1 )
        
        
        if BeatIndex == 1
            
            % Initialization
            possibleVentricularRunStart = false;
            possibleAtrialRunStart = false;
            % QRS Complex interval
            qrsIntervalThreshold = single( 0.120 );
            
        else
                        
            % BASELINE CHECK
            if ( BeatIndex > 1 )
                % Previous beat baseline
                previousBaseline = ...
                    mean( [ ...
                    ecgSignals.( matlabAPIConfig.AnalysisChannel )( qrsComplexes.StartPoint( BeatIndex - 1 ) ); ...
                    ecgSignals.( matlabAPIConfig.AnalysisChannel )( qrsComplexes.EndPoint( BeatIndex - 1 ) ) ...
                    ] );
                % Current beat baseline
                currentBaseline = mean( [ ...
                    ecgSignals.( matlabAPIConfig.AnalysisChannel )( qrsComplexes.StartPoint( BeatIndex ) ); ...
                    ecgSignals.( matlabAPIConfig.AnalysisChannel )( qrsComplexes.EndPoint( BeatIndex ) ) ...
                    ] );
                % Assessment
                if ...
                        ( abs( currentBaseline - previousBaseline ) > qrsComplexes.QRSAmplitude( BeatIndex ) ) ...
                        || ...
                        ( abs( currentBaseline - previousBaseline ) > qrsComplexes.QRSAmplitude( BeatIndex - 1 ) )
                    continue;
                end
            end
            
            % RESET
            isVentricularPrematureBeat = false;
            isAtrialPrematureBeat = false;
            
            % THRESHOLD
            if exist( 'meanQRSAmplitude', 'var' ) && ( BeatIndex > 4 )
                % QRS Amplitudes
                newMeanQRSAmplitude = mean( qrsComplexes.QRSAmplitude( double( BeatIndex - 4 ) : double( BeatIndex ) ) ); 
                if ( newMeanQRSAmplitude / meanQRSAmplitude ) < 1.25
                    meanQRSAmplitude = newMeanQRSAmplitude;
                end
            else
                % QRS Amplitudes
                meanQRSAmplitude= mean( qrsComplexes.QRSAmplitude( BeatIndex ) );
            end
            % Assessment based on the amplitude
            if meanQRSAmplitude < 0.5
                % dont care about the morphology
                if qrsComplexes.QRSAmplitude( BeatIndex ) < 0.5
                    qrsComplexes.Type( BeatIndex ) = abs( qrsComplexes.Type( BeatIndex ) );
                end
                % increase the threshold
                pvcHeartRateChangeThreshold = single( 1.30 );
                pacHeartRateChangeThreshold = single( 1.50 );
                pvcCompansatoryPauseRatio = single( 0.97 );
                pacCompansatoryPauseRatio = single( 0.97 );
            else
                % default thresholds
                pvcHeartRateChangeThreshold = single( 1.10 );
                pacHeartRateChangeThreshold = single( 1.25 );
                pvcCompansatoryPauseRatio = single( 0.91 );
                pacCompansatoryPauseRatio = single( 0.91 );
            end
            
            % CURRENT VALUES OF THE DETECTION PARAMETERS
            % - Heart Rate Condition
            HeartRateChange( BeatIndex ) = single( HeartRate( BeatIndex ) ./ normalBeatHeartRate );
            
            % - P wave condition
            PWaveCondition = ( qrsComplexes.P.Amplitude( BeatIndex ) <= single( 0.025 ) );
            if ~PWaveCondition
                if ...
                        ( HeartRateChange( BeatIndex ) > single( 1.5 ) ) && ...
                        ( qrsComplexes.QRSInterval( BeatIndex ) >= qrsIntervalThreshold ) && ...
                        ( qrsComplexes.P.Amplitude( BeatIndex ) <= single( 0.05 ) )
                    PWaveCondition = true;
                end
            end
            
            % - PLOT
            %             if qrsComplexes.R( BeatIndex ) > 23.4 * recordInfo.RecordSamplingFrequency
            %                 disp( [ 'NormalHeartRate: ' num2str( normalBeatHeartRate ) ] )
            %                 disp( [ 'HeartRate: ' num2str( HeartRate( BeatIndex ) ) ' // HeartRateChange: ' num2str( HeartRateChange( BeatIndex ) ) ] )
            %                 plotDeveloper_prematureBeats;
            %             end
            
            % ABNORMAL QRS DETECTION
            % - Initialization
            ventricularBasedAbnormalBeat = false;
            atrialBasedAbnormalBeat = false;
            % - Assessment
            if ~( qrsComplexes.NoisyBeat( BeatIndex ) ) && ( BeatIndex > 2 ) && ( HeartRateChange( BeatIndex ) > 1.10 )
                % Baseline Change
                currentStartAmplitude = ecgSignals.( matlabAPIConfig.AnalysisChannel )( qrsComplexes.StartPoint( BeatIndex ) );
                previousStartAmplitude = ecgSignals.( matlabAPIConfig.AnalysisChannel )( qrsComplexes.StartPoint( BeatIndex - 1 ) );
                if abs( currentStartAmplitude - previousStartAmplitude ) < 0.2
                    % Comparison between current and previous R point amplitudes.
                    currentRAmplitude = ecgSignals.( matlabAPIConfig.AnalysisChannel )( qrsComplexes.R( BeatIndex ) );
                    previousRAmplitude = ecgSignals.( matlabAPIConfig.AnalysisChannel )( qrsComplexes.R( BeatIndex - 1 ) );
                    % Amplitude Change
                    amplitudeChange = ( currentRAmplitude > ( previousRAmplitude + 0.2 ) );
                else
                    amplitudeChange = false;
                end
                % rapid beat
                rapidBeat = HeartRateChange( BeatIndex ) > 1.25;
                
                % ABNORMAL BEAT TYPE CONTROL
                % - If ( the amplitude is increased AND there is no p wave
                %       OR
                %      there is a rapid increase in the heart rate )
                %       THEN
                %      !! check the qrs interval or the sequintal types
                if ...
                        ... FIRST CONDITION : // increase in the amplitude && non p wave || rapid heart rate incrase
                        ( ( amplitudeChange && PWaveCondition ) || ( rapidBeat && PWaveCondition ) ) ...
                        && ...
                        ... SECOND CONDITION: // the qrs interval or the sequintal types
                        ( qrsComplexes.Type( BeatIndex ) < 0 ) || ...
                        ( ( qrsComplexes.QRSInterval( BeatIndex ) > qrsIntervalThreshold ) || ...
                        ( ( qrsComplexes.QRSInterval( BeatIndex ) > 0.090 ) && ( any( PrematureVentricularBeats( BeatIndex - 2 : BeatIndex - 1 ) ) ) ) )
                    
                    if ( HeartRate( BeatIndex ) / HeartRate( BeatIndex - 1 ) ) > 1.15
                        ventricularBasedAbnormalBeat = true;
                    end
                    
                elseif...
                        ... FIRST CONDITION : // increase in the amplitude && non p wave || rapid heart rate incrase
                        ( ( amplitudeChange && PWaveCondition ) || ( rapidBeat  ) ) ...
                        && ...
                        ( qrsComplexes.QRSInterval( BeatIndex ) < qrsIntervalThreshold )
                    
                    if ( HeartRate( BeatIndex ) / HeartRate( BeatIndex - 1 ) ) > 1.15
                        atrialBasedAbnormalBeat = true;
                    end
                    
                end
                
            end
            
            %             % - PLOT
            %             if qrsComplexes.R( BeatIndex ) > 6.5 * recordInfo.RecordSamplingFrequency
            %                 disp( [ 'NormalHeartRate: ' num2str( normalBeatHeartRate ) ] )
            %                 disp( [ 'HeartRate: ' num2str( HeartRate( BeatIndex ) ) ' // HeartRateChange: ' num2str( HeartRateChange( BeatIndex ) ) ] )
            %                 plotDeveloper_prematureBeats;
            %             end
            
            %% PREMATURE VENTRICULAR BEATS
            %%%
            %%%
            %%%
            
            % VENTRICULAR ASSESMENT
            if ...
                    ... if the p wave of the current QRS does not exist
                    ( ...
                    PWaveCondition || ...
                    ( qrsComplexes.Type( BeatIndex ) < 0 ) || ...
                    ( ventricularBasedAbnormalBeat ) ...
                    )...
                    && ...
                    ... increased heart rate change
                    ( ...
                    ( HeartRateChange( BeatIndex ) > pvcHeartRateChangeThreshold ) || ...
                    ( qrsComplexes.Type( BeatIndex ) < 0 ) || ...
                    ( ventricularBasedAbnormalBeat ) ...
                    ) && ...
                    ... qrs interval || qrs type with high amplitude
                    ( ...
                    ( qrsComplexes.QRSInterval( BeatIndex ) >= qrsIntervalThreshold ) || ...
                    ( qrsComplexes.Type( BeatIndex ) < 0 ) || ...
                    ( ventricularBasedAbnormalBeat ) ...
                    )
                
                % rise flag
                isVentricularPrematureBeat = true;
                % get run start
                % Start a run
                if ~possibleVentricularRunStart
                    % - beat index
                    possibleVentricularRunStartIndex = BeatIndex;
                end
                
            end
            
            % CHECK THE UPCOMING BEAT:
            % if the next beat has a compansatory pause or if it is a pvc beat; start a run
            % if the next beat does not have the requiered parameters, un-flag it.
            if isVentricularPrematureBeat && ( BeatIndex < length( HeartRate ) )
                
                % Next beat heart rate change: is there a compasantory pause
                if HeartRate( BeatIndex + 1 ) > ( 60 / ( analysisParameters.Asystole.ClinicThreshold / 1000 ) )
                    % if there is no such a longer pause than an asystole threshold
                    nextBeatHeartRateChange = ( HeartRate( BeatIndex + 1 ) / normalBeatHeartRate );
                else
                    % if there is a longer pause than an asystole threshold
                    nextBeatHeartRateChange = 1;
                end
                
                if ... VENTRICULAR RUN
                        ... upcoming beat heart rate change
                        ( ...
                        ( nextBeatHeartRateChange > pvcHeartRateChangeThreshold ) || ...
                        ( qrsComplexes.Type( BeatIndex + 1 ) < 0 )  ...
                        ) && ...
                        ... upcoming beat qrs interval
                        ( ...
                        ( qrsComplexes.QRSInterval( BeatIndex + 1 ) >= qrsIntervalThreshold ) || ...
                        ( qrsComplexes.Type( BeatIndex + 1 ) < 0 )  ...
                        )
                    
                    % Start a run
                    if ~possibleVentricularRunStart
                        % - flag up
                        possibleVentricularRunStart = true;
                    end
                    
                elseif ... VENTRICULAR RUN ENDS
                        ( nextBeatHeartRateChange < pvcCompansatoryPauseRatio ) ...
                        || ... 
                        ( ( ( BeatIndex - possibleVentricularRunStartIndex ) > 1 ) && PWaveCondition && ( HeartRateChange(BeatIndex ) > pvcHeartRateChangeThreshold )  )
                    
                    % Comfired and ended
                    isVentricularPrematureBeat = true;
                    possibleVentricularRunStart = false;
                    possibleVentricularRunStartIndex = -1;
                    
                else
                    
                    % Not a premature ventricular beat
                    % - clear run
                    if possibleVentricularRunStart
                        % if a run was started
                        % - clear all PVCs
                        isVentricularPrematureBeat = false;
                        PrematureVentricularBeats( double( possibleVentricularRunStartIndex ) : double( BeatIndex ) ) = false;
                        % - flag down
                        possibleVentricularRunStart = false;
                        % - initialize start index
                        possibleVentricularRunStartIndex = -1;
                    else
                        % if a single pvc is detected
                        isVentricularPrematureBeat = false;
                    end
                    
                end
                
            end
            
            if ~isVentricularPrematureBeat && possibleVentricularRunStart
                % if a run was started
                % - clear all PVCs
                isVentricularPrematureBeat = false;
                PrematureVentricularBeats( double( possibleVentricularRunStartIndex ) : double( BeatIndex ) ) = false;
                % - flag down
                possibleVentricularRunStart = false;
                % - initialize start index
                possibleVentricularRunStartIndex = -1;
            end
            
            % - PLOT
            %             if qrsComplexes.R( BeatIndex ) > 420 * recordInfo.RecordSamplingFrequency
            %                 disp( [ 'NormalHeartRate: ' num2str( normalBeatHeartRate ) ] )
            %                 disp( [ 'HeartRate: ' num2str( HeartRate( BeatIndex ) ) ' // HeartRateChange: ' num2str( HeartRateChange( BeatIndex ) ) ] )
            %                 plotDeveloper_prematureBeats;
            %             end
            
            %% PREMATURE ATRIAL BEATS
            %%%
            %%%
            %%%
            
            if ... 
                    ~ isVentricularPrematureBeat && ...
                    ...
                    ~( qrsComplexes.NoisyBeat( BeatIndex ) ) && ...
                    ...
                    ( HeartRate( BeatIndex ) > analysisParameters.Tachycardia.ClinicThreshold )
                
                % ATRIAL ASSESMENT
                if ...
                        ... increased heart rate change
                        ( ...
                        ( HeartRateChange( BeatIndex ) > pacHeartRateChangeThreshold ) || ...
                        ( atrialBasedAbnormalBeat ) ...
                        ) && ...
                        ... qrs interval || qrs type with high amplitude
                        ( ...
                        ( qrsComplexes.QRSInterval( BeatIndex ) < qrsIntervalThreshold ) || ...
                        ( atrialBasedAbnormalBeat ) ...
                        )
                    
                    % rise flag
                    isAtrialPrematureBeat = true;
                    % get run start
                    % Start a run
                    if ~possibleAtrialRunStart
                        % - beat index
                        possibleAtrialRunStartIndex = BeatIndex;
                    end
                    
                end
                
                % CHECK THE UPCOMING BEAT:
                % if the next beat has a compansatory pause or if it is a pvc beat; start a run
                % if the next beat does not have the requiered parameters, un-flag it.
                if ( isAtrialPrematureBeat && ( BeatIndex < length( HeartRate ) ) )
                    
                    % Next beat heart rate change: is there a compasantory pause
                    if HeartRate( BeatIndex + 1 ) > ( 60 / ( analysisParameters.Asystole.ClinicThreshold / 1000 ) )
                        % if there is no such a longer pause than an asystole threshold
                        nextBeatHeartRateChange = ( HeartRate( BeatIndex + 1 ) / normalBeatHeartRate );
                    else
                        % if there is a longer pause than an asystole threshold
                        nextBeatHeartRateChange = 1;
                    end
                    
                    if ... ATRIAL RUN
                            ... upcoming beat heart rate change
                            ( nextBeatHeartRateChange > pacHeartRateChangeThreshold )
                        
                        % Start a run
                        if ~possibleAtrialRunStart
                            % - flag up
                            possibleAtrialRunStart = true;
                        end
                        
                    elseif ... VENTRICULAR RUN ENDS
                            ( nextBeatHeartRateChange < pacCompansatoryPauseRatio ) ...
                            || ... CONDITION 2 : Long lasting run
                            ( ( BeatIndex - possibleAtrialRunStartIndex ) > 4 )
                        
                        % Comfired and ended
                        isAtrialPrematureBeat = true;
                        possibleAtrialRunStart = false;
                        possibleAtrialRunStartIndex = -1;
                        
                    else
                        
                        % Not a premature ventricular beat
                        % - clear run
                        if possibleAtrialRunStart
                            % if a run was started
                            % - clear all PVCs
                            isAtrialPrematureBeat = false;
                            PrematureAtrialBeats( double( possibleAtrialRunStartIndex ) : double( BeatIndex ) ) = false;
                            % - flag down
                            possibleAtrialRunStart = false;
                            % - initialize start index
                            possibleAtrialRunStartIndex = -1;
                        else
                            % if a single pvc is detected
                            isAtrialPrematureBeat = false;
                        end
                        
                    end
                    
                end
                
                if ~isAtrialPrematureBeat && possibleAtrialRunStart
                    % if a run was started
                    % - clear all PVCs
                    isAtrialPrematureBeat = false;
                    PrematureAtrialBeats( double( possibleAtrialRunStartIndex ) : double( BeatIndex ) ) = false;
                    % - flag down
                    possibleAtrialRunStart = false;
                    % - initialize start index
                    possibleAtrialRunStartIndex = -1;
                end
                
            end
            
            %% CHANGE THRESHOLD
            
            if ( BeatIndex > 2 )
                
                if ...
                        ... not a pvc or after a pvc
                        ~isVentricularPrematureBeat && ...
                        ( ~any( PrematureVentricularBeats( BeatIndex - 1 ) ) ) && ...
                        ... not a pvc or after a pvc
                        ~isAtrialPrematureBeat && ...
                        ( ~any( PrematureAtrialBeats( BeatIndex - 1 ) ) ) && ...
                        ... heart rate should not be lower the threshold
                        ( HeartRate( double( BeatIndex ) ) > ( analysisParameters.Bradycardia.ClinicThreshold  ) ) && ...
                        ... if there is no rapid heart rate change
                        ( HeartRateChange( BeatIndex ) < 1.25 )
                    
                    
                    % change heart rate level
                    normalBeatHeartRate = 0.67* normalBeatHeartRate + 0.33 * HeartRate( BeatIndex ) ;
                    if normalBeatHeartRate < analysisParameters.Bradycardia.ClinicThreshold
                        normalBeatHeartRate = analysisParameters.Bradycardia.ClinicThreshold;
                    end
                    
                end
                
            end
            
            %% ANNOTATION
            
            PrematureVentricularBeats( BeatIndex ) = isVentricularPrematureBeat;
            PrematureAtrialBeats( BeatIndex ) = isAtrialPrematureBeat;
            
        end
        
    end
    
end

end
