
function hrvResults = HRVAnalysis( qrsComplexes, originalSignalDuration, analysisParameters, recordInfo )

% Beat Segmentation
% - Duration of the signal
% - seconds
signalDuration = fix( originalSignalDuration / recordInfo.RecordSamplingFrequency );
% - minute
signalDuration = fix( signalDuration / 60 );
% - minute resolution
minuteResolution = 5;
% hrv minute resolution
hrvResults.Resolution = minuteResolution;

% Check if there are beats
if ~isempty( qrsComplexes.R ) && ( signalDuration > 0 )
    
    % Get ubnormal beats
    ubnormalBeats = ...
        qrsComplexes.VentricularBeats |... % - ignore ventricular beats
        qrsComplexes.AtrialBeats | ... % - ignore atrial beats
        qrsComplexes.NoisyBeat; % - ignore noisy beats
    
    % Get ubnormal beat indexes
    % - ignore the last and the first beat
    ubnormalBeats( [ 1; length( qrsComplexes.R ) ] ) = true;
    ubnormalBeats = find( ubnormalBeats == true );
    ubnormalBeats = sort( unique( [ ubnormalBeats; ubnormalBeats + 1 ] ) );
    ubnormalBeats( ubnormalBeats > length( qrsComplexes.R ) ) = [ ];
    
    % Initialization
    % - keep indexes
    keepIndexes = cell( fix( signalDuration / minuteResolution ), 1 );
    % - hrv parameters
    hrvResults.sdnn = zeros( length( keepIndexes ), 1, 'single' );
    hrvResults.sdrr = zeros( length( keepIndexes ), 1, 'single' );
    sdann = zeros( length( keepIndexes ), 1, 'single' );
    hrvResults.rmssd = zeros( length( keepIndexes ), 1, 'single' );
    hrvResults.nn50 = zeros( length( keepIndexes ), 1, 'single' );
    hrvResults.pnn50 = zeros( length( keepIndexes ), 1, 'single' );
    hrvResults.meanRR = zeros( length( keepIndexes ), 1, 'single' );
    hrvResults.maxRR = zeros( length( keepIndexes ), 1, 'single' );
    hrvResults.minRR = zeros( length( keepIndexes ), 1, 'single' );
    hrvResults.meanHR = zeros( length( keepIndexes ), 1, 'single' );
    hrvResults.maxHR = zeros( length( keepIndexes ), 1, 'single' );
    hrvResults.minHR = zeros( length( keepIndexes ), 1, 'single' );
    
    % - segmentation
    count = 0;
    for  segmentIndex = double( 1 ) : double( minuteResolution ) : double( signalDuration )
        
        count = count + 1;
        % segment start/end
        % segmentIndex > minute > second > sampling
        segmentStartPoint = double( segmentIndex - 1 ) * double( 60 ) * double( recordInfo.RecordSamplingFrequency ) + double( 1 );
        segmentEndPoint = double( segmentIndex + ( minuteResolution - 1 ) ) * double( 60 ) * double( recordInfo.RecordSamplingFrequency );
        % get qrs indexes points
        allIndexes = find( ...
            ( ...
            ( qrsComplexes.R >= segmentStartPoint ) & ...
            ( qrsComplexes.R < segmentEndPoint ) & ...
            ( ( 1000 * qrsComplexes.RRInterval ) < analysisParameters.Asystole.ClinicThreshold ) ...
            ) == true ...
            );
        % ignore the first beat
        allIndexes( allIndexes < 2 ) = [ ];
        % indexes to remove: ventricular ectopics
        clearedIndexes = allIndexes;
        [ ~, indexes2Remove ] = intersect( allIndexes, ubnormalBeats );
        clearedIndexes( indexes2Remove ) = [ ];
        
        % index control
        if isempty( clearedIndexes ) && ( signalDuration < minuteResolution )
            
            % sdnn
            hrvResults.sdnn = single( [ ] );
            % sdrr
            hrvResults.sdrr = single( [ ] );
            % rmssd
            hrvResults.rmssd = single( [ ] );
            % nn50
            hrvResults.nn50 = single( [ ] );
            % pNN50
            hrvResults.pnn50= single( [ ] );
            % rr intervals
            hrvResults.meanRR = single( [ ] );
            hrvResults.maxRR = single( [ ] );
            hrvResults.minRR = single( [ ] );
            % heart rates
            hrvResults.meanHR = single( [ ] );
            hrvResults.maxHR = single( [ ] );
            hrvResults.minHR = single( [ ] );
            % sdann
            hrvResults.sdann = single( [ ] );
            % sdnn index
            hrvResults.sdnnIndex = single( [ ] );
            % segment count
            hrvResults.SegmentCount = single( 0 );
            
        elseif isempty( allIndexes ) || isempty( clearedIndexes ) || ( length( clearedIndexes ) < 10 )
            
            % sdnn
            hrvResults.sdnn( count ) = single( 0 );
            % sdrr
            hrvResults.sdrr( count ) = single( 0 );
            % rmssd
            hrvResults.rmssd( count ) = single( 0 );
            % nn50
            hrvResults.nn50( count ) = single( 0 );
            % pNN50
            hrvResults.pnn50( count ) = single( 0 );
            % rr intervals
            hrvResults.meanRR( count ) = single( 0 );
            hrvResults.maxRR( count ) = single( 0 );
            hrvResults.minRR( count ) = single( 0 );
            % heart rates
            hrvResults.meanHR( count ) = single( 0 );
            hrvResults.maxHR( count ) = single( 0 );
            hrvResults.minHR( count ) = single( 0 );
            % segment count
            hrvResults.SegmentCount = count;
            
        else
            
            % keep indexes
            keepIndexes( count ) = mat2cell( allIndexes, length( allIndexes ) );
            
            % sdnn
            hrvResults.sdnn( count ) = std( 1000 * qrsComplexes.RRInterval( clearedIndexes ) );
            if isnan( hrvResults.sdnn( count ) ); hrvResults.sdnn( count ) = 0; end
            % sdrr
            hrvResults.sdrr( count ) = std( 1000 * qrsComplexes.RRInterval( allIndexes ) );
            if isnan( hrvResults.sdrr( count ) ); hrvResults.sdrr( count ) = 0; end
            % sdann
            sdann( count ) = mean( 1000 * qrsComplexes.RRInterval( clearedIndexes ) );
            if isnan( sdann( count ) ); sdann( count ) = 0; end
            % rmssd
            rmssd_ = abs( diff( 1000 * qrsComplexes.RRInterval( clearedIndexes ) ) );
            hrvResults.rmssd( count ) = sqrt( mean( rmssd_ .* rmssd_ ) );
            if isnan( hrvResults.rmssd( count ) ); hrvResults.rmssd( count ) = 0; end
            % nn50
            nn50_ = abs( diff( 1000 * qrsComplexes.RRInterval( clearedIndexes ) ) );
            hrvResults.nn50( count ) = sum( nn50_ > 50 );
            if isnan( hrvResults.nn50( count ) ); hrvResults.nn50( count ) = 0; end
            % pNN50
            hrvResults.pnn50( count ) = hrvResults.nn50( count ) / length( clearedIndexes );
            if isnan( hrvResults.pnn50( count ) ); hrvResults.pnn50( count ) = 0; end
            % rr intervals
            hrvResults.meanRR( count ) = mean( 1000 * qrsComplexes.RRInterval( allIndexes ) );
            hrvResults.maxRR( count ) = max( 1000 * qrsComplexes.RRInterval( allIndexes ) );
            hrvResults.minRR( count ) = min( 1000 * qrsComplexes.RRInterval( allIndexes ) );
            % heart rates
            hrvResults.meanHR( count ) = 60 / ( hrvResults.meanRR( count ) / 1000 );
            hrvResults.maxHR( count ) = 60 / ( hrvResults.minRR( count ) / 1000 );
            hrvResults.minHR( count ) = 60 / ( hrvResults.maxRR( count ) / 1000 );
            % segment count
            hrvResults.SegmentCount = count;
           
            %last ten beats mean heart rate
            
  
            
            
        end
        
        %         % signal
        %         hrvResults.Signal.sdnn( segmentStartPoint : segmentEndPoint ) = ...
        %             hrvResults.sdnn( count )*ones( length( segmentStartPoint : segmentEndPoint ), 1, 'single' );
        %         hrvResults.Signal.sdrr( segmentStartPoint : segmentEndPoint ) = ...
        %             hrvResults.sdrr( count )*ones( length( segmentStartPoint : segmentEndPoint ), 1, 'single' );
        %         hrvResults.Signal.rmssd( segmentStartPoint : segmentEndPoint ) = ...
        %             hrvResults.rmssd( count )*ones( length( segmentStartPoint : segmentEndPoint ), 1, 'single' );
        
    end
    
    % sdann
    if ~isempty( sdann ); hrvResults.sdann = std( sdann );
    else; hrvResults.sdann = single( [ ] ); end
    % sdnn index
    if ~isempty( hrvResults.sdnn ); hrvResults.sdnnIndex = mean( hrvResults.sdnn );
    else; hrvResults.sdnnIndex = single( [ ] ); end
    
else
    
    % sdnn
    hrvResults.sdnn = single( [ ] );
    % sdrr
    hrvResults.sdrr = single( [ ] );
    % rmssd
    hrvResults.rmssd = single( [ ] );
    % nn50
    hrvResults.nn50 = single( [ ] );
    % pNN50
    hrvResults.pnn50= single( [ ] );
    % rr intervals
    hrvResults.meanRR = single( [ ] );
    hrvResults.maxRR = single( [ ] );
    hrvResults.minRR = single( [ ] );
    % heart rates
    hrvResults.meanHR = single( [ ] );
    hrvResults.maxHR = single( [ ] );
    hrvResults.minHR = single( [ ] );
    % sdann
    hrvResults.sdann = single( [ ] );
    % sdnn index
    hrvResults.sdnnIndex = single( [ ] );
    % segment count
    hrvResults.SegmentCount = single( 0 );
    
end

end