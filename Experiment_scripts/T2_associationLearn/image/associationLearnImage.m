function associationLearnImage(subid,day)
try
    %% initialization
    addpath(fullfile(pwd,'/functions'));
    Screen('Preference', 'SkipSyncTests', 1);
    KbName('UnifyKeyNames');
    ListenChar(2);

    % Switch baseTrials depending on day1 or day2
    if strcmp(day, 'day1')
        baseTrials = generateBaseTrials(str2double(subid));
    else
        baseTrialsFolder = fullfile(pwd, 'baseTrials');
        trialFiles = dir(fullfile(baseTrialsFolder, sprintf('sub%s*.mat', subid)));
        if isempty(trialFiles)
            error('No baseTrials file found in baseTrials folder for subject %s.', subid);
        end
        load(fullfile(trialFiles(1).folder, trialFiles(1).name), 'baseTrials');
    end

    resultsDir = fullfile(pwd, 'results', day, ['sub_' subid]);
    if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end

    screenNumber = max(Screen('Screens'));
    [win, winRect] = Screen('OpenWindow', screenNumber, 255);
    [xCenter, yCenter] = RectCenter(winRect);
    Screen('TextSize', win, 28);
    HideCursor;

    %% Instruction for association task
    instrDir = fullfile(pwd, 'stimuli');
    instrFiles = [];
    for i = 1:4
        if i == 1
            instrPattern = sprintf('ins1_%s.tiff', day);  % e.g. ins_day1.tiff
        else
            instrPattern = sprintf('ins%d.tiff', i);     % e.g. ins2.tiff
        end
        instrFiles = [instrFiles; dir(fullfile(instrDir, instrPattern))];
    end
    instrPages = sort({instrFiles.name});

    page = 1;  % Initial page

    while page <= length(instrPages)
        instrImg = imread(fullfile(instrDir, instrPages{page}));
        if page == 2
            tex = showExampleCombinations(win, instrImg, baseTrials);
        else
            tex = DrawImageNoStretch(win, instrImg);
        end
        Screen('Flip', win);
        WaitSecs(0.5); % Delay to prevent mis-clicks

        % Wait for user key press
        while true
            checkForEscape();
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown
                if keyCode(KbName('RightArrow'))
                    page = page + 1;
                    break;
                elseif keyCode(KbName('LeftArrow'))
                    page = max(1, page - 1);
                    break;
                end
            end
        end
        WaitSecs(0.2); % Debounce
        Screen('Close', tex);
    end

    % Show start prompt
    Screen('FillRect', win, 255);  % White background
    DrawFormattedText(win, 'Press any key to start.', 'center', 'center', [0 0 0]);  % Black texts
    Screen('Flip', win);
    WaitSecs(0.2);
    KbWait;

    %% association task parameters
    minRepeats = 3;
    testRepeats = 2;
    consecutiveCorrectRequired = 12 - 2; % Minimum 10 correct out of 12

    perm1 = randperm(size(baseTrials, 1));
    shuffledCombos = baseTrials(perm1, :);
    learningTrials = {};
    for bNumber = 1:size(shuffledCombos, 1)
        learningTrials = [learningTrials; repmat(shuffledCombos(bNumber,:), minRepeats, 1)];
    end

    testTrials = repmat(baseTrials, testRepeats, 1);
    permTest = randperm(size(testTrials, 1));
    testTrialList = testTrials(permTest, :);

    foodNames = {'Lasagna', 'MinestroneSoup', 'Fondue', 'FishChips', 'GrilledVegetables', 'Geschnetzeltes'};
    permFoodOrder = randperm(6);
    shuffledFoodNames = foodNames(permFoodOrder);

    trialData = {};
    trialNum = 0;
    conditionResults = zeros(6, 2);

    %% association task learning phase
    trialIndex = 1;
    while trialIndex <= size(learningTrials, 1)
        retry = true;
        t_age = learningTrials{trialIndex, 1};
        t_time = learningTrials{trialIndex, 2};
        t_correct = learningTrials{trialIndex, 3};
        t_code = learningTrials{trialIndex, 4};
        t_trialN = trialIndex;

        while retry
            checkForEscape();
            trialNum = trialNum + 1;
            [choice, rt] = presentTrial(win, instrDir, t_age, t_time, shuffledFoodNames, xCenter, yCenter);
            accuracy = strcmp(choice, t_correct);
            if accuracy
                DrawFormattedText(win, 'Correct!', 'center', 'center', [0 128 0]);
                Screen('Flip', win); WaitSecs(0.5); % feedback duration
                retry = false;
                trialIndex = trialIndex + 1;
            else
                DrawFormattedText(win, 'Incorrect, try again.', 'center', 'center', [255 0 0]);
                Screen('Flip', win); WaitSecs(0.5); % feedback duration
            end
            conditionResults(t_code, 2) = conditionResults(t_code, 2) + 1;
            if accuracy
                conditionResults(t_code, 1) = conditionResults(t_code, 1) + 1;
            end
            trialRow = {day, trialNum, subid, t_trialN, t_code, t_time, t_age, t_correct, choice, accuracy, round(rt*1000), NaN};
            trialData(end+1,:) = trialRow;
        end
    end

    %% testing phase of association task
    testTrialResults = nan(size(testTrialList, 1), 1);
    testTrialIndex = 1;

    % testing trials loop
    while true
        t_age = testTrialList{testTrialIndex, 1};
        t_time = testTrialList{testTrialIndex, 2};
        t_correct = testTrialList{testTrialIndex, 3};
        t_code = testTrialList{testTrialIndex, 4};
        t_trialN = testTrialIndex;

        retry = true;
        firstTryLogged = false;  % Mark if it's the first attempt

        while retry
            checkForEscape();
            trialNum = trialNum + 1;
            [choice, rt] = presentTrial(win, instrDir, t_age, t_time, shuffledFoodNames, xCenter, yCenter);
            accuracy = strcmp(choice, t_correct);

            % Log result on first attempt
            if ~firstTryLogged
                testTrialResults(testTrialIndex) = accuracy;
                firstTryLogged = true;
            end

            % Feedback and progression logic
            if accuracy
                DrawFormattedText(win, 'Correct!', 'center', 'center', [0 128 0]);
                Screen('Flip', win); WaitSecs(0.5); % duration of feedback
                retry = false;
                testTrialIndex = testTrialIndex + 1;
            else
                DrawFormattedText(win, 'Incorrect, try again.', 'center', 'center', [255 0 0]);
                Screen('Flip', win); WaitSecs(0.5); % duration of feedback
                retry = true;
            end

            % Update conditionResults
            conditionResults(t_code, 2) = conditionResults(t_code, 2) + 1;
            if accuracy
                conditionResults(t_code, 1) = conditionResults(t_code, 1) + 1;
            end

            % save data
            cumulativeCorrectRate = mean(testTrialResults(~isnan(testTrialResults)));
            trialRow = {day, trialNum, subid, t_trialN, t_code, t_time, t_age, t_correct, choice, accuracy, round(rt*1000), cumulativeCorrectRate};
            trialData(end+1,:) = trialRow;

            % export data for each trials
            resultTable = cell2table(trialData, 'VariableNames', {'day', 'trialNumber','subid','trialN','trialCode','time','age','correctfood','chosen','accuracy','reactionTime','cumulativeAccRate'});
            resultCsv = fullfile(resultsDir, ['sub_' subid '_data.csv']);
            writetable(resultTable, resultCsv);

            conditionTable = array2table(conditionResults, 'VariableNames', {'Successes','Attempts'});
            conditionCsv = fullfile(resultsDir, ['sub_' subid '_condition_results.csv']);
            writetable(conditionTable, conditionCsv);
        end

        % === End condition check ===
        if testTrialIndex > size(testTrialList, 1)
            if sum(testTrialResults) > consecutiveCorrectRequired
                break;  % End
            else
                % Regenerate a new block of 12 test trials
                permTest = randperm(size(testTrials, 1));
                testTrialList = testTrials(permTest, :);
                testTrialResults = nan(size(testTrialList, 1), 1);
                testTrialIndex = 1;
            end
        end
    end

    %% Navigation task Instruction
    instrDir = fullfile(pwd, 'stimuli');
    instrFiles = dir(fullfile(instrDir, 'navigation_ins*.tiff'));
    instrPages = sort({instrFiles.name});
    for page = 1:length(instrPages)
        instrImg = imread(fullfile(instrDir, instrPages{page}));
        tex = Screen('MakeTexture', win, instrImg);
        Screen('DrawTexture', win, tex);
        Screen('Flip', win);
        WaitSecs(0.5);
        while true
            checkForEscape();
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown && keyCode(KbName('RightArrow'))
                break;
            end
        end
        WaitSecs(0.2);
        Screen('Close', tex);
    end
    Screen('FillRect', win, 255);
    DrawFormattedText(win, 'Press any key to start learning phase.', 'center', 'center', [0 0 0]);
    Screen('Flip', win);
    WaitSecs(0.2);
    KbWait;

    %% Navigation task parameters
    % === Mapping between food and correct time/age ===
    perm1 = randperm(size(baseTrials, 1));
    shuffledCombos = baseTrials(perm1, :);
    learningTrials = {};
    minRepeats = 2;  % Each combination repeated twice
    for bNumber = 1:size(shuffledCombos, 1)
        learningTrials = [learningTrials; repmat(shuffledCombos(bNumber,:), minRepeats, 1)];
    end

    navTrialData = {}; % Data recording

    %% Learning phase
    for trialIndex = 1:size(learningTrials, 1)
        % retry = true;
        t_age = learningTrials{trialIndex, 1};
        t_time = learningTrials{trialIndex, 2};
        t_food = learningTrials{trialIndex, 3};
        t_code = learningTrials{trialIndex, 4};

        % while retry
        [rt, timeClickCount, ageClickCount] = presentNavigationTrial(win, instrDir, t_age, t_time, t_food, xCenter, yCenter);

        % Show Next Round
        if trialIndex < size(learningTrials, 1)
            DrawFormattedText(win, 'next round...', 'center', 'center', [1 1 1]);
            Screen('Flip', win);
            WaitSecs(0.5); % duration for next round
            HideCursor;
        end

        % Save result of each trial
        navTrialRow = {trialIndex, 'learning', subid, t_code, t_food, t_time, t_age, round(rt*1000), timeClickCount, ageClickCount};
        navTrialData(end+1,:) = navTrialRow;

        navResultTable = cell2table(navTrialData, 'VariableNames', {'trialNumber', 'trialType','subid','trialCode','food','correctTime','correctAge','reactionTime','timeClickCount','ageClickCount'});
        navResultCsv = fullfile(resultsDir, ['sub_' subid '_navigation_data.csv']);
        writetable(navResultTable, navResultCsv);
    end

    %% Testing phase
    instrFiles = dir(fullfile(instrDir, 'navigation_formal_ins*.tiff'));
    instrPages = sort({instrFiles.name});
    for page = 1:length(instrPages)
        instrImg = imread(fullfile(instrDir, instrPages{page}));
        tex = Screen('MakeTexture', win, instrImg);
        Screen('DrawTexture', win, tex);
        Screen('Flip', win);
        WaitSecs(0.5);
        while true
            checkForEscape();
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown && keyCode(KbName('RightArrow'))
                break;
            end
        end
        WaitSecs(0.2);
        Screen('Close', tex);
    end
    Screen('FillRect', win, 255);
    DrawFormattedText(win, 'Press any key to start testing phase.', 'center', 'center', [0 0 0]);
    Screen('Flip', win);
    WaitSecs(0.2);
    KbWait;

    % Main testing trials
    repeatNum = 2;
    trialIdx = repmat(1:size(baseTrials, 1), 1, repeatNum); % Repeat each twice
    perm2 = trialIdx(randperm(length(trialIdx)));  % Shuffle order
    TestTrials = baseTrials(perm2,:);

    testloop = true;
    while testloop
        ClickCount = 0;
        for trialIndex = 1:size(TestTrials, 1)
            % retry = true;
            t_age = TestTrials{trialIndex, 1};
            t_time = TestTrials{trialIndex, 2};
            t_food = TestTrials{trialIndex, 3};
            t_code = TestTrials{trialIndex, 4};
            [rt, timeClickCount, ageClickCount] = presentNavigationTrial(win, instrDir, t_age, t_time, t_food, xCenter, yCenter);

            % Show Next Round
            if trialIndex < size(TestTrials, 1)
                DrawFormattedText(win, 'next round...', 'center', 'center', [1 1 1]);
                Screen('Flip', win);
                WaitSecs(0.5); % duration for next round
                HideCursor;
            end
            ClickCount = ClickCount + timeClickCount + ageClickCount;

            % Save result for each trial
            navTrialRow = {trialIndex, 'testing', subid, t_code, t_food, t_time, t_age, round(rt*1000), timeClickCount, ageClickCount};
            navTrialData(end+1,:) = navTrialRow;

            navResultTable = cell2table(navTrialData, 'VariableNames', {'trialNumber', 'trialType','subid','trialCode','food','correctTime','correctAge','reactionTime','timeClickCount','ageClickCount'});
            navResultCsv = fullfile(resultsDir, ['sub_' subid '_navigation_data.csv']);
            writetable(navResultTable, navResultCsv);
        end

        % Check if all recent 12 trials were fully clicked correctly
        if ClickCount < repeatNum*length(trialIdx) + 2 % Allowance threshold
            testloop = false; % If too few clicks, task ends
        else
            testloop = true;
        end
    end

    %% end task window flip
    Screen('FillRect', win, 255);
    DrawFormattedText(win, 'Task complete! Press any key to exit.', 'center', 'center', [0 0 0]);
    Screen('Flip', win);
    WaitSecs(0.2);
    KbWait;
    sca; ListenChar(0);

catch ME
    sca; ListenChar(0);
    rethrow(ME);
end
