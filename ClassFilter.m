classdef ClassFilter
    
    % "ClassFilter.m" class consists filters needed in "ECG Analysis.m"
    %
    % > HighPassFilter
    % > LowPassFilter
    % > BandPassFilter
    % > StopBandFilter
    % > DerivativeFilter
    % > MovingAverageFilter
    
    %% PROPERTIES
    
    properties
        
        %
        
    end
    
    %% STATIC METHODS
    
    methods (Static)
      
        
        %% High Pass Filter
        
        function output = HighPassFilter(input, cutoffFreqHz, order, samplingFreqHz, filterType)
            
            % Butterworth High Pass Filter
            %
            % output = HighPassFilter(input, cutoffFreqHz, order, samplingFreqHz, filterType)
            %
            % <<< Function Inputs for butterworth filters >>>
            %   single[n,1] input 
            %   double cutoffFreqHz
            %   double order
            %   double samplingFreqHz
            %   string filterType
            %
            % <<< Function output for butterworth filters >>>
            %   single[n,1] output 
            
            switch filterType
                
                case 'filtfilt' % > needs double
                    
                    % If input signal is not double, convert its type to double;
                    if ~( isa(input, 'double') )
                        input = double(input);
                    end
                    
                    %%- filter coefficients
                    [filterNumCoef, filterDenCoef] = calculateFilterCoeffcients(cutoffFreqHz, order, samplingFreqHz, 'high');
                    %%- filtering signal
                    output = filtfilt(filterNumCoef,filterDenCoef,input);
                    %%- convert to signle
                    output = single(output);
                    
                case 'filter'
                    
                    % If input signal is not single, convert its type to single;
                    if ~( isa(input, 'single') )
                        input = single(input);
                    end
                    
                    %%- filter coefficients
                    [filterNumCoef, filterDenCoef] = calculateFilterCoeffcients(cutoffFreqHz, order, samplingFreqHz, 'high');
                    %%- filtering signal
                    output = filter(filterNumCoef,filterDenCoef,input);
                    
            end % switch filterType
            
        end % function output = HighPassFilter(input, cutoffFreqHz, order, samplingFreqHz, filterType)
        
        
        %% Low Pass Filter
        
        function output = LowPassFilter(input, cutoffFreqHz, order, samplingFreqHz, filterType)
            
            % Butterworth Low Pass Filter
            %
            % output = LowPassFilter(input, cutoffFreqHz, order, samplingFreqHz, filterType)
            %
            % <<< Function Inputs for butterworth filters >>>
            %   single[n,1] input 
            %   double cutoffFreqHz
            %   double order
            %   double samplingFreqHz
            %   string filterType
            %
            % <<< Function output for butterworth filters >>>
            %   single[n,1] output  
            
            switch filterType
                
                case 'filtfilt' % > needs double
                    
                    % If input signal is not double, convert its type to double;
                    if ~( isa(input, 'double') )
                        input = double(input);
                    end
                    
                    %%- filter coefficients
                    [filterNumCoef, filterDenCoef] = calculateFilterCoeffcients(cutoffFreqHz, order, samplingFreqHz, 'low');
                    %%- filtering signal
                    output = filtfilt(filterNumCoef,filterDenCoef,input);
                    %%- convert to signle
                    output = single(output);
                    
                case 'filter'
                    
                    % If input signal is not single, convert its type to single;
                    if ~( isa(input, 'single') )
                        input = single(input);
                    end
                    
                    %%- filter coefficients
                    [filterNumCoef, filterDenCoef] = calculateFilterCoeffcients(cutoffFreqHz, order, samplingFreqHz, 'low');
                    %%- filtering signal
                    output = filter(filterNumCoef,filterDenCoef,input);
                    
            end % switch filterType
            
        end % function output = LowPassFilter(input, cutoffFreqHz, order, samplingFreqHz, filterType)
    
        
        %% Band Pass Filter
        
        function output = BandPassFilter(input, cutoffFreqHz, order, samplingFreqHz, filterType)
            
            % Butterworth Band Pass Filter
            %
            % output = BandPassFilter(input, cutoffFreqHz, order, samplingFreqHz, filterType)
            %
            % <<< Function Inputs for butterworth filters >>>
            %   single[n,1] input  
            %   double cutoffFreqHz
            %   double order
            %   double samplingFreqHz
            %   string filterType
            %
            % <<< Function output for butterworth filters >>>
            %   single[n,1]  output 
            
            switch filterType
                
                case 'filtfilt' % > needs double
                    
                    % If input signal is not double, convert its type to double;
                    if ~( isa(input, 'double') )
                        input = double(input);
                    end
                    
                    %%- filter coefficients
                    [filterNumCoef, filterDenCoef] = calculateFilterCoeffcients(cutoffFreqHz, order, samplingFreqHz, 'bandpass');
                    %%- filtering signal
                    output = filtfilt(filterNumCoef,filterDenCoef,input);
                    %%- convert to signle
                    output = single(output);
                    
                case 'filter'
                    
                    % If input signal is not single, convert its type to single;
                    if ~( isa(input, 'single') )
                        input = single(input);
                    end
                    
                    %%- filter coefficients
                    [filterNumCoef, filterDenCoef] = calculateFilterCoeffcients(cutoffFreqHz, order, samplingFreqHz, 'bandpass');
                    %%- filtering signal
                    output = filter(filterNumCoef,filterDenCoef,input);
                    
            end % switch filterType
            
        end % output = BandPassFilter(input, cutoffFreqHz, order, samplingFreqHz, filterType)
  
        
        %% Stop Band Filter
        
        function output = StopBandFilter(input, cutoffFreqHz, order, samplingFreqHz, filterType)
            
            % Butterworth Stop Band Filter
            %
            % output = StopBandFilter(input, cutoffFreqHz, order, samplingFreqHz, filterType)
            %
            % <<< Function Inputs for butterworth filters >>>
            %   single[n,1]  input 
            %   double cutoffFreqHz
            %   double order
            %   double samplingFreqHz
            %   string filterType
            %
            % <<< Function output for butterworth filters >>>
            %   single[n,1]  output 
            
            switch filterType
                
                case 'filtfilt' % > needs double
                    
                    % If input signal is not double, convert its type to double;
                    if ~( isa(input, 'double') )
                        input = double(input);
                    end
                    
                    %%- filter coefficients
                    [filterNumCoef, filterDenCoef] = calculateFilterCoeffcients(cutoffFreqHz, order, samplingFreqHz, 'stop');
                    %%- filtering signal
                    output = filtfilt(filterNumCoef,filterDenCoef,input);
                    %%- convert to signle
                    output = single(output);
                    
                case 'filter'
                    
                    % If input signal is not single, convert its type to single;
                    if ~( isa(input, 'single') )
                        input = single(input);
                    end
                    
                    %%- filter coefficients
                    [filterNumCoef, filterDenCoef] = calculateFilterCoeffcients(cutoffFreqHz, order, samplingFreqHz, 'stop');
                    %%- filtering signal
                    output = filter(filterNumCoef,filterDenCoef,input);
                    
            end % switch filterType
            
        end % output = StopBandFilter(input, cutoffFreqHz, order, samplingFreqHz, filterType)
      
        
        %% Derivative Filter
        
        function output = DerivativeFilter(input, num, den, filterType)
            
            % Derivative Filter
            %
            % output = DerivativeFilter(input, num, den, filterType)
            %
            % <<< Function Inputs for derivative filters >>>
            %   single input [nx1]
            %   double num [1xn]
            %   double den [1xn]
            %   string filterType
            %
            % <<< Function output for butterworth filters >>>
            %   single output [nx1]
            
            switch filterType
                
                case 'filtfilt' % > needs double
                    
                    % If input signal is not double, convert its type to double;
                    if ~( isa(input, 'double') )
                        input = double(input);
                    end
                    
                    % Filter signal - filtfilt
                    output = filtfilt(num, den, input);
                    %%- convert to single
                    output = single(output);
                    
                case 'filter'
                    
                    % If input signal is not single, convert its type to single;
                    if ~( isa(input, 'single') )
                        input = single(input);
                    end
                    
                    % Filter signal - filter
                    output = filter(num, den, input);
                    
            end % switch filterType
            
        end % output = DerivativeFilter(input, filterCoefficients, filterType)

        
        %% MovingAverageFilter
        
        function output = MovingAverageFilter(input, windowSize, sameLength)
            
            % Moving Average Filter
            %
            % output = MovingAverageFilter(input, windowSize, sameLength)
            %
            % <<< Function Inputs for derivative filters >>>
            %   single[n,1]  input  
            %   single windowSize
            %   single sameLength
            %
            % <<< Function output for butterworth filters >>>
            %   single[n,1]  output  
            
            % If input signal is not single, convert its type to single;
            if ~( isa(input, 'single') )
                input = single(input);
            end
            
            % filter coefficients
            movingAverageCoef = ones(windowSize, 1) / ( windowSize );
            
            if sameLength
                % filter
                output = conv (input, movingAverageCoef, 'same');
            else
                % filter
                output = conv (input, movingAverageCoef);                
            end

        end
  
        
    end  
    
    
end  


%% PRIVATE FUNCTIONS

function [filterNumCoef, filterDenCoef] = calculateFilterCoeffcients(cutoffFreqHz, order, samplingFreqHz, type)

% Calculation of filter coefficients.
%
% [filterNumCoef, filterDenCoef] = calculateFilterCoeffcients(cutoffFreqHz, order, samplingFreqHz, type)
%
% <<< Function Inputs for derivative filters >>>
%   single cutoffFreqHz
%   single order
%   single samplingFreqHz
%   string type
%
% <<< Function output for butterworth filters >>>
%   single filterNumCoef
%   single filterDenCoef

%%- calculating normalized cuttof freq
Wn = cutoffFreqHz * 2 / samplingFreqHz;
%%- calculating filter coefficients
[filterNumCoef, filterDenCoef] = butter(order, Wn, type);

end


