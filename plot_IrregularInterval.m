% % Beat Times
% beatTimes = qrsComplexes.R/recordInfo.RecordSamplingFrequency;
%
% % Plot
% close all;
% figure;
%
% % - FIGURE 1
% subplot(3,1, 1 )
% plot( diff( qrsComplexes.R ) );
%
% axis tight;
% grid on;
% % - FIGURE 3
% subplot(3,1,3)
% % - block plot
% blockSignal = zeros( length(rrIntervalChange ), 1, 'single' );
% for i = 1 : length( AFib.StartBeat )
%     blockSignal( AFib.StartBeat( i ) : AFib.EndBeat( i ) ) = 1;
% end
% blockSignal(1) = 0;
% blockSignal(end) = 0;
% plot( beatTimes, rrIntervalChange ); hold on;
% plot( beatTimes, blockSignal );
% plot( beatTimes, irregularThreshold * ones( length( qrsComplexes.R ), 1 ), 'r:', 'LineWidth', 2 )
% axis tight;
% ylim( [ 0 1.25 ] )
% grid on;

if exist( 'AFib' )
    intervalStart = AFib.StartBeat;
    intervalEnd = AFib.EndBeat;
else
    startTime = qrsComplexes.R( intervalBeatIndexes( 1 ) ) / 250 ;
    startMin = fix( startTime / 60 ); startMinChar = num2str( startMin ); if numel( startMinChar ) == 1; startMinChar = [ '0' num2str( startMin ) ]; end
    startSec = round( startTime - startMin * 60 ); startSecChar = num2str( startSec ); if numel( startSecChar ) == 1; startSecChar = [ '0' num2str( startSec ) ]; end
    disp( [ 'Interval Start Time: ' startMinChar ':' startSecChar '  -  ' num2str(startTime) ] )
    endTime = qrsComplexes.R( intervalBeatIndexes( end ) ) / 250 ;
    endMin = fix( endTime / 60 );  endMinChar = num2str( endMin ); if numel( endMinChar ) == 1; endMinChar = [ '0' num2str( endMin ) ]; end
    endSec = round( endTime - endMin * 60 ); endSecChar = num2str( endSec ); if numel( endSecChar ) == 1; endSecChar = [ '0' num2str( endSec ) ]; end
    disp( [ 'Interval End Time: ' endMinChar ':' endSecChar '  -  ' num2str(endTime) ] )
end
dataStart = qrsComplexes.StartPoint( intervalStart( intervalIndex ) );
dataEnd = qrsComplexes.EndPoint( intervalEnd( intervalIndex ) );
% select interval

% empty qrs
emptyQRS.StartPoint = qrsComplexes.StartPoint( intervalBeatIndexes ) - dataStart + 1;
emptyQRS.Q = qrsComplexes.Q( intervalBeatIndexes ) - dataStart + 1;
emptyQRS.R = qrsComplexes.R( intervalBeatIndexes ) - dataStart + 1;
emptyQRS.S = qrsComplexes.S( intervalBeatIndexes ) - dataStart + 1;
emptyQRS.EndPoint = qrsComplexes.EndPoint( intervalBeatIndexes ) - dataStart + 1;
emptyQRS.T.StartPoint = qrsComplexes.T.StartPoint( intervalBeatIndexes ) - dataStart + 1;
emptyQRS.T.EndPoint = qrsComplexes.T.EndPoint( intervalBeatIndexes ) - dataStart + 1;
emptyQRS.T.PeakPoint = qrsComplexes.T.PeakPoint( intervalBeatIndexes ) - dataStart + 1;
emptyQRS.T.Amplitude = ones( length( qrsComplexes.R ), 1, 'single' );
emptyQRS.T.Status = ones( length( qrsComplexes.R ), 1, 'single' );
emptyQRS.P.StartPoint = qrsComplexes.P.StartPoint( intervalBeatIndexes ) - dataStart + 1;
emptyQRS.P.PeakPoint = qrsComplexes.P.PeakPoint( intervalBeatIndexes ) - dataStart + 1;
emptyQRS.P.EndPoint = qrsComplexes.P.EndPoint( intervalBeatIndexes ) - dataStart + 1;
emptyQRS.P.Amplitude = ones( length( qrsComplexes.R ), 1, 'single' );
emptyQRS.VentricularBeats = zeros( length( qrsComplexes.R ), 1, 'single' );
emptyQRS.FlutterBeats = zeros( length( qrsComplexes.R ), 1, 'single' );
emptyQRS.AtrialBeats = zeros( length( qrsComplexes.R ), 1, 'single' );
emptyQRS.NoisyBeat = zeros( length( qrsComplexes.R ), 1, 'single' );
% Plot
PlotWaves(ecgSignals.Lead2( dataStart:dataEnd ), ecgSignals.Lead1( dataStart:dataEnd ), emptyQRS, [ ], [ ], false, true);

