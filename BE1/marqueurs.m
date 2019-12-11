%% Constants
nom_video = "Pub_C+_176_144.mp4";
cell_size = 30;
markers = 4;

%% Lecture du video original
k = 1;
video = VideoReader(nom_video);
original_h  = video.Height;
original_w = video.Width;
video_frames_1 = struct('cdata', zeros(original_h, original_w, 3, 'uint8'));

while hasFrame(video)
    video_frames_1(k).cdata = readFrame(video);
    k = k + 1;
end

%% QUICK
sequence = [53 143 164 188 201 222 249 257 269 308 486 527 553];

%% LIPTON
sequence = [562 583 596 616 636 665 691 706 721 747 813];

%% CEGETEL
sequence = [822 854 904 957 976 999 1028 1063 1100 1121 1145 1178 ...
                            1221 1256 1294 1336 1368 1445 1574];

%% SALVETA
sequence = [1583 1656 1736 1813 1872 1896 1910 1961 2008];

%% VW POLO
sequence = [2017 2107 2148 2185 2244 2488 2527 2618 2689 2767];

%% KIT KAT
sequence = [2776 2809 2830 2859 2882 2918 2935 2963 2979 3012 3087 3180 3278];

%% Obtention des marqueurs

%taille de la sequence
size_spot = size(sequence, 2);
%indexes
marked_images = zeros(1, size_spot - 1);
for n = 1:(size_spot - 1)
    current_plan = video_frames_1(sequence(n):(sequence(n + 1) - 1));
    mean_plan = zeros(original_h, original_w, 3, 'uint8');
    for m = 1:size(current_plan, 2)
        mean_plan = mean_plan + current_plan(m).cdata;
    end
    mean_plan = mean_plan / size(current_plan, 2);
    %distance carree
    distance_plan = zeros(1, size(current_plan, 2));
    for m = 1:size(current_plan, 2)
        distance_plan(1, m) = sum(sum(sum((current_plan(m).cdata - mean_plan).^2)));
    end
    marked_images(n) = find(distance_plan == min(distance_plan), 1) + sequence(n) - 1;
end

standard_deviation = zeros(1, size(sequence, 2) - 1);
for i = 1:size(marked_images, 2)
    current_index = marked_images(i);
    current_image = video_frames_1(current_index).cdata;
    %ecart type pour chaque composant R, G, B selon ses moyennes
    for j=1:3
        colour_mean = sum(sum(current_image(:, :, j))) / ...
                                    (original_h * original_w);
        colour_dv = sum(sum((current_image(:, :, j) - colour_mean).^2)) / ...
                                     (original_h * original_w);
        standard_deviation(1, i) = standard_deviation(1, i) + sqrt(colour_dv);
    end
    %ecart type moyenne pour les trois composants R, G, B
    standard_deviation(1, i) = standard_deviation(1, i) / 3;
end

selected_indexes = zeros(1, markers);
for i = 1:markers
    current_max = find(standard_deviation == max(standard_deviation), 1);
    standard_deviation(current_max) = -1;
    selected_indexes(i) = marked_images(current_max);
end

selected_indexes = sort(selected_indexes);

%% Considering times between markers 

seuil = 0.6;
video2compare = "Pub_C+_352_288_2.mp4";
% Lecture du video de test
k = 1;
videotest = VideoReader(video2compare);
test_h  = videotest.Height;
test_w = videotest.Width;
video_frames_test = struct('cdata', zeros(test_h, test_w, 3, 'uint8'));

while hasFrame(videotest)
    video_frames_test(k).cdata = readFrame(videotest);
    k = k + 1;
end

test_frames = size(video_frames_test, 2);

possible_starts = [];
for n = 1:test_frames
    valid_n = 0;
    mean_group = 0;
    for m = 1:size(selected_indexes, 2)
        video_index = n + selected_indexes(m) - selected_indexes(1);
        spot_index = selected_indexes(m);

        im_video = video_frames_test(video_index).cdata;
        video_hist_r = imhist(im_video(:, :, 1)) / (test_h * test_w);
        video_hist_g = imhist(im_video(:, :, 2)) / (test_h * test_w);
        video_hist_b = imhist(im_video(:, :, 3)) / (test_h * test_w);
        
        im_spot = video_frames_1(spot_index).cdata;
        spot_hist_r = imhist(im_spot(:, :, 1)) / (original_h * original_w);
        spot_hist_g = imhist(im_spot(:, :, 2)) / (original_h * original_w);
        spot_hist_b = imhist(im_spot(:, :, 3)) / (original_h * original_w);
        
        prop_r = sum(min(video_hist_r, spot_hist_r)) / ...
                    sum(max(video_hist_r, spot_hist_r));
        prop_g = sum(min(video_hist_g, spot_hist_g)) / ...
                    sum(max(video_hist_g, spot_hist_g));
        prop_b = sum(min(video_hist_b, spot_hist_b)) / ...
                    sum(max(video_hist_b, spot_hist_b));
        
        mean_prop = mean([prop_r, prop_g, prop_b]);
        if mean_prop < seuil
            break;
        else
            valid_n = valid_n + 1;
            mean_group = mean_group + mean_prop;
        end
    end
    if valid_n == 4
        mean_group = mean_group / size(selected_indexes, 2);
        possible_starts = [possible_starts; n mean_group];
    end
end
