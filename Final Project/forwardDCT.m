function JQ = forwardDCT(Im, array)

    Im = Im - 128;
    T  = dctmtx(8);
    y  = blkproc(Im, [8 8], 'P1*x*P2', T, T');
    JQ = blkproc(y,  [8 8], 'round(x ./ P1)', array);

end