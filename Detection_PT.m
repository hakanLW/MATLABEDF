
% PT Detection Algorithm
%
% [ qrsComplexes ] = Detection_PT( ecgRawSignal,  qrsComplexes, noisySample, vFibRun, recordInfo )
%
%  <<< Function Inputs >>>
%   single[n,1] ecgRawSignal
%   struct qrsComplexes
%   logical[n,1] noisySample
%   struct vFibRun
%   struct recordInfo
%
% <<< Function outputs >>>
%   struct  qrsComplexes
%

function [ qrsComplexes ] = Detection_PT( ecgRawSignal,  selectedChannel, qrsComplexes, recordInfo, analysisParameters )


% PREALLICATION
% - T wave
tWaveStartPoint = ones( length( qrsComplexes.R ), 1, 'single' );
tWavePeakPoint = ones( length( qrsComplexes.R ), 1, 'single' );
tWaveEndPoint  = ones( length( qrsComplexes.R ), 1, 'single' );
tWaveAmplitude = zeros( length( qrsComplexes.R ), 1, 'single' );
% - P wave
pWaveStartPoint = ones( length( qrsComplexes.R ), 1, 'single' );
pWavePeakPoint = ones( length( qrsComplexes.R ), 1, 'single' );
pWaveEndPoint  = ones( length( qrsComplexes.R ), 1, 'single' );
pWaveAmplitude = zeros( length( qrsComplexes.R ), 1, 'single' );
% - TP segment assesment
possibleSecondPWave = zeros( length( qrsComplexes.R ), 1, 'logical' );
% - Noisy intervals
noisyBeat = zeros( length( qrsComplexes.R ), 1, 'logical' );

% P & T WAVE DETECTION ALGORITHM
if ~isempty( qrsComplexes.R )
    
    % REMOVE BEATS
    %     for beatIndex = 1 : length( qrsComplexes.R )
    %         ecgRawSignal( qrsComplexes.StartPoint( beatIndex ) : qrsComplexes.EndPoint( beatIndex ) ) = 0;
    %     end
    
    % FILTER
    [ ...
        ecgRawSignal, ...
        ecgFiltered, ...
        ecgPeak, ...
        ecgWave ...
        ] = ClassPTDetection.PTDetectionFilter( ecgRawSignal, recordInfo.RecordSamplingFrequency, 0.050, 0.100  );
    
    % PARAMETERS
    asystoleThresholdBPM = ( 60 / ( analysisParameters.Asystole.ClinicThreshold / 1000 ) );
    
    % HEART RATE
    heartRate = [ 0; ClassRhythmAnalysis.CalculateHeartRate( qrsComplexes.R, recordInfo.RecordSamplingFrequency ) ];
    
    % MAIN
    for beatIndex = 2 : length( qrsComplexes.R )
        
        
        % INITIALIZATION
        % - Blocks
        pBlock = [ ];
        tBlock = [ ];
        blockStart = [ ];
        blockEnd = [ ];
        blockDensity = [ ];
        % - RR Interval
        beatInterval = qrsComplexes.R( beatIndex ) - qrsComplexes.R( beatIndex - 1 );
        beatHeartRate = heartRate( beatIndex );
        % - Interval Data Points
        dataStart = double( qrsComplexes.EndPoint( beatIndex - 1 ) ); dataStart = dataStart + 5;
        dataEnd = double( qrsComplexes.StartPoint( beatIndex ) ); dataEnd = dataEnd - 5 ;
        dataPoints = transpose( double( dataStart : dataEnd ) );
        
        
        if ...
                ( beatHeartRate < asystoleThresholdBPM ) || ...
                ( length(dataPoints) < 0.050 * recordInfo.RecordSamplingFrequency )
            
            % Dont analyse the interval if the duration is larger than an
            % asystole threshold
            
        else
            
            % SIGNALS
            intervalRawSignal = ecgRawSignal( dataPoints );
            intervalFilteredSignal = ecgFiltered( dataPoints );
            intervalPeak = ecgPeak( dataPoints );
            intervalPWave = ecgWave( dataPoints );
            
            % NOISE CONTROL
            % Filter
            windowLength = single( 5 );
            intervalNoiseControlSignal = ClassFilter.MovingAverageFilter( intervalRawSignal, windowLength, true );
            % - general distribution
            distribution = abs( intervalRawSignal - intervalNoiseControlSignal );
            % adjustment the diff cause by moving average window
            if length( distribution ) > windowLength * 2
                distribution( double( 1 ) : double( windowLength ) ) = single( 0 );
                distribution( double( end - ( windowLength - 1) ) : double( end ) ) = single( 0 );
            else
                distribution = zeros( length( intervalFilteredSignal ), 1, 'single' );
            end
            % - distribution problem
            distributionPower = sum( distribution( abs( distribution ) > 0.02 ) ) / ( length( intervalRawSignal ) / recordInfo.RecordSamplingFrequency );
            % GET BLOCKS IF THERE IS NO NOISE
            if ( distributionPower >= 1 )
                % noise flag
                noisyBeat( beatIndex ) = true;
                blockStart = [ ]; blockEnd = [ ];
            else
                % BLOCKS
                [blockStart, blockEnd] = ClassPTDetection.BlockDetection ( intervalPeak, intervalPWave, 0 );
                if ~isempty( blockStart )
                    blockStart = blockStart( end );
                    blockEnd = blockEnd( end );
                end
                % Assessments of the blocks
                for blockIndex = 1 : length( blockStart )
                    % Block Characterization
                    if ... % For reversed qrs, check the last block
                            ( qrsComplexes.Type( beatIndex ) < 0 ) && ...
                            ( blockEnd( blockIndex ) > ( length( dataPoints ) - 3 ) )
                        blockStart( blockIndex : end) = [ ]; blockEnd( blockIndex :end ) = [ ];
                        break
                    else
                        % block range
                        [ wave] =  ClassPTDetection.GetWave( ...
                            intervalFilteredSignal, ...% bufferRawSignal
                            blockStart( blockIndex ), ... % waveStart
                            blockEnd( blockIndex ) );  ... % waveEnd
                            % Final Block
                        blockStart( blockIndex, 1 ) = wave.Start;
                        blockEnd( blockIndex, 1 ) = wave.End;
                    end
                end
                % Assesment Parameters
                if ~isempty( blockStart )
                    % Positioning
                    blockSignalPlot = zeros( length( dataPoints ), 1, 'single' );
                    for blockIndexPlot = 1 : length( blockStart)
                        blockSignalPlot( blockStart(blockIndexPlot) : blockEnd(blockIndexPlot) ) = 0.1;
                    end
                    blockSignalPlot( 1 ) = 0; blockSignalPlot( end ) = 0;
                    [blockStart, blockEnd] = ClassPTDetection.BlockDetection( blockSignalPlot, zeros( length( dataPoints ), 1, 'single' ), 0 );
                    % Density
                    blockDensity = ClassPTDetection.CalculateBlockArea( blockStart, blockEnd, intervalRawSignal );
                    [blockStart, blockEnd ] = ClassPTDetection.RemoveBlock( blockStart, blockEnd, ( blockDensity < 0.5 ) ); blockDensity( blockDensity < 0.5 ) = [ ];
                    % After the assessment
                    blockPeak = ClassPTDetection.CalculateBlockMax( blockStart, blockEnd, intervalRawSignal );
                end
                
            end
            
        end
                
        % EARLY BLOCK DETERMINATION:
        if ...
                noisyBeat( beatIndex ) || ...
                ( beatHeartRate < asystoleThresholdBPM )
            
            % Noisy interval
            % - tBlock
            tBlock = [ ];
            pBlock = [ ];
            % atrial beats
            qrsComplexes.AtrialBeats( beatIndex ) = false;
            % ventriculart beats
            qrsComplexes.VentricularBeats( beatIndex ) = false;
            
            
        else
            
            % Indexes that have highest two areas
            if length( blockStart ) > 1
                tempArea = blockDensity;
                tempIndexes = zeros( 2,1, 'single' );
                tempIndexes(1) = find( tempArea == max( tempArea ), 1, 'last' );
                tempArea(tempIndexes(1))      = -Inf;
                tempIndexes(2) = find( tempArea == max( tempArea ), 1, 'last' );
            end
            
            % Pre-Decision: vol1 - very close waves
            if length( blockStart ) > 1
                if abs( diff( tempIndexes ) ) == 1
                    blockIntervals = [ 0; blockStart( 2:end ) - blockEnd( 1:end-1 ) ];
                    if blockIntervals( max( tempIndexes ) ) <= 20
                        if blockStart( max( tempIndexes ) ) >= 0.300 * recordInfo.RecordSamplingFrequency
                            pBlock = max( tempIndexes );
                            tBlock = min( tempIndexes );
                        end
                    end
                end
            end
            
            % Pre-Decision: vol2 - ideal condition
            if length( blockStart ) > 1 && isempty( pBlock )
                if ( blockEnd( tempIndexes( 1 ) ) <= 0.5 * beatInterval ) &&...
                        ( blockStart( tempIndexes( 2 ) ) >= 0.5 * beatInterval )
                    pBlock = max( tempIndexes );
                    tBlock = min( tempIndexes );
                end
            end
            
        end
        
        % SECONDARY BLOCK DETERMINATION:
        % Case : Number of blocks
        
        if isempty( pBlock ) && isempty( tBlock )
            
            switch length( blockStart )
                
                case 0
                    
                    % If there is no block left that fits requirments
                    % - tblock
                    tBlock = [ ];
                    % - pblock
                    pBlock = [ ];
                    
                case 1
                    
                    % if the only block is possible T range
                    % - tblock
                    possibleT = ( blockStart < 0.500 * beatInterval );
                    tBlock = sum( possibleT ); if tBlock == 0; tBlock = [ ]; end
                    % - pblock
                    if isempty( tBlock )
                        possibleP = blockEnd > ( beatInterval -  fix( 0.300 * recordInfo.RecordSamplingFrequency ) );
                        pBlock = find( possibleP == true );
                        if length( pBlock ) > 1; pBlock = find( blockDensity == max( blockDensity( pBlock ) ), 1, 'last'  ); end
                    else
                        pBlock = [ ];
                    end
                    
                otherwise
                    
                    % Possible T and P blocks
                    if heartRate( beatIndex ) < analysisParameters.Bradycardia.ClinicThreshold
                        % - PossibleT
                        possibleT = ( blockStart < fix( 0.250 * beatInterval ) );
                        % - PossibleP
                        possibleP = blockEnd > ( beatInterval -  fix( 0.500 * beatInterval ) );
                    else
                        % - PossibleT
                        possibleT = ( blockStart < fix( 0.500 * beatInterval ) );
                        % - PossibleP
                        possibleP = blockEnd > ( beatInterval -  fix( 0.500 * beatInterval ) );
                    end
                    % If there is no common block
                    if ~sum( possibleT & possibleP )
                        
                        if ~sum( possibleT ) % if there is no possible T block, that interval may be problemetic.
                            
                            % - tblock
                            tBlock = [ ];
                            % - pblock
                            pBlock = [ ];
                            
                        else
                            
                            % tBlock
                            tBlock = find( possibleT == true );
                            if length( tBlock ) > 1; tBlock = find( blockDensity == max( blockDensity( tBlock ) ), 1, 'first'  ); end
                            
                            % pBlock
                            pBlock = find( possibleP == true );
                            if length( pBlock ) > 1; pBlock = find( blockDensity == max( blockDensity( pBlock ) ), 1, 'last'  ); end
                            
                        end
                        
                    else %  if ~sum( possibleT & possibleP )
                        
                        % tBlock
                        tBlock = find( possibleT == true );
                        if length( tBlock ) > 1; tBlock = find( blockDensity == max( blockDensity( tBlock ) ), 1, 'first'  ); end
                        
                        % pBlock
                        if tBlock == length( blockStart )
                            pBlock = [ ];
                        else
                            pBlock = find( possibleP == true );
                            if intersect( tBlock, pBlock )
                                pBlock( pBlock == tBlock ) = [ ];
                            end
                            if sum( pBlock ) > 1; pBlock = find( blockDensity == max( blockDensity( pBlock ) ), 1, 'last'  ); end
                        end
                        
                    end %  if ~sum( possibleT & possibleP )
                    
            end % switch length( blockStart )
            
        end % if isempty( pBlock ) && isempty( tBlock )
        
        %% T WAVE
        % - Points
        if isempty( tBlock ); tempT.Start = 1; else; tempT.Start = blockStart( tBlock ) + dataStart - 1; end
        if isempty( tBlock ); tempT.End = 1; else; tempT.End = blockEnd( tBlock ) + dataStart - 1; end
        if isempty( tBlock ); tempT.Peak = 1; else;  tempT.Peak = blockPeak( tBlock ) + dataStart - 1; end
        % - Slope
        % - Amplitude
        if tempT.Start ~= 1
            % Get Amplitude
            tAmplitude = ClassPTDetection.CalculateBlockAmplitude( tempT.Start, tempT.End, ecgRawSignal );
            % Assessment
            if ( tAmplitude > 0.05 )
                tWaveAmplitude( beatIndex )  = tAmplitude;
            else
                tempT.Start = 1; tempT.Peak = 1; tempT.End = 1;
            end
        end
        % - Annotation
        tWaveStartPoint(beatIndex - 1)  = tempT.Start;
        tWavePeakPoint(beatIndex - 1)  = tempT.Peak;
        tWaveEndPoint(beatIndex - 1)   = tempT.End;
        
        %% P WAVE
        % - Points
        if isempty( pBlock ); tempP.Start = 1; else; tempP.Start = blockStart( pBlock ) + dataStart - 1; end
        if isempty( pBlock ); tempP.End = 1; else; tempP.End = blockEnd( pBlock ) + dataStart - 1; end
        if isempty( pBlock ); tempP.Peak = 1; else; tempP.Peak = blockPeak( pBlock ) + dataStart - 1; end
        % - Amplitude
        if tempP.Start ~= 1
            % Get Amplitude
            pAmplitude = ClassPTDetection.CalculateBlockAmplitude( tempP.Start, tempP.End, ecgRawSignal );
            % Assessment
            if ( pAmplitude > 0.05 )
                pWaveAmplitude( beatIndex )  = pAmplitude;
            else
                tempP.Start = 1; tempP.Peak = 1; tempP.End = 1;
            end
        end
        % - Annotation
        pWaveStartPoint(beatIndex) = tempP.Start;
        pWavePeakPoint(beatIndex) = tempP.Peak;
        pWaveEndPoint(beatIndex) = tempP.End;
        
        %         if qrsComplexes.R( beatIndex ) > 1395 * recordInfo.RecordSamplingFrequency
        %             plotDeveloper_pt
        %         end
        
        %% SECONDARY P WAVE
        %         if false % ~noisyBeat( beatIndex )
        %
        %             if ...
        %                     ... T and P Wave should be detected
        %                     ~(  tempT.Start == 1 ) && ...
        %                     ~(  tempP.Start == 1 ) && ...
        %                     ... At least 3 blocks should be detected
        %                     ( length( blockStart ) > 2 ) && ...
        %                     ... Heart rate should be under breadycardia limit
        %                     ( beatHeartRate < analysisParameters.Bradycardia.ClinicThreshold )
        %
        %                 if ~isempty( pBlock )
        %                     % Stock Values
        %                     stockBlockArea = ClassPTDetection.CalculateBlockAmplitude( blockStart, blockEnd, intervalRawSignal );
        %                     % get p block density
        %                     pBlockArea = stockBlockArea( pBlock );
        %                     % dismiss t & p block density
        %                     stockBlockArea( [ transpose(1:tBlock); pBlock ] ) = 0;
        %                     % search for similiar p block density
        %                     % - limits / density
        %                     similiarAreaMinLimit = pBlockArea * 0.66;
        %                     similiarAreaMaxLimit = pBlockArea * 1.33;
        %                     % - search
        %                     isSimiliarDensity = find( ...
        %                         ( stockBlockArea >= similiarAreaMinLimit ) & ...
        %                         ( stockBlockArea <= similiarAreaMaxLimit ) ...
        %                         );
        %                     % flag
        %                     if isSimiliarDensity
        %                         % Flag
        %                         possibleSecondPWave( beatIndex ) = true;
        %                     end
        %
        %                 end
        %             end
        %         end
        
    end
    
    % OUTPUT: Detection Channel
    qrsComplexes.DetectionChannel = find( string( recordInfo.ActiveChannels ) == string( selectedChannel ) == 1 ) * ones( length( qrsComplexes.R ), 1, 'int32' );
    % OUTPUT: T Wave
    qrsComplexes.T.StartPoint = tWaveStartPoint;
    qrsComplexes.T.PeakPoint = tWavePeakPoint;
    qrsComplexes.T.EndPoint = tWaveEndPoint;
    qrsComplexes.T.Amplitude = tWaveAmplitude;
    % OUTPUT: P Wave
    qrsComplexes.P.StartPoint = pWaveStartPoint;
    qrsComplexes.P.PeakPoint = pWavePeakPoint;
    qrsComplexes.P.EndPoint = pWaveEndPoint;
    qrsComplexes.P.Amplitude = pWaveAmplitude;
    % OUTPUT: TP Segment Assesment
    qrsComplexes.SecondPWave = possibleSecondPWave;
    % OUTPUT: Noisy Beat
    qrsComplexes.NoisyBeat = noisyBeat;
%     % AtrialBeats
%     qrsComplexes.AtrialBeats( qrsComplexes.P.PeakPoint > 1 ) = false;
%     % VentriculerBeats
%     qrsComplexes.VentricularBeats( qrsComplexes.P.PeakPoint > 1 ) = false;
    
else
    
    % OUTPUT: Detection Channels
    qrsComplexes.DetectionChannel = single( [ ] );
    % OUTPUT: T Wave
    qrsComplexes.T.StartPoint = single( [ ] );
    qrsComplexes.T.PeakPoint = single( [ ] );
    qrsComplexes.T.EndPoint = single( [ ] );
    qrsComplexes.T.Amplitude = single( [ ] );
    % OUTPUT: P Wave
    qrsComplexes.P.StartPoint = single( [ ] );
    qrsComplexes.P.PeakPoint = single( [ ] );
    qrsComplexes.P.EndPoint = single( [ ] );
    qrsComplexes.P.Amplitude = single( [ ] );
    % OUTPUT: TP Segment Assesment
    qrsComplexes.SecondPWave = single( [ ] );
    % - OUTPUT: Noisy Beat
    qrsComplexes.NoisyBeat = single( [ ] );
    
end

end
