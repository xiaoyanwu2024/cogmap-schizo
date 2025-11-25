function trialList = createT1T2(T1, T2, object_location, baseTrials)
% Output: T1_1 represents the first restaurant and the first block

%% map 1
opt1_x = [];
opt1_y = [];
opt2_x = [];
opt2_y = [];
opt1_image = {};
opt2_image = {};
for t = 1:size(T1,1)
    % option 1
    opt1 = T1.Option1(t);
    idx1 = find([baseTrials{:,4}] == opt1);
    opt1_x = [opt1_x; object_location.("x(time)")(idx1)];
    opt1_y = [opt1_y; object_location.("y(age)")(idx1)];
    opt1_image = [opt1_image; baseTrials{idx1,3}];
    % option 2
    opt2 = T1.Option2(t);
    idx2 = find([baseTrials{:,4}] == opt2);
    opt2_x = [opt2_x; object_location.("x(time)")(idx2)];
    opt2_y = [opt2_y; object_location.("y(age)")(idx2)];
    opt2_image = [opt2_image; baseTrials{idx2,3}];
end

map = repmat(1, 60, 1);
option1 = T1.Option1;
option2 = T1.Option2;
value1 = T1.ValueOpt1;
value2 = T1.ValueOpt2;

T1Table = table(map, option1, option2, value1, value2, opt1_x, opt1_y, opt1_image, opt2_x, opt2_y, opt2_image);
nums = randperm(size(T1Table, 1));        % Shuffle indices 1 to 60
T1_1 = T1Table(nums(1:30), :);            % First 30 trials as the first block
T1_2 = T1Table(nums(31:end), :);          % Last 30 trials as the second block

%% map 2
opt1_x = [];
opt1_y = [];
opt2_x = [];
opt2_y = [];
opt1_image = {};
opt2_image = {};
for t = 1:size(T2,1)
    % option 1
    opt1 = T2.Option1(t);
    idx1 = find([baseTrials{:,4}] == opt1);
    opt1_x = [opt1_x; object_location.("x(time)")(idx1)];
    opt1_y = [opt1_y; object_location.("y(age)")(idx1)];
    opt1_image = [opt1_image; baseTrials{idx1,3}];
    % option 2
    opt2 = T2.Option2(t);
    idx2 = find([baseTrials{:,4}] == opt2);
    opt2_x = [opt2_x; object_location.("x(time)")(idx2)];
    opt2_y = [opt2_y; object_location.("y(age)")(idx2)];
    opt2_image = [opt2_image; baseTrials{idx2,3}];
end

map = repmat(2, 60, 1);
option1 = T2.Option1;
option2 = T2.Option2;
value1 = T2.ValueOpt1;
value2 = T2.ValueOpt2;

T2Table = table(map, option1, option2, value1, value2, opt1_x, opt1_y, opt1_image, opt2_x, opt2_y, opt2_image);
nums = randperm(size(T2Table,1));         % Shuffle indices 1 to 60
T2_1 = T2Table(nums(1:30), :);            % First 30 trials as the first block
T2_2 = T2Table(nums(31:end), :);          % Last 30 trials as the second block

% All valid sequences (using variables rather than strings)
seqs = {
    [T1_1; T2_1; T1_2; T2_2];   % A1 B1 A2 B2
    [T2_1; T1_1; T1_2; T2_2];   % B1 A1 A2 B2
    [T1_1; T2_1; T2_2; T1_2];   % A1 B1 B2 A2
    [T2_1; T1_1; T2_2; T1_2];   % B1 A1 B2 A2
    };

% Randomly select one sequence
rng('shuffle');
idx = randi(length(seqs));
trialList = seqs{idx};  % Output trial list

% Randomly generate an index to decide the assignment of 'Tree' and 'River'
idx = randi(2);
% Create a cell array to store restaurantName for each row
restaurantName = cell(1, size(trialList,1));
% Assign restaurant names according to idx
if idx == 1
    restaurantName(trialList.map == 1) = {'Tree'};
    restaurantName(trialList.map == 2) = {'River'};
else
    restaurantName(trialList.map == 1) = {'River'};
    restaurantName(trialList.map == 2) = {'Tree'};
end
% Add restaurantName as a new field to trialList
trialList.restaurantName = restaurantName';
