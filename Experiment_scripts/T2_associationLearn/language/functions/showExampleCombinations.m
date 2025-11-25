function tex = showExampleCombinations(win, instrImg, baseTrials)

% Set path
stimDir = fullfile(pwd, 'stimuli');
tex = DrawImageNoStretch(win, instrImg);

% Image and layout parameters
imgW = 100; imgH = 100;
boxW = 310; boxH = 180;

[screenX, screenY] = Screen('WindowSize', win);

colSpacing = 100;
rowSpacing = 40;
intraSpacing = 30;

% Set font (increase font size)
Screen('TextFont', win, 'Arial');
Screen('TextSize', win, 26);

for i = 1:6
    age = baseTrials{i,6};
    time = baseTrials{i,7};
    food = baseTrials{i,3};

    % ===== Text decomposition =====
    ageWords = strsplit(age, ' ');
    article = ageWords{1};
    ageBold = ageWords{2};
    ageRest = strjoin(ageWords(3:end), ' ');

    timeWords = strsplit(time, ' ');
    timeBold = timeWords{end};
    timeRest = strjoin(timeWords(1:end-1), ' ');

    % Build sentence parts (word-level units)
    sentenceParts = {
        [timeRest],    'normal';
        timeBold,      'bold';
        [','],         'normal';
        article,       'normal';
        ageBold,       'bold';
        ageRest,       'normal';
        'is',          'normal';
        'eating...',   'normal'
        };

    % ===== Layout computation =====
    row = ceil(i / 3);
    col = mod(i - 1, 3) + 1;

    totalWidth = 3 * boxW + 2 * colSpacing;
    totalHeight = 2 * boxH + rowSpacing;
    originX = (screenX - totalWidth) / 2;
    originY = (screenY - totalHeight) / 1.75;

    blockX = originX + (col - 1) * (boxW + colSpacing);
    blockY = originY + (row - 1) * (boxH + rowSpacing);
    boxRect = [blockX, blockY, blockX + boxW + intraSpacing, blockY + boxH];

    % ===== Image processing =====
    foodImg = imread(fullfile(stimDir, ['food/', food, '.tiff']));
    foodTex = Screen('MakeTexture', win, foodImg);
    foodDst = CenterRectOnPoint([0 0 imgW imgH], blockX + boxW - imgW/2, blockY + boxH/2);

    % ===== Text drawing (word-by-word layout) =====
    textLeft = blockX + 10;
    textTop = blockY + 20;
    maxTextWidth = boxW - imgW - 30;
    lineHeight = 32;
    currentX = textLeft;
    currentY = textTop;

    for j = 1:size(sentenceParts, 1)
        word = sentenceParts{j,1};
        style = sentenceParts{j,2};

        if strcmp(style, 'bold')
            Screen('TextStyle', win, 1);  % Bold
        else
            Screen('TextStyle', win, 0);
        end

        % Measure word width
        bbox = Screen('TextBounds', win, [word, ' ']);
        wordWidth = bbox(3) - bbox(1);

        % Decide whether to wrap to next line
        if currentX + wordWidth > textLeft + maxTextWidth
            currentX = textLeft;
            currentY = currentY + lineHeight;
        end

        % Check if this is a comma; if so, slightly adjust Y position
        if strcmp(word, ',')
            drawY = currentY + 10;  % Move comma down by 5–10 pixels for better visual alignment
        else
            drawY = currentY;
        end

        % Draw the word (black)
        Screen('DrawText', win, [word, ' '], currentX, drawY, [0 0 0]);

        % Draw a red minus sign right after the word
        minusSign = '-';
        minusBBox = Screen('TextBounds', win, minusSign);
        minusWidth = minusBBox(3) - minusBBox(1);

        % X position of minus sign = currentX + word width
        Screen('DrawText', win, minusSign, currentX + wordWidth, currentY, [255 255 255]);

        % Update currentX, skipping over word and minus sign width
        currentX = currentX + wordWidth + minusWidth;
    end


    % Draw image and border
    Screen('DrawTexture', win, foodTex, [], foodDst);
    Screen('FrameRect', win, [0 0 0], boxRect, 3);
    Screen('Close', foodTex);
end

end
