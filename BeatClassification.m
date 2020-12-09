function [ qrsComplexes, normalQRSInterval ] = BeatClassification( ~, qrsComplexes, qrsMorphologies, recordInfo, matlabAPIConfig )

if isempty( qrsComplexes.R )
    
    % Output
    % - qrs
    qrsComplexes.VentricularBeats = [ ];
    qrsComplexes.AtrialBeats = [ ];
    qrsComplexes.HeartRate = [ ];
    qrsComplexes.HeartRateChange = [ ];
    % normal qrs int
    normalQRSInterval = [ ];
    
else
    
%
%
% NORMAL QRS DETECTION
% - beat counters
beatCounters = qrsMorphologies.BeatCounter;
% - frequently seen qrs morphology
[ ~, frequentlySeenMorphIndex ] = max( beatCounters );
% - beat interval
normalQRSInterval = qrsMorphologies.BeatInterval( frequentlySeenMorphIndex );
if sum( qrsMorphologies.BeatCounter == qrsMorphologies.BeatCounter( frequentlySeenMorphIndex ) ) > 1
    % - frequentlySeenMorphIndexes
    frequentlySeenMorphIndexes = find( qrsMorphologies.BeatCounter == qrsMorphologies.BeatCounter( frequentlySeenMorphIndex ) );
    % - get the min interval
    [ ~, frequentlySeenMorphIntervals ] = min( qrsMorphologies.BeatInterval( frequentlySeenMorphIndexes ) );
    % - get the  frequently seen qrs morphology
    frequentlySeenMorphIndex = frequentlySeenMorphIndexes( frequentlySeenMorphIntervals );
end
% - conversiton index to qrs beat morphology type
frequentlySeenMorphQRSType = frequentlySeenMorphIndex - 1;
% - qrs type of the frequently seen morphology
frequentlySeenMorphType = sum( qrsComplexes.Type( qrsComplexes.BeatMorphology == frequentlySeenMorphQRSType ) );

% QRS Direction
if frequentlySeenMorphType >= 0
    qrsComplexes.Type = qrsComplexes.Type * single( 3 );
    if matlabAPIConfig.IsLogWriteToConsole
        disp( 'Normal QRS Direction: "^" ');
    end
else
    qrsComplexes.Type = qrsComplexes.Type * single( -3 );
    if matlabAPIConfig.IsLogWriteToConsole
        disp( 'Normal QRS Direction: "v" ');
    end
end; clear frequentlySeenMorphType

%
%
% MORPHOLOGY BASED HEART RATE
% - heart rate
heartRate = ClassRhythmAnalysis.CalculateHeartRate( qrsComplexes.R, recordInfo.RecordSamplingFrequency );
% - since bpm of the first beat is ignored,
% - decrease the indexes of the normal QRSs by 1
normalQRSIndexes = find( qrsComplexes.BeatMorphology == frequentlySeenMorphQRSType ) - 1;
normalQRSIndexes( normalQRSIndexes < 1 ) = [ ];
% - normal qrs heart rate
normalQRSHeartRate = mean( heartRate( normalQRSIndexes ) );
% - adjust heart rate to qrs size
firstBeatMorphology = qrsComplexes.BeatMorphology( 1 );
firstBeatTypeQRSIndexes = find( qrsComplexes.BeatMorphology == firstBeatMorphology ) - 1;
firstBeatTypeQRSIndexes( firstBeatTypeQRSIndexes < 1 ) = [ ];
if ~isempty( firstBeatTypeQRSIndexes )
    firstBeatTypeMeanHeartRate = round( mean( heartRate( firstBeatTypeQRSIndexes ) ) );
else
    firstBeatTypeMeanHeartRate = heartRate(1);
end
heartRate = [ firstBeatTypeMeanHeartRate; heartRate ];
% clear workspace
clear firstBeatMorphology ...
    firstBeatTypeQRSIndexes ...
    firstBeatTypeMeanHeartRate ...
    frequentlySeenMorphIndex ...
    frequentlySeenMorphType...
    normalQRSIndexes

%
%
% HEART RATE CHANGE
% - initialization
heartRateChange = zeros( length( heartRate ), 1, 'single' );
% - assessment
for beatIndex = 1 : length( qrsComplexes.R )
    
    %     if qrsComplexes.R( beatIndex ) > 1335 * 250
    %         plot_BeatClassBPM;
    %     end
    
    % - current beat bpm
    currentHeartRate = heartRate( beatIndex );
    % - mean heart rate
    heartRateChange( beatIndex ) = currentHeartRate / normalQRSHeartRate;
    % - absolute heart rate change
    currentHeartRateChange = abs( heartRateChange( beatIndex ) - 1 );
    % normal heart rate calculation
    if ( currentHeartRate < 100 ) && ( beatIndex > 1 ) && ( ( currentHeartRateChange < 0.20 ) )
        % previous heart rate change
        previousHeartRateChange = abs( heartRateChange( beatIndex - 1 ) - 1 );
        if ( previousHeartRateChange < 0.25 ) 
            % normal qrs heart rate change
            normalQRSHeartRate = normalQRSHeartRate * 0.25 + currentHeartRate * 0.75;
        end
    end
    
end; clear absHeartRateChange beatIndex currentHeartRate normalQRSHeartRate

%
%
% MORPHOLOGY BASED HEART RATE CHANGE
% - assessment
for morphIndex = 1 : qrsMorphologies.MorphCounter
    % - beat indexes
    morphBeatIndex = ( qrsComplexes.BeatMorphology == morphIndex - 1 );
    % - mean heart rate change
    morphHeartRateChange = mean( heartRateChange( morphBeatIndex ) );
    % - add field
    qrsMorphologies.HeartRateChange( morphIndex, : ) = morphHeartRateChange;
    
end; clear numbMorph morphBeatIndex morphIndex morphHeartRateChange

%
%
% PREMATURE BEATS
% - possible ventricular morphs
possibleVentricularMorphs = ...
    ( ( qrsMorphologies.BeatInterval > 0.120 ) & ( qrsMorphologies.HeartRateChange > 1.15 ) );
% - initialization
qrsComplexes.VentricularBeats = zeros( length( qrsComplexes.R ), 1, 'logical' );
qrsComplexes.AtrialBeats = zeros( length( qrsComplexes.R ), 1, 'logical' );
for morphIndex = 1 : length( possibleVentricularMorphs )
    if possibleVentricularMorphs( morphIndex )
        qrsComplexes.VentricularBeats( qrsComplexes.BeatMorphology == morphIndex - 1 ) = true;
    end
end; clear morphIndex
if normalQRSInterval < 0.110
    qrsComplexes.VentricularBeats( (qrsComplexes.QRSInterval >= 0.120 ) & ( heartRateChange >= 1.15 ) ) = true;
end
% Atrial Beats
qrsComplexes.AtrialBeats( ~qrsComplexes.VentricularBeats & ( heartRateChange > 1.20 ) & ( heartRate > 90 ) ) = true;

%
%
% SET HEART RATE
qrsComplexes.HeartRate = heartRate;
qrsComplexes.HeartRateChange = heartRateChange;

%
%
% PLOT
% plot_BeatClassification

end

end

