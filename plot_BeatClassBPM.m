% initialize
close all; 

% time
timeSignal = 1 : length( ecgSignal );


% startPoint
startPoint = max( 0, ( qrsComplexes.R( beatIndex ) - 250 * 5 ) );
endPoint = min( length( ecgSignal ), ( qrsComplexes.R( beatIndex ) + 250 * 5 ) );

% plot
subplot(3,1,1)
plot( timeSignal, ecgSignal, 'b' ); hold on; grid on;
scatter( timeSignal( qrsComplexes.R ), ecgSignal( qrsComplexes.R ),  'v', 'filled', 'MarkerEdgeColor','k', 'MarkerFaceColor', 'k', 'LineWidth',1.5);
scatter( timeSignal( qrsComplexes.R( beatIndex ) ), ecgSignal( qrsComplexes.R( beatIndex ) ),  'v', 'filled', 'MarkerEdgeColor','r', 'MarkerFaceColor', 'r', 'LineWidth',1.5);
xlim( [ startPoint endPoint ] )

% startPoint
startPoint = max( 0, ( qrsComplexes.R( beatIndex ) - 250 * 5 ) );
endPoint = min( length( ecgSignal ), ( qrsComplexes.R( beatIndex ) +250 * 20 ) );

% plot
subplot(3,1,[ 2 3 ])
plot( timeSignal, ecgSignal, 'b' ); hold on; grid on;
scatter( timeSignal( qrsComplexes.R ), ecgSignal( qrsComplexes.R ),  'v', 'filled', 'MarkerEdgeColor','k', 'MarkerFaceColor', 'k', 'LineWidth',1.5);
scatter( timeSignal( qrsComplexes.R( beatIndex ) ), ecgSignal( qrsComplexes.R( beatIndex ) ),  'v', 'filled', 'MarkerEdgeColor','r', 'MarkerFaceColor', 'r', 'LineWidth',1.5);
xlim( [ startPoint endPoint ] )

