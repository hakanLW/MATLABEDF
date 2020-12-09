
% Plotting the findings
%
% PlotWaves(signal1, signal2, QRSComplexes, GetData2Observe )
%
% <<< Function Inputs >>>
%   single[n,1] signal1
%   single[n,1] signal2
%   struct QRSComplexes
%

function PlotWaves(signal1, QRSComplexes, Info )

close all;

if isempty(QRSComplexes) || isempty(QRSComplexes.R)
    
    % Beats
    rPoints = 1;
    qrsStartPoints = 1;
    qPoints = 1;
    sPoints = 1;
    qrsEndPoints = 1;
    TStartPoint = 1;
    TPeakPoint = 1;
    TEndPoint = 1;
    PStartPoint = 1;
    PPeakPoint = 1;
    PEndPoint = 1;
    VentricularPrematureBeats = 1;
    AtrialPrematureBeats = 1;
    NoiseBeats = 1;
    
else
    
    QRSComplexes.T.StartPoint = ones( length( QRSComplexes.R ), 1, 'single' );
    %     QRSComplexes.T.PeakPoint = ones( length( QRSComplexes.R ), 1, 'single' );
    QRSComplexes.T.EndPoint = ones( length( QRSComplexes.R ), 1, 'single' );
    %         QRSComplexes.T.Amplitude = ones( length( QRSComplexes.R ), 1, 'single' );
    QRSComplexes.T.Status = ones( length( QRSComplexes.R ), 1, 'single' );
    QRSComplexes.P.StartPoint = ones( length( QRSComplexes.R ), 1, 'single' );
    %     QRSComplexes.P.PeakPoint = ones( length( QRSComplexes.R ), 1, 'single' );
    QRSComplexes.P.EndPoint = ones( length( QRSComplexes.R ), 1, 'single' );
    %         QRSComplexes.P.Amplitude = ones( length( QRSComplexes.R ), 1, 'single' );
    QRSComplexes.Q = ones( length( QRSComplexes.R ), 1, 'single' );
    QRSComplexes.S = ones( length( QRSComplexes.R ), 1, 'single' );
    %     QRSComplexes.StartPoint = ones( length( QRSComplexes.R ), 1, 'single' );
    %     QRSComplexes.EndPoint = ones( length( QRSComplexes.R ), 1, 'single' );
    %     QRSComplexes.VentricularBeats = 1;
    %     QRSComplexes.FlutterBeats = 1;
    
    % Beats
    rPoints = QRSComplexes.R;
    qrsStartPoints = QRSComplexes.StartPoint;
    qPoints = QRSComplexes.Q;
    sPoints = QRSComplexes.S;
    qrsEndPoints = QRSComplexes.EndPoint;
    TStartPoint = QRSComplexes.T.StartPoint;
    TPeakPoint = QRSComplexes.T.PeakPoint;
    TEndPoint = QRSComplexes.T.EndPoint;
    PStartPoint = QRSComplexes.P.StartPoint;
    PPeakPoint = QRSComplexes.P.PeakPoint;
    PEndPoint = QRSComplexes.P.EndPoint;
    VentricularPrematureBeats = rPoints( QRSComplexes.VentricularBeats == 1 );
    AtrialPrematureBeats = rPoints( QRSComplexes.AtrialBeats == 1 );
    NoiseBeats = rPoints( QRSComplexes.NoisyBeat == 1 );
    
end

% BaselineFilter = movmean( signal1, 3 * 250 );
% signal2 = BaselineFilter;

% sampling freq
samplingFrequency = 250;

% time scale
timeSignal = transpose((0:(numel(signal1)-1))/samplingFrequency);

% last minute and last second determination
lastMinute = fix(numel(signal1)/250/60);
lastSecond = fix(numel(signal1)/250) - lastMinute*60;

%% Plotting

for min = 0 : lastMinute % min = ( lastMinute - 10 ) : lastMinute
    
    if min == lastMinute
    end
    
    % Error handling for signals shorter than 1 minute
    if lastSecond == 0 && min==lastMinute
        break;
    else
        figure
    end
    
    
    % Dividing a minute long signal into 20-sec parts for subplotting;
    for per20secs = 0:2
        
        % Buffer generation for each subplots
        dataStart = min*samplingFrequency*60 + per20secs*20*samplingFrequency + 1;
        dataStop = dataStart + 20*samplingFrequency - 1;
        if dataStop > numel( signal1 )
            dataStop = numel( signal1 );
        end
        
        % Determination of Waves in Interval
        RPoints = rPoints(find((rPoints>dataStart) & (rPoints<dataStop)));
        JAPoints = qrsStartPoints(find((qrsStartPoints>dataStart) & (qrsStartPoints<dataStop)));
        QPoints = qPoints(find((qPoints>dataStart) & (qPoints<dataStop)));
        SPoints = sPoints(find((sPoints>dataStart) & (sPoints<dataStop)));
        JBPoints = qrsEndPoints(find((qrsEndPoints>dataStart) & (qrsEndPoints<dataStop)));
        Ti = TStartPoint(find((TStartPoint>dataStart) & (TStartPoint<dataStop)));
        T = TPeakPoint(find((TPeakPoint>dataStart) & (TPeakPoint<dataStop)));
        Tf = TEndPoint(find((TEndPoint>dataStart) & (TEndPoint<dataStop)));
        Pi = PStartPoint(find((PStartPoint>dataStart) & (PStartPoint<dataStop)));
        P = PPeakPoint(find((PPeakPoint>dataStart) & (PPeakPoint<dataStop)));
        Pf = PEndPoint(find((PEndPoint>dataStart) & (PEndPoint<dataStop)));
        PVCPoints = VentricularPrematureBeats(find( ( VentricularPrematureBeats>dataStart) & (VentricularPrematureBeats<dataStop ) ) );
        PACPoints = AtrialPrematureBeats(find( ( AtrialPrematureBeats>dataStart) & (AtrialPrematureBeats<dataStop ) ) );
        NoiseBeatPoints = NoiseBeats(find( ( NoiseBeats>dataStart) & (NoiseBeats<dataStop ) ) );
        
        % Plotting
        subplot(3, 1, (per20secs+1));
        linspace(1,10,10);
        plot(timeSignal(dataStart:dataStop), signal1(dataStart:dataStop),'LineWidth',1.5); hold on
        scatter(timeSignal(RPoints), signal1(RPoints), 'v', 'filled', 'MarkerEdgeColor','k', 'MarkerFaceColor', 'k', 'LineWidth',1.5);
        scatter(timeSignal(JAPoints), signal1(JAPoints), 'r', 'MarkerEdgeColor','m', 'LineWidth',1);
        scatter(timeSignal(QPoints), signal1(QPoints), '^', 'MarkerEdgeColor','k', 'LineWidth',1);
        scatter(timeSignal(SPoints), signal1(SPoints), '^', 'MarkerEdgeColor','k', 'LineWidth',1);
        scatter(timeSignal(JBPoints), signal1(JBPoints), 'r', 'MarkerEdgeColor','m', 'LineWidth',1);
        scatter(timeSignal(Pi), signal1(Pi), 'x', 'MarkerEdgeColor','r', 'LineWidth',1.5);
        scatter(timeSignal(P), signal1(P), 'x', 'MarkerEdgeColor','r', 'LineWidth',1.5);
        scatter(timeSignal(Pf), signal1(Pf), 'x', 'MarkerEdgeColor','r', 'LineWidth',1.5);
        scatter(timeSignal(Ti), signal1(Ti), '+', 'MarkerEdgeColor','g', 'LineWidth',1.5);
        scatter(timeSignal(T), signal1(T), '+', 'MarkerEdgeColor','g', 'LineWidth',1.5);
        scatter(timeSignal(Tf), signal1(Tf), '+', 'MarkerEdgeColor','g', 'LineWidth',1.5);
        if ~isempty(PVCPoints )
            scatter(timeSignal(PVCPoints), signal1(PVCPoints), 'v', 'filled', 'MarkerEdgeColor','r', 'MarkerFaceColor', 'r', 'LineWidth',1.5);
            [ ~, PVCBeats, ~ ] = intersect( RPoints, PVCPoints );
            for i = 1 : length( PVCBeats )
                previousPrematureBeatStart = RPoints( PVCBeats( i ) ) - 20;
                previousPrematureBeatEnd = RPoints( PVCBeats( i ) ) + 20; if previousPrematureBeatEnd > length( signal1 );  previousPrematureBeatEnd = length( signal1 ); end
                plot( timeSignal( previousPrematureBeatStart:previousPrematureBeatEnd ), signal1( previousPrematureBeatStart:previousPrematureBeatEnd ), 'r', 'LineWidth',1.5);
            end
        end
        if ~isempty(PACPoints )
            scatter(timeSignal(PACPoints), signal1(PACPoints), 'v', 'filled', 'MarkerEdgeColor','g', 'MarkerFaceColor', 'g', 'LineWidth',1.5);
            [ ~, PVCBeats, ~ ] = intersect( RPoints, PACPoints );
            for i = 1 : length( PVCBeats )
                previousPrematureBeatStart = RPoints( PVCBeats( i ) ) - 20;
                previousPrematureBeatEnd = RPoints( PVCBeats( i ) ) + 20; if previousPrematureBeatEnd > length( signal1 );  previousPrematureBeatEnd = length( signal1 ); end
                plot( timeSignal( previousPrematureBeatStart:previousPrematureBeatEnd ), signal1( previousPrematureBeatStart:previousPrematureBeatEnd ), 'g', 'LineWidth',1.5);
            end
        end
        
        if ( min == 0 ) && ( per20secs == 0 )
            ylim( [ -3 4 ] )
        end
        
        if length( signal1 ) < 20 * 250
            xlim( [ 0 20 ] )
        end
        
        % Figure Parameters
        grid on;
        ylabel('Amplitude (mV)');
        if per20secs == 0
            title(['ECG Analysis'  ' | min: ' num2str(min) ' - ' num2str(min+1)]);
        end
        if per20secs == 2; xlabel('Time (secs)'); end
        
    end
    
    zoom on
    
    %     if ~mod( min + 1, 30 )
    %         close all;
    %     end
    
end

end