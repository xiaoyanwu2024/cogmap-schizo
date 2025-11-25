%% Map 1 settings
option_map1 = [1,2,3,4,6];
valueMap1 = [0.25, 0.67, 0.08, 0.5, 0.42]*95+5;  % Corresponding values for objects 1–6 (object 5 missing)

% All pairwise combinations + reversed order (permutations)
combs1 = nchoosek(option_map1, 2);
pairs1 = [combs1; combs1(:, [2 1])];  % Add reversed pairs, total 20 trials
pairs1 = repmat(pairs1, 3, 1);        % Repeat 3 times

% Fill structure
for p = 1:length(pairs1)
    Map1.option1(p,1) = pairs1(p,1);
    Map1.option2(p,1) = pairs1(p,2);

    % Find the corresponding value of each object
    idx1 = find(option_map1 == pairs1(p,1));
    idx2 = find(option_map1 == pairs1(p,2));

    Map1.value_op1(p,1) = valueMap1(idx1);
    Map1.value_op2(p,1) = valueMap1(idx2);
end

%% Map 2 settings
option_map2 = [1,3,4,5,6];
valueMap2 = [0.67, 0.94, 0.56, 0.11, 0.72]*95+5; % Corresponding values for objects 1–6 (object 1 missing)

combs2 = nchoosek(option_map2, 2);
pairs2 = [combs2; combs2(:, [2 1])];
pairs2 = repmat(pairs2, 3, 1);        % Repeat 3 times

for p = 1:length(pairs2)
    Map2.option1(p,1) = pairs2(p,1);
    Map2.option2(p,1) = pairs2(p,2);

    idx1 = find(option_map2 == pairs2(p,1));
    idx2 = find(option_map2 == pairs2(p,2));

    Map2.value_op1(p,1) = valueMap2(idx1);
    Map2.value_op2(p,1) = valueMap2(idx2);
end

%% Convert to tables
% Convert Map1 structure to table
T1 = table( ...
    repmat(1, length(Map1.option1), 1), ...       % Map index column
    Map1.option1, ...
    Map1.option2, ...
    Map1.value_op1, ...
    Map1.value_op2, ...
    'VariableNames', {'Map', 'Option1', 'Option2', 'Value1', 'Value2'});

% Convert Map2 structure to table
T2 = table( ...
    repmat(2, length(Map2.option1), 1), ...
    Map2.option1, ...
    Map2.option2, ...
    Map2.value_op1, ...
    Map2.value_op2, ...
    'VariableNames', {'Map', 'Option1', 'Option2', 'Value1', 'Value2'});

%% Add jitter to values
for t = 1:size(T1, 1)
    T1.ValueOpt1(t) = round(T1.Value1(t) + randi([-3, 3], 1));
    T1.ValueOpt2(t) = round(T1.Value2(t) + randi([-3, 3], 1));

    T2.ValueOpt1(t) = round(T2.Value1(t) + randi([-3, 3], 1));
    T2.ValueOpt2(t) = round(T2.Value2(t) + randi([-3, 3], 1));
end

save('T1T2.mat', 'T1', 'T2');
