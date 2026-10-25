close all; clc; clear;

%% PARAMETROS DEL SISTEMA
m  = 0.033;       
b  = 0.15;       
g  = 9.8;         
%Coeficientes del denominador de la transferencia
q0 = 33.1549;
q1 = 9.736; 
%Numerador de la transferencia
k = 11.4345;
a0 = deg2rad(-3.9);   % Offset servo-barra [rad]
a1 = 0.34;            % Pendiente servo-barra


fs = 50;              % Frecuencia de muestreo [Hz]
Ts = 1/fs;            % Periodo de muestreo [s]


N = 10000; %Largo de la muestra a utilizar

t = (0:N-1)'*Ts; %Vector de tiempos

%% TRANSFERENCIA DEL SISTEMA LINEALIZADO (PARA COMPARAR)
s = tf('s');
G = g * k * 1/s * 1/(s + b/m) * 1/(s^2 + q1 * s + q0); % <-- TRANSFERENCIA A IDENTIFICAR

kp = 2;

%% GENERACIÓN DE LA ENTRADA
amplitud = 0.5; %Amplitud del ruido
rng(1); %Semilla para replicabilidad
r = amplitud*sign(randn(N,1)); %Señal de referencia
r = r - mean(r);

r_continua = @(tt) interp1(t,r,tt,'linear','extrap');

%% DEFINICIÓN DEL MODELO NO LINEAL

modelo = @(tt,x) [
    x(2);
    g*sin(x(3)) - (b/m)*x(2);
    x(4);
    -q0*x(3) - q1*x(4) + k* kp * (r_continua(tt) - x(1))
];

x0 = [0; 0; 0; 0];
opts = odeset('MaxStep',Ts/5);

%% GENERACIÓN DE SEÑALES

[t_sol,x_sol] = ode45(modelo,t,x0,opts);

y0 = x_sol(:,1);
e = amplitud/10 * randn(N, 1);
y = y0 + e;
y = y - mean(y);

%Recuperamos u
u = kp * (r - y);


%% IDENTIFICACIÓN DE G A PARTIR DE u E y (solo por welch)

ventana = hamming(256);
noverlap = 64;
N_fft = 2048;

[Puy, f_welch] = cpsd(y, u, ventana, noverlap, N_fft, fs, 'twosided');
w = 2 * pi * f_welch;

[Puu, ~] = pwelch(u, ventana, noverlap, f_welch, fs, 'twosided');
G_welch = Puy./Puu;


G_welch = frd(G_welch, w);
G_welch_bode = squeeze(G_welch.ResponseData);

%% COMPTO DEL BODE TEÓRICO
G_teorica = squeeze(freqresp(G,w));
%% BODES
W_MIN = w(2);
W_MAX = 30;

figure;
subplot(2, 1, 1);
semilogx(w, 20*log10(abs(G_welch_bode)), 'm', 'LineWidth', 1.5); hold on;
semilogx(w, 20*log10(abs(G_teorica)), 'b--', 'LineWidth', 2);
xlim([W_MIN, W_MAX]);
grid on;
ylabel('Magnitud [dB]');
legend('Welch', 'Verdadero', 'Location', 'SouthWest');
title('Bode de G comparación');

subplot(2, 1, 2);
semilogx(w, rad2deg(unwrap(angle(G_welch_bode))) - 360, 'm' , 'LineWidth', 1.5); hold on;
semilogx(w, rad2deg(unwrap(angle(G_teorica))), 'b--', 'LineWidth', 1.5);
xlim([W_MIN, W_MAX]);
ylim([-400, 40]);
grid on;
xlabel('\omega [rad/s]');
ylabel('Fase [°]');

%{
CONCLUSIÓN:
SE PUDO IDENTIFICAR DE U a Y, ahora ambos procesos son ESA. EN ESTE CASO NO
IMPORTA SI ESTÁN CORRELACIONADOS.

EL INTEGRADOR SIGUE DANDO PROBLEMAS PARA BAJAS FRECUENCIAS
%}

%% DERIVO y

y_der = diff(y)/Ts; %este vector es de largo N-1
u = u(1:N-1);
t = t(1:N-1);

G_der = g * k * 1/(s + b/m) * 1/(s^2 + q1 * s + q0); %--> AHORA ESTA ES LA TRANSFERENCIA A IDENTIFICAR

[Puy, f_welch] = cpsd(y_der, u, ventana, noverlap, N_fft, fs, 'twosided');
w = 2 * pi * f_welch;

[Puu, ~] = pwelch(u, ventana, noverlap, f_welch, fs, 'twosided');
G_der_welch = Puy./Puu;


G_der_welch = frd(G_der_welch, w);
G_der_welch_bode = squeeze(G_der_welch.ResponseData);

%% COMPUTO DEL BODE TEÓRICO
G_der_teorica = squeeze(freqresp(G_der,w));
%% BODES
W_MIN = w(2);
W_MAX = 30;

figure;
subplot(2, 1, 1);
semilogx(w, 20*log10(abs(G_der_welch_bode)), 'm', 'LineWidth', 1.5); hold on;
semilogx(w, 20*log10(abs(G_der_teorica)), 'b--', 'LineWidth', 2);
xlim([W_MIN, W_MAX]);
grid on;
ylabel('Magnitud [dB]');
legend('Welch', 'Verdadero', 'Location', 'SouthWest');
title('Bode de G comparación');

subplot(2, 1, 2);
semilogx(w, rad2deg(unwrap(angle(G_der_welch_bode))), 'm' , 'LineWidth', 1.5); hold on;
semilogx(w, rad2deg(unwrap(angle(G_der_teorica))), 'b--', 'LineWidth', 1.5);
xlim([W_MIN, W_MAX]);
%ylim([-400, 40]);
grid on;
xlabel('\omega [rad/s]');
ylabel('Fase [°]');
