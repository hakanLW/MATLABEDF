close all; figure;
disp( [ 'Time: ' num2str( unusualPeriodStartPoint / RecordInfo.RecordSamplingFrequency ) ] );
% periodSignalStart = double( UnusualECGPeriodStart( periodIndex ) ) * double( RecordInfo.RecordSamplingFrequency ) + double( 1 );
% periodSignalEnd = double( UnusualECGPeriodEnd( periodIndex ) ) * double( RecordInfo.RecordSamplingFrequency );
% periodSignalPoints = periodSignalStart : periodSignalEnd;

periodSignal_Lead2 = ECGSignals.Lead2( unusualPeriodPoints );
% periodSignal_V5 = ECGSignals.V5( unusualPeriodPoints );

subplot( 4,1,[ 1 2 ] )
plot( periodSignal_Lead2,  'r', 'LineWidth', 0.5 );
title( 'Lead2' );
grid on
axis tight

% subplot(4,1,[ 3 4 ]);
% plot( periodSignal_V5,  'r', 'LineWidth', 0.5 );
% title( 'V5' );
% grid on
% axis tight
