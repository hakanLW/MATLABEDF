
% Reading .bin File
%
% [ ECG ] = ECGBinary2Structure( MatlabAPIConfig, RecordInfo )
%
% <<< Function Inputs >>>
%   struct MatlabAPIConfig
%   struct RecordInfo
%
% <<< Function Outputs >>>
%   struct ECG
%

function [ ECG ] = ECGBinary2Structure( MatlabAPIConfig, RecordInfo )

% Record Info
% - Number of channels
channelCount = length( RecordInfo.ChannelList );
% - Record Length
file2ReadInfo = dir( char( MatlabAPIConfig.FileAdress ) );
channelDataLength = double( file2ReadInfo.bytes );
channelDataLength = fix( channelDataLength / ( channelCount * 4 ) );

% check if file is broken
if floor( channelDataLength ) == channelDataLength
    % open file
    file2Read = fopen( MatlabAPIConfig.FileAdress );
    % get data
    rawSignal = fread( file2Read, [ channelCount, channelDataLength ], 'single' );
    rawSignal = transpose( single( rawSignal ) );
    % close file
    fclose( file2Read );
else
    error('Given binary file is broken.')
end

% check if file is empty
if ~isempty( rawSignal )
    % Signal duration control
    if length( rawSignal(:, 1) ) <= single( 5 * RecordInfo.RecordSamplingFrequency )
        disp( [ 'Data Length: ' num2str( length( rawSignal(:, 1) ) ) ] );
        error('Record is not long enough for the analysis.')
    end
    % Conversion
    for chanenlIndex = 1 : channelCount
        % get channel signal
        ECG.( RecordInfo.ChannelList{ chanenlIndex } ) = single( rawSignal(:, 1) );
        % clear channel signal
        rawSignal(:, 1) = [ ];
    end
else
    error('Given binary file is empty.')
end

end

