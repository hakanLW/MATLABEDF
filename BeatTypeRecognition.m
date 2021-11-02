
% Beat Type Recognition
%
% [ qrsComplexes ] = BeatTypeRecognition( qrsComplexes )
%
% <<< Function Inputs >>>
%   struct qrsComplexes
%
% <<< Function outputs >>>
%   struct qrsComplexes

function [ qrsComplexes ] = BeatTypeRecognition( qrsComplexes )

if ~isempty( qrsComplexes.R )
    
    % Beat Types
    beatTypes = strings( length( qrsComplexes.R ) , 1 );
    % Normal beats
    beatTypes( 1:end ) = "N_";
    % Ventricular Beats
    beatTypes( qrsComplexes.VentricularBeats == true  ) = "V_"; %| qrsComplexes.VTBeats
    % Atrial Beats
    beatTypes( qrsComplexes.AtrialBeats == true  ) = "A_"; % | qrsComplexes.SVTBeats == true
    % Noise Beats
    beatTypes( qrsComplexes.NoisyBeat == true ) = "X_";
    
    if ~isempty( beatTypes )
        
        
        % ------- Check if there is ventricular beat ------- %
        
        if sum( count( beatTypes , "V_" ) )
            
            % ventricular beat characteristic
            ventricularBeatMorphs = find( beatTypes == "V_" );
            % ventricular beat types
            for beatIndex = 1 : length( ventricularBeatMorphs )
                beatTypes( ventricularBeatMorphs( beatIndex ) ) = ...
                    strrep( ...
                    beatTypes( ventricularBeatMorphs( beatIndex ) ) , ...
                    '_' , ...
                    num2str( qrsComplexes.BeatMorphology( ventricularBeatMorphs( beatIndex ) ) ) ...
                    );
            end            
            
        end
        
        % ------- Check if there is normal beat ------- %
        
        if sum( count( beatTypes , "N_" ) )
            
            % normal beat characteristic
            normalBeatMorphs = find( beatTypes == "N_" );
            % ventricular beat types
            for beatIndex = 1 : length( normalBeatMorphs )
                beatTypes( normalBeatMorphs( beatIndex ) ) = ...
                    strrep( ...
                    beatTypes( normalBeatMorphs( beatIndex ) ) , ...
                    '_' , ...
                    num2str( qrsComplexes.BeatMorphology( normalBeatMorphs( beatIndex ) ) ) ...
                    );
            end  
            
        end
                
        % ------- Check if there is atial beat ------- %
        
        if sum( count( beatTypes , "A_" ) )
            
            % atrial beat characteristic
            atrialBeatMorphs = find( beatTypes == "A_" );
            % ventricular beat types
            for beatIndex = 1 : length( atrialBeatMorphs )
                beatTypes( atrialBeatMorphs( beatIndex ) ) = ...
                    strrep( ...
                    beatTypes( atrialBeatMorphs( beatIndex ) ) , ...
                    '_' , ...
                    num2str( qrsComplexes.BeatMorphology( atrialBeatMorphs( beatIndex ) ) ) ...
                    );
            end  
            
        end
                
        % ------- Check if there is atial beat ------- %
        
        if sum( count( beatTypes , "X_" ) )
            
            % atrial beat characteristic
            noiseBeatMorphs = find( beatTypes == "X_" );
            % ventricular beat types
            for beatIndex = 1 : length( noiseBeatMorphs )
                beatTypes( noiseBeatMorphs( beatIndex ) ) = ...
                    strrep( ...
                    beatTypes( noiseBeatMorphs( beatIndex ) ) , ...
                    '_' , ...
                    num2str( qrsComplexes.BeatMorphology( noiseBeatMorphs( beatIndex ) ) ) ...
                    );
            end  
            
        end
        
    end
    
    % Unique Beat Types
    uniqueBeatTypes = char( unique( beatTypes ) );
    
    % For each beat type
    uniqueBeatCount = zeros( length( uniqueBeatTypes( :, 1 ) ), 1, 'single' );
    for beatTypeIndex = 1 : numel( uniqueBeatCount )
        % find the beat type indexes
        indexes = find( contains( beatTypes, strtrim( uniqueBeatTypes( beatTypeIndex, : ) ) ) );
        % clear beat types
        beatTypes( indexes ) = '';
        % define a class
        storeBeatTypeInfo.( strtrim( uniqueBeatTypes( beatTypeIndex, : ) ) ) = indexes;
        % store beat count
        uniqueBeatCount( beatTypeIndex ) = length( indexes );        
    end
    
    % For each beat form
    for beatTypeIndex = 1 : numel( uniqueBeatTypes( :, 1 ) )
        % find the max beat type count
        [ ~, maxCountIndex ] = max( uniqueBeatCount );
        % max numb beat type
        maxCountBeatType = strtrim( uniqueBeatTypes( maxCountIndex, : ) );
        % new beat type name
        newBeatType = [ maxCountBeatType( 1 ) num2str( beatTypeIndex  - 1 ) ];
        % change name
        beatTypes( storeBeatTypeInfo.( strtrim( uniqueBeatTypes( maxCountIndex, : ) ) ) ) = newBeatType;
        % Erase selected max
        uniqueBeatCount( maxCountIndex ) = 0;
    end
    
    % Output
    qrsComplexes.BeatFormType = beatTypes;
   
else
    
    % Output
    qrsComplexes.BeatFormType = single( [ ] );
    
end

end

