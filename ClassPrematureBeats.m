classdef ClassPrematureBeats
    
    %"ClassPrematureBeats.m" class consists premature beat detection algorithms.
    %
    % > FindPattern
    % > FindPrematureBeatPattern
    % > FindPrematureBeatRuns
    % > ClearRun
    
    %% PROPERTIES
    
    properties
        
        %
        
    end
    
    %% STATIC METHODS
    
    methods (Static)
        
        
        %% Find Pattern
        
        function start = FindPattern(array, pattern)
            
            % Find the given pattern in array.
            %
            % start = FindPattern(array, pattern)
            %
            % <<< Function Inputs >>>
            %   single[n,1] array
            %   single[n,1] pattern
            %
            % <<< Function Outputs >>>
            %   single[n,1] start
            
            % Let's assume for now that both the pattern and the array are non-empty
            % VECTORS, but there's no checking for this.
            % For this algorithm, I loop over the pattern elements.
            len = length(pattern);
            
            % First, find candidate locations; i.e., match the first element in the
            % pattern.
            start = find(array==pattern(1));
            
            % Next remove start values that are too close to the end to possibly match
            % the pattern.
            endVals = start+len-1;
            start(endVals>length(array)) = [];
            
            % Next, loop over elements of pattern, usually much shorter than length of
            % array, to check which possible locations are valid still.
            for pattval = 2:len
                % check viable locations in array
                locs = pattern(pattval) == array(start+pattval-1);
                % delete false ones from indices
                start(~locs) = [];
            end
            
        end
        
        
        %% Find Premature Beat Pattern
        
        function [ PatternInfo ] = FindPrematureBeatPattern ( PrematureBeats, PrematureBeatsStart, PatternType )
            
            % Find the given PVC pattern in the PrematureBeats.
            %
            % [ PatternInfo ] = FindPrematureBeatPattern ( PrematureBeats, PrematureBeatsStart, PatternType )
            %
            % <<< Function Inputs >>>
            %   single[n,1] PrematureBeats
            %   single[n,1] PrematureBeatsStart
            %   string PatternType
            %
            % <<< Function Outputs >>>
            %   struct PatternInfo
            %   .StartBeat
            %   .EndBeat
            %   .BlockIndex
            
            if all( ~PrematureBeats )
                
                PatternInfo.StartBeat = [ ];
                PatternInfo.EndBeat = [ ];
                PatternInfo.BlockIndex = [ ];
                
            else
                
                % select pattern
                switch PatternType
                    
                    case 'Quadrigeminy'
                        pattern =  [ 1; 0; 0; 0; 1; 0; 0; 0];
                        singlePatternLength = 4;
                        % annotation
                        
                    case 'Trigeminy'
                        pattern =  [ 1; 0; 0; 1; 0; 0];
                        singlePatternLength = 3;
                        % annotation
                        
                    case 'Bigeminy'
                        pattern =  [ 1; 0; 1; 0 ];
                        singlePatternLength = 2;
                end
                
                % initialization
                patternRun = zeros( length( PrematureBeats ), 1, 'single' );
                
                % find pattern start indexes
                patternStartIndex = ClassPrematureBeats.FindPattern( PrematureBeats, pattern );
                patternStartIndex = [ patternStartIndex; patternStartIndex + singlePatternLength ];
                patternStartIndex = sort( unique( patternStartIndex ) );
                
                if ~( isempty( patternStartIndex ) )
                    
                    % fill pattern
                    for changeIndex = 1 : singlePatternLength
                        patternRun( patternStartIndex + ( changeIndex - 1 ) ) = 1;
                    end
                    
                    % pattern start/end
                    blockEdges = single( ( abs( diff( [ 0; patternRun; 0; 0; 0 ] ) ) > 0 ) > 0 );
                    blockEdges = single( find(blockEdges == 1) );
                    PatternInfo.StartBeat = single( blockEdges( 1:2:length( blockEdges ) ) );
                    PatternInfo.EndBeat = single( blockEdges( 2:2:length( blockEdges ) ) ) - 1;
                    PatternInfo.Duration = PatternInfo.EndBeat - PatternInfo.StartBeat;
                    % remove short patterns
                    shortPattern = find( ( PatternInfo.Duration < length( pattern ) ) );
                    for index = 1 : length( shortPattern )
                        % get beats
                        startBeat = PatternInfo.StartBeat( shortPattern( index ) );
                        endBeat = PatternInfo.EndBeat( shortPattern( index ) );
                        removeBlockIndex = ( ( patternStartIndex >= startBeat ) & ( patternStartIndex <= endBeat ) );
                        % blockIndex
                        patternStartIndex( removeBlockIndex ) = [ ];
                    end
                    % start/end beat flag
                    PatternInfo.StartBeat( shortPattern ) = [ ];
                    PatternInfo.EndBeat( shortPattern ) = [ ];
                    PatternInfo.Duration( shortPattern ) = [ ];
                    % blockIndex
                    [~, PatternInfo.BlockIndex, ~] = intersect( PrematureBeatsStart, patternStartIndex );
                    PatternInfo.BlockIndex = single( PatternInfo.BlockIndex ) ;
                    
                else
                    
                    PatternInfo.StartBeat = single( [ ] );
                    PatternInfo.EndBeat = single( [ ] );
                    PatternInfo.BlockIndex = single( [ ] );
                    
                end
                
            end
            
        end
        
        
        %% Find Premature Beat Run
        
        function [ QRSComplexes, PrematureRuns, PrematureTachyRuns ] = FindPrematureBeatRuns( QRSComplexes, TachyRuns, type, RecordInfo )
            
            % Find runs in the PrematureBeats
            %
            % [ PrematureRuns ] = FindPrematureBeatRuns( QRSComplexes, VentricularFlutters, RecordInfo, AnalysisParameters )
            %
            % <<< Function Inputs >>>
            %   struct QRSComplexes
            %   struct VentricularEctopics
            %   struct RecordInfo
            %   struct AnalysisParameters
            %
            % <<< Function Outputs >>>
            %   struct PrematureRuns
            %   .SalvoRun
            %   .TripletRun
            %   .CoupletRun
            %   .QuadrigeminyRun
            %   .TrigeminyRun
            %   .BigeminyRun
            %   .IsolatedRun
            %   struct VentricularTachy
            
            % Premature Beats
            if type == 'V'
                % get premature beats
                selectedPrematureBeats = QRSComplexes.VentricularBeats;
                if ~isempty( TachyRuns )
                    selectedPrematureBeats( TachyRuns.BeatFlag ) = false;
                end
            elseif type == 'A'
                % get premature beats
                selectedPrematureBeats = QRSComplexes.AtrialBeats;
                % include SVT beats for premature atrial beats
                if ~isempty( TachyRuns )
                    selectedPrematureBeats( TachyRuns.BeatFlag ) = false;
                end
            end
            
            % Check Premauture  Beats
            if all( ~selectedPrematureBeats )
                
                % Premature Beats
                % - Common Fields
                % // -- premature beat flags
                if type == 'V'
                    % - flag in the premature run class
                    PrematureRuns.PrematureBeats = selectedPrematureBeats;
                elseif type == 'A'
                    % - flag in the premature run class
                    PrematureRuns.PrematureBeats = selectedPrematureBeats;
                end
                % // -- total beats
                PrematureRuns.TotalBeats = single( 0 );
                % // -- total runs
                PrematureRuns.TotalRuns = single( 0 );
                % SubFields
                % // -- IVR and AIVR Runs
                if type == 'V'
                    [ ~, ~, PrematureRuns.IVRRun ] = PacketRun( [ ], [ ], [ ], [ ], ' ');
                    [ ~, ~, PrematureRuns.AIVRRun ] = PacketRun( [ ], [ ], [ ], [ ], ' ');
                end
                % // -- Salvo Runs
                [ ~, ~, PrematureRuns.SalvoRun ] = PacketRun( [ ], [ ], [ ], [ ], ' ');
                % // -- Triplet Runs
                [ ~, ~, PrematureRuns.TripletRun ] = PacketRun( [ ], [ ], [ ], [ ], ' ');
                % // -- Couplet Runs
                [ ~, ~, PrematureRuns.CoupletRun ] = PacketRun( [ ], [ ], [ ], [ ], ' ');
                % // -- Quadrigeminy Runs
                [ ~, ~, PrematureRuns.QuadrigeminyRun ] = PacketRun( [ ], [ ], [ ], [ ], ' ');
                % // -- Trigeminy Runs
                [ ~, ~, PrematureRuns.TrigeminyRun ] = PacketRun( [ ], [ ], [ ], [ ], ' ');
                % // -- Bigeminy Runs
                [ ~, ~, PrematureRuns.BigeminyRun ] = PacketRun( [ ], [ ], [ ], [ ], ' ');
                % // -- Isolated Runs
                [ ~, ~, PrematureRuns.IsolatedRun ] = PacketRun( [ ], [ ], [ ], [ ], ' ');
                % // -- Premature Tachy Runs
                PrematureTachyRuns = TachyRuns;
                
                
            else
                
                % INITIALIZATION
                % - preallocation
                PrematureRuns.PrematureBeats = [ selectedPrematureBeats; 0; 0; 0 ];
                PrematureRuns.TotalBeats = single( 0 );
                PrematureRuns.TotalRuns = single( 0 );
                % - heart rate
                HeartRate = QRSComplexes.HeartRate;
                % - get patterns
                blockEdges = single( ( abs( diff( [ 0; PrematureRuns.PrematureBeats ] ) ) > 0 ) > 0 );
                blockEdges = single( find(blockEdges == 1) );
                PrematureBeatsStart = single( blockEdges( 1:2:length( blockEdges ) ) );
                PrematureBeatsEnd = single( blockEdges( 2:2:length( blockEdges ) ) ) - 1;
                PrematureBeatsDuration = PrematureBeatsEnd - PrematureBeatsStart + 1;
                
                %% SALVO
                
                % Get Salvo
                SalvoMinimumBeatNumber = single( 4 );
                PrematureRuns.SalvoRun.BlockIndex = single( find( PrematureBeatsDuration >= SalvoMinimumBeatNumber ) );
                PrematureRuns.SalvoRun.StartBeat = PrematureBeatsStart( PrematureRuns.SalvoRun.BlockIndex );
                PrematureRuns.SalvoRun.EndBeat = PrematureBeatsEnd( PrematureRuns.SalvoRun.BlockIndex );
                % ClearSalvos
                [ PrematureRuns.PrematureBeats, PrematureBeatsStart, PrematureBeatsEnd, PrematureBeatsDuration ] = ...
                    ClassPrematureBeats.ClearRun( PrematureRuns.PrematureBeats, PrematureBeatsStart, PrematureBeatsEnd, PrematureBeatsDuration, PrematureRuns.SalvoRun);
                % Packet Run
                [ ~, ~, PrematureRuns.SalvoRun ] = PacketRun( PrematureRuns.SalvoRun, QRSComplexes, HeartRate, RecordInfo, 'Salvo');
                
                %% SALVO TYPES
                
                % ///
                % ///
                % VENTRICULAR EVENTS
                % ///
                % ///
                if type == 'V'
                    
                    if ~isempty( PrematureRuns.SalvoRun )
                        
                        % Preallocation
                        % - IVR
                        saveIVRIndex = zeros( length( PrematureRuns.SalvoRun.StartBeat), 1, 'single' );
                        % - AIVR
                        saveAIVRIndex = zeros( length( PrematureRuns.SalvoRun.StartBeat), 1, 'single' );
                        % - Salvo
                        saveSalvoIndex = zeros( length( PrematureRuns.SalvoRun.StartBeat), 1, 'single' );
                        % - Tachy
                        saveVTachyIndex = zeros( length( PrematureRuns.SalvoRun.StartBeat), 1, 'single' );
                        
                        % Salvo Type
                        for salvoIndex = 1 : length( PrematureRuns.SalvoRun.StartBeat )
                            % heart rate based segmentation
                            if PrematureRuns.SalvoRun.AverageHeartRate( salvoIndex ) < single( 100 )
                                % Salvo
                                saveSalvoIndex( salvoIndex ) = 1;
                            else
                                % Salvo
                                saveVTachyIndex( salvoIndex ) = 1;
                            end
                        end
                        
                        % Idioventricular rhythm
                        saveIVRIndex = find( saveIVRIndex == 1 );
                        [ NumbRun, NumBeats, PrematureRuns.IVRRun ] = GetRunInfo( PrematureRuns.SalvoRun, saveIVRIndex );
                        PrematureRuns.TotalBeats = PrematureRuns.TotalBeats + NumBeats;
                        PrematureRuns.TotalRuns = PrematureRuns.TotalRuns + NumbRun;
                        
                        % Accelerated idioventricular rhythm
                        saveAIVRIndex = find( saveAIVRIndex == 1 );
                        [ NumbRun, NumBeats, PrematureRuns.AIVRRun ] = GetRunInfo( PrematureRuns.SalvoRun, saveAIVRIndex );
                        PrematureRuns.TotalBeats = PrematureRuns.TotalBeats + NumBeats;
                        PrematureRuns.TotalRuns = PrematureRuns.TotalRuns + NumbRun;
                        
                        % Ventricular tachycardia
                        saveVTachyIndex = find( saveVTachyIndex == 1 );
                        [ ~, ~, PrematureTachyRuns ] = GetRunInfo( PrematureRuns.SalvoRun, saveVTachyIndex );
                        
                        % Salvo
                        saveSalvoIndex = find( saveSalvoIndex == 1 );
                        [ NumbRun, NumBeats, PrematureRuns.SalvoRun ] = GetRunInfo( PrematureRuns.SalvoRun, saveSalvoIndex );
                        PrematureRuns.TotalBeats = PrematureRuns.TotalBeats + NumBeats;
                        PrematureRuns.TotalRuns = PrematureRuns.TotalRuns + NumbRun;
                        
                        
                    else
                        
                        % IVR
                        [ ~, ~, PrematureRuns.IVRRun ] = PacketRun( [ ], [ ], [ ], [ ], ' ');
                        % AIVR
                        [ ~, ~, PrematureRuns.AIVRRun ] = PacketRun( [ ], [ ], [ ], [ ], ' ');
                        % Salvo
                        [ ~, ~, PrematureRuns.SalvoRun ] = PacketRun( [ ], [ ], [ ], [ ], ' ');
                        % Tachy
                        [ ~, ~, PrematureTachyRuns ] = PacketRun( [ ], [ ], [ ], [ ], ' ');
                        
                    end
                    
                end
                
                % ///
                % ///
                % ATRIAL EVENTS
                % ///
                % ///
                if type == 'A'
                    
                    if ~isempty( PrematureRuns.SalvoRun )
                        
                        % Initialization
                        saveSalvoIndex = zeros( length( PrematureRuns.SalvoRun.StartBeat ), 1, 'single' );
                        saveSVTachyIndex = zeros( length( PrematureRuns.SalvoRun.StartBeat), 1, 'single' );
                        
                        % Salvo Type
                        for salvoIndex = 1 : length( PrematureRuns.SalvoRun.StartBeat )
                            % heart rate based segmentation
                            if PrematureRuns.SalvoRun.AverageHeartRate( salvoIndex ) < single( 100 )
                                % Heart Rate Comparison
                                saveSalvoIndex( salvoIndex ) = 1;
                            else
                                % SVT Runs
                                saveSVTachyIndex( salvoIndex ) = 1;
                            end
                        end
                        
                        % Supraventricular tachycardia
                        saveSVTachyIndex = find( saveSVTachyIndex == 1 );
                        [ ~, ~, PrematureTachyRuns ] = GetRunInfo( PrematureRuns.SalvoRun, saveSVTachyIndex );
                        
                        % Salvo
                        saveSalvoIndex = find( saveSalvoIndex == 1 );
                        [ NumbRun, NumBeats, PrematureRuns.SalvoRun ] = GetRunInfo( PrematureRuns.SalvoRun, saveSalvoIndex );
                        PrematureRuns.TotalBeats = PrematureRuns.TotalBeats + NumBeats;
                        PrematureRuns.TotalRuns = PrematureRuns.TotalRuns + NumbRun;
                        
                        
                    else
                        
                        % Salvo
                        [ ~, ~, PrematureRuns.SalvoRun ] = PacketRun( [ ], [ ], [ ], [ ], ' ');
                        % Tachy
                        [ ~, ~, PrematureTachyRuns ] = PacketRun( [ ], [ ], [ ], [ ], ' ');
                        
                    end
                    
                end
                
                %% ADD NEW PREMATURE TACHY RUN
                
                if ~isempty( PrematureTachyRuns )
                    
                    % Adjust Field
                    % - remove
                    PrematureTachyRuns = rmfield( PrematureTachyRuns, 'BlockIndex' );
                    PrematureTachyRuns = rmfield( PrematureTachyRuns, 'TotalRun' );
                    % - add
                    PrematureTachyRuns.BeatFlag = zeros( length( QRSComplexes.R ), 1, 'logical' );
                    for tachyIndex = 1 : length( PrematureTachyRuns.StartBeat )
                        PrematureTachyRuns.BeatFlag( ...
                            double( PrematureTachyRuns.StartBeat( tachyIndex ) ) : double( PrematureTachyRuns.EndBeat( tachyIndex ) ) ...
                            ) = true;
                    end
                    
                    % Add to the existings
                    if ~isempty( TachyRuns )
                        % Tachy run fields
                        runFields = fieldnames( TachyRuns );
                        % Merge
                        for fieldIndex = 1 : length( runFields )
                            if strcmp( runFields{ fieldIndex }, 'BeatFlag' )
                                PrematureTachyRuns.( runFields{ fieldIndex } ) = ...
                                    PrematureTachyRuns.( runFields{ fieldIndex } ) | TachyRuns.( runFields{ fieldIndex } );
                            else
                                PrematureTachyRuns.( runFields{ fieldIndex } ) = ...
                                    [ PrematureTachyRuns.( runFields{ fieldIndex } ); TachyRuns.( runFields{ fieldIndex } ) ];
                            end
                        end
                    end
                       
                else
                    
                    PrematureTachyRuns = TachyRuns;
                    
                end
                
                %% TRIPLET
                
                % Get Triplet
                TripletBeatNumber = single( 3 );
                PrematureRuns.TripletRun.BlockIndex = single( find( PrematureBeatsDuration == TripletBeatNumber ) );
                PrematureRuns.TripletRun.StartBeat = PrematureBeatsStart( PrematureRuns.TripletRun.BlockIndex );
                PrematureRuns.TripletRun.EndBeat = PrematureBeatsEnd( PrematureRuns.TripletRun.BlockIndex );
                % ClearTriplet
                [ PrematureRuns.PrematureBeats, PrematureBeatsStart, PrematureBeatsEnd, PrematureBeatsDuration ] = ...
                    ClassPrematureBeats.ClearRun( PrematureRuns.PrematureBeats, PrematureBeatsStart, PrematureBeatsEnd, PrematureBeatsDuration, PrematureRuns.TripletRun);
                % Packet Run
                [ NumbRun, NumBeats, PrematureRuns.TripletRun ] = PacketRun( PrematureRuns.TripletRun, QRSComplexes, HeartRate, RecordInfo, 'Triplet');
                % Total Beat / Run
                PrematureRuns.TotalBeats = PrematureRuns.TotalBeats + NumBeats;
                PrematureRuns.TotalRuns = PrematureRuns.TotalRuns + NumbRun;
                
                %% COUPLET
                
                % Get Couplet
                CoupletBeatNumber = single( 2 );
                PrematureRuns.CoupletRun.BlockIndex = single( find( PrematureBeatsDuration == CoupletBeatNumber ) );
                PrematureRuns.CoupletRun.StartBeat = PrematureBeatsStart( PrematureRuns.CoupletRun.BlockIndex );
                PrematureRuns.CoupletRun.EndBeat = PrematureBeatsEnd( PrematureRuns.CoupletRun.BlockIndex );
                % ClearCouplet
                [ PrematureRuns.PrematureBeats, PrematureBeatsStart, PrematureBeatsEnd, PrematureBeatsDuration ] = ...
                    ClassPrematureBeats.ClearRun( PrematureRuns.PrematureBeats, PrematureBeatsStart, PrematureBeatsEnd, PrematureBeatsDuration, PrematureRuns.CoupletRun);
                % Packet Run
                [ NumbRun, NumBeats, PrematureRuns.CoupletRun ] = PacketRun( PrematureRuns.CoupletRun, QRSComplexes, HeartRate, RecordInfo, 'Couplet');
                % Total Beat / Run
                PrematureRuns.TotalBeats = PrematureRuns.TotalBeats + NumBeats;
                PrematureRuns.TotalRuns = PrematureRuns.TotalRuns + NumbRun;
                
                %% QUADRIGEMINY
                
                % Get Quadrigeminy
                [ PrematureRuns.QuadrigeminyRun ] = ClassPrematureBeats.FindPrematureBeatPattern ( PrematureRuns.PrematureBeats, PrematureBeatsStart, 'Quadrigeminy' );
                % Clear
                [ PrematureRuns.PrematureBeats, PrematureBeatsStart, PrematureBeatsEnd, PrematureBeatsDuration ] = ...
                    ClassPrematureBeats.ClearRun( PrematureRuns.PrematureBeats, PrematureBeatsStart, PrematureBeatsEnd, PrematureBeatsDuration, PrematureRuns.QuadrigeminyRun);
                % Packet Run
                [ NumbRun, NumBeats, PrematureRuns.QuadrigeminyRun ] = PacketRun( PrematureRuns.QuadrigeminyRun, QRSComplexes, HeartRate, RecordInfo, 'Quadrigeminy');
                % Total Beat / Run
                PrematureRuns.TotalBeats = PrematureRuns.TotalBeats + NumBeats;
                PrematureRuns.TotalRuns = PrematureRuns.TotalRuns + NumbRun;
                
                %% TRIGEMINY
                
                % Get Trigeminy
                [ PrematureRuns.TrigeminyRun ] = ClassPrematureBeats.FindPrematureBeatPattern ( PrematureRuns.PrematureBeats, PrematureBeatsStart, 'Trigeminy' );
                % Clear
                [ PrematureRuns.PrematureBeats, PrematureBeatsStart, PrematureBeatsEnd, PrematureBeatsDuration ] = ...
                    ClassPrematureBeats.ClearRun( PrematureRuns.PrematureBeats, PrematureBeatsStart, PrematureBeatsEnd, PrematureBeatsDuration, PrematureRuns.TrigeminyRun);
                % Packet Run
                [ NumbRun, NumBeats, PrematureRuns.TrigeminyRun ] = PacketRun( PrematureRuns.TrigeminyRun, QRSComplexes, HeartRate, RecordInfo, 'Trigeminy');
                % Total Beat / Run
                PrematureRuns.TotalBeats = PrematureRuns.TotalBeats + NumBeats;
                PrematureRuns.TotalRuns = PrematureRuns.TotalRuns + NumbRun;
                
                %% BIGEMINY
                
                % Get Bigeminy
                [ PrematureRuns.BigeminyRun ] = ClassPrematureBeats.FindPrematureBeatPattern ( PrematureRuns.PrematureBeats, PrematureBeatsStart, 'Bigeminy' );
                % Clear
                [ ~, PrematureBeatsStart, PrematureBeatsEnd, PrematureBeatsDuration ] = ...
                    ClassPrematureBeats.ClearRun( PrematureRuns.PrematureBeats, PrematureBeatsStart, PrematureBeatsEnd, PrematureBeatsDuration, PrematureRuns.BigeminyRun);
                % Packet Run
                [ NumbRun, NumBeats, PrematureRuns.BigeminyRun ] = PacketRun( PrematureRuns.BigeminyRun, QRSComplexes, HeartRate, RecordInfo, 'Bigeminy');
                % Total Beat / Run
                PrematureRuns.TotalBeats = PrematureRuns.TotalBeats + NumBeats;
                PrematureRuns.TotalRuns = PrematureRuns.TotalRuns + NumbRun;
                
                %%  ISOLATED
                
                % Get Isolated PrematureBeats
                PrematureRuns.IsolatedRun.StartBeat = PrematureBeatsStart;
                PrematureRuns.IsolatedRun.EndBeat = PrematureBeatsEnd;
                PrematureRuns.IsolatedRun.BlockIndex = single( find( PrematureBeatsDuration == 1 ) );
                % Packet Run
                [ ~, NumBeats, PrematureRuns.IsolatedRun ] = PacketRun( PrematureRuns.IsolatedRun, QRSComplexes, HeartRate, RecordInfo, 'Isolated');
                % Total Beat
                PrematureRuns.TotalBeats = PrematureRuns.TotalBeats + NumBeats;
                
            end

            
            %% QRS COMPLEXES 
            
            if type == 'V'
                % - flag in the premature run class
                if ~isempty( PrematureTachyRuns )
                    QRSComplexes.VTBeats = PrematureTachyRuns.BeatFlag;
                else
                    QRSComplexes.VTBeats = zeros( length( QRSComplexes.R ), 1, 'logical' );
                end
            elseif type == 'A'
                % - flag in the premature run class
                if ~isempty( PrematureTachyRuns )
                    QRSComplexes.SVTBeats = PrematureTachyRuns.BeatFlag;
                else
                    QRSComplexes.SVTBeats = zeros( length( QRSComplexes.R ), 1, 'logical' );
                end
            end
                
        end
        
        
        %% Clear Run
        
        % Clears the Run from the PrematureBeats.
        %
        % [ PrematureBeats, BlockStart, BlockEnd, BlockDuration ] = ...
        %     ClearRun( PrematureBeats, BlockStart, BlockEnd, BlockDuration, Run )
        %
        % <<< Function Inputs >>>
        %   single[n,1] PrematureBeats
        %   single[n,1] BlockStart
        %   single[n,1] BlockEnd
        %   single[n,1] BlockDuration
        %   single[n,1] Run
        %
        % <<< Function Outputs >>>
        %   single[n,1] PrematureBeats
        %   single[n,1] BlockStart
        %   single[n,1] BlockEnd
        %   single[n,1] BlockDuration
        
        function [ PrematureBeats, BlockStart, BlockEnd, BlockDuration ] = ...
                ClearRun( PrematureBeats, BlockStart, BlockEnd, BlockDuration, Run )
            
            if ~isempty( Run.BlockIndex )
                
                % Clear Blocks
                BlockStart( Run.BlockIndex ) = [ ];
                BlockEnd( Run.BlockIndex ) = [ ];
                BlockDuration( Run.BlockIndex ) = [ ];
                
                % Clear PrematureBeats
                for i = 1 : length( Run.StartBeat )
                    PrematureBeats( double( Run.StartBeat( i ) ) : double( Run.EndBeat( i ) ) ) = 0;
                end
                
            end
            
        end
        
        
    end
    
    
end

%% Sub-Function: Packet Run

function [ TotalRun, TotalBeats, Run ] = PacketRun( Run, QRSComplexes, HeartRate, RecordInfo, PVCType )

% Packets the Run
%
% Run = PacketRun( Run, HeartRate, RecordInfo, PVCType )
%
% <<< Function Inputs >>>
%   single[n,1] Run
%   struct QRSComplexes
%   single[n,1] HeartRate
%   struct RecordInfo
%   string PVCType
%
% <<< Function Outputs >>>
%   struct Run
%   .StartBeat
%   .StartTime
%   .EndBeat
%   .EndTime
%   .Duration
%   .AverageHeartRate
%   .BlockIndex

if isempty( Run ) || isempty( Run.StartBeat ) || isempty( Run.BlockIndex )
    
    % empty
    Run = [ ];
    % total run
    TotalRun = single( 0 );
    % total run
    TotalBeats = single( 0 );
    
else
    
    % Total Run
    Run.TotalRun = length( Run.StartBeat );
    TotalRun = single( Run.TotalRun );
    % Start Time
    Run.StartTime = ClassDatetimeCalculation.Summation...
        ( RecordInfo.RecordStartTime, QRSComplexes.StartPoint( Run.StartBeat) / RecordInfo.RecordSamplingFrequency );
    % End Time
    Run.EndBeat( Run.EndBeat > length( QRSComplexes.R ) ) = length( QRSComplexes.R );
    Run.EndTime = ClassDatetimeCalculation.Summation...
        ( RecordInfo.RecordStartTime, QRSComplexes.EndPoint( Run.EndBeat) / RecordInfo.RecordSamplingFrequency );
    % Heart Rate
    Run.AverageHeartRate = PeriodAverageHeartRate( HeartRate, Run.StartBeat, Run.EndBeat );
    
    % Duration
    switch PVCType
        
        case 'Isolated'
            Run.Duration = ones( length( Run.StartBeat ), 1, 'single' );
            
        case 'Bigeminy'
            Run.Duration = ceil( ( Run.EndBeat - Run.StartBeat + 1 ) / 2);
            
        case 'Trigeminy'
            Run.Duration = ceil( ( Run.EndBeat - Run.StartBeat + 1 ) / 3);
            
        case 'Quadrigeminy'
            Run.Duration = ceil( ( Run.EndBeat - Run.StartBeat + 1 ) / 4);
            
        case 'Couplet'
            Run.Duration = 2 * ones( length( Run.StartBeat ), 1, 'single' );
            
        case 'Triplet'
            Run.Duration = 3 * ones( length( Run.StartBeat ), 1, 'single' );
            
        case 'Salvo'
            Run.Duration = ( Run.EndBeat - Run.StartBeat + 1 );
            
    end
    
    % TotalBeats
    TotalBeats = single( sum( Run.Duration ) );
    
end

end


%% Sub-Function: Calculate Average Heart Rate

% Calculation of the averaged heart rate
%
% [runHeartRate] = PeriodAverageHeartRate( heartRate, runStartBeat, runEndBeat)
%
% <<< Function Inputs >>>
%   single[n,1] heartRate
%   single[n,1] runStartBeat
%   single[n,1] runEndBeat
%
% <<< Function Outputs >>>
%   single[n,1] runHeartRate

function [runHeartRate] = PeriodAverageHeartRate( heartRate, runStartBeat, runEndBeat)

% Initialization
runHeartRate = single( zeros( length( runStartBeat ), 1 ) );
% Calculation
for runIndex = single( 1 : numel(runStartBeat) )
    runHeartRate(runIndex) = round( mean(heartRate( double( runStartBeat( runIndex ) ) : double( runEndBeat( runIndex ) ) ) ) );
end

end


%% SubFunction: Get Run Info

function [ TotalRun, TotalBeats, Run ] = GetRunInfo( runs, condition )

fieldNames = fieldnames( runs );
fieldNames ( strcmp( fieldNames, 'TotalRun' ) ) = [  ];

if sum( condition )
    
    for fieldIndex = 1 : length( fieldNames )
        
        if sum( condition )
            [ Run.( fieldNames{ fieldIndex } ) ] = runs.( fieldNames{ fieldIndex } )( condition );
        else
            [ Run.( fieldNames{ fieldIndex } ) ] = [ ];
        end
        
    end
    
    Run.TotalRun = length( Run.StartBeat );
    TotalBeats = single( sum( Run.Duration ) ) ;
    TotalRun = single( Run.TotalRun );
    
else
    
    % empty
    Run = [ ];
    % total beats
    TotalBeats = single( 0 );
    % total run
    TotalRun = single( 0 );
    
end

end
