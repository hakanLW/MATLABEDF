classdef ClassSlope
    
    % "ClassSlope.m" class consists slope functions
    %
    % > CalculateSlope
    % > FindDiffractionPoint
    % > CalculateAngle
    
    %% PROPERTIES
    
    properties
        
        %
        
    end
    
    %% STATIC METHODS
    
    
    methods (Static)
        
        
        %% Slope Calculation
        
        function [slopeValue] = CalculateSlope(signal, maxValuePoint, minValuePoint)
            
            % Slope calculation.
            %
            % [slopeValue] = CalculateSlope(signal, maxValuePoint, minValuePoint)
            %
            % <<< Function Inputs >>>
            %   single[n,1] signal  
            %   single maxValuePoint   
            %   single minValuePoint 
            %
            % <<< Function Outputs >>>
            %   single slopeValue 
            %

            
            slopeValue = ( signal(maxValuePoint) - signal(minValuePoint) ) / ( abs( maxValuePoint - minValuePoint ) );
            
            
        end
        
        
        %% Finding Diffraction Point
        
        function [diffPoint] = FindDiffractionPoint(type, slopeStartPoint)
            
            % Finding diffraction point.
            %
            % [diffPoint] = FindDiffractionPoint(type, qrsWindow, slopeStartPoint)
            %
            % <<< Function Inputs >>>
            %   string type 
            %   single slopeStartPoint
            %
            % <<< Function Outputs >>>
            %   single diffPoint 
            %
            
            
            % DIRECTION OF THE PEAK
            if type == 'q'; direction = single( -1 ); % 
            elseif type == 's'; direction =  single( 1 ); % 
            end
            
            
            % DIFFRACTION
            diffPoint = slopeStartPoint + 2 * direction;
            
            
        end
    
        
        %% Calculate Angle
        
        function [ angle ] = CalculateAngle( mv, sample  )
            
            % Angle calculation based on 25 mm/sec ECG paper format.
            %
            % [ angle ] = CalculateAngle( mv, sample )
            %
            % <<< Function Inputs >>>
            %   single mv
            %   single sample
            %
            % <<< Function Outputs >>>
            %   single angle 
            %
            
            
            angle = atand( ( 10 * mv ) / ( 0.1 * sample ) );
            angle = single( angle );
            if isnan( angle ); angle = single( 0 ); end
            
            
        end
        
        
    end
    
    
end

