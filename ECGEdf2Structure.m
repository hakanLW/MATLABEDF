
% Reading .edf File
%
% [ ECG ] = ECGEdfStructure( MatlabAPIConfig, RecordInfo )
%
% <<< Function Inputs >>>
%   struct MatlabAPIConfig
%   struct RecordInfo
%
% <<< Function Outputs >>>
%   struct ECG
%

function [ ECG ] = ECGEdf2Structure( MatlabAPIConfig, RecordInfo )

[~,signal] =edfread(MatlabAPIConfig.FileAdress);
% Record Info
% - Number of channels
channelCount = length( RecordInfo.ChannelList );
rawSignal = transpose( single( signal ) );

% check if file is empty
if ~isempty( rawSignal )
    % Signal duration control
    if length( rawSignal(:, 1) ) <= single( 5 * RecordInfo.RecordSamplingFrequency )
        disp( [ 'Data Length: ' num2str( length( rawSignal(:, 1) ) ) ] );
        error('Record is not long enough for the analysis.')
    end
    if (size(rawSignal, 2)==1)
        ECG.V5 = zeros(size(rawSignal, 1), 1, 'single');
        ECG.Lead1 = rawSignal;
        ECG.Lead2 = zeros(size(rawSignal, 1), 1, 'single');
    
    else
    % Conversion
        for chanenlIndex = 1 : channelCount
            % get channel signal
            ECG.( RecordInfo.ChannelList{ chanenlIndex } ) = single( rawSignal(:, 1) );
            % clear channel signal
            rawSignal(:, 1) = [ ];
        end
    end
else
    error('Given binary file is empty.')
end



end

