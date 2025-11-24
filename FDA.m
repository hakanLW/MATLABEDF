function [FrequencyDomain] = FDA(signal, QRSComplexes, MatlabAPIConfigRequest, HolterRecordInfoRequest)
    % FDA - Frequency Domain Analysis (English plots with key metrics, no HR)
    %
    % Output: FrequencyDomain struct
    %   .Fs, .N
    %   .FrequencyHz, .AmplitudeSpectrum, .PowerSpectrum
    %   .FrequencyHz_0_40, .AmplitudeSpectrum_0_40, .PowerSpectrum_0_40
    %   .PSD_FrequencyHz, .PSD
    %   .BandPower        (raw band powers in 0–40 Hz)
    %   .BandPowerNorm    (percent distribution in 0–40 Hz)
    %   .DominantFrequency_Hz, .DominantAmplitude
    %   .SpectralCentroid_Hz, .SpectralBandwidth_Hz
    %   .SNR_dB, .LF_HF_Ratio, .LF_nu, .HF_nu
    %
    % Note: QRSComplexes and MatlabAPIConfigRequest are currently not used
    %#ok<*INUSD>

    % Ensure column vector
    ecg = signal(:);

    % Sampling frequency
    fs = HolterRecordInfoRequest.RecordSamplingFrequency;

    %% FFT (single-sided)
    N  = length(ecg);
    f  = (0:N-1) * (fs / N);     % double-sided frequency axis
    ECG_FFT = fft(ecg);          % FFT

    % Amplitude spectrum (normalized)
    P2 = abs(ECG_FFT / N);
    halfN = floor(N/2);
    P1 = P2(1:halfN+1);          % single-sided spectrum

    if numel(P1) > 2
        P1(2:end-1) = 2 * P1(2:end-1);
    end

    f1 = f(1:halfN+1);           % single-sided frequency axis
    PowerSpec = P1.^2;           % power spectrum

    %% Extract 0–40 Hz region
    idx_0_40 = f1 <= 40;
    f_0_40   = f1(idx_0_40);
    A_0_40   = P1(idx_0_40);
    Pow_0_40 = PowerSpec(idx_0_40);

    %% Welch PSD (0–Nyquist, display 0–40 Hz)
    winLength = min(4 * fs, N);  % 4-second Hamming window
    if winLength < 2 * fs
        winLength = min(fs, N);  % fallback to 1 second window
    end

    win = hamming(winLength);
    noverlap = floor(winLength / 2);
    nfft = max(2^nextpow2(winLength), 256);

    [PSD, f_psd] = pwelch(ecg, win, noverlap, nfft, fs);

    %% Spectral features
    [domAmp, domIdx] = max(P1);
    domFreq = f1(domIdx);

    totalPower = sum(PowerSpec);
    if totalPower > 0
        spectralCentroid  = sum(f1 .* PowerSpec) / totalPower;
        spectralBandwidth = sqrt(sum(((f1 - spectralCentroid).^2) .* PowerSpec) / totalPower);
    else
        spectralCentroid  = NaN;
        spectralBandwidth = NaN;
    end

    %% Bandpowers (0–40 Hz)
    % ECG-related bands:
    %   0.00–0.50 Hz  : Baseline wander
    %   0.50–5.00 Hz  : P & T waves
    %   5.00–15.0 Hz  : QRS complex
    %   15.0–40.0 Hz  : Muscle / high-frequency noise

    calcBand = @(fvec, pvec, fmin, fmax) ...
        sum(pvec(fvec >= fmin & fvec < fmax));

    BandPower.Baseline_0_0p5_Hz = calcBand(f_0_40, Pow_0_40, 0.00, 0.50);
    BandPower.P_T_0p5_5_Hz      = calcBand(f_0_40, Pow_0_40, 0.50, 5.00);
    BandPower.QRS_5_15_Hz       = calcBand(f_0_40, Pow_0_40, 5.00, 15.0);
    BandPower.Noise_15_40_Hz    = calcBand(f_0_40, Pow_0_40, 15.0, 40.0);
    BandPower.Total_0_40_Hz     = sum(Pow_0_40);

    % HRV-like bands (for reference)
    BandPower.VLF_0_0p04_Hz     = calcBand(f_0_40, Pow_0_40, 0.00, 0.04);
    BandPower.LF_0p04_0p15_Hz   = calcBand(f_0_40, Pow_0_40, 0.04, 0.15);
    BandPower.HF_0p15_0p40_Hz   = calcBand(f_0_40, Pow_0_40, 0.15, 0.40);

    %% Derived metrics (percentages, SNR, LF/HF, etc.)
    BandPowerNorm = struct();
    SNR_dB   = NaN;
    LF_HF    = NaN;
    LF_nu    = NaN;
    HF_nu    = NaN;

    if BandPower.Total_0_40_Hz > 0
        total0_40 = BandPower.Total_0_40_Hz;

        BandPowerNorm.Baseline_pct = 100 * BandPower.Baseline_0_0p5_Hz / total0_40;
        BandPowerNorm.P_T_pct      = 100 * BandPower.P_T_0p5_5_Hz      / total0_40;
        BandPowerNorm.QRS_pct      = 100 * BandPower.QRS_5_15_Hz       / total0_40;
        BandPowerNorm.Noise_pct    = 100 * BandPower.Noise_15_40_Hz    / total0_40;

        % SNR: QRS band vs (Baseline + Noise bands)
        signalPow = BandPower.QRS_5_15_Hz;
        noisePow  = BandPower.Noise_15_40_Hz + BandPower.Baseline_0_0p5_Hz;
        if noisePow > 0
            SNR_dB = 10 * log10(signalPow / noisePow);
        end

        % LF/HF ratio (HRV bands)
        LF  = BandPower.LF_0p04_0p15_Hz;
        HF  = BandPower.HF_0p15_0p40_Hz;
        VLF = BandPower.VLF_0_0p04_Hz; %#ok<NASGU>

        if HF > 0
            LF_HF = LF / HF;
        end

        denom = (LF + HF);  % exclude VLF from normalized units
        if denom > 0
            LF_nu = 100 * LF / denom;
            HF_nu = 100 * HF / denom;
        end
    end

    %% Fill output struct
    FrequencyDomain.Fs          = fs;
    FrequencyDomain.N           = N;
    FrequencyDomain.FrequencyHz = f1;
    FrequencyDomain.AmplitudeSpectrum  = P1;
    FrequencyDomain.PowerSpectrum      = PowerSpec;

    FrequencyDomain.FrequencyHz_0_40       = f_0_40;
    FrequencyDomain.AmplitudeSpectrum_0_40 = A_0_40;
    FrequencyDomain.PowerSpectrum_0_40     = Pow_0_40;

    FrequencyDomain.PSD_FrequencyHz = f_psd;
    FrequencyDomain.PSD             = PSD;

    FrequencyDomain.BandPower      = BandPower;
    FrequencyDomain.BandPowerNorm  = BandPowerNorm;

    FrequencyDomain.DominantFrequency_Hz = domFreq;
    FrequencyDomain.DominantAmplitude    = domAmp;
    FrequencyDomain.SpectralCentroid_Hz  = spectralCentroid;
    FrequencyDomain.SpectralBandwidth_Hz = spectralBandwidth;

    FrequencyDomain.SNR_dB      = SNR_dB;
    FrequencyDomain.LF_HF_Ratio = LF_HF;
    FrequencyDomain.LF_nu       = LF_nu;
    FrequencyDomain.HF_nu       = HF_nu;

    %% === CLINICAL PLOTS WITH ENGLISH ANNOTATIONS (NO HR) ===

    % Time domain (first 10 seconds)
    t = (0:N-1) / fs;
    maxTimeToShow = 10;
    idx_time = t <= maxTimeToShow;
    t_seg   = t(idx_time);
    ecg_seg = ecg(idx_time);

    % Band percentages for bar plot (cast to double explicitly)
    if BandPower.Total_0_40_Hz > 0
        baseline_pct = double(BandPowerNorm.Baseline_pct);
        pt_pct       = double(BandPowerNorm.P_T_pct);
        qrs_pct      = double(BandPowerNorm.QRS_pct);
        noise_pct    = double(BandPowerNorm.Noise_pct);
    else
        baseline_pct = 0; pt_pct = 0; qrs_pct = 0; noise_pct = 0;
    end

    figure('Name','ECG Frequency Domain Analysis','NumberTitle','off');

    %% 1) Time-domain ECG
    subplot(2,2,1);
    plot(t_seg, ecg_seg, 'LineWidth', 1);
    xlabel('Time (s)');
    ylabel('Amplitude (mV)');
    title('ECG – Time Domain (first 10 s)');
    grid on;

    % Annotation: basic recording info
    recDuration = N / fs;
    txt1 = { ...
        sprintf('Sampling rate: %.1f Hz', fs), ...
        sprintf('Total duration: %.1f s', recDuration), ...
        sprintf('Samples: %d', N) ...
    };
    text(0.02, 0.95, strjoin(txt1, '\n'), ...
        'Units','normalized', 'VerticalAlignment','top', ...
        'FontSize',8, 'BackgroundColor','w');

    %% 2) Amplitude Spectrum 0–40 Hz
    subplot(2,2,2);
    plot(f_0_40, A_0_40, 'LineWidth', 1);
    hold on;
    % Mark dominant frequency if within 0–40 Hz
    if ~isnan(domFreq) && domFreq <= 40
        plot(domFreq, domAmp, 'ro', 'MarkerSize',5, 'LineWidth',1);
    end
    hold off;
    xlabel('Frequency (Hz)');
    ylabel('Amplitude (a.u.)');
    title('Amplitude Spectrum (0–40 Hz)');
    xlim([0 40]);
    grid on;

    % Annotate key spectral features
    txt2 = {};
    if ~isnan(domFreq)
        txt2{end+1} = sprintf('Dominant freq: %.2f Hz', domFreq);
    end
    if ~isnan(spectralCentroid)
        txt2{end+1} = sprintf('Spectral centroid: %.2f Hz', spectralCentroid);
    end
    if ~isnan(spectralBandwidth)
        txt2{end+1} = sprintf('Spectral bandwidth: %.2f Hz', spectralBandwidth);
    end
    text(0.02, 0.95, strjoin(txt2, '\n'), ...
        'Units','normalized', 'VerticalAlignment','top', ...
        'FontSize',8, 'BackgroundColor','w');

    %% 3) Welch PSD (0–40 Hz) with SNR and LF/HF
    subplot(2,2,3);
    PSD_dB = 10*log10(PSD + eps);
    plot(f_psd, PSD_dB, 'LineWidth', 1);
    xlabel('Frequency (Hz)');
    ylabel('PSD (dB/Hz)');
    title('Welch Power Spectral Density');
    xlim([0 40]);
    grid on;

    txt3 = {};
    if ~isnan(SNR_dB)
        txt3{end+1} = sprintf('SNR (QRS vs Baseline+Noise): %.1f dB', SNR_dB);
    else
        txt3{end+1} = 'SNR: N/A';
    end
    if ~isnan(LF_HF)
        txt3{end+1} = sprintf('LF/HF ratio: %.2f', LF_HF);
    end
    if ~isnan(LF_nu) && ~isnan(HF_nu)
        txt3{end+1} = sprintf('LF_nu: %.1f%%, HF_nu: %.1f%%', LF_nu, HF_nu);
    end
    text(0.02, 0.95, strjoin(txt3, '\n'), ...
        'Units','normalized', 'VerticalAlignment','top', ...
        'FontSize',8, 'BackgroundColor','w');

    %% 4) Band power distribution (0–40 Hz)
    subplot(2,2,4);
    bandNames  = {'Baseline (0–0.5)', 'P&T (0.5–5)', 'QRS (5–15)', 'Noise (15–40)'};
    bandValues = double([baseline_pct, pt_pct, qrs_pct, noise_pct]);  % ensure double
    bar(bandValues);
    set(gca, 'XTickLabel', bandNames, 'XTickLabelRotation', 20);
    ylabel('Power (%)');
    title('Band Power Distribution (0–40 Hz)');
    grid on;

    % Show percentages above bars – ensure numeric doubles & finite
    ylimCurr = ylim;
    yRange   = ylimCurr(2) - ylimCurr(1);
    for k = 1:numel(bandValues)
        if ~isfinite(bandValues(k))
            continue; % skip NaN/Inf
        end
        xPos = double(k);
        yPos = double(bandValues(k)) + 0.02 * yRange;
        labelStr = sprintf('%.1f%%', bandValues(k));
        text(xPos, yPos, labelStr, ...
            'HorizontalAlignment','center', 'FontSize',8);
    end

end

