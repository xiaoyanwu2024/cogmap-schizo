function orderTaskLanguage(subID, dayLabel)
try
    % clear;clc;
    addpath(fullfile(pwd, 'functions'));
    Screen('Preference', 'SkipSyncTests', 1);
    KbName('UnifyKeyNames');

    ListenChar(2);
    isOdd = mod(str2double(subID), 2) == 1;

    % Create results folder (results/dayX/sub_XXX)
    subFolder = fullfile('results', dayLabel, ['sub_' subID]);
    if ~exist(subFolder, 'dir'); mkdir(subFolder); end

    % Open screen
    screenNumber = max(Screen('Screens'));
    [win, winRect] = Screen('OpenWindow', screenNumber, 255);
    [xCenter, yCenter] = RectCenter(winRect);
    Screen('TextSize', win, 28);

    % Load instruction images (with day label)
    instrDir = fullfile(pwd, 'stimuli');
    generalInsPattern = sprintf('general_ins_%s*.tiff', dayLabel);
    showInstructions(win, generalInsPattern, instrDir);

    % Define task order
    if isOdd
        taskOrder = {"Age", "Time"};
    else
        taskOrder = {"Time", "Age"};
    end

    allResults = [];

    % Age and Time task configuration
    taskConfig.Age.labels = {'toddler', 'child', 'teenager', 'adult', 'midAge', 'elderly', 'old'};
    taskConfig.Age.instructions = 'ins*_age.tiff';
    taskConfig.Age.dragIns = 'drag_ins_age.tiff';
    taskConfig.Age.questionText = {'Which one is OLDER?', 'Which one is YOUNGER?'};
    taskConfig.Age.questionType = {'older', 'younger'};

    taskConfig.Time.labels = {'dawn', 'morning', 'noon', 'afternoon', 'evening', 'nightfall','night'};
    taskConfig.Time.instructions = 'ins*_time.tiff';
    taskConfig.Time.dragIns = 'drag_ins_time.tiff';
    taskConfig.Time.questionText = {'Which one is LATER?', 'Which one is EARLIER?'};
    taskConfig.Time.questionType = {'later', 'earlier'};

    % general instruction
    instrDir = fullfile(pwd, 'stimuli');
    generalInsPattern = sprintf('general_%s_ins*.tiff', dayLabel);
    showInstructions(win, generalInsPattern, instrDir);

    % Perform both tasks (Time and Age) according to subject ID
    for t = 1:2
        taskType = taskOrder{t};
        config = taskConfig.(taskType);

        %% ==== instruction  ==== %%
        instrFiles = dir(fullfile(instrDir, config.instructions));
        instrFiles = sort({instrFiles.name});

        currPage = 1;
        while currPage <= length(instrFiles)
            checkForEscape();
            img = imread(fullfile(instrDir, instrFiles{currPage}));
            DrawImageNoStretch(win, img);
            Screen('Flip', win);

            key = 0;
            while ~key
                checkForEscape();
                [keyIsDown, ~, keyCode] = KbCheck;
                if keyIsDown
                    if keyCode(KbName('RightArrow'))
                        currPage = currPage + 1; key = 1;
                    elseif keyCode(KbName('LeftArrow'))
                        currPage = max(1, currPage - 1); key = 1;
                    end
                    WaitSecs(0.2);
                end
            end
        end

        DrawFormattedText(win, 'Press any key to start the task.', 'center', 'center', [0 0 0]);
        Screen('Flip', win);
        KbWait;

        %% Task judgment
        texMap = containers.Map;
        for i = 1:length(config.labels)
            img = imread(fullfile(instrDir, [config.labels{i} '.tiff']));
            texMap(config.labels{i}) = Screen('MakeTexture', win, img);
        end

        labelOrder = 1:7;
        combs = nchoosek(1:7, 2);
        combCount = size(combs, 1);

        block = 1; correctRate = 0;
        totalTrials = [];

        while correctRate < 0.85
            trialOrder = combs(randperm(combCount), :);
            blockCorrect = 0;
            qIdx = randi(2);
            questionType = config.questionType{qIdx};
            questionText = config.questionText{qIdx};

            for i = 1:21
                idx = mod(i - 1, combCount) + 1;
                pair = trialOrder(idx, :);
                if rand < 0.5
                    left = pair(1); right = pair(2);
                else
                    left = pair(2); right = pair(1);
                end

                if strcmp(questionType, config.questionType{1})
                    if labelOrder(left) > labelOrder(right)
                        correctSide = 'left';
                    else
                        correctSide = 'right';
                    end
                else
                    if labelOrder(left) < labelOrder(right)
                        correctSide = 'left';
                    else
                        correctSide = 'right';
                    end
                end

                rt = NaN; key = ''; attempt = 0;
                startRT = GetSecs;
                while true
                    checkForEscape();
                    attempt = attempt + 1;
                    Screen('FillRect', win, 255);
                    Screen('DrawTexture', win, texMap(config.labels{left}), [], CenterRectOnPoint([0 0 200 200], xCenter - 200, yCenter));
                    Screen('DrawTexture', win, texMap(config.labels{right}), [], CenterRectOnPoint([0 0 200 200], xCenter + 200, yCenter));
                    DrawFormattedText(win, [questionText '\nLeftArrow = Left, RightArrow = Right'], 'center', yCenter + 200, [0 0 0]);
                    Screen('Flip', win);
                    [secs, keyCode] = KbWait;
                    if keyCode(KbName('LeftArrow'))
                        resp = 'left'; key = 'left';
                    elseif keyCode(KbName('RightArrow'))
                        resp = 'right'; key = 'right';
                    else
                        continue;
                    end
                    rt = secs - startRT;
                    if strcmp(resp, correctSide)
                        if attempt == 1
                            blockCorrect = blockCorrect + 1;
                        end
                        DrawFormattedText(win, 'Correct!', 'center', 'center', [0 128 0]);
                        Screen('Flip', win); WaitSecs(0.5); break;
                    else
                        DrawFormattedText(win, 'Incorrect, try again.', 'center', 'center', [255 0 0]);
                        Screen('Flip', win); WaitSecs(0.5);
                    end
                end

                correctSoFar = blockCorrect / i;
                totalTrials = [totalTrials; {block, dayLabel, i, config.labels{left}, config.labels{right}, questionType, correctSide, key, rt, correctSoFar}];
            end
            correctRate = blockCorrect / 21;
            block = block + 1;
        end

        resultsTbl = cell2table(totalTrials, 'VariableNames', {'Block', 'Day','Trial','Left','Right','Question','CorrectSide','Response','ReactionTime','AccRate'});
        resultsTbl.Type = repmat({taskType}, height(resultsTbl), 1);
        allResults = [allResults; resultsTbl];

        % Transition screen
        DrawFormattedText(win, 'Congratulations! You completed this part.\nPress any key to continue to the next.', 'center', 'center', [0 0 0]);
        Screen('Flip', win); KbWait;

        %% Drag-and-drop sorting task
        dragImg = imread(fullfile(instrDir, config.dragIns));
        DrawImageNoStretch(win, dragImg);
        Screen('Flip', win);
        WaitSecs(2);
        KbWait;

        correctOrder = config.labels;
        imageFiles = strcat(correctOrder, '.tiff');
        shuffledIdx = randperm(7);
        shuffledOrder = imageFiles(shuffledIdx);
        [xCenter, yCenter] = RectCenter(winRect);
        ShowCursor;
        targetW = 120; targetH = 120; spacing = 40;
        startY = yCenter - 200;
        totalWidth = 7 * targetW + 6 * spacing;
        startX = xCenter - totalWidth / 2;
        dropY = yCenter + 150;
        dropCenters = zeros(7, 2);
        for i = 1:7
            dropCenters(i, :) = [startX + (i - 1)*(targetW + spacing) + targetW/2, dropY];
        end
        images = struct();
        for i = 1:7
            img = imread(fullfile(instrDir, shuffledOrder{i}));
            tex = Screen('MakeTexture', win, img);
            x = startX + (i - 1)*(targetW + spacing);
            y = startY;
            images(i).name = shuffledOrder{i}(1:end-5);
            images(i).tex = tex;
            images(i).rect = CenterRectOnPoint([0 0 targetW targetH], x + targetW/2, y + targetH/2);
            images(i).placed = false;
        end
        accList = [];
        dragging = false; draggedIdx = -1;
        clickTimes = []; clickCount = 0; t0 = GetSecs;
        taskCompleted = false;
        while true
            Screen('FillRect', win, 255);
            baseRect = [0 0 targetW targetH];
            for i = 1:7
                dstRect = CenterRectOnPoint(baseRect, dropCenters(i, 1), dropCenters(i, 2));
                Screen('FrameRect', win, [200 200 200], dstRect, 3);
            end
            checkForEscape();
            [x, y, buttons] = GetMouse(win);

            if ~dragging && buttons(1)
                for i = 1:7
                    if IsInRect(x, y, images(i).rect)
                        dragging = true;
                        draggedIdx = i;
                        break;
                    end
                end
            end

            if dragging
                images(draggedIdx).rect = CenterRectOnPoint([0 0 targetW targetH], x, y);
                if ~buttons(1)
                    for i = 1:7
                        dst = CenterRectOnPoint([0 0 targetW targetH], dropCenters(i, 1), dropCenters(i, 2));
                        if IsInRect(x, y, dst)
                            images(draggedIdx).rect = dst;
                            images(draggedIdx).placed = true;
                            images(draggedIdx).slot = i;

                            isCorrect = strcmp(images(draggedIdx).name, correctOrder{i});  % Whether placed correctly
                            accList(end+1) = isCorrect; % Record accuracy
                            clickTimes(end+1) = GetSecs - t0; % Record reaction time
                            clickCount = length(clickTimes); % Update click count
                            break;
                        end
                    end
                    dragging = false;
                    draggedIdx = -1;
                end

            end

            for i = 1:7
                Screen('DrawTexture', win, images(i).tex, [], images(i).rect);
            end
            placedFlags = [images.placed];
            currentStatus = 'Not yet completed';
            if all(placedFlags) && all(arrayfun(@(x) isfield(x, 'slot') && x.slot >= 1 && x.slot <= 7, images))
                slotOrder = zeros(1, 7);
                names = strings(1, 7);
                for i = 1:7
                    slotOrder(images(i).slot) = i;
                end
                for i = 1:7
                    if slotOrder(i) > 0 && slotOrder(i) <= length(images)
                        names(i) = images(slotOrder(i)).name;
                    else
                        names(i) = "";
                    end
                end
                if isequal(cellstr(names), correctOrder)
                    currentStatus = 'Completed!';
                    if ~taskCompleted
                        taskCompleted = true;
                        DrawFormattedText(win, currentStatus, 'center', yCenter + 250, [0 128 0]);
                        Screen('Flip', win);
                        WaitSecs(2); break;
                    end
                end
            end
            if ~taskCompleted
                DrawFormattedText(win, currentStatus, 'center', yCenter + 250, [255 0 0]);
            end
            Screen('Flip', win);
        end

        drag.day = dayLabel;
        totalTime = GetSecs - t0;
        drag.type = taskType;
        drag.subID = subID;
        drag.totalTime = totalTime;
        drag.clickCount = clickCount;

        maxClicks = length(clickTimes);
        for k = 1:maxClicks
            drag.(['click' num2str(k)]) = clickTimes(k);
            drag.(['acc' num2str(k)]) = accList(k);
        end

        writetable(struct2table(drag), fullfile(subFolder, sprintf('sub_%s_drag_%s.csv', subID, taskType)));
    end

    writetable(allResults, fullfile(subFolder, ['sub_' subID '_task_all.csv']));
    DrawFormattedText(win, 'Task complete! Press any key to exit.', 'center', 'center', [0 0 0]);
    Screen('Flip', win); KbWait;
    sca; ListenChar(0);

catch ME
    sca; ListenChar(0);
    rethrow(ME);
end
