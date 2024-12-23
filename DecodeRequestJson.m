
% Decode Request Json
%
%  [ RecordInfo, AnalysisParameters, AlarmButton, MatlabAPIConfig ] = DecodeRequestJson ( RequestJson, FileAdress )
%
% <<< Function Inputs >>>
%   string RequestJson
%   string FileAdress
%
% <<< Function Outputs >>>
%   struct RecordInfo
%   struct AnalysisParameters
%   struct AlarmButton
%   struct MatlabAPIConfig


function [ RecordInfo, AnalysisParameters, AlarmButton, MatlabAPIConfig ] = DecodeRequestJson ( RequestJson, FileAdress )

if ( RequestJson == "" )
    
    % Empty json
    error( 'Invalid json is given.' )
    
else
    
    % Check File Adress
    if CheckFileAdress( FileAdress )
        
        % Write the Request Json
        WriteJSON( RequestJson );
        
        % Convert to struct
        RequestPackets = jsondecode( char( RequestJson ) );
        clear RequestJson;
        
        % - Matlab API Configuration
        [ MatlabAPIConfig ] = GetMatlabAPIConfig( RequestPackets, FileAdress, datetime('now') );
        % - Holter Info
        [ RecordInfo, MatlabAPIConfig ] = GetRecordInfo( RequestPackets, MatlabAPIConfig );
        % - Analysis Parameters
        [ AnalysisParameters ] = GetAnalysisParameters( RequestPackets, RecordInfo );
        % Analysis Channel
        MatlabAPIConfig.AnalysisChannel = ...
        GetAnalysisChannel( RecordInfo, MatlabAPIConfig,AnalysisParameters );
        % - Alarm Button
        [ AlarmButton ] = GetAlarmButton( RequestPackets, RecordInfo );
        % - Clear
        clear RequestPackets;
        
    end
    
end

end


%% SubFunction : Check File Adress

function isFileExist = CheckFileAdress( FileAdress )

% Initialization
FileAdress = char( FileAdress );
isFileExist = false;
% Check Address
% - check the length of the address
if length(FileAdress) > 15
    % - check the address format
    if (strcmp(FileAdress((end-18):end), '_FilteredSignal.bin') || ...
            strcmp(FileAdress((end-18):end), '_FilteredSignal.EDF'))
        % - check if file exists
        if exist(FileAdress, 'file')
            % - raise flag
            isFileExist = true;
        end
    end
end


% Error
if ~isFileExist
    error('File adress is not valid.')
end

end


%% SubFunction : WriteJson

function WriteJSON( requestJson )

fid = fopen('_JsonRequest.txt','wt');
fprintf(fid, string( requestJson ) );
fclose(fid);

end


%% SubFunction : Get Record Info

function [ recordInfo, matlabAPIConfig ] = GetRecordInfo( RequestPackets, matlabAPIConfig )

% Record Start Time
recordInfo.RecordStartTime = ...
    ClassTypeConversion.ConvertChar2Datetime( RequestPackets.HolterRecordInfoRequest.RecordStartTime);
% Record End Time
recordInfo.RecordEndTime = ...
    ClassTypeConversion.ConvertChar2Datetime( RequestPackets.HolterRecordInfoRequest.RecordEndTime);
% Sampling Frequency of the Record
recordInfo.RecordSamplingFrequency = ...
    single( RequestPackets.HolterRecordInfoRequest.RecordSamplingFrequency );
% Channel List & Its Order
recordInfo.ChannelList = ...
    RequestPackets.HolterRecordInfoRequest.ChannelList;
% Electrode State List
recordInfo = ...
    GetECGElectrodeState( RequestPackets, recordInfo );
% Active Signals
recordInfo.ActiveSignals = recordInfo.ActiveChannels;
if any( strcmp( recordInfo.ActiveChannels, "Lead1" ) ) && any( strcmp( recordInfo.ActiveChannels, "Lead2" ) )
    recordInfo.ActiveSignals{ length( recordInfo.ActiveSignals ) + 1 } = 'Lead3';
    recordInfo.ActiveSignals{ length( recordInfo.ActiveSignals ) + 1 } = 'aVR';
    recordInfo.ActiveSignals{ length( recordInfo.ActiveSignals ) + 1 } = 'aVL';
    recordInfo.ActiveSignals{ length( recordInfo.ActiveSignals ) + 1 } = 'aVF';
    recordInfo.ActiveSignals{ length( recordInfo.ActiveSignals ) + 1 } = 'V1';
    recordInfo.ActiveSignals{ length( recordInfo.ActiveSignals ) + 1 } = 'V2';
    recordInfo.ActiveSignals{ length( recordInfo.ActiveSignals ) + 1 } = 'V3';
    recordInfo.ActiveSignals{ length( recordInfo.ActiveSignals ) + 1 } = 'V4';
    recordInfo.ActiveSignals{ length( recordInfo.ActiveSignals ) + 1 } = 'V5';
    recordInfo.ActiveSignals{ length( recordInfo.ActiveSignals ) + 1 } = 'V6';
   
    
end


end


%% SubFunction : Get Analysis Parameters

function [ analysisParameters ] = GetAnalysisParameters( RequestPackets, recordInfo )

% Analysis Parameteres
analysisParameters = RequestPackets.AnalysisParametersRequest;

% Minimum Amplitude
analysisParameters.MinimumSignalAmplitude = ...
    single( 0.025 );

% Asystole
analysisParameters.Asystole.ClinicThreshold = ...
    single( analysisParameters.Asystole.ClinicThreshold );

% Bradycardia
analysisParameters.Bradycardia.ActivityThreshold = ...
    single( analysisParameters.Bradycardia.ActivityThreshold );
analysisParameters.Bradycardia.AlarmThreshold = ...
    single( analysisParameters.Bradycardia.AlarmThreshold );
analysisParameters.Bradycardia.ClinicThreshold = ...
    single( analysisParameters.Bradycardia.ClinicThreshold );

% Tachycardia
analysisParameters.Tachycardia.ActivityThreshold = ...
    single( analysisParameters.Tachycardia.ActivityThreshold );
analysisParameters.Tachycardia.AlarmThreshold = ...
    single( analysisParameters.Tachycardia.AlarmThreshold );
analysisParameters.Tachycardia.ClinicThreshold = ...
    single( analysisParameters.Tachycardia.ClinicThreshold );

% Pause
analysisParameters.Pause.ClinicThreshold = ...
    single( analysisParameters.Pause.ClinicThreshold );

% Active period
analysisParameters.ActivePeriod.StartTime = ...
    single( analysisParameters.ActivePeriod.StartTime );
analysisParameters.ActivePeriod.EndTime = ...
    single( analysisParameters.ActivePeriod.EndTime );

% - intervalWithoutSignal
if ~isempty( recordInfo.AnalysisStartPoint )
    
    % DEFINING THE GIVEN INTERVALs
    % If there is a list of interval without signal
    for intervalIndex = 1 : length( analysisParameters.IntervalWithoutSignal)
        if intervalIndex == length( analysisParameters.IntervalWithoutSignal )
            % [2] pop the empty interval
            analysisParameters.IntervalWithoutSignal(intervalIndex) = [ ];
        else
            % [1] give a type for each intervals
            analysisParameters.IntervalWithoutSignal(intervalIndex).Type = deal( 'Given' );
        end
    end
    
    % DEFINING THE INTERVALs WITH NO ACTIVE CHANNEL
    % AS NOISE
    for cableConfigIndex = 1 : recordInfo.CableConfigurationCount
        % If there is a interval without any active channel,
        % define them as a given noise
        if ( isempty( recordInfo.CableConfigurations( cableConfigIndex ).ActiveChannelList ) )
            % get the length of the intervals without signal
            numberIntervalWithoutSignal = int32( numel( analysisParameters.IntervalWithoutSignal ) );
            % add starting point
            analysisParameters.IntervalWithoutSignal( numberIntervalWithoutSignal + 1 ).StartTime = ...
                char( ...
                ClassDatetimeCalculation.Summation( ...
                recordInfo.RecordStartTime, ...
                round(  ( recordInfo.CableConfigurations( cableConfigIndex ).StartPoint ) / recordInfo.RecordSamplingFrequency ) ) ...
                );
            % add end point
            if cableConfigIndex == recordInfo.CableConfigurationCount
                analysisParameters.IntervalWithoutSignal( numberIntervalWithoutSignal + 1 ).EndTime = ...
                    char( recordInfo.RecordEndTime );
            else
                analysisParameters.IntervalWithoutSignal( numberIntervalWithoutSignal + 1 ).EndTime = ...
                    char( ...
                    ClassDatetimeCalculation.Summation( ...
                    recordInfo.RecordStartTime, ...
                    round(  ( recordInfo.CableConfigurations( cableConfigIndex + 1 ).StartPoint ) / recordInfo.RecordSamplingFrequency ) ) ...
                    );
            end
            % add type
            analysisParameters.IntervalWithoutSignal( numberIntervalWithoutSignal + 1 ).Type = deal( 'Given' );
        end
    end
    
else
    
    % If starting point is empty, consider the the all signal as a noisy area
    analysisParameters.IntervalWithoutSignal.StartTime = char( recordInfo.RecordStartTime );
    analysisParameters.IntervalWithoutSignal.EndTime = char( recordInfo.RecordEndTime );
    analysisParameters.IntervalWithoutSignal.Type = deal( 'Given' );
    
end
% % - Channel
% analysisParameters.Channel = ...
%     string( analysisParameters.Channel );
end


%% SubFunction : MatlabAPI Configuration

function [ matlabAPIConfig ] = GetMatlabAPIConfig( RequestPackets, FileAdress, AnalysisStartDateTime )

% - Matlab API Config
matlabAPIConfig = RequestPackets.MatlabAPIConfigRequest;
matlabAPIConfig.FileAdress = FileAdress;
matlabAPIConfig.AnalysisStartDateTime = AnalysisStartDateTime;
matlabAPIConfig.ReAnalysis = RequestPackets.ReAnalysis;
matlabAPIConfig.PaceMaker = RequestPackets.PaceMaker;

% - Enviroment
if isfield( RequestPackets, 'EnvironmentConfig' )
    matlabAPIConfig.Environment.isTest = RequestPackets.EnvironmentConfig.Environment == 'T';
    matlabAPIConfig.Environment.channelFileAdress = RequestPackets.EnvironmentConfig.ChannelDataPath;
else
    matlabAPIConfig.Environment.isTest = false;
end
        
end


%% SubFunction : MatlabAPI Configuration

function [ AlarmButton ] = GetAlarmButton( RequestPackets, RecordInfo )

if isfield( RequestPackets, 'AlarmButtonRequest' )
    
    if isempty( RequestPackets.AlarmButtonRequest )
        % Empty packet
        AlarmButton = [ ];
        
    else
        
        % Get Alarm Infos
        AlarmButtonRequest = RequestPackets.AlarmButtonRequest.AlarmButtonInfoList;
        
        % Total Run
        TotalAlarmButtonRun = ( length( AlarmButtonRequest ) - 1 );
        
        % Initialization
        AlarmButton.StartTime = ...
            strings( TotalAlarmButtonRun, 1 );
        AlarmButton.StartPoint = ...
            zeros( TotalAlarmButtonRun, 1 );
        AlarmButton.EndTime = ...
            strings( TotalAlarmButtonRun, 1 );
        AlarmButton.EndPoint = ...
            zeros( TotalAlarmButtonRun, 1 );
        AlarmButton.AverageHeartRate = ...
            zeros( TotalAlarmButtonRun, 1 );
        AlarmButton.Duration = ...
            zeros( TotalAlarmButtonRun, 1 );
        
        % Get startTime & endTime
        for runIndex = 1 : TotalAlarmButtonRun
            % - start time
            AlarmButton.StartTime( runIndex ) = ...
                AlarmButtonRequest( runIndex ).StartTime;
            % - start point
            AlarmButton.StartPoint( runIndex ) = ...
                ClassTypeConversion.ConvertDuration2Miliseconds( ...
                ClassDatetimeCalculation.Substraction( ...
                AlarmButton.StartTime( runIndex ), RecordInfo.RecordStartTime ...
                ) ...
                ) / 1000 * 250;
            % - end time
            AlarmButton.EndTime( runIndex ) = ...
                AlarmButtonRequest( runIndex ).EndTime;
            % - end point
            AlarmButton.EndPoint( runIndex ) = ...
                ClassTypeConversion.ConvertDuration2Miliseconds( ...
                ClassDatetimeCalculation.Substraction( ...
                AlarmButton.EndTime( runIndex ), RecordInfo.RecordStartTime ...
                ) ...
                ) / 1000 * 250;
        end
        
    end
    
else
    
    % Empty packet
    AlarmButton = [ ];
    
end

end


%% SubFunction : ECG Electrode State

function [ recordInfo ] = GetECGElectrodeState( RequestPackets, recordInfo )

% Get the given request packet
ecgElectrodeStateList = RequestPackets.HolterRecordInfoRequest.EcgElectrodeStateList;

% Count the number of cable configuration change
if isempty( ecgElectrodeStateList )
    % ERROR: Empty electrode state
    ecgElectrodeStateList(1).MeasurementDateTime = recordInfo.RecordStartTime;
    ecgElectrodeStateList(1).ProbeStatus.V1 = false;
    ecgElectrodeStateList(1).ProbeStatus.V2 = false;
    ecgElectrodeStateList(1).ProbeStatus.V3 = false;
    ecgElectrodeStateList(1).ProbeStatus.V4 = false;
    ecgElectrodeStateList(1).ProbeStatus.V5 = false;
    ecgElectrodeStateList(1).ProbeStatus.V6 = false;
    ecgElectrodeStateList(1).ProbeStatus.RA = true;
    ecgElectrodeStateList(1).ProbeStatus.LA = false;
    ecgElectrodeStateList(1).ProbeStatus.LL = true;
    ecgElectrodeStateList(1).ProbeStatus.None = false;
    RequestPackets.HolterRecordInfoRequest.EcgElectrodeStateList = ecgElectrodeStateList;
else
    % check the last element of the electrode state list
    if ( ecgElectrodeStateList( length( ecgElectrodeStateList ) ).ProbeStatus.None )
        % remove the empty state
        for index = length( ecgElectrodeStateList ) : -1 : 1
            if ecgElectrodeStateList(index).ProbeStatus.None
                ecgElectrodeStateList( index ) = [ ];
            end
        end        
        % last item of the class list is ignored if it is empty;
        if ~isempty( ecgElectrodeStateList )
            % 
        else
            % ERROR: Electrode state format is wrong
            % error( 'ECG electrode state is given empty: ONLY AN EMPTY STATE IS GIVEN.' )
            ecgElectrodeStateList(1).MeasurementDateTime = recordInfo.RecordStartTime;
            ecgElectrodeStateList(1).ProbeStatus.V1 = false;
            ecgElectrodeStateList(1).ProbeStatus.V2 = false;
            ecgElectrodeStateList(1).ProbeStatus.V3 = false;
            ecgElectrodeStateList(1).ProbeStatus.V4 = false;
            ecgElectrodeStateList(1).ProbeStatus.V5 = false;
            ecgElectrodeStateList(1).ProbeStatus.V6 = false;
            ecgElectrodeStateList(1).ProbeStatus.RA = true;
            ecgElectrodeStateList(1).ProbeStatus.LA = false;
            ecgElectrodeStateList(1).ProbeStatus.LL = true;
            ecgElectrodeStateList(1).ProbeStatus.None = false;
            RequestPackets.HolterRecordInfoRequest.EcgElectrodeStateList = ecgElectrodeStateList;
        end
    else
        % ERROR: Empty electrode state
        ecgElectrodeStateList(1).MeasurementDateTime = recordInfo.RecordStartTime;
        ecgElectrodeStateList(1).ProbeStatus.V1 = false;
        ecgElectrodeStateList(1).ProbeStatus.V2 = false;
        ecgElectrodeStateList(1).ProbeStatus.V3 = false;
        ecgElectrodeStateList(1).ProbeStatus.V4 = false;
        ecgElectrodeStateList(1).ProbeStatus.V5 = false;
        ecgElectrodeStateList(1).ProbeStatus.V6 = false;
        ecgElectrodeStateList(1).ProbeStatus.RA = true;
        ecgElectrodeStateList(1).ProbeStatus.LA = false;
        ecgElectrodeStateList(1).ProbeStatus.LL = true;
        ecgElectrodeStateList(1).ProbeStatus.None = false;
        RequestPackets.HolterRecordInfoRequest.EcgElectrodeStateList = ecgElectrodeStateList;
    end
end

% clear same states 
for stateIndex = length( ecgElectrodeStateList ) : -1 : 2
    if isequaln( ecgElectrodeStateList( stateIndex ).ProbeStatus, ecgElectrodeStateList( stateIndex - 1 ).ProbeStatus )
        ecgElectrodeStateList( stateIndex ) = [ ];
    end
end

% cable configuration count
recordInfo.CableConfigurationCount = length( ecgElectrodeStateList );

% get each fongiuration
for stateIndex = 1 : length( ecgElectrodeStateList )
    
    % starting point of the cable configuration change
    recordInfo.CableConfigurations( stateIndex ).StartPoint = ...
        max( 1, (...
        double( ...
        seconds( ...
        ClassDatetimeCalculation.Substraction( ...
        ClassTypeConversion.ConvertChar2Datetime( ...
        RequestPackets.HolterRecordInfoRequest.EcgElectrodeStateList( stateIndex ).MeasurementDateTime ), ...
        recordInfo.RecordStartTime ...
        )...
        )...
        ) * recordInfo.RecordSamplingFrequency + 1 )...
        );
    
    % get the active channel list
    recordInfo.CableConfigurations( stateIndex ).ActiveChannelList = ...
        GetActiveChannelList( ecgElectrodeStateList( stateIndex ).ProbeStatus, RequestPackets.HolterRecordInfoRequest.ChannelList  );
    
    % wait until the Lead1 or the Lead2 is active
    if stateIndex == 1
        % check cables
        if  ...
                any( strcmp( recordInfo.CableConfigurations( stateIndex ).ActiveChannelList, 'Lead1' ) ) || ...
                any( strcmp( recordInfo.CableConfigurations( stateIndex ).ActiveChannelList, 'Lead2' ) ) || ...
                any( strcmp( recordInfo.CableConfigurations( stateIndex ).ActiveChannelList, 'V5' ) )
            % flag for detection of the analysis start point
            startingWithNoise = false;
        else
            % flag for detection of the analysis start point
            startingWithNoise = true;
        end
    end
    
    % if it is started with noise
    if startingWithNoise
        
        % wait until a major channel is activated
        if ...
                any( strcmp( recordInfo.CableConfigurations( stateIndex ).ActiveChannelList, 'Lead1' ) ) || ...
                any( strcmp( recordInfo.CableConfigurations( stateIndex ).ActiveChannelList, 'Lead2' ) ) || ...
                any( strcmp( recordInfo.CableConfigurations( stateIndex ).ActiveChannelList, 'V5' ) )
            
            recordInfo.AnalysisStartPoint = recordInfo.CableConfigurations( stateIndex ).StartPoint;
            % flag for detection of the analysis start point
            startingWithNoise = false;
            
        else
            
            if stateIndex == recordInfo.CableConfigurationCount
                % if through the record, none of the major channels are
                % not activated
                recordInfo.AnalysisStartPoint = [ ];
            end
            
        end
        
    elseif stateIndex == 1
        % flag for detection of the analysis start point
        recordInfo.AnalysisStartPoint = 1;
    end
    
end

% Active Channels
activeChannelCount = zeros( recordInfo.CableConfigurationCount, 1, 'single' );
for channelChangeIndex = 1 : recordInfo.CableConfigurationCount
    activeChannelCount( channelChangeIndex ) = length( recordInfo.CableConfigurations( channelChangeIndex ).ActiveChannelList );
end
if sum( activeChannelCount == max( activeChannelCount ) ) > 1
    highestChannelCountIndexes = find( activeChannelCount == max( activeChannelCount ) );
    recordInfo.ActiveChannels = recordInfo.CableConfigurations( highestChannelCountIndexes( 1 ) ).ActiveChannelList;
    for index = 2 : length( highestChannelCountIndexes )
        channels2Add = recordInfo.CableConfigurations( highestChannelCountIndexes( index ) ).ActiveChannelList;
        recordInfo.ActiveChannels = unique([ recordInfo.ActiveChannels; channels2Add ]);
    end
    recordInfo.ActiveChannelCount = length( recordInfo.ActiveChannels );
else
    [ recordInfo.ActiveChannelCount, highestChannelCountIndex ] = max( activeChannelCount );
    recordInfo.ActiveChannels = recordInfo.CableConfigurations( highestChannelCountIndex ).ActiveChannelList;
end

end


%% SubFunction : Get Active Channel List

function channelList = GetActiveChannelList( electrodeStateList, channelList )

% Check if channel is active
% - V1;
if ~electrodeStateList.LL || ~electrodeStateList.LA || ~electrodeStateList.V1
    channelList(strcmp(channelList, 'V1' ), :) = [ ];
end
% - V2;
if ~electrodeStateList.LL || ~electrodeStateList.LA || ~electrodeStateList.V2
    channelList(strcmp(channelList, 'V2' ), :) = [ ];
end
% - V3;
if ~electrodeStateList.LL || ~electrodeStateList.LA || ~electrodeStateList.V3
    channelList(strcmp(channelList, 'V3' ), :) = [ ];
end
% - V4;
if ~electrodeStateList.LL || ~electrodeStateList.LA || ~electrodeStateList.V4
    channelList(strcmp(channelList, 'V4' ), :) = [ ];
end
% - V5;
if ~electrodeStateList.LL || ~electrodeStateList.LA || ~electrodeStateList.V5
    channelList(strcmp(channelList, 'V5' ), :) = [ ];
end
% - V6;
if ~electrodeStateList.LL || ~electrodeStateList.LA || ~electrodeStateList.V6
    channelList(strcmp(channelList, 'V6' ), :) = [ ];
end
% - Lead1;
if ~electrodeStateList.RA || ~electrodeStateList.LA
    channelList(strcmp(channelList, 'Lead1' ), :) = [ ];
end
% - Lead2;
if ~electrodeStateList.RA || ~electrodeStateList.LL
    channelList(strcmp(channelList, 'Lead2' ), :) = [ ];
end

% if (~electrodeStateList.RA || ~electrodeStateList.LA  || ~electrodeStateList.LL)
% % - Lead3
% channelList(strcmp(channelList, 'Lead3' ), :) = [ ];
% % - aVL
% channelList(strcmp(channelList, 'aVL' ), :) = [ ];
% % - aVF
% channelList(strcmp(channelList, 'aVF' ), :) = [ ];
% % - aVR
% channelList(strcmp(channelList, 'aVR' ), :) = [ ];
% end

end


%% SubFunction : Analysis Channel

function analysisChannel = GetAnalysisChannel( recordInfo, matlabAPIConfig,analysisParameters )

if isempty( recordInfo.ActiveChannels )
    error( 'There is no channel to be used in the analysis.' )
end
if ~isempty(analysisParameters.Channel)
     analysisChannel=analysisParameters.Channel;
elseif any( strcmp( recordInfo.ActiveChannels, 'Lead2' ) )
    analysisChannel = 'Lead2';
elseif any( strcmp( recordInfo.ActiveChannels, 'V5' ) )
    analysisChannel = 'V5';
elseif any( strcmp( recordInfo.ActiveChannels, 'Lead1' ) )
    analysisChannel = 'Lead1';
elseif any( strcmp( recordInfo.ActiveChannels, 'V6' ) )
    analysisChannel = 'V6';
else
    error( 'There is no channel to be used in analysis' )
end
if matlabAPIConfig.IsLogWriteToConsole
    disp( [ 'Analysis Channel: ' analysisChannel ] )
end

end