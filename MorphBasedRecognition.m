function [ qrsComplexes ] = MorphBasedRecognition( qrsComplexes,ecgSignal )
heartRate=qrsComplexes.HeartRate;
heartRate(1:10)=(mean(heartRate(qrsComplexes.NoisyBeat==0)));
deNoisyBeats=(qrsComplexes.NoisyBeat==0);
% qrsComplexesVetricularBeats( qrsComplexes.QRSInterval>= single( 0.120 ))=1;

for i =1:length(heartRate)
    if deNoisyBeats(i) == 0
        heartRate(i)=0;
    end
end

tL=cell(length(deNoisyBeats),1);
tempList=zeros(10,1);
hrChange=zeros(length(deNoisyBeats),1);
hrChange(1:10)=1;
for j =10:length(heartRate)
    count=1;
    for k =((j+1)-10):j
        if single(heartRate(k))>=single(40) && single(heartRate(k))<=single(180)
        tempList(count)=heartRate(k);
        
        else
         tempList(count)=0;  
        end
        count=count+1;
    end
    tL{k}=tempList; 
    tL{end}=zeros(10,1);
    
%     if nnz(tempList)==0
%       hrChange(j)= qrsComplexes.HeartRateChange(j);
%     else
%         avg=sum(tempList)/nnz(tempList);
%         hrChange(j)=heartRate(j)/avg;
%     end
  
tempList=zeros(10,1);
end
for u =10:length( tL)
    for z=2:9
        if tL{u,1}(z) == 0
            tL{u,1}(z+1)= 0;
            tL{u,1}(z-1) = 0;
        end
    end
end
avg=zeros(length(tL),1);
for y =10:length( tL)
    if nnz(tL{(y-1),1}) >=5
      avg(y)=sum(tL{(y-1),1})/nnz(tL{(y-1),1});
     
    else
     avg(y)=0;
    end
end

avg(1:10)=heartRate(1:10);
for y =10:length( tL)
    if nnz(tL{(y-1),1}) >=5
      avg(y)=sum(tL{(y-1),1})/nnz(tL{(y-1),1});
     
    else
     avg(y)=0;
    end
end
avg=round(avg);
hR=zeros(length(qrsComplexes.HeartRate),1);
hR(1:10)=round(mean(heartRate((qrsComplexes.NoisyBeat==0) & (single(qrsComplexes.HeartRate)>=single(50)) & (single(qrsComplexes.HeartRate)<=single(180)) )));
hR(11:length(qrsComplexes.HeartRate))=qrsComplexes.HeartRate(11:end);
% for h =1:lengt(hR)
%     if hr(h)<=10
%          hr(h)=hr(h+2);
%     end
% end
    
for d =11:length(tL)
    
    if avg(d)>0
        hrChange(d)=single(hR(d)) /single(avg(d));
    else
       for e=1:d
           if avg(d-e)>0
         hrChange(d)=single(hR(d)) /single(avg(d-e));
         break
           end
       end
    end
end
        
ectopics=zeros(length(hrChange),1,'logical');
ectopics((single(hrChange) >single(1.15) & single( hrChange)<single(3.5)))=true; 
ectopics(qrsComplexes.NoisyBeat==true)=false;

for m =2:length(ectopics)-1
     if qrsComplexes.HeartRate(m)<20 && ectopics(m+1)==true
         ectopics(m+1)=false;
    end
    if ((ectopics(m-1)==false)|| (qrsComplexes.NoisyBeat(m-1)==false)) && (ectopics(m)==true) 
        if (qrsComplexes.HeartRate(m) / qrsComplexes.HeartRate(m-1)) <1.15
             ectopics(m)=false;
        end
    end
end


% %%%
% possibleVentricular=zeros(length(qrsComplexes.R),1);
% NormalMorph=find(qrsComplexes.BeatMorphology==0 & qrsComplexes.NoisyBeat==0 & ectopics==0 );
% N=58224;
% NormalTemplate=ecgSignal(qrsComplexes.Q(N):qrsComplexes.S(N));
% 
%     TargetTemplate=ecgSignal(qrsComplexes.Q(12121):qrsComplexes.S(12121));
%     [r,lag]= xcorr(TargetTemplate,NormalTemplate);
%     [~,I] = max(abs(r));
%     SampleDiff = lag(I);
%     timeDiff = SampleDiff/250;
% %%%


possibleVentricular=zeros(length(qrsComplexes.R),1);

NormalMorph=find(qrsComplexes.BeatMorphology==0 & qrsComplexes.NoisyBeat==0 & ectopics==0 & qrsComplexes.P.StartPoint>1 & qrsComplexes.P.EndPoint>1 & qrsComplexes.T.StartPoint>1 & qrsComplexes.T.EndPoint>1);

L=length(NormalMorph);
ind=round(L/2);
if ind==0
    ind=1;
end

N=NormalMorph(ind);
% NormalTemplate=ecgSignal(qrsComplexes.Q(N):qrsComplexes.S(N));
% for i =1:length(qrsComplexes.R)
%     TargetTemplate=ecgSignal(qrsComplexes.Q(i):qrsComplexes.S(i));
%     [r,lag]= xcorr(TargetTemplate,NormalTemplate);
%     [~,I] = max(abs(r));
%     SampleDiff = lag(I);
%     timeDiff = SampleDiff/250;
%     
%     if timeDiff>0.0025
%         possibleVentricular(i)=true;
%     end
% end
NormalTemplate=ecgSignal((qrsComplexes.R(N)-40):(qrsComplexes.R(N)+90));
% figure
% plot(NormalTemplate);
for i =1:length(qrsComplexes.R)
     TargetTemplate=ecgSignal((qrsComplexes.R(i)-40):(qrsComplexes.R(i)+90));
%     plot(TargetTemplate)
     [R,P,RL,RU] = corrcoef(TargetTemplate,NormalTemplate,'Alpha',0.05);
     if R(1,2) <=0.90
         possibleVentricular(i)=true;   
     end
end

  disp('# REFERENCE BEAT...')
  N
  
  
% 
%  [R,P,RL,RU] = corrcoef(TT,NormalTemplate,'Alpha',0.05);
zeros(length(qrsComplexes.R),1);
qrsComplexes.AtrialBeats=[];
qrsComplexes.VentricularBeats=[];
qrsComplexes.AtrialBeats=zeros(length(qrsComplexes.R),1);
qrsComplexes.VentricularBeats=zeros(length(qrsComplexes.R),1);
qrsComplexes.VentricularBeats=(possibleVentricular==1 & qrsComplexes.NoisyBeat==0 & ectopics==1);
qrsComplexes.AtrialBeats=(ectopics==1 & possibleVentricular==false  & qrsComplexes.NoisyBeat==0);
for j =2:length(qrsComplexes.R)-1
    if qrsComplexes.VentricularBeats(j)==true && qrsComplexes.AtrialBeats(j-1)==true
        qrsComplexes.AtrialBeats(j-1)=false;
    end
     if qrsComplexes.VentricularBeats(j)==true && qrsComplexes.AtrialBeats(j+1)==true
        qrsComplexes.AtrialBeats(j+1)=false;
    end
end
end