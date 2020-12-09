
% S Detection Algorithm
%
% [qrsEndPoint, sPoint] = Detection_S(qrsWindow, qrsWindowRPoint, qrAmplitude, rsAmplitude, samplingFreq)
% <<< Function Inputs >>>
%   single[n,1] qrsWindow
%   single qrsWindowRPoint
%   single qrAmplitude
%   single rsAmplitude
%   single samplingFreq
%
% <<< Function outputs >>>
%   single qrsEndPoint
%   single sPoint
%

function [qrsEndPoint, sPoint] = Detection_S(qrsWindow, qrsWindowRPoint, qrsDirection, qrAmplitude, rsAmplitude, jaAmplitude, samplingFreq)

%% INITIALIZATION
% Outputs of the function is initialized.
qrsEndPoint = single(1);
sPoint = single(1);

% - amplitudeLimitRatio >> rs amplitude limit ratio.
% - initialDiffRatioThrehold >> diffraction ratio.
if rsAmplitude < single( 0.5 )
    amplitudeLimitRatio = single(0.40);
    initialDiffractionRatioThrehold = single(0.33);
else
    amplitudeLimitRatio = single(0.75);
    initialDiffractionRatioThrehold = single(0.33);
end

%% S DETECTION

% Slope change is being calculated with 3 successive samples.
% Slope change is detected according to the "sSearchDiffThreshold".
sSearchWindowLength = single(3);
sSearchDiffractionWindowLegth = single(2);
sSearchDiffThreshold = initialDiffractionRatioThrehold;

% If S point is detected, "sDetected" is changed to "true".
% If S could not found with initial searching parameters, detection
% algoritm goes back to square one with new searching parameters.
sDetected = false;
sSearchThresholdChageStop = false;

% Searching starts from R point; ends at
% the point 150 ms away from the peak point.
% WARNING: "If distance between begining of the signal and the peak point of
% interested QRS is lower than 150 ms, searching limit ends at the signal
% ending point."
sSearchSignalStartPoint = qrsWindowRPoint;
sSearchSignalEndPoint = qrsWindowRPoint + round(0.150 * samplingFreq);
if sSearchSignalEndPoint > (numel(qrsWindow) - sSearchDiffractionWindowLegth)
    sSearchSignalEndPoint = (numel(qrsWindow) - sSearchDiffractionWindowLegth); end

% To avoid finding wrong s points in abnormal QRS complexes, like rabbit
% ears, a limit point is determined.
[sAmplitudeThresholdFound,sAmplitudeThresholdPoint] =...
    ClassNotchEvaluation.FindQRSLimit(qrsWindow, ...
    sSearchSignalStartPoint, ...
    sSearchSignalEndPoint, ...
    rsAmplitude, ...
    amplitudeLimitRatio);

% S DETECTION ALGORITHM
while  ~sDetected
    
    % If amplitude threshold limit could not be found,
    % it means that there is no slope change in determinated limits.
    if sAmplitudeThresholdFound
        
        % Possible s point searching;
        % - starts from sAmplitudeThresholdPoint
        % - ends at 150 ms away from the r point.
        for possibleSPoint = double( sAmplitudeThresholdPoint ) : double( 1 ) : double( sSearchSignalEndPoint )
            
            % Check if possible s is under peak limit
            isSUnderLine =  ClassNotchEvaluation.QRSLimit...
                ( qrsWindow(qrsWindowRPoint), qrsWindow(possibleSPoint), rsAmplitude, amplitudeLimitRatio);
            
            % Reference slope value
            sRefSlope = ClassSlope.CalculateSlope(qrsWindow, qrsWindowRPoint, possibleSPoint);
            
            % Possible s window slope value
            sSearchWindowSlope = ClassSlope.CalculateSlope(qrsWindow, possibleSPoint, (possibleSPoint + sSearchWindowLength - 1) );
            
            % Possible s window slope ratio
            sSearchSlopeRatio = round( (sSearchWindowSlope / sRefSlope), 2);
            
            % Find the diffraction point
            if (sSearchSlopeRatio <= sSearchDiffThreshold) && (isSUnderLine)
                % S Point
                [sPoint] = ClassSlope.FindDiffractionPoint('s', possibleSPoint);
                % S point is founded
                sDetected = true;
                % break the for loop
                break;
                
            end
            
            % If S could not detected after threshold values are
            % changed; annotade the QRS as non-S.
            if (possibleSPoint == sSearchSignalEndPoint) && ~sDetected && sSearchThresholdChageStop
                sPoint = qrsWindowRPoint;
                qrsEndPoint = qrsWindowRPoint;
                sDetected = true;
                % break the for loop
                break;
            end
            
            % New seaching threshold values are being determined
            if (possibleSPoint == sSearchSignalEndPoint) && ~sDetected && ~sSearchThresholdChageStop
                % increase diffraction thresold
                sSearchDiffThreshold = sSearchDiffThreshold + 0.10;
                if sSearchDiffThreshold >= 1
                    sSearchThresholdChageStop = true;
                end
                sDetected = false;
            end
            
        end % for possibleSPoint = sAmplitudeThresholdPoint : 1 : sSearchSignalEndPoint
        
    else % if sAmplitudeThresholdFound
        
        sPoint = qrsWindowRPoint;
        qrsEndPoint = qrsWindowRPoint;
        sDetected = true;
        
    end % if sAmplitudeThresholdFound
    
end % while ~sDetected


%% QRS END DETECTION

if sPoint ~= qrsWindowRPoint
    
    % - riseAfterS >> selection of the sample number after S point
    % - sampleBeforeS >> selection of the sample number to go backwards from S point
    % - sampleAfterS >> selection of the sample number to go afterwards from S point
    % slope calculation of the s segment
    if ( jaAmplitude - single( 0.1 ) ) >= qrsWindow( sPoint )
        % normal qrs
        riseAfterS = single(2);
        sampleBeforeS = single(2);
        sampleAfterS = single(25);
    else
        % pvc caused deep s point
        riseAfterS = single(2);
        sampleBeforeS = single(2);
        sampleAfterS = single(12);
    end
                 
    % sAmplitudeThresholdFound based on qrs direction
    if qrsDirection < 0
        % possible notch searchin limits 
        % // end point
        possibleNotchSearchLimitEnd = sPoint +  sampleAfterS;
        if possibleNotchSearchLimitEnd > (numel(qrsWindow) - riseAfterS)
            possibleNotchSearchLimitEnd = (numel(qrsWindow) - riseAfterS); end
        % // start point
        % - s point value
        sPointValue = qrsWindow( sPoint );
        % - end point value
        endPointValue = qrsWindow( possibleNotchSearchLimitEnd );
        % - temp limit 
        valueThreshold = sPointValue + ( endPointValue - sPointValue ) * 0.50;
        % - point
        possibleNotchSearchLimitStart = ( qrsWindow > valueThreshold );
        possibleNotchSearchLimitStart( 1 : sPoint ) = false;
        possibleNotchSearchLimitStart = find( possibleNotchSearchLimitStart, 1, 'first' );
    else
        % possible notch searchin limits
        % // end point
        possibleNotchSearchLimitEnd = sPoint +  sampleAfterS;
        if possibleNotchSearchLimitEnd > (numel(qrsWindow) - riseAfterS)
            possibleNotchSearchLimitEnd = (numel(qrsWindow) - riseAfterS); end
        % // start point
        possibleNotchSearchLimitStart = sPoint - sampleBeforeS;
    end
      
    % -If amplitude threshold limit could not be found,
    % it means that there is no slope change in determinated limits.
    if sAmplitudeThresholdFound
        
        % possibleNotch >> possible notch point
        for possibleNotch = double( possibleNotchSearchLimitStart ) : double( 1 ) : double( possibleNotchSearchLimitEnd )
            
            % Searching window limits
            % - first sample is the outmost sample
            notchSearchWindowStart = qrsWindowRPoint;
            notchSearchWindowEnd = (possibleNotch + riseAfterS);
            if notchSearchWindowEnd > numel(qrsWindow); notchSearchWindowEnd = numel(qrsWindow); end
            notchSearchWindowRaw = qrsWindow( double( notchSearchWindowStart ) : double( notchSearchWindowEnd ) );
            
            % Searching window's length must be more than 6.
            % - First 2 >> notch deep / consecutive increasing check
            % - 3 >> notch
            % - 4 >> neglection sample (for possible noise)
            % - Last 2 >> consecutive increasing check
            if numel(notchSearchWindowRaw) > 6
                
                % Check if notch is the minimum sample in the window
                if qrsDirection < 0
                    isNotchMinWindow = true;
                else
                    isNotchMinWindow = ClassNotchEvaluation.Depth...
                        ('s', riseAfterS, notchSearchWindowRaw);
                end
                
                % IF POSSIBLE NOTCH IS UNDER LIMIT AND 4th SAMLE IN THE WINDOW IS THE LOCAL MINIMUM
                if isNotchMinWindow
                    
                    % slope calculation of the s segment
                    slopeAmplitude = abs( qrsWindow( sPoint ) - qrsWindow( possibleNotch ) );
                    slopeDuration = abs( sPoint - possibleNotch );
                    slopeAngle = ClassSlope.CalculateAngle( slopeAmplitude, slopeDuration);
                    
                    % slope assesment of the ref notch
                    if slopeAngle >= single( 60 ) && ...
                            ( abs( qrsWindow( sPoint ) - qrsWindow( possibleNotch ) ) <= single( 0.10 ) || ...
                            abs( qrsWindow( sPoint ) - qrsWindow( possibleNotch ) ) >= single( 0.30 )  )
                        if qrsDirection > 0
                            sPoint = possibleNotch;
                        end
                        refNotch = possibleNotch;
                    else
                        refNotch = sPoint;
                    end
                    
                    
                    % possible s wave start/end point
                    [sWaveEndPoint, ~] = ClassNotchCharacteristic.FindQRSEndPoint(qrsWindow, qrAmplitude, rsAmplitude, possibleNotch, samplingFreq);
                    
                    % does notch have at least one little square amplitude/2
                    [isAmplitude] = ClassNotchEvaluation.Amplitude...
                        (qrsWindow(sWaveEndPoint), qrsWindow(refNotch), single(0.025));
                    
                    % slope calculation of the s segment
                    if ( jaAmplitude - single( 0.1 ) ) >= qrsWindow( sPoint )
                        % normal qrs
                        [isSlopeEnough] = ClassNotchEvaluation.Slope...
                            ( qrsWindow, sWaveEndPoint, refNotch, single( 33 ) );
                    else
                        % pvc caused deep s point
                        [isSlopeEnough] = ClassNotchEvaluation.Slope...
                            ( qrsWindow, sWaveEndPoint, refNotch, single( 60 ) );
                    end
                    
                    % Decision
                    if isAmplitude && isSlopeEnough
                        % If every condition is fulfilled
                        qrsEndPoint = sWaveEndPoint;
                        break;
                    else
                        % If there is a notch but it is not s wave
                        qrsEndPoint = sPoint;
                        break;
                    end
                    
                else % isNotchUnderLine && isNotchMinWindow
                    
                    qrsEndPoint = sPoint;
                    
                end % isNotchUnderLine && isNotchMinWindow
                
            end %  if numel(notchSearchWindowRaw) > 6
            
        end % for possibleNotch = possibleNotchSearchLimitStart : 1 : possibleNotchSearchLimitEnd
        
    else % if sAmplitudeThresholdFound
        
        sPoint = qrsWindowRPoint;
        qrsEndPoint = qrsWindowRPoint;
        
    end % if sAmplitudeThresholdFound
    
else %  sPoint ~= qrsWindowRPoint
    
    sPoint = qrsWindowRPoint;
    qrsEndPoint = qrsWindowRPoint;
    
end %  sPoint ~= qrsWindowRPoint


end
