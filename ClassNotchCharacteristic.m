classdef ClassNotchCharacteristic
    
    % "ClassNotchCharacteristic.m" class consists charactersitic point
    %detection algorithms.
    %
    % > FindQRSStartPoint
    % > FindQRSEndPoint
    % > FindNotchStartInQRS
    
    %% PROPERTIES
    
    properties
        
        %
        
    end
    
    %% STATIC METHODS
    
    methods (Static)
        
        
        %% Finding QRS Start Point
        
        
        function [qrsStartPoint, qrsStartAmplitude] = FindQRSStartPoint(qrsWindow, notchPoint, samplingFreq)
            
            % Finding QRS start point.
            %
            % [qrsStartPoint, qrsStartAmplitude] = FindQRSStartPoint(qrsWindow, notchPoint, samplingFreq)
            %
            % <<< Function Inputs >>>
            %   single[n,1]  qrsWindow
            %   single notchPoint
            %   single samplingFreq
            %
            % <<< Function Outputs >>>
            %   single qrsStartPoint
            %   single qrsStartAmplitude
            
            
            % Initialization
            isFound = false;
            
            
            
            %%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%
            %%%  Segmentation Method   %%
            %%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%
            
            
            
            % diffraction ratio >> diffraction method
            diffractionWindowLength = single(2);
            diffractionRatioThreshold = single(0.25);
            
            % segment serach parameters
            segmentWindowLength = single( 10 );
            segmentAmplitudeThreshold = single( 0.1 );
            
            % searching limits
            segmentSearchLimitStart = notchPoint;
            segmentSearchLimitEnd = notchPoint - round(0.025 *samplingFreq);
            if segmentSearchLimitEnd < segmentWindowLength; segmentSearchLimitEnd = segmentWindowLength; end
            
            % if there is not enough interval, dont look segment and jump
            % for diffraction search
            if segmentSearchLimitEnd > segmentSearchLimitStart; searchForDiffractionFirst = true;
            else; searchForDiffractionFirst = false;
            end
            
            % search for qrs start point
            if ~searchForDiffractionFirst
                
                % searching for segment
                for segmentStartPoint = segmentSearchLimitStart : -1 : segmentSearchLimitEnd
                    
                    % window of segment
                    segmentWindow = qrsWindow( double( segmentStartPoint ) : double( -1 ) : double( segmentStartPoint - segmentWindowLength + 1 ) );
                    segmentWindowAmplitude = max(segmentWindow) - min(segmentWindow);
                    % segment threshold value: 0.1 mV / one little squares
                    isSegmentWindowFound = segmentWindowAmplitude < segmentAmplitudeThreshold;
                    
                    % if segmentWindowAmplitude is under one little sqaure
                    if isSegmentWindowFound
                        
                        % qrs window indexes of 10 sampled segment with
                        % amplitude lower than 0.1 mv
                        segmentIndexes = ( double( segmentStartPoint ) : double( -1 ) : double( segmentStartPoint - segmentWindowLength + 1 ) );
                        
                        % searching for the peak point in segment
                        for segmentPeak = segmentIndexes(1) : -1 : segmentIndexes(5)
                            
                            % find for the peak in window
                            if round( qrsWindow(segmentPeak), 2) > round( qrsWindow(segmentPeak + 2), 2) &&...
                                    round( qrsWindow(segmentPeak), 2) >= round( qrsWindow(segmentPeak - 2), 2)
                                
                                qrsStartPoint = segmentPeak;
                                qrsStartAmplitude = qrsWindow(segmentPeak);
                                isFound = true;
                                
                                break;
                                
                            else % is peak point is not found found, then there is no j point in the segment
                                
                                isFound = false;
                                
                            end % is peak point found
                            
                        end % for segmentPeak = segmentIndexes(1) : -1 : segmentIndexes(8)
                        
                        break; % for segmentWindowStartPoint = segmentSearchLimitStart : -1 : segmentSearchLimitEnd
                        
                    else % isSegmentWindowFound
                        
                        isFound = false;
                        
                    end % isSegmentWindowFound
                    
                end % for segmentWindowStartPoint = segmentSearchLimitStart : -1 : segmentSearchLimitEnd
                
            end % if ~searchForDiffractionFirst
            
            
            
            %%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%
            %%%   Diffraction Method   %%%
            %%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%
            
            
            
            % If qrs start point is not found with segment, then look for a diffraction
            while ~isFound
                
                % searching limits
                diffractionSearchLimitStart = (notchPoint - diffractionWindowLength);
                diffractionSearchLimitEnd =  (notchPoint - round(0.025 * samplingFreq));
                if diffractionSearchLimitEnd < (diffractionWindowLength + 1); diffractionSearchLimitEnd = (diffractionWindowLength + 1); end
                
                % assesment of the limits
                if diffractionSearchLimitStart < diffractionSearchLimitEnd
                    % if limits are not normal; the qrs is not normal
                    qrsStartPoint = notchPoint;
                    qrsStartAmplitude = qrsWindow(notchPoint);
                    isFound = true;
                    
                else
                    
                    % J point must be at least 2 sample away from the notch
                    for diffractionStartPoint = diffractionSearchLimitStart : -1 : diffractionSearchLimitEnd
                        
                        % searching diffraction
                        diffractionRefSlope = ClassSlope.CalculateSlope...
                            (qrsWindow, diffractionStartPoint, notchPoint);
                        diffractionSearchingSlope = ClassSlope.CalculateSlope...
                            (qrsWindow, (diffractionStartPoint - diffractionWindowLength), diffractionStartPoint);
                        diffractionSlopeRatio = diffractionSearchingSlope/diffractionRefSlope;
                        
                        % window slope assesment
                        if (diffractionSlopeRatio <= diffractionRatioThreshold) || ( diffractionSearchingSlope <= 0 )
                            
                            % position the point
                            if qrsWindow(diffractionStartPoint - 1) > qrsWindow(diffractionStartPoint)
                                qrsStartPoint = diffractionStartPoint - 1;
                            else
                                qrsStartPoint = diffractionStartPoint;
                            end
                            qrsStartAmplitude = qrsWindow(qrsStartPoint);
                            isFound = true;
                            
                            % break the loop
                            break;
                            
                        else
                            
                            % if diffraction is not found
                            isFound = false;
                            
                        end % diffractionSearchSlopeRatio <= diffRatioThreshold
                        
                        % if diffraction is not detected, change the threshold value
                        if (diffractionStartPoint == diffractionSearchLimitEnd) && ~isFound
                            diffractionRatioThreshold = diffractionRatioThreshold + 0.10;
                            if diffractionRatioThreshold >= 1
                                % Stop for searching diffraction;
                                isFound = true;
                                qrsStartPoint = notchPoint;
                                qrsStartAmplitude = qrsWindow(notchPoint);
                                
                            end % diffractionRatioThreshold >= 1
                            
                        end %  (diffractionStartPoint == diffractionSearchLimitEnd) && ~isFound
                        
                    end % diffractionStartPoint = diffractionSearchLimitStart : -1 : diffractionSearchLimitEnd
                    
                end % diffractionSearchLimitStart < diffractionSearchLimitEnd
                
            end % while ~isFound
            
        end
        
        
        %% Finding QRS End Point
        
        function [qrsEndPoint, qrsEndAmplitude] = FindQRSEndPoint(qrsWindow, qrAmplitude, rsAmplitude, notchPoint, samplingFreq)
            
            % Finding QRS end point.
            %
            % [qrsEndPoint, qrsEndAmplitude] = FindQRSEndPoint(qrsWindow, qrAmplitude, rsAmplitude, notchPoint, samplingFreq)
            %
            % <<< Function Inputs >>>
            %   single[n,1]  qrsWindow
            %   single qrAmplitude
            %   single rsAmplitude
            %   single notchPoint
            %   single samplingFreq
            %
            % <<< Function Outputs >>>
            %   single qrsEndPoint
            %   single qrsEndAmplitude
            
            % Initialization
            isFound = false;
            
            % diffraction search parameters : vol 1
            diffractionWindowLength = single(2);
            if ( rsAmplitude * 0.66 >= qrAmplitude )
                diffractionRatioThreshold = single(0.33);
            else
                diffractionRatioThreshold = single(0.75);
            end
            % segment comparison amplitude threshold
            %- possible pvc
            if qrAmplitude > 0.75
                if ( rsAmplitude * 0.66 >= qrAmplitude )
                    segmentComparisonAmplitudeRatio = single(0.60);
                else
                    segmentComparisonAmplitudeRatio = single( 0.30 );
                end
            else
                segmentComparisonAmplitudeRatio = single(0.60);
            end
            
            % segment limits
            segmentComparisonSearchLimitStart = notchPoint;
            segmentComparisonSearchLimitEnd = notchPoint + round(0.100 * samplingFreq );
            if segmentComparisonSearchLimitEnd > ( length( qrsWindow ) - diffractionWindowLength )
                segmentComparisonSearchLimitEnd = ( length( qrsWindow ) - diffractionWindowLength ); end
            % segment amplitude
            segmentComparisonAmplitude = max( qrsWindow( double( segmentComparisonSearchLimitStart ) : double( segmentComparisonSearchLimitEnd ) ) ) - qrsWindow(notchPoint);
            if segmentComparisonAmplitude <= 0.25; segmentComparisonAmplitude = single( 0 ); end
            
            
            
            %%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%
            %%%   Diffraction Method   %%%
            %%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%
            
            
            
            % If qrs end point is not found with segment, then look for a diffraction
            while ~isFound
                
                % diffraction search limits
                diffractionSearchLimitStart = notchPoint + diffractionWindowLength;
                diffractionSearchLimitEnd = notchPoint + round(0.120 * samplingFreq);
                if diffractionSearchLimitEnd > (numel(qrsWindow) - diffractionWindowLength)
                    diffractionSearchLimitEnd = (numel(qrsWindow) - diffractionWindowLength); end
                
                % assesment of the limits
                if diffractionSearchLimitStart > diffractionSearchLimitEnd
                    % if limits are not normal; the qrs is not normal
                    qrsEndPoint = notchPoint;
                    qrsEndAmplitude = qrsWindow(notchPoint);
                    isFound = true;
                    
                else
                    
                    % J point must be at least 2 sample away from the notch
                    for diffractionStartPoint = diffractionSearchLimitStart : 1 : diffractionSearchLimitEnd
                        
                        % searching diffraction
                        diffractionRefSlope = ClassSlope.CalculateSlope...
                            (qrsWindow, diffractionStartPoint, notchPoint);
                        diffractionSearchingSlope = ClassSlope.CalculateSlope...
                            (qrsWindow, (diffractionStartPoint + diffractionWindowLength), diffractionStartPoint);
                        diffractionSearchSlopeRatio = diffractionSearchingSlope/diffractionRefSlope;
                        
                        % window slope assesment
                        if ( diffractionSearchSlopeRatio < diffractionRatioThreshold )
                            
                            %- segment amplitude comparison
                            if (qrsWindow(diffractionStartPoint) - qrsWindow(notchPoint) ) >= segmentComparisonAmplitudeRatio * segmentComparisonAmplitude
                                
                                % position the j point
                                if qrsWindow(diffractionStartPoint + 1) > qrsWindow(diffractionStartPoint)
                                    qrsEndPoint = diffractionStartPoint + 1;
                                else
                                    qrsEndPoint = diffractionStartPoint;
                                end
                                qrsEndAmplitude = qrsWindow(qrsEndPoint);
                                isFound = true;
                                
                                % break the loop
                                break;
                                
                            else
                                
                                % if diffraction is not found
                                isFound = false;
                                
                            end % if (qrsWindow(tempJStartPoint) - qrsWindow(possibleNotch) ) >= segmentComparisonAmplitudeRatioThreshold * segmentComparisonAmplitude
                            
                        else
                            
                            % if diffraction is not found
                            isFound = false;
                            
                        end % ( diffractionSearchSlopeRatio < diffractionThreshold ) || ( diffractionSearchWindowSlope <= 0 )
                        
                        % if diffraction is not detected, change the threshold value
                        if (diffractionStartPoint == diffractionSearchLimitEnd ) && (~isFound)
                            diffractionRatioThreshold = diffractionRatioThreshold + 0.10;
                            if diffractionRatioThreshold >= 1
                                % Stop for searching diffraction;
                                isFound = true;
                                qrsEndPoint = notchPoint;
                                qrsEndAmplitude = qrsWindow(notchPoint);
                            end
                            
                        end % (diffractionStartPoint == diffractionSearchLimitEnd ) && (~isFound)
                        
                    end % for diffractionStartPoint = diffractionSearchLimitStart : 1 : diffractionSearchLimitEnd
                    
                end % if diffractionSearchLimitStart > diffractionSearchLimitEnd
                
            end % while ~isFound
            
        end % function [qrsEndPoint, qrsEndAmplitude] = FindQRSEndPoint(qrsWindow, notchPoint)
        
        
        %% Finding Notch Point in a QRS Complex
        
        function [point] = FindNotchStartInQRS(type, signal, jValue, startPoint, endPoint)
            
            % Finding Notch start point in QRS complex.
            %
            % [point] = FindNotchStartInQRS(type, signal, jValue, startPoint, endPoint)
            %
            % <<< Function Inputs >>>
            %   string type
            %   single[n,1]  signal
            %   single jValue
            %   single startPoint
            %   single endPoint
            %
            % <<< Function Outputs >>>
            %   single point
            
            % type selection
            if type == 'q'; direction = single(1); notFoundPoint = single(1);
            elseif type == 's'; direction = single(-1); notFoundPoint = single(numel(signal));
            end
            
            % finding start of the wave
            for search = startPoint : direction : endPoint
                
                if ( signal(search) >= jValue) && (signal(search - direction) < jValue)
                    point = search;
                    break;
                    
                else % ( signal(search) >= jValue) && (signal(search - direction) < jValue)
                    point = notFoundPoint;
                    
                end % ( signal(search) >= jValue) && (signal(search - direction) < jValue)
                
            end % for search = startPoint : direction : endPoint
            
        end % function [point] = FindNotchStartInQRS(type, signal, jValue, startPoint, endPoint)
        
        
    end
    
    
end

