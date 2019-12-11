%% Initialisation et chargement de la vidéo

nom_video = "Pub_C+_176_144.mp4";
sub_h = 6; % nombre de subdivisions en hauteur
sub_w = 6; % nombre de subdivisions en largeur

% Lecture de la vidéo
video = VideoReader(nom_video);
video_h  = video.Height;
video_w = video.Width;
video_frames = struct('cdata', zeros(video_h, video_w, 3, 'uint8'));

cell_height = floor(video_h / sub_h);
cell_width = floor(video_w / sub_w);
cell_pixels = cell_width * cell_height;

%% Création des histogrammes

histogram_frames = zeros(255, sub_h, sub_w, size(video_frames, 2));

frame_number = 1;
while hasFrame(video)
    video_frames(frame_number).cdata = readFrame(video);
    video_frames(frame_number).cdata = rgb2gray(video_frames(frame_number).cdata);
    for n = 1:sub_h
        for m = 1:sub_w
            list_h = ((n - 1) * cell_height + 1) : (n * cell_height);
            list_w = ((n - 1) * cell_width + 1) : (n * cell_width);
            hist_zone = imhist(video_frames(frame_number).cdata(list_h, list_w), 255) / cell_pixels;
            histogram_frames(:, n, m, frame_number) = hist_zone;
        end
    end
    frame_number = frame_number + 1;
end

%% Calcul des pourcentages de similarité

similarite = zeros(sub_h, sub_w, size(video_frames, 2) - 1);
for n = 1:sub_h
    for m = 1:sub_w
        for x = 2:size(video_frames, 2)
            hist_a = histogram_frames(:, n, m, x - 1);
            hist_b = histogram_frames(:, n, m, x);
            similarite(n, m, x - 1) = sum(min(hist_a, hist_b)) / sum(max(hist_a, hist_b)) * 100;
        end
    end
end

% Affichage des similarités pour la division (3,6) de la vidéo
figure;
zone_to_plot = squeeze(similarite(3,6,:));
plot(zone_to_plot);

%% Recherche des changements de plan pour un seuil de similarité de 0.33

change_seuil = 33;
change_or_not = zeros(1, size(video_frames, 2) - 1);
for x = 1:(size(video_frames, 2) - 1)
    change_or_not(1,x) = ( mean(similarite(:,:,x), 'all') < change_seuil );
end
changements = find(change_or_not);

%% Calcul de la précision et du rappel pour le seuil de 0.33

verite = get_verite_terrain();
vrais_positifs = [];
for i = 1:size(changements, 2)
    if sum(verite == changements(i)) > 0
        vrais_positifs = [vrais_positifs changements(i)];
    end
end

figure;
plot(changements_par_seuil);
%}

precision = size(vrais_positifs, 2) / size(changements, 2)
rappel = size(vrais_positifs, 2) / size(verite, 1)


%% Influence du seuil sur la précision et le rappel

seuils = 1:99;
precisions = [];
rappels = [];
verite = get_verite_terrain();

for s = 1:size(seuils, 2)
    change_or_not = zeros(1, size(video_frames, 2) - 1);
    for x = 1:(size(video_frames, 2) - 1)
        change_or_not(1,x) = ( mean(similarite(:,:,x), 'all') < seuils(s) );
    end
    changements = find(change_or_not);
    
    vrais_positifs = [];
    for i = 1:size(changements, 2)
        if sum(verite == changements(i)) > 0
            vrais_positifs = [vrais_positifs changements(i)];
        end
    end
    precision = size(vrais_positifs, 2) / size(changements, 2);
    precisions = [precisions precision];
    rappel = size(vrais_positifs, 2) / size(verite, 1);
    rappels = [rappels rappel];
end

figure;
plot(seuils, precisions, 'DisplayName', 'Precision');
hold on;
plot(seuils, rappels, 'DisplayName', 'Rappel');
xlabel('Seuil (%)');
legend;



