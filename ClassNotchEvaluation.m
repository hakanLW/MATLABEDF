classdef ClassNotchEvaluation
    
    % "ClassQRSCharacteristics.m" class consists charactersitic point
    %assessments.
    %
    % > FindQRSLimit
    % > QRSLimit
    % > Depth 
    % > Amplitude 
    % > Duration 
    % > Slope 
    
    %% PROPERTIES
    
    properties
        
        %
        
    end
    
    %% STATIC METHODS
    
    
    methods (Static)
        
        
        %% Finding QRS Limit Point
        
        function [isLimitFound, limitPoint] = FindQRSLimit(signal, qrsWindowRPoint, searchEndPoint, rAmplitude, ratio)
            
            % Finding QRS limit point.
            %
            % [isLimitFound, limitPoint] = FindQRSLimit(signal, qrsWindowRPoint, searchEndPoint, rAmplitude, ratio)
            %
            % <<< Function Inputs >>>
            %   single[n,1]  signal 
            %   single qrsWindowRPoint
            %   single searchEndPoint
            %   single rAmplitude
            %   single ratio
            %
            % <<< Function Outputs >>>
            %   boolean isLimitFound 
            %   single limitPoint
            
            % Initialization
            isLimitFound = false;
            limitPoint = qrsWindowRPoint;
            
            % Direction determination for the searching loop.
            if qrsWindowRPoint >= searchEndPoint; direction = single( - 1 );
            elseif  searchEndPoint > qrsWindowRPoint; direction = single( + 1 );
            end
            
            % Searching for the limit point
            for searchPoint = qrsWindowRPoint : direction : searchEndPoint
                isLimitFound = ( ( signal(qrsWindowRPoint) - rAmplitude* ratio ) >= signal(searchPoint) );
                if isLimitFound
                    limitPoint = searchPoint;
                    break;
                end
            end
            
            % Is detected limit point has enough value
            limitPointAmplitude = signal(qrsWindowRPoint) - signal(limitPoint);
            if limitPointAmplitude < 0.05 
                isLimitFound = false;
                limitPoint = qrsWindowRPoint;
            end
            
        end
        
        
        %% Assesment of Notch Limit Amplitude
        
        function [isUnderLine] = QRSLimit( rAmplitude, pointAmplitude, refAmplitude, ratio)
            
            % Evaluation if notch is under amplitude limit depth.
            %
            % [isUnderLine] = QRSLimit( rAmplitude, pointAmplitude, refAmplitude, ratio)
            %
            % <<< Function Inputs >>>
            %   single rAmplitude 
            %   single pointAmplitude
            %   single refAmplitude 
            %   single ratio
            %
            % <<< Function Outputs >>>
            %   boolean isUnderLine 
            
            isUnderLine = ( ( rAmplitude - refAmplitude * ratio ) >= pointAmplitude );
            
        end
        
        
        %% Assesment of Notch Depth
        
        function [isMin] = Depth(type, minRise, searchWindow)
            
            % Evaluation of the notch depth.
            %
            % [isMin] = Depth(type, minRise, searchWindow)
            %
            % <<< Function Inputs >>>
            %   string type 
            %   single minRise 
            %   single[n,1] searchWindow 
            %
            % <<< Function Outputs >>>
            %   boolean isMin 
            
            % Type of the notch
            if type == 'q'; window = searchWindow;
            elseif type == 's'; window = flipud(searchWindow);
            end
            
            % Checking outlying points
            for checkForIfMin = 1 : minRise
                if window(checkForIfMin) > window(checkForIfMin + 1)
                    isMin = true;
                else
                    isMin = false;
                    break;
                end
            end
            
            % Checking subcentral points
            if isMin
                for checkForIfMin = (minRise + 3) : 2 : (minRise + 5)
                    if ( window(checkForIfMin) > window(checkForIfMin - 1) ) && isMin
                        isMin = true;
                    else
                        isMin = false;
                        break;
                    end
                end
            end
            
        end
        
        
        %% Assesment of Notch Amplitude
        
        function [isMinAmplitude] = Amplitude(jValue, notchValue, minAmplitude)
            
            % Evaluation of the notch amplitude.
            %
            % [isMinAmplitude] = Amplitude(jValue, notchValue, minAmplitude)
            %
            % <<< Function Inputs >>>
            %   single jValue 
            %   single notchValue 
            %   single minAmplitude 
            %
            % <<< Function Outputs >>>
            %   boolean isMinAmplitude 
            
            % - amplitude of the notch
            amplitude = round ( abs ( jValue - notchValue ) , 3);
            % - is notch enough amplitude
            isMinAmplitude = ( ( amplitude ) >= minAmplitude );
            
        end
        
        
        %% Assesment of Notch Duration
        
        function [isDuration] = Duration(startPoint, endPoint, maxDuration)
            
            % Evaluation of the notch duration
            %
            % [isDuration] = Duration(startPoint, endPoint, maxDuration)
            %
            % <<< Function Inputs >>>
            %   single startPoint 
            %   single endPoint
            %   single maxDuration 
            %
            % <<< Function Outputs >>>
            %   boolean isDuration 
            
            if maxDuration == 0 % if notch duration is not in interest. | sWave
                isDuration = true;
                
            else % if notch duration is in interest. | qWave
                isDuration = ( (endPoint - startPoint) <=  maxDuration && (endPoint - startPoint) > 0);
                
            end
            
        end
        
        
        %% Assesment of Notch Slope
        
        function [isSlopeEnough] = Slope(signal, jPoint, notchPoint, desired)
            
            % Evaluation ofthe notch slope.
            %
            % [isSlopeEnough] = Slope(signal, jPoint, notchPoint, desiredRatio )
            %
            % <<< Function Inputs >>>
            %   single[n,1] signal 
            %   single jPoint 
            %   single notchPoint 
            %   single desiredRatio 
            %
            % <<< Function Outputs >>>
            %   boolean isSlopeEnough 
            
            % jAmplitude
            jAmplitude = ( signal(jPoint) - signal(notchPoint) );
            % jDuration
            jDuration = abs( jPoint - notchPoint );
            % Slope
            jSlope = ClassSlope.CalculateAngle( jAmplitude, jDuration );

            % assessment
            if jSlope < desired
                isSlopeEnough = false;
            else
                isSlopeEnough = true;
            end
            
        end
        
        
    end
    
end

