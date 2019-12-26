function output1 = cos_sim(HIST1, HIST2)
    %cos_sim
    %   cos_sim(HIST1, HIST2) takes two matrixes with the HOG of two images
    %   and returns the value of the cosine similarity. HIST1 and HIST2
    %   must have the same dimentions, otherwise the function will return
    %   0.
    
    [X1, Y1, Z1] = size(HIST1);
    [X2, Y2, Z2] = size(HIST2);
    if (X1 ~= X2) || (Y1 ~= Y2) || (Z1 ~= Z2)
        
        % Returning 0 if one of the dimensions are different
        output1 = 0;
    else
        
        % Creation of the row vectors with the histograms concatenated
        total_hist1 = zeros(1, Z1 * Y1 * X1);
        total_hist2 = zeros(1, Z1 * Y1 * X1);
        indice = 1;
        for i = 1:X1
            for j = 1:Y1
                for k = 1:Z1
                    total_hist1(1, indice) = HIST1(i, j, k);
                    total_hist2(1, indice) = HIST2(i, j, k);
                    indice = indice + 1;
                end
            end
        end

        % Application of the cosine similarity 
        num = 0;
        den_1 = 0;
        den_2 = 0;
        for k = 1:(Z1 * X1 * Y1)
            num = num + total_hist1(1, k) * total_hist2(1, k);
            den_1 = den_1 + total_hist1(1, k)^2;
            den_2 = den_2 + total_hist2(1, k)^2;
        end
        den_1 = sqrt(den_1);
        den_2 = sqrt(den_2);
        output1 = num / (den_1 * den_2);

    end
    
end