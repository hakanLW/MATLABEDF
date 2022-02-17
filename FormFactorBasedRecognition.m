function [ qrsComplexes,similarity ] = FormFactorBasedRecognition( qrsComplexes,ecgSignal)

%% HEART RATE CHANGE %%
heartRate=qrsComplexes.HeartRate;
heartRate(1:10)=(mean(heartRate(qrsComplexes.NoisyBeat==0)));
deNoisyBeats=(qrsComplexes.NoisyBeat==0);


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
       for e=1:(d-1)
           if avg(d-e)>0
         hrChange(d)=single(hR(d)) /single(avg(d-e));
         break
           end
       end
    end
end
 %% ECTOPICS DETECTION       
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

%% PREMATURE BEAT CLASSIFICATION
possibleVentricular=zeros(length(qrsComplexes.R),1);


NormalMorph=find(qrsComplexes.BeatMorphology==0 & qrsComplexes.NoisyBeat==0 & ectopics==0 & qrsComplexes.P.StartPoint>1 ...
    & qrsComplexes.P.EndPoint>1 & qrsComplexes.HeartRate > 40 ...
    & qrsComplexes.HeartRate<100 );
NormalCondition=NormalMorph;
for n =2:length(NormalMorph)-1
    if qrsComplexes.HeartRate(NormalCondition(n)-1) ~= qrsComplexes.HeartRate(NormalCondition(n)+1)
        NormalCondition(n)=0;
    end
end
%BAK BURAYA
NormalCondition(NormalCondition==0)=[ ];
hrEV=qrsComplexes.HeartRate(NormalCondition);

if ~isempty(NormalCondition)
        [~,I]=min(hrEV);
        ind=I;
        disp('Nabza Dayali')
else
    L=length(NormalMorph);
    ind=round(L/2);
    disp('Normal Morfoloji')
end

disp("**** IND ****")
%ind
N=NormalMorph(ind);

% NormalMorph(qrsComplexes.BeatMorphology==0 & qrsComplexes.NoisyBeat==0 & ectopics==0 & qrsComplexes.P.StartPoint>1 & qrsComplexes.P.EndPoint>1 & qrsComplexes.T.StartPoint>1 & qrsComplexes.T.EndPoint>1) = true;
% for n =1:length(NormalMorph)-1
%     if ectopics(n+1) == 1 && NormalMorph(n) ==true
%         NormalMorph(n)=false;
%     end
% end
%         
% nM=find(NormalMorph==true);
% L=length(nM);
% ind=round(L/2);
% if ind==0
%     ind=1;
% end
% 
% N=nM(ind);


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
similarity=zeros(length(qrsComplexes.R),1);
QR=int64(qrsComplexes.R);

negative=QR(N)-int64(qrsComplexes.P.StartPoint(N));
positive=int64(92);
% nDir=qrsComplexes.R(N)-qrsComplexes.P.StartPoint(N);
% pDir=qrsComplexes.T.EndPoint(N)-qrsComplexes.R(N);
NormalTemplate=ecgSignal((QR(N)-negative):(QR(N)+positive));
% figure
% plot(NormalTemplate);
TargetTemplate=cell(length(qrsComplexes.R),1);
for i =1:length(qrsComplexes.R)
     TargetTemplate{i}=ecgSignal((QR(i)-negative):(QR(i)+positive));
%     plot(TargetTemplate)
     [R,~,~,~] = corrcoef(TargetTemplate{i},NormalTemplate,'Alpha',0.05);
     similarity(i)=R(1,2) ;
%      if R(1,2) <=0.90
%          possibleVentricular(i)=true;   
%      end
end
varN=var(NormalTemplate);
nDer=diff(NormalTemplate);
varN1=var(nDer);

mobilityN1=sqrt(varN1/varN);

nDer2=diff(nDer);
varN2=var(nDer2);

mobilityN2=sqrt(varN2/varN1);

formFactorN=mobilityN2/mobilityN1;
formFactorT=zeros(length(qrsComplexes.R),1);
for v =1:length(qrsComplexes.R)
    varT=var(TargetTemplate{v});
    tDer=diff(TargetTemplate{v});
    varT1=var(tDer);
    mobilityT1=sqrt(varT1/varT);
    
    tDer2=diff(tDer);
    varT2=var(tDer2);

    mobilityT2=sqrt(varT2/varT1);
    
    formFactorT(v)=mobilityT2/mobilityT1;
        
end

for o =1:length(similarity)
    if round(similarity(o)*exp(-(qrsComplexes.QRSInterval(o)/qrsComplexes.QRSInterval(N))),2,'significant') <0.3 && similarity(o) <0.95
          possibleVentricular(o)=true;   
    end
end

% %% P WAVE SIMILARITY %% 
% dirN= int64(qrsComplexes.Q(N))-int64(qrsComplexes.P.StartPoint(N));
% 
% NormalP=ecgSignal(int64(qrsComplexes.Q(N)):-1:(int64(qrsComplexes.Q(N))-dirN));
% pWaveSimilarity=zeros(length(qrsComplexes.R),1);
% for p =1:length(qrsComplexes.R)
%      TargetlP=ecgSignal(int64(qrsComplexes.Q(p)):-1:((int64(qrsComplexes.Q(p))-dirN)));
% %     plot(TargetTemplate)
%      [Rp,~,~,~] = corrcoef(TargetlP,NormalP,'Alpha',0.05);
%      pWaveSimilarity(p)=Rp(1,2) ;
% %      if R(1,2) <=0.90
% %          possibleVentricular(i)=true;   
% %      end
% end

  disp('### REFERENCE BEAT ###')
  disp(N)

%   possibleV=ones(length(qrsComplexes.R),1);
%   for t = 2:length(qrsComplexes.R)-1
%     if ((possibleVentricular(t) ==true && possibleVentricular(t+1) == true) ||  (possibleVentricular(t-1) ==true && possibleVentricular(t) == true)) && ((ectopics(t) ==1 && ectopics(t+1) ==1) || (ectopics(t) ==1 && ectopics(t-1) ==1))
%          if (qrsComplexes.QRSInterval(t) / qrsComplexes.QRSInterval(N) ) < 1.18
%               possibleV(t)=0;   
%          end
%     end
%   end
%  possibleVentricular(possibleV==0)=false;
%  
%  for v =1:length(possibleVentricular)
%      if similarity(v) >0.80 && (qrsComplexes.QRSInterval(v) / qrsComplexes.QRSInterval(N))< 1.18
%          possibleVentricular(v)=false;
%      end
%  end
%   
% 
%  [R,P,RL,RU] = corrcoef(TT,NormalTemplate,'Alpha',0.05);
zeros(length(qrsComplexes.R),1);
qrsComplexes.AtrialBeats=[];
qrsComplexes.VentricularBeats=[];
qrsComplexes.AtrialBeats=zeros(length(qrsComplexes.R),1,'logical');
qrsComplexes.VentricularBeats=zeros(length(qrsComplexes.R),1,'logical');
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

%  qrsComplexes.VentricularBeats(qrsComplexes.AtrialBeats(similarity<0))=true;
%  qrsComplexes.AtrialBeats(similarity<0)=false;

end