function [ qrsComplexes,similarity ] = MorphBasedRecognition3( qrsComplexes,ecgSignal)

%% HEART RATE CHANGE 

%First 10 Beat selection
heartRate=qrsComplexes.HeartRate;
heartRate(1:10)=(mean(heartRate(qrsComplexes.NoisyBeat==0)));
deNoisyBeats=(qrsComplexes.NoisyBeat==0);

%Resetting beats which have meaningless values
for i =1:length(heartRate)
    if deNoisyBeats(i) == 0 || heartRate(i)<40 || heartRate(i) >180
        heartRate(i)=0;
    end
end

tL=cell(length(deNoisyBeats),1); %Windows with 10 beats
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
tempList=zeros(10,1);
end

%Resetting beats which have meaningless values on each windows
for u =10:length( tL)
    for z=2:9
        if tL{u,1}(z) == 0
            tL{u,1}(z+1)= 0;
            tL{u,1}(z-1) = 0;
        end
    end
end

%Create Average Heart Beat List
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
avg=round(avg,2,'significant');
hR=zeros(length(qrsComplexes.HeartRate),1);
hR(1:10)=round(mean(heartRate((qrsComplexes.NoisyBeat==0) & (single(qrsComplexes.HeartRate)>=single(50)) & (single(qrsComplexes.HeartRate)<=single(180)) )));
hR(11:length(qrsComplexes.HeartRate))=qrsComplexes.HeartRate(11:end); 

%Finding Heart Rate Change by looking at windows 10 and calling back    
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
ectopics((single(hrChange) >single(1.15) & single( hrChange)<single(4)))=true; 
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

  
     
%% NORMAL BEAT SELECTION

possibleVentricular=zeros(length(qrsComplexes.R),1);


NormalMorph=find(qrsComplexes.BeatMorphology==0 & qrsComplexes.NoisyBeat==0 & ectopics==0 & qrsComplexes.P.StartPoint>1 ...
    & qrsComplexes.P.EndPoint>1 & qrsComplexes.HeartRate > 40 ...
    & qrsComplexes.HeartRate<100 );
NormalCondition=zeros(length(NormalMorph),1);

for n =2:length(NormalMorph)-1
    if qrsComplexes.HeartRate(NormalMorph(n)-1) ~= qrsComplexes.HeartRate(NormalMorph(n)+1)
        NormalCondition(n)=0;
    else
         NormalCondition(n)=NormalMorph(n);
    end
end
NormalCondition(NormalCondition==0)=[ ];

hrEV=zeros(length(qrsComplexes.HeartRate),1);
hrEV(NormalCondition)=qrsComplexes.HeartRate(NormalCondition);

hrEV(hrEV==0 & hrEV<45)=500;

if ~isempty(NormalCondition)
        [~,I]=min(hrEV);
        ind=I;
        disp('Nabza Dayali')
        N=ind;
else
    L=length(NormalMorph);
    ind=round(L/2);
    disp('Normal Morfoloji')
    N=NormalMorph(ind);
end

disp(" REFERENCE BEAT ###")
disp(N)


%% SIMILARITY CHECK
similarity=zeros(length(qrsComplexes.R),1);
QR=int64(qrsComplexes.R);

negative=QR(N)-int64(qrsComplexes.P.StartPoint(N));
positive=int64(92);

NormalTemplate=ecgSignal((QR(N)-negative):(QR(N)+positive));

for i =1:length(qrsComplexes.R)
     TargetTemplate=ecgSignal((QR(i)-negative):(QR(i)+positive));
     [R,~,~,~] = corrcoef(TargetTemplate,NormalTemplate,'Alpha',0.05);
     similarity(i)=R(1,2) ;

end

dyn=zeros(length(NormalMorph),1);
sym=zeros(length(NormalMorph),1);
for z=1:length(NormalMorph)
    dyn(z)=round(exp(-(qrsComplexes.QRSInterval(NormalMorph(z))/qrsComplexes.QRSInterval(N))),2,'significant');
    sym(z)=similarity(NormalMorph(z));
end
symMean=mean(sym);
symSTD=std(sym);
dynMean=mean(dyn);
dynSTD=std(dyn);
dynThresh=dynMean-dynSTD;
dynTreshSim=symMean-symSTD;

for o =1:length(similarity)
    if round(exp(-(qrsComplexes.QRSInterval(o)/qrsComplexes.QRSInterval(N))),2,'significant') <= dynThresh && similarity(o) <dynTreshSim
          possibleVentricular(o)=true;   
    end
end


% for o =1:length(similarity)
%     if round(similarity(o)*exp(-(qrsComplexes.QRSInterval(o)/qrsComplexes.QRSInterval(N))),2,'significant') <= 0.29 && similarity(o) <0.90
%           possibleVentricular(o)=true;   
%     end
% end

%% CREATE PAC AND PVC LISTS
zeros(length(qrsComplexes.R),1);
qrsComplexes.AtrialBeats=[];
qrsComplexes.VentricularBeats=[];
qrsComplexes.AtrialBeats=zeros(length(qrsComplexes.R),1,'logical');
qrsComplexes.VentricularBeats=zeros(length(qrsComplexes.R),1,'logical');
qrsComplexes.VentricularBeats=(possibleVentricular==1 & qrsComplexes.NoisyBeat==0 & ectopics==1);
qrsComplexes.AtrialBeats=(ectopics==1 & qrsComplexes.VentricularBeats==false  & qrsComplexes.NoisyBeat==0);
for j =2:length(qrsComplexes.R)-1
    if qrsComplexes.VentricularBeats(j)==true && qrsComplexes.AtrialBeats(j-1)==true
        qrsComplexes.AtrialBeats(j-1)=false;
    end
     if qrsComplexes.VentricularBeats(j)==true && qrsComplexes.AtrialBeats(j+1)==true
        qrsComplexes.AtrialBeats(j+1)=false;
    end
end

% % %% COMPENSATORY PAUSE
NRR=qrsComplexes.RRInterval(N);

for e=2:length(qrsComplexes.RRInterval)-1
    if ectopics(e-1)==false && ectopics(e+1)==false && qrsComplexes.AtrialBeats(e)==true && similarity(e) <0.95
        if   qrsComplexes.RRInterval(e) +qrsComplexes.RRInterval(e+1) >1.896*NRR 
            qrsComplexes.AtrialBeats(e)=false;
            qrsComplexes.VentricularBeats(e)=true;
        end
    end
end


        
%% TACHYCARDIA 


%  qrsComplexes.VentricularBeats(qrsComplexes.AtrialBeats(similarity<0))=true;
%  qrsComplexes.AtrialBeats(similarity<0)=false;

end