%{

EVALUAR:

1) Filtro la velociadad. ¿Recupero la posición si la integro?

2) Puedo identificar con la velocidad filtrada? Calcular la matriz de
información. Armar una función que permita calcular la matriz de
información dadas las señales y los órdenes

%}

clear; clc; close all;

load('datos_LC_v1_procesados.mat');

Ts = 0.02;
fs = 1/Ts;

figure;
lw = 2;
xmax = 15;
subplot(2, 1, 1);
plot(t, u, 'LineWidth', lw); grid on;
title('Acción de control [rad]');
xlim([0 xmax]);
subplot(2, 1, 2);
plot(t, y_der, 'LineWidth', lw); grid on;
title('Velocidad (salida)');
xlim([0 xmax]);

%%  OBSERVACIÓN: NO PUEDO IDENTIFICAR CON ESTOS DATOS, MUCHO RUIDO
N_corte = floor(length(y_der) * 0.75);

z_id = iddata(y_der(1:N_corte), u(1:N_corte), Ts);
z_val = iddata(y_der(N_corte+1:end), u(N_corte+1:end), Ts);

ordenes = [2 1 1];

matriz_de_informacion(z_id, ordenes);

%% FILTRADO EXPONENCIAL

alfa = 0.7; %Cuanto mas grande es alfa, mas fuerte es el filtrado

y_der_f = zeros(size(y_der));
y_der_f(1) = y_der(1);

for k = 2:length(y_der)
    y_der_f(k) = alfa*y_der_f(k-1) + (1-alfa)*y_der(k);
end


figure;
plot(t, y_der)
hold on
plot(t, y_der_f, 'LineWidth', 1.5)
grid on
legend('y_{der}', 'y_{der,f}')
xlabel('Tiempo [s]'); xlim([0, 20]);
ylabel('Velocidad')

%% ¿PIERDO INFORMACIÓN FILTRANDO? ¿PUEDO RECUPERAR LA POSICIÓN?

y_int = cumsum(y_der_f) * Ts;
y_int = y_int + y(1);

figure;
plot(t, y, 'LineWidth', lw); hold on;
plot(t, y_int, 'LineWidth', lw);
grid on;
legend('Original', 'Integrada');

%Coinciden bastannnte bien

%% ¿COMO AFECTA EL FILTRO A LA MATRIZ DE INFORMACIÓN?
clc;
z_id_f = iddata(y_der_f(1:N_corte), u(1:N_corte), Ts);

ordenes = [2 1 1];

matriz_de_informacion(z_id, ordenes);
matriz_de_informacion(z_id_f, ordenes);

%{

A pesar del filtrado, me sigue faltando información. No era tema del
ruido?

Más que el ruido, parece ser tema del orden. No puedo identificar ordenes
muy altos, no tengo señales suficientemente ricas. Eso pasa porque no veo
la dinámica completa porque estoy trabajando a lazo cerrado

%}

%% ¿Depende la identificación del filtrado exponencial?

alfas = [0.7 0.8 0.9];
modelos = cell(1, length(alfas));

for i = 1:length(alfas)
    alfa = alfas(i);
    y_der_f = filtrar(alfa, y_der);
    
    z_id_f = iddata(y_der_f(1:N_corte), u(1:N_corte), Ts);
    
    modelo = oe(z_id_f, [2 3 1]);
    
    modelos{i} = modelo;
end

bode(modelos{:}); 
grid on;

% Create a cell array of strings for the legend
etiquetas = arrayfun(@(a) sprintf('\\alpha = %.1f', a), alfas, 'UniformOutput', false);
legend(etiquetas, 'Location', 'best');
title('Comparación de modelos ARX según el factor de filtrado \alpha');

%{

RESULTADO CURIOSO:

Si uso arx, el modelo identificado depende de alfa, es decir, estoy
identificando el filtro exponencial más que el modelo verdadero

Si uso oe, la identificación es casi la misma para cualquier alfa

Conclusión: Puedo identificar un modelo de hasta orden 2 con el filtrado
exponencial y con oe.

Ordenes usados: [1 2 1]

Pero esos ordenes dan malos resultados

Los ordenes que habría que usar son [2 3 1]

Pero usando esos ordenes obtengo una dinámica pasa altos???

¿Por qué tengo más ceros que polos?

No tiene ningún tipo de sentido. ¿Por qué explica los datos?
%}