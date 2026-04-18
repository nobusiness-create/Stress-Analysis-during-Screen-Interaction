
%% 1: Load Data
load('bidmc_data.mat');       

subj = data(1);               
ppg  = double(subj.ppg.v);   % raw PPG signal values
fs   = double(subj.ppg.fs);  % sampling rate = 125 Hz

time = (0:length(ppg)-1) / fs;   % time axis in seconds


%% 2: Raw Signal
figure(1); clf;
plot(time, ppg, 'b');
title('Raw PPG Signal');
xlabel('Time (s)');
ylabel('Amplitude (a.)');
grid on;


%% 3: Butterworth Bandpass Filter

order   = 4;
low_hz  = 0.5;
high_hz = 4.0;

[b, a]       = butter(order, [low_hz high_hz] / (fs/2), 'bandpass');
ppg_filtered = filtfilt(b, a, ppg);   % zero-phase filtering

% Plot raw vs filtered
figure(2); clf;
subplot(2,1,1);
plot(time, ppg, 'b');
title('Raw PPG');
xlabel('Time (s)'); 
ylabel('Amplitude');
grid on; xlim([0 30]);

subplot(2,1,2);
plot(time, ppg_filtered, 'k');
title('Filtered PPG — Butterworth Bandpass (0.5–4 Hz)');
xlabel('Time (s)'); 
ylabel('Amplitude');
grid on; xlim([0 30]);


%% 4: Peak Detection (Heartbeats)

min_dist = round(0.5 * fs);                                 % 0.5 sec gap
min_prom = 0.3 * (max(ppg_filtered) - min(ppg_filtered));    

[pks, locs] = findpeaks(ppg_filtered, ...
    'MinPeakDistance', min_dist, ...
    'MinPeakProminence', min_prom);

% Plot peaks
figure(3); clf;
plot(time, ppg_filtered, 'k'); hold on;
plot(time(locs), pks, 'o');
title('Filtered PPG with Detected Peaks');
xlabel('Time (s)');
ylabel('Amplitude');
grid on; xlim([0 30]);


%% 5: RR Intervals (Beat-to-Beat Timing)

% Safety check
if length(locs) < 2
    error('Not enough peaks detected. Adjust filter or peak settings.');
end

rr_samples = diff(locs);           % gap between peaks in samples
rr_seconds = rr_samples / fs;      % convert to seconds
rr_time    = time(locs(2:end));    % time axis for each RR interval

% Sanity check — remove physiologically impossible values
valid      = rr_seconds > 0.3 & rr_seconds < 2.0;   % 30–200 BPM range
rr_seconds = rr_seconds(valid);
rr_time    = rr_time(valid);

% Plot RR tachogram
figure(4); clf;
plot(rr_time, rr_seconds, 'b.-');
title('RR Interval Tachogram (Beat-to-Beat Variability)');
xlabel('Time (s)'); ylabel('RR Interval (seconds)');
ylim([0.4 1.2]); grid on;


%% SECTION 6: HRV Feature Extraction

mean_rr = mean(rr_seconds);
mean_hr = 60 / mean_rr;                               % BPM
sdnn    = std(rr_seconds);                            % overall variability
rmssd   = sqrt(mean(diff(rr_seconds).^2));            % short-term variability

% pNN50
nn50  = sum(abs(diff(rr_seconds)) > 0.05);
pnn50 = (nn50 / length(rr_seconds)) * 100;


%% SECTION 7: Frequency Domain (HRV Metrics Only)

rr_uniform_fs = 4;
t_uniform     = rr_time(1) : 1/rr_uniform_fs : rr_time(end);

rr_uniform = interp1(rr_time, rr_seconds, ...
                     t_uniform, 'spline', 'extrap');

N   = length(rr_uniform);
f   = (0:N-1) * (rr_uniform_fs / N);
psd = abs(fft(rr_uniform - mean(rr_uniform))).^2 / N;

lf_idx   = f >= 0.04 & f <= 0.15;
hf_idx   = f >= 0.15 & f <= 0.40;

lf_power = sum(psd(lf_idx));
hf_power = sum(psd(hf_idx));

if hf_power == 0
    lf_hf = NaN;
else
    lf_hf = lf_power / hf_power;
end


%% SECTION 8: Summary Dashboard

figure(5); clf;
set(gcf, 'Name', 'PPG Analysis Dashboard', 'NumberTitle', 'off', ...
         'Position', [100 100 1200 700]);

subplot(3,2,1);
plot(time(time<=30), ppg(time<=30), 'b');
title(' Raw PPG Signal'); xlabel('Time (s)'); grid on;

subplot(3,2,2);
plot(time(time<=30), ppg_filtered(time<=30), 'k');
title(' Filtered PPG'); xlabel('Time (s)'); grid on;

subplot(3,2,3);
t30 = time <= 30;
in_range = locs(time(locs) <= 30);

plot(time(t30), ppg_filtered(t30), 'k'); hold on;
plot(time(in_range), ppg_filtered(in_range), 'ro', ...
     'MarkerFaceColor', 'r');
title(' Peak Detection'); xlabel('Time (s)'); grid on;

subplot(3,2,4);
plot(rr_time, rr_seconds, 'b.-');
title(' RR Tachogram'); xlabel('Time (s)');
ylabel('RR (s)'); grid on;

subplot(3,2,5);
metrics = [sdnn, rmssd, pnn50/100];
bar(metrics);
set(gca, 'XTickLabel', {'SDNN','RMSSD','pNN50'});
title(' HRV Metrics'); grid on;

subplot(3,2,6);
hrv_labels = {'Mean HR','SDNN','RMSSD','pNN50','LF/HF'};
hrv_vals   = [mean_hr, sdnn*1000, rmssd*1000, pnn50, lf_hf];

barh(hrv_vals);
set(gca, 'YTickLabel', hrv_labels);
title(' HRV Summary'); grid on;

sgtitle('PPG Stress Analysis Pipeline — BIDMC Dataset');