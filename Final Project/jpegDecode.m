function [reconstructed] = jpegDecode(code, dict, dim)

    reverseJQ = huffmandeco(code, dict);

    JQOG  = reshape(reverseJQ, dim(1,1), dim(1,2));
    fid   = fopen('Qtable2.txt', 'r');
    array = fscanf(fid,'%e', [8, inf]);

    reconstructed = inverseDCT(JQOG, array);

end