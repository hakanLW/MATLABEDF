disp( num2str( qrsComplexes.R( peak )  / 250 ) );
close all

subplot(4,1,[ 1 2 ] )
time = transpose( 1 : numel( ecgSignal2Analyze ) );
plot( time, ecgSignal2Analyze );
hold on
scatter( time( qrsComplexes.R ), ecgSignal2Analyze( qrsComplexes.R ), 'v' );
scatter( time( qrsComplexes.R(peak) ), ecgSignal2Analyze( qrsComplexes.R(peak) ), 'o', 'filled', 'MarkerEdgeColor','k', 'LineWidth',1);
scatter(time(qrsStartPoints), ecgSignal2Analyze(qrsStartPoints), 'v');
scatter(time(qrsQPoints), ecgSignal2Analyze(qrsQPoints), '^');
scatter(time(qrsSPoints), ecgSignal2Analyze(qrsSPoints), '^');
scatter(time(qrsEndPoints), ecgSignal2Analyze(qrsEndPoints), 'v');
% scatter(time(qrsWindowStartPoint), ecgSignal2Analyze(qrsWindowStartPoint), 'v');
% scatter(time(qrsWindowEndPoint), ecgSignal2Analyze(qrsWindowEndPoint), 'v');

if ( peak > 2 ) && ( peak + 3 ) <= length( qrsComplexes.R )
    xlim( round(  [ ( qrsComplexes.R( previousBeat ) - 250 )  qrsComplexes.R( peak + 3 ) ] )  )
else
    if peak <= 2
        xlim( round(  [ 1  qrsComplexes.R( peak + 3 ) ] )  )
    else
        xlim( round(  [ ( qrsComplexes.R( previousBeat ) - 250 )  qrsComplexes.R( end ) ] )  )
    end
end

% qrs window
qrsWindow = ecgSignal2Analyze( qrsWindowStart : qrsWindowEnd );
        
subplot(4,1,[ 3 4 ] )
time = 1:numel(qrsWindow);
plot(time,qrsWindow); 
hold on;
scatter(time(qrsWindowRPoint), qrsWindow(qrsWindowRPoint), 'r');

axis tight