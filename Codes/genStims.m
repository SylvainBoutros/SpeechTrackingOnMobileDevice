function [practice_shuff, experiment_shuff] = genStims(DataPath, rampON)
load(DataPath);
if isequal(rampON, 1)
    kSamplesInRamp = floor(expTable(1).fs * 0.01); 
    onRamp = linspace(0, 1, kSamplesInRamp);
    offRamp = linspace(1, 0, kSamplesInRamp);

    for i = 1:length(expTable)
        tmpStim{i} = (expTable(i).y - mean(expTable(i).y)) ./ abs(max(expTable(i).y));
        tmpStim{i}(1:kSamplesInRamp, 1) = tmpStim{i}(1:kSamplesInRamp, 1) .* onRamp';
        tmpStim{i}(length(tmpStim{i}) - kSamplesInRamp + 1: end, 1) = tmpStim{i}(length(tmpStim{i}) - kSamplesInRamp + 1: end, 1) .* offRamp';
        expTable(i).y = tmpStim{i};
    end
end

% Temp fix cause randperm wasn't working
experiment_shuff = expTable(randperm(size(expTable,1)),:);
experiment_shuff = Shuffle(experiment_shuff);
practice_shuff = practiceTable(randperm(size(practiceTable, 1)), :);
practice_shuff = Shuffle(practice_shuff);
end