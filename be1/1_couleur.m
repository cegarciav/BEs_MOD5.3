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
plot_data = zeros(1, size(video_frames, 2) - 1);
for x = 2:size(video_frames, 2)
    hist_a = histogram_frames(:, 3, 6, x - 1);
    hist_b = histogram_frames(:, 3, 6, x);
    plot_data(1, x - 1) = sum(min(hist_a, hist_b)) / sum(max(hist_a, hist_b)) * 100;
end
figure;
plot(plot_data);

%%
