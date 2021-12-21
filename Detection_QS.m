
% QS Detection Algorithm
%
% function [ qrsComplexes ] = ...
%     Detection_QS( ecgSignals , analysisChannel, qrsComplexes, ventricularEctopicRun, recordInfo )
%
% <<< Function Inputs >>>
%   struct ecgSignals
%   string analysisChannel
%   struct qrsComplexes
%   struct ventricularEctopicPoints
%   struct recordInfo
%
% <<< Function outputs >>>
%   struct qrsComplexes
%

function [ qrsComplexes ] = ...
    Detection_QS( ecgSignal2Analyze, qrsComplexes, recordInfo )


%% INITIALIOZTION

% Threshold Change Controller
isThresholdCalculated = ...
    false;
% - Total Beat Number
numbBeats = ...
    length( qrsComplexes.R );
% - Signal Length
signalLength = ...
    length( ecgSignal2Analyze );
% - Preallocations
qrsStartPoints = ...
    ones( numbBeats, 1, 'single' );
qrsQPoints = ...
    ones( numbBeats, 1, 'single' );
qrsSPoints = ...
    ones( numbBeats, 1, 'single' );
qrsEndPoints = ...
    ones( numbBeats, 1, 'single' );
qrsPointSummations = ...
    zeros( numbBeats, 1, 'single' );
qrsPeakAngle = ...
    zeros( numbBeats, 1, 'single' );
jPointValue = ...
    ones( numbBeats, 1, 'single' );
stChange = ...
    ones( numbBeats, 1, 'single' );
qrsAmplitude = ...
    zeros( numbBeats, 1, 'single' );


%% START POINT, Q, S and END POINT DETECTION

if ~isempty( qrsComplexes.R )
    
    %     close all;
    %     figure;
    %     subplot( 2,1,1 )
    %     plot( ecgSignal2Analyze ); hold on;
    %     stemSignal = zeros( signalLength, 1, 'single' );
    %     for i = 1 : numbBeats
    %         stemSignal( qrsComplexes.R( i ) ) = 1;
    %     end
    %     stem( stemSignal, 'LineWidth', 2 )
    %     subplot( 2,1,2 )
    %     plot( ecgSignal2Analyze ); hold on;
    %     stemSignal = zeros( signalLength, 1, 'single' );
    %     for i = 1 : numbBeats
    %         stemSignal( qrsComplexes.R( i ) ) = 1 * qrsComplexes.Type( i );
    %     end
    %     stem( stemSignal, 'LineWidth', 2 )
    
    % find Q and S points for each beat
    for peak = double ( 1 : numbBeats ) % last R is not interesterd
        
        % PREVIOUS BEAT
        if peak > 1
            % CHECK:    If the beat whose index is "peak - 1" has a 1
            % value, that means that the beat indexed as "peak - 1" was
            % ignored according to the previously made assessments
            if qrsComplexes.R( peak - 1 ) ~= 1
                % If the previous beat was not indexed as "1", that beat
                % is determined as previous beat
                previousBeat = peak - 1;
                previousBeatRemoved = false;
            else
                % If the previous beat was indexed as "1", search for the
                % latest beat with indexed something does not equal to "1".
                previousBeat = find( qrsComplexes.R( 1 : double( peak - 1 ) ) ~= 1, 1, 'last');
                previousBeatRemoved = false;
            end
            
        else
            % previousBeat
            previousBeat = [ ];
            previousBeatRemoved = false;
        end
        
        
        % CHARACTERISTIC POINT SEARCH WINDIW
        if qrsComplexes.Type( peak ) <= 0
            % QRS window range for reversed type beats.
            % - start point
            qrsWindowStart = ...
                max( double( qrsComplexes.R( peak ) - round( 0.050 * recordInfo.RecordSamplingFrequency ) ), double( 1 ) );
            % - end point
            qrsWindowEnd = ...
                min( double( qrsComplexes.R( peak ) + round( 0.250 * recordInfo.RecordSamplingFrequency ) ), double( signalLength ) );
            % QRS Window
            qrsWindow = ecgSignal2Analyze( double( qrsWindowStart ) : double( qrsWindowEnd ) );
            qrsWindowLength = length( qrsWindow );
        else
            % QRS window range for normal type beats.
            % - start point
            qrsWindowStart = ...
                max( double( qrsComplexes.R( peak ) - round( 0.150 * recordInfo.RecordSamplingFrequency ) ), double( 1 ) );
            % - end point
            qrsWindowEnd = ...
                min( double( qrsComplexes.R( peak ) + round( 0.250 * recordInfo.RecordSamplingFrequency ) ), double( signalLength ) );
            % QRS Window
            qrsWindow = ecgSignal2Analyze( double( qrsWindowStart ) : double( qrsWindowEnd ) );
            qrsWindowLength = length( qrsWindow );
        end
        
        
        % QRS WINDOW // R POINT
        qrsWindowRPoint = ...
            double( qrsComplexes.R( peak ) - qrsWindowStart + 1);
        qrsWindowRValue ...
            = qrsWindow( qrsWindowRPoint );
        
        
        % RE-POSITION OF THE R POINT
        if ...
                ... % If a previousBeat has been found, then the rr-interval can be calculated.
                ~isempty( previousBeat ) ...
                ... % Check the rr-interval
                && ( ( qrsComplexes.R( peak ) - qrsEndPoints( previousBeat ) ) > 0.360 * recordInfo.RecordSamplingFrequency )
            % Get the local peak paramter
            [ tempMaxValue, tempMaxIndex ] = max( qrsWindow( double( 1 ) : double( qrsWindowRPoint ) ) );
            % If the local peak value is higher than the current R point value;
            if ( tempMaxValue > qrsWindowRValue + 0.1 )
                % Calculate the local peak angle
                AngleBetweenPeaks = ClassSlope.CalculateAngle( ( tempMaxValue - qrsWindowRValue ), ( qrsWindowRPoint - tempMaxIndex ) );
                % If the local peak angle is higher than the threshold,
                if AngleBetweenPeaks > 75
                    % Define the new r point
                    qrsWindowRPoint = tempMaxIndex;
                    qrsComplexes.R( peak ) = qrsWindowStart + tempMaxIndex - 1;
                end
            end
        end
        
        
        % QR AMPLITUDE
        qrRange = ...
            max( double( qrsWindowRPoint - round( 0.100 * recordInfo.RecordSamplingFrequency) + 1 ), double( 1 ) );
        qrAmplitude = ...
            qrsWindow( qrsWindowRPoint ) - min( qrsWindow( double( qrsWindowRPoint ) : double( -1 ) : double( qrRange ) ) );
        
        
        % RS AMPLITUDE
        rsRange = ...
            min( double( qrsWindowRPoint + round(0.150*recordInfo.RecordSamplingFrequency) - 1 ), qrsWindowLength );
        rsAmplitude= ...
            qrsWindow(qrsWindowRPoint) - min( qrsWindow( double( qrsWindowRPoint ) : double( 1 ) : double( rsRange ) ) );
        
        
        %% StartPoint and Q Detection
        
        %         if qrsComplexes.R( peak ) > 0 * 250
        %             plot_qs;
        %         end
        
        % IF QR AMPLITUDE IS HIGHER THAN THE THRESHOLD:
        % - Detection_Q Algorithm runs
        if ( qrAmplitude >= 0.15 )
            
            % qrsStartPoint and q detection
            [ ...
                qrsWindowStartPoint, ...
                qrsWindowQPoint ...
                ] = Detection_Q( qrsWindow, qrsWindowRPoint, qrAmplitude, recordInfo.RecordSamplingFrequency );
            
            % CHECK: if QR slope is lower than 45 degrees,
            % Q and StartPoint are positioned at R point.
            if ~ClassNotchEvaluation.Slope( qrsWindow, qrsWindowRPoint, qrsWindowQPoint, single( 45 ) )
                % - start point
                qrsWindowStartPoint = ...
                    qrsWindowRPoint;
                % - q point
                qrsWindowQPoint = ...
                    qrsWindowRPoint;
            end
            
        else
            % IF QR AMPLITUDE IS LOWER THAN THE THRESHOLD:
            % - WaveDetection Algortihm runs
            
            % Determination of the sub-Window
            % - start point
            minLimit = ...
                max( double( qrsWindowRPoint - 15 ), double( 1 ) );
            % - end point
            maxLimit = ...
                min( double( qrsWindowRPoint + 15 ), double( qrsWindowLength ) );
            % Wave Detection
            [ qrsWave] =  ClassPTDetection.WaveCharacteristic( ...
                1, ... % bufferStart
                minLimit, ... % minLimit
                maxLimit, ... % maxLimit
                qrsWindow, ...% bufferRawSignal
                qrsWindowRPoint - 5, ... % waveStart
                qrsWindowRPoint + 5, ...
                'P'); % waveEnd
            
            % Annotation
            qrsWindowStartPoint = ...
                qrsWave.Start;
            qrsWindowQPoint = ...
                qrsWave.Start;
            
        end
        
        %% S and EndPoint Detection
        
        if  ( rsAmplitude >= 0.15 )
            
            [ ...
                qrsWindowEndPoint, ...
                qrsWindowSPoint ...
                ] = Detection_S( qrsWindow, qrsWindowRPoint, qrsComplexes.Type( peak ), qrAmplitude, rsAmplitude, qrsWindow( qrsWindowQPoint ), recordInfo.RecordSamplingFrequency );
            
        else
            
            if ( qrAmplitude >= 0.15 )
                
                % Determination of the sub-Window
                % - start point
                minLimit = ...
                    max( double( qrsWindowRPoint - 15 ), double( 1 ) );
                % - end point
                maxLimit = ...
                    min( double( qrsWindowRPoint + 15 ), double( qrsWindowLength ) );
                % Wave Detection
                [ qrsWave] =  ClassPTDetection.WaveCharacteristic( ...
                    1, ... % bufferStart
                    minLimit, ... % minLimit
                    maxLimit, ... % maxLimit
                    qrsWindow, ...% bufferRawSignal
                    qrsWindowRPoint - 5, ... % waveStart
                    qrsWindowRPoint + 5, ...
                    'P'); % waveEnd
                
                qrsWindowSPoint = ...
                    qrsWave.End;
                qrsWindowEndPoint = ...
                    qrsWave.End;
                
            else
                
                qrsWindowSPoint = ...
                    qrsWave.End;
                qrsWindowEndPoint = ...
                    qrsWave.End;
                
            end
            
        end
        
        if ( rsAmplitude >= 0.15 ) && ( abs( qrsWindowEndPoint - qrsWindowRPoint ) < 5 )
                        
            % Determination of the sub-Window
            % - start point
            minLimit = ...
                max( double( qrsWindowRPoint - 15 ), double( 1 ) );
            % - end point
            maxLimit = ...
                min( double( qrsWindowRPoint + 15 ), double( qrsWindowLength ) );
            % Wave Detection
            [ qrsWave] =  ClassPTDetection.WaveCharacteristic( ...
                1, ... % bufferStart
                minLimit, ... % minLimit
                maxLimit, ... % maxLimit
                qrsWindow, ...% bufferRawSignal
                qrsWindowRPoint - 5, ... % waveStart
                qrsWindowRPoint + 5, ...
                'P'); % waveEnd
            
            qrsWindowSPoint = ...
                qrsWave.End;
            qrsWindowEndPoint = ...
                qrsWave.End;
            
        end
        
        %%  Signal Annotation
        
        % Characteristic Point in Signal
        % - start point
        qrsWindowStartPoint = ...
            double( qrsWindowStart ) + double( qrsWindowStartPoint ) - double( 1 );
        % - q point
        qrsWindowQPoint = ...
            double( qrsWindowStart ) + double( qrsWindowQPoint ) - double( 1 );
        % - s point
        qrsWindowSPoint = ...
            double( qrsWindowStart ) + double( qrsWindowSPoint ) - double( 1 );
        % - end point
        qrsWindowEndPoint = ...
            double( qrsWindowStart ) + double( qrsWindowEndPoint ) - double( 1 );
        
        
        %%   REPOSITION OF R and ANGLE CALCULATION
        
        % reposition
        [ maxValueInQRS, maxValueInQRSIndex ] = max( ecgSignal2Analyze( double( qrsWindowStartPoint ) : double( qrsWindowSPoint ) ) );
        if ( ( maxValueInQRS - single( 0.10 ) ) >= single( ecgSignal2Analyze( ( qrsComplexes.R( peak ) ) ) ) ) && ~( qrsComplexes.R(peak) == 1 )
            qrsComplexes.R(peak) = maxValueInQRSIndex + qrsWindowStartPoint - 1;
        end
        
        % peak angle
        qrsPeakAngle( peak ) = ...
            ClassSlope.CalculateAngle( ...
            diff( ecgSignal2Analyze( [ qrsWindowSPoint; qrsComplexes.R( peak ) ] ) ), ...
            abs( diff( [ qrsWindowSPoint; qrsComplexes.R( peak ) ] ) ) ...
            );
        
        
        %% QRS PointSummation
        
        qrsPointSummation = ...
            ... Summation of the points in the QRS window, referenced to the starting point of the beat
            sum( ecgSignal2Analyze( double( qrsWindowStartPoint ) : double( qrsWindowEndPoint ) ) - ecgSignal2Analyze( double( qrsWindowStartPoint ) ) ) ;
        
        
        %% QRS Amplitude
        
        currentQRSAmplitude = ...
            ... Peak Point = R point of the QRS
            ecgSignal2Analyze( double( qrsComplexes.R( peak ) ) ) - ...
            ... Low Point = The point that has the minimum value, Q or S point of the QRS
            min( [ ecgSignal2Analyze( double( qrsWindowQPoint ) ) ecgSignal2Analyze( double( qrsWindowSPoint ) ) ] );
        
        
        %% PLOT
        
        %         if qrsComplexes.R( peak ) > 316 * 250
        %             plot_qs;
        %         end
        
        
        %% QRS ASSESMENT
        
        % Initialization
        removeBeat = false;
        
        % QRS Amplitude
        if currentQRSAmplitude < 0.01
            removeBeat = true;
        end
        
        % Low Angle
        if ~removeBeat && ( peak > 1 ) && ( peak ~= numbBeats )
            % Heart Rate
            qrsHeartRate = ClassRhythmAnalysis.CalculateHeartRate( qrsComplexes.R( peak-1 : peak+1 ), recordInfo.RecordSamplingFrequency );
            % Assessment
            if any( qrsHeartRate > 175 )
                % Angle of the current beat
                AngleCurrent = ClassSlope.CalculateAngle( ...
                    diff( ecgSignal2Analyze( [ qrsWindowSPoint; qrsComplexes.R( peak ) ] ) ), ...
                    abs( diff( [ qrsWindowSPoint; qrsComplexes.R( peak ) ] ) ) ...
                    );
                if AngleCurrent < 45
                    removeBeat = true;
                end
            end
        end
        
        % Assessment
        if  ~removeBeat && ( peak > 5 ) && ( peak ~= numbBeats )
            
            % - - - - QRS & R AMPLITUDE
            if ( isThresholdCalculated ) && (meanQRSAmplitude > 0.50 )
                if ... QRS amplitude change
                        ( currentQRSAmplitude > meanQRSAmplitude * 5 ) || ...
                        ( currentQRSAmplitude * 5 < meanQRSAmplitude ) || ...
                        ( abs( currentQRSAmplitude ) < 0.20 )
                    removeBeat = true;
                end
            end
            
            
            % - - - - QRS TYPE CONDITION
            if ( ~removeBeat )
                
                % qrs type
                qrsTypeCondition = ... If QRS' R point and the end of the QRS is the same,
                    ( qrsComplexes.R( peak ) == qrsWindowEndPoint );
                qrsTypeCondition = ... If QRS' R Point is in the point with Q and the start of the QRS,
                    qrsTypeCondition || ( ( qrsComplexes.R(peak) == qrsWindowQPoint ) && ( qrsComplexes.R(peak) == qrsWindowSPoint ) );
                qrsTypeCondition = ... If QRS is line with a high slope
                    qrsTypeCondition || ( ( qrsComplexes.R(peak) == qrsWindowStartPoint ) && ( qrsWindowSPoint == qrsWindowEndPoint) );
                
                % if the qrs is an artifact
                if qrsTypeCondition
                    removeBeat = true;
                end
                
            end
            
            % DELETION OF THE T WAVES DETECTED AS QRS
            % Assesment: Based on the angle change.
            if ~removeBeat && ~isempty( previousBeat ) && ( peak > 2 ) && ( peak ~= numbBeats ) && exist('meanQRSAmplitude','var')  && ( meanQRSAmplitude > 0.50 )
                
                if ... RR Interval Condition
                        ( qrsComplexes.R( peak ) - qrsComplexes.R(previousBeat) ) <= ( 0.300*recordInfo.RecordSamplingFrequency )
                    
                    % Angle of the previous beat
                    AnglePrevious = ClassSlope.CalculateAngle( ...
                        diff( ecgSignal2Analyze( [ qrsSPoints( previousBeat ); qrsComplexes.R( previousBeat ) ] ) ), ...
                        abs( diff( [ qrsSPoints( previousBeat ); qrsComplexes.R( previousBeat ) ] ) ) ...
                        );
                    % Angle of the current beat
                    AngleCurrent = ClassSlope.CalculateAngle( ...
                        diff( ecgSignal2Analyze( [ qrsWindowSPoint; qrsComplexes.R( peak ) ] ) ), ...
                        abs( diff( [ qrsWindowSPoint; qrsComplexes.R( peak ) ] ) ) ...
                        );
                    % Angle change
                    AngleChange = ( min( [ AnglePrevious; AngleCurrent ] ) / max( [ AnglePrevious; AngleCurrent ] ) );
                    
                    if ( AnglePrevious > 90 ) || ( AngleCurrent < 75 )
                        if ( AngleChange < 0.90 ) 
                            if AngleCurrent < AnglePrevious
                                removeBeat = true;
                            else
                                qrsComplexes.R( previousBeat ) = 1;
                                previousBeatRemoved = true;
                            end
                        end
                    end
                    
                end
                
            end
            
            % - - - - T WAVE AFTER PVC
            if ~removeBeat && ~previousBeatRemoved && ~isempty( previousBeat ) && ( peak > 2 ) && ( peak ~= numbBeats )
                
                % Previous Beat
                previousQRSCondition = ( qrsWindowStartPoint - qrsEndPoints( previousBeat ) ) < 0.100 * recordInfo.RecordSamplingFrequency;
                previousQRSCondition = previousQRSCondition && ( ( qrsComplexes.R(peak) - qrsEndPoints(previousBeat) ) <= ( 0.400*recordInfo.RecordSamplingFrequency ) );
                previousQRSCondition = previousQRSCondition && ( qrsComplexes.Type( previousBeat ) < 0  );
                
                if previousQRSCondition && ( qrsComplexes.Type( peak ) > 0 )
                    removeBeat = true;
                end
                
            end
            
        end
        
        
        %%  QRS Identification
        
        %         if qrsComplexes.R( peak ) > 1391 * 250
        %             plotDeveloper_qs;
        %         end
        
        if ~removeBeat
            
            % Amplitude Calculation
            srAmplitude = ecgSignal2Analyze( qrsComplexes.R( peak ) ) - ecgSignal2Analyze( qrsWindowSPoint );
            qrAmplitude = ecgSignal2Analyze( qrsComplexes.R( peak ) ) - ecgSignal2Analyze( qrsWindowQPoint );
            sqRatio = round( ( qrAmplitude / srAmplitude ), 2 );
            
            % Assessment
            if qrsComplexes.Type( peak ) < 0
                if sqRatio > 0.35
                    qrsComplexes.Type( peak ) = - qrsComplexes.Type( peak );
                end
            else
                if sqRatio < 0.10
                    qrsComplexes.Type( peak ) = - qrsComplexes.Type( peak );
                end
            end
            
        end
        
        
        %% Threshold Calculation
        
        
        
        if ~removeBeat
            if isempty( previousBeat )
                meanQRSAmplitude = currentQRSAmplitude;
                isThresholdCalculated = true;
            else
                if exist( 'meanQRSAmplitude', 'var' )
                    if peak > 10
                        if ( ...
                                max( [ currentQRSAmplitude; meanQRSAmplitude] ) / ...
                                min ( [ currentQRSAmplitude; meanQRSAmplitude] ) ...
                                ) < 1.5
                            meanQRSAmplitude = 0.67 * meanQRSAmplitude + 0.33 * currentQRSAmplitude;
                            isThresholdCalculated = true;
                        end
                    else
                        meanQRSAmplitude = 0.33 * meanQRSAmplitude + 0.67 * currentQRSAmplitude;
                        isThresholdCalculated = true;
                    end
                else
                    meanQRSAmplitude = currentQRSAmplitude;
                    isThresholdCalculated = true;
                end
            end
        end
        
        % Store QRS amplitude
        qrsAmplitude( peak ) = currentQRSAmplitude;
        
        %% ST Segment
        
        if removeBeat
            
            qrsComplexes.R( peak ) =  1; % not a beat
            
        else
            
            % ST Segment
            if ( peak > 1 ) && ( peak < numbBeats )
                % st value
                endPoints = double( qrsWindowEndPoint ) : double( qrsWindowEndPoint ) + double( 2 );
                endPointsValue = max( ecgSignal2Analyze( endPoints ) );
                % ref value
                startPoints = double( qrsWindowStartPoint - 2 ) : double( qrsWindowStartPoint );
                startPointsValue = min( ecgSignal2Analyze( startPoints ) );
                % st change
                stChange( peak ) = endPointsValue - startPointsValue;
                % j point
                jPointValue( peak ) = startPointsValue;
            else
                stChange( peak ) = single( 0 );
                jPointValue( peak ) = single( 0 );
            end
            
            % Save Points
            qrsStartPoints( peak ) = qrsWindowStartPoint;
            qrsQPoints( peak ) = qrsWindowQPoint;
            qrsSPoints( peak ) = qrsWindowSPoint;
            qrsEndPoints( peak ) = qrsWindowEndPoint;
            qrsPointSummations( peak ) = qrsPointSummation;
            
        end
        
    end
    
    %% Clear non-Beats
    
    % Determination of the non beats
    nonBeats = ( qrsComplexes.R == 1 );
    % r points
    qrsComplexes.R( nonBeats ) = [ ];
    % start points
    qrsStartPoints( nonBeats ) = [ ];
    qrsComplexes.StartPoint = qrsStartPoints;
    % q points
    qrsQPoints( nonBeats ) = [ ];
    qrsComplexes.Q = qrsQPoints;
    % s points
    qrsSPoints( nonBeats ) = [ ];
    qrsComplexes.S = qrsSPoints;
    % end points
    qrsEndPoints( nonBeats ) = [ ];
    qrsComplexes.EndPoint = qrsEndPoints;
    % peak angle
    qrsPeakAngle( nonBeats ) = [ ];
    qrsComplexes.PeakAngle = qrsPeakAngle;
    % st segment
    stChange( nonBeats ) = [ ];
    qrsComplexes.STSegmentChange = stChange;
    % j point
    jPointValue( nonBeats ) = [ ];
    qrsComplexes.JPointValue = jPointValue;
    % types
    qrsComplexes.Type( nonBeats ) = [ ];
    % qrs amplitude
    qrsAmplitude( nonBeats ) = [ ];
    qrsComplexes.QRSAmplitude = qrsAmplitude;
    % qrs interval
    qrsComplexes.QRSInterval = round( ( qrsComplexes.EndPoint - qrsComplexes.StartPoint ) / recordInfo.RecordSamplingFrequency, 3);
    
    %% Check number of beats
    
    if numbBeats <= 2
        
        % r points
        qrsComplexes.R = single( [ ] );
        % start points
        qrsComplexes.StartPoint = single( [ ] );
        % q points
        qrsComplexes.Q = single( [ ] );
        % s points
        qrsComplexes.S = single( [ ] );
        % end points
        qrsComplexes.EndPoint = single( [ ] );
        % peak angle
        qrsComplexes.PeakAngle = single( [ ] );
        % st segment
        qrsComplexes.STSegmentChange = single( [ ] );
        % j Point Value
        qrsComplexes.JPointValue = single( [ ] );
        % types
        qrsComplexes.Type = single( [ ] );
        % qrs amplitude
        qrsComplexes.QRSAmplitude = single( [ ] );
        % qrs interval
        qrsComplexes.QRSInterval = single( [ ] );
        
    end
    
else
    
    % r points
    qrsComplexes.R = single( [ ] );
    % start points
    qrsComplexes.StartPoint = single( [ ] );
    % q points
    qrsComplexes.Q = single( [ ] );
    % s points
    qrsComplexes.S = single( [ ] );
    % end points
    qrsComplexes.EndPoint = single( [ ] );
    % peak angle
    qrsComplexes.PeakAngle = single( [ ] );
    % st segment
    qrsComplexes.STSegmentChange = single( [ ] );
    % j Point Value
    qrsComplexes.JPointValue = single( [ ] );
    % types
    qrsComplexes.Type = single( [ ] );
    % qrs amplitude
    qrsComplexes.QRSAmplitude = single( [ ] );
    % qrs interval
    qrsComplexes.QRSInterval = single( [ ] );
    
end

end
