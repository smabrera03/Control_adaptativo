% ¿Es identificable esta planta?

clear; clc; close all;

load('datos_LC_v1_procesados.mat');

Ts = 0.02;
fs = 1/Ts;

N_corte = floor(length(y_der) * 0.75);

z_id = iddata(y_der(1:N_corte), u(1:N_corte), Ts);
z_val = iddata(y_der(N_corte+1:end), u(N_corte+1:end), Ts);

%%

modeloARX = arx(z_id, [3 2 1]);
present(modeloARX);

compare(z_val, modeloARX);


%% Matriz de información

y_id = y_der(1:N_corte);
u_id = u(1:N_corte);

na = 3;
nb = 2;
nk = 1;

N = length(y_id);

% Primera muestra para la que existen todos los regresores
k0 = max(na, nk + nb - 1) + 1;

Phi = zeros(N-k0+1, na+nb);

for k = k0:N
    
    % Regresores de salida
    phi_y = -y_id(k-1:-1:k-na);
    
    % Regresores de entrada
    phi_u = u_id(k-nk:-1:k-nk-nb+1);
    
    Phi(k-k0+1,:) = [phi_y(:).' phi_u(:).'];
end

% Matriz de información
M = Phi' * Phi;

disp('Matriz de información Phi''*Phi:')
disp(M)

% Rango
fprintf('Rango de Phi: %d de %d\n', rank(Phi), size(Phi,2));

% Valores propios
lambda = eig(M);

disp('Valores propios de Phi''*Phi:')
disp(lambda)

% Número de condición
fprintf('cond(Phi) = %.3e\n', cond(Phi));
fprintf('cond(Phi''*Phi) = %.3e\n', cond(M)); %Números de condición. Si es muy alto, la matriz es casi singular



%% Filtrado exponencial de la velocidad

alfa = 0.7; %Cuanto mas grande es alfa, mas fuerte es el filtrado

y_der_f = zeros(size(y_der));
y_der_f(1) = y_der(1);

for k = 2:length(y_der)
    y_der_f(k) = alfa*y_der_f(k-1) + (1-alfa)*y_der(k);
end

t = (0:length(y_der)-1)*Ts;

figure;
plot(t, y_der)
hold on
plot(t, y_der_f, 'LineWidth', 1.5)
grid on
legend('y_{der}', 'y_{der,f}')
xlabel('Tiempo [s]'); xlim([0, 20]);
ylabel('Velocidad')

N_corte = floor(length(y_der_f) * 0.75);

z_id = iddata(y_der_f(1:N_corte), u(1:N_corte), Ts);
%z_val = iddata(y_der_f(N_corte+1:end), u(N_corte+1:end), Ts);

modeloOE = oe(z_id, [1 2 1]);

present(modeloOE);

figure;
compare(z_val, modeloOE);

%{
ALGO ESTÁ IDENTIFICANDO

Cuidado igual. Está identificando la derivada FILTRADA.

¿Replica bien la dinámica de la posición?
%}

%% Añado el integrador

z_val_int = iddata(y(1:250), u(1:250), Ts);

s = tf('s');
integrador = c2d(1/s, Ts);

modeloOE_int = integrador * modeloOE;

present(modeloOE_int);

compare(modeloOE_int, z_val_int);

%{
Observación: cuanto más chico es el intervalo de comparación mejor es la
estimación. El integrador acumula error.

Simula bien a corto plaz?

PENSAR
%}