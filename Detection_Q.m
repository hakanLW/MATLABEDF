
% Q Detection Algorithm
%
% [qrsStartPoint, qPoint] = Detection_Q(qrsWindow, qrsWindowRPoint, qrAmplitude, samplingFreq)
%
% <<< Function Inputs >>>
%   single[n,1]  qrsWindow
%   single qrsWindowRPoint
%   single qrAmplitude
%   single samplingFreq
%
% <<< Function outputs >>>
%   single qrsStartPoint
%   single qrsQPoint

function [qrsStartPoint, qPoint] = Detection_Q(qrsWindow, qrsWindowRPoint, qrAmplitude, samplingFreq)


%% INITIALIZATION
% Outputs of the function is initialized.
qrsStartPoint = single(1);
qPoint = single(1);

% Determination of initial thresholds
% - amplitudeLimitRatio >> qr amplitude limit ratio.
% - initialDiffRatioThrehold >> diffraction ratio.
if qrAmplitude < 0.50
    amplitudeLimitRatio = single(0.40);
    initialDiffractionRatioThrehold = single(0.33);
else
    amplitudeLimitRatio = single(0.60);
    initialDiffractionRatioThrehold = single(0.33);
end

%% Q DETECTION

% Slope change is being calculated with 3 successive samples.
% Slope change is detected according to the "qSearchDiffThreshold".
qSearchWindowLength = single(3);
qSearchDiffractionWindowLegth = single(2);
qSearchDiffThreshold = initialDiffractionRatioThrehold;

% If Q point is detected, "qDetected" is changed to "true".
% If Q could not found with initial searching parameters, detection
% algoritm goes back to square one with new searching parameters.
qDetected = false;
qSearchThresholdChageStop = false;

% Searching starts from R point; ends at
% the point 150 ms away from the peak point.
% WARNING: "If distance between begining of the signal and the peak point of
% interested QRS is lower than 150 ms, searching limit ends at the signal
% begining point."
qSearchSignalLimitStart = qrsWindowRPoint;
qSearchSignalLimitEnd =  single( 1 + qSearchDiffractionWindowLegth );

% To avoid finding wrong q points in abnormal QRS complexes, like rabbit
% ears, a limit point is determined.
[qAmplitudeThresholdFound, qAmplitudeThresholdPoint] = ...
    ClassNotchEvaluation.FindQRSLimit(qrsWindow, ...
                                                                            qSearchSignalLimitStart, ...
                                                                            qSearchSignalLimitEnd, ...
                                                                            qrAmplitude, ...
                                                                            amplitudeLimitRatio);

% Q DETECTION ALGORITHM
while ~qDetected
    
    % If amplitude threshold limit could not be found,
    % it means that there is no slope change in determinated limits.
    if qAmplitudeThresholdFound
        
        % Abnormal qrs
        if qSearchSignalLimitEnd > qAmplitudeThresholdPoint
            qPoint = qrsWindowRPoint;
            qrsStartPoint = qrsWindowRPoint;
            qDetected = true;
            
        else
            
            % Possible q point searching;
            % - starts from qAmplitudeThresholdPoint
            % - ends at 150 ms away from the r point.
            for possibleQPoint = double( qAmplitudeThresholdPoint ) : double( -1 ) : double( qSearchSignalLimitEnd )
                
                % Check if possible q is under peak limit
                isQUnderLine = ClassNotchEvaluation.QRSLimit...
                    ( qrsWindow(qrsWindowRPoint), qrsWindow(possibleQPoint), qrAmplitude, amplitudeLimitRatio);
                
                % Reference slope value
                qRefSlope = ClassSlope.CalculateSlope(qrsWindow, qrsWindowRPoint, possibleQPoint);
                
                % Possible q window slope value
                qWindowSlope = ClassSlope.CalculateSlope(qrsWindow, possibleQPoint, (possibleQPoint - qSearchWindowLength + 1) );
                
                % Possible q window slope ratio
                qSearchSlopeRatio = round( (qWindowSlope / qRefSlope), 2);
                
                % Find the diffraction point
                if ( qSearchSlopeRatio <= qSearchDiffThreshold ) && (isQUnderLine)
                    % Q Point
                    [qPoint] = ClassSlope.FindDiffractionPoint('q', possibleQPoint);
                    % Q point is founded
                    qDetected = true;
                    % break the for loop
                    break;
                    
                end % ( qSearchSlopeRatio <= qSearchDiffThreshold ) && (isQUnderLine)
                
                % If Q could not detected after threshold values are
                % changed; annotade the QRS as non-Q.
                if (possibleQPoint == qSearchSignalLimitEnd) && ~qDetected && qSearchThresholdChageStop
                    qPoint = qrsWindowRPoint;
                    qrsStartPoint = qrsWindowRPoint;
                    qDetected = true;
                    % break the for loop
                    break;
                end
                
                % New seaching threshold values are being determined
                if (possibleQPoint == qSearchSignalLimitEnd) && ~qDetected && ~qSearchThresholdChageStop
                    % increase diffraction thresold
                    qSearchDiffThreshold = qSearchDiffThreshold + 0.10;
                    if qSearchDiffThreshold >= 1
                        qSearchThresholdChageStop = true;
                    end
                    qDetected = false;
                end
                
            end % possibleQPoint = qAmplitudeThresholdPoint : -1 : qSearchSignalEndPoint
            
        end % if qSearchSignalEndPoint > qAmplitudeThresholdPoint
        
    else % if qAmplitudeThresholdFound
        
        qPoint = qrsWindowRPoint;
        qrsStartPoint = qrsWindowRPoint;
        qDetected = true;
        
    end % if qAmplitudeThresholdFound
    
end % while ~qDetected


%% QRS START DETECTION

if qrAmplitude <= 0.20
    % - if qrAmplitude is lower than 0.25 mV, it may be a qs shaped QRS complex
    % - if qrAmplitude is highher than 0.25 mV, run the qrs start point detection algoirthm
    qrsStartPoint = qPoint;
    
else
    
    if qPoint ~= qrsWindowRPoint
        
        % - riseAfterQ >> selection of the sample number after Q point
        % - sampleNumberBeforeQ >> selection of the sample number to go backwards from Q point
        % - sampleNumberAfterQ >> selection of the sample number to go afterwards from Q point
        riseAfterQ = single(2);
        sampleBeforeQ = single(2);
        sampleAfterQ = single(3);
        
        % Notch searching limits
        possibleNotchSearchLimitStart = qPoint + sampleBeforeQ;
        possibleNotchSearchLimitEnd = qPoint - sampleAfterQ;
        if possibleNotchSearchLimitEnd < (1 + riseAfterQ); possibleNotchSearchLimitEnd = (1 + riseAfterQ); end
        
        % If amplitude threshold limit could not be found,
        % it means that there is no slope change in determinated limits.
        if qAmplitudeThresholdFound
            
            % possibleNotch >> possible notch point
            for possibleNotch = double( possibleNotchSearchLimitStart ) : double( -1 ) : double( possibleNotchSearchLimitEnd )
                
                % Searching window limits
                % - first sample is the outmost sample
                notchSearchWindowStart = double(possibleNotch - riseAfterQ);
                if notchSearchWindowStart < 1; notchSearchWindowStart = 1; end
                notchSearchWindowEnd = double( qrsWindowRPoint );
                notchSearchWindowRaw = qrsWindow( double( notchSearchWindowStart ) : double( notchSearchWindowEnd ) );
                
                % Searching window's length must be more than 6.
                % - First 2 >> notch deep / consecutive increasing check
                % - 3 >> notch
                % - 4 >> neglection sample (for possible noise)
                % - Last 2 >> consecutive increasing check
                if numel(notchSearchWindowRaw) > 6
                    
                    % Check if notch is the minimum sample in the window
                    isNotchMinWindow = ClassNotchEvaluation.Depth...
                        ('q', riseAfterQ, notchSearchWindowRaw);
                    
                    % IF POSSIBLE NOTCH IS UNDER LIMIT AND 4th SAMLE IN THE WINDOW IS THE LOCAL MINIMUM
                    if isNotchMinWindow
                        
                        % possible q wave start/end point
                        [qWaveStartPoint, qWaveStartAmplitude] = ...
                            ClassNotchCharacteristic.FindQRSStartPoint(qrsWindow, possibleNotch, samplingFreq);
                        [qWaveEndPoint] = ...
                            ClassNotchCharacteristic.FindNotchStartInQRS('q', qrsWindow, qWaveStartAmplitude, possibleNotch, qrsWindowRPoint);
                        
                        % does notch have at least one little square amplitude/4
                        [isAmplitude] = ClassNotchEvaluation.Amplitude...
                            (qrsWindow(qWaveStartPoint), qrsWindow(possibleNotch), single(0.025));
                        
                        % is notch duration under limit
                        [isDuration] = ClassNotchEvaluation.Duration...
                            (qWaveStartPoint, qWaveEndPoint, single(15));
                        
                        % slope calculation of the q segment
                        [isSlopeEnough] = ClassNotchEvaluation.Slope...
                            ( qrsWindow, qWaveStartPoint, possibleNotch, single( 60 ) );
                        
                        % Decision
                        if isAmplitude && isSlopeEnough && isDuration
                            % If every condition is fulfilled
                            qPoint = possibleNotch;
                            qrsStartPoint = qWaveStartPoint;
                            break;
                        else
                            % If there is a notch but it is not q wave
                            qrsStartPoint = qPoint;
                            break;
                        end
                        
                    else % isNotchUnderLine && isNotchMinWindow
                        
                        qrsStartPoint = qPoint;
                        
                    end % isNotchUnderLine && isNotchMinWindow
                    
                end % numel(notchSearchWindowRaw) > 6
                
            end % possibleNotch = possibleNotchSearchLimitStart :-1: possibleNotchSearchLimitEnd
            
        else % if (qAmplitudeThresholdFound)
            
            qPoint = qrsWindowRPoint;
            qrsStartPoint = qrsWindowRPoint;
            
        end % if (qAmplitudeThresholdFound)
        
    else % if qPeak ~= qrsWindowRPoint
        
        qPoint = qrsWindowRPoint;
        qrsStartPoint = qrsWindowRPoint;
        
    end % if qPeak ~= qrsWindowRPoint
    
end % if qrAmplitude <= 0.25

%% BASELINE

% if qrsStartPoint ~= qrsWindowRPoint && qrsStartPoint ~= qPoint && qrsStartPoint ~= 1
%     
%     % sharp peak
%     if ( qrsWindow(qrsStartPoint) - qrsWindow(qrsStartPoint - 1) ) > 0.01 ||...
%             ( qrsWindow(qrsStartPoint) - qrsWindow(qrsStartPoint + 1) ) > 0.01
%         
%         % searchBaseline limits
%         searchBaselineStartPoint = qrsStartPoint - 2;
%         searchBaselineEndPoint = single(3);
%         
%         % searchBaseline parameters
%         searchBaselineAmpThreshold = single(0.15);
%         searchBaselineDiffRatioThreshold = single(0.50);
%         
%         % baselinePoint search
%         for baselinePoint = double( searchBaselineStartPoint ) : double( -1 ) : double( searchBaselineEndPoint )
%             
%             % diffraction calculation
%             baselineSearchRefSlope = ClassSlope.CalculateSlope(qrsWindow, qrsStartPoint, baselinePoint);
%             baselineSearchWindowSlope = ClassSlope.CalculateSlope(qrsWindow, baselinePoint, (baselinePoint - 2));
%             baselineSearchSlopeRatio = baselineSearchWindowSlope /  baselineSearchRefSlope;
%             
%             % if diffraction ratio is under limit
%             if baselineSearchSlopeRatio < searchBaselineDiffRatioThreshold
%                 
%                 tempBaselinePoint = baselinePoint;
%                 
%                 if ( qrsWindow(qrsStartPoint) - qrsWindow(tempBaselinePoint) ) > searchBaselineAmpThreshold
%                     qrsStartPoint = tempBaselinePoint;
%                 end
%                 
%                 break;
%                 
%             end % baselineSearchSlopeRatio < searchBaselineDiffRatioThreshold
%             
%         end % for baselinePoint = searchBaselineStartPoint : -1 : searchBaselineEndPoint
%         
%     end % ( qrsWindow(qrsStartPoint) - qrsWindow(qrsStartPoint - 1) ) > 0.01 ||...
%     
% end % qrsStartPoint ~= qrsWindowRPoint && qrsStartPoint ~= qPoint

end


