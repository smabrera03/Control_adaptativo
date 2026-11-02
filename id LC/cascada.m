clear; clc; close all;

load('datos_LC_v1_procesados.mat');

%{
ang_barra: angulo medido de la barra [rad]
y:         posicion del carro [m]
t:         vector de tiempo [s]
%}

%% Senales

ang_barra = double(ang_barra(:));
y = double(y(:));

%% Muestreo

Ts = 0.02;
Fs = 1/Ts;           % 50 Hz

%% Parametros de Welch

L = 1024;            % 20.48 s por segmento
window = hann(L);

noverlap = L/2;      % 50 % de solapamiento
nfft = L;

%% Densidades espectrales

% PSD de la entrada: angulo de la barra
[Saa, f] = pwelch(ang_barra, ...
                  window, noverlap, nfft, Fs);

% PSD de la salida: posicion del carro
[Syy, ~] = pwelch(y, ...
                  window, noverlap, nfft, Fs);

% Densidad espectral cruzada entrada-salida
[Say, ~] = cpsd(ang_barra, y, ...
                window, noverlap, nfft, Fs);

%% Transferencia estimada

G = Say ./ Saa;

%% Coherencia

coh = mscohere(ang_barra, y, ...
               window, noverlap, nfft, Fs);

%% PSD

figure;

subplot(2,1,1)
semilogy(f, Saa, 'LineWidth', 1.2);
grid on;
xlabel('Frecuencia [Hz]');
ylabel('S_{\theta\theta}');
title('PSD del angulo de la barra');

subplot(2,1,2)
semilogy(f, Syy, 'LineWidth', 1.2);
grid on;
xlabel('Frecuencia [Hz]');
ylabel('S_{yy}');
title('PSD de la posicion del carro');

%% Respuesta en frecuencia

figure;

subplot(2,1,1)
semilogx(f(2:end), ...
         20*log10(abs(G(2:end))), ...
         'LineWidth', 1.2);

grid on;
ylabel('Magnitud [dB]');
title('Transferencia estimada ang\_barra -> y');

subplot(2,1,2)
semilogx(f(2:end), ...
         unwrap(angle(G(2:end)))*180/pi, ...
         'LineWidth', 1.2);

grid on;
xlabel('Frecuencia [Hz]');
ylabel('Fase [grados]');

%% Coherencia

figure;

plot(f, coh, 'LineWidth', 1.2);
grid on;

ylim([0 1.05]);
xlim([0 Fs/2]);

xlabel('Frecuencia [Hz]');
ylabel('\gamma^2_{\theta y}');
title('Coherencia ang\_barra - y');