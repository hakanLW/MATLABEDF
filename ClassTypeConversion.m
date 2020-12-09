classdef ClassTypeConversion
    
    % "ClassTypeConversion.m" class consists type conversion functions
    %
    % > ConvertMiliseconds2String
    % > ConvertChar2Datetime
    % > ConvertDuration2Miliseconds
    
    %% PROPERTIES
    
    properties
        
        %
        
    end
    
    %% STATIC METHODS
    
    
    methods (Static)
        
        
        %% Function to Milicseconds to String
        
        function [ stringArray ] = ConvertMiliseconds2String( msecArray )
            
            % Function for converting milicseconds to string array.
            %
            % [ stringArray ] = ConvertMiliseconds2String( msecArray )
            %
            % <<< Function Inputs >>>
            %   single msecArray: Numeric matrix of duration in terms of miliseconds.
            %
            % <<< Function Outputs >>>
            %   string stringArray: String matrix of duration in pre-determined duration format.
            %
            
            
            % PREALLOCATION
            stringArray = strings( length( msecArray ), 1);
            
            
            % PARTIAL 
            % - day
            days = floor(msecArray / 86400000);
            msecArray = msecArray - days * 86400000;
            % - hour
            hours = floor(msecArray / 3600000 );
            msecArray = msecArray - hours * 3600000;
            % - minute
            mins = floor(msecArray / 60000);
            msecArray = msecArray - mins * 60000;
            % second
            secs = floor( msecArray / 1000 );
            msecArray = msecArray - secs * 1000;
            
            
            % PARS
            for i = 1:length( msecArray )
                stringArray(i,:) = sprintf('%02d.%02d:%02d:%02d.%03d', days(i), hours(i), mins(i), secs(i), msecArray(i) );
            end
            
           
        end
        
        
        %% Function to Covert CharArray to CellArray
        
        function [ datetimeArray ] = ConvertChar2Datetime( charArray )
            
            % Function for converting char to datetime.
            %
            %[ datetimeArray ] = ConvertChar2Datetime( charArray )
            %
            % <<< Function Inputs >>>
            %   string charArray 
            %
            % <<< Function Outputs >>>
            %   datetime datetimeArray 
            %
            
            datetimeArray = datetime( charArray, 'Format','uuuu-MM-dd''T''HH:mm:ss.SSSXXX','TimeZone','UTC');
                
            
        end
        
        
        %% Function to Convert Duration to Miliseconds
        
        function [ miliseconds ] = ConvertDuration2Miliseconds( duration )
            
            % Function for converting duration to miliseconds
            %
            % [ miliseconds ] = ConvertDuration2Miliseconds( duration )
            %
            % <<< Function Inputs >>>
            %   duration duration
            %
            % <<< Function Outputs >>>
            %   single miliseconds
            %
                        
            miliseconds = fix( seconds( duration ) ) * 1000;
            
            
        end
        
        
    end
    
    
end

