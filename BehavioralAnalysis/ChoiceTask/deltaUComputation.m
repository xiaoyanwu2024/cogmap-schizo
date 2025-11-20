clear; clc
load('data.mat'); % data of the choice task

for s = 1:length(data)
    % Find trial indices belonging to map 1 and map 2
    idx_map1 = find([data(s).data.map] == 1);  
    idx_map2 = find([data(s).data.map] == 2);  

    % Extract chosen and unchosen values for all trials
    chosen_value   = [data(s).data.chosen_value];
    unchosen_value = [data(s).data.unchosen_value];

    % Compute ΔU = chosen value – unchosen value for each map separately
    deltaU_map1(s,:) = chosen_value(idx_map1) - unchosen_value(idx_map1);
    deltaU_map2(s,:) = chosen_value(idx_map2) - unchosen_value(idx_map2);
end

% Combine the two maps by averaging (resulting size: [nSubjects × nTrials])
deltaU = (deltaU_map1 + deltaU_map2) / 2;

% Group labels
groups = [data.group];
img_idx  = strcmp(groups, 'image');
lang_idx = strcmp(groups, 'language');

x = 1:size(deltaU,2);  % Number of trials

% --- Compute group means and standard errors ---
mean_img = mean(deltaU(img_idx,:), 1);
se_img   = std(deltaU(img_idx,:), 0, 1) ./ sqrt(sum(img_idx));
ci95_img = 1.96 * se_img;   % 95% confidence interval

mean_lang = mean(deltaU(lang_idx,:), 1);
se_lang   = std(deltaU(lang_idx,:), 0, 1) ./ sqrt(sum(lang_idx));
ci95_lang = 1.96 * se_lang; % 95% confidence interval

% --- Plotting ---
figure; hold on;

% Image group (cyan #00CED1)
fill([x fliplr(x)], [mean_img-ci95_img fliplr(mean_img+ci95_img)], ...
    [0, 206, 209]/255, 'FaceAlpha',0.15, 'EdgeColor','none');
plot(x, mean_img, 'Color',[0, 206, 209]/255, 'LineWidth',2);

% Language group (purple #800080)
fill([x fliplr(x)], [mean_lang-ci95_lang fliplr(mean_lang+ci95_lang)], ...
    [128, 0, 128]/255, 'FaceAlpha',0.15, 'EdgeColor','none');
plot(x, mean_lang, 'Color',[128, 0, 128]/255, 'LineWidth',2);

xlabel('Trials');
ylabel('\Delta Value (chosen - unchosen)');
legend({'Image 95% CI','Image mean','Language 95% CI','Language mean'}, ...
       'Location','best');

set(gca,'FontName','Arial','FontSize',12);
box off;
