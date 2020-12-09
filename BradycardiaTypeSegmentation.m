function [ bradyRuns, avDegree1Runs, avDegree2_t1Runs, avDegree2_t2Runs, avDegree3Runs ] = BradycardiaTypeSegmentation( ...
    qrsComplexes, ...
    bradyRuns, ....
    recordInfo, ...
    analysisParameters ...
    )

% Initialization
% - sinus bradycardia
if ~isempty( bradyRuns ) 
    sinBradyIndex = bradyRuns.BeatFlag;
else
    sinBradyIndex = zeros( length( qrsComplexes.R ), 1, 'logical' );
end
% - av block degree 1
avDegree1Index = zeros( length( qrsComplexes.R ), 1, 'logical' );
% - av block degree 2 type 1
avDegree2_t1Index = zeros( length( qrsComplexes.R ), 1, 'logical' );
% - av block degree 2 type 2
avDegree2_t2Index = zeros( length( qrsComplexes.R ), 1, 'logical' );
% - av block degree 3
avDegree3Index = zeros( length( qrsComplexes.R ), 1, 'logical' );


% Check if there is a brady run
if ~isempty( bradyRuns )
    % Evaluation for each brady run
    for bradyIndex = 1 : length( bradyRuns.StartTime )        
        % Check if the brady run is caused by paused beats
        runBeatIndexes = double( bradyRuns.StartBeat( bradyIndex ) ) : double( bradyRuns.EndBeat( bradyIndex ) );
        % Check if there is paused based beats
        if all( qrsComplexes.HeartRate( runBeatIndexes ) <= ( 60 / ( analysisParameters.Pause.ClinicThreshold / 1000 ) ) )
            sinBradyIndex( runBeatIndexes ) = false;
        else
            sinBradyIndex( runBeatIndexes( qrsComplexes.HeartRate( runBeatIndexes ) > analysisParameters.Bradycardia.ClinicThreshold ) ) = false;
        end        
    end    
end

% Packet ventricular tachycardia run
% - min beat duration: 5
bradyRuns = PacketRun( qrsComplexes, sinBradyIndex, 5, false, recordInfo );
% - min beat duration: 5
avDegree1Runs = PacketRun( qrsComplexes, avDegree1Index, 5, false, recordInfo );
% - min beat duration: 5
avDegree2_t1Runs = PacketRun( qrsComplexes, avDegree2_t1Index, 5, false, recordInfo );
% - min beat duration: 5
avDegree2_t2Runs = PacketRun( qrsComplexes, avDegree2_t2Index, 5, false, recordInfo );
% - min beat duration: 5
avDegree3Runs = PacketRun( qrsComplexes, avDegree3Index, 5, false, recordInfo );

end


%% SubFunction : Run Packet

function [ run ] = PacketRun( qrsComplexes, runPoints, minBeatDuration, singleBeatBrady, recordInfo )

if any( runPoints )
    
    % start and end beats
    if singleBeatBrady
        % get beat edges
        endBeat = ...
            find( runPoints );
        startBeat = ...
            find( runPoints ) - 1;
        % ignore first beat
        endBeat( startBeat < 1 ) = [ ];
        startBeat( startBeat < 1 ) = [ ];
    else
        % get beat edges
        [ startBeat, endBeat ] = ...
            BlockSegmentation( runPoints, minBeatDuration );
    end
    
    % check if there is run
    if ~isempty( startBeat )
        
        % start and end time
        if singleBeatBrady
            beatStartTime = ...
                ( qrsComplexes.R(1:end) / recordInfo.RecordSamplingFrequency );
            beatEndTime = ...
                ( qrsComplexes.R(1:end) / recordInfo.RecordSamplingFrequency );
        else
            beatStartTime = ...
                ( qrsComplexes.StartPoint(1:end) / recordInfo.RecordSamplingFrequency );
            beatEndTime = ...
                ( qrsComplexes.EndPoint(1:end) / recordInfo.RecordSamplingFrequency );
        end
        
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
        if singleBeatBrady
            % - time based duration
            run.Duration = ...
                round( 1000 * ( qrsComplexes.R( run.EndBeat ) - qrsComplexes.R( run.StartBeat ) ) / recordInfo.RecordSamplingFrequency );
        else
            % - beat based duration
            run.Duration = ...
                endBeat - startBeat + 1;
        end
        % - heart rate
        if singleBeatBrady
            % - beat  heart rate
            run.AverageHeartRate = ...
                AverageHeartRate( qrsComplexes.HeartRate, endBeat, endBeat );
        else
            % - run heart rate
            run.AverageHeartRate = ...
                AverageHeartRate( qrsComplexes.HeartRate, startBeat, endBeat );
        end
        % - beat flag
        % - - initialization
        run.BeatFlag = zeros( length( qrsComplexes.R ), 1, 'logical' );
        % - - rise flag
        if singleBeatBrady
            run.BeatFlag = runPoints;
        else
            for runIndex = 1 : length( run.StartBeat )
                run.BeatFlag( double( run.StartBeat( runIndex ) ) : double( run.EndBeat( runIndex ) ) ) = true;
            end
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