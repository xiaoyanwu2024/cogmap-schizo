function baseTrials = generateBaseTrials(subID)
% Check whether the input is a three-digit integer
if ~isnumeric(subID) || subID < 100 || subID > 999 || floor(subID) ~= subID
    error('Input must be a three-digit integer.');
end

% Get current time, replacing all separators with underscores
timestamp = datestr(now, 'yyyy_mm_dd_HH_MM_SS');

% Define base trial structure
baseTrials = {
    'old',      'afternoon', '', 1, '', 'an old person',          'In the afternoon';
    'midAge',   'dawn',      '', 2, '', 'a middle-aged person',   'At dawn';
    'elderly',  'night',     '', 3, '', 'an elderly person',      'At night';
    'teenager', 'evening',   '', 4, '', 'a teenager',             'In the evening';
    'toddler',  'morning',   '', 5, '', 'a toddler',              'In the morning';
    'child',    'night',     '', 6, '', 'a child',                'At night'};

% Original food items
foods = {'Lasagna', 'MinestroneSoup', 'Fondue', 'FishChips', 'GrilledVegetables', 'Geschnetzeltes'};

% Shuffle and fill in
rng('shuffle');  % Ensure randomness
shuffledFoods = foods(randperm(length(foods)));
for i = 1:length(baseTrials(:, 1))
    baseTrials{i, 3} = shuffledFoods{i};
    baseTrials{i, 5} = timestamp;  % Add timestamp
end

% Save directory and filename
resultsDir = fullfile(pwd, 'baseTrials');
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

filename = sprintf('sub%03d_%s.mat', subID, timestamp(1:end-9));
fullpath = fullfile(resultsDir, filename);
save(fullpath, 'baseTrials');

fprintf('Saved baseTrials for subject %03d to %s\n', subID, fullpath);
end
