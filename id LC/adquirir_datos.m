delete(instrfindall);
clear; clc; close all;

%% Configuracion del ensayo

Texp = 10;           % Duracion [s]
Ts_prbs = 0.05;      % Actualizacion PRBS: 20 Hz
A = 0.05;            % Amplitud de la entrada [rad]

% Controlador PD (valores iniciales para ajustar)
Kp = 1.0;
Kd = 0.2;
% Filtro de velocidad
alpha = 0.7;

%% Generar PRBS
% Requiere System Identification Toolbox
N = ceil(Texp/Ts_prbs) + 1;
prbs = A * idinput(N, 'prbs', [0 1], [-1 1]);
prbs = prbs(:);

%prbs = ones(N,1);

%% Abrir puerto serie
s = serial('/dev/ttyUSB0', ...
    'BaudRate', 115200, ...
    'Terminator', 'LF', ...
    'Timeout', 2);

fopen(s);
pause(2);
flushinput(s);

fprintf(s, '0\n');


% El puerto puede reiniciar el ESP8266 al abrirse
pause(2);
flushinput(s);
fprintf(s, '0\n');

fprintf("Esperando telemetria del Wemos...\n");

%% Esperar una trama valida
while true
    linea = fgetl(s);
    v = sscanf(linea, '%f');

    if numel(v) == 4 && all(isfinite(v))
        break;
    end
end

fprintf("Adquisicion iniciada.\n");

%% Adquisicion en lazo cerrado

% Columnas:
% timestamp_us, q1, q2, u_wemos, referencia, tau_cmd
T = zeros(0,6);

t0 = tic;
t_ref_next = 0;
k = 1;

% Estado inicial del estimador de velocidad
q1_prev = v(2);
q2_prev = v(3);
ts_prev = v(1);
q1_p_f = 0;
q2_p_f = 0;

% Referencia inicial
r = prbs(k);
k = k + 1;

while toc(t0) < Texp

    % Leer telemetria: timestamp_us, q1, q2, u
    linea = fgetl(s);
    vn = sscanf(linea, '%f');

    if numel(vn) ~= 4 || any(~isfinite(vn))
        continue;
    end

    timestamp_us = vn(1);
    q1 = vn(2);
    q2 = vn(3);
    u_wemos = vn(4);

    % Intervalo real entre muestras segun micros() del Wemos
    dt = mod(timestamp_us - ts_prev, 2^32)*1e-6;

    if dt <= 0 || dt > 0.5
        ts_prev = timestamp_us;
        q2_prev = q2;
        q1_prev = q1;
        continue;
    end

    % Estimacion filtrada de la velocidad del carro
    q2_p_raw = (q2 - q2_prev)/dt;
    q2_p_f = alpha*q2_p_f + (1-alpha)*q2_p_raw;

    % Actualizar referencia PRBS
    t = toc(t0);

    if t >= t_ref_next
        if k <= numel(prbs)
            r = prbs(k);
            k = k + 1;
        else
            r = 0;
        end

        t_ref_next = t_ref_next + Ts_prbs;
    end

    % Control de posicion del carro
    % Realimentacion de estados
    q1_ref = Kp*(-r+q2); % - Kd*q2_p_f;

    % Enviar q1_ref al Wemos
    fprintf(s, '%.6f\n', q1_ref);

    % Guardar telemetria y variables del controlador
    T(end+1,:) = [timestamp_us, q1, q2, ...
                  u_wemos, r, q1_ref];

    % Actualizar muestras anteriores
    q2_prev = q2;
    ts_prev = timestamp_us;
end

% Llevar el torque a cero al terminar
fprintf(s, '0\n');

fclose(s);
delete(s);
clear s;

%% Procesamiento de los datos

timestamp_us = T(:,1);
q1 = T(:,2);
q2 = T(:,3);
u = T(:,4);

% Tiempo relativo usando el reloj del Wemos.
% Contempla el desbordamiento de micros() a los ~71.6 min.
dt_us = mod(diff(timestamp_us), 2^32);
t = [0; cumsum(dt_us)] * 1e-6;

datos = table(t, timestamp_us, q1, q2, u);

%% Graficos
figure;

subplot(2,1,1);
plot(t, q1 , t ,q2);
legend('Angulo barra [rad]','Posicion Carro [m]')
grid on;
ylabel('q');
title('Respuesta de la barra y el carro');

subplot(2,1,2);
stairs(t, u);
grid on;
ylabel('u [rad]');
xlabel('Tiempo [s]');
title('Entrada aplicada');

%% Guardar
%writetable(datos, 'datos_pendulo_prbs.csv');
%save('datos_pendulo_prbs.mat', 'datos', 'prbs', 'Ts_adq', 'Ts_prbs', 'A');
save('datos_cart_beam.mat', 'datos');

fprintf('\nMuestras adquiridas: %d\n', height(datos));
fprintf('Duracion registrada: %.3f s\n', t(end));
fprintf('Intervalo medio: %.3f ms\n', 1000*mean(diff(t)));
fprintf('Datos guardados.\n');