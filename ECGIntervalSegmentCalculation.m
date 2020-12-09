
% Calculation of the segments and intervals in ECG
%
% [ qrs ] = ECGIntervalSegmentCalculation( ecgSignal, qrs, recordInfo )
%
% <<< Function Inputs >>>
%   struct ecgSignal
%   struct qrs
%   struct recordInfo
%
% <<< Function outputs >>>
%   struct qrs

function [ qrs ] = ECGIntervalSegmentCalculation( ecgSignal, qrs, recordInfo )


if length( qrs.R ) >= 2
    
    % Get info
    samplingFreq = recordInfo.RecordSamplingFrequency;
    
    % Initialization
    samplePrecision = single( 3 );
    initialValue = single( 0 );
    
    % PR
    % -
    qrs.PRInterval = round( ( qrs.StartPoint - qrs.P.StartPoint ) / samplingFreq, samplePrecision);
    qrs.PRInterval( qrs.P.StartPoint == 1 ) = NaN;
    qrs.PRInterval( qrs.PRInterval < 0 ) = initialValue;
    qrs.PRInterval( isnan( ( qrs.PRInterval ) ) ) = single( 0 );
    % -
    qrs.PRSegment = round( ( qrs.StartPoint - qrs.P.EndPoint) / samplingFreq, samplePrecision);
    qrs.PRSegment( qrs.P.StartPoint == 1 ) = NaN;
    qrs.PRSegment( qrs.PRSegment < 0 ) = initialValue;
    qrs.PRSegment( isnan( ( qrs.PRSegment ) ) ) = single( 0 );
    % -
    qrs.P.Interval = round( ( qrs.P.EndPoint - qrs.P.StartPoint) / samplingFreq, samplePrecision);
    
    % ST
    % -
    qrs.STInterval = round( ( qrs.T.EndPoint - qrs.EndPoint) / samplingFreq, samplePrecision);
    qrs.STInterval( qrs.T.StartPoint == 1 ) = NaN;
    qrs.STInterval( qrs.STInterval < 0 ) = initialValue;
    qrs.STInterval( isnan( ( qrs.STInterval ) ) ) = single( 0 );
    % -
    qrs.STSegment = round( ( qrs.T.StartPoint - qrs.EndPoint) / samplingFreq, samplePrecision);
    qrs.STSegment( qrs.T.StartPoint == 1 ) = NaN;
    qrs.STSegment( qrs.STSegment < 0 ) = initialValue;
    qrs.STSegment( isnan( ( qrs.STSegment ) ) ) = single( 0 );
    % -
    qrs.T.Interval = round( ( qrs.T.EndPoint - qrs.T.StartPoint) / samplingFreq, samplePrecision);
    
    % QRS Interval
    % -
    qrs.QTInterval = round( ( qrs.T.EndPoint - qrs.StartPoint) / samplingFreq, samplePrecision);
    qrs.QTInterval( qrs.T.StartPoint == 1 ) = NaN;
    qrs.QTInterval( qrs.QTInterval < 0 ) = initialValue;
    qrs.QTInterval( isnan( ( qrs.QTInterval ) ) ) = single( 0 );
    % -
    qrs.RRInterval = round( ( diff( qrs.R ) ) / samplingFreq, samplePrecision);
    qrs.RRInterval = [ initialValue; qrs.RRInterval ];
    %- QTc interval calculation is made based on the Bazett Formula
    qrs.QTcInterval = round( ( qrs.QTInterval ./ sqrt( qrs.RRInterval ) ), samplePrecision );
    qrs.QTcInterval( qrs.QTcInterval == Inf ) = NaN;
    qrs.QTcInterval( isnan( ( qrs.QTcInterval ) ) ) = single( 0 );
    
    % QRS Characteristic
    % -
    jaAmplitude = ecgSignal( qrs.StartPoint );
    qAmplitude = ecgSignal( qrs.Q );
    rAmplitude = ecgSignal( qrs.R );
    sAmplitude = ecgSignal( qrs.S );
    jbAmplitude = ecgSignal( qrs.EndPoint );
    % -
    qrs.jaqAmplitude = jaAmplitude - qAmplitude;
    qrs.rqAmplitude = rAmplitude - qAmplitude;
    qrs.rsAmplitude = rAmplitude - sAmplitude;
    qrs.jbsAmplitude = jbAmplitude - sAmplitude;
    % -
    qrs.QCharacteristic = qrs.rqAmplitude ./ qrs.jaqAmplitude;
    qrs.SCharacteristic= qrs.rsAmplitude ./ qrs.jbsAmplitude;
    % -
    tempPEndPoint = qrs.P.EndPoint( 2:end);
    tempTStartPoint = qrs.T.StartPoint( 1:end-1);
    qrs.PTSegment = round( ( tempPEndPoint - tempTStartPoint ) / samplingFreq, samplePrecision);
    qrs.PTSegment( qrs.PTSegment < 0 ) = 0;
    qrs.PTSegment = [ 0; qrs.PTSegment ];
    % -
    tempPStartPoint = qrs.P.StartPoint( 2:end);
    tempTEndPoint = qrs.T.EndPoint( 1:end-1);
    qrs.PTInterval= round( ( tempPStartPoint - tempTEndPoint ) / samplingFreq, samplePrecision);
    qrs.PTInterval( qrs.PTInterval < 0 ) = 0;
    qrs.PTInterval = [ 0; qrs.PTInterval ];
    
else
    
    % PR
    qrs.PRInterval = [ ];
    % -
    qrs.PRSegment = [ ];
    % -
    qrs.P.Interval = [ ];
    
    % ST
    % -
    qrs.STInterval= [ ];
    % -
    qrs.STSegment = [ ];
    % -
    qrs.T.Interval = [ ];
    
    % QRS Interval
    % -
    qrs.QRSInterval = [ ];
    % -
    qrs.QTInterval = [ ];
    % -
    qrs.RRInterval = [ ];
    %-
    qrs.QTcInterval = [ ];
    
    % QRS Characteristic
    % -
    qrs.jaqAmplitude = [ ];
    qrs.rqAmplitude = [ ];
    qrs.rsAmplitude = [ ];
    qrs.jbsAmplitude = [ ];
    % -
    qrs.QCharacteristic = [ ];
    qrs.SCharacteristic = [ ]; 
    % -
    qrs.PTSegment = [ ];
    
    
end

end

