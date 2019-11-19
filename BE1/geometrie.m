%% Obtention des donnees du video

% Constants
nom_video = "Pub_C+_352_288_2.mp4";
cell_size = 30;
conv = 0;
signed = 0;
n_bins = 9;
video_h  = 176;
video_w = 144;


% Lecture du video
video = VideoReader(nom_video);
original_h  = video.Height;
original_w = video.Width;
sub_h = round(video_h / cell_size);
sub_w = round(video_w / cell_size);
video_frames = struct('cdata', zeros(video_h, video_w, 3, 'uint8'));

% Pour obtenir les images à niveaux de gris
k = 1;
cell_pixels = cell_size^2;
histogram_frames = zeros(sub_h, sub_w, n_bins, 1);

while hasFrame(video)
    video_frames(k).cdata = readFrame(video);
    video_frames(k).cdata = im2double(rgb2gray(video_frames(k).cdata));
    if original_h > video_h || original_w > video_w
        video_frames(k).cdata = imfilter(video_frames(k).cdata, fspecial('gaussian', 7, 1));
        video_frames(k).cdata = imresize(video_frames(k).cdata, [video_h video_w]);
    end
    hist_frame = HOG_function(video_frames(k).cdata, signed, conv, sub_w, sub_h, n_bins);
    histogram_frames(:, :, :, k)= hist_frame;
    k = k + 1;
end

frames_amount = size(video_frames, 2);
g_filter = fspecial('gaussian', [sub_h sub_w], 1);

%% Traitement geometrique : HOG + proportion de la surface minimal vs maximal

plot_data = zeros(1, frames_amount);
for fr = 2:frames_amount
    diff_frames = zeros(sub_h, sub_w);
    for x_cell = 1:sub_h
        for y_cell = 1:sub_w
            hist_a = squeeze(histogram_frames(x_cell, y_cell, :, fr - 1));
            hist_b = squeeze(histogram_frames(x_cell, y_cell, :, fr));
            max_area = sum(max(hist_a, hist_b));
            if max_area == 0
                diff_frames(x_cell, y_cell) = 0;
            else
                diff_frames(x_cell, y_cell) = 100 * (1 - (sum(min(hist_a, hist_b)) / max_area));
            end
        end
    end
    plot_data(1, fr) = sum(sum(diff_frames.*g_filter));
end

plot_data_g = imfilter(plot_data, [-1 0 1]);
plot_data_g2 = imfilter(plot_data_g, [-1 0 1]);
seuil = 50;


%% Graphique des donnees

figure;
plot(plot_data);


%% Traitement geometrique : HOG + proportion de la surface minimal vs maximal double

plot_data = zeros(1, frames_amount);
for fr = 2:(frames_amount - 1)
    diff_frames = zeros(sub_h, sub_w);
    for x_cell = 1:sub_h
        for y_cell = 1:sub_w
            hist_a = squeeze(histogram_frames(x_cell, y_cell, :, fr - 1));
            hist_b = squeeze(histogram_frames(x_cell, y_cell, :, fr));
            hist_c = squeeze(histogram_frames(x_cell, y_cell, :, fr + 1));
            max_area_back = sum(max(hist_a, hist_b));
            max_area_for = sum(max(hist_b, hist_c));
            if max_area_back == 0
                backward_diff = 0;
            else
                backward_diff =  100 * (1 - (sum(min(hist_a, hist_b)) / max_area_back));
            end

            if max_area_for == 0
                forward_diff = 0;
            else
                forward_diff = - 100 * (1 - (sum(min(hist_b, hist_c)) / max_area_for));
            end
            diff_frames(x_cell, y_cell) = (backward_diff + forward_diff) / 2;
        end
    end
    plot_data(1, fr) = sum(sum(diff_frames.*g_filter));
end

plot_data_g = imfilter(plot_data, [-1 0 1]);
plot_data_g2 = imfilter(plot_data_g, [-1 0 1]);
seuil = 14;


%% Filtrage des donnees

% Added 130, 588 to the ground truth
verite = [43 53 130 143 164 188 201 222 249 257 269 308 486 527 553 562 583 588 596 616 636 665 691 706 721 747 813 822 854 904 957 976 999 1028 1063 1100 1121 1145 1178 1221 1256 1294 1336 1368 1445 1574 1583 1656 1736 1813 1872 1896 1910 1961 2008 2017 2107 2148 2185 2244 2488 2527 2618 2689 2767 2776 2809 2830 2859 2882 2918 2935 2963 2979 3012 3087 3180 3278 3287];
faux_possitifs = [];
faux_negatifs = [];
vrai_possitifs = [];
filtered_data = plot_data > seuil & plot_data_g > 0 & plot_data_g2 < 0;
found_frames = find(filtered_data);

for i = 1:size(found_frames, 2)
    if sum(verite == found_frames(i)) == 0
        faux_possitifs = [faux_possitifs found_frames(i)];
    else
        vrai_possitifs = [vrai_possitifs found_frames(i)];
    end
end

for i = 1:size(verite, 2)
    if sum(found_frames == verite(i)) == 0
        faux_negatifs = [faux_negatifs verite(i)];
    end
end

seuil
signed
precision = size(vrai_possitifs, 2) / size(found_frames, 2)
rappel =  size(vrai_possitifs, 2) / size(verite, 2)