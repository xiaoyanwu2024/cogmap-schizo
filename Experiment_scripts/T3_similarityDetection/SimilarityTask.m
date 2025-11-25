function SimilarityTask(subid, group)
try
    %% Initialization
    addpath(fullfile(pwd, 'functions'));
    Screen('Preference', 'SkipSyncTests', 1);
    KbName('UnifyKeyNames');
    ListenChar(2);

    % Set up result directory
    resultFolder = fullfile(pwd, 'results',group, ['sub_' subid]);
    if ~exist(resultFolder, 'dir')
        mkdir(resultFolder);
    end

    % Set up screen
    screenNumber = max(Screen('Screens'));
    [win, winRect] = Screen('OpenWindow', screenNumber, 255);
    [xCenter, yCenter] = RectCenter(winRect);
    Screen('TextSize', win, 28);
    HideCursor;

    % Prepare result file name
    dateStr = datestr(now, 'yyyy_mm_dd');
    filename = fullfile(resultFolder, sprintf('sub_%s_%s__similarity_task.mat', subid, dateStr));

    % Load base trials
    basePath = fullfile('..', 'T3_associationLearn', group, 'baseTrials');
    files = dir(fullfile(basePath, ['sub' subid '*.mat']));
    assert(~isempty(files), 'No matching baseTrials file found.');
    load(fullfile(basePath, files(1).name), 'baseTrials');

    %% Instruction pages
    instrDir = fullfile(pwd, 'stimuli');
    instrFiles = dir(fullfile(instrDir, 'ins*.tiff'));
    instrPages = sort({instrFiles.name});

    page = 1;
    while page <= length(instrPages)
        instrImg = imread(fullfile(instrDir, instrPages{page}));
        tex = DrawImageNoStretch(win, instrImg);
        Screen('Flip', win);
        WaitSecs(0.5);

        while true
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
        WaitSecs(0.2);
        Screen('Close', tex);
    end

    % Begin prompt
    Screen('FillRect', win, 255);
    DrawFormattedText(win, 'Press any key to start.', 'center', 'center', [0 0 0]);
    Screen('Flip', win);
    WaitSecs(0.2);
    KbWait;

    %% Generate pairwise similarity trials
    load('object_location.mat');
    imageNames = baseTrials(:,3);
    imageLocationX = object_location.("x(time)");
    imageLocationY = object_location.("y(age)");

    allCombos = {};
    for i = 1:length(imageNames)
        for j = 1:length(imageNames)
            if i ~= j
                dx = imageLocationX(i) - imageLocationX(j);
                dy = imageLocationY(i) - imageLocationY(j);
                dist = sqrt(dx^2 + dy^2);
                allCombos{end+1, 1} = {imageNames{i}, imageNames{j}};
                allCombos{end, 2} = dist;
            end
        end
    end

    % Repeat each pair twice and shuffle
    repeatTimes = 2;
    trialList = repmat(allCombos, repeatTimes, 1);
    trialList = trialList(randperm(size(trialList,1)), :);

    %% Trial loop
    results = struct;
    expStart = GetSecs();

    for t = 1:length(trialList)
        % Scheduled break halfway through
        if t == 31
            DrawFormattedText(win, 'Take a short break. Press any key to continue when you are ready.', 'center', 'center', [0 0 0]);
            Screen('Flip', win);
            WaitSecs(5);
            KbStrokeWait;
        end

        % Load images
        img1 = imread(fullfile('stimuli', [trialList{t}{1} '.tiff']));
        img2 = imread(fullfile('stimuli', [trialList{t}{2} '.tiff']));
        tex1 = Screen('MakeTexture', win, img1);
        tex2 = Screen('MakeTexture', win, img2);
        dist = trialList{t,2};

        % Set image and slider positions
        offset = 200;
        imgRect = [0 0 300 300];
        leftPos = CenterRectOnPoint(imgRect, xCenter - offset, yCenter - 200);
        rightPos = CenterRectOnPoint(imgRect, xCenter + offset, yCenter - 200);

        sliderMin = xCenter - 300;
        sliderMax = xCenter + 300;
        sliderX = round((2*xCenter - 600) + rand() * 1200); % Random initial position
        % sliderX = round(2*xCenter-600 + rand() * ((2*xCenter+600) - (2*xCenter-600)));
        SetMouse(sliderX, 2*yCenter + 400, win);

        clicked = false;
        imgOnset = GetSecs;
        moved = false;
        moveOnset = NaN;

        % Rating interface loop
        while ~clicked
            [x,~,buttons] = GetMouse(win);
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown && keyCode(KbName('ESCAPE'))
                sca; ListenChar(0); error('User exited.');
            end
            x = min(max(x, sliderMin), sliderMax);

            if ~moved && abs(x - sliderX) > 2
                moveOnset = GetSecs;
                moved = true;
            end

            binEdges = linspace(sliderMin, sliderMax, 11);
            [~, rating] = min(abs(x - binEdges));
            rating = rating - 1;
            x = binEdges(rating+1);

            % Draw interface
            Screen('DrawTexture', win, tex1, [], leftPos);
            Screen('DrawTexture', win, tex2, [], rightPos);

            % Slider
            baseLineRect = [sliderMin-5, yCenter+195, sliderMax+5, yCenter+205];
            Screen('FillRect', win, [160 160 160], baseLineRect);
            handleRect = [x-10, yCenter+190, x+10, yCenter+210];
            Screen('FillRect', win, [176 36 24], handleRect);

            % Ticks
            for i = 0:10
                tickX = sliderMin + i * (sliderMax - sliderMin) / 10;
                DrawFormattedText(win, num2str(i), tickX - 5, yCenter + 230, [0 0 0], [], [], [], 1.0, [], []);
            end

            % Labels and instructions
            ratingStr = sprintf('%d', rating);
            bounds = Screen('TextBounds', win, ratingStr);
            textX = x - (bounds(3)-bounds(1))/2;
            textY = yCenter + 160;
            Screen('TextSize', win, 40);
            DrawFormattedText(win, ratingStr, textX, textY, [0 0 0]);
            Screen('TextSize', win, 28);
            DrawFormattedText(win, 'Not at all similar', sliderMin - 220, yCenter + 200, [0 0 0]);
            DrawFormattedText(win, 'Highly similar', sliderMax + 20, yCenter + 200, [0 0 0]);

            if t == 1
                DrawFormattedText(win, 'Move the slider with your mouse. Click the left mouse button to confirm.', 'center', yCenter + 270, [0 0 0]);
            end
            Screen('Flip', win);

            % Confirm rating on mouse click
            if any(buttons)
                while any(buttons)
                    [~,~,buttons] = GetMouse(win);
                end
                clicked = true;

                % Confirmation screen
                Screen('DrawTexture', win, tex1, [], leftPos);
                Screen('DrawTexture', win, tex2, [], rightPos);
                Screen('FillRect', win, [160 160 160], baseLineRect);
                Screen('FillRect', win, [176 36 24], handleRect);
                Screen('TextSize', win, 40);
                DrawFormattedText(win, ratingStr, textX, textY, [255 0 0]);
                Screen('TextSize', win, 28);
                for i = 0:10
                    tickX = sliderMin + i * (sliderMax - sliderMin) / 10;
                    DrawFormattedText(win, num2str(i), tickX - 5, yCenter + 230, [0 0 0], [], [], [], 1.0, [], []);
                end
                DrawFormattedText(win, 'Not at all similar', sliderMin - 220, yCenter + 200, [0 0 0]);
                DrawFormattedText(win, 'Highly similar', sliderMax + 20, yCenter + 200, [0 0 0]);
                if t == 1
                    DrawFormattedText(win, 'Move the slider with your mouse. Click the left mouse button to confirm.', 'center', yCenter + 270, [0 0 0]);
                end
                Screen('Flip', win);
                WaitSecs(0.5);
            end
        end

        % Record results
        rt = GetSecs - imgOnset;
        results(t).subid = subid;
        results(t).trial = t;
        results(t).img1 = trialList{t}{1};
        results(t).img2 = trialList{t}{2};
        results(t).distance = dist;
        results(t).similarity = rating;
        results(t).RT = rt;
        results(t).imgOnset = imgOnset - expStart;
        results(t).moveOnset = moveOnset - expStart;
        save(filename, 'results');

        % Inter-trial screen
        Screen('FillRect', win, [217 217 217]);
        DrawFormattedText(win, 'next round...', 'center', 'center', [0 0 0]);
        Screen('Flip', win);
        WaitSecs(0.5);
    end

    %% Completion screen
    DrawFormattedText(win, 'Task complete! Press any key to exit.', 'center', 'center', [0 0 0]);
    Screen('Flip', win);
    ListenChar(0);
    ShowCursor;
    KbWait;
    sca;

catch ME
    sca; ListenChar(0); ShowCursor;
    rethrow(ME);
end
