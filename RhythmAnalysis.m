
% Rhythm Analysis
%
% function [bradyRuns, tachyRuns, activityBasedHighHeartRateRuns] = ...
%     RhythmAnalysis (qrsComplexes, recordInfo, analysisParameters, matlabAPIConfig )
%
% <<< Function Inputs >>>
%   struct qrsComplexes
%   struct recordInfo
%   struct analysisParameters
%   struct matlabAPIConfig
%
% <<< Function outputs >>>
%   struct bradyRuns
%   struct tachyRuns
%   struct activityBasedHighHeartRateRuns

function [bradyRuns, tachyRuns, activityBasedHighHeartRateRuns] = ...
    RhythmAnalysis ( qrsComplexes, recordInfo, analysisParameters, matlabAPIConfig )

% Check if there is a detected beat
if isempty( qrsComplexes.R )
    
    % if there are no beats, then there is no need for detection
    bradyRuns = single( [ ] );
    tachyRuns = single( [ ] );
    activityBasedHighHeartRateRuns = single( [ ] );
    
else
    
    %
    %
    % Tachycardia and Bradcardia Runs Detection
    if matlabAPIConfig.IsLogWriteToConsole
        disp('- Heart rate calculation is completed.')
    end
    % Bradycardia and Tachycardia Runs
    [bradyRuns, tachyRuns] = ClassRhythmAnalysis.AbnormalRhythmRunDetection( ...
        qrsComplexes.HeartRate, ...
        qrsComplexes, ...
        analysisParameters.Bradycardia.ClinicThreshold , ...
        analysisParameters.Tachycardia.ClinicThreshold , ...
        round( 60 / ( analysisParameters.Asystole.ClinicThreshold / 1000 ) ), ...
        recordInfo.RecordStartTime, ...
        recordInfo.RecordSamplingFrequency );
    % End
    if matlabAPIConfig.IsLogWriteToConsole
        disp('- Bradycardia and tachycardia runs are detected.')
    end
    
    %
    %
    % Activity Based High Heart Rate Runs Detection
    if matlabAPIConfig.IsLogWriteToConsole
        disp('- Heart rate calculation is completed.')
    end
    % Activity Based High Heart Rate Runs
    if ~isempty( analysisParameters.ActivityPeriod ) && ~isempty( tachyRuns )
        [activityBasedHighHeartRateRuns, ~] = ClassRhythmAnalysis.ActivityBasedAnalysis( tachyRuns, analysisParameters.ActivityPeriod, analysisParameters.Tachycardia );
    else
        activityBasedHighHeartRateRuns = [ ];
    end
    % - End
    if matlabAPIConfig.IsLogWriteToConsole
        disp('- Activity based high heart rate runs are detected.')
    end
    
end

end




