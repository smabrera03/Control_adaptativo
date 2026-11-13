%{

Calcular la matriz de información para un modelo ARX dadas las señales u e
y y los ordenes [na nb nk]

Entradas: z_id (es un objeto IDDATA con las señales de entrada y salida), ordenes = [na nb nk]

Salidas: Matirz de información M = Phi´ * Phi, su rango, sus autovalores y
su numero de condicion. (El objetivo es definir si la matriz es inversible
o no, si es inversible la información es suficiente para estimar el modelo)

Al llamarse la función debe imprimirse un mensaje por consola que inidque
si la matriz es inversible o no, junto con su número de condición


%}


function [M, rango, autovalores, num_cond] = matriz_de_informacion(z_id, ordenes, mostrar)
%{
Calcular la matriz de información para un modelo ARX dadas las señales u e
y y los ordenes [na nb nk]

Entradas: z_id (es un objeto IDDATA con las señales de entrada y salida), ordenes = [na nb nk]
          mostrar (opcional, booleano): si es true imprime la información
          por consola. Por defecto es true.

Salidas: Matriz de información M = Phi' * Phi, su rango, sus autovalores y
su numero de condicion. (El objetivo es definir si la matriz es inversible
o no, si es inversible la información es suficiente para estimar el modelo)

Al llamarse la función debe imprimirse un mensaje por consola que indique
si la matriz es inversible o no, junto con su número de condición

Modelo ARX:
y(t) + a1*y(t-1) + ... + a_na*y(t-na) = b1*u(t-nk) + ... + b_nb*u(t-nk-nb+1) + e(t)

Vector de regresores:
phi(t) = [-y(t-1) ... -y(t-na)  u(t-nk) ... u(t-nk-nb+1)]'
%}

    % --- Valor por defecto de 'mostrar' ---
    if nargin < 3 || isempty(mostrar)
        mostrar = true;
    end

    % --- Órdenes ---
    na = ordenes(1);
    nb = ordenes(2);
    nk = ordenes(3);

    % --- Señales ---
    y = z_id.OutputData;
    u = z_id.InputData;

    if iscell(y)
        error('El iddata tiene múltiples experimentos. Usá un único experimento.');
    end
    if size(y, 2) ~= 1 || size(u, 2) ~= 1
        error('La función solo admite sistemas SISO (una entrada, una salida).');
    end

    N = length(y);
    d = na + nb;                          % cantidad de parámetros

    % Primer instante en el que todos los regresores están disponibles
    t0 = max(na, nk + nb - 1) + 1;
    if t0 > N
        error('No hay suficientes muestras para los órdenes especificados.');
    end

    % --- Matriz de regresores Phi ---
    t   = (t0:N)';
    Phi = zeros(length(t), d);

    for i = 1:na
        Phi(:, i) = -y(t - i);                % parte autorregresiva
    end
    for j = 1:nb
        Phi(:, na + j) = u(t - nk - j + 1);   % parte exógena
    end

    % --- Matriz de información y propiedades ---
    M           = Phi' * Phi;
    rango       = rank(M);
    autovalores = sort(eig(M), 'descend');
    num_cond    = cond(M);

    % --- Mensaje por consola ---
    if mostrar
        fprintf('\nModelo ARX [na nb nk] = [%d %d %d]  ->  M de %dx%d\n', na, nb, nk, d, d);
        fprintf('Rango de M: %d de %d\n', rango, d);
        fprintf('Autovalor máximo: %.4e | Autovalor mínimo: %.4e\n', ...
                autovalores(1), autovalores(end));

        if rango == d
            fprintf('La matriz de información ES inversible. Número de condición: %.4e\n', num_cond);
            if num_cond > 1e10
                fprintf(['  Atención: M está mal condicionada. La estimación puede ser ' ...
                         'numéricamente sensible (excitación pobre o sobreparametrización).\n']);
            end
        else
            fprintf('La matriz de información NO es inversible. Número de condición: %.4e\n', num_cond);
            fprintf('  La información de los datos no alcanza para estimar el modelo.\n');
        end
        fprintf('\n');
    end
end
