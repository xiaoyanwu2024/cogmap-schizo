function choiceTask(subid, group)
try
    %% Initialization
    % clear; clc;
    addpath(fullfile(pwd, 'functions'));
    KbName('UnifyKeyNames');
    Screen('Preference', 'SkipSyncTests', 1);

    [win, rect] = Screen('OpenWindow', max(Screen('Screens')), [217 217 217]);
    Screen('TextFont', win, 'Arial');
    Screen('TextSize', win, 40);
    HideCursor;

    %% Create result saving path
    resultFolder = fullfile(pwd, 'results', group, ['sub_' subid]);
    if ~exist(resultFolder, 'dir')
        mkdir(resultFolder);
    end

    dateStr = datestr(now, 'yyyy_mm_dd');
    dataFile = fullfile(resultFolder, sprintf('sub_%s_%s_data.mat', subid, dateStr));
    pracFile = fullfile(resultFolder, sprintf('sub_%s_%s_prac.mat', subid, dateStr));

    %% Load data
    load('object_location.mat'); % Location info of each option including x (time) and y (age)
    load('T1T2.mat');
    imgPath = 'stimuli/';

    % Load subject-specific baseTrials
    basePath = fullfile('..', 'T3_associationLearn', group, 'baseTrials');
    files = dir(fullfile(basePath, ['sub' subid '*.mat']));
    assert(~isempty(files), 'No matching baseTrials file found.');
    load(fullfile(basePath, files(1).name), 'baseTrials');

    % Generate formal trialList
    trialList = createDf2(T1,T2, object_location, baseTrials);

    % Set response keys to arrows
    leftKey = KbName('LeftArrow');
    rightKey = KbName('RightArrow');
    escKey = KbName('ESCAPE');

    % Screen center
    [cx, cy] = RectCenter(rect);
    imgSize = 200;
    gap = 200;

    % Instruction screens
    instrDir = fullfile(pwd, 'stimuli');
    instrFiles = dir(fullfile(instrDir, 'ins*.tiff'));
    instrPages = sort({instrFiles.name});

    page = 1;  % Initial page
    while page <= length(instrPages)
        instrImg = imread(fullfile(instrDir, instrPages{page}));
        tex = DrawImageNoStretch(win, instrImg);
        Screen('Flip', win);
        WaitSecs(0.5); % Delay to avoid mispress

        % Wait for user keypress
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
        WaitSecs(0.2); % Debounce delay
        Screen('Close', tex);
    end

    %% Start practice
    practiceIdx = randperm(size(trialList,1), 6);
    pracList = trialList(practiceIdx,:);
    pracResult  = struct;

    Screen('FillRect', win, [217 217 217]);
    DrawFormattedText(win, ...
        'Press any key to start practice.', ...
        'center', 'center', [0 0 0]);
    Screen('Flip', win);
    WaitSecs(0.2);
    KbWait;

    pracStart = GetSecs;
    for t = 1:size(pracList,1)
        pracResult(t).subid = subid;
        pracResult(t).trial = t;
        pracResult(t).option1 = pracList.option1(t);
        pracResult(t).option2 = pracList.option2(t);
        pracResult(t).value1 = pracList.value1(t);
        pracResult(t).value2 = pracList.value2(t);
        pracResult(t).op1_x = pracList.opt1_x(t);
        pracResult(t).op1_y = pracList.opt1_y(t);
        pracResult(t).op2_x = pracList.opt2_x(t);
        pracResult(t).op2_y = pracList.opt2_y(t);

        % Fixation cross
        Screen('TextFont', win, 'Arial');
        Screen('TextSize', win, 60);
        Screen('FillRect', win, [217 217 217]);
        DrawFormattedText(win, '+', 'center', 'center', [0 0 0], [], [], [], 5); % 更大注视点
        fixOnset = Screen('Flip', win); pracResult(t).jitterOnset = fixOnset - pracStart;
        WaitSecs(1 + rand());
        pracResult(t).jitterDuration = GetSecs - fixOnset;

        % Load images
        imgL = imread(fullfile(imgPath, [pracList.opt1_image{t}, '.tiff'])); pracResult(t).imgLeft = pracList.opt1_image{t};
        imgR = imread(fullfile(imgPath, [pracList.opt2_image{t}, '.tiff'])); pracResult(t).imgRight = pracList.opt2_image{t};
        texL = Screen('MakeTexture', win, imgL);
        texR = Screen('MakeTexture', win, imgR);

        % Fixation cross
        Screen('TextFont', win, 'Arial');
        Screen('TextSize', win, 60);
        Screen('FillRect', win, [217 217 217]);
        DrawFormattedText(win, '+', 'center', 'center', [0 0 0], [], [], [], 5);

        % Draw images
        dstRectL = CenterRectOnPoint([0 0 imgSize imgSize], cx - gap, cy);
        dstRectR = CenterRectOnPoint([0 0 imgSize imgSize], cx + gap, cy);
        Screen('DrawTexture', win, texL, [], dstRectL);
        Screen('DrawTexture', win, texR, [], dstRectR);
        imageOnset = Screen('Flip', win); % Response start time
        pracResult(t).imageOnset = imageOnset - pracStart;

        choice = 0;
        while choice == 0
            checkForEscape();
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown
                if keyCode(leftKey)
                    choice = 1;
                elseif keyCode(rightKey)
                    choice = 2;
                elseif keyCode(escKey)
                    sca; return;
                end
            end
        end
        pracResult(t).reactionTime = GetSecs - imageOnset;

        % Record choice data
        if choice == 1
            pracResult(t).chosen = pracResult(t).option1;
            pracResult(t).unchosen = pracResult(t).option2;
            pracResult(t).chosen_value = pracList.value1(t);
            pracResult(t).unchosen_value = pracList.value2(t);
        else
            pracResult(t).chosen = pracResult(t).option2;
            pracResult(t).unchosen = pracResult(t).option1;
            pracResult(t).chosen_value = pracList.value2(t);
            pracResult(t).unchosen_value = pracList.value1(t);
        end

        % Show feedback
        Screen('TextFont', win, 'Arial');
        Screen('TextSize', win, 40);
        Screen('FillRect', win, [217 217 217]);
        rewardText = '$XX';
        DrawFormattedText(win, rewardText, 'center', 'center', [0 100 0]);
        feedbackOnset = Screen('Flip', win);
        pracResult(t).feedbackOnset = feedbackOnset - pracStart;
        WaitSecs(1); % feedback duration
        pracResult(t).feedbackDuration = GetSecs - feedbackOnset;

        % Save practice data immediately
        save(pracFile, 'pracResult');
    end

    % End of practice screen
    DrawFormattedText(win, ...
        ['Practice complete.\nGet ready for the main task.\n\nPress any key to continue.'], ...
        'center', 'center', [0 0 0]);  % Black text
    Screen('Flip', win);
    KbWait;
    WaitSecs(0.2);

    %% Main task: maps loop
    result  = struct;
    expStart = GetSecs;
    for t = 1:size(trialList,1)
        map = trialList.map(t);
        restaurantName = trialList.restaurantName{t};
        % Show map cue at the beginning of each block (every 30 trials)
        if t == 1 || t == 31 || t == 61 || t == 91
            mapText = sprintf('The food items in the following rounds are from restaurant %s.\n\nPress any key when you are ready to start.', restaurantName);
            Screen('FillRect', win, [217 217 217]);
            Screen('FillRect', win, [217 217 217]);
            DrawFormattedText(win, mapText, 'center', 'center', [0 0 0]);
            blockStart = Screen('Flip', win);
            KbStrokeWait;
        end

        result(t).subid = subid;
        result(t).trial = t;
        result(t).map = map;
        result(t).restaurantName = restaurantName;
        result(t).option1 = trialList.option1(t);
        result(t).option2 = trialList.option2(t);
        result(t).value1 = trialList.value1(t);
        result(t).value2 = trialList.value2(t);
        result(t).op1_x = trialList.opt1_x(t);
        result(t).op1_y = trialList.opt1_y(t);
        result(t).op2_x = trialList.opt2_x(t);
        result(t).op2_y = trialList.opt2_y(t);

        % fixation window
        Screen('TextFont', win, 'Arial');
        Screen('TextSize', win, 60);
        Screen('FillRect', win, [217 217 217]);
        DrawFormattedText(win, '+', 'center', 'center', [0 0 0], [], [], [], 5); % 更大注视点
        fixOnset = Screen('Flip', win); result(t).jitterOnset = fixOnset - expStart;
        WaitSecs(1 + rand());
        result(t).jitterDuration = GetSecs - fixOnset;

        % load image
        imgL = imread(fullfile(imgPath, [trialList.opt1_image{t}, '.tiff'])); result(t).imgLeft = trialList.opt1_image{t};
        imgR = imread(fullfile(imgPath, [trialList.opt2_image{t}, '.tiff'])); result(t).imgRight = trialList.opt2_image{t};
        texL = Screen('MakeTexture', win, imgL);
        texR = Screen('MakeTexture', win, imgR);

        % fixation window
        Screen('TextFont', win, 'Arial');
        Screen('TextSize', win, 60);
        Screen('FillRect', win, [217 217 217]);
        DrawFormattedText(win, '+', 'center', 'center', [0 0 0], [], [], [], 5);

        % draw image texture
        dstRectL = CenterRectOnPoint([0 0 imgSize imgSize], cx - gap, cy);
        dstRectR = CenterRectOnPoint([0 0 imgSize imgSize], cx + gap, cy);
        Screen('DrawTexture', win, texL, [], dstRectL);
        Screen('DrawTexture', win, texR, [], dstRectR);
        DrawFormattedText(win, restaurantName, 'center', cy - imgSize, [0 0 0]); % 上方中间文字

        imageOnset = Screen('Flip', win);
        result(t).imageOnset = imageOnset - expStart;

        choice = 0;
        while choice == 0
            checkForEscape();
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown
                if keyCode(leftKey)
                    choice = 1;
                elseif keyCode(rightKey)
                    choice = 2;
                elseif keyCode(escKey)
                    sca; return;
                end
            end
        end
        result(t).reactionTime = GetSecs - imageOnset;

        % recored choice data
        if choice == 1
            result(t).chosen = trialList.option1(t);
            result(t).unchosen = trialList.option2(t);
            result(t).chosen_value = trialList.value1(t);
            result(t).unchosen_value= trialList.value2(t);
        else
            result(t).chosen = trialList.option2(t);
            result(t).unchosen = trialList.option1(t);
            result(t).chosen_value = trialList.value2(t);
            result(t).unchosen_value= trialList.value1(t);
        end
        valC = result(t).chosen_value;

        % show feedback
        Screen('TextFont', win, 'Arial');
        Screen('TextSize', win, 40);
        Screen('FillRect', win, [217 217 217]);
        rewardText = sprintf('$%d', valC);
        DrawFormattedText(win, rewardText, 'center', 'center', [0 100 0]);
        feedbackOnset = Screen('Flip', win);
        result(t).feedbackOnset = feedbackOnset - expStart;
        WaitSecs(1); % feedback duration
        result(t).feedbackDuration = GetSecs - feedbackOnset;

        % save data for each trial
        save(dataFile, 'result');
    end

    %% task end
    DrawFormattedText(win, 'The task is now complete! Press any key to exit.', 'center', 'center', [0 0 0]);
    Screen('Flip', win);
    ListenChar(0);
    ShowCursor;
    KbWait;
    sca;

catch ME
    sca;
    disp('Error occurred. Exiting experiment.');
    rethrow(ME);
end
