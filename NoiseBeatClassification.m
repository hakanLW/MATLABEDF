function [ qrsComplexes, signalNoise ] = NoiseBeatClassification( ecgSignal, qrsComplexes, recordInfo )

% Signal Peak Detection
[ qrsComplexes, signalNoise ] = SignalPeakDetection( ecgSignal, qrsComplexes, recordInfo );

% Clear QRS with Noise
% - indexes
[ ~, noiseBeatIndexes ] = intersect( qrsComplexes.R, find( signalNoise ) );
% - clear
[ qrsComplexes ] = ClassUnusualSignalDetection.ClearQRS( qrsComplexes, noiseBeatIndexes );

end

%% subFunction: Signal Peak Detection

function [ qrsComplexes, noiseFlag ]= SignalPeakDetection( ecgSignal, qrsComplexes, recordInfo )

% Initialization
noiseFlag = zeros( length( ecgSignal ), 1, 'logical' );

% NOISE ASSESSMENT
if ~isempty( qrsComplexes ) && ~isempty( qrsComplexes.R )
    
    % QRS amplitude based noise detection
    qrsAmplitudeThreshold = fitdist( double( qrsComplexes.QRSAmplitude ), 'normal' );
    qrsAmplitudeThreshold = qrsAmplitudeThreshold.mu * 10;
    % Noise Flag
    noiseFlag( abs( ecgSignal ) > qrsAmplitudeThreshold ) = true;
    % Block
    [ nStart, nEnd ] = BlockSegmentation( noiseFlag );
    % Expend the blocks
    nStart = ...
        nStart - recordInfo.RecordSamplingFrequency;
    nEnd = ...
        nEnd + recordInfo.RecordSamplingFrequency;
    
else
    
    % Output
    nStart = [ ];
    nEnd = [ ];
    
end

% CLEAR QRS
for noiseIndex = 1 : length( nStart )
    
    % noise points
    noisePoints = nStart( noiseIndex ) : nEnd( noiseIndex );
    % flag
    noisePoints( noisePoints > length( ecgSignal ) ) = [ ];
    noisePoints( noisePoints < 1 ) = [ ];
    noiseFlag( noisePoints ) = true;
    
end

% PLOT
% plot_NoiseBeatClassification_p1

end



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