clc; clear all; close all;

%% Example call
dmn_autodiscover( ...
   '/Volumes/Kevin-SSD/MRI-Study/IndivAnal/dmn_rest_PrePost', ...
   '/Volumes/Kevin-SSD/MRI-Study/IndivAnal/dmn_rest_PrePost/Statistics');

%% ================================================================
function dmn_autodiscover(dataDir, outDir, zscoreEachROI)
% Auto-discovers ROI CSVs and runs DMN stats (no manifest needed).
% Handles two naming schemes:
%   (A) "...sub-0XX-1..." or "...sub-0XX-2..."  -> Sham / FUS
%   (B) "...sub-<anything>_<NNN>...PreFUS/PostFUS..." -> Sham / FUS
%
%  - dataDir: folder containing per-subject ROI time-series CSVs
%  - outDir : output folder
%  - zscoreEachROI (optional, default = true): z-score each ROI timecourse
%
% Writes:
%   outDir/per_subject/<sub>_Z_7x7.csv                     (per-subject Fisher-Z)
%   outDir/DMN_edges_long.csv                              (long table)
%   outDir/DMN_mixedmodel_results.csv                      (LME per edge)
%   outDir/discovered_manifest.csv                         (what was found)
%   outDir/summary/MeanZ_<Group>_<Cond>_7x7.csv            (4 matrices)
%   outDir/summary/MeanR_<Group>_<Cond>_7x7.csv            (4 matrices)
%   outDir/summary/counts.txt

if nargin < 3, zscoreEachROI = true; end
if ~exist(outDir,'dir'), mkdir(outDir); end
perSubDir = fullfile(outDir,'per_subject'); if ~exist(perSubDir,'dir'), mkdir(perSubDir); end
sumDir    = fullfile(outDir,'summary');     if ~exist(sumDir,'dir'),    mkdir(sumDir);    end

% --- ROI labels and ROI order we will use ---
ROI = {'PCC_L','PCC_R','Precuneus_L','Precuneus_R','mPFC','AG_L','AG_R'};
N   = numel(ROI);
[II,JJ] = find(triu(true(N),1));          % indices for 21 edges
edgeNames = arrayfun(@(k) sprintf('%s:%s', ROI{II(k)}, ROI{JJ(k)}), 1:numel(II), 'uni', 0);

% --- discover files (recursive) ---
S = dir(fullfile(dataDir,'**','*.csv'));
keep  = false(numel(S),1);
Subj  = strings(numel(S),1);
Cond  = strings(numel(S),1);
Group = strings(numel(S),1);
Pair  = strings(numel(S),1);
Path  = strings(numel(S),1);

for i = 1:numel(S)
    fn = string(fullfile(S(i).folder, S(i).name));

    subjStr = "";  idnum = NaN;  cond = "";

    % ---- Pattern A: sub-0XX-1 / sub-0XX-2 ----
    tokA = regexp(fn, 'sub-(\d+)-(1|2)', 'tokens', 'once');
    if ~isempty(tokA)
        idnum = str2double(tokA{1});
        flag  = tokA{2};                    % '1' / '2'
        cond  = tern(flag=="2", "FUS", "Sham");
        subjStr = sprintf('sub-%03d-%s', idnum, flag);
    else
        % ---- Pattern B: sub-<anything>_<NNN> ... (PreFUS|PostFUS) ----
        tokB = regexp(fn, 'sub-[^/]*_(\d+).*?(PreFUS|PostFUS)', 'tokens', 'once');
        if ~isempty(tokB)
            idnum = str2double(tokB{1});
            pf    = string(tokB{2});
            cond  = tern(pf=="PostFUS","FUS","Sham");     % PostFUS→FUS, PreFUS→Sham
            subjStr = sprintf('sub-%03d-%s', idnum, lower(char(cond))); % e.g., sub-001-sham
        end
    end

    if isnan(idnum) || strlength(cond)==0
        continue; % not recognized
    end

    % Clinical group by ID
    if idnum >= 1 && idnum <= 16
        grp = "Healthy";
    elseif idnum >= 17 && idnum <= 28
        grp = "Insomnia";
    else
        continue
    end

    keep(i)  = true;
    Subj(i)  = subjStr;
    Cond(i)  = cond;
    Group(i) = grp;
    Pair(i)  = sprintf('sub-%03d', idnum);
    Path(i)  = fn;
end

S     = S(keep);
Subj  = Subj(keep);
Cond  = Cond(keep);
Group = Group(keep);
Pair  = Pair(keep);
Path  = Path(keep);

if isempty(S)
    error('No matching CSVs found in %s (need filenames containing sub-0XX-[12] or PreFUS/PostFUS).', dataDir);
end

Manifest = table(Subj, Group, Cond, Pair, Path,'VariableNames', ...
    {'SubjectID','Group','Condition','PairID','File'});
writetable(Manifest, fullfile(outDir,'discovered_manifest.csv'));

% --- Prepare long table container ---
Long = table('Size',[0 7], ...
    'VariableTypes', {'string','categorical','categorical','string','string','string','double'}, ...
    'VariableNames', {'SubjectID','Group','Condition','Edge','ROI1','ROI2','Z'});

% --- Aggregation holders: Group x Condition (4 combos) ---
GC = ["Healthy|Sham","Healthy|FUS","Insomnia|Sham","Insomnia|FUS"];
sumZ = containers.Map(GC, {zeros(N), zeros(N), zeros(N), zeros(N)});
nZ   = containers.Map(GC, {0, 0, 0, 0});

% --- iterate files, build per-subject Z and push to long table ---
for r = 1:height(Manifest)
    sid   = Manifest.SubjectID(r);
    grp   = Manifest.Group(r);      % "Healthy"/"Insomnia"
    cond  = Manifest.Condition(r);  % "Sham"/"FUS"
    fcsv  = Manifest.File(r);

    T = readtable(fcsv, 'TextType','string');
    X = [];

    if width(T) >= N && all(ismember(ROI, string(T.Properties.VariableNames)))
        X = table2array(T(:, ROI));             % reorder explicitly
    elseif width(T) >= N
        X = table2array(T(:,1:N));              % assume first 7 cols are PCC_L..AG_R
        warning('Header mismatch in %s: using first 7 columns as PCC_L..AG_R', fcsv);
    else
        X = readmatrix(fcsv);
        if size(X,2) < N
            warning('Skipping %s (has < 7 columns)', fcsv);
            continue
        end
        X = X(:,1:N);
    end

    if size(X,1) < 3
        warning('Skipping %s (too few timepoints)', fcsv);
        continue
    end

    if zscoreEachROI
        X = (X - mean(X,1,'omitnan')) ./ std(X,0,1,'omitnan');
    end

    R = corrcoef(X, 'Rows','pairwise');
    R = max(min(R,0.999999),-0.999999);
    Z = atanh(R);
    Z(1:N+1:end) = 0;

    % per-subject Z with headers
    Ztbl = array2table(Z, 'VariableNames', ROI, 'RowNames', ROI);
    writetable(Ztbl, fullfile(perSubDir, sprintf('%s_Z_7x7.csv', sid)), 'WriteRowNames', true);

    % add to Group×Condition aggregate
    key = sprintf('%s|%s', grp, cond);
    Zsum = sumZ(key);  Zsum = Zsum + Z;  sumZ(key) = Zsum;
    nZ(key) = nZ(key) + 1;

    % long table (21 edges)
    for k = 1:numel(II)
        Long = [Long; {sid, categorical(grp), categorical(cond), edgeNames{k}, ROI{II(k)}, ROI{JJ(k)}, Z(II(k),JJ(k))}]; %#ok<AGROW>
    end
end

% write long edges table
writetable(Long, fullfile(outDir,'DMN_edges_long.csv'));

% --- Mixed model per edge: Z ~ Group * Condition + (1 | PairID) ---
Long.PairID    = categorical(regexprep(Long.SubjectID,'-(1|2|sham|fus)$','')); % both styles
Long.Group     = categorical(cellstr(string(Long.Group)), {'Healthy','Insomnia'}); % reference: Healthy
Long.Condition = categorical(cellstr(string(Long.Condition)), {'Sham','FUS'});     % reference: Sham

E = unique(Long.Edge);
K = numel(E);
res = table('Size',[K 10], 'VariableTypes', ...
    {'string','double','double','double','double','double','double','double','double','double'}, ...
    'VariableNames', {'Edge','Npairs','p_Group','p_Cond','p_Interaction','q_Group','q_Cond','q_Interaction','beta_CondFUS','beta_Interaction'});

for i = 1:K
    e = E(i);
    D = Long(Long.Edge==e,:);

    % keep only pairs that have both Sham & FUS
    pid = categories(D.PairID);
    keepIDs = strings(0,1);
    for j = 1:numel(pid)
        pj = pid{j};
        dj = D(D.PairID==pj,:);
        if any(dj.Condition=="Sham") && any(dj.Condition=="FUS")
            keepIDs(end+1,1) = string(pj); %#ok<AGROW>
        end
    end
    D = D(ismember(string(D.PairID), keepIDs), :);
    if height(D) < 6,  % very small sample guard
        warning('Too few rows for edge %s (pairs=%d); skipping.', e, numel(unique(D.PairID)));
        continue
    end

    lme = fitlme(D, 'Z ~ Group*Condition + (1|PairID)', 'DummyVarCoding','reference');

    a  = anova(lme,'DFMethod','Satterthwaite');
    pG = pullP(a,'Group');
    pC = pullP(a,'Condition');
    pI = pullP(a,'Group:Condition');

    bt = lme.Coefficients;
    bC  = pullCoef(bt,'Condition_FUS');
    bIx = pullAnyOf(bt, {'Group_Insomnia:Condition_FUS','Condition_FUS:Group_Insomnia'});

    res.Edge(i)            = e;
    res.Npairs(i)          = numel(unique(D.PairID));
    res.p_Group(i)         = pG;
    res.p_Cond(i)          = pC;
    res.p_Interaction(i)   = pI;
    res.beta_CondFUS(i)    = bC;
    res.beta_Interaction(i)= bIx;
end

% FDR by BH
res.q_Group       = fdr_bh(res.p_Group);
res.q_Cond        = fdr_bh(res.p_Cond);
res.q_Interaction = fdr_bh(res.p_Interaction);

writetable(res, fullfile(outDir,'DMN_mixedmodel_results.csv'));

% --- Aggregate summary correlation matrices (Group × Condition = 4) ---
groups = ["Healthy","Insomnia"];
conds  = ["Sham","FUS"];
for g = groups
    for c = conds
        key = sprintf('%s|%s', g, c);
        n   = nZ(key);
        if n > 0
            MeanZ = sumZ(key) ./ n;
            MeanR = tanh(MeanZ);
            Ztbl  = array2table(MeanZ, 'VariableNames', ROI, 'RowNames', ROI);
            Rtbl  = array2table(MeanR, 'VariableNames', ROI, 'RowNames', ROI);
            writetable(Ztbl, fullfile(sumDir, sprintf('MeanZ_%s_%s_7x7.csv', g, c)), 'WriteRowNames', true);
            writetable(Rtbl, fullfile(sumDir, sprintf('MeanR_%s_%s_7x7.csv', g, c)), 'WriteRowNames', true);
        end
    end
end

% simple counts file
fid = fopen(fullfile(sumDir,'counts.txt'),'w');
fprintf(fid,'Subjects per Group × Condition:\n');
for g = groups
    for c = conds
        fprintf(fid,'  %s | %s: %d\n', g, c, nZ(sprintf('%s|%s', g, c)));
    end
end
fclose(fid);

fprintf('\nDone.\n- Per-subject Z: %s\n- Long edges: %s\n- Mixed model: %s\n- Manifest: %s\n- Summary: %s\n', ...
    perSubDir, fullfile(outDir,'DMN_edges_long.csv'), fullfile(outDir,'DMN_mixedmodel_results.csv'), ...
    fullfile(outDir,'discovered_manifest.csv'), sumDir);
end

% ===================== helpers =====================
function y = tern(cond, a, b), if cond, y=a; else, y=b; end, end
function q = fdr_bh(p)
q = nan(size(p));
good = ~isnan(p);
[ps,ix] = sort(p(good),'ascend');
m = sum(good);
if m==0, return; end
qs = ps .* m ./ (1:m)';
for k=m-1:-1:1, qs(k) = min(qs(k), qs(k+1)); end
tmp = nan(size(p)); tmp(good) = qs(rank2order(ix,m));
q = tmp;
end
function ord = rank2order(ix,m)
ord = zeros(m,1); ord(ix) = 1:m;
end
function p = pullP(a, term)
p = NaN; hit = strcmp(string(a.Term), term); if any(hit), p = a.pValue(find(hit,1)); end
end
function b = pullCoef(bt, nameFrag)
b = NaN; hit = contains(string(bt.Name), nameFrag); if any(hit), b = bt.Estimate(find(hit,1)); end
end
function b = pullAnyOf(bt, frags)
b = NaN;
for k=1:numel(frags)
    hit = contains(string(bt.Name), frags{k});
    if any(hit), b = bt.Estimate(find(hit,1)); return; end
end
end
