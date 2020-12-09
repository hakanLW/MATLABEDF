% PLOT
close all;
% Plot the subplots
for MorphologyIndex = 1 : length( updatedMorphologies.BeatCounter )
    
    % Max size is 4X4; 
    if ~mod( MorphologyIndex - 1, 16 )
        figure; subplotCounter = 1;
    else
        subplotCounter = subplotCounter + 1;
    end
    % Plot
    subplot( 4, 4, subplotCounter ); 
    plot( updatedMorphologies.Morphologies( MorphologyIndex, : ), 'k' );
    title( [ ...
        ' Morph Type: ', num2str( MorphologyIndex ), ' [', num2str( updatedMorphologies.BeatInterval( MorphologyIndex ) ), ']' ...
        ' TypeCount: ', num2str( updatedMorphologies.BeatCounter( MorphologyIndex ) ) ...
        ] )
    axis tight; grid on;
    
end