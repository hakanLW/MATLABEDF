classdef ClassPTDetection
    
    % "ClassPTDetection.m" class consists function used during P and T wave
    % detection
    %
    % > PTDetectionFilter
    % > BlockDetection
    % > BlockMerge
    % > CalculateBlockSTD
    % > CalculateBlockSlope
    % > CalculateBlockAmplitude
    % > CalculateBlockArea
    % > CalculateBlockAngle
    % > CalculateBlockDensity
    % > CalculateBlockMax
    % > EliminateBlocks
    % > CalculateRealWaveAmp
    % > GetWave
    % > WaveCharacteristic
    % >
    
    %% PROPERTIES
    
    properties
        
        %
        
    end
    
    %% STATIC METHODS
    
    methods (Static)
        
        
        %% PT Detection Filter
        
        function [ ecgSignalRaw, ecgSignalBandPassedFiltered, maPeak, maPWave ] = PTDetectionFilter( ecgSignalRaw, samplingFreq, minWidth, maxWidth  )
            
            % Filters used in P and T wave detection.
            %
            % [ecgSignal, maPeak, maPWave] = PTDetectionFilter( ecgSignal, samplingFreq )
            %
            % <<< Function Inputs >>>
            %   single[n,1] ecgSignal
            %   single samplingFreq
            %
            % <<< Function output >>>
            %   single[n,1] ecgSignal
            %   single[n,1] noBaseline
            %   single[n,1] maPeak
            %   single[n,1] maPWave
            
            
            % baseline removel
            baseline = medfilt1( ecgSignalRaw, round( samplingFreq * 0.5 ) );
            ecgSignalRaw = ecgSignalRaw - baseline;
            
            % bandpassed filter
            ecgSignalBandPassedFiltered = ClassFilter.BandPassFilter( ecgSignalRaw, [ 0.5 10 ], 1 , samplingFreq, 'filtfilt' );
            
            % moving average filters
            maPeak = ClassFilter.MovingAverageFilter( ecgSignalBandPassedFiltered, round( minWidth * samplingFreq ), true );
            maPWave = ClassFilter.MovingAverageFilter( ecgSignalBandPassedFiltered, round( maxWidth * samplingFreq ), true );
            
        end
        
        
        %% Block Detection
        
        function [blockStart, blockEnd] = BlockDetection ( maPeak, maPWave, minDuration )
            
            % Block detection.
            %
            % [blockStart, blockEnd] = BlockDetection ( maPeak, maPWave )
            %
            % <<< Function Inputs >>>
            %   single[n,1] maPeak
            %   single[n,1] maPWave
            %
            % <<< Function output >>>
            %   single[n,1] blockStart
            %   single[n,1] blockEnd
            
            % Blocks
            block = single( ( maPeak > ( maPWave) ) * 0.25 );
            block(1) = single( 0 );
            block(end) = single( 0 );
            
            % Detection
            blockEdges = single( [0; abs( diff( block ) ) > 0 ] > 0 );
            blockEdges = single( find(blockEdges == 1) );
            blockStart = single( blockEdges( 1:2:length( blockEdges ) ) );
            blockEnd = single( blockEdges( 2:2:length( blockEdges ) ) );
            blockDuration = blockEnd - blockStart;
            
            % Elimination
            blockStart( blockDuration < minDuration ) = [ ];
            blockEnd( blockDuration < minDuration ) = [ ];
            
        end
        
        
        %% Removing Blocks
        
        function  [ blockStart, blockEnd ] = RemoveBlock( blockStart, blockEnd, condition )
            
            % Blocks to be removed.
            %
            % [blockStart, blockEnd] = RemoveBlock( blockStart, blockEnd, condition )
            %
            % <<< Function Inputs >>>
            %   single[n,1] blockStart
            %   single[n,1] blockEnd
            %   boolean condition
            %
            % <<< Function output >>>
            %   single[n,1] blockStart
            %   single[n,1] blockEnd
            
            if ~isempty( blockStart )
                % remove blocks
                blockStart( condition ) = [ ];
                blockEnd( condition ) = [ ];
            end
            
        end
        
        
        %% Block Merge
        
        function  [ blockStart, blockEnd ] = BlockMerge( blockStart, blockEnd )
            
            % Blocks to be removed.
            %
            % [blockStart, blockEnd] = BlockMerge( blockStart, blockEnd )
            %
            % <<< Function Inputs >>>
            %   single[n,1] blockStart
            %   single[n,1] blockEnd
            %
            % <<< Function output >>>
            %   single[n,1] blockStart
            %   single[n,1] blockEnd
            
            slideStart = blockStart( 2:end );
            slideEnd = blockEnd( 1:end-1 );
            slideNeg = slideStart - slideEnd;
            
            block2Merge = find(slideNeg <= 0);
            
            blockEnd( block2Merge ) = [ ];
            blockStart( block2Merge + 1 ) = [ ];
            
        end
        
        
        %% Calculate Standart Deviation
        
        function sd = CalculateBlockSTD( blockStart, blockEnd, maPeak, maPWave )
            
            % To calculate standard deviation of maPeak and maPWave signals
            % in each blocks.
            %
            % sd = CalculateBlockSTD( blockStart, blockEnd, maPeak, maPWave )
            %
            % <<< Function Inputs >>>
            %   single[n,1] blockStart
            %   single[n,1] blockEnd
            %   single[n,1] maPeak
            %   single[n,1] maPWave
            %
            % <<< Function output >>>
            %   single[n,1] sd
            
            % Initialization
            sd = ones( length( blockStart ), 1, 'single' );
            
            % Calculation
            if ~isempty( blockStart )
                
                for blockIndex = 1 : length( blockStart )
                    
                    signal = maPeak( ( blockStart( blockIndex ) : blockEnd( blockIndex ) ) ) - maPWave( ( blockStart( blockIndex ) : blockEnd( blockIndex ) ) );
                    sd( blockIndex, 1 ) = std( signal );
                    
                end
                
                % Rounding
                sd( isnan( sd ) ) = 0;
                sd = round( sd, 3 );
                
            else
                
                sd = [ ];
                
            end
            
        end
        
        
        %% Calculate Block Slope
        
        function slopeValue = CalculateBlockSlope( blockStart, blockEnd, signal )
            
            % To calculate the wave slope in each blocks.
            %
            % slopeValue = CalculateBlockSlope( blockStart, blockEnd, signal )
            %
            % <<< Function Inputs >>>
            %   single[n,1] blockStart
            %   single[n,1] blockEnd
            %   single[n,1] signal
            %
            % <<< Function output >>>
            %   single[n,1] slopeValue
            
            % Initialization
            slopeValue = ones( length( blockStart ), 1, 'single' );
            
            % Calculation
            if ~isempty( blockStart )
                
                for blockIndex = 1 : length( blockStart )
                    
                    blockFilteredSignal = signal( blockStart( blockIndex ) : blockEnd( blockIndex ) );
                    [peakValue, deltaT] = max( blockFilteredSignal );
                    startValue = blockFilteredSignal(1); startValue( isnan( startValue ) ) = single( 0 );
                    stopValue = blockFilteredSignal(end);
                    startSlope = ( peakValue - startValue ) / ( deltaT - 1);
                    stopSlope = ( peakValue - stopValue) / ( length( blockFilteredSignal ) - deltaT);
                    slopeValue( blockIndex, 1 ) = ( startSlope + stopSlope )/2;
                    
                end
                
                slopeValue( isnan( slopeValue ) ) = single( 0 );
                
            else
                
                slopeValue = [ ];
                
            end
            
        end
        
        
        %% Calculate Block Amplitude
        
        function ampValue = CalculateBlockAmplitude( blockStart, blockEnd, signal )
            
            % tTo calculate the wave amplitude in each blocks.
            %
            % ampValue = CalculateBlockAmplitude( blockStart, blockEnd, signal )
            %
            % <<< Function Inputs >>>
            %   single[n,1] blockStart
            %   single[n,1] blockEnd
            %   single[n,1] signal
            %
            % <<< Function output >>>
            %   single[n,1] ampValue
            
            % Initialization
            ampValue = ones( length( blockStart ), 1, 'single' );
            
            % Calculation
            if ~isempty( blockStart )
                
                for blockIndex = 1 : length( blockStart )
                    
                    blockSignal= signal( ( blockStart( blockIndex ) ) : ( blockEnd ( blockIndex ) ) );
                    ampValue( blockIndex, 1 ) = max(blockSignal) - min(blockSignal);
                    
                end
                
            else
                
                ampValue = [ ];
                
            end
            
        end
        
        
        %% Calculate Block Area
        
        function waveArea = CalculateBlockArea( blockStart, blockEnd, signal )
            
            % To calculate area of the wave in the block.
            %
            % waveArea = CalculateBlockArea( blockStart, blockEnd, signal )
            %
            % <<< Function Inputs >>>
            %   single[n,1] blockStart
            %   single[n,1] blockEnd
            %   single[n,1] signal
            %
            % <<< Function output >>>
            %   single[n,1] waveArea
            
            % Initialization
            %             signal = ClassFilter.HighPassFilter( signal, 1, 1, 250, 'filtfilt' );
            waveArea = ones( length( blockStart ), 1, 'single' );
                        
            % Calculation
            if ~isempty( blockStart )
                
                for blockIndex = single( 1 : length( blockStart ) )
                    
                    %                     waveArea( blockIndex ) =  trapz( signal ( ( blockStart( blockIndex ) ) : ( blockEnd ( blockIndex ) )  ) ) ;
                    %                     blockArea =  trapz( signal ( ( blockStart( blockIndex ) ) : ( blockEnd ( blockIndex ) )  ) ) ;
                    %                     waveArea( blockIndex ) = blockArea - trapz( [blockStart( blockIndex ) blockEnd( blockIndex )], ...
                    %                         [signal( blockStart( blockIndex ) ) signal( blockEnd( blockIndex ) ) ] );
                    waveSignal = signal ( ( blockStart( blockIndex ) ) : ( blockEnd ( blockIndex ) ) );          
                    % waveSignal = waveSignal - min( waveSignal );
                    % close all; figure; plot( waveSignal )
                    waveArea( blockIndex ) =  trapz( waveSignal ) ;
                    
                end
                
            else
                
                waveArea = single( [ ] );
                
            end
            
        end
        
        
        %% Calculate Block Angle
        
        function waveAngle = CalculateBlockAngle( blockStart, blockEnd, signal )
            
            % To calculate the angle between the begining and end of the wave in the block.
            %
            % waveAngle = CalculateBlockAngle( blockStart, blockEnd, signal )
            %
            % <<< Function Inputs >>>
            %   single[n,1] blockStart
            %   single[n,1] blockEnd
            %   single[n,1] signal
            %
            % <<< Function output >>>
            %   single[n,1] waveAngle
            
            % Initialization
            waveAngle = ones( length( blockStart ), 1, 'single' );
            
            % Calculation
            if ~isempty( blockStart )
                
                waveDuration = blockEnd - blockStart;
                
                for blockIndex = single( 1 : length( blockStart ) )
                    
                    waveEdgeAmplitude = signal( blockEnd( blockIndex) ) - signal( blockStart( blockIndex ) );
                    waveAngle( blockIndex ) = ClassSlope.CalculateAngle( waveEdgeAmplitude, waveDuration( blockIndex ) );
                    
                end
                
            else
                
                waveAngle = single( [ ] );
                
            end
            
        end
        
        
        %% Calculate Block Density
        
        function [waveDensity, waveArea] = CalculateBlockDensity( blockStart, blockEnd, signal )
            
            % To calculate the density of the wave are in the block.
            %
            % [waveDensity, waveArea] = CalculateBlockDensity( blockStart, blockEnd, signal )
            %
            % <<< Function Inputs >>>
            %   single[n,1] blockStart
            %   single[n,1] blockEnd
            %   single[n,1] signal
            %
            % <<< Function output >>>
            %   single[n,1] waveDensity
            %   single[n,1] waveArea
            
            % Calculation
            if ~isempty( blockStart )
                
                waveArea = ClassPTDetection.CalculateBlockArea( blockStart, blockEnd, signal );
                blockDuration = blockEnd - blockStart;
                waveDensity  = ( waveArea * 1000 ) ./ ( blockDuration .^ 2 );
                
            else
                
                waveArea = single( [ ] );
                waveDensity = single( [ ] );
                
            end
            
        end
        
        
        %% Calculate Block Max Points
        
        function [ waveMaxPoint, waveMaxValue ] = CalculateBlockMax( blockStart, blockEnd, signal )
            
            % To calculate the max point in the wave are in the block.
            %
            % [ waveMaxPoint ] = CalculateBlockMax( blockStart, blockEnd, signal )
            %
            % <<< Function Inputs >>>
            %   single[n,1] blockStart
            %   single[n,1] blockEnd
            %   single[n,1] signal
            %
            % <<< Function output >>>
            %   single[n,1] waveMaxPoint
            
            % Initialization
            waveMaxPoint = zeros( length( blockStart ), 1, 'single' );
            waveMaxValue = zeros( length( blockStart ), 1, 'single' );
            
            % Calculation
            if ~isempty( blockStart )
                
                for blockIndex = 1 : length( blockStart )
                    
                    [ waveMaxValue(blockIndex) , waveMaxPoint( blockIndex ) ] = max( signal( blockStart( blockIndex ) : blockEnd( blockIndex ) ) );
                    waveMaxPoint( blockIndex ) = waveMaxPoint( blockIndex ) + blockStart( blockIndex ) - 1;
                    
                end
                
            else
                
                waveMaxPoint = single( [ ] );
                waveMaxValue = single( [ ] );
                
            end
            
        end
        
        
        %% Degrade the Number of the Detected Blocks
        
        
        function [ blockStart, blockEnd ] = EliminateBlocks( blockStart, blockEnd, sortParameter, numbBlock )
            
            % To sort detected blocks according to their sortParameter.
            %
            % [ blockStart, blockEnd ] = EliminateBlocks( blockStart, blockEnd, sortParameter, numbBlock )
            %
            % <<< Function Inputs >>>
            %   single[n,1] blockStart
            %   single[n,1] blockEnd
            %   single[n,1] sortParameter
            %   single numbBlock
            %
            % <<< Function output >>>
            %   single[n,1] blockStart
            %   single[n,1] blockEnd
            
            % sort STDs
            [ ~, sortedIndexes ] = sort( sortParameter, 'descend' );
            if length( sortedIndexes  ) > numbBlock
                sortedIndexes = sortedIndexes( 1 : numbBlock );
            end
            sortedIndexes = sort( sortedIndexes );
            
            % sort blocks
            blockStart = blockStart( sortedIndexes );
            blockEnd = blockEnd( sortedIndexes );
            
        end
        
        
        %% Calculate Real Amp
        
        function waveAmplitude = CalculateRealWaveAmp( wave, signal )
            
            % Calculation of the real amplitude of a wave based on the its peak and its angle.
            %
            % waveAmplitude = CalculateRealWaveAmp( wave, signal )
            %
            % <<< Function Inputs >>>
            %   single[n,1] wave
            %   single[n,1] signal
            %
            % <<< Function output >>>
            %   single[n,1] waveAmplitude
            
            % Rising length of the wave
            risingDuration = ( wave.Peak - wave.Start ) / 10;
            risingAmplitude = ( signal( wave.Peak ) - signal( wave.Start ) ) / 0.1;
            risingLength = sqrt( risingDuration^2 + risingAmplitude^2 );
            
            % Descending length of the wave
            descendingDuration = ( wave.End - wave.Peak ) / 10;
            descendingAmplitude = ( signal( wave.Peak ) - signal( wave.End ) ) / 0.1;
            descendingLength = sqrt( descendingDuration^2 + descendingAmplitude^2 );
            
            % Hipotalamus length
            blockDuration = ( wave.End - wave.Start ) / 10;
            blockAmplitude = ( signal( wave.Start ) - signal( wave.End ) ) / 0.1;
            blockLength = sqrt( blockDuration^2 + blockAmplitude^2 );
            
            % Rising Angle
            risingAngle =  (  descendingLength^2 - risingLength^2 - blockLength^2  ) / (  - 2*risingLength*blockLength );
            risingAngle = acosd( risingAngle );
            
            % Real Amplitude of the Wave in terms of box size
            waveAmplitude = risingLength * sind( risingAngle );
            % Real Amplitude of the Wave in terms of voltage
            waveAmplitude = waveAmplitude * 0.1;
            
            if isnan( waveAmplitude )
                waveAmplitude = 0;
            end
            
        end
        
        
        %% Wave Characterization
        
        function [wave] = GetWave(bufferSignal, waveStart, waveEnd )
            
            % To find the begining and end of each wave.
            %
            % [wave] = WaveCharacteristic(bufferStart, minLimit, maxLimit, bufferSignal, waveStart, waveEnd, type )
            %
            % <<< Function Inputs >>>
            %   single bufferStart
            %   single minLimit
            %   single maxLimit
            %   single[n,1] bufferSignal
            %   single waveStart
            %   single waveEnd
            %   char type
            %
            % <<< Function output >>>
            %   struct wave
            
            if ~isempty( waveStart )
                
                % initialization
                bufferSignal = round( bufferSignal, 2 );
                
                % limit initialization
                searchStartPoint = max( ( waveStart - 40 + 1), 1 );
                searchEndPoint = min( ( waveStart + 40 + 1), length( bufferSignal ) );
                
                % wave end
                waveEndSignal = diff( bufferSignal( waveEnd : searchEndPoint ) );
                waveEndPoint( :, 1) = waveEndSignal( 1:end-1 );
                waveEndPoint( :, 2) = waveEndSignal( 2:end );
                waveEndPoint = find( waveEndPoint(:,1) >= 0 & waveEndPoint(:,2) >= 0, 1, 'first') ;
                if ~isempty( waveEndPoint )
                    waveEndPoint = waveEnd + waveEndPoint - 2;
                else
                    waveEndPoint = searchEndPoint;
                end
                
                % wave start
                waveStartSignal = diff( bufferSignal( waveStart : -1 : searchStartPoint ) );
                waveStartPoint( :, 1) = waveStartSignal( 1:end-1 );
                waveStartPoint( :, 2) = waveStartSignal( 2:end );
                waveStartPoint = find( waveStartPoint(:,1) >= 0 & waveStartPoint(:,2) >= 0, 1, 'first') ;
                if ~isempty( waveStartPoint )
                    waveStartPoint = waveStart - waveStartPoint + 2;
                else
                    waveStartPoint = searchStartPoint;
                end
                
                % store
                if ( waveEndPoint - waveStartPoint ) < 5
                    wave.Start = 1;
                    wave.End = 1;
                else
                    % - start
                    wave.Start = waveStartPoint;
                    % - end
                    wave.End = waveEndPoint;
                end
                
            else
                wave.Start = 1;
                wave.End = 1;
                
            end
            
            
        end
        
        
        %% Wave Characterization
        
        function [wave] = WaveCharacteristic(bufferStart, minLimit, maxLimit, bufferSignal, waveStart, waveEnd, type )
            
            % To find the begining and end of each wave.
            %
            % [wave] = WaveCharacteristic(bufferStart, minLimit, maxLimit, bufferSignal, waveStart, waveEnd, type )
            %
            % <<< Function Inputs >>>
            %   single bufferStart
            %   single minLimit
            %   single maxLimit
            %   single[n,1] bufferSignal
            %   single waveStart
            %   single waveEnd
            %   char type
            %
            % <<< Function output >>>
            %   struct wave
            
            if ~isempty( waveStart )
                
                % initialization
                bufferSignal = round( bufferSignal, 2 );
                % narrow initial wave
                waveStart = waveStart - 2;
                waveEnd = waveEnd + 2;
                minLimit = minLimit - bufferStart + 1; if minLimit < 1; minLimit = 1; end
                maxLimit = maxLimit - bufferStart + 1; if maxLimit > length( bufferSignal ); maxLimit = length( bufferSignal ); end
                
                % limit initialization
                if type == 'T'; searchLimit = single( 30 );
                elseif type == 'P'; searchLimit = single( 20 );
                end
                searchStartPoint = waveStart - searchLimit + 1; if searchStartPoint < minLimit; searchStartPoint = minLimit; end
                searchEndPoint = waveEnd + searchLimit - 1;  if searchEndPoint > maxLimit; searchEndPoint = maxLimit; end
                
                % wave end
                waveEndSignal = bufferSignal( waveEnd : 1 : searchEndPoint );
                waveEndSignal = diff( waveEndSignal );
                waveEndSignal( waveEndSignal < 0 ) = -1;
                waveEndSignal( waveEndSignal >= 0 ) = 1;
                waveEndPoint( :, 1) = waveEndSignal( 1:end-1 );
                waveEndPoint( :, 2) = waveEndSignal( 2:end );
                waveEndPoint = find( waveEndPoint(:,1) == 1 & waveEndPoint(:,2) == 1, 1, 'first') ;
                if ~isempty( waveEndPoint )
                    waveEndPoint = waveEnd + waveEndPoint - 2;
                else
                    waveEndPoint = searchEndPoint;
                end
                
                % wave start
                waveStartSignal = bufferSignal( waveStart : -1 : searchStartPoint );
                waveStartSignal = diff( waveStartSignal );
                waveStartSignal( waveStartSignal < 0 ) = -1;
                waveStartSignal( waveStartSignal >= 0 ) = 1;
                waveStartPoint( :, 1) = waveStartSignal( 1:end-1 );
                waveStartPoint( :, 2) = waveStartSignal( 2:end );
                waveStartPoint = find( waveStartPoint(:,1) == 1 & waveStartPoint(:,2) == 1, 1, 'first') ;
                if ~isempty( waveStartPoint )
                    waveStartPoint = waveStart - waveStartPoint + 2;
                else
                    waveStartPoint = searchStartPoint;
                end
                
                % store
                if ( waveEndPoint - waveStartPoint ) < 5
                    wave.Peak = 1;
                    wave.Start = 1;
                    wave.End = 1;
                else
                    % - start
                    wave.Start = waveStartPoint + bufferStart - 1;
                    % - end
                    wave.End = waveEndPoint + bufferStart - 1;
                    % - peak
                    [~, wave.Peak] = max( bufferSignal( waveStartPoint:waveEndPoint ) );
                    wave.Peak = wave.Peak + waveStartPoint - 1;
                    wave.Peak = wave.Peak + bufferStart;
                end
                
            else
                wave.Peak = 1;
                wave.Start = 1;
                wave.End = 1;
                
            end
            
            
        end
        
        
        
    end
    
    
end


