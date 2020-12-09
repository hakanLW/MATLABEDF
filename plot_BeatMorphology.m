% PLOT
close all;
for MorphologyIndex = 1 : Morphologies.Counter
    
    % Max size is 4X4;
    if ~mod( MorphologyIndex - 1, 16 )
        figure; subplotCounter = 1;
    else
        subplotCounter = subplotCounter + 1;
    end
    % Plot
    subplot( 4, 4, subplotCounter );
    plot( ( Morphologies.BeatSignal( MorphologyIndex, : ) ), 'k' );
    title( [ ...
        ' Morph Type: ', num2str( MorphologyIndex ), ' [', num2str( Morphologies.BeatInterval( MorphologyIndex ) ), ']' ...
        ' TypeCount: ', num2str( Morphologies.BeatCounter( MorphologyIndex ) ) ...
        ] )
    axis tight; grid on;
    
end