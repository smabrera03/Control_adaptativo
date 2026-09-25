clear; clc; close all;

load('data.mat');

u = data(:, 1);
y = data(:, 2);
N = length(y);
plot(u); hold on;
plot(y); grid on;
xlim([0, N]);

% Correlación entrada-salida
m = 1000;
R = covf([y u],m+1);

% Estimación de la respuesta al impulso
h = R(2,:)'/R(4,1);

% Comparación con la respuesta al impulso del modelo
figure
plot([h(1:m)],'LineWidth',2)
grid
legend('Estimación por correlación')

%%
z = iddata(y,u,1);
H_etfe = etfe(z);

% Welch
Pyu = cpsd(y,u);
Puu = pwelch(u);
H_welch = Pyu./Puu;
w_welch = (0:length(H_welch)-1)'*pi/length(H_welch);
H_welch  = frd(H_welch ,w_welch);

% Correlograma
R = covf([y u],m+1);
h_cor = R(2,:)'/R(4,1);

% Respuesta en frecuencia del correlograma
N = 256;
H_cor = fft(h_cor,N);
w_cor = (0:N-1)'*2*pi/N;
H_cor = frd(H_cor,w_cor);

% Comparaciónw_cor
figure
bode(w_cor,H_etfe,H_welch,H_cor)
grid
legend('ETFE','Welch','Correlograma')
title('Espectros')
h = findobj(gcf,'type','line');
set(h,'linewidth',2);
