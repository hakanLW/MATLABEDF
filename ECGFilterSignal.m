% Filtering ECG Signals
%
% [ ECGSignals ] = ECGFilterSignal( ECGSignals, RecordInfo, MatlabAPIConfigs )
%
% <<< Function Inputs >>>
%   struct ECGSignals
%   struct RecordInfo
%   struct MatlabAPIConfigs
%
% <<< Function outputs >>>
%   struct ECGSignals


function [ ECGSignals ] = ECGFilterSignal( ECGSignals, RecordInfo, MatlabAPIConfigs )


% SIGNAL FILTERING
if isempty( RecordInfo.AnalysisStartPoint )
    
    % If there is no channel to be used in the anaylsis,
    % give an error.
    error( 'There is no channel to be used in the analysis.' )
    
else
    
    
    %% Filter - Holter Report
    if MatlabAPIConfigs.IsLogWriteToConsole
        disp('Signal filtering: ')
        tic
    end
    % for the report page
    [ ECGSignals ] = ReportFilter( ECGSignals, RecordInfo, MatlabAPIConfigs );
    % For the analysis
    [ ECGSignals ] = AnalysisFilter( ECGSignals, RecordInfo );
    if MatlabAPIConfigs.IsLogWriteToConsole
        disp('# Completed...')
        toc
        disp(' ');
    end
    
    
end


end


%% SubFunction: Report Filter

function ecgSignals = ReportFilter( ecgSignals, recordInfo, matlabConfig )

% Freq Band
lowFreq = 0.5;
highFreq = 40;

for channel = 1 : length( recordInfo.ChannelList )
    
    
    if ... # if the channel is an active channel, then filter it.
            any( strcmp( recordInfo.ChannelList{ channel }, recordInfo.ActiveChannels ) )
        
        ecgSignals.( recordInfo.ChannelList{ channel } ) = ...
            FilterChannel( ecgSignals.( recordInfo.ChannelList{ channel } ), recordInfo.RecordSamplingFrequency, lowFreq, highFreq, 'filtfilt' );
                
    else
        ecgSignals.( recordInfo.ChannelList{ channel } ) = ...
            zeros( length( ecgSignals.( recordInfo.ChannelList{ channel } ) ), 1, 'single' );
        
    end
    
end

% SAVE THE FILTERED SIGNAL
ClassPackageOutput.FilteredECGPacket ( ecgSignals, matlabConfig );
if matlabConfig.IsLogWriteToConsole
    disp('# Filtered signals are written into the bin file.')
end

end


%% SubFunction: Analysis Filter

function [ ecgSignals ] = AnalysisFilter( ecgSignals, recordInfo )

for channel = 1 : length( recordInfo.ChannelList )
    
    if ... # if the channel is an active channel, then filter it.
            any( strcmp( recordInfo.ChannelList{ channel }, recordInfo.ActiveChannels ) )
                
        % Erase
        %         ecgSignals.( recordInfo.ChannelList{ channel } )...
        %             ( double( 13 * recordInfo.RecordSamplingFrequency ) : double( 18 * recordInfo.RecordSamplingFrequency ) ) = 0;
        %
        %                 ecgSignals.( recordInfo.ChannelList{ channel } )( double( 10 * 60 * recordInfo.RecordSamplingFrequency ) : double( length( ecgSignals.( recordInfo.ChannelList{ channel } ) ) ) ) = [ ];
        %         ecgSignals.( recordInfo.ChannelList{ channel } )( double( 1 ) : double( 25 * 60 * recordInfo.RecordSamplingFrequency ) ) = [ ];
        
        % Filter
        %         ecgSignals.( recordInfo.ChannelList{ channel } ) = ...
        %             FilterChannel( ecgSignals.( recordInfo.ChannelList{ channel } ), recordInfo.RecordSamplingFrequency, 0.5, 35, 'filtfilt' );
        
    else
        
        % Signal list update
        ecgSignals = rmfield( ecgSignals, recordInfo.ChannelList{ channel } );
        
    end
    
end

end


%% SubFunction: Filter Channel

function [ signal ] = FilterChannel( signal, samplingFreq, hpFreq, lpFreq, filterType )

% BandPassFilter
signal = ClassFilter.BandPassFilter(signal, [ hpFreq lpFreq ], 2, samplingFreq, filterType );

end