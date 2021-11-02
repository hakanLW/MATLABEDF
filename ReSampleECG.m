function [ECGSignals , HolterRecordInfoRequest]= ReSampleECG( ECGSignals, HolterRecordInfoRequest )

sampFreq= double(HolterRecordInfoRequest.RecordSamplingFrequency);
% Lead1 - Data

if sampFreq ~= 250
    Lead1 = (ECGSignals.Lead1 );
    Lead2 = (ECGSignals.Lead2);
    V5 = ( ECGSignals.V5 );
    
    Lead1 =ResampleSignal( Lead1, sampFreq, 250 );
    ECGSignals.Lead1 = Lead1;

    Lead2 = ResampleSignal( Lead2, sampFreq, 250 );
    ECGSignals.Lead2 = Lead2;

    
    V5 = ResampleSignal( V5, sampFreq, 250 );
    ECGSignals.V5 = V5;
    
    HolterRecordInfoRequest.RecordSamplingFrequency = single(250);

end
        
end

%% Resample Function

function outputSignal = ResampleSignal(inputSignal, originalFreq, desiredFreq)

% resampling parameters
[num, den] = rat(desiredFreq/originalFreq);

% resampled ECG
inputSignal = double(inputSignal);
outputSignal = resample(inputSignal,num,den);
outputSignal = single (outputSignal);

end