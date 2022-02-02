function[ qrsComplexes] = PrematureBeatEvaulation( qrsComplexes )
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


% 
% for control = 1:length(ectopics)
%     if (single(hR(control)<single(20))) && (ectopics(control+1)==true)
%         ectopics((control+1) : (control +11))=false;     
%     end
% end
% 
% for control = 1:length(ectopics)
%     if (hR(control)<20) && (ectopics(control+1)==true)
%         for control2 =control+1:control+10
%             if ectopics(control2)==true
%             ectopics((control+1))=false;
%             else
%                 break
%             end
%         end
%     end
% end
        
    
% % for p= 1:length(ectopics)-1
% %     if ectopics(p)==1 && ( (abs(heartRate(p)-hrChange(p+1))<=5 || hrChange(p+1) > hrChange(p)))
% %         ectopics(p+1)=1;
% %     end
% % end
% 
% %%%% POSSIBLE NORMAL%%%
% 
possibleNormal=zeros(length(deNoisyBeats),1);
possibleNormal(ectopics==0 & qrsComplexes.NoisyBeat==0 )=true;
% for b =1:length(ectopics)
%     if ectopics(b)==true
%         possibleNormal(b)=0;
%     end
% end

%% COMPENSATORY PAUSE %% 
RRI=4*25*qrsComplexes.RRInterval;
% denominator=zeros(length(RRI),1);
% denominator(1:3)=RRI(1:3);
% for r=4:length(RRI)
%     if(ectopics(r)==true && ectopics(r+1)==false && ectopics(r-1)==false )
%     denominator(r)=RRI(r-2);
%     else
%      denominator(r)=inf;
%     end
% end
% comp=zeros(length(RRI),1);
% for c =1:length(RRI)-1
%     if (single(RRI(c)+RRI(c+1))) >=single(1.90*denominator(c)) && denominator(c) ~=inf
%         comp(c)=true;
%     else
%         comp(c)=false;
%     end
% end
%%% duzeltme yapilacak %%%
comp=zeros(length(RRI),1);
for c =3:length(RRI)-1
    if (RRI(c)+RRI(c+1)) /(RRI(c-1)+RRI(c-2)) >= 0.94
        comp(c)=true;
    else
        comp(c)=false;
    end
end

interval= qrsComplexes.QRSInterval(ectopics==0 & qrsComplexes.NoisyBeat==0);
normalQRSInterval=mean(interval);
% 
% if normalQRSInterval>=0.07 && normalQRSInterval<=0.1
%     intervalTh=0.12;
% else
%     intervalTh=(normalQRSInterval*0.12)/0.07;
% end
    
%%%QRSInterval P Wave %%%
possibleVentricular=zeros(length(ectopics),1,'logical');
possibleAtrial=zeros(length(ectopics),1,'logical');

possibleVentricular(ectopics ==1 & single(qrsComplexes.QRSInterval) >= single(0.12) & qrsComplexes.P.StartPoint==1 &comp==true )=true;  
possibleAtrial(ectopics ==1 &  single(qrsComplexes.QRSInterval) < single(0.12) & single(hR)> single(90) &qrsComplexes.P.StartPoint >1 & comp==false )=true; 


undefinedEctopicBeats=(ectopics==true & possibleVentricular==false & possibleAtrial==false);  

% uEVindex= (undefinedEctopicBeats==1 & comp==true  );
% ueAIndex= (undefinedEctopicBeats==1 & comp== false );

uEVindex= (undefinedEctopicBeats==1 & comp==true & qrsComplexes.P.StartPoint==1 & single(qrsComplexes.QRSInterval) >= single(0.12)  );
ueAIndex= (undefinedEctopicBeats==1 & comp== false &single(hR)> single(90) &qrsComplexes.P.StartPoint>1  );

possibleAtrial(ueAIndex)=true;
possibleVentricular(uEVindex)=true;

possibleNormal=(~possibleAtrial & ~possibleVentricular & qrsComplexes.NoisyBeat==0);
 


for l =2: length(possibleNormal)

     if possibleNormal(l) ==1  && possibleNormal(l-1) ==1  %&&single(qrsComplexes.QRSInterval(l)) >= single(0.12)
         if(qrsComplexes.HeartRate(l)/qrsComplexes.HeartRate(l-1)) >1.15 && qrsComplexes.HeartRate(l-1) >20 && qrsComplexes.P.StartPoint(l)==1  && comp(l)==true && qrsComplexes.HeartRate(l) >90 && qrsComplexes.QRSInterval(l) > qrsComplexes.QRSInterval(l-1)
                possibleVentricular(l)=true;
          if(qrsComplexes.HeartRate(l)/qrsComplexes.HeartRate(l-1)) >1.15 && qrsComplexes.HeartRate(l-1) >20 && qrsComplexes.P.StartPoint(l)>1  && comp(l)==false && qrsComplexes.HeartRate(l) >90
                possibleAtrial(l)=true;
         end
         end
     end
end


% possibleNormal(possibleVentricular==true & possibleVentricular==true)=false;

%% COMPENSATORY PAUSE AND P WAVE %%% DUZELTME YAPILACAK
% 
% RRI=4*25*qrsComplexes.RRInterval;
% 
% for o= 1:length(qrsComplexes.R)
%     if possibleAtrial(o)==true && ectopics(o-1) ==false && ectopics(o+1) ==false &&  qrsComplexes.P.StartPoint(o)==1
%         if single(qrsComplexes.QRSInterval(o))>single(qrsComplexes.QRSInterval(o-1)) 
%             if (RRI(o) + RRI(o+1)) /(RRI(o-2)) >=2 
%                 possibleAtrial(o)=false;
%                 possibleVentricular(o)=true;
%             end
%         end
%     end
% end
% 
% for o= 1:length(qrsComplexes.R)
%     if possibleVentricular(o)==true && ectopics(o-1) ==false && ectopics(o+1) ==false &&  qrsComplexes.P.StartPoint(o)>1
%         if single(qrsComplexes.QRSInterval(o))>single(qrsComplexes.QRSInterval(o-1)) 
%             if (RRI(o) + RRI(o+1)) /(RRI(o-2)) >=2 
%                 possibleAtrial(o)=false;
%                 possibleVentricular(o)=true;
%             end
%         end
%     end
% end


% for c=1:length(ectopics)
%     if ectopics(c)==1 && qrsComplexes.QRSInterval(c) >=0.120
%         possibleVentricular(c)=t;
%     end
% end
% 
% Pa=find( ectopics==1 & possibleVentricular==0);
% for h =1:length(Pa)
%     possibleAtrial(Pa(h))=1;
% end
%   
% 
% %%% PWAVE %%%
% Adefect=find(possibleAtrial==1  & qrsComplexes.P.StartPoint ==1);
% 
% for l =1:length(Adefect)
%     possibleAtrial(Adefect(l))=0;
%     possibleVentricular(Adefect(l))=1;
% end
   
    
qrsComplexes.VentricularBeats=[ ];
qrsComplexes.AtrialBeats=[ ];
qrsComplexes.AtrialBeats=possibleAtrial;
qrsComplexes.VentricularBeats=possibleVentricular;


% qrsComplexes.VentricularBeats=possibleVentricular;

% x=qrsComplexes.QRSInterval(qrsComplexes.QRSInterval<0.120);
% y=qrsComplexes.QRSInterval(single(qrsComplexes.QRSInterval)<single(0.120));
% 
% x=length(x);
% y=length(y);
% 
% disp(' ')
% disp( '**********************************************************' )
% disp('Length x)')
% x
% disp('Length Single ')
% y
% disp('********************************** ')

end