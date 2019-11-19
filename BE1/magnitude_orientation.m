function [output1, output2] = magnitude_orientation(IMG, signed, conv)
    %magnitude_orientation
    %   magnitude_orientation(IMG, signed, conv) returns a matrix output1
    %   with the magnitude of the gradient of IMG and another matrix 
    %   output2 with the orientation between 0 and 180 if signed = 0 and
    %   between 0 and 360 otherwise. The function uses the option 'conv'
    %   to filter the image if conv is different from 0.

    [Sizex, Sizey] = size(IMG);
    
    % filter the image using convolution or correlation according to
    % the parameter conv given. Ix has the values of the horizontal
    % gradients and Iy the values of the vertical gradients
    if conv
        Ix = imfilter(IMG, [-1 0 1], 'conv');
        Iy = imfilter(IMG, [-1; 0; 1], 'conv');
    else
        Ix = imfilter(IMG, [-1 0 1]);
        Iy = imfilter(IMG, [-1; 0; 1]);
    end

    % Return of the magnitude of the gradients
    output1 = (Ix.^2 + Iy.^2).^(1/2);
    
    % Angles in degrees acording to atan2, so between -180 and 180
    Theta = (180 / pi) * atan2(Iy, Ix);

    % Transformation of the interval of angles according to the parameter
    % signed (0º to 180º or 0º to 360º)
    for i = 1:Sizex
        for j = 1:Sizey
            if signed
                if Theta(i, j) < 0
                    Theta(i, j) = 360 + Theta(i, j);            
                end
            else
                if Theta(i, j) < 0
                    Theta(i, j) = 180 + Theta(i, j);
                end
            end
        end
    end

    output2 = Theta;

end
