clear; clc; close all;

load('datos_LC_v1_procesados.mat');
load('resultado_servo-barra.mat');

Ts = 0.02;
Fs = 1/Ts;

s = tf('s');
m  = 0.033;       
b  = 0.15;    
g  = 9.8;
G = m_arx_red * c2d(g/(s + b/m), Ts); %--> Transferencia (discreta) a identificar, sin integrador
G_int = G * c2d(1/s, Ts); %--> Transferencia completa, con integrador

%{

r: referencia en metros. PRBS

u: Acción de control. ángulo comandado al servo en radianes

ang_barra: Ángulo de la barra en radianes

y: posición del carro en metros

y_der: derivada de y en metros/s

t: vector de tiempo

%}

%% 2. Parametros del metodo de Welch

N = length(u);

% Longitud de los segmentos
L = min(512, floor(N/8));

% Ventana de Hann
window = hann(L);

% Solapamiento del 50 %
noverlap = floor(L/2);

% Numero de puntos de FFT
nfft = max(2048, 2^nextpow2(L));

%% 3. Estimacion de densidades espectrales

% Densidad espectral de potencia de la entrada
[Suu, f] = pwelch(r, window, noverlap, nfft, Fs);

% Densidad espectral de potencia de la salida
[Syy, ~] = pwelch(y, window, noverlap, nfft, Fs);

% Densidad espectral cruzada entrada-salida
[Syu, ~] = cpsd(r, y, window, noverlap, nfft, Fs);

%% 4. Respuesta en frecuencia estimada

G = Syu ./ Suu;

%% 5. Coherencia

Cuy = mscohere(u, y_der, window, noverlap, nfft, Fs);

%% 6. Densidades espectrales

figure;

subplot(2,1,1)
semilogy(f, Suu);
grid on;
xlabel('Frecuencia [Hz]');
ylabel('S_{uu}');
title('PSD de la entrada');

subplot(2,1,2)
semilogy(f, Syy);
grid on;
xlabel('Frecuencia [Hz]');
ylabel('S_{yy}');
title('PSD de la salida');

%% 7. Respuesta en frecuencia estimada

figure;

subplot(2,1,1)
semilogx(f(2:end), 20*log10(abs(G(2:end))));
grid on;
ylabel('Magnitud [dB]');
title('Respuesta en frecuencia estimada');

subplot(2,1,2)
semilogx(f(2:end), unwrap(angle(G(2:end)))*180/pi);
grid on;
xlabel('Frecuencia [Hz]');
ylabel('Fase [grados]');

%% 8. Coherencia

figure;

plot(f, Cuy);
grid on;
ylim([0 1.05]);

xlabel('Frecuencia [Hz]');
ylabel('\gamma^2_{uy}');
title('Coherencia entrada-salida');


%{

Todo mal. 

Copilot me tiró una que puede ser buena.

G = Syr/Sur


Otra posibilidad:

u = -Kp * y  + d

donde d es PRBS

andará?

Mi conclusión: está mal hecho este experimento
%}