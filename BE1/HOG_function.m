%function [output1, output2] = HOG_function(IMG, signed, conv, awc, ahc, n_bins)
function output1 = HOG_function(IMG, signed, conv, awc, ahc, n_bins)
    %HOG_function
    %   HOG_function(IMG, signed, conv, awc, ahc, n_bins) returns a matrix
    %   output1 with the vectors of the histograms of each cell, and a
    %   vector output2 that represents the angles used as bins for the
    %   histograms.

    [Sizex, Sizey] = size(IMG);
    cell_height = floor(Sizex / ahc);
    cell_width = floor(Sizey / awc);

    % Getting magnitude and orientation of the image
    [G, Theta]  = magnitude_orientation(IMG, signed, conv);
    
    % Getting the vector of bins according to the parameter signed
    if signed
        vector_x = 0:360/n_bins:360;
    else
        vector_x = 0:180/n_bins:180;
    end
    
    vector_x = vector_x(1:n_bins);
    
    % Initialising variables
    hists_img = zeros(ahc, awc, n_bins);
    x_cell = 1;
    y_cell = 1;
    
    for n = 1:cell_height:Sizex
        for m = 1:cell_width:Sizey
            
            % Getting the limit of the cell in process
            limit_h = min(Sizex, n + cell_height - 1);
            if x_cell == ahc
                limit_h = Sizex;
            end
            limit_w = min(Sizey, m + cell_width - 1);
            if y_cell == awc
                limit_w = Sizey;
            end
            Limit_sup = [limit_h, limit_w];
            ppcell = (limit_h - n + 1) * (limit_w - m + 1);
            
            % vector_y is the vector with the values of the histogram for
            % the cell in process
            vector_y = zeros(1, length(vector_x));
            
            % Iterating on the cell
            for i = n:Limit_sup(1)
                for j = m:Limit_sup(2)
                    angle = Theta(i, j);
                    
                    % Adding the values when the angle of the pixel (i, j)
                    % is one of the values of the bins
                    for k = 1:length(vector_x)
                        if angle == vector_x(k)
                            vector_y(k) = vector_y(k) + G(i, j);
                        end
                    end
                    for k = 2:length(vector_x)
                        
                        % Case when the angle is between two bins and we
                        % need to interpolate
                        if angle < vector_x(k) && angle > vector_x(k - 1)
                            prop_inf = 1 - (angle - vector_x(k - 1))/(vector_x(k) - vector_x(k - 1));
                            value_inf = prop_inf * G(i, j);
                            value_sup = (1 - prop_inf) * G(i, j);
                            vector_y(k - 1) = vector_y(k - 1) + value_inf;
                            vector_y(k) = vector_y(k) + value_sup;
                        end
                    end
                    
                    % Case when the angle is between the last bin and 180º or
                    % 360º according to the parameter signed
                    if angle > vector_x(length(vector_x))
                        prop_inf = 1 - (angle - vector_x(length(vector_x))) / (vector_x(length(vector_x)) - vector_x(length(vector_x) - 1));
                        value_inf = prop_inf * G(i, j);
                        value_sup = (1 - prop_inf) * G(i, j);
                        vector_y(length(vector_x)) = vector_y(length(vector_x)) + value_inf;
                        vector_y(1) = vector_y(1) + value_sup;
                    end
                    
                    % Case when the angle is between 0 and the first bin
                    if angle < vector_x(1)
                        prop_sup = 1 - (vector_x(1) - angle)/(vector_x(2) - vector_x(1));
                        value_inf = (1 - prop_sup) * G(i, j);
                        value_sup = prop_sup * G(i, j);
                        vector_y(length(vector_x)) = vector_y(length(vector_x)) + value_inf;
                        vector_y(1) = vector_y(1) + value_sup;
                    end
                end
            end
            
            % Adding the normalized vector of the cell in process to the matrix
            hists_img(x_cell, y_cell, :) = vector_y / ppcell;
            
            y_cell = y_cell + 1;
            if y_cell > awc
                break;
            end
        end
        x_cell = x_cell + 1;
        y_cell = 1;
        if x_cell > ahc
            break;
        end
    end
    
    output1 = hists_img;
    %output2 = vector_x;
end