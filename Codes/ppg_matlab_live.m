%% ESP8266 + MAX30105 — PPG Stress Monitor
% ESP8266 sends raw IR PPG values over USB serial
% MATLAB performs:
%   - Filtering
%   - Peak detection
%   - HRV analysis
%   - Stress estimation
%   - Live plotting
%   - ThingSpeak upload

clear;
clc;
close all;

%% ── SETTINGS ────────────────────────────────────────────────────────────

COM_PORT = 'COM7';              % Change to your COM port
BAUDRATE = 115200;

API_KEY = '5UP8RBGK4DYPNBN0';

fs = 100;                       % Sampling frequency (matches Arduino)

% 1 = Social Media
% 2 = Gaming
% 3 = Studying
% 4 = Leisure Reading

CONDITION = 3;

COND_NAMES = { ...
    'Social Media', ...
    'Gaming', ...
    'Studying', ...
    'Leisure Reading'};

%% ── WINDOW SETTINGS ────────────────────────────────────────────────────

WINDOW_SEC = 30;
WINDOW_SAMPLES = fs * WINDOW_SEC;

%% ── FILTER DESIGN ──────────────────────────────────────────────────────

[b, a] = butter(4, [0.5 4] / (fs/2), 'bandpass');

%% ── SERIAL SETUP ───────────────────────────────────────────────────────

try

    s = serialport(COM_PORT, BAUDRATE);

catch

    warning('Serial port busy. Clearing old connections...');

    delete(instrfindall);

    pause(1);

    s = serialport(COM_PORT, BAUDRATE);

end

configureTerminator(s, "LF");

flush(s);

fprintf('Connected to %s\n', COM_PORT);
fprintf('Condition: %s\n\n', COND_NAMES{CONDITION});

pause(2);

flush(s);   % remove startup text

%% ── FIGURE SETUP ───────────────────────────────────────────────────────

fig = figure( ...
    'Name', 'PPG Stress Monitor', ...
    'Position', [50 50 1200 700]);

%% Live PPG Plot

ax1 = subplot(3,2,[1 2]);

h_raw = plot(nan, nan, 'b');

hold on;

h_filt = plot(nan, nan, 'k', 'LineWidth', 1.2);

h_pks = plot(nan, nan, ...
    'ro', ...
    'MarkerFaceColor', 'r', ...
    'MarkerSize', 5);

title('Live PPG Signal');

xlabel('Time (s)');
ylabel('Amplitude');

legend({'Raw','Filtered','Peaks'});

grid on;

%% RR Plot

ax2 = subplot(3,2,3);

h_rr = plot(nan, nan, 'b.-', 'MarkerSize', 10);

title('RR Intervals');

xlabel('Time (s)');
ylabel('RR (s)');

ylim([0.4 1.3]);

grid on;

%% HR Trend

ax3 = subplot(3,2,4);

h_hr = plot(nan, nan, 'r.-', 'MarkerSize', 10);

title('Heart Rate Trend');

xlabel('Window Number');
ylabel('BPM');

ylim([40 130]);

grid on;

%% HRV Metrics

ax4 = subplot(3,2,5);

h_bar = bar([0 0 0]);

set(ax4, ...
    'XTickLabel', ...
    {'SDNN','RMSSD','pNN50'});

ylabel('Value');

title('HRV Metrics');

grid on;

%% Text Info

ax5 = subplot(3,2,6);

axis off;

h_txt = text( ...
    0.5, ...
    0.5, ...
    'Collecting data...', ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 11, ...
    'Units', 'normalized');

sgtitle( ...
    sprintf('Condition: %s', COND_NAMES{CONDITION}), ...
    'FontSize', 14);

%% ── VARIABLES ──────────────────────────────────────────────────────────

buffer = zeros(1, WINDOW_SAMPLES);

n = 0;

window_num = 0;

hr_trend = [];

ts_timer = tic;

fprintf('Recording started...\n');
fprintf('Close figure window to stop.\n\n');

%% ── MAIN LOOP ──────────────────────────────────────────────────────────

while ishandle(fig)

    %% Read Serial Data

    try

        raw_line = readline(s);

        val = str2double(raw_line);

    catch

        continue;

    end

    %% Ignore Invalid Data

    if isnan(val)

        continue;

    end

    %% Update Buffer

    n = n + 1;

    buffer = [buffer(2:end), val];

    %% Live Plot Update

    if mod(n,20) == 0 && n >= WINDOW_SAMPLES

        t = (0:WINDOW_SAMPLES-1) / fs;

        filtered_preview = filtfilt(b, a, buffer);

        set(h_raw, ...
            'XData', t, ...
            'YData', buffer);

        set(h_filt, ...
            'XData', t, ...
            'YData', filtered_preview);

        drawnow limitrate;

    end

    %% HRV Analysis Every 30 Seconds

    if n >= WINDOW_SAMPLES && mod(n, WINDOW_SAMPLES) == 0

        window_num = window_num + 1;

        t = (0:WINDOW_SAMPLES-1) / fs;

        %% FILTER

        ppg_filt = filtfilt(b, a, buffer);

        %% PEAK DETECTION

        min_dist = round(0.4 * fs);

        min_prom = std(ppg_filt) * 0.8;

        [pks, locs] = findpeaks( ...
            ppg_filt, ...
            'MinPeakDistance', min_dist, ...
            'MinPeakProminence', min_prom);

        %% CHECK PEAK COUNT

        if length(locs) < 5

            fprintf( ...
                'Window %d: Too few peaks detected\n', ...
                window_num);

            continue;

        end

        %% RR INTERVALS

        rr_sec = diff(locs) / fs;

        rr_time = t(locs(2:end));

        %% Remove Invalid RR

        valid = rr_sec > 0.4 & rr_sec < 1.3;

        rr_sec = rr_sec(valid);

        rr_time = rr_time(valid);

        if length(rr_sec) < 4

            fprintf( ...
                'Window %d: Invalid RR intervals\n', ...
                window_num);

            continue;

        end

        %% TIME DOMAIN HRV

        mean_hr = 60 / mean(rr_sec);

        sdnn = std(rr_sec) * 1000;

        rmssd = sqrt(mean(diff(rr_sec).^2)) * 1000;

        pnn50 = ...
            sum(abs(diff(rr_sec)) > 0.05) ...
            / length(rr_sec) * 100;

        %% FREQUENCY DOMAIN HRV

        rr_fs = 4;

        t_uni = rr_time(1):1/rr_fs:rr_time(end);

        rr_uni = interp1( ...
            rr_time, ...
            rr_sec, ...
            t_uni, ...
            'spline', ...
            'extrap');

        N = length(rr_uni);

        f = (0:N-1) * (rr_fs/N);

        ps = abs(fft(rr_uni - mean(rr_uni))).^2 / N;

        lf = sum(ps(f >= 0.04 & f <= 0.15));

        hf = sum(ps(f >= 0.15 & f <= 0.40));

        lf_hf = lf / max(hf, 1e-6);

        %% STRESS SCORE

        stress = min( ...
            100, ...
            max(0, (lf_hf * 15) + (50 - rmssd)));

        %% PRINT RESULTS

        fprintf( ...
            'Window %d | HR %.1f BPM | SDNN %.1f ms | RMSSD %.1f ms | Stress %.0f\n', ...
            window_num, ...
            mean_hr, ...
            sdnn, ...
            rmssd, ...
            stress);

        %% UPDATE PLOTS

        set(h_raw, ...
            'XData', t, ...
            'YData', buffer);

        set(h_filt, ...
            'XData', t, ...
            'YData', ppg_filt);

        set(h_pks, ...
            'XData', t(locs), ...
            'YData', ppg_filt(locs));

        set(h_rr, ...
            'XData', rr_time, ...
            'YData', rr_sec);

        hr_trend = [hr_trend mean_hr];

        set(h_hr, ...
            'XData', 1:length(hr_trend), ...
            'YData', hr_trend);

        set(h_bar, ...
            'YData', [sdnn rmssd pnn50]);

        set(h_txt, ...
            'String', sprintf( ...
            ['Window: %d\n' ...
             'Heart Rate: %.1f BPM\n' ...
             'SDNN: %.1f ms\n' ...
             'RMSSD: %.1f ms\n' ...
             'pNN50: %.1f %%\n' ...
             'LF/HF: %.2f\n' ...
             'Stress: %.0f / 100'], ...
             window_num, ...
             mean_hr, ...
             sdnn, ...
             rmssd, ...
             pnn50, ...
             lf_hf, ...
             stress));

        drawnow;

        %% THINGSPEAK UPDATE

        if toc(ts_timer) >= 15

            try

                url = sprintf([ ...
                    'https://api.thingspeak.com/update?' ...
                    'api_key=%s&field1=%.1f&field2=%.1f&' ...
                    'field3=%.1f&field4=%.1f&field5=%.2f&' ...
                    'field6=%.0f&field7=%d'], ...
                    API_KEY, ...
                    mean_hr, ...
                    sdnn, ...
                    rmssd, ...
                    pnn50, ...
                    lf_hf, ...
                    stress, ...
                    CONDITION);

                resp = webread(url);

                fprintf( ...
                    'ThingSpeak updated | Entry %s\n', ...
                    string(resp));

                ts_timer = tic;

            catch e

                fprintf( ...
                    'ThingSpeak Error: %s\n', ...
                    e.message);

            end

        end

        %% SAVE DATA

        log(window_num).time = datetime('now');

        log(window_num).condition = ...
            COND_NAMES{CONDITION};

        log(window_num).hr = mean_hr;

        log(window_num).sdnn = sdnn;

        log(window_num).rmssd = rmssd;

        log(window_num).pnn50 = pnn50;

        log(window_num).lf_hf = lf_hf;

        log(window_num).stress = stress;

    end

end

%% ── CLEANUP ────────────────────────────────────────────────────────────

fname = sprintf( ...
    'session_%s_%s.mat', ...
    strrep(COND_NAMES{CONDITION}, ' ', '_'), ...
    datestr(now,'yyyymmdd_HHMMSS'));

if exist('log','var')

    save(fname,'log');

    fprintf('\nSaved session: %s\n', fname);

end

clear s;

fprintf('Program stopped.\n');