function checkForEscape()
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown && keyCode(KbName('ESCAPE'))
        sca; ListenChar(0); ShowCursor;
        disp('User pressed ESC to exit.');
    end
end
