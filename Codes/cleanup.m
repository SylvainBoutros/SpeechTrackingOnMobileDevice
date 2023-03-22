% Function to assign the answers to a structure called participant
function participant = cleanup(answers)
participant = struct();

participant.id = str2double(answers{1});
participant.age = str2double(answers{2});
participant.sex = answers{3};
participant.handedness = answers{4};
participant.course = answers{5};
participant.instructor = answers{6};
participant.eeg = str2double(answers{7});

end