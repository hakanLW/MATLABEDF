classdef ClassDatetimeCalculation
    
    % "ClassDatetimeCalculation.m" class consists datetime calculations.
    %
    % > Summation
    % > Substraction
    
    %% PROPERTIES
    
    properties
        
        %
        
    end
    
    %% STATIC METHODS
    
    
    methods (Static)
        
        
        %% Summation
        
        function [ datetimeResult ] = Summation( startTime, time2Sum )
            
            % Summation of datetimes.
            %
            % [ datetimeResult ] = Summation( startTime, time2Sum )
            %
            % <<< Function Inputs >>>
            %   string startTime
            %   string/single time2Sum
            %
            % <<< Function Outputs >>>
            %   datetime datetimeResult
            
            if isdatetime( time2Sum )
                                
                % summation
                datetimeResult = startTime + time2Sum;
                
            else
                                
                % summation
                datetimeResult = startTime + seconds( time2Sum );
                
            end
            
        end  
        
        
        %% Substraction
        
        function [datetimeResult ] = Substraction ( time2Substract, startTime )
            
            % Substraction of datetimes.
            %
            %  [datetimeResult ] = Substraction (startTime, time2Substract)
            %
            % <<< Function Inputs >>>
            %   string strStartTime
            %   string/single time2Substract
            %
            % <<< Function Outputs >>>
            %   string strResult
            
            % substraction
            datetimeResult = time2Substract - startTime;
            
        end  
        
        
    end
    
    
end




