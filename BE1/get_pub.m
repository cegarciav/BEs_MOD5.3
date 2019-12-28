function [sequence] = get_pub(nomPub)

    if strcmp(nomPub, 'quick')
        sequence = [53 143 164 188 201 222 249 257 269 308 486 527 553];
    elseif strcmp(nomPub, 'lipton')
        sequence = [562 583 596 616 636 665 691 706 721 747 813];
    elseif strcmp(nomPub, 'cegetel')
        sequence = [822 854 904 957 976 999 1028 1063 1100 1121 1145 1178 1221 1256 1294 1336 1368 1445 1574];
    elseif strcmp(nomPub, 'salveta')
        sequence = [1583 1656 1736 1813 1872 1896 1910 1961 2008];
    elseif strcmp(nomPub, 'polo')
        sequence = [2017 2107 2148 2185 2244 2488 2527 2618 2689 2767];
    elseif strcmp(nomPub, 'kitkat')
        sequence = [2776 2809 2830 2859 2882 2918 2935 2963 2979 3012 3087 3180 3278];
    end

end

