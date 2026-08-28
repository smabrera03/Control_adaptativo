clear; clc; close all;
T_MAX = 30;
load('Barra_quieta.mat');
idx = t < T_MAX;
x_barra_quieta = x(idx);

load('Barra_movil.mat');
idx = t < T_MAX;
x_barra_movil = x(idx);

u_bq = mean(x_barra_quieta);
std_bq = std(x_barra_quieta);

u_bm = mean(x_barra_movil);
std_bm = std(x_barra_movil);

t = t(idx);

figure;
plot(t, x_barra_quieta);
hold on
plot(t, x_barra_movil);

grid();
legend('Barra quieta', 'Barra movil');

figure;
plot(t, x_barra_quieta);
hold on

yline(u_bq, '--', 'LineWidth', 2, 'DisplayName', '\mu');
yline(u_bq + std_bq, ':', 'LineWidth', 2, 'DisplayName', '\mu + \sigma');
yline(u_bq - std_bq, ':', 'LineWidth', 2, 'DisplayName', '\mu - \sigma');

ylim([5, 10]);
legend()
grid on;

figure;
plot(t, x_barra_movil);
hold on

yline(u_bm, '--', 'LineWidth', 2, 'DisplayName', '\mu');
yline(u_bm + std_bm, ':', 'LineWidth', 2, 'DisplayName', '\mu + \sigma');
yline(u_bm - std_bm, ':', 'LineWidth', 2, 'DisplayName', '\mu - \sigma');

ylim([5, 10]);
legend()
grid on;

%Conclusión: el movimiento de la barra afecta a las mediciones del
%ultrasónico