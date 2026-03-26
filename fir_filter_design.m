% ============================================================
% Project      : FIR / IIR Digital Filter Design & Simulation
% Author       : Harshit Bothra
% College      : PES University, ECE Department
% Tool         : MATLAB R2022a or later
% Description  : Designs a low-pass FIR filter using the
%                Hamming window method, verifies frequency
%                response, and exports coefficients for
%                SystemVerilog hardware implementation.
% ============================================================

clear; clc; close all;

%% ---- FILTER SPECIFICATIONS ----
Fs      = 8000;     % Sampling frequency (Hz) — e.g. audio at 8kHz
Fc      = 1000;     % Cutoff frequency (Hz)   — pass below 1kHz
N       = 16;       % Filter order (number of taps = N+1 = 17)
Wn      = Fc/(Fs/2);% Normalized cutoff (0 to 1, where 1 = Fs/2)

fprintf('=== FIR Filter Design ===\n');
fprintf('Sampling Freq  : %d Hz\n', Fs);
fprintf('Cutoff Freq    : %d Hz\n', Fc);
fprintf('Filter Order   : %d (Taps: %d)\n', N, N+1);
fprintf('Window         : Hamming\n\n');

%% ---- DESIGN FIR FILTER (Windowing Method) ----
% fir1 uses the ideal sinc response windowed by Hamming window
% This is the most common method for FIR design
h = fir1(N, Wn, 'low', hamming(N+1));

fprintf('FIR Coefficients (h):\n');
disp(h);

%% ---- FREQUENCY RESPONSE ----
[H, f] = freqz(h, 1, 1024, Fs);

figure('Name', 'FIR Filter Frequency Response', 'NumberTitle', 'off');

% Magnitude Response
subplot(2,1,1);
plot(f, 20*log10(abs(H)), 'b', 'LineWidth', 1.5);
hold on;
xline(Fc, 'r--', 'LineWidth', 1.2);
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title('FIR Low-Pass Filter - Magnitude Response');
legend('Filter Response', 'Cutoff Frequency');
grid on; ylim([-80 5]);

% Phase Response
subplot(2,1,2);
plot(f, angle(H)*180/pi, 'g', 'LineWidth', 1.5);
xlabel('Frequency (Hz)'); ylabel('Phase (degrees)');
title('Phase Response');
grid on;

%% ---- TEST SIGNAL ----
% Create a composite test signal: 500Hz (pass) + 2000Hz (stop)
t  = 0:1/Fs:0.1;                    % 100ms duration
x1 = sin(2*pi*500*t);               % 500Hz — should PASS through filter
x2 = sin(2*pi*2000*t);              % 2000Hz — should be BLOCKED
x  = x1 + x2;                      % Combined input signal

% Apply FIR filter
y = filter(h, 1, x);

figure('Name', 'Filter Applied to Test Signal', 'NumberTitle', 'off');
subplot(3,1,1); plot(t(1:200), x(1:200));  title('Input Signal (500Hz + 2000Hz)'); xlabel('Time (s)'); grid on;
subplot(3,1,2); plot(t(1:200), y(1:200));  title('Filtered Output (500Hz only)');  xlabel('Time (s)'); grid on;
subplot(3,1,3);
X = fft(x, 1024); Y = fft(y, 1024);
freq = (0:511)*Fs/1024;
plot(freq, abs(X(1:512))/512, 'b'); hold on;
plot(freq, abs(Y(1:512))/512, 'r');
title('FFT: Input vs Output Spectrum'); xlabel('Frequency (Hz)');
legend('Input', 'Filtered Output'); grid on;

%% ---- EXPORT COEFFICIENTS FOR HARDWARE ----
% Scale coefficients to 16-bit fixed point for SystemVerilog
scale   = 2^15 - 1;  % Q15 format (1 sign bit + 15 fractional bits)
h_fixed = round(h * scale);

fprintf('\nFixed-Point Coefficients (Q15 format for SystemVerilog):\n');
fprintf('parameter logic signed [15:0] COEFF [0:%d] = ''{\n', N);
for i = 1:length(h_fixed)
    if i < length(h_fixed)
        fprintf("    16'sd%d,\n", h_fixed(i));
    else
        fprintf("    16'sd%d\n", h_fixed(i));
    end
end
fprintf('};\n\n');

fprintf('Copy the above parameters into fir_filter.sv\n');

%% ---- IIR FILTER FOR COMPARISON ----
fprintf('\n=== IIR Butterworth Filter (for comparison) ===\n');
[b_iir, a_iir] = butter(4, Wn, 'low');  % 4th order Butterworth

fprintf('IIR Numerator (b):   '); disp(b_iir);
fprintf('IIR Denominator (a): '); disp(a_iir);

[H_iir, ~] = freqz(b_iir, a_iir, 1024, Fs);

figure('Name', 'FIR vs IIR Comparison', 'NumberTitle', 'off');
plot(f, 20*log10(abs(H)),     'b', 'LineWidth', 1.5); hold on;
plot(f, 20*log10(abs(H_iir)), 'r', 'LineWidth', 1.5);
xline(Fc, 'k--');
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title('FIR vs IIR: Frequency Response Comparison');
legend('FIR (Hamming, N=16)', 'IIR (Butterworth, N=4)', 'Cutoff');
grid on; ylim([-80 5]);

fprintf('\nKey Difference:\n');
fprintf('  FIR: Linear phase, more taps, good for audio\n');
fprintf('  IIR: Sharper rolloff, fewer taps, may be unstable\n');
fprintf('  For hardware implementation: FIR preferred (no feedback)\n');
