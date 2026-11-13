%

function [y_f] = filtrar(alfa, y)
    y_f = zeros(size(y));
    y_f(1) = y(1);

    for k = 2:length(y)
        y_f(k) = alfa*y_f(k-1) + (1-alfa)*y(k);
    end
    
end