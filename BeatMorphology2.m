function [ qrsComplexes, updatedMorphologies, noiseSample ] = BeatMorphology2( ecgSignal, qrsComplexes, recordInfo )
% BeatMorphology
%   - QRS atýmlarýnýn morfolojilerini çýkarýr ve kümeler
%   - Aþýrý uç (çok küçük / çok büyük) genlikli atýmlarý noise olarak iþaretler
%   - Noise atýmlarýn etrafýndaki örnekleri noiseSample ile iþaretler
%
% Giriþler:
%   ecgSignal      : Tek kanallý ECG sinyali (vektör)
%   qrsComplexes   : R (veya S), Type, StartPoint, EndPoint, QRSAmplitude alanlarýný içeren yapý
%   recordInfo     : RecordSamplingFrequency alanýný içeren yapý
%
% Çýkýþlar:
%   qrsComplexes        : BeatMorphology alaný doldurulmuþ QRS yapýsý
%   updatedMorphologies : Morfoloji þablonlarý ve istatistikleri
%   noiseSample         : Mantýksal vektör, noise olarak iþaretlenen örnekler

%% BOÞ DURUM
if isempty(qrsComplexes) || ~isfield(qrsComplexes,'R') || isempty(qrsComplexes.R)
    % QRS yoksa her þeyi boþ döndür
    qrsComplexes.BeatMorphology = [];
    updatedMorphologies.BeatInterval   = [];
    updatedMorphologies.BeatNumber     = [];
    updatedMorphologies.Morphologies   = [];
    updatedMorphologies.BeatDirection  = [];
    updatedMorphologies.MorphCounter   = int32(0);
    noiseSample = false(length(ecgSignal),1);
    return;
end

%% PARAMETRELER
fs              = recordInfo.RecordSamplingFrequency;
morpLength      = 76;      % her beat için örnek sayýsý (þablon uzunluðu)
preSamples      = 25;      % referans noktanýn soluna alýnacak örnek sayýsý
postSamples     = morpLength - preSamples - 1; % sað taraf
morphLimit      = 99;      % maksimum morfoloji sayýsý
corrAssignThr   = 0.90;    % mevcut bir morfa atanma alt eþiði
corrNewMorphThr = 0.75;    % yeni morfoloji oluþturma alt sýnýrý
alphaUpdate     = 0.30;    % centroid güncelleme katsayýsý

nBeats = numel(qrsComplexes.R);
N      = numel(ecgSignal);

% Çýkýþ preallocation
noiseSample = false(N,1);

%% 1) TÜM BEAT’LER ÝÇÝN PENCERE (MORFOLOJÝ SÝNYALÝ) ÇIKAR
[allBeatWindows, allBeatIntervalsSec] = extractBeatWindows( ...
    ecgSignal, qrsComplexes, fs, morpLength, preSamples, postSamples);

%% 2) GENLÝK TABANLI NOISE BEAT TESPÝTÝ (MUÇLAK DEÐÝL, KONSERVATÝF)
noiseBeatMask = detectNoiseBeatsAmplitudeBased(qrsComplexes);

% Noise atýmlarýn etrafýný noiseSample ile iþaretle (örneðin ±0.5 sn)
noiseSample = markNoiseSamplesAroundBeats(qrsComplexes, noiseBeatMask, N, fs, noiseSample);

% Noise atýmlarý QRS listesinden temizle
if any(noiseBeatMask)
    noiseBeatIdx = find(noiseBeatMask);
    % Bu indeksler QRS dizilerinde beat indeksleri, ClearQRS bunlarý silecek
    qrsComplexes = ClassUnusualSignalDetection.ClearQRS( qrsComplexes, noiseBeatIdx );
end

% Temizlendikten sonra hiç QRS kalmadýysa
if isempty(qrsComplexes.R)
    qrsComplexes.BeatMorphology = [];
    updatedMorphologies.BeatInterval   = [];
    updatedMorphologies.BeatNumber     = [];
    updatedMorphologies.Morphologies   = [];
    updatedMorphologies.BeatDirection  = [];
    updatedMorphologies.MorphCounter   = int32(0);
    return;
end

%% 3) NOISE TEMÝZLENDÝKTEN SONRA TEKRAR BEAT PENCERELERÝNÝ OLUÞTUR
[beatWindows, beatIntervalsSec] = extractBeatWindows( ...
    ecgSignal, qrsComplexes, fs, morpLength, preSamples, postSamples);

nBeatsClean = size(beatWindows,1);

%% 4) MORFOLOJÝ KÜMELEME (KORELASYON TABANLI, DAHA SIKI AYRIM)
% Çýktýlar:
%   clusterId        : her beat için morfoloji indexi (1..nMorph)
%   centroids        : [nMorph x morpLength]
[clusterId, centroids] = clusterMorphologies( ...
    beatWindows, qrsComplexes.Type, beatIntervalsSec, ...
    corrAssignThr, corrNewMorphThr, morphLimit, alphaUpdate );

% clusterId (1..K) -> BeatMorphology için atanacak
qrsComplexes.BeatMorphology = single(clusterId(:));  % geçici, henüz -1 kaydýrmadýk

%% 5) MORFOLOJÝ ÖZETLERÝNÝ OLUÞTUR (SAYI, ARALIK, YÖN VS.) VE SIRALA
updatedMorphologies = buildMorphologySummary( ...
    qrsComplexes, centroids, beatIntervalsSec, morpLength );

%% 6) DIÞ DÜNYAYA UYUMLU INDEX (0..K-1) DÖNDÜR
% Burada, BeatMorphology = [1..K] => [0..K-1] olacak
qrsComplexes.BeatMorphology = qrsComplexes.BeatMorphology - 1;

end % main function


%% ------------------------------------------------------------------------
%% ALT FONKSÝYON: Beat Pencerelerini Çýkar ve Normalize Et
function [beatWindows, beatIntervalsSec] = extractBeatWindows( ...
    ecgSignal, qrsComplexes, fs, morpLength, preSamples, postSamples)

nBeats = numel(qrsComplexes.R);
beatWindows      = zeros(nBeats, morpLength, 'single');
beatIntervalsSec = zeros(nBeats, 1, 'single');

for iBeat = 1:nBeats
    % Referans noktasý: normal tipteyse R, ters tipteyse S kullan
    if isfield(qrsComplexes,'Type') && qrsComplexes.Type(iBeat) <= 0 ...
            && isfield(qrsComplexes,'S') && ~isempty(qrsComplexes.S)
        refPoint = double(qrsComplexes.S(iBeat));
    else
        refPoint = double(qrsComplexes.R(iBeat));
    end

    startPoint = max(1, refPoint - preSamples);
    endPoint   = min(numel(ecgSignal), refPoint + postSamples);

    win = ecgSignal(startPoint:endPoint);

    % Uzunluk morpLength deðilse interpolate
    if numel(win) ~= morpLength
        xOld = linspace(1, morpLength, numel(win));
        xNew = 1:morpLength;
        win  = interp1(xOld, double(win(:))', xNew, 'linear', 'extrap')';
    else
        win = double(win(:));
    end

    % Normalizasyon (þekil odaklý olsun diye DC ve ölçek normalizasyonu)
    win = win - mean(win);
    maxAbs = max(abs(win)) + eps;
    win = win ./ maxAbs;

    beatWindows(iBeat,:)      = single(win(:))';
    % Beat interval (saniye cinsinden)
    beatIntervalsSec(iBeat,1) = single( ...
        (double(qrsComplexes.EndPoint(iBeat)) - double(qrsComplexes.StartPoint(iBeat)) + 1) / fs );
end

end


%% ------------------------------------------------------------------------
%% ALT FONKSÝYON: Genlik Tabanlý Noise Beat Tespiti (Konservatif)
function noiseBeatMask = detectNoiseBeatsAmplitudeBased(qrsComplexes)
% QRSAmplitude daðýlýmýna bak, aþýrý uçlarý noise olarak iþaretle

amps = double(qrsComplexes.QRSAmplitude(:));
medAmp = median(amps);
if medAmp <= 0
    % Patolojik bir durum, hiçbirini noise yapma
    noiseBeatMask = false(size(amps));
    return;
end

% Robust ölçek (MAD)
madAmp = mad(amps,1);
if madAmp == 0
    madAmp = medAmp / 10;
end

% Çok düþük ve çok yüksek genlik eþikleri (konservatif)
lowThr  = 0.10 * medAmp;        % medyanýn %10’dan küçükse
highThr = medAmp + 6 * madAmp;  % medyan + 6*MAD üstü

noiseBeatMask = (amps < lowThr) | (amps > highThr);
noiseBeatMask = noiseBeatMask(:);

end


%% ------------------------------------------------------------------------
%% ALT FONKSÝYON: Noise Beat’lerin Etrafýndaki Örnekleri Ýþaretle
function noiseSample = markNoiseSamplesAroundBeats(qrsComplexes, noiseBeatMask, signalLength, fs, noiseSample)

if nargin < 5 || isempty(noiseSample)
    noiseSample = false(signalLength,1);
end

noiseIdx = find(noiseBeatMask);
if isempty(noiseIdx)
    return;
end

padSec   = 0.25;  % beat etrafýnda ±0.5 sn
padSamples = round(padSec * fs);

for k = 1:numel(noiseIdx)
    bIdx = noiseIdx(k);

    if bIdx < 1 || bIdx > numel(qrsComplexes.StartPoint)
        continue;
    end

    startPoint = max(1, double(qrsComplexes.StartPoint(bIdx)) - padSamples);
    endPoint   = min(signalLength, double(qrsComplexes.EndPoint(bIdx)) + padSamples);

    noiseSample(startPoint:endPoint) = true;
end

end


%% ------------------------------------------------------------------------
%% ALT FONKSÝYON: Korelasyon Tabanlý Morfoloji Kümeleme
function [clusterId, centroids] = clusterMorphologies( ...
    beatWindows, beatTypes, beatIntervalsSec, ...
    corrAssignThr, corrNewMorphThr, morphLimit, alphaUpdate)

nBeats      = size(beatWindows,1);
morpLength  = size(beatWindows,2);

clusterId   = zeros(nBeats,1,'int32');
centroids   = zeros(0, morpLength, 'single');  % dinamik büyüyecek
morphCount  = [];   %#ok<NASGU>  % sadece açýklýk için, kullanmasak da sakýncalý deðil
nMorph      = 0;

for iBeat = 1:nBeats
    x = double(beatWindows(iBeat,:));  % zaten normalize ama yine de double alalým

    if nMorph == 0
        % Ýlk morfoloji
        nMorph = 1;
        centroids(1,:) = single(x);
        clusterId(iBeat) = int32(1);
    else
        % Mevcut centroid’lerle korelasyon
        corrVals = zeros(nMorph,1);
        for m = 1:nMorph
            corrVals(m) = CrossCorr(centroids(m,:), x);
        end

        [maxCorr, bestIdx] = max(corrVals);

        if maxCorr >= corrAssignThr
            % Güçlü benzerlik -> o morfa ata ve centroid’i güncelle
            clusterId(iBeat) = int32(bestIdx);
            centroids(bestIdx,:) = single( (1-alphaUpdate)*double(centroids(bestIdx,:)) + alphaUpdate*x );
        elseif maxCorr >= corrNewMorphThr
            % Orta seviyede benzerlik -> yine mevcut morfa ata ama centroid güncellemeyi daha az yapabilirdik
            clusterId(iBeat) = int32(bestIdx);
            centroids(bestIdx,:) = single( (1-alphaUpdate)*double(centroids(bestIdx,:)) + alphaUpdate*x );
        else
            % Benzer morf yok -> yeni morfoloji aç (limit aþýlmadýysa)
            if nMorph < morphLimit
                nMorph = nMorph + 1;
                centroids(nMorph,:) = single(x);
                clusterId(iBeat) = int32(nMorph);
            else
                % Limit doluysa en benzer olana ata
                clusterId(iBeat) = int32(bestIdx);
                centroids(bestIdx,:) = single( (1-alphaUpdate)*double(centroids(bestIdx,:)) + alphaUpdate*x );
            end
        end
    end
end

% Güvenlik: 0 clusterId kalmasýn
zeroIdx = (clusterId == 0);
if any(zeroIdx)
    clusterId(zeroIdx) = 1;
end

end


%% ------------------------------------------------------------------------
%% ALT FONKSÝYON: Morfoloji Özet Yapýsýný Oluþtur
function updatedMorphologies = buildMorphologySummary( ...
    qrsComplexes, centroids, beatIntervalsSec, morpLength)

clusterId = double(qrsComplexes.BeatMorphology(:));  % þu anda 1..K
clusterId(clusterId < 1) = 1;                        % güvenlik

uniqueMorphs = unique(clusterId);
nMorph       = numel(uniqueMorphs);

% Preallocation
Morphologies   = zeros(nMorph, morpLength, 'single');
BeatInterval   = zeros(nMorph, 1, 'single');
BeatCounter    = zeros(nMorph, 1, 'single');
BeatDirection  = zeros(nMorph, 1, 'single');

for k = 1:nMorph
    morphIdx = uniqueMorphs(k);

    beatMask = (clusterId == morphIdx);
    idxBeats = find(beatMask);

    % Þablon
    Morphologies(k,:) = centroids(morphIdx,:);

    % Beat interval (ortalama, saniye)
    if ~isempty(idxBeats)
        BeatInterval(k) = single(mean(beatIntervalsSec(idxBeats)));
    else
        BeatInterval(k) = single(0);
    end

    % Beat sayýsý
    BeatCounter(k) = single(numel(idxBeats));

    % Beat yönü (Type toplamý)
    if isfield(qrsComplexes,'Type') && ~isempty(qrsComplexes.Type)
        BeatDirection(k) = single(sum(qrsComplexes.Type(idxBeats)));
    else
        BeatDirection(k) = 0;
    end
end

% Morfolojileri beat sayýsýna göre azalan sýrala
[~, order] = sort(BeatCounter, 'descend');

Morphologies  = Morphologies(order,:);
BeatInterval  = BeatInterval(order,:);
BeatCounter   = BeatCounter(order,:);
BeatDirection = BeatDirection(order,:);

% QRS içindeki indexleri bu yeni sýraya göre yeniden eþle
mapOldToNew = zeros(max(uniqueMorphs),1);
for newIdx = 1:nMorph
    oldMorph = uniqueMorphs(order(newIdx));
    mapOldToNew(oldMorph) = newIdx;
end

clusterIdNew = zeros(size(clusterId));
for i = 1:numel(clusterId)
    cid = clusterId(i);
    if cid >= 1 && cid <= numel(mapOldToNew)
        clusterIdNew(i) = mapOldToNew(cid);
    else
        clusterIdNew(i) = 1;
    end
end

qrsComplexes.BeatMorphology = single(clusterIdNew);

% Çýkýþ yapýsý
updatedMorphologies.Morphologies  = Morphologies;
updatedMorphologies.BeatInterval  = round(BeatInterval, 4);
updatedMorphologies.BeatCounter   = BeatCounter;
updatedMorphologies.BeatDirection = BeatDirection;
updatedMorphologies.MorphCounter  = int32(nMorph);

end


%% ------------------------------------------------------------------------
%% ALT FONKSÝYON: Korelasyon Hesabý (orijinaline benzer)
function corr = CrossCorr(signal1, signal2)

signal1 = double(signal1(:));
signal2 = double(signal2(:));

Ex  = sum(signal1);
Ey  = sum(signal2);
Exy = sum(signal1.*signal2);
Exx = sum(signal1.*signal1);
Eyy = sum(signal2.*signal2);
n   = numel(signal1);

num = (n*Exy - Ex*Ey);
den = sqrt((n*Exx - Ex*Ex) * (n*Eyy - Ey*Ey)) + eps;

corr = num / den;
corr = max(min(corr,1),-1);   % numerik güvenlik
corr = round(corr, 4);

end
