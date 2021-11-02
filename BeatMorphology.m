
function [ qrsComplexes, updatedMorphologies, noiseSample ] = BeatMorphology( ecgSignal, qrsComplexes, recordInfo )

if isempty( qrsComplexes.R )
    
    % Output
    % - qrs
    qrsComplexes.BeatMorphology = [ ];
    % - morphologies
    updatedMorphologies.BeatInterval = [ ];
    updatedMorphologies.BeatNumber = [ ];
    updatedMorphologies.Morphologies = [ ];
    % - noise sample
    noiseSample = zeros( length( ecgSignal ), 1, 'logical' );
    
else
    
    % - Correlation Threshold
    corrThreshold = 85;
    % - Morp Length
    morpLength = 76;
    % - Morp Limit
    morphLimit = 99;
    % - Beat Signal
    signalMinLength = round( length( ecgSignal ) / recordInfo.RecordSamplingFrequency );
    Morphologies.BeatSignal = zeros( signalMinLength, morpLength, 'single' );
    % - Counter
    Morphologies.BeatCounter = zeros( signalMinLength, 1, 'single' );
    % - Beat Interval
    Morphologies.BeatInterval = zeros( signalMinLength, 1, 'single' );
    % - Counter
    Morphologies.Counter = 0;
    % - QRS Complexes Beat Morphology
    qrsComplexes.BeatMorphology = zeros( length( qrsComplexes.R ), 1, 'single' );
    % Clear
    clear allocatedIndex allocatedIndex signalMinLength
    
    for beatIndex = 1 : length( qrsComplexes.R )
        
        % beat start / end point
        % - if it is a normal type of beat,
        % - reference point is the r point of the beat
        if qrsComplexes.Type( beatIndex ) > 0
            startPoint = ...
                max( ( double( qrsComplexes.R( double( beatIndex ) ) ) - double( 25 ) ), double( 1 ) );
            endPoint = ...
                min( ( double( qrsComplexes.R( double( beatIndex ) ) ) + double( 50 ) ), double( length( ecgSignal ) ) );
        else
            % - if it is a reversed type of beat,
            % - reference point is the s point of the beat
            startPoint = ...
                max( ( double( qrsComplexes.S( double( beatIndex ) ) ) - double( 25 ) ), double( 1 ) );
            endPoint = ...
                min( ( double( qrsComplexes.S( double( beatIndex ) ) ) + double( 50 ) ), double( length( ecgSignal ) ) );
        end
        % beat interval
        beatInterval = ...
            double( qrsComplexes.EndPoint( double( beatIndex ) ) ) - ...
            double( qrsComplexes.StartPoint( double( beatIndex ) ) ) + ...
            double( 1 );
        
        % beat window
        BeatWindow = ecgSignal( double( startPoint ) : double( endPoint ) );
        if length( BeatWindow ) ~= morpLength
            BeatWindow = transpose( interp1( ...
                linspace(1, morpLength, length( BeatWindow ) ), ...
                BeatWindow, ...
                ( 1 : morpLength ) ) );
        end; clear startPoint endPoint
        BeatWindow = transpose( BeatWindow );
        
        % look-at table
        if beatIndex == 1
            
            % Set in the table
            Morphologies.BeatSignal( 1, : ) = BeatWindow;
            Morphologies.BeatCounter( 1 ) = 1;
            Morphologies.BeatInterval( 1 ) = beatInterval;
            % Set the qrs morp
            qrsComplexes.BeatMorphology( beatIndex ) = -1;
            % Set counter
            Morphologies.Counter = Morphologies.Counter + 1;
            
        else
            
            % Prealllocation: Cross Correlation Values
            CrossCorrValues = zeros( Morphologies.Counter, 1, 'single' );
            % Check each morphs
            for MorphologyIndex = 1 : Morphologies.Counter
                % Get Morphology Signal
                SignalMorphology = Morphologies.BeatSignal( MorphologyIndex, : );
                % Calculate Cross Corr
                %                     CrossCorrMatrix = corrcoef( SignalMorphology, BeatWindow );
                %                     CrossCorrValues( MorphologyIndex ) = round( CrossCorrMatrix(2,1) * 100 );
                CrossCorrMatrix = CrossCorr( SignalMorphology, BeatWindow );
                CrossCorrValues( MorphologyIndex ) = round( CrossCorrMatrix * 100 );
                % Save Corr Value
                % If the current corr value is over the threshold; break
                if CrossCorrValues( MorphologyIndex ) > 90
                    break
                end
            end
            
            %             if qrsComplexes.R( beatIndex )  > 3495.5 * 250
            %                 plot_BeatMorphology; figure; plot( BeatWindow );
            %             end
            
            % Assessment
            SimilarBeatMorphologyIndex = CrossCorrValues > corrThreshold;
            
            % Add / Edit a beat morphology
            if any( SimilarBeatMorphologyIndex )
                % find the morphology with the highest correlation
                [ SimilarBeatMorphologyCorrValue, SimilarBeatMorphologyIndex ] = max( CrossCorrValues );
                % increase the counter
                Morphologies.BeatCounter( SimilarBeatMorphologyIndex ) = ...
                    Morphologies.BeatCounter( SimilarBeatMorphologyIndex ) + 1;
                % check for high correlation
                if ...
                        ( SimilarBeatMorphologyCorrValue > 90 ) && ...
                        ( Morphologies.BeatCounter( SimilarBeatMorphologyIndex ) < morphLimit )
                    % change the beat signal
                    Morphologies.BeatSignal( SimilarBeatMorphologyIndex, : ) = ...
                        0.75 * BeatWindow + 0.25 * Morphologies.BeatSignal( SimilarBeatMorphologyIndex, : );
                    % get the beat interval
                    % originalBeatInterval = Morphologies.BeatInterval( SimilarBeatMorphologyIndex );
                    Morphologies.BeatInterval( SimilarBeatMorphologyIndex ) = ...
                        0.75 * ( beatInterval ) + 0.25 * ( Morphologies.BeatInterval( SimilarBeatMorphologyIndex ) );
                else
                    % skip
                    % plot_BeatMorphology;
                end
                % // set the qrs morp
                qrsComplexes.BeatMorphology( beatIndex ) = -SimilarBeatMorphologyIndex;
                
            else
                
                %                 plot_BeatMorphology; figure; plot( BeatWindow );
                
                if Morphologies.Counter == morphLimit
                    % Change Threshold
                    corrThreshold = 80;
                    % Set counter
                    Morphologies.Counter = morphLimit + 1;
                    % Set in the table
                    Morphologies.BeatSignal( Morphologies.Counter, : ) = zeros( 1, morpLength, 'single' );
                    Morphologies.BeatCounter( Morphologies.Counter ) = 0;
                    Morphologies.BeatInterval( Morphologies.Counter ) = 0;
                    % Set the qrs morp
                    qrsComplexes.BeatMorphology( beatIndex ) = morphLimit + 1;
                elseif Morphologies.Counter > morphLimit
                    % Set the qrs morp
                    qrsComplexes.BeatMorphology( beatIndex ) = morphLimit + 1;
                else
                    % Set counter
                    Morphologies.Counter = Morphologies.Counter + 1;
                    % Set in the table
                    Morphologies.BeatSignal( Morphologies.Counter, : ) = BeatWindow;
                    Morphologies.BeatCounter( Morphologies.Counter ) = 1;
                    Morphologies.BeatInterval( Morphologies.Counter ) = beatInterval;
                    % Set the qrs morp
                    qrsComplexes.BeatMorphology( beatIndex ) = -Morphologies.Counter;
                end
                
            end
            
        end
                
    end
    
    % CLEAR EMPTY MORPS
    % // BeatSignal
    Morphologies.BeatSignal( ( Morphologies.Counter + 1 ) : end, : ) = [ ];
    % // Beat Counter
    Morphologies.BeatCounter( ( Morphologies.Counter + 1 ) : end, : ) = [ ];
    % // Beat Interval
    Morphologies.BeatInterval( ( Morphologies.Counter + 1 ) : end, : ) = [ ];
    
    % PLOT
    %     plot_BeatMorphology;
    
    % MOST SEEN QRS MORP AMPLITUDE
    [ ~, commonMorph ] = max( Morphologies.BeatCounter );
    qrsAmplitude = mean( qrsComplexes.QRSAmplitude( qrsComplexes.BeatMorphology == - commonMorph ) );
    
    % NOISE
    [ qrsComplexes, NoiseMorph, noiseSample ] = ...
        SignalNoiseBasedMorphology( 'ecgSignal', length( ecgSignal ), qrsComplexes, qrsAmplitude, recordInfo );
    
    % NOISE BEAT
    [ qrsComplexes, noiseSample ] = NoiseBeatInterval( qrsComplexes, length( ecgSignal ), noiseSample, recordInfo );
    
    % New Beat Counter
    for morphIndex = 1 : Morphologies.Counter
        % New Beat Counter
        Morphologies.BeatCounter( morphIndex ) = sum( qrsComplexes.BeatMorphology == -morphIndex );
    end
    
    % ORDER ARRANGEMENT
    % Preallocation
    % - Signal
    updatedMorphologies.Morphologies = zeros( Morphologies.Counter, morpLength, 'single' );
    % - Beat Counter
    updatedMorphologies.BeatCounter = zeros( Morphologies.Counter, 1, 'single' );
    % - Beat Interval
    updatedMorphologies.BeatInterval = zeros( Morphologies.Counter, 1, 'single' );
    % - Beat Direction
    updatedMorphologies.BeatDirection = zeros( Morphologies.Counter, 1, 'single' );
    % - Morp Counter
    MorpCounter = 0;
    % - Order
    for MorphologyIndex = 1 : Morphologies.Counter
        
        % Get the maximum count
        [ MaxCountValue, MaxCountIndex ] = max( Morphologies.BeatCounter );
        % Check End
        if MaxCountValue < 1; break; end
        if ~ismember( -MaxCountIndex, NoiseMorph )
            MorpCounter = MorpCounter + 1;
        else
            Morphologies.BeatCounter( MaxCountIndex ) = -Morphologies.BeatCounter( MaxCountIndex );
            continue
        end
        % Arrange
        updatedMorphologies.Morphologies( MorpCounter, :) = Morphologies.BeatSignal( MaxCountIndex, : );
        % Beat Interval
        updatedMorphologies.BeatInterval( MorpCounter, : ) = round( ( Morphologies.BeatInterval( MaxCountIndex ) / recordInfo.RecordSamplingFrequency ), 4 );
        % Beat Number
        updatedMorphologies.BeatCounter( MorpCounter, : ) = sum( qrsComplexes.BeatMorphology == -MaxCountIndex );
        % QRS Complex
        qrsComplexes.BeatMorphology( qrsComplexes.BeatMorphology == -MaxCountIndex ) = MorpCounter;
        % Beat Direction
        updatedMorphologies.BeatDirection( MorpCounter, : ) = sum( qrsComplexes.Type( qrsComplexes.BeatMorphology == MorpCounter ) );
        % Manipulate the beat counter
        Morphologies.BeatCounter( MaxCountIndex ) = -Morphologies.BeatCounter( MaxCountIndex );
        
    end; clear Morphologies
    
    % CLEAR EMPTY MORPS
    % // Counter
    updatedMorphologies.MorphCounter = MorpCounter;
    % // BeatSignal
    updatedMorphologies.Morphologies( ( MorpCounter + 1 ) : end, : ) = [ ];
    % // Beat Interval
    updatedMorphologies.BeatInterval( ( MorpCounter + 1 ) : end, : ) = [ ];
    % // Beat Counter
    updatedMorphologies.BeatCounter( ( MorpCounter + 1 ) : end, : ) = [ ];
    % // Beat Direction
    updatedMorphologies.BeatDirection( ( MorpCounter + 1 ) : end, : ) = [ ];
    
    % OUTPUT
    qrsComplexes.BeatMorphology = qrsComplexes.BeatMorphology - 1;
    
    %
    %
    % PLOT
    %     plot_updatedBeatMorphology;
    
end

end


%% SubFuntion: SignalNoiseBasedMorphology

function [ qrsComplexes, deletedMorphs, signalNoise ] = SignalNoiseBasedMorphology( ~, signalLength, qrsComplexes, qrsAmplitude, recordInfo )

% Initialization
signalNoise = zeros( signalLength, 1, 'logical' );

% Original Morphs
originalMorphs = unique( qrsComplexes.BeatMorphology );

% Signal length in seconds
signalLengthSecs = fix( signalLength / recordInfo.RecordSamplingFrequency );

% Beat Search Start Point
beatStartIndex = 1;

% assessment for each 10 minutes
for secondIndex = 1 : 5 : signalLengthSecs
    
    % Signal Points
    intervalStartPoint = ...
        max( double( 1 ), ( double( secondIndex - 1 ) * double( recordInfo.RecordSamplingFrequency ) + double( 1 ) ) );
    intervalEndPoint = ...
        min( double( signalLength ), ( double( secondIndex + 4 ) * double( recordInfo.RecordSamplingFrequency ) ) );
    intervalPoints = ...
        double( intervalStartPoint ) : double( intervalEndPoint );
    
    % Beat Indexes
    for beatIndex = beatStartIndex : length( qrsComplexes.R )
        if qrsComplexes.R( beatIndex ) > intervalEndPoint
            intervalBeatIndexes = beatStartIndex : ( beatIndex - 1 );
            beatStartIndex = beatIndex;
            break
        end
    end
        
    % Unique Morp
    uniqueMorps = unique( qrsComplexes.BeatMorphology( intervalBeatIndexes ) );
    
    % Small QRS Amplitude
    if qrsAmplitude < 0.5; uniqueMorpsThreshold = 7; else; uniqueMorpsThreshold = 5; end
    
    % Noise flag
    if ( length( uniqueMorps ) > uniqueMorpsThreshold ) || ( logical( sum( uniqueMorps > 0 ) ) )
        %         % Interval Signal
        %         intervalSignal = signal( intervalPoints );
        %         % Plot
        %         close all; plot( intervalSignal );
        % Rise Flag - signal
        signalNoise( intervalPoints ) = true;
        % Rise Flag - qrs
        qrsComplexes.BeatMorphology( intervalBeatIndexes ) = 1;
    end
    
end

deletedMorphs = originalMorphs( ~ismember( originalMorphs, qrsComplexes.BeatMorphology ) );

end

%% SubFunction: Noise Beat

function [ qrsComplexes, noiseSample ] = NoiseBeatInterval( qrsComplexes, signalLength, noiseSample, recordInfo )

% Beat Noise Indexes
noiseBeatIndexes = find( qrsComplexes.BeatMorphology > 0 );
% for each noise beat
for beatIndex = 1 : length( noiseBeatIndexes )
    % - start point
    startPoint = max( ...
        double( 1 ), ...
        ( double( qrsComplexes.StartPoint( noiseBeatIndexes( beatIndex ) ) ) - double( recordInfo.RecordSamplingFrequency ) ) ...
        );
    % - end point
    endPoint = min( ...
        double( signalLength ), ...
        ( double( qrsComplexes.EndPoint( noiseBeatIndexes( beatIndex ) ) ) + double( recordInfo.RecordSamplingFrequency ) ) ...
        );
    % - flag
    noiseSample( double( startPoint ) : double( endPoint ) ) = true;

end

% CLEAR QRS
% - indexes
[ ~, noiseBeatIndexes ] = intersect( qrsComplexes.R, find( noiseSample ) );
% - clear
qrsComplexes = ClassUnusualSignalDetection.ClearQRS( qrsComplexes, noiseBeatIndexes );

end


%%%%%%%%%%%%%%%%%%%%%%%%

function [ corr ] = CrossCorr( signal1, signal2 )

Ex   = sum(signal1);
Ey   = sum(signal2);
Exy = sum(signal1.*signal2);
Exx = sum(signal1.*signal1);
Eyy = sum(signal2.*signal2);
n = numel(signal1);
corr = (n*Exy - Ex*Ey) / sqrt((n*Exx -Ex*Ex)*(n*Eyy -Ey*Ey));
corr = round(corr, 4);

end