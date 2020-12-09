% Initialization
close all
figure;

% Workspace Display
beatIndexTime = qrsComplexes.R( beatIndex - 1 ) / 250;
disp( [ 'beatIndex time: ' num2str( beatIndexTime ) ] );
disp( [ 'P Block: ' num2str( pBlock ) ] )
disp( [ 'T Block: ' num2str( tBlock ) ] )

% ECG Signal
qrsStartPoints = qrsComplexes.StartPoint;
qrsEndPoints = qrsComplexes.EndPoint;
rPoints = qrsComplexes.R;
ecgSignal = ecgRawSignal;
subplot(4,2,[ 1 2 3 4])
timeSignal = ( 1 : length( ecgSignal ) );
plot( timeSignal, ecgRawSignal ); hold on;
scatter(timeSignal(qrsStartPoints), ecgSignal(qrsStartPoints), 'r', 'MarkerEdgeColor','m', 'LineWidth',1);
scatter(timeSignal(rPoints), ecgSignal(rPoints), 'v', 'filled', 'MarkerEdgeColor','k', 'MarkerFaceColor', 'k', 'LineWidth',1.5);
scatter(timeSignal(qrsEndPoints), ecgSignal(qrsEndPoints), 'r', 'MarkerEdgeColor','m', 'LineWidth',1);
scatter(timeSignal(pWaveStartPoint), ecgSignal(pWaveStartPoint), 'x', 'MarkerEdgeColor','k', 'LineWidth',1);
scatter(timeSignal(pWavePeakPoint), ecgSignal(pWavePeakPoint), 'x', 'MarkerEdgeColor','k', 'LineWidth',1);
scatter(timeSignal(pWaveEndPoint), ecgSignal(pWaveEndPoint), 'x', 'MarkerEdgeColor','k', 'LineWidth',1);
scatter(timeSignal(tWaveStartPoint), ecgSignal(tWaveStartPoint), '+', 'MarkerEdgeColor','k', 'LineWidth',1);
scatter(timeSignal(tWavePeakPoint), ecgSignal(tWavePeakPoint), '+', 'MarkerEdgeColor','k', 'LineWidth',1);
scatter(timeSignal(tWaveEndPoint), ecgSignal(tWaveEndPoint), '+', 'MarkerEdgeColor','k', 'LineWidth',1);
if ( beatIndex > 2 ) && ( beatIndex + 3 ) <= length( qrsStartPoints )
    xlim( round(  [ ( qrsStartPoints( beatIndex - 2) - 20 )  qrsEndPoints( beatIndex + 3 ) ] )  )
else
    if beatIndex <= 2
        xlim( round(  [ 1  qrsEndPoints( beatIndex + 3 ) ] )  )
    else
        xlim( round(  [ ( qrsStartPoints( beatIndex - 2) - 20 )  qrsEndPoints( end ) ] )  )
    end
end
grid on;
title( 'ECG Signal' );

if ~exist( 'blockStart' ); blockStart = []; end
if ~exist( 'blockEnd' ); blockEnd = []; end

% BLOCK SIGNAL
if ~isempty( blockStart )
    blockSignalPlot = zeros( length( dataPoints ), 1, 'single' );
    for blockIndexPlot = 1 : length( blockStart)
        blockSignalPlot( blockStart(blockIndexPlot) : blockEnd(blockIndexPlot) ) = 0.1;
    end
    blockSignalPlot( ( blockEnd(blockIndexPlot) + 1 ) : length( intervalFilteredSignal ) ) = 0;
else
    blockSignalPlot = zeros( length( dataPoints ), 1, 'single' );
end

% DEBUG PLOT
subplot(4,2,[ 5 7 ] );
time = transpose( 1 : length( intervalFilteredSignal ) );
plot( intervalPeak ); hold on;
plot( intervalPWave );
plot( blockSignalPlot, 'k' );
axis tight;
grid on;
title( 'Blocks' );

% RAW vs FILTERED SIGNAL
subplot(4,2,[ 6 8 ] );
plot( intervalRawSignal ); axis tight; grid on; hold on;
plot( intervalFilteredSignal ); 
plot( blockSignalPlot, 'k' );
title( 'Raw vs Filtered' );
