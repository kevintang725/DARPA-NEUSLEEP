%% 
clc; clear all; close all

%% Main
result = erythema_qscore_analysis('/Users/kevintang/Desktop/Desktop-Kevin/UTAustin/Project/DARPA-REM-Sleep/Experiments/Bioadhesive Substrate/Images/Day 2.jpg');
disp(result)
%%
function results = erythema_qscore_analysis(imageFile, doInvert, outputDir, padPixels)
% ERYTHEMA_QSCORE_SAVE_BOTH_VERSIONS_THINBLACK
% Same behaviour as prior "save both versions" function but with
% thinner black lesion boundary lines in the "with_outline" saved image.
%
% USAGE:
%  results = erythema_qscore_save_both_versions_thinblack(imageFile);
%  results = erythema_qscore_save_both_versions_thinblack(imageFile, false, 'EQ_out', 8);

    if nargin < 2 || isempty(doInvert), doInvert = false; end
    if nargin < 3 || isempty(outputDir), outputDir = 'EQ_output'; end
    if nargin < 4 || isempty(padPixels), padPixels = 0; end

    if ~exist(outputDir, 'dir'), mkdir(outputDir); end

    Iorig = imread(imageFile);
    if size(Iorig,3) ~= 3
        error('Input must be an RGB image.');
    end
    I = im2double(Iorig);
    [H, W, ~] = size(I);

    R = I(:,:,1); G = I(:,:,2);
    ratio_red = R ./ max(G, 1e-6);

    [~, baseName, ~] = fileparts(imageFile);

    % Main interactive figure for ROI drawing (keeps temporary boxes only during selection)
    hFig = figure('Name','EQscore Crop & Save (both versions)','NumberTitle','off','Color','w');
    imshow(I);
    title('Draw lesion field rectangle (box). Double-click to confirm.');
    hold on;

    results = struct([]);
    lesionIdx = 0;
    keepGoing = true;

    while keepGoing
        lesionIdx = lesionIdx + 1;
        fprintf('\n--- Lesion %d ---\n', lesionIdx);

        % 1) lesion field rectangle (box)
        hField = drawrectangle('Color','y','LineWidth',1.0);
        wait(hField);
        fieldRect = round(hField.Position);          % [x y w h]
        fieldRect = clipRectToImage(fieldRect, H, W);

        % 2) gradient rectangle
        title(sprintf('Lesion %d: Draw GRADIENT ROI (box).', lesionIdx));
        hGrad = drawrectangle('Color','c','LineWidth',1.0);
        wait(hGrad);
        gradRect = round(hGrad.Position);
        gradRect = clipRectToImage(gradRect, H, W);
        gradMask = rectMask(gradRect, H, W);

        % 3) normal rectangle
        title(sprintf('Lesion %d: Draw NORMAL ROI (box).', lesionIdx));
        hNorm = drawrectangle('Color','g','LineWidth',1.0);
        wait(hNorm);
        normRect = round(hNorm.Position);
        normRect = clipRectToImage(normRect, H, W);
        normMask = rectMask(normRect, H, W);

        % remove interactive ROI objects (so they won't appear in saved crops)
        deleteIfValid(hField);
        deleteIfValid(hGrad);
        deleteIfValid(hNorm);

        % compute threshold & lesion mask (paper method)
        threshold = median(ratio_red(gradMask), 'omitnan');
        if ~doInvert
            lesionMaskFull = rectMask(fieldRect, H, W) & (ratio_red > threshold);
        else
            lesionMaskFull = rectMask(fieldRect, H, W) & (ratio_red < threshold);
        end

        lesionVals = ratio_red(lesionMaskFull);
        norm_red = mean(ratio_red(normMask), 'omitnan');

        if isempty(lesionVals) || all(isnan(lesionVals))
            lesion_red = NaN; EQCI = NaN; EQCIs = NaN; EQscore = NaN;
            warning('No lesion pixels detected for lesion %d.', lesionIdx);
        else
            lesion_red = mean(lesionVals, 'omitnan');
            EQCI  = 10 * (lesion_red / norm_red - 1);
            EQCIs = 0.34 + 0.54 * EQCI;
            EQscore = -0.35 + 1.9 * EQCIs - 0.2 * (EQCIs.^2);
        end

        % Crop rectangle with padding
        x1 = max(1, fieldRect(1) - padPixels);
        y1 = max(1, fieldRect(2) - padPixels);
        x2 = min(W, fieldRect(1) + fieldRect(3) - 1 + padPixels);
        y2 = min(H, fieldRect(2) + fieldRect(4) - 1 + padPixels);
        cropImg = I(y1:y2, x1:x2, :);             % double 0..1
        cropMask = lesionMaskFull(y1:y2, x1:x2);

        % Build overlay (red semi-transparent) only if EQscore >= 0 and cropMask not empty
        showOutline = ~isnan(EQscore) && EQscore >= 0 && any(cropMask(:));
        overlayImg = cropImg;  % default identical to crop

        if showOutline
            perim = bwperim(cropMask);
            perim = imdilate(perim, strel('disk', 1));  % adjust disk radius if you want thicker red alpha
            alphaVal = 0.5; % 50% transparency
            alphaMask = double(perim) * alphaVal;   % Hc x Wc
            % alpha blend red on top of cropImg
            redChannel   = cropImg(:,:,1) .* (1 - alphaMask) + 1 .* alphaMask;
            greenChannel = cropImg(:,:,2) .* (1 - alphaMask) + 0 .* alphaMask;
            blueChannel  = cropImg(:,:,3) .* (1 - alphaMask) + 0 .* alphaMask;
            overlayImg = cat(3, redChannel, greenChannel, blueChannel);
        end

        % ---------- Save NO-OUTLINE version ----------
        outFile_no = fullfile(outputDir, sprintf('%s_lesion_%02d_no_outline_EQ_%.2f.png', baseName, lesionIdx, double(EQscore)));
        hNoFig = figure('Visible','off'); imshow(cropImg); hold on;
        txt = sprintf('EQ = %.2f', EQscore);
        text(8, 12, txt, 'Color','w', 'FontWeight','bold', 'FontSize', 12, 'BackgroundColor','k', 'Margin', 4, 'VerticalAlignment','top');
        axis off; set(gca,'Position',[0 0 1 1]); drawnow;
        exportgraphics(gca, outFile_no, 'Resolution', 300);
        close(hNoFig);

        % ---------- Save WITH-OUTLINE version ----------
        outFile_with = fullfile(outputDir, sprintf('%s_lesion_%02d_with_outline_EQ_%.2f.png', baseName, lesionIdx, double(EQscore)));
        hWithFig = figure('Visible','off'); imshow(overlayImg); hold on;
        % draw THIN black lesion boundary on top of overlay if showOutline
        if showOutline
            B = bwboundaries(cropMask, 'noholes');
            for k = 1:numel(B)
                boundary_k = B{k};
                % Thin black line (user requested "thinner and black")
                plot(boundary_k(:,2), boundary_k(:,1), 'k', 'LineWidth', 1.0);
            end
        end
        text(8, 12, txt, 'Color','w', 'FontWeight','bold', 'FontSize', 12, 'BackgroundColor','k', 'Margin', 4, 'VerticalAlignment','top');
        axis off; set(gca,'Position',[0 0 1 1]); drawnow;
        exportgraphics(gca, outFile_with, 'Resolution', 300);
        close(hWithFig);

        % If no outline should appear (EQ < 0) the two files will be identical except filenames.

        fprintf('Saved (no outline): %s\n', outFile_no);
        fprintf('Saved (with outline): %s\n', outFile_with);

        % store results (include both file paths)
        results(lesionIdx).lesion_index = lesionIdx;
        results(lesionIdx).imageFile = imageFile;
        results(lesionIdx).outputFile_no_outline = outFile_no;
        results(lesionIdx).outputFile_with_outline = outFile_with;
        results(lesionIdx).fieldRect = fieldRect;
        results(lesionIdx).gradRect  = gradRect;
        results(lesionIdx).normRect  = normRect;
        results(lesionIdx).threshold = threshold;
        results(lesionIdx).lesion_red = lesion_red;
        results(lesionIdx).norm_red = norm_red;
        results(lesionIdx).EQCI = EQCI;
        results(lesionIdx).EQCIs = EQCIs;
        results(lesionIdx).EQscore = EQscore;

        % prompt to continue
        resp = input('Add another lesion? (y/n): ','s');
        if isempty(resp), resp = 'n'; end
        keepGoing = lower(resp(1)) == 'y';

        % restore main figure for next ROI selection
        figure(hFig); imshow(I); hold on;
    end

    % Save CSV summary (include both filenames)
    if ~isempty(results)
        summaryFile = fullfile(outputDir, sprintf('%s_EQ_summary.csv', baseName));
        lesion_index = [results.lesion_index]';
        EQscore_col   = [results.EQscore]';
        EQCI_col      = [results.EQCI]';
        lesion_red_col= [results.lesion_red]';
        norm_red_col  = [results.norm_red]';
        threshold_col = [results.threshold]';
        file_no_col   = string({results.outputFile_no_outline})';
        file_with_col = string({results.outputFile_with_outline})';
        T = table(lesion_index, EQscore_col, EQCI_col, lesion_red_col, norm_red_col, threshold_col, file_no_col, file_with_col, ...
            'VariableNames', {'lesion_index','EQscore','EQCI','lesion_red','norm_red','threshold','file_no_outline','file_with_outline'});
        writetable(T, summaryFile);
        fprintf('Summary CSV saved: %s\n', summaryFile);
    end

    close(hFig);
end

%% Helper subfunctions
function rect = clipRectToImage(rect, H, W)
    x = max(1, round(rect(1))); y = max(1, round(rect(2)));
    w = max(1, round(rect(3))); h = max(1, round(rect(4)));
    if x + w - 1 > W, w = W - x + 1; end
    if y + h - 1 > H, h = H - y + 1; end
    rect = [x y w h];
end

function mask = rectMask(rect, H, W)
    mask = false(H, W);
    x1 = rect(1); y1 = rect(2);
    x2 = min(W, rect(1) + rect(3) - 1);
    y2 = min(H, rect(2) + rect(4) - 1);
    mask(y1:y2, x1:x2) = true;
end

function deleteIfValid(h)
    if ~isempty(h) && isvalid(h), delete(h); end
end

