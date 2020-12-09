
% % PLOT
% Initialization
close all
figure;
% Plot figures
plots(1) = subplot(2,1,1);
plot( ecgSignal ); hold on;
plots(2) = subplot(2,1,2);
plot( noiseFlag ); hold on; ylim( [ 0 2 ] )
linkaxes([plots], 'x');
zoom on;