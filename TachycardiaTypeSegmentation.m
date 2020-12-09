function [ sinTachyRuns, svtTachyRuns, venTachyRuns, venFlutterRuns ] = TachycardiaTypeSegmentation( ...
    qrsComplexes, ...
    tachyRuns, ....
    recordInfo, ...
	analysisParameters ...
    )

% Initialization
% - sinus tachycardia
sinTachyIndex = zeros( length( qrsComplexes.R ), 1, 'logical' );
% - svt tachycardia
svtTachyIndex = zeros( length( qrsComplexes.R ), 1, 'logical' );
% - ven tachycardia
venTachyIndex = zeros( length( qrsComplexes.R ), 1, 'logical' );
% - ven flutter
venFlutterIndex = zeros( length( qrsComplexes.R ), 1, 'logical' );

% Check if there is a tachy run
if ~isempty( tachyRuns )
    % Evaluation for each tachy run
    for tachyIndex = 1 : length( tachyRuns.StartTime )        
        % Check if the tachy run is caused by premature beats
        runBeatIndexes = double( tachyRuns.StartBeat( tachyIndex ) ) : double( tachyRuns.EndBeat( tachyIndex ) );
        runBeatIndexes( qrsComplexes.HeartRate( runBeatIndexes ) < analysisParameters.Tachycardia.ClinicThreshold ) = [ ];
        % Check if there is venticular based beats
        venBasedBeat = qrsComplexes.VentricularBeats( runBeatIndexes );
        venTachyIndex( runBeatIndexes( venBasedBeat ) ) = true;
        % Check if there is atrial based beats
        svtBasedBeat = qrsComplexes.AtrialBeats( runBeatIndexes );
        svtTachyIndex( runBeatIndexes( svtBasedBeat ) ) = true;
        % Check if there is sinus based beats
        sinTachyIndex( runBeatIndexes( ~( venBasedBeat | svtBasedBeat ) ) ) = true;
    end    
end

% Packet ventricular tachycardia run
% - min beat duration: 5
sinTachyRuns = PacketRun( qrsComplexes, sinTachyIndex, 5, recordInfo );
% - min beat duration: 3
svtTachyRuns = PacketRun( qrsComplexes, svtTachyIndex, 3, recordInfo );
% - min beat duration: 3
venTachyRuns = PacketRun( qrsComplexes, venTachyIndex, 3, recordInfo );
% - min beat duration: inf
venFlutterRuns = PacketRun( qrsComplexes, venFlutterIndex, inf, recordInfo );

end


%% SubFunction : Run Packet

function [ run ] = PacketRun( qrsComplexes, runPoints, minBeatDuration, recordInfo )

if any( runPoints )
    
    % start and end beats
    [ startBeat, endBeat ] = BlockSegmentation( runPoints, minBeatDuration );
    
    % check if there is run
    if ~isempty( startBeat )
        
        % start and end time
        beatStartTime = ...
            ( qrsComplexes.StartPoint(1:end) / recordInfo.RecordSamplingFrequency );
        beatEndTime = ...
            ( qrsComplexes.EndPoint(1:end) / recordInfo.RecordSamplingFrequency );
        
        % PACKET RUN
        % - start beat
        run.StartBeat = ...
            startBeat;
        % - start date time
        run.StartTime = ...
            ClassDatetimeCalculation.Summation( recordInfo.RecordStartTime, beatStartTime( startBeat ) );
        % - end beat
        run.EndBeat = ...
            endBeat;
        % - start date time
        run.EndTime = ...
            ClassDatetimeCalculation.Summation( recordInfo.RecordStartTime, beatEndTime( endBeat ) );
    	% - duration
        run.Duration = ...
            endBeat - startBeat + 1;
        % - heart rate
        run.AverageHeartRate = ...
            AverageHeartRate( qrsComplexes.HeartRate, startBeat, endBeat );
        % - beat flag
        % - - initialization
        run.BeatFlag = zeros( length( qrsComplexes.R ), 1, 'logical' );
        % - - rise flag
        for runIndex = 1 : length( run.StartBeat )
            run.BeatFlag( double( run.StartBeat( runIndex ) ) : double( run.EndBeat( runIndex ) ) ) = true;
        end
        
    else
        
        run = single( [ ] );
        
    end    
    
else
    
    run = single( [ ] );
    
end

end


%% SubFunction: Block Segmentation

function [ blockStart, blockEnd ] = BlockSegmentation( binarySignal, minDuration )

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
% - duration
blockDuration = blockEnd - blockStart + 1;
% - min duration condition
blockStart( blockDuration < minDuration ) = [ ];
blockEnd( blockDuration < minDuration ) = [ ];

end


%% SubFunction: Average Heart Rate Calculation


function [runHeartRate] = AverageHeartRate( heartRate, startBeat, endBeat )

% Initialization
runHeartRate = single( zeros( length( startBeat ), 1 ) );
% Calculation
for runIndex = 1 : numel(startBeat)
    runHeartRate(runIndex) = round( mean( heartRate( double( startBeat( runIndex ) ) : double( endBeat( runIndex ) ) ) ) );
end

end