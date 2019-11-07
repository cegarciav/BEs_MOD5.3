% Constants
nom_video = "Pub_C+_176_144.mp4";
sub_h = 6;
sub_w = 6;


% Lecture du video
video = VideoReader(nom_video);
video_h  = video.Height;
video_w = video.Width;
video_frames = struct('cdata', zeros(video_h, video_w, 3, 'uint8'));

% Pour obtenir les images à niveaux de gris
k = 1;
cell_height = floor(video_h / sub_h);
cell_width = floor(video_w / sub_w);
cell_pixels = cell_width * cell_height;
histogram_frames = zeros(255, sub_h, sub_w, size(video_frames, 2));

while hasFrame(video)
    video_frames(k).cdata = readFrame(video);
    video_frames(k).cdata = rgb2gray(video_frames(k).cdata);
    for n = 1:sub_h
        for m = 1:sub_w
            list_h = ((n - 1) * cell_height + 1) : (n * cell_height);
            list_w = ((n - 1) * cell_width + 1) : (n * cell_width);
            hist_zone = imhist(video_frames(k).cdata(list_h, list_w), 255) / cell_pixels;
            histogram_frames(:, n, m, k) = hist_zone;
        end
    end
    k = k + 1;
end

%%

% Plot example for percentages of similarity for one division (3,6)
plot_data = zeros(1, size(video_frames, 2) - 1);
for x = 2:size(video_frames, 2)
    hist_a = histogram_frames(:, 3, 6, x - 1);
    hist_b = histogram_frames(:, 3, 6, x);
    plot_data(1, x - 1) = sum(min(hist_a, hist_b)) / sum(max(hist_a, hist_b)) * 100;
end

%%

figure;
plot(plot_data);

%%

complete_plot_data = zeros(sub_h, sub_w, size(video_frames, 2) - 1);
for n = 1:sub_h
    for m = 1:sub_w
        for x = 2:size(video_frames, 2)
            hist_a = histogram_frames(:, n, m, x - 1);
            hist_b = histogram_frames(:, n, m, x);
            complete_plot_data(n, m, x - 1) = sum(min(hist_a, hist_b)) / sum(max(hist_a, hist_b)) * 100;
        end
    end
end

%%

figure;
zone_to_plot = squeeze(complete_plot_data(3,6,:));
plot(zone_to_plot);

%%

change_seuil = 35;
change_or_not = zeros(1, size(video_frames, 2) - 1);
for x = 1:(size(video_frames, 2) - 1)
    change_or_not(1,x) = ( mean(complete_plot_data(:,:,x), 'all') < change_seuil );
end
changements = find(change_or_not);

%%

%{
seuils = 0:5:50;
changements_par_seuil = zeros(1, size(seuils, 2));
for s = 1:size(seuils)
    change_or_not_s = zeros(1, size(video_frames, 2) - 1);
    for x = 1:(size(video_frames, 2) - 1)
        change_or_not_s(1,x) = ( mean(complete_plot_data(:,:,x), 'all') < seuils(s) );
    end
    changements_par_seuil(1,s) = size(find(change_or_not_s), 2)
end

figure;
plot(changements_par_seuil);
}%









