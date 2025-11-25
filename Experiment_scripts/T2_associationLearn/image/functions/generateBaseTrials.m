function baseTrials = generateBaseTrials(subID)
% Check whether input is a three-digit integer
if ~isnumeric(subID) || subID < 100 || subID > 999 || floor(subID) ~= subID
    error('Input must be a three-digit integer.');
end

% Get current time, replace all separators with underscores
timestamp = datestr(now, 'yyyy_mm_dd_HH_MM_SS');

% Define base trial structure
baseTrials = {
    'old',      'afternoon', '', 1;
    'midAge',   'dawn',      '', 2;
    'elderly',  'night',     '', 3;
    'teenager', 'sunset',    '', 4;
    'toddler',  'morning',   '', 5;
    'child',    'night',     '', 6};

% Original food items
foods = {'Lasagna', 'MinestroneSoup', 'Fondue', 'FishChips', 'GrilledVegetables', 'Geschnetzeltes'};

% Shuffle and insert foods
rng('shuffle');  % Put at the beginning to ensure randomness
shuffledFoods = foods(randperm(length(foods)));
for i = 1:length(baseTrials)
    baseTrials{i, 3} = shuffledFoods{i};
    baseTrials{i, 5} = timestamp;  % Add timestamp
end

% Directory and filename for saving
resultsDir = fullfile(pwd, 'baseTrials');
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

filename = sprintf('sub%03d_%s.mat', subID, timestamp(1:end-9));
fullpath = fullfile(resultsDir, filename);
save(fullpath, 'baseTrials');

fprintf('Saved baseTrials for subject %03d to %s\n', subID, fullpath);
end
