function RUN_ALL_TASKS()
% RUN_ALL_TASKS
% This function runs all experimental tasks in sequence for a given participant.
% It collects participant information, identifies the experimental group
% (Image vs. Language), selects the session day (Day 1 or Day 2), and then
% executes each task in the predefined order.

% -----------------------------
% Get participant ID
% -----------------------------
% Prompt the experimenter to enter the participant ID.
subID = inputdlg('Enter participant ID (e.g., 001):', 'Subject Info');
subid = subID{1};

% -----------------------------
% Group assignment
% -----------------------------
% Ask whether the participant belongs to the Image group or Language group.
groupChoice = questdlg('Which group is?', 'Group Selection', 'Image', 'Language', 'Image');
if isempty(groupChoice), error('You must choose Image or Language.'); end
% Normalize group name (e.g., "Image" -> "image")
group = lower(strrep(groupChoice, ' ', ''));

% -----------------------------
% Session day selection
% -----------------------------
% Allow the experimenter to choose whether this is Day 1 or Day 2.
dayChoice = questdlg('Which session is this?', 'Day Selection', 'Day 1', 'Day 2', 'Day 1');
if isempty(dayChoice), error('You must choose Day 1 or Day 2'); end
if strcmpi(dayChoice, 'Day 1')
    dayLabel = 'day1';
else
    dayLabel = 'day2';
end

% -----------------------------
% Set root directory
% -----------------------------
% Store the current working directory as the root directory so the script
% can return to it after running each task.
root_dir = pwd;

% -----------------------------
% Run tasks sequentially
% -----------------------------
try
    % Task 1: Ordering task
    cd(fullfile(root_dir, 'T1_ordering', group));
    if strcmp(group, 'image')
        orderTaskImage(subid, dayLabel);
    else
        orderTaskLanguage(subid, dayLabel); % Assumes this function exists
    end

    % Task 2: Association learning
    cd(fullfile(root_dir, 'T2_associationLearn', group));
    if strcmp(group, 'image')
        associationLearnImage(subid, dayLabel);
    else
        associationLearnLanguage(subid, dayLabel);
    end

    % Task 3: Similarity detection task
    cd(fullfile(root_dir, 'T3_similarityDetection'));
    SimilarityTask(subid, group);

    % Task 4: Choice task
    cd(fullfile(root_dir, 'T4_choiceTask'));
    choiceTask(subid, group);
    cd(fullfile(root_dir, 'T4_choiceTask'));
    ValueRatingTask(subid, group);

    % Task 5: Location dragging task
    cd(fullfile(root_dir, 'T5_LocationDrag'));
    LocationDrag(subid, group);

    % Return to root and notify completion
    cd(root_dir);
    fprintf('\nAll tasks completed.\n');

catch ME
    % In case of error, return to the root directory and rethrow the error
    cd(root_dir);
    rethrow(ME);
end

end
