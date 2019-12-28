% Constants
nom_video = "Pub_C+_176_144.mp4";
video2compare = "Pub_C+_352_288_1.mp4";
sequence = get_pub('cegetel'); % quick, lipton, cegetel, salveta, polo, kitkat
seuil = 0.6;
nb_markers = 8;

% Lecture du video original
k = 1;
video = VideoReader(nom_video);
original_h  = video.Height;
original_w = video.Width;
video_frames_1 = struct('cdata', zeros(original_h, original_w, 3, 'uint8'));

while hasFrame(video)
    video_frames_1(k).cdata = readFrame(video);
    k = k + 1;
end

% Obtention des marqueurs

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
    marked_images(n) = find(distance_plan == max(distance_plan), 1) + sequence(n) - 1;
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

selected_indexes = zeros(1, nb_markers);
for i = 1:nb_markers
    current_max = find(standard_deviation == max(standard_deviation), 1);
    standard_deviation(current_max) = -1;
    selected_indexes(i) = marked_images(current_max);
end

selected_indexes = sort(selected_indexes);
selected_indexes = [sequence(1) selected_indexes];

% Considering times between markers 


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
greatest_diff = selected_indexes(size(selected_indexes, 2)) - selected_indexes(1);
for n = 1:(test_frames - greatest_diff)
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
    if valid_n == size(selected_indexes, 2)
        mean_group = mean_group / size(selected_indexes, 2);
        possible_starts = [possible_starts; n mean_group];
    end
end
