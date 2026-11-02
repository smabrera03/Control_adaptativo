%{

A HACER:

Se identifica:
Gder =  g /(s + b/m) * (servo->barra). No es un objetivo, es una referencia
Se identifican 3 polos (¿y un cero de fase no mínima?)
A partir de:
u, y_der

Se identifica por:
welch, iv4



Luego se agregará el integrador [1/(1 - z^-1)] y se comparará con G

CUIDADO: Hay 2 planos a comparar: CON y SIN el integrador. PRIMERO HACER
TODO SIN EL INTEGRADOR, AGREGARLO DSP.

Usar la re-identificación. Comprobar si las dinámicas acopladas influyen.
|
|--> Si la identificación hecha a lazo cerrado da lo mismo que la conexión
en cascada, el acoplamiento es despreciable.

Dudas: Tenemos un modelo discreto obtenido por arx reducido
¿Cómo lo pasamos a continuo? ¿d2c y cierro los ojos?
%}

%% DEFINICIÓN DE TRANSFERENCIAS E IMPORTACIÓN DE DATOS. CONJUNTOS DE ID Y VALIDACIÓN
clear; close all; clc;

load('datos_LC_v1_procesados.mat');
load('resultado_servo-barra.mat');
m_arx_red; %Modelo servo-barra reidentificado (sacarlo? A Pablo no le va a gustar...
m_arx_red_cont; %Modelo reidentificado continuo. Se obtuvo por d2c. ¿Qué hace d2c? Investigar...

m  = 0.033;       
b  = 0.15;    
g  = 9.8;
Ts = 0.02;
fs = 1/Ts;


s = tf('s');
G = m_arx_red * c2d(g/(s + b/m), Ts); %--> Transferencia (discreta) a identificar, sin integrador
G_int = G * c2d(1/s, Ts); %--> Transferencia completa, con integrador

N_corte = floor(length(y_der) * 0.75);

z_id = iddata(y_der(1:N_corte), u(1:N_corte), Ts);
z_val = iddata(y_der(N_corte+1:end), u(N_corte+1:end), Ts);

%% Gráfico de la velocidad. Muhco ruido. ¿Tiene sentido filtrar?

figure;
plot(t, y_der, 'LineWidth', 2);
grid on;
xlim([10, 15]);

[B, A] = butter(2, 0.3, 'low');

y_der_filt = filter(B, A, y_der);

figure;
plot(t, y_der_filt, 'LineWidth', 2);
grid on;
xlim([10, 15]);

%% CORRELOGRAMA

NFFT = 512;
ventana = hamming(NFFT);
noverlap = NFFT/2;

[Pyu,f] = cpsd(y_der,u,ventana,noverlap,NFFT,fs, 'twosided');
[Puu,~] = cpsd(u,u,ventana,noverlap,NFFT,fs, 'twosided');
w = 2 * pi * f;

G_welch = Pyu./Puu;

figure;
plot(w, Puu);grid on;
xlim([0, 10]);
%{

La estimación por correlograma da mal. 

Posibles razones: 

1) La excitación tiene poco contenido espectral. Estoy
dividiendo por cero casi siempre.

2) Derivada ruidosa. Intenté filtrarla. Da igual de mal

¿Tiene sentido identificar por correlograma? ¿Tiene sentido identificar con
estos datos?

%}

%% IV

modelo_IV4 = iv4(z_id, [3, 2, 1]);
present(modelo_IV4);

%fit negativo. Buenísimo

compare(z_val, modelo_IV4);
