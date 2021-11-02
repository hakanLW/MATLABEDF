%% Maximum Heart Rate Detection

 function AverageHeartRateDetectionResults = AverageHeartRateDetection( qrsComplexes, heartRate ) 


newHeartRate = heartRate;
% 
% minIndeksArray=zeros(length(heartRate),1);
% maxIndeksArray=zeros(length(heartRate),1);

for index = 6 : length( heartRate ) - 1
    
    heartRateSum = 0;
    i=0;
%    maxRate=0;
%    minRate=1000;
  
    for index_internal = (index-5):(index-1)
        
        % Basic morphological conditions
        if  ( ~contains( qrsComplexes.BeatFormType( index_internal + 0 ), 'X' ) || ...
               ~contains( qrsComplexes.BeatFormType( index_internal + 1 ), 'X' )   )  
           
               % Basic HR conditions
               if (heartRate(index_internal) > 20 && ...
                    heartRate(index_internal) < 180 )
                        
                        heartRateSum = heartRateSum + heartRate(index_internal) ;
                        i=i+1;
               end
               
%                %Max HR
%                if heartRate(index_internal)> maxRate
%                    maxRate=heartRate(index_internal);
%                    maxIndeksArray(index)=index_internal;
%                end
%                
%                %Min HR
%                if heartRate(index_internal)< minRate
%                    minRate=heartRate(index_internal);
%                    minIndeksArray(index)=index_internal;
%                end
               
        end
        
    
    end
    
    if (i>3)
        newHeartRate(index) =double(heartRateSum)/double(i);
        
        %Handle first 5 beats
        if (index==6)
            newHeartRate(1:5) = newHeartRate(index);
        end
    
    else
        newHeartRate(index) = newHeartRate(index-1);
%         maxIndeksArray(index) = maxIndeksArray(index-1);
%         minIndeksArray(index) = minIndeksArray(index-1);
        
         %Handle first 5 beats
          if (index==6)
            newHeartRate(1:5) = mean(heartRate);
          end
        
    end

 end
 
 % Handle for last index
 newHeartRate(index) = newHeartRate(index-1);
 
 % Send calculations
AverageHeartRateDetectionResults.newHeartRate = int32(newHeartRate);
% AverageHeartRateDetectionResults.MinimumHeartRateBeatIndex=  minIndeksArray;
% AverageHeartRateDetectionResults.MaximumHeartRateBeatIndex=maxIndeksArray;

% hold on; plot( newHeartRate );
% ylim( [ 0 250 ] )
% disp( num2str( max( newHeartRate ) ) )

end