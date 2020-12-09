% PLOT
close all;
% Plot the subplots
for MorphologyIndex = 1 : qrsMorphologies.MorphCounter
    
    % Max size is 4X4; 
    if ~mod( MorphologyIndex - 1, 16 )
        figure; subplotCounter = 1;
    else
        subplotCounter = subplotCounter + 1;
    end
    % Plot
    subplot( 4, 4, subplotCounter ); 
    if possibleVentricularMorphs( MorphologyIndex )
        plot( qrsMorphologies.Morphologies( MorphologyIndex, : ), 'r' );
    else
        plot( qrsMorphologies.Morphologies( MorphologyIndex, : ), 'k' );
    end
    title( [ ...
        ' Morph Type: ', num2str( MorphologyIndex ), ' [', num2str( qrsMorphologies.BeatInterval( MorphologyIndex ) ), ']' ...
        ' TypeCount: ', num2str( qrsMorphologies.BeatCounter( MorphologyIndex ) ) ...
        ] )
    axis tight; grid on;
    
end