function [output1, output2] = HOG_function(IMG, signed, conv)
    %HOG_function
    %   HOG_function(IMG) returns a matrix output1 with the vectors of the
    %   histograms of each cell, and a vector output2 that represents
    %   the angles used as bins for the histograms

    [Sizex, Sizey] = size(IMG);

    % Creation of the dialog box
    prompt = {'Cell width:','Cell height:', 'Number of bins'};
    dlgtitle = 'HOG parameters';
    dims = [1 35];
    definput = {'30','30', '9'};
    
    % Default parameters
    cell_width = 30;
    cell_height = 30;
    number_bins = 9;
    
    % The values given by the user are in answer
    answer = inputdlg(prompt,dlgtitle,dims,definput);
    
    % Validation of the parameters
    if ~isnan(answer{1})
        cw = str2double(answer{1});
        if floor(cw) == cw && cw > 0
            cell_width = cw;
        end
    end
    if ~isnan(answer{2})
        cw = str2double(answer{2});
        if floor(cw) == cw && cw > 0
            cell_height = cw;
        end
    end
    if ~isnan(answer{3})
        cw = str2double(answer{3});
        if floor(cw) == cw && cw > 0
            number_bins = cw;
        end
    end

    % Getting magnitude and orientation of the image
    [G, Theta]  = magnitude_orientation(IMG, signed, conv);

    % Getting the amount of vertical (qvc) and horizontal (qhc) cells. We
    % add one to the integer part of qvc or qhc if they're not integers at
    % the beginning
    qvc = Sizex/cell_height;
    if ~ (floor(qvc) == qvc)
        qvc = floor(qvc) + 1;
    end

    qhc = Sizey/cell_width;
    if ~ (floor(qhc) == qhc)
        qhc = floor(qhc) + 1;
    end
    
    % Getting the vector of bins according to the parameter signed
    if signed
        vector_x = 0:360/number_bins:360;
    else
        vector_x = 0:180/number_bins:180;
    end
    
    vector_x = vector_x(1:number_bins);
    
    % Initialising variables
    hists_img = zeros(qvc, qhc, number_bins);
    x_cell = 1;
    y_cell = 1;
    sub_hist = 1;
    
    
    for n = 1:cell_height:Sizex
        for m = 1:cell_width:Sizey
            
            % Getting the limit of the cell in process
            Limit_sup = [min(Sizex, n + cell_height - 1) min(Sizey, m + cell_width - 1)];
            
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
                    
                    % Case when the angle is between the las bin and 180º or
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
            
            % Adding the vector of the cell in process to the matrix
            hists_img(x_cell, y_cell, :) = vector_y;
            
            % Ploting the histogram of the cell in process
            subplot(qvc, qhc, sub_hist), bar(vector_x, vector_y, 'hist'), set(gca,'xtick',[], 'ytick', []);
            y_cell = y_cell + 1;
            sub_hist = sub_hist + 1;
        end
        x_cell = x_cell + 1;
        y_cell = 1;
    end
    
    % Process to remove the space between the histograms of the differents
    % cells after ploting them all. We let a margin of 10% in the window
    % that shows the histograms
    pos_hist = get(gcf, 'children');
    pos_h = 0.9 - 0.8 / qhc;
    pos_v = 0.1;
    for i = 1:(qvc * qhc)
        set(pos_hist(i), 'position', [pos_h pos_v 0.8/qhc 0.8/qvc]);
        if floor(i / qhc) == i / qhc
            pos_h = 0.9 - 0.8 / qhc;
            pos_v = pos_v + 0.8 / qvc;
        else
            pos_h = pos_h - 0.8 / qhc; 
        end
    end
    
    output1 = hists_img;
    output2 = vector_x;
end