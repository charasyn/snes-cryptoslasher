#!/usr/bin/env python3

import sys

def interleave(str1, str2):
    words1 = str1.split(" ")
    words2 = str2.split(" ")
    outp = ""
    i1 = 0
    i2 = 0
    while i1 < len(words1) or i2 < len(words2):
        if i1 < len(words1):
            outp += words1[i1] + " "
            i1 += 1
        if i2 < len(words2):
            outp += words2[i2] + " "
            i2 += 1
    return outp

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print('Usage: {0} "<str 1>" "<str 2>"'.format(sys.argv[0]))
        sys.exit(1)
    print(interleave(sys.argv[1], sys.argv[2]))
