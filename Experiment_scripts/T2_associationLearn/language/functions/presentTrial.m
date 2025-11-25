function [choice, rt] = presentTrial(win, instrDir, t_age, t_time, shuffledFoodNames, xCenter, yCenter)

% Set font
Screen('TextFont', win, 'Arial');
Screen('TextSize', win, 26);

% === Combine age and time into one sentence with bold keywords ===
ageWords = strsplit(t_age, ' ');
article = ageWords{1};
ageBold = ageWords{2};
ageRest = strjoin(ageWords(3:end), ' ');

timeWords = strsplit(t_time, ' ');
timeBold = timeWords{end};
timeRest = strjoin(timeWords(1:end-1), ' ');

sentenceParts = {
    [timeRest], 'normal';
    timeBold, 'bold';
    [','], 'normal';
    article, 'normal';
    ageBold, 'bold';
    ageRest, 'normal';
    'is', 'normal';
    'eating...', 'normal'
    };

% Clear screen
Screen('FillRect', win, 255);

% === Display sentence (bold keywords + automatic line wrapping + no word splitting) ===
textLeft = xCenter - 400;
textTop = yCenter - 200;
maxTextWidth = 800;
lineHeight = 32;
currentX = textLeft;
currentY = textTop;

for j = 1:size(sentenceParts, 1)
    word = sentenceParts{j,1};
    style = sentenceParts{j,2};

    if strcmp(style, 'bold')
        Screen('TextStyle', win, 1);
    else
        Screen('TextStyle', win, 0);
    end

    fullWord = [word, ' '];
    bbox = Screen('TextBounds', win, fullWord);
    wordWidth = bbox(3) - bbox(1);

    % Line break check
    if currentX + wordWidth > textLeft + maxTextWidth
        currentX = textLeft;
        currentY = currentY + lineHeight;
    end

    % If it is a comma, add an extra 10-pixel vertical offset
    if strcmp(word, ',')
        drawY = currentY + 10;
    else
        drawY = currentY;
    end

    % Draw word (black)
    Screen('DrawText', win, fullWord, currentX, drawY, [0 0 0]);

    % Draw gray minus sign '-'
    minusSign = '-';
    minusBBox = Screen('TextBounds', win, minusSign);
    minusWidth = minusBBox(3) - minusBBox(1);
    Screen('DrawText', win, minusSign, currentX + wordWidth, currentY, [255 255 255]);

    % Update X coordinate: skip over word and minus sign
    currentX = currentX + wordWidth + minusWidth;
end

% === Display 6 food images and numeric labels at the bottom ===
nOptions = 6;
optionSpacing = 120;
optionWidth = 80;
totalWidth = nOptions * optionWidth + (nOptions - 1) * optionSpacing;
startX = xCenter - totalWidth / 2 + optionWidth / 2;

rectList = cell(1, nOptions);
for k = 1:nOptions
    foodImg = imread(fullfile(instrDir, 'food', [shuffledFoodNames{k} '.tiff']));
    tex = Screen('MakeTexture', win, foodImg);
    xPos = startX + (k-1) * (optionWidth + optionSpacing);
    yPos = yCenter + 50;
    dstRect = CenterRectOnPoint([0 0 optionWidth optionWidth], xPos, yPos);
    rectList{k} = dstRect;
    Screen('DrawTexture', win, tex, [], dstRect);
    DrawFormattedText(win, ['(' num2str(k) ')'], xPos - 15, yPos + 60, [0 0 0]);
end

% === Flip to screen and start timing ===
Screen('Flip', win);
tStart = GetSecs;
ShowCursor;

% === Wait for mouse click ===
clicked = false;
choice = '';
rt = NaN;
while ~clicked
    [x, y, buttons] = GetMouse(win);
    if any(buttons)
        for k = 1:nOptions
            if IsInRect(x, y, rectList{k})
                choice = shuffledFoodNames{k};
                rt = GetSecs - tStart;
                clicked = true;
                break;
            end
        end
    end
end
HideCursor;
end
