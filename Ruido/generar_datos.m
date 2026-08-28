t = double(out.tout);
u = double(out.u);
ang_imu = double(out.ang_imu);
x = double(out.x);

save('Barra_movil', 't', 'u', 'ang_imu', 'x'); %para volcar los datos en un archivo
%Para recuperar: load('datos_sin_carrito.mat');
