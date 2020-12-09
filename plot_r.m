%% BEFORE TO USE THIS, IMPLEMENT FOLLOWING CODES IN SPECIFIED AREAS...

%-- INITIALIZATION OF THE R DETECTION

% % FOR PLOTTING
% MeanNoise_smoothed  = [ ];
% MeanSignal_smoothed  = [ ];
% 
% MeanNoise_bandpassed = [ ];
% MeanSignal_bandpassed  = [ ];


%-- END OF THE R DETECTION

%     %% FOR PLOTTING
%     
%     MeanNoise_smoothed  = [MeanNoise_smoothed;  poweredNoiseThreshold];
%     MeanSignal_smoothed  = [MeanSignal_smoothed;  poweredSignalThreshold];
%     
%     MeanNoise_bandpassed = [MeanNoise_bandpassed;  bandPassedNoiseThreshold];
%     MeanSignal_bandpassed  = [MeanSignal_bandpassed;  bandPassedSignalThreshold];

%%
close all;

index = peakIndex;

xlimMin = pPeakIndex(index) - 750; if xlimMin < 1; xlimMin = 1; end
xlimMax = xlimMin + 1500; if xlimMax > numel(ecgRaw); xlimMax = numel(ecgRaw); end

xlimFilteredMin = pPeakIndex(index) - 200; if xlimFilteredMin < 1; xlimFilteredMin = 1; end
xlimFilteredMax = xlimFilteredMin + 400; if xlimFilteredMax > numel(ecgRaw); xliilteredMax = numel(ecgRaw); end

%% raw
subplot(4,1,1)
time = (1 : numel(ecgRaw)) / 1;
plot(time, ecgRaw); grid on; hold on;
scatter(time(rPoints), ecgRaw(rPoints), 'r');

xlim( [ xlimMin xlimMax ] / 1)
title([ 'Raw Signal mins: [ ' num2str( round ( [ xlimMin xlimMax ]/250) ) ' ]' ] )


%% derivatived + bandpassed

subplot(4,1,2)
plot( ecgRaw/max(ecgRaw), 'r'); grid on; hold on;
plot( abs(ecgBandPassed)/max(abs(ecgBandPassed)), 'k');

legend('ecgRaw', 'ecgBandPassedAbs' , 'location', 'northeast')
xlim( [ xlimFilteredMin xlimFilteredMax ] )
title('ecgRaw & abs(ecgBandPassed)')

%% bandpassed
subplot(4,1,3)
time = 1 : numel(ecgBandPassed);
plot(time, ecgBandPassed); grid on; hold on;

if index > 3
    
    localPeaks = pPeakIndex(1: numel(MeanNoise_bandpassed) + 1  );
    meanNoise = [MeanNoise_bandpassed; MeanNoise_bandpassed(end)];
    meanSignal = [MeanSignal_bandpassed; MeanSignal_bandpassed(end)];
    
    plot(localPeaks,meanNoise,'LineWidth',1,'Linestyle','--','color','r');
    plot(localPeaks,meanSignal,'LineWidth',1,'Linestyle','--','color','g');

end

xlim( [ xlimFilteredMin xlimFilteredMax ] )
title('Bandpassed Signal')

%% powered
subplot(4,1,4)
signalLength = numel(ecgPowered);
time = 1 : signalLength;
plot(time, ecgPowered); grid on; hold on;
scatter(time(pPeakIndex), ecgPowered(pPeakIndex), 'r' )
scatter(time(rPointsPoweredIndexes), ecgPowered(rPointsPoweredIndexes), 'v', 'MarkerEdgeColor','k', 'LineWidth', 2);

if index > 3
    
    localPeaks = pPeakIndex(1: numel(MeanNoise_smoothed) + 1  );
    meanNoise = [MeanNoise_smoothed; MeanNoise_smoothed(end)];
    meanSignal = [MeanSignal_smoothed; MeanSignal_smoothed(end)];

    plot(localPeaks,meanNoise,'LineWidth',1,'Linestyle','--','color','r');
    plot(localPeaks,meanSignal,'LineWidth',1,'Linestyle','--','color','g');
    
end

xlim( [ xlimFilteredMin xlimFilteredMax ] )
title('Powered Signal')