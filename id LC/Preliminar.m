clear all; clc, close all;

load('datos_LC_v1.mat');
t = t - min(t); % Para que arranque en 0,
figure;

subplot(2, 1, 1);
plot(t, r); hold on;
plot(t, y);
grid on;
legend('referencia', 'posicion')
xlim([0, 30]);
title('Posicion y referencia');

subplot(2, 1, 2);
plot(t, u);
grid on;
xlim([0, 30]);
title('Acción de control');

%% PASAR TODO A UNIDADES DE m O rad

r = r/100;
u = deg2rad(u);
ang_barra = deg2rad(ang_barra);
y = y/100;

fprintf('Media de r: %.3f \n', mean(r));
fprintf('Media de u: %.3f \n', mean(u));
fprintf('Media de y: %.3f \n', mean(y));
fprintf('Media del ángulo de la barra: %.3f \n', mean(ang_barra));

r = r - mean(r);
u = y - mean(u);
y = y - mean(y);
ang_barra = ang_barra - mean(ang_barra);

%% PSD de r:
fs = 50;

NFFT = 512; %aprox 10 s de ventana
ventana = hamming(NFFT);
noverlap = NFFT/2;

[PSD_r, f] = pwelch(r, [], noverlap, NFFT, fs,  'twosided');
w = 2*pi * f;

figure;
stem(w, PSD_r); hold on;
plot(w, PSD_r, 'LineWidth', 2); grid on;
xlim([0, 2 * pi * fs/20]);
xlabel('\omega [rad/s]');

%% PSD DE u

[PSD_u, f] = pwelch(u, [], noverlap, NFFT, fs,  'twosided');

figure;
stem(w, PSD_u); hold on;
plot(w, PSD_u, 'LineWidth', 2); grid on;
xlim([0, 2 * pi * fs/20])
xlabel('\omega [rad/s]');

% ¿Alcanzará?

%% GENERO LA DERIVADA Y GUARDO LAS SEÑALES PROCESADAS 
%PARA PASAR DIRECTO A LA IDENTIFICACIÓN
Ts = 1/fs;
y_der = diff(y)/Ts;
N = length(y_der);

t = t(1:N);
r = r(1:N);
u = u(1:N);
ang_barra = ang_barra(1:N);
y = y(1:N);

save('datos_LC_v1_procesados.mat', 'r', 'u', 'ang_barra', 'y', 'y_der', 't');