clear; clc
load('SimilarityData.mat');

%% ============================================
%  Concatenate all subjects’ data
% ============================================
all_subid = [];
all_group = [];
all_distance = [];
all_similarity = [];

for s = 1:length(SimilarityData)
    nTrials = length(SimilarityData(s).data);

    % Extract subject-specific information
    subid      = str2double(SimilarityData(s).subid);
    group      = repmat({SimilarityData(s).group}, nTrials, 1);
    distances  = [SimilarityData(s).data.distance]';
    similarities = [SimilarityData(s).data.similarity]';

    % Append to the aggregated dataset
    all_subid      = [all_subid; repmat(subid, nTrials, 1)];
    all_group      = [all_group; group];
    all_distance   = [all_distance; distances];
    all_similarity = [all_similarity; similarities];
end

% Final table: one row per trial
dataset = table(all_subid, all_group, all_distance, all_similarity, ...
    'VariableNames', {'subid','group','distance','similarity'});

%% ============================================
%  Fit Linear Mixed-Effects Model (LMM)
%  Model: similarity ~ distance * group + (1 | subid)
% ============================================
lme = fitlme(dataset, 'similarity ~ distance*group + (1|subid)');

% Display results
disp(lme)
anova(lme);   % Check significance of interaction terms


%% ============================================
%  Prepare normalized scatter + regression plot
%  Dissimilarity = (10 − similarity), then normalized to [0,1]
% ============================================

% -------- Extract by group --------
dist_image = dataset.distance(dataset.group == "image");
sim_image  = 10 - dataset.similarity(dataset.group == "image");  % convert to dissimilarity

dist_language = dataset.distance(dataset.group == "language");
sim_language  = 10 - dataset.similarity(dataset.group == "language");

% -------- Combine for global min-max normalization --------
all_dist = [dist_image; dist_language];
all_sim  = [sim_image;  sim_language];

min_dist = min(all_dist);   max_dist = max(all_dist);
min_sim  = min(all_sim);    max_sim  = max(all_sim);

range_dist = max_dist - min_dist;
range_sim  = max_sim  - min_sim;

% Avoid division by zero (if data are constant)
if range_dist == 0
    all_dist_norm = zeros(size(all_dist));
else
    all_dist_norm = (all_dist - min_dist) / range_dist;
end

if range_sim == 0
    all_sim_norm = zeros(size(all_sim));
else
    all_sim_norm = (all_sim - min_sim) / range_sim;
end

% -------- Split normalized values back to groups --------
n_img = numel(dist_image);
dist_image_norm     = all_dist_norm(1:n_img);
dist_language_norm  = all_dist_norm(n_img+1:end);

sim_image_norm      = all_sim_norm(1:n_img);
sim_language_norm   = all_sim_norm(n_img+1:end);

% Colors for plotting
col_img  = [0 180 200] / 255;   % cyan
col_lang = [148 103 189] / 255; % purple

%% ============================================
%  Fit separate simple linear models to each group
% ============================================
mdl_img  = fitlm(dist_image_norm(:),     sim_image_norm(:));
mdl_lang = fitlm(dist_language_norm(:),  sim_language_norm(:));

% Predict on a uniform grid in the normalized space
xgrid = linspace(0, 1, 100)'; 
[y_img,  CI_img]  = predict(mdl_img,  xgrid);
[y_lang, CI_lang] = predict(mdl_lang, xgrid);

%% ============================================
%  Plot regression lines with 95% CI (normalized space)
% ============================================
figure; hold on;

% 95% CI (Image)
fill([xgrid; flipud(xgrid)], ...
     [CI_img(:,1); flipud(CI_img(:,2))], ...
     col_img, 'FaceAlpha',0.20, 'EdgeColor','none');

% Regression line (Image)
plot(xgrid, y_img, 'Color', col_img, 'LineWidth', 2);

% 95% CI (Language)
fill([xgrid; flipud(xgrid)], ...
     [CI_lang(:,1); flipud(CI_lang(:,2))], ...
     col_lang, 'FaceAlpha',0.20, 'EdgeColor','none');

% Regression line (Language)
plot(xgrid, y_lang, 'Color', col_lang, 'LineWidth', 2);

% Appearance settings
xlabel('Normalized 2D distance');
ylabel('Normalized dissimilarity');
legend({'Image 95% CI','Image fit', ...
        'Language 95% CI','Language fit'}, 'Location','northwest');
set(gca,'FontSize',12,'Box','off');
xlim([0 1]); ylim([0 1]);
