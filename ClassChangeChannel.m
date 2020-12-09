classdef ClassChangeChannel
    
    % "ClassChangeChannel.m" class consists functions to continue the
    % analysis in another channel.
    %
    % > RemoveChannel
    % > ControlChannel4Activity
    % > FindChannel2Analyze
    % > QRSCharacterization
    % > Merge
    
    %% PROPERTIES
    
    properties
        
        %
        
    end
    
    %% STATIC METHODS
    
    methods (Static)
        
        
        %% Remove Channel
        
        function ecgSignals = RemoveChannel( ecgSignals, recordInfo, matlabAPIConfig )
            
            for channelIndex = 1 : recordInfo.ActiveChannelCount
                
                if ... # if the channel is an active channel, then filter it.
                        ~strcmp( recordInfo.ActiveChannels{ channelIndex }, matlabAPIConfig.AnalysisChannel )
                    ecgSignals = rmfield( ecgSignals, recordInfo.ActiveChannels{ channelIndex } );
                end
                
            end
            
        end
        
        
        %% Channel Control For Activity
        
        function  isActive = ControlChannel4Activity( signal, samplingFreq )
            
            % Channel control for activity.
            %
            % isActive = ControlChannel4Activity( signal, samplingFreq )
            %
            % <<< Function Inputs >>>
            %   single[n,1] signal
            %   single samplingFreq
            %
            % <<< Function Outputs >>>
            %   boolean isActive
            %
            
            % Minimum signal amplitude range
            minSignalAmplitude = single( 0.025 ); 
            
            % BandPassed Filter
            signal = ClassFilter.BandPassFilter( signal, [ 5 20 ], 1, samplingFreq, 'filtfilt' );
                        
            % Number of 1-minute intervals of signal
            numberOf1MinuteIntervals = fix( length( signal ) / samplingFreq );
            
            % Possible beat detection in signal
            isBeat = zeros( numberOf1MinuteIntervals, 1, 'single' );
                        
            for intervalIndex = 1 : numberOf1MinuteIntervals
                % The begining and the end of signal interval to check for signal
                minuteIntervalSignalStart = length( signal ) - samplingFreq * ( intervalIndex ) + 1;
                minuteIntervalSignalEnd = length( signal ) - samplingFreq * ( intervalIndex - 1 );
                % Signal interval
                minuteIntervalSignal = signal( double( minuteIntervalSignalStart ) : double( minuteIntervalSignalEnd ) );
                % Amplitude of the signal
                minuteIntervalSignalAmp = max( abs( minuteIntervalSignal ) );
                % IsBeat
                isBeat( intervalIndex ) = minuteIntervalSignalAmp >= minSignalAmplitude;
            end
            
            % Comparison
            if sum( isBeat ) > length( isBeat ) * 0.1  
                isActive = true;
            else
                isActive = false;
            end
            
        end
        
        
        %% Determination of the New Channel For Analysis
        
        function SelectedChannel = FindChannel2Analyze( ecgSignals, missingIIntervals, recordInfo, analysisChannel )
            
            % Selection of new channel for the analysis.
            %
            % SelectedChannel = FindChannel2Analyze( ecgSignals, missingIIntervals, recordInfo )
            %
            % <<< Function Inputs >>>
            %   stucture ecgSignals
            %   stucture missingIIntervals
            %   stucture recordInfo
            %
            % <<< Function Outputs >>>
            %   string SelectedChannel
            %
            
            % Get RecordInfo
            samplingFreq = recordInfo.RecordSamplingFrequency;
            channelList = recordInfo.ActiveChannels;
            
            % Initialization
            SelectedChannel = cell( length( missingIIntervals.StartPoint ), 1 );
        
            %             % order of precedence
            %             if length( channelList ) == 8
            %                 ecgChannelOrder = { 'V5'; 'V6'; 'Lead1' };  %{ 'V5'; 'Lead1'; 'V4'; 'V6'; 'V3'; 'V2'; 'V1' };
            %             elseif length( channelList ) == 12
            %                 ecgChannelOrder = { 'V5'; 'V6'; 'Lead1' };  %{ 'V5'; 'Lead1'; 'V4'; 'V6'; 'V3'; 'V2'; 'V1' };
            %             else
            %                 error('Channel list is not valid.')
            %             end
            
            % Active Channel Change Points
            ActiveChannelChangePoints = zeros( recordInfo.CableConfigurationCount, 1, 'single' );
            for i = 1 : recordInfo.CableConfigurationCount
                ActiveChannelChangePoints( i, 1 ) = recordInfo.CableConfigurations( i ).StartPoint;
                if i == recordInfo.CableConfigurationCount
                    ActiveChannelChangePoints( i, 2 ) = length( ecgSignals.( analysisChannel ) );
                else
                    ActiveChannelChangePoints( i, 2 ) = recordInfo.CableConfigurations( i + 1 ).StartPoint - 1;
                end
            end
    
            % checking channels according to order of precedence
            for intervalIndex = 1 : length( missingIIntervals.StartPoint )
                
                % missing interval start/end time
                intervalStart = double(round( missingIIntervals.StartPoint( intervalIndex ) ));
                intervalEnd = double(round( missingIIntervals.EndPoint( intervalIndex ) ) ); 
                intervalPoints = transpose( double( intervalStart) : double( intervalEnd ) );
                
                % Active Channel List
                [ ~, ActiveChannelChangeIndex ] = intersect( ActiveChannelChangePoints( :, 1 ), intervalPoints );
                if ActiveChannelChangeIndex
                    % unusual points and channel change has an intersected point
                    ActiveChannelChangeIndex = sort( unique( [ ActiveChannelChangeIndex ( ActiveChannelChangeIndex - 1 ) ] ) );
                    ActiveChannelChangeIndex( ActiveChannelChangeIndex < 1 ) = [ ];
                    % find the minimum
                    ActiveChannelCount = zeros( length( ActiveChannelChangeIndex ), 1, 'uint16' );
                    for ChannelChangeIndex = 1 : length( ActiveChannelChangeIndex )
                        ActiveChannelCount( ChannelChangeIndex ) = length( recordInfo.CableConfigurations( ActiveChannelChangeIndex( ChannelChangeIndex ) ).ActiveChannelList );
                    end
                    [ ~, ActiveChannelChangeIndex ] = min( ActiveChannelCount );
                    % Active Channels List
                    if isempty( ActiveChannelChangeIndex )
                        ActiveChannelList = [ ];
                    else
                        ActiveChannelList = recordInfo.CableConfigurations( ActiveChannelChangeIndex ).ActiveChannelList;
                    end
                else
                    % unusual points and channel change has no intersected points
                    ActiveChannelChangeIndex = find( ( ( ActiveChannelChangePoints( :, 1 )  <= intervalStart ) & (  ActiveChannelChangePoints( :, 2 ) >= intervalEnd ) ), true );
                    % Active Channels List
                    if isempty( ActiveChannelChangeIndex )
                        ActiveChannelList = [ ];
                    else
                        ActiveChannelList = recordInfo.CableConfigurations( ActiveChannelChangeIndex ).ActiveChannelList;
                    end
                end
                
                % ecg channel order
                ecgChannelOrder = cell( length( channelList ), 1 );
                orderCount = int8( 1 );
                %                 if any( strcmp( ActiveChannelList, 'Lead2' ) )
                %                     ecgChannelOrder{ orderCount } = 'Lead2';
                %                     orderCount = orderCount + 1;
                %                 end
                if any( strcmp( ActiveChannelList, 'V5' ) )
                    ecgChannelOrder{ orderCount } = 'V5';
                    orderCount = orderCount + 1;
                end
                if any( strcmp( ActiveChannelList, 'Lead1' ) )
                    ecgChannelOrder{ orderCount } = 'Lead1';
                    orderCount = orderCount + 1;
                end
                if any( strcmp( ActiveChannelList, 'V6' ) )
                    ecgChannelOrder{ orderCount } = 'V6';
                    orderCount = orderCount + 1;
                end
                if ~any( strcmp( ActiveChannelList, 'V5' ) ) && ~any( strcmp( ActiveChannelList, 'Lead1' ) ) && ~any( strcmp( ActiveChannelList, 'V6' ) )
                    ecgChannelOrder{ orderCount } = 'None';
                end
                
                
                ecgChannelOrder = ecgChannelOrder( ~cellfun( 'isempty', ecgChannelOrder ) ); % ecgChannelOrder{ 1 : ( orderCount - 1 ) };
                
                % for each missing interval, channels are being analyzed
                for channelIndex = 1 : length( ecgChannelOrder )
                    
                    % check channel
                    if strcmp( ecgChannelOrder{ channelIndex }, 'None' )
                        SelectedChannel{ intervalIndex } = analysisChannel;
                    else
                        if ClassChangeChannel.ControlChannel4Activity( ecgSignals.( ecgChannelOrder{ channelIndex } )( double( intervalStart ) : double( intervalEnd ) ) , samplingFreq )
                            SelectedChannel{ intervalIndex } = char( ecgChannelOrder( channelIndex ) );
                            break;
                        elseif channelIndex == length( ecgChannelOrder )
                            SelectedChannel{ intervalIndex } = analysisChannel;
                        end
                    end
                    
                end
                
            end
            
        end
        
        
        %% ECG Characteristic
        
        function [ asystoleRuns, vfRuns, noiseRuns, missingQRSComplex ] = QRSCharacterization...
                ( ecgSignals, asystoleRuns, vfRuns, noiseRuns, selectedChannels, missingIntervals, recordInfo, analysisParameters, matlabAPIConfig )
            
            % ECG characteristic analysis for each interval.
            %
            % [ asystoleRuns, vfRuns, noiseRuns, missingQRSComplex ] = QRSCharacterization...
            %     ( ecgSignals, asystoleRuns, vfRuns, noiseRuns, selectedChannels, missingIntervals, recordInfo, analysisParameters, matlabAPIConfig )
            %
            % <<< Function Inputs >>>
            %   stucture ecgSignals
            %   stucture asystoleRuns
            %   stucture vfRuns
            %   stucture noiseRuns
            %   string list selectedChannels
            %   stucture missingIntervals
            %   stucture recordInfo
            %   stucture analysisParameters
            %   stucture matlabAPIConfig
            %
            % <<< Function Outputs >>>
            %   stucture asystoleRuns
            %   stucture vfRuns
            %   stucture noiseRuns
            %   stucture missingQRSComplex
            %
            
            % save characteristic points
            missingQRSComplex.R = [ ];
            missingQRSComplex.StartPoint = [ ];
            missingQRSComplex.Q = [ ];
            missingQRSComplex.S = [ ];
            missingQRSComplex.EndPoint = [ ];
            missingQRSComplex.STSegmentChange = [ ];
            missingQRSComplex.JPointValue = [ ];
            missingQRSComplex.Type = [ ];
            missingQRSComplex.QRSAmplitude = [ ];
            missingQRSComplex.DetectionChannel = [ ];
            missingQRSComplex.T.StartPoint = [ ];
            missingQRSComplex.T.PeakPoint = [ ];
            missingQRSComplex.T.EndPoint = [ ];
            missingQRSComplex.T.Amplitude = [ ];
            missingQRSComplex.P.StartPoint = [ ];
            missingQRSComplex.P.PeakPoint = [ ];
            missingQRSComplex.P.EndPoint = [ ];
            missingQRSComplex.P.Amplitude = [ ];
            missingQRSComplex.SecondPWave = [ ];
            missingQRSComplex.NoisyBeat = [ ];
            missingQRSComplex.PeakAngle = [ ];
            
            % length of the signal in points
            originalLengthSignal = length( ecgSignals.( selectedChannels{ 1 } ) );
            
            % determination of the number of the missing intervals
            numberOfMissingInterval = length( missingIntervals.StartPoint );          
            
            % interval ecg characteristic analysis
            for intervalIndex = 1 : numberOfMissingInterval
                
                if matlabAPIConfig.IsLogWriteToConsole
                    disp( ' ' );
                    disp( [ 'Missing Interval Number: '  num2str( intervalIndex ) ] );
                    disp( [ 'Missing Interval Selected Channel: '  selectedChannels{ intervalIndex } ] );
                    disp( [ 'Missing Interval Start Time: '  num2str( round( missingIntervals.StartPoint( intervalIndex ) / recordInfo.RecordSamplingFrequency) ) ] );
                    disp( [ 'Missing Interval End Time: '  num2str( round( missingIntervals.EndPoint( intervalIndex ) / recordInfo.RecordSamplingFrequency) ) ] );
                end
                
                
                % - - - TIME SHIFT
                timeShift = single( 2 * recordInfo.RecordSamplingFrequency );
                
                
                
                % - - - MISSING INTERVAL START / END TIME
                missingIntervalStartTime = double( round( missingIntervals.StartPoint( intervalIndex ) - timeShift ) );
                missingIntervalEndTime = double( round( missingIntervals.EndPoint( intervalIndex ) ) );
                
                
                
                % - - - MISSING INTERVAL START / END TIME CHECK
                if missingIntervalStartTime < 1
                    missingIntervalStartTime = single( 1 );
                    timeShift = missingIntervals.StartPoint( intervalIndex ) - missingIntervalStartTime + 1;
                end
                
                
                
                % - - - MISSING INTERVAL SIGNALS
                for channelIndex = 1 : numel( recordInfo.ActiveChannels )
                    
                    % Get the specified channel
                    missingSignals.( recordInfo.ActiveChannels{ channelIndex } ) = ...
                        ecgSignals.( recordInfo.ActiveChannels{ channelIndex } )( double( missingIntervalStartTime ) : double( missingIntervalEndTime ) );
                    
                end
                
                % - - - MISSING INTERVAL RECORINFO
                tempRecordInfo = recordInfo;
                for cableConfigIndex = 1 : tempRecordInfo.CableConfigurationCount
                    tempRecordInfo.CableConfigurations( cableConfigIndex ).StartPoint = ...
                        tempRecordInfo.CableConfigurations( cableConfigIndex ).StartPoint - missingIntervalStartTime;
                end
                 
                % - - - MISSING INTERVAL SIGNALS
                analysisParameters.IntervalWithoutSignal = [ ];
                
                
                % - - - BEAT DETECTION
                if matlabAPIConfig.IsLogWriteToConsole
                    disp( 'Beat Detection: ' )
                end
                [ temp ] = Detection_Beat...
                    ( ....
                    missingSignals.( selectedChannels{ intervalIndex } ), ....
                    recordInfo, ...
                    analysisParameters, ...
                    matlabAPIConfig ...
                    );
                if matlabAPIConfig.IsLogWriteToConsole
                    disp('# Completed...')
                end
                
                
                
                % - - - Q AND S DETECTION
                if matlabAPIConfig.IsLogWriteToConsole
                    disp( 'Q and S Detection: ' )
                end
                [ temp ] = Detection_QS( missingSignals.( selectedChannels{ intervalIndex } ), temp, recordInfo );
                if matlabAPIConfig.IsLogWriteToConsole
                    disp('# Completed...')
                end
                
                
                
                % - - - P AND T DETECTION
                if matlabAPIConfig.IsLogWriteToConsole
                    disp( 'P and T Detection: ' )
                end
                [ temp ] = Detection_PT(  missingSignals.( selectedChannels{ intervalIndex } ), ( selectedChannels{ intervalIndex } ), temp, recordInfo, analysisParameters );
                if matlabAPIConfig.IsLogWriteToConsole
                    disp('# Completed...')
                end
                
                
                
                % - - - Ventricular Ectopics Detection
                if matlabAPIConfig.IsLogWriteToConsole
                    disp( 'Ventricular Fibrillation / Flutter Detection: ' )
                end
                tempRecordInfo.ActiveChannels( strcmp(  tempRecordInfo.ActiveChannels, matlabAPIConfig.AnalysisChannel ) ) = [ ];
                [ temp, missingSignalVFibRun, missingSignalNoiseRun, analysisParameters ]  = ...
                    Detection_UnusualSignal( missingSignals, temp, recordInfo, analysisParameters, selectedChannels{ intervalIndex } );
                if matlabAPIConfig.IsLogWriteToConsole
                    disp('# Completed...')
                end                
                
                
                %                 close all; figure;
                %                 plot( missingSignals.( selectedChannels{ intervalIndex } ) )
                
                % - - -  QRS MORPHOLOGY
                if matlabAPIConfig.IsLogWriteToConsole
                    disp( 'QRS Morphology Detection: ' )
                end
                [ temp ] = Detection_NormalQRSMorphology( temp, matlabAPIConfig );
                if matlabAPIConfig.IsLogWriteToConsole
                    disp('# Completed...')
                end                
                
                
                % - - - ASYSTOLE DETECTION
                [missingSignalAsystoleRuns, ~] = ClassRhythmAnalysis.AsystoleDetection( missingSignals, ...
                    temp.R, ...
                    recordInfo, ...
                    analysisParameters, ...
                    selectedChannels{ intervalIndex }  );
                
                
                % - - - MERGE RUNS
                % Asystole
                [ asystoleRuns ] = MergeRun( false, missingIntervalStartTime, missingSignalAsystoleRuns, asystoleRuns, originalLengthSignal, recordInfo );
                % VFib
                [ vfRuns ] = MergeRun( true, missingIntervalStartTime, missingSignalVFibRun, vfRuns, originalLengthSignal, recordInfo );
                % Noise
                [ noiseRuns ] = MergeRun( true, missingIntervalStartTime, missingSignalNoiseRun, noiseRuns, originalLengthSignal, recordInfo );
                
                
                % - - - QRS CHARACTERIZATION
                if ~isempty( temp.R )
                    
                    % - - - STORE QRS POINTS
                    qrsFieldNames = fieldnames( temp );
                    qrsFieldNames ( strcmp( qrsFieldNames, 'T' ) ) = [  ];
                    qrsFieldNames ( strcmp( qrsFieldNames, 'P' ) ) = [  ];
                    for pointName = 1 : length( qrsFieldNames )
                        [missingQRSComplex.( qrsFieldNames{ pointName } ) ] = StoreAnnotatedPointInMissingInterval( ...
                            'QRS', ...
                            qrsFieldNames{ pointName }, ...
                            missingQRSComplex.( qrsFieldNames{ pointName } ), ...
                            temp.( qrsFieldNames{ pointName } ), ...
                            missingIntervals.StartPoint( intervalIndex ), timeShift );
                    end
                    
                    
                    
                    % - - - STORE T DETAILS
                    tFieldNames = fieldnames( temp.T );
                    for pointName = 1 : length( tFieldNames )
                        [missingQRSComplex.T.( tFieldNames{ pointName } ) ] = StoreAnnotatedPointInMissingInterval( ...
                            'T', ...
                            tFieldNames{ pointName }, ...
                            missingQRSComplex.T.( tFieldNames{ pointName } ), ...
                            temp.T.( tFieldNames{ pointName } ), ...
                            missingIntervals.StartPoint( intervalIndex ), timeShift );
                    end
                    
                    
                    
                    % - - - STORE P DETAILS
                    pFieldNames = fieldnames( temp.P );
                    for pointName = 1 : length( pFieldNames )
                        [missingQRSComplex.P.( pFieldNames{ pointName } ) ] = StoreAnnotatedPointInMissingInterval( ...
                            'P', ...
                            pFieldNames{ pointName }, ...
                            missingQRSComplex.P.( pFieldNames{ pointName } ), ...
                            temp.P.( pFieldNames{ pointName } ), ...
                            missingIntervals.StartPoint( intervalIndex ), timeShift );
                    end
                    
                end
                
            end
            
        end
        
        
        %% Integration into the Previous Findings
        
        function [ qrsComplexes ] = Merge( analysisSignal, qrsComplexes, missingQRSComplexes, recordInfo )
            
            % Merging qrs complexes that found in missing intervals and lead 2 signal.
            %
            % [ qrsComplexes ] = Merge( lead2Signal, qrsComplexes, missingQRSComplexes )
            %
            % <<< Function Inputs >>>
            %   single[n,1] lead2Signal
            %   stucture qrsComplexes
            %   stucture missingQRSComplexes
            %
            % <<< Function Outputs >>>
            %   stucture qrsComplexes
            %
            
            % Initialization
            % - fields
            qrsFieldNames = fieldnames( qrsComplexes );
            qrsFieldNames ( strcmp( qrsFieldNames, 'T' ) ) = [  ];
            qrsFieldNames ( strcmp( qrsFieldNames, 'P' ) ) = [  ];
            tFieldNames = fieldnames( qrsComplexes.T );
            pFieldNames = fieldnames( qrsComplexes.P );
            
            % sorted points matrix initials
            sortedPointsIndex = 1;
            sortedPoints = zeros( ( length( qrsComplexes.R ) + length( missingQRSComplexes.R ) ), ...
                ( length( qrsFieldNames ) +  length( tFieldNames ) + length( pFieldNames ) ), ...
                'single' );
            
            % generation a matrix for sorting qrs complexes
            for fieldIndex = 1 : length( qrsFieldNames )
                sortedPoints( :, sortedPointsIndex ) = [ qrsComplexes.( qrsFieldNames{ fieldIndex } ); missingQRSComplexes.( qrsFieldNames{ fieldIndex } ) ];
                sortedPointsIndex = sortedPointsIndex + 1;
            end
            
            for fieldIndex = 1 : length( tFieldNames )
                sortedPoints( :, sortedPointsIndex ) = [ qrsComplexes.T.( tFieldNames{ fieldIndex } ); missingQRSComplexes.T.( tFieldNames{ fieldIndex } ) ];
                sortedPointsIndex = sortedPointsIndex + 1;
            end
            
            for fieldIndex = 1 : length( pFieldNames )
                sortedPoints( :, sortedPointsIndex ) = [ qrsComplexes.P.( pFieldNames{ fieldIndex } ); missingQRSComplexes.P.( pFieldNames{ fieldIndex } ) ];
                sortedPointsIndex = sortedPointsIndex + 1;
            end
            
            % sorting
            sortedPoints = sortrows(sortedPoints, 1);
            
            % identic beat detection
            identicBeat = diff( sortedPoints(:,1) );
            identicBeat = find( identicBeat < 0.200 * recordInfo.RecordSamplingFrequency );
            
            % selecting the one of the identic beat duos
            for identicBeatNo = 1 : numel( identicBeat )
                
                % selecting the extra qrs
                [~, lowerBeat] = min( [ analysisSignal( sortedPoints( identicBeat( identicBeatNo ),1 ) ),  analysisSignal( sortedPoints( identicBeat( identicBeatNo ) + 1, 1 ) ) ] );
                lowerBeat = identicBeat( identicBeatNo ) + lowerBeat - 1;
                % deleting the qrs complex
                sortedPoints( lowerBeat, : ) = [ ];
                % arrange matrix
                identicBeat = identicBeat - ones( numel(identicBeat), 1 );
                
            end
            
            % new qrs complex structure
            clear QRSComplexes missingQRS
            for fieldIndex = 1 : length( qrsFieldNames )
                qrsComplexes.( qrsFieldNames{ fieldIndex } ) = sortedPoints(:,1);
                sortedPoints(:,1) = [ ];
            end
            
            for fieldIndex = 1 : length( tFieldNames )
                qrsComplexes.T.( tFieldNames{ fieldIndex } ) = sortedPoints(:,1);
                sortedPoints(:,1) = [ ];
            end
            
            for fieldIndex = 1 : length( pFieldNames )
                qrsComplexes.P.( pFieldNames{ fieldIndex } ) = sortedPoints(:,1);
                sortedPoints(:,1) = [ ];
            end
            
        end
        
        
    end
    
    
end


%% subFunction : Store annotaded points in missing interval

function [storePoints] = StoreAnnotatedPointInMissingInterval( mainFieldName, fieldName, storePoints, points, startPoint, timeShift )

% Calculation of new points sample number in signal according to the missing interval start time.
%
% [storePoints] = StoreAnnotatedPointInMissingInterval( mainFieldName, fieldName, storePoints, points, startPoint, timeShift )
%
% <<< Function Inputs >>>
%   string mainFieldName
%   string fieldname
%   single[n,1] storePoints
%   single[n,1] points
%   single startPoint
%   single timeShift
%
% <<< Function Outputs >>>
%   single[n,1] storePoints
%

% ignore first and last beat
% if ~isempty( points )
%     points( 1 ) = [ ];
% end
% if ~isempty( points )
%     points( end ) = [ ];
% end

% qrs fields
if strcmp( mainFieldName, 'QRS' )
    if ...
            ~strcmp( fieldName, 'Type' ) &&...
            ~strcmp( fieldName, 'QRSAmplitude' ) &&... 
            ~strcmp( fieldName, 'STSegmentChange' ) &&... 
            ~strcmp( fieldName, 'JPointValue' ) &&... 
            ~strcmp( fieldName, 'NoisyBeat' ) &&... 
            ~strcmp( fieldName, 'SecondPWave' ) &&... 
            ~strcmp( fieldName, 'DetectionChannel' ) &&... 
            ~strcmp( fieldName, 'PeakAngle' ) 
        if ~isempty( points )
            % get indexes which has value 1
            onePoints = ( points == 1 );
            % shift
            points = points + ones( numel( points), 1 )*( startPoint - timeShift ) - 1;
            % return 1 values
            points( onePoints ) = 1;
            % store
            storePoints = [ storePoints; points ];
        end
    else
        if ~isempty( points )
            storePoints = [ storePoints; points ];
        end
    end
    % p and t fields
else
    if ~ strcmp( fieldName, 'Status' ) && ~strcmp( fieldName, 'Amplitude' ) 
        if ~isempty( points )
            % get indexes which has value 1
            onePoints = ( points == 1 );
            % shift
            points = points + ones( numel( points), 1 )*( startPoint - timeShift ) - 1;
            % return 1 values
            points( onePoints ) = 1;
            % store
            storePoints = [ storePoints; points ];
        end
    else
        if ~isempty( points )
            storePoints = [ storePoints; points ];
        end
    end
end

end


%% subFunction : Merge run

function [ run ] = MergeRun( pointPrecision, missingIntervalStartTime, missingRun, run, originalLengthSignal, recordInfo )

if ~isempty( missingRun )
    
    if pointPrecision
        
        % VFib Runs / VEctop Runs / Noise Runs
        if isempty( run )
            run.AverageHeartRate = missingRun.AverageHeartRate;
            run.Duration = missingRun.Duration;
            run.End = missingRun.End + missingIntervalStartTime - 1;
            run.EndTime = ClassDatetimeCalculation.Summation( ClassTypeConversion.ConvertChar2Datetime( missingRun.EndTime ), ( missingIntervalStartTime / recordInfo.RecordSamplingFrequency ) );
            run.Start = missingRun.Start + missingIntervalStartTime - 1;
            run.StartTime = ClassDatetimeCalculation.Summation( ClassTypeConversion.ConvertChar2Datetime( missingRun.StartTime ), ( missingIntervalStartTime / recordInfo.RecordSamplingFrequency ) );
            run.Points = zeros( originalLengthSignal, 1, 'logical' );
            for runIndex = 1 : length( run.Start )
                run.Points( double( run.Start( runIndex ) ) : double( run.End( runIndex ) ) ) = true;
            end
        else
            initialRunCount = length( run.Start );
            run.AverageHeartRate = [ run.AverageHeartRate; missingRun.AverageHeartRate ];
            run.Duration = [ run.Duration; missingRun.Duration ];
            run.End = [ run.End; missingRun.End + missingIntervalStartTime - 1 ];
            run.EndTime = [ run.EndTime; ...
                ClassDatetimeCalculation.Summation( ClassTypeConversion.ConvertChar2Datetime( missingRun.EndTime ), ( missingIntervalStartTime / recordInfo.RecordSamplingFrequency ) ) ];
            run.Start = [ run.Start; missingRun.Start + missingIntervalStartTime - 1 ];
            run.StartTime = [ run.StartTime; ...
                ClassDatetimeCalculation.Summation( ClassTypeConversion.ConvertChar2Datetime( missingRun.StartTime ), ( missingIntervalStartTime / recordInfo.RecordSamplingFrequency ) ) ];
            for runIndex = ( initialRunCount + 1 ): length( run.Start )
                run.Points( double( run.Start( runIndex ) ) : double( run.End( runIndex ) ) ) = true;
            end
        end
        
    else
        
        % Asystole Runs
        if isempty( run )
            run = missingRun;
            run.StartTime = ClassDatetimeCalculation.Summation( ClassTypeConversion.ConvertChar2Datetime( missingRun.StartTime ), ( missingIntervalStartTime / recordInfo.RecordSamplingFrequency ) );
            run.EndTime = ClassDatetimeCalculation.Summation( ClassTypeConversion.ConvertChar2Datetime( missingRun.EndTime ), ( missingIntervalStartTime / recordInfo.RecordSamplingFrequency ) );
        else
            run.AverageHeartRate = [ run.AverageHeartRate; missingRun.AverageHeartRate ];
            run.Duration = [ run.Duration; missingRun.Duration ];
            run.EndTime = [ run.EndTime; ...
                ClassDatetimeCalculation.Summation( ClassTypeConversion.ConvertChar2Datetime( missingRun.EndTime ), ( missingIntervalStartTime / recordInfo.RecordSamplingFrequency ) ) ];
            run.StartTime = [ run.StartTime; ...
                ClassDatetimeCalculation.Summation( ClassTypeConversion.ConvertChar2Datetime( missingRun.StartTime ), ( missingIntervalStartTime / recordInfo.RecordSamplingFrequency ) ) ];
        end
        
    end
    
end

end








