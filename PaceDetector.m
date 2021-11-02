function [AdjustedECG,pace] = PaceDetector(ecg,~)
% 
% t = 1:length(ecg);
% figure
% plot(t,ecg)
% notch filter baseline kaldýrýlmasý
b = [1 -1];
a = [1 -0.9];
adjustedecg= filter(b,a,ecg);
% 
filtecg= ClassFilter.HighPassFilter(adjustedecg, 50, 1, 250, 'filtfilt');

% hold on;
% 
% plot(t,filtecg)
% title('Signal with a Trend')
% xlabel('Samples');
% ylabel('Voltage(mV)')
% legend('Noisy ecg Signal')
% grid on
% zoom on
% hold on;


[~,locs] = findpeaks(filtecg,'MinPeakHeight',1) ;
% 
% 
% plot(t,filtecg)
% title('Signal with a Trend')
% xlabel('Samples');
% ylabel('Voltage(mV)')
% legend('Noisy ecg Signal')
% grid on
% zoom on
% hold on;
% 
% plot(locs,(filtecg(locs)),'rv','MarkerFaceColor','r')
% hold on;
for i=1:length(ecg)
      ecg(locs) =ecg(locs-1);
end

ecg(locs-1) =ecg(locs-3);
ecg(locs+1)=ecg(locs+3);
ecg(locs) = (ecg(locs-1) + ecg(locs+1))/2;

% figure
% 
% plot(t,ecg)
% title('Signal with a Trend')
% xlabel('Samples');
% ylabel('Voltage(mV)')
% legend('Last ecg')
% grid on
% hold on
% zoom on

AdjustedECG=ecg;
pace=locs;