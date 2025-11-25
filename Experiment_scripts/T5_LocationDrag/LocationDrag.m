function LocationDrag(subid, group)
try
    %% Setup
    % clear; clc;
    addpath(fullfile(pwd, 'functions'));
    KbName('UnifyKeyNames');
    ListenChar(1);

    %% Define static mapping
    itemLocations = [
        1 4 7;
        2 1 5;
        3 7 6;
        4 5 3;
        5 2 1;
        6 7 2];

    ageList = {'toddler', 'child', 'teenager', 'adult', 'midAge', 'elderly', 'old'};
    timeList = {'dawn', 'morning', 'noon', 'afternoon', 'evening', 'nightfall', 'night'};

    %% Initialize PTB
    Screen('Preference', 'SkipSyncTests', 1);
    [win, winRect] = Screen('OpenWindow', max(Screen('Screens')), [217 217 217]);
    [cx, cy] = RectCenter(winRect);
    SetMouse(cx, cy, win);
    ShowCursor;
    Screen('TextSize', win, 24);

    [screenX, screenY] = Screen('WindowSize', win);
    gridSize = 7;
    gridW = screenX * 0.5;
    gridH = screenY * 0.5;
    gridX0 = cx - gridW/2;
    gridY0 = cy - gridH/2;
    cellW = gridW / gridSize;
    cellH = gridH / gridSize;

    %% Precompute grid centers
    gridCenters = zeros(7,7,2);
    for i = 1:7
        for j = 1:7
            gridCenters(i,j,1) = gridX0 + (j-1)*cellW + cellW/2;
            gridCenters(i,j,2) = gridY0 + (7-i)*cellH + cellH/2;
        end
    end

    %% Load axis labels
    stimDir = 'stimuli';
    axisImgs = struct(); axisTex = struct();
    for i = [1 7]
        axisImgs.age{i} = imread(fullfile(stimDir, group, [ageList{i}, '.tiff']));
        axisImgs.time{i} = imread(fullfile(stimDir, group, [timeList{i}, '.tiff']));
        axisTex.age{i} = Screen('MakeTexture', win, axisImgs.age{i});
        axisTex.time{i} = Screen('MakeTexture', win, axisImgs.time{i});
    end

    %% Load participant trial info
    basePath = fullfile('..', 'T3_associationLearn', group, 'baseTrials');
    files = dir(fullfile(basePath, ['sub' subid '*.mat']));
    assert(~isempty(files), 'No matching baseTrials file found.');
    load(fullfile(basePath, files(1).name), 'baseTrials');
    trialMatrix = baseTrials;

    %% Extract images
    trialImgs = {}; imgTex = zeros(1,6);
    trialNames = cell(1,6); trialIDs = zeros(1,6);
    for i = 1:6
        trialNames{i} = trialMatrix{i,3};
        trialIDs(i) = trialMatrix{i,4};
        trialImgs{i} = imread(fullfile(stimDir, group, [trialNames{i}, '.tiff']));
    end

    %% Show instruction slides
    imgPath = fullfile(pwd, 'stimuli');
    instrFiles = dir(fullfile(imgPath, 'ins*.tiff'));
    instrPages = sort({instrFiles.name});

    page = 1;
    while page <= length(instrPages)
        instrImg = imread(fullfile(imgPath, instrPages{page}));
        tex = DrawImageNoStretch(win, instrImg);
        Screen('Flip', win);
        WaitSecs(0.5); % Debounce delay

        % wait for response
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

    %% Display images at top
    rng('shuffle');
    order = randperm(6);
    dragRects = zeros(6,4);
    imgSize = round(min([cellW, cellH]) * 0.9);
    dragX0 = gridX0;
    dragY = gridY0 - imgSize - 80;
    for i = 1:6
        x = dragX0 + (i-1)*(imgSize + 40);
        y = dragY;
        dragRects(i,:) = [x, y, x+imgSize, y+imgSize];
        imgTex(i) = Screen('MakeTexture', win, trialImgs{order(i)});
    end
    currPos = nan(6,2); rtLog = [];

    %% Drag interaction loop
    dragging = false; selected = 0;
    while 1
        [x, y, buttons] = GetMouse(win);
        if buttons(1)
            if ~dragging
                for i = 1:6
                    if IsInRect(x, y, dragRects(i,:))
                        dragging = true; selected = i;
                        dragOffset = [x, y] - dragRects(i,1:2);
                        t0 = GetSecs; break;
                    end
                end
            else
                newRect = [x - dragOffset(1), y - dragOffset(2), ...
                    x - dragOffset(1) + imgSize, y - dragOffset(2) + imgSize];
                dragRects(selected,:) = newRect;
            end
        else
            if dragging
                t1 = GetSecs; dragging = false;
                centerX = dragRects(selected,1) + imgSize/2;
                centerY = dragRects(selected,2) + imgSize/2;
                relativeX = (centerX - gridX0) / cellW + 1;
                relativeY = 7 - ((centerY - gridY0) / cellH);
                currPos(order(selected),:) = [relativeX, relativeY];
                rtLog = [rtLog; {selected, t0, t1}];
            end
        end

        Screen('FillRect', win, [255 255 255]);
        Screen('FrameRect', win, [0 0 0], [gridX0 gridY0 gridX0+gridW gridY0+gridH], 3);

        % Axis endpoints only
        for i = [1 7]
            tx = gridX0 + (i-1)*cellW + cellW/2 - imgSize/2;
            ty = gridY0 + gridH + 10;
            Screen('DrawTexture', win, axisTex.time{i}, [], [tx, ty, tx+imgSize, ty+imgSize]);

            tx = gridX0 - imgSize - 10;
            ty = gridY0 + (7-i)*cellH + cellH/2 - imgSize/2;
            Screen('DrawTexture', win, axisTex.age{i}, [], [tx, ty, tx+imgSize, ty+imgSize]);
        end

        Screen('TextSize', win, 18);

        % Horizontal Time (centered based on the left and right images)
        txL = gridX0 + cellW/2;
        txR = gridX0 + gridW - cellW/2;
        DrawFormattedText(win, '< Time >', 'center', gridY0 + gridH + imgSize/2+10, [0 0 0]);

        % Vertical Age (aligned based on the top and bottom images)
        tyT = gridY0 + cellH/2;
        tyB = gridY0 + gridH - cellH/2;
        Screen('TextSize', win, 22);
        DrawFormattedText(win, '^', gridX0 - imgSize/2-5, gridY0 + gridH/2-30, [0 0 0]);
        Screen('TextSize', win, 18);
        DrawFormattedText(win, 'Age', gridX0 - imgSize/2-15, gridY0 + gridH/2 - 10, [0 0 0]);
        DrawFormattedText(win, 'v', gridX0 - imgSize/2-5, gridY0 + gridH/2 + 15, [0 0 0]);

        for i = 1:6
            Screen('DrawTexture', win, imgTex(i), [], dragRects(i,:));
        end
        DrawFormattedText(win, 'Press ENTER when done.', 'center', gridY0 + gridH + imgSize + 60, [0 0 0]);
        Screen('Flip', win);

        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('Return'))
            allInside = all(arrayfun(@(i) ...
                all(dragRects(i,[1 2]) >= [gridX0, gridY0]) && ...
                all(dragRects(i,[3 4]) <= [gridX0 + gridW, gridY0 + gridH]), 1:6));
            if any(any(isnan(currPos))) || ~allInside
                DrawFormattedText(win, 'Please place all items on the grid before continuing.', 'center', 'center', [255 0 0]);
                Screen('Flip', win);
                KbWait;
                continue;
            else
                break;
            end
        end

        WaitSecs(0.01);
    end

    %% Score placements
    output = {};
    for i = 1:6
        actual = currPos(i,:);
        correctID = trialIDs(i);
        correctRow = itemLocations(itemLocations(:,1)==correctID, 2:3);

        if any(isnan(actual))
            dist = NaN;
            actualTime = NaN;
            actualAge = NaN;
            actualTimeLabel = '';
            actualAgeLabel = '';
        else
            dx = actual(1) - correctRow(1);
            dy = actual(2) - correctRow(2);
            dist = sqrt(dx^2 + dy^2);
            actualTime = actual(1);
            actualAge = actual(2);
            actualTimeLabel = timeList{round(min(max(1, actual(1)), 7))};
            actualAgeLabel = ageList{round(min(max(1, actual(2)), 7))};
        end

        output(i,:) = {subid, group, correctID, trialNames{i}, ...
            correctRow(1), timeList{correctRow(1)}, ...
            correctRow(2), ageList{correctRow(2)}, ...
            actualTime, actualTimeLabel, ...
            actualAge, actualAgeLabel, dist};
    end

    resultFolder = fullfile('results', group);
    if ~exist(resultFolder, 'dir'), mkdir(resultFolder); end
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    outputTable = cell2table(output, ...
        'VariableNames', {'SubID', 'Group', 'FoodID', 'FoodName', ...
        'CorrectTimeNum', 'CorrectTime', 'CorrectAgeNum', 'CorrectAge', ...
        'PlacedTimeNum', 'PlacedTime', 'PlacedAgeNum', 'PlacedAge', 'Distance'});
    writetable(outputTable, fullfile(resultFolder, [subid, '_', timestamp, '.csv']));

    imageArray = Screen('GetImage', win);
    imwrite(imageArray, fullfile(resultFolder, [subid, '_', timestamp, '_final.tiff']));

    % Draw correct placements
    Screen('FillRect', win, [255 255 255]);
    Screen('FrameRect', win, [0 0 0], [gridX0 gridY0 gridX0+gridW gridY0+gridH], 3);
    for i = [1 7]
        tx = gridX0 + (i-1)*cellW + cellW/2 - imgSize/2;
        ty = gridY0 + gridH + 10;
        Screen('DrawTexture', win, axisTex.time{i}, [], [tx, ty, tx+imgSize, ty+imgSize]);

        tx = gridX0 - imgSize - 10;
        ty = gridY0 + (7-i)*cellH + cellH/2 - imgSize/2;
        Screen('DrawTexture', win, axisTex.age{i}, [], [tx, ty, tx+imgSize, ty+imgSize]);
    end
    for i = 1:6
        col = itemLocations(i,2);
        row = itemLocations(i,3);
        x0 = gridCenters(row, col, 1) - imgSize/2;
        y0 = gridCenters(row, col, 2) - imgSize/2;
        Screen('DrawTexture', win, imgTex(order==i), [], [x0, y0, x0+imgSize, y0+imgSize]);
    end
    Screen('Flip', win);
    correctImg = Screen('GetImage', win);
    imwrite(correctImg, fullfile(resultFolder, [subid, '_', timestamp, '_correct.tiff']));

    %% Cleanup
    Screen('CloseAll'); ListenChar(0); ShowCursor;
    disp('Experiment complete.');
catch ME
    Screen('CloseAll'); ListenChar(0); ShowCursor;
    rethrow(ME);
end
