function [code, dict, dimMV] = huffEncode(motionVect)

    % Dimension of frame (needed to decode later on)
    dimMV = size(motionVect);

    % Reshape motion vectores into a single bitstream (1 row)
    bitstream = reshape(motionVect, 1, []);
    uniq_bitstream = unique(bitstream);
    
    % Value - # occurrences
    p = histc(bitstream, uniq_bitstream) / prod(dimMV);

    % Create dictionary (needed to decode later on)
    [dict, ~] = huffmandict(uniq_bitstream,p);
    
    % Encode bistream using dictionary
    code = huffmanenco(bitstream, dict);

end