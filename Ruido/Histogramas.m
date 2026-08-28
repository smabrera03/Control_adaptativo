clear; clc; close all;
T_MAX = 30;
load('Barra_quieta.mat');
idx = t < T_MAX;
x_barra_quieta = x(idx);

load('Barra_movil.mat');
idx = t < T_MAX;
x_barra_movil = x(idx);

figure;
histogram(x_barra_quieta, 'BinWidth', 0.3);

grid on;
xlabel('Posición [cm]');
ylabel('Cantidad de mediciones');
title('Histograma - Barra quieta');

figure;
histogram(x_barra_movil, 'BinWidth', 0.3);

grid on;
xlabel('Posición [cm]');
ylabel('Cantidad de mediciones');
title('Histograma - Barra Movil');