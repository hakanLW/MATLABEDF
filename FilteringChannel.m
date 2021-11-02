
function [ signal ] = FilteringChannel( FileAdress, ~, ~, ~, ~ )
MatlabAPIConfig.FileAdress = FileAdress;
HolterRecordInfoRequest.RecordSamplingFrequency=250;
ECGBinary2Structure( MatlabAPIConfigRequest.FileAdress, HolterRecordInfoRequest );

samplingFreq=250;
hpFreq =0.5;
lpFreq =40;
filterType= 'filtfilt';

% BandPassFilter
signal = ClassFilter.BandPassFilter(signal, [ hpFreq lpFreq ], 2, samplingFreq, filterType );

plot(signal)
end