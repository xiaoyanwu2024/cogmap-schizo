% runSpatialDragExperiment.m
% Author: OpenAI ChatGPT (modified)
% Description: PTB-based drag-drop image experiment in 7x7 space with snapping to nearest grid center and validated result scoring

try
    %% Setup
    clear; clc;
    KbName('UnifyKeyNames');

    % Input participant info
    subid = inputdlg('Enter participant ID (e.g., 001):', 'Subject Info');
    subid = subid{1};

    groupChoice = questdlg('Which group is?', 'Group Selection', 'Image', 'Language', 'Image');
    if isempty(groupChoice), error('You must choose Image or Language.'); end
    group = lower(strrep(groupChoice, ' ', ''));
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
    timeList = {'dawn', 'morning', 'noon', 'afternoon', 'sunset', 'evening', 'night'};

    %% Initialize PTB
    Screen('Preference', 'SkipSyncTests', 1);
    screens = Screen('Screens');
    screenNumber = min(screens);
    [win, winRect] = Screen('OpenWindow', screenNumber, [255 255 255]);
    [cx, cy] = RectCenter(winRect);
    SetMouse(cx, cy, win);
    ShowCursor;
    Screen('TextSize', win, 24);

    % Grid layout
    [screenX, screenY] = Screen('WindowSize', win);
    gridSize = 7;
    gridW = screenX * 0.5;
    gridH = screenY * 0.5;
    gridX0 = cx - gridW/2;
    gridY0 = cy - gridH/2;
    cellW = gridW / gridSize;
    cellH = gridH / gridSize;

    %% Precompute grid centers (reversed row index for y axis)
    gridCenters = zeros(7,7,2);
    for i = 1:7
        for j = 1:7
            gridCenters(i,j,1) = gridX0 + (j-1)*cellW + cellW/2;
            gridCenters(i,j,2) = gridY0 + (7-i)*cellH + cellH/2;
        end
    end

    %% Load axis labels
    stimDir = 'stimuli';
    axisImgs = struct();
    axisTex = struct();
    for i = 1:7
        axisImgs.age{i} = imread(fullfile(stimDir, group, [ageList{i}, '.tiff']));
        axisImgs.time{i} = imread(fullfile(stimDir, group, [timeList{i}, '.tiff']));
        axisTex.age{i} = Screen('MakeTexture', win, axisImgs.age{i});
        axisTex.time{i} = Screen('MakeTexture', win, axisImgs.time{i});
    end

    %% Load participant answer mapping file
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

    %% Display images at top (wider spacing)
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
                minDist = inf; minPos = [NaN, NaN];
                for row = 1:7
                    for col = 1:7
                        gx = gridCenters(row,col,1);
                        gy = gridCenters(row,col,2);
                        d = sqrt((centerX - gx)^2 + (centerY - gy)^2);
                        if d < minDist
                            minDist = d;
                            minPos = [col, row];
                        end
                    end
                end
                if all(minPos >= 1 & minPos <= 7)
                    x0 = gridCenters(minPos(2), minPos(1), 1) - imgSize/2;
                    y0 = gridCenters(minPos(2), minPos(1), 2) - imgSize/2;
                    dragRects(selected,:) = [x0 y0 x0+imgSize y0+imgSize];
                    currPos(order(selected),:) = minPos;
                end
                rtLog = [rtLog; {selected, t0, t1}];
            end
        end

        Screen('FillRect', win, [255 255 255]);
        for i = 0:gridSize
            xg = gridX0 + i*cellW;
            yg = gridY0 + i*cellH;
            Screen('DrawLine', win, [0 0 0], gridX0, yg, gridX0+gridW, yg, 2);
            Screen('DrawLine', win, [0 0 0], xg, gridY0, xg, gridY0+gridH, 2);
        end
        for i = 1:7
            tx = gridX0 + (i-1)*cellW + cellW/2 - imgSize/2;
            ty = gridY0 + gridH + 10;
            Screen('DrawTexture', win, axisTex.time{i}, [], [tx, ty, tx+imgSize, ty+imgSize]);
            tx = gridX0 - imgSize - 10;
            ty = gridY0 + (7-i)*cellH + cellH/2 - imgSize/2;
            Screen('DrawTexture', win, axisTex.age{i}, [], [tx, ty, tx+imgSize, ty+imgSize]);
        end
        for i = 1:6
            Screen('DrawTexture', win, imgTex(i), [], dragRects(i,:));
        end
        DrawFormattedText(win, 'Press ENTER when done.', 'center', gridY0 + gridH + imgSize + 60, [0 0 0]);
        Screen('Flip', win);

        [~, ~, keyCode] = KbCheck;
        if any([keyCode(KbName('return')), keyCode(KbName('ENTER'))])
            if any(any(isnan(currPos)))
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

    %% Score the placements
    %% Score the placements (完整信息)
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
            actualTimeLabel = timeList{actual(1)};
            actualAgeLabel = ageList{actual(2)};
        end

        output(i,:) = {subid, group, correctID, trialNames{i}, ...
            correctRow(1), timeList{correctRow(1)}, ...
            correctRow(2), ageList{correctRow(2)}, ...
            actualTime, actualTimeLabel, ...
            actualAge, actualAgeLabel, dist};
    end

    % Save as table
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

    % Draw correct placements with full background and save
    Screen('FillRect', win, [255 255 255]);

    % Draw grid lines
    for i = 0:gridSize
        xg = gridX0 + i*cellW;
        yg = gridY0 + i*cellH;
        Screen('DrawLine', win, [0 0 0], gridX0, yg, gridX0+gridW, yg, 2);
        Screen('DrawLine', win, [0 0 0], xg, gridY0, xg, gridY0+gridH, 2);
    end

    % Draw axis labels
    for i = 1:7
        tx = gridX0 + (i-1)*cellW + cellW/2 - imgSize/2;
        ty = gridY0 + gridH + 10;
        Screen('DrawTexture', win, axisTex.time{i}, [], [tx, ty, tx+imgSize, ty+imgSize]);
        tx = gridX0 - imgSize - 10;
        ty = gridY0 + (7-i)*cellH + cellH/2 - imgSize/2;
        Screen('DrawTexture', win, axisTex.age{i}, [], [tx, ty, tx+imgSize, ty+imgSize]);
    end

    % Draw correct food placements
    for i = 1:6
        col = itemLocations(i,2);
        row = itemLocations(i,3);
        x0 = gridCenters(row, col, 1) - imgSize/2;
        y0 = gridCenters(row, col, 2) - imgSize/2;
        Screen('DrawTexture', win, imgTex(order==i), [], [x0, y0, x0+imgSize, y0+imgSize]);
    end

    % Flip and capture
    Screen('Flip', win);
    WaitSecs(1);
    correctImg = Screen('GetImage', win);
    imwrite(correctImg, fullfile(resultFolder, [subid, '_', timestamp, '_correct.tiff']));


    %% Cleanup
    Screen('CloseAll'); ListenChar(0); ShowCursor;
    disp('Experiment complete.');
catch ME
    Screen('CloseAll'); ListenChar(0); ShowCursor;
    rethrow(ME);
end
