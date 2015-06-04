function m = inverseDCT(JQ, array)

    T  = dctmtx(8);
    B2 = blkproc(JQ, [8 8], 'x .* P1', array);
    m  = blkproc(B2, [8 8], 'P1 * x * P2', T', T);
    m  = m + 128;

end