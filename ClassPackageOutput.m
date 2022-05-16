
classdef ClassPackageOutput
    
    %"ClassPackageOutput.m" class consists packaging outputs of MATLAP.API
    %
    % > FilteredECGPacket
    % > AnalysisSummaryPacket
    % > HeartRateSummaryPacket
    % > HRVariablityPacket
    % > STSegmentAnalysisPacket
    % > SinusArythmiaPacket
    % > VentricularEventsPacket
    % > SupraventricularEventsPacket
    % > TachycardiaPacket
    % > BradycardiaPacket
    % > AtrialFibPacket
    % > AtrialFlutterPacket
    % > VenticularFibPacket
    % > VentricularFlutterPacket
    % > AsystolePacket
    % > AlarmButtonPacket
    % > NoisePacket
    % > BeatDetailsPacket
    % >PaceMakerPacket
    % > JsonPacket
    %
    
    %% PROPERTIES
    
    properties
        
        %
        
    end
    
    %% STATIC METHODS
    
    methods (Static)
        
        
        %% Filtered Signal Packet
        
        function FilteredECGPacket( filteredSignal, matlabConfig )
            % Filtered Signal Packet
            %
            % FilteredECGPacket( ecgSignal )
            %
            % <<< Function Inputs >>>
            %   struct filteredSignal
            %   .V1 [nx1]
            %   .V2 [nx1]
            %   .V3 [nx1]
            %   .V4 [nx1]
            %   .V5 [nx1]
            %   .V6 [nx1]
            %   .Lead1 [nx1]
            %   .Lead2 [nx1]
            % string fileAdress
            %
            
            % Save each channel as a indivual file
            % - WebUITest Application
            %             if matlabConfig.Environment.isTest
            %                 % get folder adress
            %                 folderAdress = matlabConfig.Environment.channelFileAdress;
            %                 if ~( folderAdress( end ) == '\' ); folderAdress = [ folderAdress '\' ]; end
            %                 % file name
            %                 fileName = strsplit( matlabConfig.FileAdress, '\' );
            %                 fileName = char( erase( fileName( end ), '_RawSignal.bin' ) );
            %                 % new folder adress
            %                 folderAdress = [ folderAdress fileName '_channel.bin' ];
            %                 % For each
            %                 for channelIndex = 1:length( channelList )
            %                     % file adress
            %                     channelAdress = strrep( folderAdress, '_channel.bin', [ '_' channelList{ channelIndex } '.bin' ] );
            %                     % open file
            %                     channelFile = fopen( channelAdress, 'W');
            %                     % write
            %                     fwrite(channelFile, filteredSignal.( channelList{ channelIndex } ), 'single');
            %                     % close file
            %                     fclose(channelFile);
            %                     % close all
            %                     fclose( 'all' );
            %                 end
            %             end            
            % Conversion
            filteredSignal = transpose( cell2mat( transpose( struct2cell( filteredSignal ) ) ) );
            % File Adress
            fileAdress =  matlabConfig.FileAdress;
            % open file
            file2Write = fopen( fileAdress, 'W');
            % write
            fwrite(file2Write, filteredSignal, 'single');
            % close file
            fclose(file2Write);
            % close all
            fclose( 'all' );
            
        end
        
        
        %% Analysis Summary Packet
        
        function analysisSummaryPacket = AnalysisSummaryPacket( analysisChannel, recordInfo, signalSampleDuration, qrsComplexes, noiseRun, normalSample )
            % Analysis Summary Packet
            %
            % analysisSummaryPacket = AnalysisSummaryPacket( analysisDuration, totalBeats )
            %
            % <<< Function Inputs >>>
            %   struct recordInfo
            %   single signalSampleDuration
            %   struct qrsComplexes
            %   struct noiseRun
            %
            % <<< Function Outputs >>>
            %   struct analysisSummaryPacket
            
            % Signal Quality
            % - signal duration sample to ms
            signalSampleDuration = signalSampleDuration / recordInfo.RecordSamplingFrequency; % sec
            signalSampleDuration = round( signalSampleDuration * single( 1000 ) ); % msec
            % - noise ratio
            %             if ~isempty( qrsComplexes.R ); noisyBeatRatio = sum( qrsComplexes.NoisyBeat ) / length( qrsComplexes.R ); else; noisyBeatRatio = single( 0 ); end
            if ~isempty( noiseRun );signalNoiseRatio = sum( noiseRun.Duration ) / signalSampleDuration; else; signalNoiseRatio = single( 0 ); end
            %             totalNoiseRatio = single( round( ( noisyBeatRatio + signalNoiseRatio ), 2 ) );
            totalNoiseRatio = single( round( ( signalNoiseRatio ), 2 ) );
            
            % Class: AnalysisSummary
            % -
            analysisSummaryPacket.Summary.RecordStartTime = recordInfo.RecordStartTime;
            % -
            analysisSummaryPacket.Summary.RecordEndTime = recordInfo.RecordEndTime;
            % -
            analysisSummaryPacket.Summary.AnalysisDuration = ...
                ClassTypeConversion.ConvertMiliseconds2String( signalSampleDuration );
            % -
            if isempty( noiseRun )
                analysisSummaryPacket.Summary.PoorSignalDuration = ...
                    ClassTypeConversion.ConvertMiliseconds2String( 0 );
            else
                analysisSummaryPacket.Summary.PoorSignalDuration = ...
                    ClassTypeConversion.ConvertMiliseconds2String( sum( noiseRun.Duration ) );
            end
            % -
            analysisSummaryPacket.Summary.AnalysisChannel = analysisChannel;
            % - 
            
             analysisSummaryPacket.Summary.NormalSample = normalSample;
            if numel( recordInfo.ChannelList ) >= numel( recordInfo.ActiveSignals )
                analysisSummaryPacket.Summary.ActiveSignals = recordInfo.ActiveSignals;
            else
                analysisSummaryPacket.Summary.ActiveSignals = recordInfo.ChannelList;
            end
            % -
            analysisSummaryPacket.Summary.SignalQuality = single ( ( single( 1 ) - totalNoiseRatio ) * 100 );
            
            % Class: Beats
            analysisSummaryPacket.Beats.TotalBeats = int32( length( qrsComplexes.R ) );
            
            % Class: AbnormalBeats
            analysisSummaryPacket.AbnormalBeats = string( NaN );
            %             analysisSummaryPacket.AbnormalBeats.TotalBeats = int32( 0 );
            %             analysisSummaryPacket.AbnormalBeats.BeatRatio = single( 0 );
            
            % Class: UnidentifiedBeats
            analysisSummaryPacket.UnidentifiedBeats = string( NaN );
            %             analysisSummaryPacket.UnidentifiedBeats.TotalBeats = int32( 0 );
            %             analysisSummaryPacket.UnidentifiedBeats.BeatRatio = single( 0 );
            
            % Class: PacemakerBeats
            analysisSummaryPacket.PacemakerBeats = string( NaN );
            %            analysisSummaryPacket.PacemakerBeats.TotalBeats = int32( 0 );
            %            analysisSummaryPacket.PacemakerBeats.BeatRatio = single( 0 );
            
        end
        
        
        %% Heart Rate Summary Packet
        
        function heartRateSummaryPacket = HeartRateSummaryPacket( GeneralPeriod, ActivePeriod, PassivePeriod )
            % Heart Rate Summary Packet
            %
            % heartRateSummaryPacket = HeartRateSummaryPacket( GeneralPeriod, ActivePeriod, PassivePeriod )
            %
            % <<< Function Inputs >>>
            %     struct GeneralPeriod
            %     struct ActivePeriod
            %     struct PassivePeriod
            %     - period.MinimumHeartRate
            %     - period.MinimumHeartRateTime
            %     - period.MaximumHeartRate
            %     - period.MaximumHeartRateTime
            %     - period.AverageHeartRate
            %
            % <<< Function Outputs >>>
            %   struct heartRateSummaryPacket
            
            % Class: GeneralPeriod
            if ~isempty(GeneralPeriod)
                
                % 0
                heartRateSummaryPacket.GeneralPeriod.LowestHeartRate = int32( GeneralPeriod.LowestHeartRate );
                % 1
                heartRateSummaryPacket.GeneralPeriod.LowestHeartRateTime = GeneralPeriod.LowestHeartRateTime;
                % 2
                heartRateSummaryPacket.GeneralPeriod.HighestHeartRate = int32( GeneralPeriod.HighestHeartRate );
                % 3
                heartRateSummaryPacket.GeneralPeriod.HighestHeartRateTime = GeneralPeriod.HighestHeartRateTime;
                % 4
                heartRateSummaryPacket.GeneralPeriod.AverageHeartRate = int32 ( GeneralPeriod.AverageHeartRate ) ;
                
            else
                
                % 0
                heartRateSummaryPacket.GeneralPeriod = string(NaN);
                
            end
            
            % Class: PassivePeriod
            if ~isempty( PassivePeriod )
                
                % 5
                heartRateSummaryPacket.PassivePeriod.LowestHeartRate =  int32( PassivePeriod.LowestHeartRate );
                % 6
                heartRateSummaryPacket.PassivePeriod.LowestHeartRateTime = PassivePeriod.LowestHeartRateTime;
                % 7
                heartRateSummaryPacket.PassivePeriod.HighestHeartRate = int32( PassivePeriod.HighestHeartRate );
                % 8
                heartRateSummaryPacket.PassivePeriod.HighestHeartRateTime = PassivePeriod.HighestHeartRateTime;
                % 9
                heartRateSummaryPacket.PassivePeriod.AverageHeartRate = int32 ( PassivePeriod.AverageHeartRate ) ;
                
            else
                
                % 0
                heartRateSummaryPacket.PassivePeriod = string(NaN);
                
            end
            
            % Class: ActivePeriod
            if ~isempty( ActivePeriod )
                
                % 10
                heartRateSummaryPacket.ActivePeriod.LowestHeartRate = int32( ActivePeriod.LowestHeartRate );
                % 11
                heartRateSummaryPacket.ActivePeriod.LowestHeartRateTime = ActivePeriod.LowestHeartRateTime;
                % 12
                heartRateSummaryPacket.ActivePeriod.HighestHeartRate = int32( ActivePeriod.HighestHeartRate );
                % 13
                heartRateSummaryPacket.ActivePeriod.HighestHeartRateTime =  ActivePeriod.HighestHeartRateTime;
                % 14
                heartRateSummaryPacket.ActivePeriod.AverageHeartRate = int32 ( ActivePeriod.AverageHeartRate ) ;
                
            else
                
                % 0
                heartRateSummaryPacket.ActivePeriod = string(NaN);
                
            end
            
        end
        

        
        
        %% HRV Packet
         
        
        function hrvPacket = HRVariabilityPacket( hrvAnalysisResult, apiInfo )
            % HRV Packet
            %
            % hrvPacket = HRVariablityPacket( initialValue )
            %
            % <<< Function Inputs >>>
            %   single initialValue
            %
            % <<< Function Outputs >>>
            %   struct hrvPacket
            
            % Class: itself
            if ~isempty( hrvAnalysisResult ) && ( apiInfo.Version.Major > 6 )
                
                % Parameters
                hrvPacket.Parameters.MinuteResolution = int32( hrvAnalysisResult.Resolution );
                % Summary
                if isempty( hrvAnalysisResult.sdnn ) || isempty( hrvAnalysisResult.sdann )
                    hrvPacket.Summary = string( NaN );
                else
                    hrvPacket.Summary.SDANN = round( hrvAnalysisResult.sdann, 2);
                    hrvPacket.Summary.SDNNIndex = round( hrvAnalysisResult.sdnnIndex, 2);
                end
                % Graph
                hrvPacket.Graph = HRVGraph( hrvAnalysisResult );
                
            else
                
                % Not supported
                hrvPacket = string( NaN );
                
            end
            
        end
        
       
        %% ST Segment Analysis Packet
        
        function stSegmentAnalysisPacket = STSegmentAnalysisPacket ( qrsComplexes, recordInfo, apiInfo )
            % ST Segment Analysis Packet
            %
            % stSegmentAnalysisPacket = STSegmentAnalysisPacket ( qrsComplexes, recordInfo )
            %
            % <<< Function Inputs >>>
            %   struct qrsComplexes
            %   struct recordInfo
            %
            % <<< Function Outputs >>>
            %   struct stSegmentAnalysisPacket
            
            % Class: itself
            if ~isempty( qrsComplexes.R ) && ( apiInfo.Version.Major > 6 )
                
                % Summary
                clearedSTSegmentChange = round( qrsComplexes.STSegmentChange( 2:end-1 ), 2 );
                % - Mean Amplitude
                stSegmentAnalysisPacket.Summary.MeanAmplitude = round( mean( clearedSTSegmentChange ), 2 );
                % - Max Amplitude
                [ maxAmplitudeValue, maxAmplitudeIndex ] = max( clearedSTSegmentChange );
                maxAmplitudeIndex = maxAmplitudeIndex + 1; % first beat was ignored
                % - - [ value ]
                stSegmentAnalysisPacket.Summary.HighestAmplitudeValue = ...
                    single( maxAmplitudeValue );
                % - - [ date time ]
                stSegmentAnalysisPacket.Summary.HighestAmplitudeDateTime = ...
                    ClassDatetimeCalculation.Summation( recordInfo.RecordStartTime, ( qrsComplexes.R( maxAmplitudeIndex ) / recordInfo.RecordSamplingFrequency ) );
                % - Min Amplitude
                [ minAmplitudeValue, minAmplitudeIndex ] = min( clearedSTSegmentChange );
                minAmplitudeIndex = minAmplitudeIndex + 1; % first beat was ignored
                % - - [ value ]
                stSegmentAnalysisPacket.Summary.LowestAmplitudeValue = ...
                    single( minAmplitudeValue );
                % - - [ date time ]
                stSegmentAnalysisPacket.Summary.LowestAmplitudeDateTime = ...
                    ClassDatetimeCalculation.Summation( recordInfo.RecordStartTime, ( qrsComplexes.R( minAmplitudeIndex ) / recordInfo.RecordSamplingFrequency ) );
                
                % ST Segment
                stSegmentAnalysisPacket.Graph = STSegmentGraph( qrsComplexes );
                
            else
                
                % Not supported
                stSegmentAnalysisPacket.Summary = string( NaN );
                stSegmentAnalysisPacket.Graph = string( NaN );
                
            end
            
        end
        
        
        %% Sinus Arythmia Response
        
        function sinusArythmiaPacket = SinusArythmiaPacket( SinusArythmiaRuns, totalBeats )
            % Atrial Flutter Packet
            %
            % hrvPacket = HRVariablityPacket( initialValue )
            %
            % <<< Function Inputs >>>
            %   single initialValue
            %
            % <<< Function Outputs >>>
            %   struct atrialFlutterPacket
            
            % Class: itself
            if ~isempty( SinusArythmiaRuns )

                % IsFeatureSupported
                sinusArythmiaPacket.IsFeatureSupported = true;
                
                % Longest Run
                longestDurationRunBeats = max(SinusArythmiaRuns.Duration );
                longestDurationRunIndex = find(SinusArythmiaRuns.Duration == longestDurationRunBeats, 1, 'last');
                
                % subClass: Summary
                % - TotalBeats
                sinusArythmiaPacket.Summary.TotalBeats = int32 ( sum( SinusArythmiaRuns.Duration ) );
                % - BeatRatio
                sinusArythmiaPacket.Summary.BeatRatio = single ( single( sinusArythmiaPacket.Summary.TotalBeats ) / totalBeats );
                sinusArythmiaPacket.Summary.BeatRatio = round( ( 100 * sinusArythmiaPacket.Summary.BeatRatio ), 2);
                % - TotalRuns
                sinusArythmiaPacket.Summary.TotalRuns = int32 ( numel( SinusArythmiaRuns.StartTime(:, 1) ) );
                % -Longest
                sinusArythmiaPacket.Summary.LongestRunBeats = int32 ( SinusArythmiaRuns.Duration(longestDurationRunIndex) );
                sinusArythmiaPacket.Summary.LongestRunStartTime = SinusArythmiaRuns.StartTime(longestDurationRunIndex, :);
                sinusArythmiaPacket.Summary.LongestRunEndTime = SinusArythmiaRuns.EndTime(longestDurationRunIndex, :);
                sinusArythmiaPacket.Summary.LongestRunHeartRate = SinusArythmiaRuns.AverageHeartRate(longestDurationRunIndex, :);
                
                % subClass: Atrial Fibrillation Runs
                sinusArythmiaPacket.Runs = GenerateClassList( SinusArythmiaRuns, 'SinusArrythmia', 'Beats');
                
            else
                
                % IsFeatureSupported
                sinusArythmiaPacket.IsFeatureSupported = true;
                sinusArythmiaPacket.Summary = string(NaN);
                sinusArythmiaPacket.Runs = string(NaN);
                
            end
            
        end
        
        
        %% Ventricular Events Packet
        
        function ventricularEventsPacket = VentricularEventsPacket( QRSComplexes, PVCRuns )
            % Ventricular Events Packet
            %
            % ventricularEventsPacket = VentricularEventsPacket( initialValue )
            %
            % <<< Function Inputs >>>
            %   struct QRSComplexes
            %   struct PVCRuns
            %
            % <<< Function Outputs >>>
            %   struct ventricularEventsPacket
            
            % Class: itself
            if ~isempty( PVCRuns )
                
                % Summary/1
                ventricularEventsPacket.Summary.TotalBeats = int32( PVCRuns.TotalBeats );
                ventricularEventsPacket.Summary.BeatRatio = PVCRuns.TotalBeats / length( QRSComplexes.R );
                ventricularEventsPacket.Summary.BeatRatio = single( round( ( 100 * ventricularEventsPacket.Summary.BeatRatio ), 2) );
                if isnan( ventricularEventsPacket.Summary.BeatRatio ); ventricularEventsPacket.Summary.BeatRatio = 0; end
                ventricularEventsPacket.Summary.TotalRuns = int32( PVCRuns.TotalRuns );
                
                % PVC Isolated
                if ~isempty( PVCRuns.IsolatedRun )
                    ventricularEventsPacket.PVCIsolated.IsFeatureSupported = true;
                    ventricularEventsPacket.PVCIsolated.Summary.TotalBeats = int32( length( PVCRuns.IsolatedRun.StartBeat ) );
                    ventricularEventsPacket.PVCIsolated.Summary.BeatRatio = single( round( ( PVCRuns.IsolatedRun.TotalRun / length( QRSComplexes.R ) ), 2 ) );
                    ventricularEventsPacket.PVCIsolated.Summary.BeatRatio = single( round( ( 100 * ventricularEventsPacket.PVCIsolated.Summary.BeatRatio ), 2) );
                    ventricularEventsPacket.PVCIsolated.Runs = GenerateClassList( PVCRuns.IsolatedRun, 'PVCIsolated', 'Beats');
                else
                    ventricularEventsPacket.PVCIsolated.IsFeatureSupported = true;
                    ventricularEventsPacket.PVCIsolated.Summary = string(NaN);
                    ventricularEventsPacket.PVCIsolated.Runs = string(NaN);
                end
                
                % PVC Bigeminy
                if ~isempty( PVCRuns.BigeminyRun )
                    % A. IsFeatureSupported
                    ventricularEventsPacket.PVCBigeminy.IsFeatureSupported = true;
                    % Longest Run
                    longestDurationRunBeats = max( PVCRuns.BigeminyRun.Duration );
                    longestDurationRunIndex = find( PVCRuns.BigeminyRun.Duration == longestDurationRunBeats, 1, 'last');
                    % B. Summary
                    ventricularEventsPacket.PVCBigeminy.Summary.TotalRuns = int32( length( PVCRuns.BigeminyRun.StartBeat ) );
                    ventricularEventsPacket.PVCBigeminy.Summary.LongestRunBeats = int32 ( PVCRuns.BigeminyRun.Duration(longestDurationRunIndex) );
                    ventricularEventsPacket.PVCBigeminy.Summary.LongestRunStartTime = PVCRuns.BigeminyRun.StartTime(longestDurationRunIndex, :);
                    ventricularEventsPacket.PVCBigeminy.Summary.LongestRunEndTime = PVCRuns.BigeminyRun.EndTime(longestDurationRunIndex, :);
                    ventricularEventsPacket.PVCBigeminy.Summary.LongestRunHeartRate = PVCRuns.BigeminyRun.AverageHeartRate(longestDurationRunIndex, :);
                    % C. Runs
                    ventricularEventsPacket.PVCBigeminy.Runs = GenerateClassList( PVCRuns.BigeminyRun, 'PVCBigeminy', 'Beats');
                else
                    ventricularEventsPacket.PVCBigeminy.IsFeatureSupported = true;
                    ventricularEventsPacket.PVCBigeminy.Summary = string(NaN);
                    ventricularEventsPacket.PVCBigeminy.Runs = string(NaN);
                end
                
                % PVC Trigeminy
                if ~isempty( PVCRuns.TrigeminyRun )
                    % A. IsFeatureSupported
                    ventricularEventsPacket.PVCTrigeminy.IsFeatureSupported = true;
                    % Longest Run
                    longestDurationRunBeats = max( PVCRuns.TrigeminyRun.Duration );
                    longestDurationRunIndex = find( PVCRuns.TrigeminyRun.Duration == longestDurationRunBeats, 1, 'last');
                    % B. Summary
                    ventricularEventsPacket.PVCTrigeminy.Summary.TotalRuns = length( PVCRuns.TrigeminyRun.StartBeat );
                    ventricularEventsPacket.PVCTrigeminy.Summary.LongestRunBeats = int32 ( PVCRuns.TrigeminyRun.Duration(longestDurationRunIndex) );
                    ventricularEventsPacket.PVCTrigeminy.Summary.LongestRunStartTime = PVCRuns.TrigeminyRun.StartTime(longestDurationRunIndex, :);
                    ventricularEventsPacket.PVCTrigeminy.Summary.LongestRunEndTime = PVCRuns.TrigeminyRun.EndTime(longestDurationRunIndex, :);
                    ventricularEventsPacket.PVCTrigeminy.Summary.LongestRunHeartRate = PVCRuns.TrigeminyRun.AverageHeartRate(longestDurationRunIndex, :);
                    % C. Runs
                    ventricularEventsPacket.PVCTrigeminy.Runs = GenerateClassList( PVCRuns.TrigeminyRun, 'PVCTrigeminy', 'Beats');
                else
                    ventricularEventsPacket.PVCTrigeminy.IsFeatureSupported = true;
                    ventricularEventsPacket.PVCTrigeminy.Summary = string(NaN);
                    ventricularEventsPacket.PVCTrigeminy.Runs = string(NaN);
                end
                
                % PVC Quadrigeminy
                if ~isempty( PVCRuns.QuadrigeminyRun )
                    % A. IsFeatureSupported
                    ventricularEventsPacket.PVCQuadrigeminy.IsFeatureSupported = true;
                    % Longest Run
                    longestDurationRunBeats = max( PVCRuns.QuadrigeminyRun.Duration );
                    longestDurationRunIndex = find( PVCRuns.QuadrigeminyRun.Duration == longestDurationRunBeats, 1, 'last');
                    % B. Summary
                    ventricularEventsPacket.PVCQuadrigeminy.Summary.TotalRuns = length( PVCRuns.QuadrigeminyRun.StartBeat ) ;
                    ventricularEventsPacket.PVCQuadrigeminy.Summary.LongestRunBeats = int32 ( PVCRuns.QuadrigeminyRun.Duration(longestDurationRunIndex) );
                    ventricularEventsPacket.PVCQuadrigeminy.Summary.LongestRunStartTime = PVCRuns.QuadrigeminyRun.StartTime(longestDurationRunIndex, :);
                    ventricularEventsPacket.PVCQuadrigeminy.Summary.LongestRunEndTime = PVCRuns.QuadrigeminyRun.EndTime(longestDurationRunIndex, :);
                    ventricularEventsPacket.PVCQuadrigeminy.Summary.LongestRunHeartRate = PVCRuns.QuadrigeminyRun.AverageHeartRate(longestDurationRunIndex, :);
                    % C. Runs
                    ventricularEventsPacket.PVCQuadrigeminy.Runs = GenerateClassList( PVCRuns.QuadrigeminyRun, 'PVCQuadrigeminy', 'Beats');
                else
                    ventricularEventsPacket.PVCQuadrigeminy.IsFeatureSupported = true;
                    ventricularEventsPacket.PVCQuadrigeminy.Summary = string(NaN);
                    ventricularEventsPacket.PVCQuadrigeminy.Runs = string(NaN);
                end
                
                % PVC Couplet
                if ~isempty( PVCRuns.CoupletRun )
                    ventricularEventsPacket.PVCCouplet.IsFeatureSupported = true;
                    ventricularEventsPacket.PVCCouplet.Summary.TotalRuns = int32( length( PVCRuns.CoupletRun.StartBeat ) );
                    ventricularEventsPacket.PVCCouplet.Runs = GenerateClassList( PVCRuns.CoupletRun, 'PVCCouplets', 'Beats');
                else
                    ventricularEventsPacket.PVCCouplet.IsFeatureSupported = true;
                    ventricularEventsPacket.PVCCouplet.Summary = string(NaN);
                    ventricularEventsPacket.PVCCouplet.Runs = string(NaN);
                end
                
                % PVC Triplet
                if ~isempty( PVCRuns.TripletRun )
                    ventricularEventsPacket.PVCTriplet.IsFeatureSupported = true;
                    ventricularEventsPacket.PVCTriplet.Summary.TotalRuns = int32( length( PVCRuns.TripletRun.StartBeat ) );
                    ventricularEventsPacket.PVCTriplet.Runs = GenerateClassList( PVCRuns.TripletRun, 'PVCTriplets', 'Beats');
                else
                    ventricularEventsPacket.PVCTriplet.IsFeatureSupported = true;
                    ventricularEventsPacket.PVCTriplet.Summary = string(NaN);
                    ventricularEventsPacket.PVCTriplet.Runs = string(NaN);
                end
                
                % PVC Salvo
                if ~isempty( PVCRuns.SalvoRun )
                    % A. IsFeatureSupported
                    ventricularEventsPacket.PVCSalvo.IsFeatureSupported = true;
                    % HighestHeartRate TahcyRun
                    highestHeartRateRunAverageHeartRate = max( PVCRuns.SalvoRun.AverageHeartRate );
                    highestHeartRateRunIndex = find( PVCRuns.SalvoRun.AverageHeartRate == highestHeartRateRunAverageHeartRate, 1, 'last');
                    % B. Summary
                    ventricularEventsPacket.PVCSalvo.Summary.TotalRuns = length( PVCRuns.SalvoRun.StartBeat ) ;
                    ventricularEventsPacket.PVCSalvo.Summary.HighestHeartRateRunBeats = int32 ( PVCRuns.SalvoRun.Duration(highestHeartRateRunIndex) );
                    ventricularEventsPacket.PVCSalvo.Summary.HighestHeartRateRunStartTime = PVCRuns.SalvoRun.StartTime(highestHeartRateRunIndex, :);
                    ventricularEventsPacket.PVCSalvo.Summary.HighestHeartRateRunEndTime = PVCRuns.SalvoRun.EndTime(highestHeartRateRunIndex, :);
                    ventricularEventsPacket.PVCSalvo.Summary.HighestHeartRateRunHeartRate = PVCRuns.SalvoRun.AverageHeartRate(highestHeartRateRunIndex, :);
                    % C. Runs
                    ventricularEventsPacket.PVCSalvo.Runs = GenerateClassList( PVCRuns.SalvoRun, 'PVCSalvo', 'Beats');
                else
                    ventricularEventsPacket.PVCSalvo.IsFeatureSupported = true;
                    ventricularEventsPacket.PVCSalvo.Summary = string(NaN);
                    ventricularEventsPacket.PVCSalvo.Runs = string(NaN);
                end
                
                
                % IdioventricularRhythm
                if ~isempty( PVCRuns.IVRRun )
                    % A. IsFeatureSupported
                    ventricularEventsPacket.IdioventricularRhythm.IsFeatureSupported = true;
                    
                    % Longest BradyDuration
                    longestDurationRunBeats = max( PVCRuns.IVRRun.Duration );
                    longestDurationRunIndex = find( PVCRuns.IVRRun.Duration == longestDurationRunBeats, 1, 'last');
                    
                    % LowestHeartRate TahcyRun
                    lowestHeartRateRunAverageHeartRate = min( PVCRuns.IVRRun.AverageHeartRate);
                    lowestHeartRateRunIndex = find( PVCRuns.IVRRun.AverageHeartRate == lowestHeartRateRunAverageHeartRate, 1, 'last');
                    
                    % B. Summary
                    % - TotalBeats
                    ventricularEventsPacket.IdioventricularRhythm.Summary.TotalBeats = int32 ( sum( PVCRuns.IVRRun.Duration ) );
                    % - BeatRatio
                    ventricularEventsPacket.IdioventricularRhythm.Summary.BeatRatio = single ( single( ventricularEventsPacket.IdioventricularRhythm.Summary.TotalBeats ) / length( QRSComplexes.R ) );
                    ventricularEventsPacket.IdioventricularRhythm.Summary.BeatRatio = round( ( 100 * ventricularEventsPacket.IdioventricularRhythm.Summary.BeatRatio ), 2);
                    % - TotalRuns
                    ventricularEventsPacket.IdioventricularRhythm.Summary.TotalRuns = int32 ( numel( PVCRuns.IVRRun.StartTime(:, 1) ) );
                    % -LongestRun
                    ventricularEventsPacket.IdioventricularRhythm.Summary.LongestRunBeats = int32 ( PVCRuns.IVRRun.Duration(longestDurationRunIndex) );
                    ventricularEventsPacket.IdioventricularRhythm.Summary.LongestRunStartTime = PVCRuns.IVRRun.StartTime(longestDurationRunIndex, :);
                    ventricularEventsPacket.IdioventricularRhythm.Summary.LongestRunEndTime = PVCRuns.IVRRun.EndTime(longestDurationRunIndex, :);
                    ventricularEventsPacket.IdioventricularRhythm.Summary.LongestRunHeartRate = PVCRuns.IVRRun.AverageHeartRate(longestDurationRunIndex, :);
                    % -LowestHeartRate
                    ventricularEventsPacket.IdioventricularRhythm.Summary.LowestHeartRateRunBeats = int32 ( PVCRuns.IVRRun.Duration(lowestHeartRateRunIndex) );
                    ventricularEventsPacket.IdioventricularRhythm.Summary.LowestHeartRateRunStartTime = PVCRuns.IVRRun.StartTime(lowestHeartRateRunIndex, :);
                    ventricularEventsPacket.IdioventricularRhythm.Summary.LowestHeartRateRunEndTime = PVCRuns.IVRRun.EndTime(lowestHeartRateRunIndex, :);
                    ventricularEventsPacket.IdioventricularRhythm.Summary.LowestHeartRateRunHeartRate = PVCRuns.IVRRun.AverageHeartRate(lowestHeartRateRunIndex, :);
                    
                    % C. Runs
                    ventricularEventsPacket.IdioventricularRhythm.Runs = GenerateClassList( PVCRuns.IVRRun, 'IVR', 'Beats');
                else
                    ventricularEventsPacket.IdioventricularRhythm.IsFeatureSupported = true;
                    ventricularEventsPacket.IdioventricularRhythm.Summary = string(NaN);
                    ventricularEventsPacket.IdioventricularRhythm.Runs = string(NaN);
                end
                
                % AcceleratedidioventricularRhythm
                if ~isempty( PVCRuns.AIVRRun )
                    % A. IsFeatureSupported
                    ventricularEventsPacket.AcceleratedIdioventricularRhythm.IsFeatureSupported = true;
                    
                    % Longest BradyDuration
                    longestDurationRunBeats = max( PVCRuns.AIVRRun.Duration );
                    longestDurationRunIndex = find( PVCRuns.AIVRRun.Duration == longestDurationRunBeats, 1, 'last');
                    
                    % HighestHeartRate TahcyRun
                    lowestHeartRateRunAverageHeartRate = min( PVCRuns.AIVRRun.AverageHeartRate);
                    lowestHeartRateRunIndex = find( PVCRuns.AIVRRun.AverageHeartRate == lowestHeartRateRunAverageHeartRate, 1, 'last');
                    
                    % subClass: Summary
                    % - TotalBeats
                    ventricularEventsPacket.AcceleratedIdioventricularRhythm.Summary.TotalBeats = int32 ( sum( PVCRuns.AIVRRun.Duration ) );
                    % - BeatRatio
                    ventricularEventsPacket.AcceleratedIdioventricularRhythm.Summary.BeatRatio = single ( single( ventricularEventsPacket.AcceleratedIdioventricularRhythm.Summary.TotalBeats ) / length( QRSComplexes.R ) );
                    ventricularEventsPacket.AcceleratedIdioventricularRhythm.Summary.BeatRatio = round( ( 100 * ventricularEventsPacket.AcceleratedIdioventricularRhythm.Summary.BeatRatio ), 2);
                    % - TotalRuns
                    ventricularEventsPacket.AcceleratedIdioventricularRhythm.Summary.TotalRuns = int32 ( numel( PVCRuns.AIVRRun.StartTime(:, 1) ) );
                    % -LongestRun
                    ventricularEventsPacket.AcceleratedIdioventricularRhythm.Summary.LongestRunBeats = int32 ( PVCRuns.AIVRRun.Duration(longestDurationRunIndex) );
                    ventricularEventsPacket.AcceleratedIdioventricularRhythm.Summary.LongestRunStartTime = PVCRuns.AIVRRun.StartTime(longestDurationRunIndex, :);
                    ventricularEventsPacket.AcceleratedIdioventricularRhythm.Summary.LongestRunEndTime = PVCRuns.AIVRRun.EndTime(longestDurationRunIndex, :);
                    ventricularEventsPacket.AcceleratedIdioventricularRhythm.Summary.LongestRunHeartRate = PVCRuns.AIVRRun.AverageHeartRate(longestDurationRunIndex, :);
                    % -LowestHeartRate
                    ventricularEventsPacket.AcceleratedIdioventricularRhythm.Summary.LowestHeartRateRunBeats = int32 ( PVCRuns.AIVRRun.Duration(lowestHeartRateRunIndex) );
                    ventricularEventsPacket.AcceleratedIdioventricularRhythm.Summary.LowestHeartRateRunStartTime = PVCRuns.AIVRRun.StartTime(lowestHeartRateRunIndex, :);
                    ventricularEventsPacket.AcceleratedIdioventricularRhythm.Summary.LowestHeartRateRunEndTime = PVCRuns.AIVRRun.EndTime(lowestHeartRateRunIndex, :);
                    ventricularEventsPacket.AcceleratedIdioventricularRhythm.Summary.LowestHeartRateRunHeartRate = PVCRuns.AIVRRun.AverageHeartRate(lowestHeartRateRunIndex, :);
                    
                    % C. Runs
                    ventricularEventsPacket.AcceleratedIdioventricularRhythm.Runs = GenerateClassList( PVCRuns.AIVRRun, 'AIVR', 'Beats');
                else
                    ventricularEventsPacket.AcceleratedIdioventricularRhythm.IsFeatureSupported = true;
                    ventricularEventsPacket.AcceleratedIdioventricularRhythm.Summary = string(NaN);
                    ventricularEventsPacket.AcceleratedIdioventricularRhythm.Runs = string(NaN);
                end
                
                % RonT
                ventricularEventsPacket.RonT.IsFeatureSupported = true;
                ventricularEventsPacket.RonT.TotalBeats = int32( 0 );
                ventricularEventsPacket.RonT.EventType = "RonT";
                
                
            else
                
                % Not supported
                ventricularEventsPacket.Summary = string(NaN);
                ventricularEventsPacket.PVCIsolated.IsFeatureSupported = false;
                ventricularEventsPacket.PVCBigeminy.IsFeatureSupported = false;
                ventricularEventsPacket.PVCTrigeminy.IsFeatureSupported = false;
                ventricularEventsPacket.PVCQuadrigeminy.IsFeatureSupported = false;
                ventricularEventsPacket.PVCCouplet.IsFeatureSupported = false;
                ventricularEventsPacket.PVCTriplet.IsFeatureSupported = false;
                ventricularEventsPacket.PVCSalvo.IsFeatureSupported = false;
                ventricularEventsPacket.IdioventricularRhythm.IsFeatureSupported = false;
                ventricularEventsPacket.AcceleratedIdioventricularRhythm.IsFeatureSupported = false;
                ventricularEventsPacket.RonT.IsFeatureSupported = false;
                
            end
            
        end
        
        
        %% Supraventricular Events Packet
        
        function supraventricularEventsPacket = SupraventricularEventsPacket( QRSComplexes, PACRuns )
            % Supraventricular Events Packet
            %
            % supraventricularEventsPacket = SupraventricularEventsPacket( initialValue )
            %
            % <<< Function Inputs >>>
            %   struct QRSComplexes
            %   struct PACRuns
            %
            % <<< Function Outputs >>>
            %   struct supraventricularEventsPacket
            
            % Class: itself
            if ~isempty( PACRuns )
                
                % Summary/1
                supraventricularEventsPacket.Summary.TotalBeats = int32( PACRuns.TotalBeats );
                supraventricularEventsPacket.Summary.BeatRatio = PACRuns.TotalBeats / length( QRSComplexes.R );
                supraventricularEventsPacket.Summary.BeatRatio = single( round( ( 100 * supraventricularEventsPacket.Summary.BeatRatio ), 2) );
                if isnan( supraventricularEventsPacket.Summary.BeatRatio ); supraventricularEventsPacket.Summary.BeatRatio = 0; end
                supraventricularEventsPacket.Summary.TotalRuns = int32( PACRuns.TotalRuns );
                
                % PAC Isolated
                if ~isempty( PACRuns.IsolatedRun )
                    supraventricularEventsPacket.PACIsolated.IsFeatureSupported = true;
                    supraventricularEventsPacket.PACIsolated.Summary.TotalBeats = int32( length( PACRuns.IsolatedRun.StartBeat ) );
                    supraventricularEventsPacket.PACIsolated.Summary.BeatRatio = single( round( ( PACRuns.IsolatedRun.TotalRun / length( QRSComplexes.R ) ), 2 ) );
                    supraventricularEventsPacket.PACIsolated.Summary.BeatRatio = single( round( ( 100 * supraventricularEventsPacket.PACIsolated.Summary.BeatRatio ), 2) );
                    supraventricularEventsPacket.PACIsolated.Runs = GenerateClassList( PACRuns.IsolatedRun, 'PACIsolated', 'Beats');
                else
                    supraventricularEventsPacket.PACIsolated.IsFeatureSupported = true;
                    supraventricularEventsPacket.PACIsolated.Summary = string(NaN);
                    supraventricularEventsPacket.PACIsolated.Runs = string(NaN);
                end
                
                % PAC Bigeminy
                if ~isempty( PACRuns.BigeminyRun )
                    % A. IsFeatureSupported
                    supraventricularEventsPacket.PACBigeminy.IsFeatureSupported = true;
                    % Longest Run
                    longestDurationRunBeats = max( PACRuns.BigeminyRun.Duration );
                    longestDurationRunIndex = find( PACRuns.BigeminyRun.Duration == longestDurationRunBeats, 1, 'last');
                    % B. Summary
                    supraventricularEventsPacket.PACBigeminy.Summary.TotalRuns = int32( length( PACRuns.BigeminyRun.StartBeat ) );
                    supraventricularEventsPacket.PACBigeminy.Summary.LongestRunBeats = int32 ( PACRuns.BigeminyRun.Duration(longestDurationRunIndex) );
                    supraventricularEventsPacket.PACBigeminy.Summary.LongestRunStartTime = PACRuns.BigeminyRun.StartTime(longestDurationRunIndex, :);
                    supraventricularEventsPacket.PACBigeminy.Summary.LongestRunEndTime = PACRuns.BigeminyRun.EndTime(longestDurationRunIndex, :);
                    supraventricularEventsPacket.PACBigeminy.Summary.LongestRunHeartRate = PACRuns.BigeminyRun.AverageHeartRate(longestDurationRunIndex, :);
                    % C. Runs
                    supraventricularEventsPacket.PACBigeminy.Runs = GenerateClassList( PACRuns.BigeminyRun, 'PACBigeminy', 'Beats');
                else
                    supraventricularEventsPacket.PACBigeminy.IsFeatureSupported = true;
                    supraventricularEventsPacket.PACBigeminy.Summary = string(NaN);
                    supraventricularEventsPacket.PACBigeminy.Runs = string(NaN);
                end
                
                % PAC Trigeminy
                if ~isempty( PACRuns.TrigeminyRun )
                    % A. IsFeatureSupported
                    supraventricularEventsPacket.PACTrigeminy.IsFeatureSupported = true;
                    % Longest Run
                    longestDurationRunBeats = max( PACRuns.TrigeminyRun.Duration );
                    longestDurationRunIndex = find( PACRuns.TrigeminyRun.Duration == longestDurationRunBeats, 1, 'last');
                    % B. Summary
                    supraventricularEventsPacket.PACTrigeminy.Summary.TotalRuns = length( PACRuns.TrigeminyRun.StartBeat );
                    supraventricularEventsPacket.PACTrigeminy.Summary.LongestRunBeats = int32 ( PACRuns.TrigeminyRun.Duration(longestDurationRunIndex) );
                    supraventricularEventsPacket.PACTrigeminy.Summary.LongestRunStartTime = PACRuns.TrigeminyRun.StartTime(longestDurationRunIndex, :);
                    supraventricularEventsPacket.PACTrigeminy.Summary.LongestRunEndTime = PACRuns.TrigeminyRun.EndTime(longestDurationRunIndex, :);
                    supraventricularEventsPacket.PACTrigeminy.Summary.LongestRunHeartRate = PACRuns.TrigeminyRun.AverageHeartRate(longestDurationRunIndex, :);
                    % C. Runs
                    supraventricularEventsPacket.PACTrigeminy.Runs = GenerateClassList( PACRuns.TrigeminyRun, 'PACTrigeminy', 'Beats');
                else
                    supraventricularEventsPacket.PACTrigeminy.IsFeatureSupported = true;
                    supraventricularEventsPacket.PACTrigeminy.Summary = string(NaN);
                    supraventricularEventsPacket.PACTrigeminy.Runs = string(NaN);
                end
                
                % PAC Quadrigeminy
                if ~isempty( PACRuns.QuadrigeminyRun )
                    % A. IsFeatureSupported
                    supraventricularEventsPacket.PACQuadrigeminy.IsFeatureSupported = true;
                    % Longest Run
                    longestDurationRunBeats = max( PACRuns.QuadrigeminyRun.Duration );
                    longestDurationRunIndex = find( PACRuns.QuadrigeminyRun.Duration == longestDurationRunBeats, 1, 'last');
                    % B. Summary
                    supraventricularEventsPacket.PACQuadrigeminy.Summary.TotalRuns = length( PACRuns.QuadrigeminyRun.StartBeat ) ;
                    supraventricularEventsPacket.PACQuadrigeminy.Summary.LongestRunBeats = int32 ( PACRuns.QuadrigeminyRun.Duration(longestDurationRunIndex) );
                    supraventricularEventsPacket.PACQuadrigeminy.Summary.LongestRunStartTime = PACRuns.QuadrigeminyRun.StartTime(longestDurationRunIndex, :);
                    supraventricularEventsPacket.PACQuadrigeminy.Summary.LongestRunEndTime = PACRuns.QuadrigeminyRun.EndTime(longestDurationRunIndex, :);
                    supraventricularEventsPacket.PACQuadrigeminy.Summary.LongestRunHeartRate = PACRuns.QuadrigeminyRun.AverageHeartRate(longestDurationRunIndex, :);
                    % C. Runs
                    supraventricularEventsPacket.PACQuadrigeminy.Runs = GenerateClassList( PACRuns.QuadrigeminyRun, 'PACQuadrigeminy', 'Beats');
                else
                    supraventricularEventsPacket.PACQuadrigeminy.IsFeatureSupported = true;
                    supraventricularEventsPacket.PACQuadrigeminy.Summary = string(NaN);
                    supraventricularEventsPacket.PACQuadrigeminy.Runs = string(NaN);
                end
                
                % PAC Couplet
                if ~isempty( PACRuns.CoupletRun )
                    supraventricularEventsPacket.PACCouplet.IsFeatureSupported = true;
                    supraventricularEventsPacket.PACCouplet.Summary.TotalRuns = int32( length( PACRuns.CoupletRun.StartBeat ) );
                    supraventricularEventsPacket.PACCouplet.Runs = GenerateClassList( PACRuns.CoupletRun, 'PACCouplets', 'Beats');
                else
                    supraventricularEventsPacket.PACCouplet.IsFeatureSupported = true;
                    supraventricularEventsPacket.PACCouplet.Summary = string(NaN);
                    supraventricularEventsPacket.PACCouplet.Runs = string(NaN);
                end
                
                % PAC Triplet
                if ~isempty( PACRuns.TripletRun )
                    supraventricularEventsPacket.PACTriplet.IsFeatureSupported = true;
                    supraventricularEventsPacket.PACTriplet.Summary.TotalRuns = int32( length( PACRuns.TripletRun.StartBeat ) );
                    supraventricularEventsPacket.PACTriplet.Runs = GenerateClassList( PACRuns.TripletRun, 'PACTriplets', 'Beats');
                else
                    supraventricularEventsPacket.PACTriplet.IsFeatureSupported = true;
                    supraventricularEventsPacket.PACTriplet.Summary = string(NaN);
                    supraventricularEventsPacket.PACTriplet.Runs = string(NaN);
                end
                
                % PAC Salvo
                if ~isempty( PACRuns.SalvoRun )
                    % A. IsFeatureSupported
                    supraventricularEventsPacket.PACSalvo.IsFeatureSupported = true;
                    % HighestHeartRate TahcyRun
                    highestHeartRateRunAverageHeartRate = max( PACRuns.SalvoRun.AverageHeartRate );
                    highestHeartRateRunIndex = find( PACRuns.SalvoRun.AverageHeartRate == highestHeartRateRunAverageHeartRate, 1, 'last');
                    % B. Summary
                    supraventricularEventsPacket.PACSalvo.Summary.TotalRuns = length( PACRuns.SalvoRun.StartBeat ) ;
                    supraventricularEventsPacket.PACSalvo.Summary.HighestHeartRateRunBeats = int32 ( PACRuns.SalvoRun.Duration(highestHeartRateRunIndex) );
                    supraventricularEventsPacket.PACSalvo.Summary.HighestHeartRateRunStartTime = PACRuns.SalvoRun.StartTime(highestHeartRateRunIndex, :);
                    supraventricularEventsPacket.PACSalvo.Summary.HighestHeartRateRunEndTime = PACRuns.SalvoRun.EndTime(highestHeartRateRunIndex, :);
                    supraventricularEventsPacket.PACSalvo.Summary.HighestHeartRateRunHeartRate = PACRuns.SalvoRun.AverageHeartRate(highestHeartRateRunIndex, :);
                    % C. Runs
                    supraventricularEventsPacket.PACSalvo.Runs = GenerateClassList( PACRuns.SalvoRun, 'PACSalvo', 'Beats');
                else
                    supraventricularEventsPacket.PACSalvo.IsFeatureSupported = true;
                    supraventricularEventsPacket.PACSalvo.Summary = string(NaN);
                    supraventricularEventsPacket.PACSalvo.Runs = string(NaN);
                end
                
                
            else
                
                % Not supported
                supraventricularEventsPacket.Summary = string(NaN);
                supraventricularEventsPacket.PACIsolated.IsFeatureSupported = false;
                supraventricularEventsPacket.PACBigeminy.IsFeatureSupported = false;
                supraventricularEventsPacket.PACTrigeminy.IsFeatureSupported = false;
                supraventricularEventsPacket.PACQuadrigeminy.IsFeatureSupported = false;
                supraventricularEventsPacket.PACCouplet.IsFeatureSupported = false;
                supraventricularEventsPacket.PACTriplet.IsFeatureSupported = false;
                supraventricularEventsPacket.PACSalvo.IsFeatureSupported = false;
                
            end
            
        end
        
        
        %% Tachycardia Packet
        
        function tachyPacket = TachycardiaPacket( sinusTachyRuns, activityBasedHighHeartRateRuns, ventTachyRuns, supVentTachyRuns, totalBeats, generalPeriod)
            % Tachycardia Packet
            %
            % tachyPacket = TachycardiaPacket( sinusTachyRuns, ventTachyRuns, supVentTachyRuns, totalBeats, generalPeriod)
            %
            % <<< Function Inputs >>>
            %   struct sinusTachyRuns: sinus tachycardia runs info
            % - - .StartTime = start time of the runs in sample
            % - - .EndTime = end time of the runs in sample
            % - - .Duration = duration of the runs in beats
            % - - .AverageHeartRate = heart rate of the runs
            %   struct activityBasedHighHeartRateRuns:
            % - - .StartTime = start time of the runs in sample
            % - - .EndTime = end time of the runs in sample
            % - - .Duration = duration of the runs in beats
            % - - .AverageHeartRate = heart rate of the runs
            %   single ventTachyRuns: ventricular tachycardia runs info
            %   single supVentTachyRuns: supraventricular tachycardia runs info
            %   single totalBeats: total detected bpms
            %   struct generalPeriod
            %   string recordStartTime: time of the begining of the
            %
            % <<< Function Outputs >>>
            %   struct tachyPacket
            
            %% Class: SinusTachycardia
            if ~isempty(sinusTachyRuns)
                
                % IsFeatureSupported
                tachyPacket.SinusTachycardia.IsFeatureSupported = true;
                
                % Longest TahcyRun
                longestDurationRunBeats = max(sinusTachyRuns.Duration );
                longestDurationRunIndex = find(sinusTachyRuns.Duration == longestDurationRunBeats, 1, 'last');
                
                % HighestHeartRate TahcyRun
                highestHeartRateRunAverageHeartRate = max(sinusTachyRuns.AverageHeartRate);
                highestHeartRateRunIndex = find(sinusTachyRuns.AverageHeartRate == highestHeartRateRunAverageHeartRate, 1, 'last');
                
                % subClass: Summary
                % - TotalBeats
                tachyPacket.SinusTachycardia.Summary.TotalBeats = int32 ( sum( sinusTachyRuns.Duration ) );
                % - BeatRatio
                tachyPacket.SinusTachycardia.Summary.BeatRatio = single ( single( tachyPacket.SinusTachycardia.Summary.TotalBeats ) / totalBeats );
                tachyPacket.SinusTachycardia.Summary.BeatRatio = round( ( 100 * tachyPacket.SinusTachycardia.Summary.BeatRatio ), 2);
                % - TotalRuns
                tachyPacket.SinusTachycardia.Summary.TotalRuns = int32 ( numel( sinusTachyRuns.StartTime(:, 1) ) );
                % -Longest
                tachyPacket.SinusTachycardia.Summary.LongestRunBeats = int32 ( sinusTachyRuns.Duration(longestDurationRunIndex) );
                tachyPacket.SinusTachycardia.Summary.LongestRunStartTime = sinusTachyRuns.StartTime(longestDurationRunIndex, :);
                tachyPacket.SinusTachycardia.Summary.LongestRunEndTime = sinusTachyRuns.EndTime(longestDurationRunIndex, :);
                tachyPacket.SinusTachycardia.Summary.LongestRunHeartRate = sinusTachyRuns.AverageHeartRate(longestDurationRunIndex, :);
                % -HighestHeartRate
                tachyPacket.SinusTachycardia.Summary.HighestHeartRateRunBeats = int32 ( sinusTachyRuns.Duration(highestHeartRateRunIndex) );
                tachyPacket.SinusTachycardia.Summary.HighestHeartRateRunStartTime = sinusTachyRuns.StartTime(highestHeartRateRunIndex, :);
                tachyPacket.SinusTachycardia.Summary.HighestHeartRateRunEndTime = sinusTachyRuns.EndTime(highestHeartRateRunIndex, :);
                tachyPacket.SinusTachycardia.Summary.HighestHeartRateRunHeartRate = sinusTachyRuns.AverageHeartRate(highestHeartRateRunIndex, :);
                % - AverageHeartRate
                AverageHeartRate = int32 ( sum( sinusTachyRuns.Duration .* sinusTachyRuns.AverageHeartRate ) / sum( sinusTachyRuns.Duration ) );
                tachyPacket.SinusTachycardia.Summary.AverageHeartRate = AverageHeartRate;
                % - HighestHeartRate
                tachyPacket.SinusTachycardia.Summary.HighestHeartRate = int32( generalPeriod.HighestHeartRate );
                % - HighestHeartRateTime
                tachyPacket.SinusTachycardia.Summary.HighestHeartRateTime = generalPeriod.HighestHeartRateTime;
                
                % subClass: SinusTachycardiaRuns
                tachyPacket.SinusTachycardia.Runs = GenerateClassList( sinusTachyRuns, 'SinusTachycardia', 'Beats');
                
            else
                
                % IsFeatureSupported
                tachyPacket.SinusTachycardia.IsFeatureSupported = true;
                tachyPacket.SinusTachycardia.Summary = string(NaN);
                tachyPacket.SinusTachycardia.Runs = string(NaN);
                
            end
            
            
            %% Class: VentricularTachycardia
            
            %             if ~isempty( ventTachyRuns.StartBeat )
            if ~isempty( ventTachyRuns )
                
                % IsFeatureSupported
                tachyPacket.VentricularTachycardia.IsFeatureSupported = true;
                
                % Longest VentricularTachycardia
                longestDurationRunBeats = max(ventTachyRuns.Duration );
                longestDurationRunIndex = find(ventTachyRuns.Duration == longestDurationRunBeats, 1, 'last');
                
                % HighestHeartRate VentricularTachycardia
                highestHeartRateRunAverageHeartRate = max(ventTachyRuns.AverageHeartRate);
                highestHeartRateRunIndex = find(ventTachyRuns.AverageHeartRate == highestHeartRateRunAverageHeartRate, 1, 'last');
                
                % subClass: Summary
                % - TotalBeats
                tachyPacket.VentricularTachycardia.Summary.TotalBeats = int32 ( sum( ventTachyRuns.Duration ) );
                % - BeatRatio
                tachyPacket.VentricularTachycardia.Summary.BeatRatio = single ( single( tachyPacket.VentricularTachycardia.Summary.TotalBeats ) / totalBeats );
                tachyPacket.VentricularTachycardia.Summary.BeatRatio = round( ( 100 * tachyPacket.VentricularTachycardia.Summary.BeatRatio ), 2);
                % - TotalRuns
                tachyPacket.VentricularTachycardia.Summary.TotalRuns = int32 ( numel( ventTachyRuns.StartTime(:, 1) ) );
                % -Longest
                tachyPacket.VentricularTachycardia.Summary.LongestRunBeats = int32 ( ventTachyRuns.Duration(longestDurationRunIndex) );
                tachyPacket.VentricularTachycardia.Summary.LongestRunStartTime = ventTachyRuns.StartTime(longestDurationRunIndex, :);
                tachyPacket.VentricularTachycardia.Summary.LongestRunEndTime = ventTachyRuns.EndTime(longestDurationRunIndex, :);
                tachyPacket.VentricularTachycardia.Summary.LongestRunHeartRate = ventTachyRuns.AverageHeartRate(longestDurationRunIndex, :);
                % -HighestHeartRate
                tachyPacket.VentricularTachycardia.Summary.HighestHeartRateRunBeats = int32 ( ventTachyRuns.Duration(highestHeartRateRunIndex) );
                tachyPacket.VentricularTachycardia.Summary.HighestHeartRateRunStartTime = ventTachyRuns.StartTime(highestHeartRateRunIndex, :);
                tachyPacket.VentricularTachycardia.Summary.HighestHeartRateRunEndTime = ventTachyRuns.EndTime(highestHeartRateRunIndex, :);
                tachyPacket.VentricularTachycardia.Summary.HighestHeartRateRunHeartRate = ventTachyRuns.AverageHeartRate(highestHeartRateRunIndex, :);
                % - AverageHeartRate
                AverageHeartRate = int32 ( sum( ventTachyRuns.Duration .* ventTachyRuns.AverageHeartRate ) / sum( ventTachyRuns.Duration ) );
                tachyPacket.VentricularTachycardia.Summary.AverageHeartRate = AverageHeartRate;
                % - HighestHeartRate
                tachyPacket.VentricularTachycardia.Summary.HighestHeartRate = int32( generalPeriod.HighestHeartRate );
                % - HighestHeartRateTime
                tachyPacket.VentricularTachycardia.Summary.HighestHeartRateTime = generalPeriod.HighestHeartRateTime;
                
                % subClass: VentricularTachycardiaRuns
                tachyPacket.VentricularTachycardia.Runs = GenerateClassList( ventTachyRuns, 'VentricularTachycardia', 'Beats');
                
            else
                
                % IsFeatureSupported
                tachyPacket.VentricularTachycardia.IsFeatureSupported = true;
                tachyPacket.VentricularTachycardia.Summary = string(NaN);
                tachyPacket.VentricularTachycardia.Runs = string(NaN);
                
            end
            
            
            %% Class: SupraventricularTachycardia
            
            if ~isempty(supVentTachyRuns)
                % IsFeatureSupported
                tachyPacket.SupraventricularTachycardia.IsFeatureSupported = true;
                
                % Longest TahcyRun
                longestDurationRunBeats = max(supVentTachyRuns.Duration );
                longestDurationRunIndex = find(supVentTachyRuns.Duration == longestDurationRunBeats, 1, 'last');
                
                % HighestHeartRate TahcyRun
                highestHeartRateRunAverageHeartRate = max(supVentTachyRuns.AverageHeartRate);
                highestHeartRateRunIndex = find(supVentTachyRuns.AverageHeartRate == highestHeartRateRunAverageHeartRate, 1, 'last');
                
                % subClass: Summary
                % - TotalBeats
                tachyPacket.SupraventricularTachycardia.Summary.TotalBeats = int32 ( sum( supVentTachyRuns.Duration ) );
                % - BeatRatio
                tachyPacket.SupraventricularTachycardia.Summary.BeatRatio = single ( single( tachyPacket.SupraventricularTachycardia.Summary.TotalBeats ) / totalBeats );
                tachyPacket.SupraventricularTachycardia.Summary.BeatRatio = round( ( 100 * tachyPacket.SupraventricularTachycardia.Summary.BeatRatio ), 2);
                % - TotalRuns
                tachyPacket.SupraventricularTachycardia.Summary.TotalRuns = int32 ( numel( supVentTachyRuns.StartTime(:, 1) ) );
                % -Longest
                tachyPacket.SupraventricularTachycardia.Summary.LongestRunBeats = int32 ( supVentTachyRuns.Duration(longestDurationRunIndex) );
                tachyPacket.SupraventricularTachycardia.Summary.LongestRunStartTime = supVentTachyRuns.StartTime(longestDurationRunIndex, :);
                tachyPacket.SupraventricularTachycardia.Summary.LongestRunEndTime = supVentTachyRuns.EndTime(longestDurationRunIndex, :);
                tachyPacket.SupraventricularTachycardia.Summary.LongestRunHeartRate = supVentTachyRuns.AverageHeartRate(longestDurationRunIndex, :);
                % -HighestHeartRate
                tachyPacket.SupraventricularTachycardia.Summary.HighestHeartRateRunBeats = int32 ( supVentTachyRuns.Duration(highestHeartRateRunIndex) );
                tachyPacket.SupraventricularTachycardia.Summary.HighestHeartRateRunStartTime = supVentTachyRuns.StartTime(highestHeartRateRunIndex, :);
                tachyPacket.SupraventricularTachycardia.Summary.HighestHeartRateRunEndTime = supVentTachyRuns.EndTime(highestHeartRateRunIndex, :);
                tachyPacket.SupraventricularTachycardia.Summary.HighestHeartRateRunHeartRate = supVentTachyRuns.AverageHeartRate(highestHeartRateRunIndex, :);
                % - AverageHeartRate
                AverageHeartRate = int32 ( sum( supVentTachyRuns.Duration .* supVentTachyRuns.AverageHeartRate ) / sum( supVentTachyRuns.Duration ) );
                tachyPacket.SupraventricularTachycardia.Summary.AverageHeartRate = AverageHeartRate;
                % - HighestHeartRate
                tachyPacket.SupraventricularTachycardia.Summary.HighestHeartRate = int32( generalPeriod.HighestHeartRate );
                % - HighestHeartRateTime
                tachyPacket.SupraventricularTachycardia.Summary.HighestHeartRateTime = generalPeriod.HighestHeartRateTime;
                
                % subClass: SupraventricularTachycardiaRuns
                tachyPacket.SupraventricularTachycardia.Runs = GenerateClassList( supVentTachyRuns, 'SupraventricularTachycardia', 'Beats');
                
            else
                
                % IsFeatureSupported
                tachyPacket.SupraventricularTachycardia.IsFeatureSupported = true;
                tachyPacket.SupraventricularTachycardia.Summary = string(NaN);
                tachyPacket.SupraventricularTachycardia.Runs = string(NaN);
                
            end
            
            
            %% Class: ActivityBasedHighHeartRate
            
            if ~isempty(activityBasedHighHeartRateRuns)
                
                % IsFeatureSupported
                tachyPacket.ActivityBasedHighHeartRate.IsFeatureSupported = true;
                
                % Longest BradyDuration
                longestDurationRunBeats = max(activityBasedHighHeartRateRuns.Duration );
                longestDurationRunIndex = find(activityBasedHighHeartRateRuns.Duration == longestDurationRunBeats, 1, 'last');
                
                % HighestHeartRate TahcyRun
                highestHeartRateRunAverageHeartRate = max(activityBasedHighHeartRateRuns.AverageHeartRate);
                highestHeartRateRunIndex = find(activityBasedHighHeartRateRuns.AverageHeartRate == highestHeartRateRunAverageHeartRate, 1, 'last');
                
                % subClass: Summary
                % - TotalBeats
                tachyPacket.ActivityBasedHighHeartRate.Summary.TotalBeats = int32 ( sum( activityBasedHighHeartRateRuns.Duration ) );
                % - BeatRatio
                tachyPacket.ActivityBasedHighHeartRate.Summary.BeatRatio = single ( single( tachyPacket.ActivityBasedHighHeartRate.Summary.TotalBeats ) / totalBeats );
                tachyPacket.ActivityBasedHighHeartRate.Summary.BeatRatio = round( ( 100 * tachyPacket.ActivityBasedHighHeartRate.Summary.BeatRatio ), 2);
                % - TotalRuns
                tachyPacket.ActivityBasedHighHeartRate.Summary.TotalRuns = int32 ( numel( activityBasedHighHeartRateRuns.StartTime(:, 1) ) );
                % -LongestRun
                tachyPacket.ActivityBasedHighHeartRate.Summary.LongestRunBeats = int32 ( activityBasedHighHeartRateRuns.Duration(longestDurationRunIndex) );
                tachyPacket.ActivityBasedHighHeartRate.Summary.LongestRunStartTime = activityBasedHighHeartRateRuns.StartTime(longestDurationRunIndex, :);
                tachyPacket.ActivityBasedHighHeartRate.Summary.LongestRunEndTime = activityBasedHighHeartRateRuns.EndTime(longestDurationRunIndex, :);
                tachyPacket.ActivityBasedHighHeartRate.Summary.LongestRunHeartRate = activityBasedHighHeartRateRuns.AverageHeartRate(longestDurationRunIndex, :);
                % -HighestHeartRate
                tachyPacket.ActivityBasedHighHeartRate.Summary.HighestHeartRateRunBeats = int32 ( activityBasedHighHeartRateRuns.Duration(highestHeartRateRunIndex) );
                tachyPacket.ActivityBasedHighHeartRate.Summary.HighestHeartRateRunStartTime = activityBasedHighHeartRateRuns.StartTime(highestHeartRateRunIndex, :);
                tachyPacket.ActivityBasedHighHeartRate.Summary.HighestHeartRateRunEndTime = activityBasedHighHeartRateRuns.EndTime(highestHeartRateRunIndex, :);
                tachyPacket.ActivityBasedHighHeartRate.Summary.HighestHeartRateRunHeartRate = activityBasedHighHeartRateRuns.AverageHeartRate(highestHeartRateRunIndex, :);
                % - AverageHeartRate
                AverageHeartRate = int32 ( sum( activityBasedHighHeartRateRuns.Duration .* activityBasedHighHeartRateRuns.AverageHeartRate ) / sum( activityBasedHighHeartRateRuns.Duration ) );
                tachyPacket.ActivityBasedHighHeartRate.Summary.AverageHeartRate = AverageHeartRate;
                % - HighestHeartRate
                tachyPacket.ActivityBasedHighHeartRate.Summary.HighestHeartRate = int32( generalPeriod.HighestHeartRate );
                % - HighestHeartRateTime
                tachyPacket.ActivityBasedHighHeartRate.Summary.HighestHeartRateTime = generalPeriod.HighestHeartRateTime;
                
                % subClass: ActivityWithHighHeartRate
                tachyPacket.ActivityBasedHighHeartRate.Runs = GenerateClassList( activityBasedHighHeartRateRuns, 'ActivityWithHighHeartRate', 'Beats');
                
            else
                
                % IsFeatureSupported
                tachyPacket.ActivityBasedHighHeartRate.IsFeatureSupported = true;
                tachyPacket.ActivityBasedHighHeartRate.Summary = string(NaN);
                tachyPacket.ActivityBasedHighHeartRate.Runs = string(NaN);
                
            end
            
            
        end
        
        
        %% Bradycardia Packet
        
        function bradyPacket = BradycardiaPacket( bradyRuns, pauseRuns, avBlockDegreeI, avBlockDegreeII_type1, avBlockDegreeII_type2, avBlockDegreeIII, activityBasedLowHeartRateRuns, totalBeats, totalSignalDuration, generalPeriod)
            % Bradycardia Packet
            %
            % bradyPacket = BradycardiaPacket( bradyRuns, pauseRuns, totalBeats, minHeartRateInfo, recordStartTime, bradyClinicThreshold, pauseThreshold)
            %
            % <<< Function Inputs >>>
            %   struct bradyRuns: bradycardia runs info
            %   struct pauseRuns: bradycardia runs info
            %   struct avBlockDegreeI
            %   struct avBlockDegreeII_type1
            %   struct avBlockDegreeII_type2
            %   struct avBlockDegreeIII
            %   struct activityBasedLowHeartRateRuns
            %   single totalBeats: total detected bpms
            %   struct generalPeriod
            %   string recordStartTime: time of the begining of the
            %   single bradyClinicThreshold: clinic bradycardia threshold
            %   single pauseThreshold: clinic pause threshold
            %
            % <<< Function Outputs >>>
            %   struct bradyPacket
            
            %% Class: SinusBradycardia
            if ~isempty(bradyRuns)
                
                % IsFeatureSupported
                bradyPacket.SinusBradycardia.IsFeatureSupported = true;
                
                % Longest BradyDuration
                longestDurationRunBeats = max(bradyRuns.Duration );
                longestDurationRunIndex = find(bradyRuns.Duration == longestDurationRunBeats, 1, 'last');
                
                % HighestHeartRate TahcyRun
                lowestHeartRateRunAverageHeartRate = min(bradyRuns.AverageHeartRate);
                lowestHeartRateRunIndex = find(bradyRuns.AverageHeartRate == lowestHeartRateRunAverageHeartRate, 1, 'last');
                
                % subClass: Summary
                % - TotalBeats
                bradyPacket.SinusBradycardia.Summary.TotalBeats = int32 ( sum( bradyRuns.Duration ) );
                % - BeatRatio
                bradyPacket.SinusBradycardia.Summary.BeatRatio = single ( single( bradyPacket.SinusBradycardia.Summary.TotalBeats ) / totalBeats );
                bradyPacket.SinusBradycardia.Summary.BeatRatio = round( ( 100 * bradyPacket.SinusBradycardia.Summary.BeatRatio ), 2);
                % - TotalRuns
                bradyPacket.SinusBradycardia.Summary.TotalRuns = int32 ( numel( bradyRuns.StartTime(:, 1) ) );
                % -LongestRun
                bradyPacket.SinusBradycardia.Summary.LongestRunBeats = int32 ( bradyRuns.Duration(longestDurationRunIndex) );
                bradyPacket.SinusBradycardia.Summary.LongestRunStartTime = bradyRuns.StartTime(longestDurationRunIndex, :);
                bradyPacket.SinusBradycardia.Summary.LongestRunEndTime = bradyRuns.EndTime(longestDurationRunIndex, :);
                bradyPacket.SinusBradycardia.Summary.LongestRunHeartRate = bradyRuns.AverageHeartRate(longestDurationRunIndex, :);
                % -LowestHeartRate
                bradyPacket.SinusBradycardia.Summary.LowestHeartRateRunBeats = int32 ( bradyRuns.Duration(lowestHeartRateRunIndex) );
                bradyPacket.SinusBradycardia.Summary.LowestHeartRateRunStartTime = bradyRuns.StartTime(lowestHeartRateRunIndex, :);
                bradyPacket.SinusBradycardia.Summary.LowestHeartRateRunEndTime = bradyRuns.EndTime(lowestHeartRateRunIndex, :);
                bradyPacket.SinusBradycardia.Summary.LowestHeartRateRunHeartRate = bradyRuns.AverageHeartRate(lowestHeartRateRunIndex, :);
                % - AverageHeartRate
                AverageHeartRate = int32 ( sum( bradyRuns.Duration .* bradyRuns.AverageHeartRate ) / sum( bradyRuns.Duration ) );
                bradyPacket.SinusBradycardia.Summary.AverageHeartRate = AverageHeartRate;
                % - HighestHeartRate
                bradyPacket.SinusBradycardia.Summary.LowestHeartRate = int32( generalPeriod.LowestHeartRate );
                % - HighestHeartRateTime
                bradyPacket.SinusBradycardia.Summary.LowestHeartRateTime = generalPeriod.LowestHeartRateTime;
                
                % subClass: SinusBradycardia
                bradyPacket.SinusBradycardia.Runs = GenerateClassList( bradyRuns, 'SinusBradycardia', 'Beats');
                
            else
                
                % IsFeatureSupported
                bradyPacket.SinusBradycardia.IsFeatureSupported = true;
                bradyPacket.SinusBradycardia.Summary = string(NaN);
                bradyPacket.SinusBradycardia.Runs = string(NaN);
                
                
            end
            
            %% Class: Pause
            if ~isempty(pauseRuns)
                
                % IsFeatureSupported
                bradyPacket.Pause.IsFeatureSupported = true;
                
                % Longest Pause
                longestDurationRunBeats = max(pauseRuns.Duration );
                longestDurationRunIndex = find(pauseRuns.Duration == longestDurationRunBeats, 1, 'last');
                
                % subClass: Summary
                %
                bradyPacket.Pause.Summary.TotalDuration = ClassTypeConversion.ConvertMiliseconds2String( sum(pauseRuns.Duration) );
                %
                bradyPacket.Pause.Summary.DurationRatio = single( sum( pauseRuns.Duration ) * 0.001 / totalSignalDuration );
                bradyPacket.Pause.Summary.DurationRatio = round( 100 * bradyPacket.Pause.Summary.DurationRatio, 2 );
                %
                bradyPacket.Pause.Summary.TotalRuns = int32 ( numel( pauseRuns.StartTime(:,1) ) );
                %
                bradyPacket.Pause.Summary.LongestRunDuration =  ClassTypeConversion.ConvertMiliseconds2String( pauseRuns.Duration( longestDurationRunIndex ) );
                %
                bradyPacket.Pause.Summary.LongestRunStartTime = pauseRuns.StartTime( longestDurationRunIndex, : );
                %
                bradyPacket.Pause.Summary.LongestRunEndTime = pauseRuns.EndTime( longestDurationRunIndex, : );
                %
                bradyPacket.Pause.Summary.LongestRunHeartRate = pauseRuns.AverageHeartRate( longestDurationRunIndex, : );
                
                % subClass: PauseRuns
                bradyPacket.Pause.Runs = GenerateClassList( pauseRuns, 'Pause', 'Time');
                
            else
                
                % IsFeatureSupported
                bradyPacket.Pause.IsFeatureSupported = true;
                bradyPacket.Pause.Summary = string(NaN);
                bradyPacket.Pause.Runs = string(NaN);
                
                
            end % if isempty(pauseRuns)
            
            %% Class: AV Block I
            
            if ~isempty(avBlockDegreeI)
                
                % IsFeatureSupported
                bradyPacket.AVBlockDegreeI.IsFeatureSupported = true;
                
                % Longest BradyDuration
                longestDurationRunBeats = max(avBlockDegreeI.Duration );
                longestDurationRunIndex = find(avBlockDegreeI.Duration == longestDurationRunBeats, 1, 'last');
                
                % HighestHeartRate TahcyRun
                lowestHeartRateRunAverageHeartRate = min(avBlockDegreeI.AverageHeartRate);
                lowestHeartRateRunIndex = find(avBlockDegreeI.AverageHeartRate == lowestHeartRateRunAverageHeartRate, 1, 'last');
                
                % subClass: Summary
                % - TotalBeats
                bradyPacket.AVBlockDegreeI.Summary.TotalBeats = int32 ( sum( avBlockDegreeI.Duration ) );
                % - BeatRatio
                bradyPacket.AVBlockDegreeI.Summary.BeatRatio = single ( single( bradyPacket.AVBlockDegreeI.Summary.TotalBeats ) / totalBeats );
                bradyPacket.AVBlockDegreeI.Summary.BeatRatio = round( ( 100 * bradyPacket.AVBlockDegreeI.Summary.BeatRatio ), 2);
                % - TotalRuns
                bradyPacket.AVBlockDegreeI.Summary.TotalRuns = int32 ( numel( avBlockDegreeI.StartTime(:, 1) ) );
                % -LongestRun
                bradyPacket.AVBlockDegreeI.Summary.LongestRunBeats = int32 ( avBlockDegreeI.Duration(longestDurationRunIndex) );
                bradyPacket.AVBlockDegreeI.Summary.LongestRunStartTime = avBlockDegreeI.StartTime(longestDurationRunIndex, :);
                bradyPacket.AVBlockDegreeI.Summary.LongestRunEndTime = avBlockDegreeI.EndTime(longestDurationRunIndex, :);
                bradyPacket.AVBlockDegreeI.Summary.LongestRunHeartRate = avBlockDegreeI.AverageHeartRate(longestDurationRunIndex, :);
                % -LowestHeartRate
                bradyPacket.AVBlockDegreeI.Summary.LowestHeartRateRunBeats = int32 ( avBlockDegreeI.Duration(lowestHeartRateRunIndex) );
                bradyPacket.AVBlockDegreeI.Summary.LowestHeartRateRunStartTime = avBlockDegreeI.StartTime(lowestHeartRateRunIndex, :);
                bradyPacket.AVBlockDegreeI.Summary.LowestHeartRateRunEndTime = avBlockDegreeI.EndTime(lowestHeartRateRunIndex, :);
                bradyPacket.AVBlockDegreeI.Summary.LowestHeartRateRunHeartRate = avBlockDegreeI.AverageHeartRate(lowestHeartRateRunIndex, :);
                
                % subClass: AVBlockDegreeIII
                bradyPacket.AVBlockDegreeI.Runs = GenerateClassList( avBlockDegreeI, 'AVBlockDegreeI', 'Beats');
                
            else
                
                % IsFeatureSupported
                bradyPacket.AVBlockDegreeI.IsFeatureSupported = true;
                bradyPacket.AVBlockDegreeI.Summary = string(NaN);
                bradyPacket.AVBlockDegreeI.Runs = string(NaN);
                
                
            end
            
            %% Class: AV Block II Type 1
            
            if ~isempty(avBlockDegreeII_type1)
                % Under development
                
                % IsFeatureSupported
                bradyPacket.AVBlockDegreeII_Type1.IsFeatureSupported = true;
                
                % Longest BradyDuration
                longestDurationRunBeats = max( avBlockDegreeII_type1.Duration );
                longestDurationRunIndex = find( avBlockDegreeII_type1.Duration == longestDurationRunBeats, 1, 'last');
                
                % HighestHeartRate TahcyRun
                lowestHeartRateRunAverageHeartRate = min( avBlockDegreeII_type1.AverageHeartRate );
                lowestHeartRateRunIndex = find( avBlockDegreeII_type1.AverageHeartRate == lowestHeartRateRunAverageHeartRate, 1, 'last');
                
                % subClass: Summary
                % - TotalBeats
                bradyPacket.AVBlockDegreeII_Type1.Summary.TotalBeats = int32 ( sum( avBlockDegreeII_type1.Duration ) );
                % - BeatRatio
                bradyPacket.AVBlockDegreeII_Type1.Summary.BeatRatio = single ( single( bradyPacket.AVBlockDegreeII_Type1.Summary.TotalBeats ) / totalBeats );
                bradyPacket.AVBlockDegreeII_Type1.Summary.BeatRatio = round( ( 100 * bradyPacket.AVBlockDegreeII_Type1.Summary.BeatRatio ), 2);
                % - TotalRuns
                bradyPacket.AVBlockDegreeII_Type1.Summary.TotalRuns = int32 ( numel( avBlockDegreeII_type1.StartTime(:, 1) ) );
                % -LongestRun
                bradyPacket.AVBlockDegreeII_Type1.Summary.LongestRunBeats = int32 ( avBlockDegreeII_type1.Duration(longestDurationRunIndex) );
                bradyPacket.AVBlockDegreeII_Type1.Summary.LongestRunStartTime = avBlockDegreeII_type1.StartTime(longestDurationRunIndex, :);
                bradyPacket.AVBlockDegreeII_Type1.Summary.LongestRunEndTime = avBlockDegreeII_type1.EndTime(longestDurationRunIndex, :);
                bradyPacket.AVBlockDegreeII_Type1.Summary.LongestRunHeartRate = avBlockDegreeII_type1.AverageHeartRate(longestDurationRunIndex, :);
                % -LowestHeartRate
                bradyPacket.AVBlockDegreeII_Type1.Summary.LowestHeartRateRunBeats = int32 ( avBlockDegreeII_type1.Duration(lowestHeartRateRunIndex) );
                bradyPacket.AVBlockDegreeII_Type1.Summary.LowestHeartRateRunStartTime = avBlockDegreeII_type1.StartTime(lowestHeartRateRunIndex, :);
                bradyPacket.AVBlockDegreeII_Type1.Summary.LowestHeartRateRunEndTime = avBlockDegreeII_type1.EndTime(lowestHeartRateRunIndex, :);
                bradyPacket.AVBlockDegreeII_Type1.Summary.LowestHeartRateRunHeartRate = avBlockDegreeII_type1.AverageHeartRate(lowestHeartRateRunIndex, :);
                
                % subClass: AVBlockDegreeIII
                bradyPacket.AVBlockDegreeII_Type1.Runs = GenerateClassList( avBlockDegreeII_type1, 'AVBlockDegreeII_Type1', 'Beats');
                
            else
                
                % IsFeatureSupported
                bradyPacket.AVBlockDegreeII_Type1.IsFeatureSupported = true;
                bradyPacket.AVBlockDegreeII_Type1.Summary = string(NaN);
                bradyPacket.AVBlockDegreeII_Type1.Runs = string(NaN);
                
            end
            
            %% Class: AV Block II Type 2
            if ~isempty(avBlockDegreeII_type2)

                % IsFeatureSupported
                bradyPacket.AVBlockDegreeII_Type2.IsFeatureSupported = true;
                
                % Longest BradyDuration
                longestDurationRunBeats = max( avBlockDegreeII_type2.Duration );
                longestDurationRunIndex = find( avBlockDegreeII_type2.Duration == longestDurationRunBeats, 1, 'last');
                
                % HighestHeartRate TahcyRun
                lowestHeartRateRunAverageHeartRate = min( avBlockDegreeII_type2.AverageHeartRate );
                lowestHeartRateRunIndex = find( avBlockDegreeII_type2.AverageHeartRate == lowestHeartRateRunAverageHeartRate, 1, 'last');
                
                % subClass: Summary
                % - TotalBeats
                bradyPacket.AVBlockDegreeII_Type2.Summary.TotalBeats = int32 ( sum( avBlockDegreeII_type2.Duration ) );
                % - BeatRatio
                bradyPacket.AVBlockDegreeII_Type2.Summary.BeatRatio = single ( single( bradyPacket.AVBlockDegreeII_Type2.Summary.TotalBeats ) / totalBeats );
                bradyPacket.AVBlockDegreeII_Type2.Summary.BeatRatio = round( ( 100 * bradyPacket.AVBlockDegreeII_Type2.Summary.BeatRatio ), 2);
                % - TotalRuns
                bradyPacket.AVBlockDegreeII_Type2.Summary.TotalRuns = int32 ( numel( avBlockDegreeII_type2.StartTime(:, 1) ) );
                % -LongestRun
                bradyPacket.AVBlockDegreeII_Type2.Summary.LongestRunBeats = int32 ( avBlockDegreeII_type2.Duration(longestDurationRunIndex) );
                bradyPacket.AVBlockDegreeII_Type2.Summary.LongestRunStartTime = avBlockDegreeII_type2.StartTime(longestDurationRunIndex, :);
                bradyPacket.AVBlockDegreeII_Type2.Summary.LongestRunEndTime = avBlockDegreeII_type2.EndTime(longestDurationRunIndex, :);
                bradyPacket.AVBlockDegreeII_Type2.Summary.LongestRunHeartRate = avBlockDegreeII_type2.AverageHeartRate(longestDurationRunIndex, :);
                % -LowestHeartRate
                bradyPacket.AVBlockDegreeII_Type2.Summary.LowestHeartRateRunBeats = int32 ( avBlockDegreeII_type2.Duration(lowestHeartRateRunIndex) );
                bradyPacket.AVBlockDegreeII_Type2.Summary.LowestHeartRateRunStartTime = avBlockDegreeII_type2.StartTime(lowestHeartRateRunIndex, :);
                bradyPacket.AVBlockDegreeII_Type2.Summary.LowestHeartRateRunEndTime = avBlockDegreeII_type2.EndTime(lowestHeartRateRunIndex, :);
                bradyPacket.AVBlockDegreeII_Type2.Summary.LowestHeartRateRunHeartRate = avBlockDegreeII_type2.AverageHeartRate(lowestHeartRateRunIndex, :);
                
                % subClass: AVBlockDegreeIII
                bradyPacket.AVBlockDegreeII_Type2.Runs = GenerateClassList( avBlockDegreeII_type2, 'AVBlockDegreeII_Type2', 'Beats');
                
            else
                
                % IsFeatureSupported
                bradyPacket.AVBlockDegreeII_Type2.IsFeatureSupported = true;
                bradyPacket.AVBlockDegreeII_Type2.Summary = string(NaN);
                bradyPacket.AVBlockDegreeII_Type2.Runs = string(NaN);
                
            end
            
            %% Class: AV Block III
            if ~isempty(avBlockDegreeIII)
                
                % IsFeatureSupported
                bradyPacket.AVBlockDegreeIII.IsFeatureSupported = true;
                
                % Longest BradyDuration
                longestDurationRunBeats = max(avBlockDegreeIII.Duration );
                longestDurationRunIndex = find(avBlockDegreeIII.Duration == longestDurationRunBeats, 1, 'last');
                
                % HighestHeartRate TahcyRun
                lowestHeartRateRunAverageHeartRate = min(avBlockDegreeIII.AverageHeartRate);
                lowestHeartRateRunIndex = find(avBlockDegreeIII.AverageHeartRate == lowestHeartRateRunAverageHeartRate, 1, 'last');
                
                % subClass: Summary
                % - TotalBeats
                bradyPacket.AVBlockDegreeIII.Summary.TotalBeats = int32 ( sum( avBlockDegreeIII.Duration ) );
                % - BeatRatio
                bradyPacket.AVBlockDegreeIII.Summary.BeatRatio = single ( single( bradyPacket.AVBlockDegreeIII.Summary.TotalBeats ) / totalBeats );
                bradyPacket.AVBlockDegreeIII.Summary.BeatRatio = round( ( 100 * bradyPacket.AVBlockDegreeIII.Summary.BeatRatio ), 2);
                % - TotalRuns
                bradyPacket.AVBlockDegreeIII.Summary.TotalRuns = int32 ( numel( avBlockDegreeIII.StartTime(:, 1) ) );
                % -LongestRun
                bradyPacket.AVBlockDegreeIII.Summary.LongestRunBeats = int32 ( avBlockDegreeIII.Duration(longestDurationRunIndex) );
                bradyPacket.AVBlockDegreeIII.Summary.LongestRunStartTime = avBlockDegreeIII.StartTime(longestDurationRunIndex, :);
                bradyPacket.AVBlockDegreeIII.Summary.LongestRunEndTime = avBlockDegreeIII.EndTime(longestDurationRunIndex, :);
                bradyPacket.AVBlockDegreeIII.Summary.LongestRunHeartRate = avBlockDegreeIII.AverageHeartRate(longestDurationRunIndex, :);
                % -LowestHeartRate
                bradyPacket.AVBlockDegreeIII.Summary.LowestHeartRateRunBeats = int32 ( avBlockDegreeIII.Duration(lowestHeartRateRunIndex) );
                bradyPacket.AVBlockDegreeIII.Summary.LowestHeartRateRunStartTime = avBlockDegreeIII.StartTime(lowestHeartRateRunIndex, :);
                bradyPacket.AVBlockDegreeIII.Summary.LowestHeartRateRunEndTime = avBlockDegreeIII.EndTime(lowestHeartRateRunIndex, :);
                bradyPacket.AVBlockDegreeIII.Summary.LowestHeartRateRunHeartRate = avBlockDegreeIII.AverageHeartRate(lowestHeartRateRunIndex, :);
                
                % subClass: AVBlockDegreeIII
                bradyPacket.AVBlockDegreeIII.Runs = GenerateClassList( avBlockDegreeIII, 'AVBlockDegreeIII', 'Beats');
                
            else
                
                % IsFeatureSupported
                bradyPacket.AVBlockDegreeIII.IsFeatureSupported = true;
                bradyPacket.AVBlockDegreeIII.Summary = string(NaN);
                bradyPacket.AVBlockDegreeIII.Runs = string(NaN);
                
                
            end
            
            %% Class: Activity Based Low Heart Rate Runs
            if ~isempty(activityBasedLowHeartRateRuns)
                % Under development
                
            else
                
                % IsFeatureSupported
                bradyPacket.ActivityBasedLowHeartRate.IsFeatureSupported = true;
                bradyPacket.ActivityBasedLowHeartRate.Summary = string(NaN);
                bradyPacket.ActivityBasedLowHeartRate.Runs = string(NaN);
                
            end
            
        end % function bradyPacket = BradycardiaPacket( recordStartTime, heartRate, bradyRuns, bradyClinicThreshold)
        
        
        %% Atrial Fibrilation Packet
        
        function atrialFibPacket = AtrialFibPacket( AFibRun, totalBeats )
            % Atrial Fibrilation Packet
            %
            % atrialFibPacket = AtrialFibPacket( AFibRun, totalBeats )
            %
            % <<< Function Inputs >>>
            %   struct AFibRun
            %   single totalBeats
            %
            % <<< Function Outputs >>>
            %   struct atrialFibPacket
            
            % Class: itself
            if ~isempty( AFibRun )
                
                % IsFeatureSupported
                atrialFibPacket.IsFeatureSupported = true;
                
                % Longest Run
                longestDurationRunBeats = max(AFibRun.Duration );
                longestDurationRunIndex = find(AFibRun.Duration == longestDurationRunBeats, 1, 'last');
                
                % subClass: Summary
                % - TotalBeats
                atrialFibPacket.Summary.TotalBeats = int32 ( sum( AFibRun.Duration ) );
                % - BeatRatio
                atrialFibPacket.Summary.BeatRatio = single ( single( atrialFibPacket.Summary.TotalBeats ) / totalBeats );
                atrialFibPacket.Summary.BeatRatio = round( ( 100 * atrialFibPacket.Summary.BeatRatio ), 2);
                % - TotalRuns
                atrialFibPacket.Summary.TotalRuns = int32 ( numel( AFibRun.StartTime(:, 1) ) );
                % -Longest
                atrialFibPacket.Summary.LongestRunBeats = int32 ( AFibRun.Duration(longestDurationRunIndex) );
                atrialFibPacket.Summary.LongestRunStartTime = AFibRun.StartTime(longestDurationRunIndex, :);
                atrialFibPacket.Summary.LongestRunEndTime = AFibRun.EndTime(longestDurationRunIndex, :);
                atrialFibPacket.Summary.LongestRunHeartRate = AFibRun.AverageHeartRate(longestDurationRunIndex, :);
                
                % subClass: Atrial Fibrillation Runs
                atrialFibPacket.Runs = GenerateClassList( AFibRun, 'AtrialFib', 'Beats');
                
            else
                
                % IsFeatureSupported
                atrialFibPacket.IsFeatureSupported = true;
                atrialFibPacket.Summary = string(NaN);
                atrialFibPacket.Runs = string(NaN);
                
            end
            
        end
        
        
        %% Atrial Flutter Packet
        
        function atrialFlutterPacket = AtrialFlutterPacket( initialValue )
            % Atrial Flutter Packet
            %
            % hrvPacket = HRVariablityPacket( initialValue )
            %
            % <<< Function Inputs >>>
            %   single initialValue
            %
            % <<< Function Outputs >>>
            %   struct atrialFlutterPacket
            
            % Class: itself
            if ~isempty( initialValue )
                % Under development
                
            else
                
                % IsFeatureSupported
                atrialFlutterPacket.IsFeatureSupported = true;
                atrialFlutterPacket.Summary = string(NaN);
                atrialFlutterPacket.Runs = string(NaN);
                
            end
            
        end
        
        
        %% Ventricular Fibrilation Packet
        
        function ventricularFibPacket = VentricularFibPacket( VFibRun, totalSignalDuration )
            % Ventricular Fibrilation Packet
            %
            % ventricularFibPacket = VentricularFibPacket( VFibRun )
            %
            % <<< Function Inputs >>>
            %   struct VFibRun
            %   single totalSignalDuration
            %
            % <<< Function Outputs >>>
            %   struct ventricularFibPacket
            
            % Class: itself
            if ~isempty( VFibRun )
                
                % IsFeatureSupported
                ventricularFibPacket.IsFeatureSupported = true;
                
                % Longest Run
                longestDurationRunBeats = max( VFibRun.Duration );
                longestDurationRunIndex = find( VFibRun.Duration == longestDurationRunBeats, 1, 'last');
                
                % subClass: Summary
                %
                ventricularFibPacket.Summary.TotalDuration = ClassTypeConversion.ConvertMiliseconds2String( sum( VFibRun.Duration ) );
                %
                ventricularFibPacket.Summary.DurationRatio = single( sum( VFibRun.Duration ) * 0.001 / totalSignalDuration );
                ventricularFibPacket.Summary.DurationRatio = round( 100 * ventricularFibPacket.Summary.DurationRatio, 2 );
                %
                ventricularFibPacket.Summary.TotalRuns = int32( numel( VFibRun.StartTime(:,1) ) );
                %
                ventricularFibPacket.Summary.LongestRunDuration =  ClassTypeConversion.ConvertMiliseconds2String( VFibRun.Duration( longestDurationRunIndex ) );
                %
                ventricularFibPacket.Summary.LongestRunStartTime = VFibRun.StartTime( longestDurationRunIndex, : );
                %
                ventricularFibPacket.Summary.LongestRunEndTime = VFibRun.EndTime( longestDurationRunIndex, : );
                %
                ventricularFibPacket.Summary.LongestRunHeartRate = VFibRun.AverageHeartRate( longestDurationRunIndex, : );
                
                % subClass: AsystoleRuns
                ventricularFibPacket.Runs = GenerateClassList( VFibRun, 'VentricularFib', 'Time');
                
                
            else
                
                % IsFeatureSupported
                ventricularFibPacket.IsFeatureSupported = true;
                ventricularFibPacket.Summary = string(NaN);
                ventricularFibPacket.Runs = string(NaN);
                
            end
            
            
        end
        
        
        %% Ventricular Flutter Packet
        
        function ventricularFlutterPacket = VentricularFlutterPacket( VFlutRuns, TotalBeats )
            % Ventricular Flutter Packet
            %
            % ventricularFlutterPacket = VentricularFlutterPacket( VFlutRuns, TotalBeats )
            %
            % <<< Function Inputs >>>
            %   struct VFlutRuns
            %   single TotalBeats
            %
            % <<< Function Outputs >>>
            %   struct ventricularFlutterPacket
            
            if ~isempty(VFlutRuns)
                
                % IsFeatureSupported
                ventricularFlutterPacket.IsFeatureSupported = true;
                
                % Longest TahcyRun
                longestDurationRunBeats = max(VFlutRuns.Duration );
                longestDurationRunIndex = find(VFlutRuns.Duration == longestDurationRunBeats, 1, 'last');
                
                % subClass: Summary
                % - TotalBeats
                ventricularFlutterPacket.Summary.TotalBeats = int32 ( sum( VFlutRuns.Duration ) );
                % - BeatRatio
                ventricularFlutterPacket.Summary.BeatRatio = single ( single( ventricularFlutterPacket.Summary.TotalBeats ) / TotalBeats );
                ventricularFlutterPacket.Summary.BeatRatio = round( ( 100 * ventricularFlutterPacket.Summary.BeatRatio ), 2);
                % - TotalRuns
                ventricularFlutterPacket.Summary.TotalRuns = int32 ( numel( VFlutRuns.StartTime(:, 1) ) );
                % -Longest
                ventricularFlutterPacket.Summary.LongestRunBeats = int32 ( VFlutRuns.Duration(longestDurationRunIndex) );
                ventricularFlutterPacket.Summary.LongestRunStartTime = VFlutRuns.StartTime(longestDurationRunIndex, :);
                ventricularFlutterPacket.Summary.LongestRunEndTime = VFlutRuns.EndTime(longestDurationRunIndex, :);
                ventricularFlutterPacket.Summary.LongestRunHeartRate = VFlutRuns.AverageHeartRate(longestDurationRunIndex, :);
                % - AverageHeartRate
                AverageHeartRate = int32 ( sum( VFlutRuns.Duration .* VFlutRuns.AverageHeartRate ) / sum( VFlutRuns.Duration ) );
                ventricularFlutterPacket.Summary.AverageHeartRate = AverageHeartRate;
                
                % subClass: SinusTachycardiaRuns
                ventricularFlutterPacket.Runs = GenerateClassList( VFlutRuns, 'VentricularFlutter', 'Beats');
                
            else
                
                % IsFeatureSupported
                ventricularFlutterPacket.IsFeatureSupported = true;
                ventricularFlutterPacket.Summary = string(NaN);
                ventricularFlutterPacket.Runs = string(NaN);
                
            end
            
        end
        
        
        %% Asystole Packet
        
        function asystolePacket = AsystolePacket( asystoleRuns, totalSignalDuration )
            % Asystole Packet
            %
            % asystolePacket = AsystolePacket( initialValue )
            %
            % <<< Function Inputs >>>
            %   single initialValue
            %
            % <<< Function Outputs >>>
            %   struct asystolePacket
            
            % Class: Asystole
            if ~isempty( asystoleRuns)
                
                % IsFeatureSupported
                asystolePacket.IsFeatureSupported = true;
                
                % Longest BradyDuration
                longestDurationRunBeats = max( asystoleRuns.Duration );
                longestDurationRunIndex = find( asystoleRuns.Duration == longestDurationRunBeats, 1, 'last');
                
                % subClass: Summary
                %
                asystolePacket.Summary.TotalDuration = ClassTypeConversion.ConvertMiliseconds2String( sum(asystoleRuns.Duration) );
                %
                asystolePacket.Summary.DurationRatio = single( sum( asystoleRuns.Duration ) * 0.001 / totalSignalDuration );
                asystolePacket.Summary.DurationRatio = round( 100 * asystolePacket.Summary.DurationRatio, 2 );
                %
                asystolePacket.Summary.TotalRuns = int32( numel( asystoleRuns.StartTime(:,1) ) );
                %
                asystolePacket.Summary.LongestRunDuration =  ClassTypeConversion.ConvertMiliseconds2String( asystoleRuns.Duration( longestDurationRunIndex ) );
                %
                asystolePacket.Summary.LongestRunStartTime = asystoleRuns.StartTime( longestDurationRunIndex, : );
                %
                asystolePacket.Summary.LongestRunEndTime = asystoleRuns.EndTime( longestDurationRunIndex, : );
                %
                asystolePacket.Summary.LongestRunHeartRate = asystoleRuns.AverageHeartRate( longestDurationRunIndex, : );
                
                % subClass: AsystoleRuns
                asystolePacket.Runs = GenerateClassList( asystoleRuns, 'Asystole', 'Time');
                
            else
                
                % IsFeatureSupported
                asystolePacket.IsFeatureSupported = true;
                asystolePacket.Summary = string(NaN);
                asystolePacket.Runs = string(NaN);
                
            end
            
        end
        
        
        %% Alarm Button Packet
        
        function alarmButtonPacket = AlarmButtonPacket( alarmRuns, qrsComplexes, recordInfo )
            % Asystole Packet
            %
            % asystolePacket = AsystolePacket( initialValue )
            %
            % <<< Function Inputs >>>
            %   single initialValue
            %
            % <<< Function Outputs >>>
            %   struct asystolePacket
            
            
            % Class: Alarm Button
            if ~isempty( alarmRuns)
                
                % Heart rate
                HeartRate = ClassRhythmAnalysis.CalculateHeartRate( qrsComplexes.R, recordInfo.RecordSamplingFrequency );
                HeartRate = [ 0; HeartRate ];
                for runIndex = 1 : length( alarmRuns.StartPoint )
                    runPoints = alarmRuns.StartPoint( runIndex ) : alarmRuns.EndPoint( runIndex );
                    [ ~, ~, runBeats ] = intersect( runPoints, qrsComplexes.R );
                    if ~isempty( runBeats )
                        alarmRuns.Duration( runIndex ) = length( runBeats );
                        alarmRuns.AverageHeartRate( runIndex ) =round( mean( HeartRate( runBeats ) ) );
                    end
                end
                % IsFeatureSupported
                alarmButtonPacket.IsFeatureSupported = true;
                
                % Summary. TotalRuns
                alarmButtonPacket.Summary.TotalRuns = int32( length( alarmRuns.StartTime ) );
                
                % Runs
                alarmButtonPacket.Runs = GenerateClassList( alarmRuns, 'AlarmButton', 'Beats' );
                
            else
                
                alarmButtonPacket.IsFeatureSupported = true;
                alarmButtonPacket.Summary = string(NaN);
                alarmButtonPacket.Runs = string(NaN);
                
            end
            
        end
        
        
        %% Noise Packet
        
        function noisePacket = NoisePacket( noiseRuns, totalSignalDuration )
            % Noise Packet
            %
            % noisePacket = NoisePacket( noiseRuns, totalSignalDuration )
            %
            % <<< Function Inputs >>>
            %   struct noiseRuns
            %   single totalSignalDuration
            %
            % <<< Function Outputs >>>
            %   struct noisePacket
            
            % Class: Asystole
            if ~isempty( noiseRuns)
                
                % IsFeatureSupported
                noisePacket.IsFeatureSupported = true;
                
                % Longest BradyDuration
                longestDurationRunBeats = max( noiseRuns.Duration );
                longestDurationRunIndex = find( noiseRuns.Duration == longestDurationRunBeats, 1, 'last');
                
                % subClass: Summary
                %
                noisePacket.Summary.TotalDuration = ClassTypeConversion.ConvertMiliseconds2String( sum(noiseRuns.Duration) );
                %
                noisePacket.Summary.DurationRatio = single( sum( noiseRuns.Duration ) * 0.001 / totalSignalDuration );
                noisePacket.Summary.DurationRatio = round( 100 * noisePacket.Summary.DurationRatio, 2 );
                %
                noisePacket.Summary.TotalRuns = int32( numel( noiseRuns.StartTime(:,1) ) );
                %
                noisePacket.Summary.LongestRunDuration =  ClassTypeConversion.ConvertMiliseconds2String( noiseRuns.Duration( longestDurationRunIndex ) );
                %
                noisePacket.Summary.LongestRunStartTime = noiseRuns.StartTime( longestDurationRunIndex, : );
                %
                noisePacket.Summary.LongestRunEndTime = noiseRuns.EndTime( longestDurationRunIndex, : );
                %
                noisePacket.Summary.LongestRunHeartRate = noiseRuns.AverageHeartRate( longestDurationRunIndex, : );
                
                % subClass: AsystoleRuns
                noisePacket.Runs = GenerateClassList( noiseRuns, 'Noise', 'Time');
                
            else
                
                % IsFeatureSupported
                noisePacket.IsFeatureSupported = true;
                noisePacket.Summary = string(NaN);
                noisePacket.Runs = string(NaN);
                
            end
            
        end
        
        
        %% Beat Details Packet
        %  Beat Details Packet
        %
        % beatDetailsPacket = BeatDetailsPacket( qrsComplexes, samplingFreq )
        %
        % <<< Function Inputs >>>
        %   struct qrsComplexes
        %   single samplingFreq
        %
        % <<< Function Outputs >>>
        %   struct beatDetailsPacket
        
        function beatDetailsPacket = BeatDetailsPacket( qrsComplexes, samplingFreq,similarity )
            
            % Beat Details
            beatDetailsPacket.BeatDetails = BeatClassification( qrsComplexes, samplingFreq,similarity );
            
            %  Beat Classification Details
            beatDetailsPacket.BeatForms = BeatForm( qrsComplexes );
            
            % Intervals
            if ~isempty( qrsComplexes.R )
                temp = BeatInterval( qrsComplexes );
                beatDetailsPacket.IntervalMeanValues = temp.MeanValues;
            else
                beatDetailsPacket.IntervalMeanValues = string( nan );
            end
            
        end
        
        %% Pace Maker Packet
        %
        function paceMakerPacket =PaceMakerPacket( pace,SignalNoisePoints )
           if ~isempty( pace )
              for i=1:length(pace)
                 if SignalNoisePoints(pace(i)) ==1
                   pace(i)=0;
                 end
              end
               pace(pace==0) = [];
                paceMakerPacket.Pace=pace;
                paceMakerPacket.Pace(end+1)=deal(int32(0));     
            else
                paceMakerPacket.Pace=string(nan);
            end
        end
        %% 
        
        %% Json Packet
        % Json Packet
        %
        % jsonPacket = JsonPacket( jsonPacket, fileAdress )
        %
        % <<< Function Inputs >>>
        %   struct jsonPacket
        %   string fileAdress
        %
        % <<< Function Outputs >>>
        %   string fileAdress
        %
        
        function jsonPacket = JsonPacket( jsonPacket, fileAdress, ResponseInfo )
            
            % Response Info
            ResponseInfo.Analysis.EndDateTime = datetime('now','TimeZone','UTC','Format','d-MMM-y HH:mm:ss');
            ResponseInfo.Analysis.Duration = milliseconds( ResponseInfo.Analysis.EndDateTime - ResponseInfo.Analysis.StartDateTime );
            % Type Conversion
            ResponseInfo.Analysis.StartDateTime = ClassTypeConversion.ConvertChar2Datetime( char( ResponseInfo.Analysis.StartDateTime ) );
            ResponseInfo.Analysis.EndDateTime = ClassTypeConversion.ConvertChar2Datetime( char( ResponseInfo.Analysis.EndDateTime ) );
            ResponseInfo.Analysis.Duration = ClassTypeConversion.ConvertMiliseconds2String( ResponseInfo.Analysis.Duration );
            % Merge Json
            jsonPacket.ResponseInfo = ResponseInfo;
            
            % json string
            jsonPacket = jsonencode( jsonPacket  );
            jsonPacket = string( jsonPacket );
            jsonPacket = strcat(jsonPacket, '  ');
            % write to text file
            fileAdress = strrep(fileAdress, '_FilteredSignal.bin' , '_MatlabAPIReport.json' );
            % open file
            reportFile = fopen(fileAdress, 'w');
            % write json to file
            fwrite(reportFile, jsonPacket);
            % close file
            fclose(reportFile);
            % close all
            fclose( 'all' );
            
        end
        
        
    end
    
    
end


%% PRIVATE FUNCTIONS : Generate Class List
% Generating Class LÝst
%
% ClassList = GenerateClassList( Run, Name, DurationType )
%
% <<< Function Inputs >>>
%   struct Run
%   string Name
%   string DurationType
%
% <<< Function Outputs >>>
%   class list ClassList
%

function [ ClassList ] = GenerateClassList( Run, Name, DurationType )

% Total Runs
TotalRuns = numel( Run.StartTime( :, 1 ) );
StartRuns = 1;

% start time
RunStartTime = cellstr(Run.StartTime );
[ Class.(Name)( double( StartRuns ) : double( TotalRuns ) ).StartTime ] = deal( RunStartTime{:} );
[ Class.(Name)(TotalRuns + 1).StartTime ] = deal( '0001-01-01T00:00:00.000Z' );

% end time
RunEndTime = cellstr(Run.EndTime );
[ Class.(Name)( double( StartRuns ) : double( TotalRuns ) ).EndTime ] = deal( RunEndTime{:} );
[ Class.(Name)(TotalRuns + 1).EndTime ] = deal( '0001-01-01T00:00:00.000Z' );

% duration
switch DurationType
    case 'Time'
        RunDuration = cellstr( ClassTypeConversion.ConvertMiliseconds2String( ( Run.Duration ) ) );
        [ Class.(Name)( double( StartRuns ): double( TotalRuns ) ).Duration ] = deal( RunDuration{:} );
        [ Class.(Name)(TotalRuns + 1).Duration ] = deal( '00.00:00:00.000' );
    case 'Beats'
        RunDuration = num2cell( Run.Duration );
        [ Class.(Name)( double( StartRuns ) : double( TotalRuns ) ).Beats ] = deal( RunDuration{:} );
        [ Class.(Name)(TotalRuns + 1).Beats ] = deal( int32(0) );
end

% average heart rate
RunAverageHeartRate = num2cell( Run.AverageHeartRate );
[ Class.(Name)( double( StartRuns ) : double( TotalRuns ) ).AverageHeartRate ] = deal( RunAverageHeartRate{:} );
[ Class.(Name)(TotalRuns + 1).AverageHeartRate ] = deal( int32(0) );

% event type
[ Class.(Name)( double( StartRuns ) : double( TotalRuns ) ).EventType ] = deal( Name );
[ Class.(Name)(TotalRuns + 1).EventType ] = deal( int32(0) );

% % strip data
% % - start
% StripStartTime = cellstr( ClassDatetimeCalculation.Substraction( Run.StartTime, 60) );
% [ StripCell(StartRuns:TotalRuns).StartTime ] = deal( StripStartTime{:} );
% [ StripCell(TotalRuns + 1).StartTime ] = deal( string(NaN) );
% % - end
% StripEndTime = cellstr( ClassDatetimeCalculation.Summation( Run.EndTime, 60) );
% [ StripCell(StartRuns:TotalRuns).EndTime ] = deal( StripEndTime{:} );
% [ StripCell(TotalRuns + 1).EndTime ] = deal( string(NaN) );
% % - to cell
% StripCell = num2cell( StripCell );
% [ Class.(Name)(StartRuns:TotalRuns + 1).StripData ] = deal( StripCell{:} );

% Output ClassList
ClassList = Class.(Name);

end



%% HRV GRAPH
%
% [ ClassList] = HRVGraph( hrvAnalysis )
%
% <<< Function Inputs >>>
%   struct hrvAnalysis
%
% <<< Function Outputs >>>
%   class list ClassList
%

function [ ClassList] = HRVGraph( hrvAnalysisResults )

if ( hrvAnalysisResults.SegmentCount > 0 ) 
    
    % number of points
    numberOfPoints = ( hrvAnalysisResults.SegmentCount );
        
    % fields
    hrvSDNN = ...
        num2cell( round( hrvAnalysisResults.sdnn, 2 ) );
    hrvSDRR = ...
        num2cell( round( hrvAnalysisResults.sdrr, 2 ) );
    hrvNN50 = ...
        num2cell( round( hrvAnalysisResults.nn50, 2 ) );
    hrvPNN50 = ...
        num2cell( round( 100 * hrvAnalysisResults.pnn50, 2 ) );
    hrvRMSSD = ...
        num2cell( round( hrvAnalysisResults.rmssd, 2 ) );
    hrvMeanRR = ...
        num2cell( round( hrvAnalysisResults.meanRR, 2 ) );
    hrvMaxRR = ...
        num2cell( round( hrvAnalysisResults.maxRR, 2 ) );
    hrvMinRR = ...
        num2cell( round( hrvAnalysisResults.minRR, 2 ) );
    hrvMeanHR = ...
        num2cell( round( hrvAnalysisResults.meanHR, 2 ) );
    hrvMaxHR = ...
        num2cell( round( hrvAnalysisResults.maxHR, 2 ) );
    hrvMinHR = ...
        num2cell( round( hrvAnalysisResults.minHR, 2 ) );
    
    
    % store
    % - SDNN
    [ Class( double( 1 ) : double( numberOfPoints ) ).SDNN ] = deal( hrvSDNN{:} );
    [ Class(numberOfPoints + 1).SDNN ] = deal( single(0) );
    % - SDRR
    [ Class( double( 1 ) : double( numberOfPoints ) ).SDRR ] = deal( hrvSDRR{:} );
    [ Class(numberOfPoints + 1).SDRR ] = deal( single(0) );
    % - NN50
    [ Class( double( 1 ) : double( numberOfPoints ) ).NN50 ] = deal( hrvNN50{:} );
    [ Class(numberOfPoints + 1).NN50 ] = deal( single(0) );
    % - PNN50
    [ Class( double( 1 ) : double( numberOfPoints ) ).PNN50 ] = deal( hrvPNN50{:} );
    [ Class(numberOfPoints + 1).PNN50 ] = deal( single(0) );
    % - RMSSD
    [ Class( double( 1 ) : double( numberOfPoints ) ).RMSSD ] = deal( hrvRMSSD{:} );
    [ Class(numberOfPoints + 1).RMSSD ] = deal( single(0) );
    % - MeanRR
    [ Class( double( 1 ) : double( numberOfPoints ) ).MeanRR ] = deal( hrvMeanRR{:} );
    [ Class(numberOfPoints + 1).MeanRR ] = deal( single(0) );
    % - MaxRR
    [ Class( double( 1 ) : double( numberOfPoints ) ).MaxRR ] = deal( hrvMaxRR{:} );
    [ Class(numberOfPoints + 1).MaxRR ] = deal( single(0) );
    % - MinRR
    [ Class( double( 1 ) : double( numberOfPoints ) ).MinRR ] = deal( hrvMinRR{:} );
    [ Class(numberOfPoints + 1).MinRR ] = deal( single(0) );
    % - MeanHR
    [ Class( double( 1 ) : double( numberOfPoints ) ).MeanHR ] = deal( hrvMeanHR{:} );
    [ Class(numberOfPoints + 1).MeanHR ] = deal( single(0) );
    % - MaxHR
    [ Class( double( 1 ) : double( numberOfPoints ) ).MaxHR ] = deal( hrvMaxHR{:} );
    [ Class(numberOfPoints + 1).MaxHR ] = deal( single(0) );
    % - MinHR
    [ Class( double( 1 ) : double( numberOfPoints ) ).MinHR ] = deal( hrvMinHR{:} );
    [ Class(numberOfPoints + 1).MinHR ] = deal( single(0) );
    
    % Output ClassList
    ClassList = Class;
    
    
else
    
    % Output ClassList
    ClassList = string(NaN);
    
end


end


%% ST SEGMENT GRAPH
%
% [ ClassList] = BeatInterval( qrsComplexes, type )
%
% <<< Function Inputs >>>
%   struct qrsComplexes
%   string type
%
% <<< Function Outputs >>>
%   class list ClassList
%

function [ ClassList] = STSegmentGraph( qrs )

if ~isempty( qrs.R )
    
    % number of points
    numberOfPoints = length( qrs.R );
        
    % points
    stChangeValues = num2cell( round( qrs.STSegmentChange, 2 ) );
    jPointValues = num2cell( round(  qrs.JPointValue, 2 ) );
    
    % store
    % - Amplitude
    [ Class( double( 1 ) : double( numberOfPoints ) ).Amplitude ] = deal( stChangeValues{:} );
    [ Class(numberOfPoints + 1).Amplitude ] = deal( single(0) );
    % - J Point
    [ Class( double( 1 ) : double( numberOfPoints ) ).JPoint ] = deal( jPointValues{:} );
    [ Class(numberOfPoints + 1).JPoint ] = deal( single(0) );
    
    % Output ClassList
    ClassList = Class;
    
else
    
    % Output ClassList
    ClassList = single( [ ] );
    
end


end


%% Beat Details
% BEAT CLASSIFICATION: Beat Details
%
% [ ClassList] = BeatClassification( BeatPoints, samplingFreq )
%
% <<< Function Inputs >>>
%   single[n,1] BeatPoints
%   single samplingFreq
%
% <<< Function Outputs >>>
%   class list ClassList
%

function [ ClassList ] = BeatClassification(  qrsComplexes, samplingFreq,similarity )

% Get Data
beatPoints = qrsComplexes.R;
beatFormType = qrsComplexes.BeatFormType;
AverageHeartRateDetectionResults=  AverageHeartRateDetection(qrsComplexes, qrsComplexes.HeartRate);

if ~isempty( beatFormType )
    
%    Initialization
    beatFormType = char( beatFormType );
    
    % number of beats
    numberOfBeats = length( beatPoints );
    
    % heart rates
    beatBPM = zeros( length( beatPoints ),1 );
    beatBPM( 2:end ) = ClassRhythmAnalysis.CalculateHeartRate(beatPoints, samplingFreq);
    %newHeartRate
  % newbeatBPM = zeros( length( beatPoints),1 );
    newbeatBPM= AverageHeartRateDetectionResults.newHeartRate;
%  %MinimumHeartRateBeatIndex
%    MinimumHeartRateBeatIndex = AverageHeartRateDetectionResults.MinimumHeartRateBeatIndex;
%    %MaximumHeartRateBeatIndex
%    MaximumHeartRateBeatIndex = AverageHeartRateDetectionResults.MaximumHeartRateBeatIndex;
    
  
    
    
    % convert to cell
    % - beat index
    beatIndex = num2cell( transpose( double( 1 ) : double( numberOfBeats ) ) );
    % - beat points
    beatPoints = num2cell( beatPoints );
    % - beat bpm
    beatBPM = num2cell( beatBPM );
    %new beatbpm
     newbeatBPM = num2cell( newbeatBPM );
     %similarity
     similarity = num2cell( similarity );
    % MinimumHeartRateBeatIndex
%     MinimumHeartRateBeatIndex=num2cell(MinimumHeartRateBeatIndex);
%     %MaximumHeartRateBeatIndex
%     MaximumHeartRateBeatIndex=num2cell(MaximumHeartRateBeatIndex);
    % - beat type
    beatType = num2cell( beatFormType( : ,1) );
    % - beat form
    uniqueBeatTypes = unique( beatType );
    for typeIndex = 1 : length( uniqueBeatTypes )
        beatFormType = strip( string( beatFormType ), 'left', char( uniqueBeatTypes( typeIndex ) ) );
    end
    beatForm = num2cell( beatFormType );
    
    %P Start Point
    pStartPoint = num2cell(qrsComplexes.P.StartPoint);
    
    %T End Point
    tEndPoint = num2cell(qrsComplexes.T.EndPoint);
%     %Q
%     Q = num2cell(qrsComplexes.Q);
%     
%     %S
%     S = num2cell(qrsComplexes.S);
    % ListName
    Name = 'BeatDetails';
    
    % store
    % - beat index
    [ Class.(Name)( double( 1 ) : double( numberOfBeats) ).Index ] = deal( beatIndex{:} );
    [ Class.(Name)(numberOfBeats + 1).Index ] = deal( int32(0) );
    % - beat point
    [ Class.(Name)( double( 1 ) : double( numberOfBeats) ).Sample ] = deal( beatPoints{:} );
    [ Class.(Name)(numberOfBeats + 1).Sample ] = deal( int32(0) );
    % - beat classification
    [ Class.(Name)( double( 1 ) : double( numberOfBeats) ).Type ] = deal( beatType{:} );
    [ Class.(Name)(numberOfBeats + 1).Type ] = deal( int32(0) );
    % - beat form
    [ Class.(Name)( double( 1 ) : double( numberOfBeats) ).Form ] = deal( beatForm{:} );
    [ Class.(Name)(numberOfBeats + 1).Form ] = deal( int32(0) );
    % - beat bpm
    [ Class.(Name)( double( 1 ) : double( numberOfBeats) ).HeartRate ] = deal( beatBPM{:} );
    [ Class.(Name)(numberOfBeats + 1).HeartRate ] = deal( int32(0) );
    %- newbeatbpm
    [ Class.(Name)( double( 1 ) : double( numberOfBeats) ).AverageHeartRate ] = deal( newbeatBPM{:} );
    [ Class.(Name)(numberOfBeats + 1).AverageHeartRate ] = deal( int32(0) );
    %pStartPoint
    [ Class.(Name)( double( 1 ) : double( numberOfBeats) ).pStartPoint ] = deal( pStartPoint{:} );
    [ Class.(Name)(numberOfBeats + 1).pStartPoint ] = deal( int32(0) );
    %tEndPoint
    [ Class.(Name)( double( 1 ) : double( numberOfBeats) ).tEndPoint ] = deal( tEndPoint{:} );
    [ Class.(Name)(numberOfBeats + 1).tEndPoint ] = deal( int32(0) );
   %
    %Similarity
    [ Class.(Name)( double( 1 ) : double( numberOfBeats) ).similarity ] = deal( similarity{:} );
    [ Class.(Name)(numberOfBeats + 1).similarity ] = deal( int32(0) );
    
%     % MinimumHeartRateBeatIndex
%     [ Class.(Name)( double( 1 ) : double( numberOfBeats) ).MinimumHeartRateBeatIndex ] = deal( MinimumHeartRateBeatIndex{:} );
%     [ Class.(Name)(numberOfBeats + 1).MinimumHeartRateBeatIndex ] = deal( int32(0) );
%     % MaximumHeartRateBeatIndex
%     [ Class.(Name)( double( 1 ) : double( numberOfBeats) ).MaximumHeartRateBeatIndex ] = deal( MaximumHeartRateBeatIndex{:} );
%     [ Class.(Name)(numberOfBeats + 1).MaximumHeartRateBeatIndex ] = deal( int32(0) );
    % - beat bpm
    for i = 1 : numberOfBeats + 1
        
        if i < numberOfBeats + 1
            % - qrs interval
            Class.(Name)(i).Intervals.QRSInterval =  ...
                1000 * qrsComplexes.QRSInterval( i );
            % - qt interval
            Class.(Name)(i).Intervals.QTInterval =  ...
                1000 * qrsComplexes.QTInterval( i );
            % - qtc interval
            Class.(Name)(i).Intervals.QTcInterval =  ...
                1000 * qrsComplexes.QTcInterval( i );
            % - pr interval
            Class.(Name)(i).Intervals.PRInterval =  ...
                1000 * qrsComplexes.PRInterval( i );
            % - rr interval
            Class.(Name)(i).Intervals.RRInterval =  ...
                1000 * qrsComplexes.RRInterval( i );
            % - p interval
            Class.(Name)(i).Intervals.PInterval =  ...
                1000 * qrsComplexes.P.Interval( i );
        else
            % - last item of the list
            Class.BeatDetails(i).Intervals = string(NaN);
        end
        
    end
    % Output ClassList
    ClassList = Class.(Name);
    
else
    
    % Output ClassList
    ClassList = string(NaN);
    
end


end


%% Beat Forms
% BEAT CLASSIFICATION: Beat Details
%
% [ ClassList] = BeatClassification( qrsComplexes, beatTypes )
%
% <<< Function Inputs >>>
%   struct qrsComplexes
%   string list beatTypes
%
% <<< Function Outputs >>>
%   class list ClassList
%

function [ ClassList] = BeatForm( qrsComplexes )

% % General Beat Types
% expectedBeatTypes = { ...
%     'N_'; ... % normal beat
%     'V1'; ... % reversed pvc
%     'V2'; ... % up pvc
%     'P_'; ... % pacemaker
%     'U_'; ... % unclassified beat
%     'X_'; ... % diðer
%     };

% Initialization
beatTypes = qrsComplexes.BeatFormType;

% BeatForm
if ~isempty( qrsComplexes.BeatFormType )
    
    % Unique Beat Types
    uniqueBeatTypes = char( unique( beatTypes ) );
    
    % For each beat type
    uniqueBeatCount = zeros( length( uniqueBeatTypes( :, 1 ) ), 1, 'single' );
    for beatTypeIndex = 1 : numel( uniqueBeatCount )
        % find the beat type indexes
        indexes = find( contains( beatTypes, strtrim( uniqueBeatTypes( beatTypeIndex, : ) ) ) );
        % store beat count
        uniqueBeatCount( beatTypeIndex ) = length( indexes );        
    end
    
    % For each beat form
    for beatTypeIndex = 1 : numel( uniqueBeatTypes( :, 1 ) )
        % find the max beat type count
        [ maxCountValue, maxCountIndex ] = max( uniqueBeatCount );
        % max numb beat type
        Class.BeatForms(beatTypeIndex,1).Classification = uniqueBeatTypes( maxCountIndex, 1 );
        % new beat type name
        Class.BeatForms(beatTypeIndex,1).FormIndex = int32( str2double( uniqueBeatTypes( maxCountIndex, 2:end ) ) );
        % change name
        Class.BeatForms(beatTypeIndex,1).BeatCount = maxCountValue;
        % Erase selected max
        uniqueBeatCount( maxCountIndex ) = 0;
    end
    
    % Insert last null class
    Class.BeatForms( beatTypeIndex + 1 ,1 ).Classification = deal( int32(0) );
    Class.BeatForms( beatTypeIndex + 1 ,1 ).FormIndex = deal( int32(0) );
    Class.BeatForms( beatTypeIndex + 1 ,1 ).BeatCount = deal( int32(0) );
    
    % Output ClassList
    ClassList = Class.BeatForms;
    
else
    
    % Output ClassList
    ClassList = string(NaN);
    
end


end


%% Beat Intervals
%
% [ ClassList] = BeatInterval( qrsComplexes )
%
% <<< Function Inputs >>>
%   struct qrsComplexes
%
% <<< Function Outputs >>>
%   class list ClassList
%

function [ ClassList] = BeatInterval( qrsComplexes )

if ~isempty( qrsComplexes.R )
    
    % number of beats
    numberOfBeats = length( qrsComplexes.R );
    
    % convert to cell
    % - qrs interval
    qrsInterval = ...
        num2cell( 1000 * qrsComplexes.QRSInterval ); % ms
    % - qt interval
    qtInterval = ...
        num2cell( 1000 * qrsComplexes.QTInterval ); % ms
    % - qtc interval
    qtcInterval = ...
        num2cell( 1000 * qrsComplexes.QTcInterval ); % ms
    % - pr interval
    prInterval = ...
        num2cell( 1000 * qrsComplexes.PRInterval ); % ms
    % - rr interval
    rrInterval = ...
        num2cell( 1000 * qrsComplexes.RRInterval ); % ms
    % - p wave duration
    pWaveDuration = ...
        num2cell( 1000 * qrsComplexes.P.Interval ); % ms
        
    
    % store
    % - QRSInterval
    [ Class.Intervals( double( 1 ) : double( numberOfBeats ) ).QRSInterval ] = deal( qrsInterval{:} );
    [ Class.Intervals(numberOfBeats + 1).QRSInterval ] = deal( single(0) );
    % - QTInterval
    [ Class.Intervals( double( 1 ) : double( numberOfBeats ) ).QTInterval ] = deal( qtInterval{:} );
    [ Class.Intervals(numberOfBeats + 1).QTInterval ] = deal( single(0) );
    % - QTcInterval
    [ Class.Intervals( double( 1 ) : double( numberOfBeats ) ).QTcInterval ] = deal( qtcInterval{:} );
    [ Class.Intervals(numberOfBeats + 1).QTcInterval ] = deal( single(0) );
    % - PRInterval
    [ Class.Intervals( double( 1 ) : double( numberOfBeats ) ).PRInterval ] = deal( prInterval{:} );
    [ Class.Intervals(numberOfBeats + 1).PRInterval ] = deal( single(0) );
    % - RRInterval
    [ Class.Intervals( double( 1 ) : double( numberOfBeats ) ).RRInterval ] = deal( rrInterval{:} );
    [ Class.Intervals(numberOfBeats + 1).RRInterval ] = deal( single(0) );
    % - P Interval
    [ Class.Intervals( double( 1 ) : double( numberOfBeats ) ).PInterval ] = deal( pWaveDuration{:} );
    [ Class.Intervals(numberOfBeats + 1).PInterval ] = deal( single(0) );
    % - Mean Values
    Class.MeanValues.QRSInterval = ...
        round( 1000 * mean( qrsComplexes.QRSInterval( qrsComplexes.QRSInterval >= 0 ) ) ); % ms
    Class.MeanValues.QTInterval = ...
        round( 1000 * mean( qrsComplexes.QTInterval( qrsComplexes.QTInterval >= 0 ) ) ); % ms
    Class.MeanValues.QTcInterval = ...
        round( 1000 * mean( qrsComplexes.QTcInterval( qrsComplexes.QTcInterval >= 0 ) ) ); % ms
    Class.MeanValues.PRInterval = ...
        round( 1000 * mean( qrsComplexes.PRInterval( qrsComplexes.PRInterval >= 0 ) ) ); % ms
    Class.MeanValues.RRInterval = ...
        round( 1000 * mean( qrsComplexes.RRInterval( qrsComplexes.RRInterval >= 0 ) ) ); % ms
    Class.MeanValues.PInterval = ...
        round( 1000 * mean( qrsComplexes.P.Interval( qrsComplexes.P.Interval >= 0 ) ) ); % ms
    
    % Output ClassList
    ClassList = Class;
    
else
    
    % Output ClassList
    ClassList = string(NaN);
    
end


end


%% ENUM LIST

% public enum DBEnum_AlarmModelType
%         {
%             None,
%             NoAnalysis,
%             NoDiagnosis,
%             AlarmButton,
%             SinusArrythmia,
%             SinusBradycardia,
%             Pause,
%             AVBlockDegreeI,
%             AVBlockDegreeII_Type1,
%             AVBlockDegreeII_Type2,
%             AVBlockDegreeIII,
%             SinusTachycardia,
%             VentricularTachycardia,
%             SupraventricularTachycardia,
%             PVCUncategorized,
%             PVCIsolated,
%             PVCBigeminy,
%             PVCTrigeminy,
%             PVCQuadrigeminy,
%             PVCCouplets,
%             PVCTriplets,
%             PVCSalvo,
%             IVR,
%             AIVR,
%             PACUncategorized,
%             PACIsolated,
%             PACBigeminy,
%             PACTrigeminy,
%             PACQuadrigeminy,
%             PACCouplets,
%             PACTriplets,
%             PACSalvo,
%             AtrialFib,
%             AtrialFlutter,
%             VentricularFib,
%             VentricularFlutter,
%             Asystole,
%             ActivityWithHighHeartRate,
%             ActivityWithLowHeartRate,
%             Noise
%         }









