function [ qrsComplexes, signalNoise ] = NoiseBeatClassificationNew( ecgSignal, qrsComplexes, recordInfo )
% NoiseBeatClassification
%   - ECG sinyalinde genlik tabanlý bir gürültü tespiti yapar
%   - Gürültülü bölgelerdeki QRS komplekslerini listeden temizler
%
% Giriþler:
%   ecgSignal   : 1D ECG sinyali (vektör)
%   qrsComplexes: QRS tespit sonuçlarýný içeren yapý (en azýndan R ve QRSAmplitude alanlarý olmalý)
%   recordInfo  : Kayýt bilgisi (RecordSamplingFrequency alaný olmalý)
%
% Çýkýþlar:
%   qrsComplexes: Gürültü içindeki QRS'ler temizlendikten sonraki yapý
%   signalNoise : Mantýksal vektör (true = gürültü olarak iþaretlenen örnek)

    % --- Gürültü tespiti (peak tabanlý) ---
    [ qrsComplexes, signalNoise ] = SignalPeakDetection( ecgSignal, qrsComplexes, recordInfo );

    % --- Gürültü içindeki QRS indekslerini bul ve temizle ---
    if ~isempty(qrsComplexes) && isfield(qrsComplexes,'R') && ~isempty(qrsComplexes.R)
        noisySamples = find( signalNoise );
        [ ~, noiseBeatIndexes ] = intersect( qrsComplexes.R, noisySamples );

        if ~isempty(noiseBeatIndexes)
            % QRS temizleme fonksiyonun
            qrsComplexes = ClassUnusualSignalDetection.ClearQRS( qrsComplexes, noiseBeatIndexes );
        end
    end

end


%% ------------------------------------------------------------------------
%% SubFunction: Signal Peak Detection (Gürültü tespiti)
%% ------------------------------------------------------------------------
function [ qrsComplexes, noiseFlag ] = SignalPeakDetection( ecgSignal, qrsComplexes, recordInfo )

    N  = length( ecgSignal );
    Fs = recordInfo.RecordSamplingFrequency;

    % Çýkýþ vektörü (baþta gürültü yok varsay)
    noiseFlag = false( N, 1 );

    % QRS yapýsý ve alanlarý kontrol
    if isempty(qrsComplexes) || ...
       ~isfield(qrsComplexes,'R') || isempty(qrsComplexes.R) || ...
       ~isfield(qrsComplexes,'QRSAmplitude') || isempty(qrsComplexes.QRSAmplitude)

        % Gerekli bilgiler yoksa gürültü tespiti yapmadan çýk
        return;
    end

    % --- QRS genliklerini al ve temizle ---
    qrsAmp = abs( double( qrsComplexes.QRSAmplitude(:) ) );
    qrsAmp = qrsAmp(~isnan(qrsAmp) & qrsAmp > 0);

    if isempty(qrsAmp)
        % Geçerli QRS genlik verisi yoksa, gürültü tespiti yapma
        return;
    end

    % --- Robust eþik hesaplama (optimum yaklaþým) ---
    % Outlier etkisini azaltmak için 5–95 persentiller arasý inlier'lar
    p5  = prctile(qrsAmp, 5);
    p95 = prctile(qrsAmp, 95);
    p99 = prctile(qrsAmp, 99);   % En yüksek normal QRS'leri temsil etsin

    inlierMask  = (qrsAmp >= p5) & (qrsAmp <= p95);
    inlierAmps  = qrsAmp(inlierMask);

    mu  = mean( inlierAmps );
    sd  = std( inlierAmps );

    % Temel eþik: ortalama + 3*std (QRS bandýnýn biraz üstü)
    baseThr = mu + 3 * sd;

    % Çok yüksek QRS'leri kaçýrmamak için 99. persentilin biraz üstüyle de kýyasla
    robustMaxQRS        = p99;
    qrsAmplitudeThreshold = max( baseThr, robustMaxQRS * 1.3 );  % 1.3–1.5 arasý oynanabilir

    % --- Gürültü adaylarýný iþaretle ---
    absSig = abs( double( ecgSignal(:) ) );
    noiseFlag( absSig > qrsAmplitudeThreshold ) = true;

    % --- Gürültü bloklarýný bul ---
    [ nStart, nEnd ] = BlockSegmentation( noiseFlag );

    if isempty(nStart)
        % Eþik aþan bölge yoksa direkt çýk
        noiseFlag(:) = false;
        return;
    end

    % --- Minimum süre filtresi (çok kýsa pikleri eliyoruz) ---
    minNoiseDuration_sec = 0.08;                           % min 80 ms
    minNoiseSamples      = round( minNoiseDuration_sec * Fs );

    blockLen = nEnd - nStart + 1;
    validIdx = blockLen >= minNoiseSamples;

    nStart = nStart(validIdx);
    nEnd   = nEnd(validIdx);

    if isempty(nStart)
        % Yeterince uzun gürültü bloðu kalmadýysa
        noiseFlag(:) = false;
        return;
    end

    % --- Gürültü bloklarýný makul miktarda geniþlet (örneðin ±200 ms) ---
    padding = round( 0.2 * Fs );  % 200 ms

    nStart = nStart - padding;
    nEnd   = nEnd   + padding;

    % Sýnýrlarý sinyal uzunluðuna kýrp
    nStart( nStart < 1 ) = 1;
    nEnd(   nEnd   > N ) = N;

    % noiseFlag'i bloklara göre yeniden oluþtur
    noiseFlag(:) = false;
    for i = 1:numel(nStart)
        noiseFlag( nStart(i) : nEnd(i) ) = true;
    end

end


%% ------------------------------------------------------------------------
%% SubFunction: Block Segmentation
%%   Mantýksal (0/1) sinyalde 1'lerin blok baþlangýç ve bitiþ indekslerini bulur
%% ------------------------------------------------------------------------
function [ blockStart, blockEnd ] = BlockSegmentation( binarySignal )

    binarySignal = binarySignal(:) ~= 0;          % Mantýksal vektör
    edges        = diff( [false; binarySignal; false] );

    blockStart   = find( edges ==  1 );           % 0 -> 1 geçiþleri
    blockEnd     = find( edges == -1 ) - 1;       % 1 -> 0 geçiþleri

end
