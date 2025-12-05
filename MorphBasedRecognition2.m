function [ qrsComplexes,similarity, NormalSample] = MorphBasedRecognition2( qrsComplexes,ecgSignal)

% Giriþ/çýkýþ yapýsý deðiþtirilmedi:
%  - Input:  qrsComplexes, ecgSignal
%  - Output: qrsComplexes, similarity, NormalSample

%% Kýsa kontrol: yeterli beat yoksa
if length(qrsComplexes.HeartRate) <= 15
    qrsComplexes.AtrialBeats      = [ ];
    qrsComplexes.VentricularBeats = [ ];
    similarity   = [ ];
    NormalSample = 0;
    return;
end

%% Temel deðiþkenleri hazýrla
R          = double(qrsComplexes.R(:));
nBeats     = length(R);
HR         = double(qrsComplexes.HeartRate(:));

if isfield(qrsComplexes,'NoisyBeat') && ~isempty(qrsComplexes.NoisyBeat)
    NoisyBeat = logical(qrsComplexes.NoisyBeat(:));
else
    NoisyBeat = false(nBeats,1);
end

% P dalgasý var mý?
hasP = false(nBeats,1);
if isfield(qrsComplexes,'P') && isfield(qrsComplexes.P,'StartPoint') && isfield(qrsComplexes.P,'EndPoint')
    Pstart = double(qrsComplexes.P.StartPoint(:));
    Pend   = double(qrsComplexes.P.EndPoint(:));
    hasP   = (Pstart > 1 & Pend > 1);
else
    Pstart = zeros(nBeats,1);
    Pend   = zeros(nBeats,1);
end

% BeatMorphology varsa normal morfoloji
if isfield(qrsComplexes,'BeatMorphology') && ~isempty(qrsComplexes.BeatMorphology)
    isNormalMorph = (qrsComplexes.BeatMorphology(:) == 0);
else
    isNormalMorph = true(nBeats,1);
end

%% 1) RR tabanlý ektopik beat tespiti (ectopics)
RR = diff(R);
RR = [RR(1); RR];      % ilk beat için ayný deðeri kullan

localRR = zeros(nBeats,1);
for i = 1:nBeats
    idx = max(1,i-5):min(nBeats,i+5);    % +-5 komþu
    idx = idx(~NoisyBeat(idx));          % gürültüsüz komþular
    if numel(idx) >= 3
        localRR(i) = mean(RR(idx));
    else
        localRR(i) = RR(i);
    end
end

% Erken beat: RR, lokal RR'in %80'inden kýsa ise
ectopics = false(nBeats,1);
validRR  = localRR > 0 & RR > 0;
ectopics(validRR) = RR(validRR) < 0.8 * localRR(validRR);

% Gürültülü beat'ler asla ektopik sayýlmasýn
ectopics(NoisyBeat) = false;

%% 2) Normal referans beat seçimi

% Aday normal beatler:
% 1. seviye: normal morfoloji + gürültüsüz + ektopik deðil + P var + HR 40–100
cand1 = isNormalMorph & ~NoisyBeat & ~ectopics & hasP & HR > 40 & HR < 100;
% 2. seviye: P þartýný kaldýr
cand2 = isNormalMorph & ~NoisyBeat & ~ectopics & HR > 40 & HR < 120;
% 3. seviye: sadece normal morfoloji + gürültüsüz + ektopik deðil
cand3 = isNormalMorph & ~NoisyBeat & ~ectopics;

normalIdx = find(cand1);
if isempty(normalIdx); normalIdx = find(cand2); end
if isempty(normalIdx); normalIdx = find(cand3); end
if isempty(normalIdx); normalIdx = find(~NoisyBeat); end
if isempty(normalIdx); normalIdx = 1; end

% Ortalama HR'e en yakýn beat referans olsun
meanHR         = mean(HR(normalIdx));
[~,minInd]     = min(abs(HR(normalIdx) - meanHR));
N              = normalIdx(minInd);
NormalSample   = int64(qrsComplexes.R(N));

%% 3) Morfolojik benzerlik (similarity) hesabý

QR = int64(qrsComplexes.R(:));

% Template penceresi: P baþlangýcý biliniyorsa oradan al, yoksa sabit
if Pstart(N) > 1
    negativeSamples = QR(N) - int64(Pstart(N));
    if negativeSamples < 20
        negativeSamples = 40;
    end
else
    negativeSamples = int64(40);
end
positiveSamples = int64(92);      % QRS + ST + T kýsmý için

sigLen = length(ecgSignal);

% Referans þablon
leftN  = QR(N) - negativeSamples;
rightN = QR(N) + positiveSamples;
leftN  = max(leftN,  1);
rightN = min(rightN, sigLen);

NormalTemplate = ecgSignal(leftN:rightN);
tplLen         = length(NormalTemplate);

similarity = zeros(nBeats,1);

for i = 1:nBeats

    % Gürültülü beat için similarity hesaplama
    if NoisyBeat(i)
        similarity(i) = 0;
        continue;
    end

    li = QR(i) - negativeSamples;
    ri = QR(i) + positiveSamples;

    if li < 1 || ri > sigLen
        similarity(i) = 0;
        continue;
    end

    TargetTemplate = ecgSignal(li:ri);

    % Uzunluk farký varsa kýrp
    if length(TargetTemplate) ~= tplLen
        Lmin           = min(length(TargetTemplate), tplLen);
        TargetTemplate = TargetTemplate(1:Lmin);
        NormTmp        = NormalTemplate(1:Lmin);
    else
        NormTmp = NormalTemplate;
    end

    Rmat = corrcoef(double(TargetTemplate), double(NormTmp));
    similarity(i) = Rmat(1,2);
end

%% 4) PVC / PAC sýnýflandýrma

qrsComplexes.AtrialBeats      = false(nBeats,1);
qrsComplexes.VentricularBeats = false(nBeats,1);

% QRS interval oraný (referans beat'e göre)
if isfield(qrsComplexes,'QRSInterval') && ~isempty(qrsComplexes.QRSInterval)
    QRS      = double(qrsComplexes.QRSInterval(:));
    refQRS   = QRS(N);
    if refQRS <= 0
        refQRS = median(QRS(QRS>0));
        if isempty(refQRS) || isnan(refQRS)
            refQRS = 1;
        end
    end
    relQRS = QRS / refQRS;
else
    relQRS = ones(nBeats,1);
end

% Eþikler
simPVC_th   = 0.70;   % PVC için: normal template'e benzerlik düþük
simPAC_th   = 0.70;   % PAC için: normal template'e benzerlik yüksek
wideQRS_th  = 1.20;   % referans QRS'in %20 üstü = geniþ
earlyRR_th  = 0.75;   % RR < 0.75*localRR ise erken
pauseRR_th  = 1.10;   % RR > 1.1*localRR ise kompansatuvar pause

PVC = false(nBeats,1);
PAC = false(nBeats,1);

for i = 2:nBeats-1

    % Gürültülü beat'e asla sýnýflama yapma
    if NoisyBeat(i)
        continue;
    end

    % Ektopik deðilse PAC/PVC arama
    if ~ectopics(i)
        continue;
    end

    baseRR = localRR(i);
    if baseRR <= 0
        baseRR = RR(i);
    end

    isEarly  = (RR(i) < earlyRR_th * baseRR);
    hasPause = (RR(i+1) > pauseRR_th * baseRR);
    isWide   = (relQRS(i) > wideQRS_th);
    corrVal  = similarity(i);
    hasPbeat = hasP(i);

    % --- PVC kriteri ---
    %  - Ektopik
    %  - Geniþ QRS
    %  - Korelasyon düþük
    %  - Erken + kompansatuvar pause
    if isWide && isEarly && hasPause && (corrVal < simPVC_th)
        PVC(i) = true;
        continue;
    end

    % --- PAC kriteri ---
    %  - Ektopik
    %  - Dar QRS (relQRS ~ 1)
    %  - Korelasyon yüksek
    %  - P dalgasý var
    %  - Erken, ama arkasýndan aþýrý uzun pause yok
    if ~isWide && (corrVal >= simPAC_th) && hasPbeat && isEarly && (RR(i+1) < 1.3*baseRR)
        PAC(i) = true;
    end
end

% Gürültülülerde yine de güvence: asla PAC/PVC olmasýn
PVC(NoisyBeat) = false;
PAC(NoisyBeat) = false;

% Çakýþma durumunda PVC öncelikli olsun
PAC(PVC) = false;

qrsComplexes.VentricularBeats = PVC;
qrsComplexes.AtrialBeats      = PAC;

end
