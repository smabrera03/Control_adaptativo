%

clear; clc; close all;

load('datos_LC_v1_procesados.mat');

Ts = 0.02;
fs = 1/Ts;

lw = 2;

alfa = 0.9;
y_der_f = filtrar(alfa, y_der);

N_corte = floor(length(y_der_f) * 0.75);

z_id = iddata(y_der_f(1:N_corte), u(1:N_corte), Ts);
z_val = iddata(y_der_f(N_corte+1:end), u(N_corte+1:end), Ts);

ordenes = [2 1 1];

matriz_de_informacion(z_id, ordenes);


xmax = 20;

figure;
subplot(2, 1, 1);
plot(t, u, 'LineWidth', lw);
grid on;
title('Entrada');
xlabel('Tiempo [s]'); ylabel('u [rad]');
xlim([0 xmax]);

subplot(2, 1, 2);
plot(t, y_der_f, 'LineWidth', lw);
grid on;
title('Salida');
xlabel('Tiempo [s]'); ylabel('Velocidad [m/s]');
xlim([0 xmax]);

%% Identificación de la dinámica de la velocidad

modeloOE = oe(z_id, [2 3 1]);
present(modeloOE);
figure;
compare(z_val, modeloOE); grid on;

figure;
pzmap(modeloOE);

%% Identificación de la dinámica de la posición

s = tf('s');
integrador = c2d(1/s, Ts, 'zoh');
modeloOE_int = integrador * modeloOE;

Nlim = 50 * 15;
z_pos = iddata(y(1:Nlim), u(1:Nlim), Ts);

figure;
compare(z_pos, modeloOE_int); grid on;

