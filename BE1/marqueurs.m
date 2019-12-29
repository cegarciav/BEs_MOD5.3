% Paramètres initiaux (à modifier selon l'expérimentation)
nom_source_video = "Pub_C+_176_144.mp4";
nom_test_video = "Pub_C+_176_144.mp4";
spot_pub = get_pub('quick'); % quick, lipton, cegetel, salveta, polo, kitkat
seuil = 0.6;
nb_markers = 8;

% Chargement de la vidéo source
source_video = VideoReader(nom_source_video);
source_h = source_video.Height;
source_w = source_video.Width;
source_frames = struct('cdata', zeros(source_h, source_w, 3, 'uint8'));
k = 1;
while hasFrame(source_video)
    source_frames(k).cdata = readFrame(source_video);
    k = k + 1;
end

% Définition des images représentatives pour chaque plan du spot
potential_markers = zeros(1, size(spot_pub, 2) - 1);
for n = 1:(size(spot_pub, 2) - 1)
    current_plan = source_frames(spot_pub(n):(spot_pub(n + 1) - 1));
    
    % Calcul de l'image moyenne du plan
    mean_plan = zeros(source_h, source_w, 3);
    for m = 1:size(current_plan, 2)
        mean_plan = mean_plan + double(current_plan(m).cdata);
    end
    mean_plan = mean_plan / size(current_plan, 2);
    
    % Calcul des distances des images du plan par rapport à l'image moyenne
    distance_plan = zeros(1, size(current_plan, 2));
    for m = 1:size(current_plan, 2)
        distance_plan(1, m) = sum(sum(sum((double(current_plan(m).cdata) - mean_plan).^2)));
    end
    
    % L'image représentative du plan est celle dont la distance par rapport
    % à l'image moyenne est la plus grande
    potential_markers(n) = find(distance_plan == max(distance_plan), 1) + spot_pub(n) - 1;
end

% Choix des marqueurs en fonction de la richesse en information couleur
standard_deviation = zeros(1, size(spot_pub, 2) - 1);
for i = 1:size(potential_markers, 2)
    current_index = potential_markers(i);
    current_image = source_frames(current_index).cdata;
    
    % Calcul de l'écart-type pour chaque composante R, G, B selon ses moyennes
    for j=1:3
        colour_mean = sum(sum(current_image(:, :, j))) / ...
                                    (source_h * source_w);
        colour_dv = sum(sum((current_image(:, :, j) - colour_mean).^2)) / ...
                                     (source_h * source_w);
        standard_deviation(1, i) = standard_deviation(1, i) + sqrt(colour_dv);
    end
    % On garde de l'écart-type moyen
    standard_deviation(1, i) = standard_deviation(1, i) / 3;
end

% On choisit les k marqueurs ayant le plus grand écart-type moyen (richesse
% en couleurs)
markers = zeros(1, nb_markers);
for i = 1:nb_markers
    current_max = find(standard_deviation == max(standard_deviation), 1);
    standard_deviation(current_max) = -1;
    markers(i) = potential_markers(current_max);
end
markers = sort(markers);

% On rajoute la première image du spot aux marqueurs
markers = [spot_pub(1) markers];

% Chargement de la vidéo test
test_video = VideoReader(nom_test_video);
test_h  = test_video.Height;
test_w = test_video.Width;
test_frames = struct('cdata', zeros(test_h, test_w, 3, 'uint8'));
k = 1;
while hasFrame(test_video)
    test_frames(k).cdata = readFrame(test_video);
    k = k + 1;
end


% Algorithme de reconnaissance

departs_potentiels = [];
window_size = markers(size(markers, 2)) - markers(1);

for start_index = 1:(size(test_frames, 2) - window_size)
    
    nb_hits = 0;
    overall_mean_similarity = 0;
    
    % On mesure la similarité entre chaque marqueur et la frame correspondante
    for m = 1:size(markers, 2)
        
        test_frame_index = start_index + markers(m) - markers(1);
        marker_frame_index = markers(m);

        im_video = test_frames(test_frame_index).cdata;
        video_hist_r = imhist(im_video(:, :, 1)) / (test_h * test_w);
        video_hist_g = imhist(im_video(:, :, 2)) / (test_h * test_w);
        video_hist_b = imhist(im_video(:, :, 3)) / (test_h * test_w);
        
        im_marker = source_frames(marker_frame_index).cdata;
        spot_hist_r = imhist(im_marker(:, :, 1)) / (source_h * source_w);
        spot_hist_g = imhist(im_marker(:, :, 2)) / (source_h * source_w);
        spot_hist_b = imhist(im_marker(:, :, 3)) / (source_h * source_w);
        
        similarity_r = sum(min(video_hist_r, spot_hist_r)) / ...
                    sum(max(video_hist_r, spot_hist_r));
        similarity_g = sum(min(video_hist_g, spot_hist_g)) / ...
                    sum(max(video_hist_g, spot_hist_g));
        similarity_b = sum(min(video_hist_b, spot_hist_b)) / ...
                    sum(max(video_hist_b, spot_hist_b));
        
        mean_similarity = mean([similarity_r, similarity_g, similarity_b]);
        
        % On compare la mesure de similarité moyenne au seuil
        if mean_similarity < seuil
            break;
        else
            nb_hits = nb_hits + 1;
            overall_mean_similarity = overall_mean_similarity + mean_similarity;
        end
        
    end

    % Si toutes les mesures sont supérieures au seuil, on a alors trouvé un
    % départ potentiel
    if nb_hits == size(markers, 2)
        overall_mean_similarity = overall_mean_similarity / size(markers, 2);
        departs_potentiels = [departs_potentiels; start_index overall_mean_similarity];
    end

end

% Affichage du verdict (pour plus de détails, les départs potentiels sont 
% disponibles dans la variable departs_potentiels)
if size(departs_potentiels, 1) == 1 && departs_potentiels(1,1) == spot_pub(1)
    disp('OK')
else
    disp('NOT OK')
end
beep on; beep;
