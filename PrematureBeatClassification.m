function qrsComplexes = PrematureBeatClassification( qrsComplexes, analysisParameters )

% INITIALIZATION
% - atrial beats
qrsComplexes.AtrialBeats = ...
    qrsComplexes.AtrialBeats & ~( qrsComplexes.P.PeakPoint > 1 );
if ~isempty( qrsComplexes.R )
    qrsComplexes.AtrialBeats( end ) = false;
end
% - ventricular beats
qrsComplexes.VentricularBeats = ...
    qrsComplexes.VentricularBeats & ~( qrsComplexes.P.PeakPoint > 1 );
if ~isempty( qrsComplexes.R )
    qrsComplexes.VentricularBeats( end ) = false;
end
% Mostly Seen Morph HeartRate
initialHeartRateRef = mean( qrsComplexes.HeartRate( qrsComplexes.BeatMorphology == 0 ) );

%
%
% ATRIAL BEAT CLASSIFICATION
% - initialization
startBeatIndex = - 1;
startRun = false;
% - Assessment
for beatIndex = 1 : ( length( qrsComplexes.R ) - 1 )
    
    % Ref Value
    if beatIndex > 4
        prematureBeatControl = any( qrsComplexes.VentricularBeats( beatIndex - 4 : beatIndex ) );
        prematureBeatControl = prematureBeatControl || any( qrsComplexes.AtrialBeats( beatIndex - 4 : beatIndex ) );
        prematureBeatControl = prematureBeatControl || any( abs( 1 - qrsComplexes.HeartRateChange( beatIndex - 4 : beatIndex ) ) > 0.25 );
        if ~prematureBeatControl
            refHeartRate = mean( qrsComplexes.HeartRate( beatIndex - 4 : beatIndex ) );
        end
    else
        refHeartRate = initialHeartRateRef;
    end
    
    if ~qrsComplexes.AtrialBeats( beatIndex )
        if ...
                ... no p wave
                ~( qrsComplexes.P.PeakPoint( beatIndex ) > 1 ) && ...
                ... not the first beat
                ( beatIndex > 2 ) && ...
                ... not in ventricular pattern
                ~qrsComplexes.VentricularBeats( beatIndex - 2 ) && ...
                ~qrsComplexes.VentricularBeats( beatIndex - 1 ) && ...
                ~qrsComplexes.VentricularBeats( beatIndex )
            
            if ...
                    ... previous beat condition
                    ( qrsComplexes.HeartRate( beatIndex - 1 ) > 60 / ( analysisParameters.Pause.ClinicThreshold / 1000 ) ) && ...
                    ... current beat condition
                    ( qrsComplexes.HeartRate( beatIndex ) > analysisParameters.Tachycardia.ClinicThreshold )
                % heart rate change
                suddenHeartRateChange = qrsComplexes.HeartRate( beatIndex ) / qrsComplexes.HeartRate( beatIndex - 1 );
                % assessment
                if suddenHeartRateChange > 1.25
                    qrsComplexes.HeartRateChange( beatIndex ) = suddenHeartRateChange;
                    qrsComplexes.AtrialBeats( beatIndex ) = true;
                end
            end
        end
    end
    
    % Heart rate based check
    if beatIndex > 1
        if qrsComplexes.AtrialBeats( beatIndex )
            % - low heart rate
            if qrsComplexes.HeartRate( beatIndex ) < 90
                qrsComplexes.AtrialBeats( beatIndex ) = false;
            end
            % - noise based pvc
            if qrsComplexes.VentricularBeats( beatIndex - 1 )
                qrsComplexes.AtrialBeats( beatIndex ) = false;
                qrsComplexes.VentricularBeats( beatIndex - 1 ) = false;
            end
        end
    end
    
    %     if qrsComplexes.R( beatIndex ) > 735 * 250
    %         plot_BeatClassBPM;
    %         title( num2str( qrsComplexes.AtrialBeats( beatIndex ) ) )
    %     end
    
    % Search for each beat
    if qrsComplexes.AtrialBeats( beatIndex )
        % Get the start index
        if ~startRun
            startBeatIndex = beatIndex;
            startRun = true;
        end
        % Check for the compensatory pause
        if qrsComplexes.AtrialBeats( beatIndex + 1 ) && ( beatIndex < ( length( qrsComplexes.R ) - 1 ) ) 
            continue;
        else
            % Check if the next beat is not ventricular
            if ~qrsComplexes.VentricularBeats( beatIndex + 1 )
                % Check for the heart rate change of the next beat
                if qrsComplexes.HeartRate( beatIndex + 1 ) > 60 / ( analysisParameters.Pause.ClinicThreshold / 1000 )
                    nextBeatHeartRateChange = qrsComplexes.HeartRate( beatIndex + 1 ) / refHeartRate;
                else
                    nextBeatHeartRateChange = inf;
                end
                % Check for the heart rate change of the initial beat
                if qrsComplexes.HeartRate( startBeatIndex ) > 60 / ( analysisParameters.Pause.ClinicThreshold / 1000 )
                    initialBeatHeartRateChange = qrsComplexes.HeartRate( startBeatIndex ) / refHeartRate;
                else
                    initialBeatHeartRateChange = inf;
                end
                % If there is a compensatory pause, skip
                if ( nextBeatHeartRateChange < 0.90 ) && ( initialBeatHeartRateChange > 1.10 )
                    % - end of the run
                    startBeatIndex = -1;
                    startRun = false;
                    continue;
                else
                    % run length
                    runBeatDuration = beatIndex - startBeatIndex + 1;
                    % previous heart rate change mean
                    runHeartRateChange = mean( qrsComplexes.HeartRate( startBeatIndex : beatIndex ) ) / refHeartRate;
                    % based on the run length
                    if ( nextBeatHeartRateChange < 1 ) && ( runBeatDuration > 2 ) && ( runHeartRateChange > 1.50 )
                        % - end of the run
                        startBeatIndex = -1;
                        startRun = false;
                    else
                        % - flag down
                        qrsComplexes.AtrialBeats( startBeatIndex : beatIndex ) = false;
                        % - end of the run
                        startBeatIndex = -1;
                        startRun = false;
                    end
                end
            else
                % - flag down
                qrsComplexes.AtrialBeats( startBeatIndex : beatIndex ) = false;
                % - end of the run
                startBeatIndex = -1;
                startRun = false;
            end
        end
    end
end
%        if meanQRSAmplitude < 0.5
%                 % dont care about the morphology
%                 if qrsComplexes.QRSAmplitude( BeatIndex ) < 0.5
%                     qrsComplexes.Type( BeatIndex ) = abs( qrsComplexes.Type( BeatIndex ) );
%                 end
%                 % increase the threshold
%                 pvcHeartRateChangeThreshold = single( 1.30 );
%                 pacHeartRateChangeThreshold = single( 1.50 );
%                 pvcCompansatoryPauseRatio = single( 0.97 );
%                 pacCompansatoryPauseRatio = single( 0.97 );
%             else
%                 % default thresholds
%                 pvcHeartRateChangeThreshold = single( 1.10 );
%                 pacHeartRateChangeThreshold = single( 1.25 );
%                 pvcCompansatoryPauseRatio = single( 0.91 );
%                 pacCompansatoryPauseRatio = single( 0.91 );
%             end

% 
% QRS Interval Based Adjustment
% wideQRSPAC = ...
%     ( qrsComplexes.AtrialBeats & qrsComplexes.QRSInterval > 0.120 );
% qrsComplexes.AtrialBeats( wideQRSPAC ) = false;
% qrsComplexes.VentricularBeats( wideQRSPAC ) = true;

%
%
% VENTRICULAR BEAT CLASSIFICATION
% - initialization
startBeatIndex = - 1;
startRun = false;
% - Assessment
for beatIndex = 1 : ( length( qrsComplexes.R ) - 1 )
    
    % Ref Value
    if beatIndex > 4
        prematureBeatControl = any( qrsComplexes.VentricularBeats( beatIndex - 4 : beatIndex ) );
        prematureBeatControl = prematureBeatControl || any( qrsComplexes.AtrialBeats( beatIndex - 4 : beatIndex ) );
        prematureBeatControl = prematureBeatControl || any( abs( 1 - qrsComplexes.HeartRateChange( beatIndex - 4 : beatIndex ) ) > 0.25 );
        if ~prematureBeatControl
            refHeartRate = mean( qrsComplexes.HeartRate( beatIndex - 4 : beatIndex ) );
        end
    else
        refHeartRate = initialHeartRateRef;
    end
    
    %     if qrsComplexes.R( beatIndex ) > 3495.5 * 250
    %         plot_BeatClassBPM;
    %         title( num2str( qrsComplexes.VentricularBeats( beatIndex ) ) )
    %     end
    
    % Search for each beat
    if qrsComplexes.VentricularBeats( beatIndex )
        % Get the start index
        if ~startRun
            startBeatIndex = beatIndex;
            startRun = true;
        end
        % Check for the compensatory pause
        if qrsComplexes.VentricularBeats( beatIndex + 1 ) && ( beatIndex < ( length( qrsComplexes.R ) - 1 ) ) 
            continue;
        else
            % Check for the heart rate change of the next beat
            if qrsComplexes.HeartRate( beatIndex + 1 ) > 60 / ( analysisParameters.Pause.ClinicThreshold / 1000 )
                nextBeatHeartRateChange = qrsComplexes.HeartRate( beatIndex + 1 ) / refHeartRate;
            else
                nextBeatHeartRateChange = inf;
            end
            % Check for the heart rate change of the initial beat
            if qrsComplexes.HeartRate( startBeatIndex ) > 60 / ( analysisParameters.Pause.ClinicThreshold / 1000 )
                initialBeatHeartRateChange = qrsComplexes.HeartRate( startBeatIndex ) / refHeartRate;
            else
                initialBeatHeartRateChange = inf;
            end
            % If there is a compensatory pause, skip
            if ( nextBeatHeartRateChange < 0.90 ) && ( initialBeatHeartRateChange > 1.10 )
                % - end of the run
                startBeatIndex = -1;
                startRun = false;
                continue;
            else
                if qrsComplexes.AtrialBeats( beatIndex + 1 )
                    % - flag down
                    qrsComplexes.VentricularBeats( startBeatIndex : beatIndex ) = false;
                    % - end of the run
                    startBeatIndex = -1;
                    startRun = false;
                else
                    % run length
                    runBeatDuration = beatIndex - startBeatIndex + 1;
                    % previous heart rate change mean
                    runHeartRateChange = mean( qrsComplexes.HeartRate( startBeatIndex : beatIndex ) ) / refHeartRate;
                    % based on the run length
                    if ( nextBeatHeartRateChange < 1 ) && ( runBeatDuration > 2 ) && ( runHeartRateChange > 1.25 )
                        % - end of the run
                        startBeatIndex = -1;
                        startRun = false;
                    else
                        % - flag down
                        qrsComplexes.VentricularBeats( startBeatIndex : beatIndex ) = false;
                        % - end of the run
                        startBeatIndex = -1;
                        startRun = false;
                    end
                end
            end
        end
    end
end

%     atr=zeros(length(find(cluster==2)),1);
%     vtr=zeros(length(find(cluster==1)),1);
% else
%     atr=zeros(length(find(cluster==1)),1);
%     vtr=zeros(length(find(cluster==2)),1);
% end

    


for k =2:length(qrsComplexes.NoisyBeat)
    if (qrsComplexes.AtrialBeats(k) ==1 && qrsComplexes.NoisyBeat(k-1)==1) 
        qrsComplexes.AtrialBeats(k)=0;
    end
      if (qrsComplexes.VentricularBeats(k) ==1 && qrsComplexes.NoisyBeat(k-1)==1)
        qrsComplexes.VentricularBeats(k)=0;
     end
end
% RRRInterval=zeros(length(qrsComplexes.R),1);
% % error=0.1;
% for r =3:length(qrsComplexes.R)-3
%     RRRInterval(r)=...
%         round(((qrsComplexes.R(r+2)-qrsComplexes.R(r)))/...
%         HolterRecordInfoRequest.RecordSamplingFrequency);
% end
% 
% for c=2:length(RRRInterval)
%     if (qrsComplexes.AtrialBeats(c) ==1) && ...
%             ((RRRInterval(c-1)==RRRInterval(c+1)) && (RRRInterval(c-1)==RRRInterval(c+1)))
%         qrsComplexes.AtrialBeats(c)=false;
%         qrsComplexes.VentricularBeats(c)=true;
%     end
% end

% LAST BEAT
if ~isempty( qrsComplexes.R )
    % - atrial beats
    qrsComplexes.AtrialBeats( end ) = false;
    % - ventricular beats
    qrsComplexes.VentricularBeats( end ) = false;
end

end

    


