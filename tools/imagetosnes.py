#!/usr/bin/env python3

from PIL import Image
import os
import sys
import itertools

def groups(data, l):
    ret = []
    while len(data) > 0:
        ret.append(data[0:l])
        data = data[l:]
    return ret

def generateCollapsedPalette(img):
    pal = img.getpalette()
    for i in range(0,len(pal),3):
        yield tuple(pal[i:i+3])

def buildSubImages(img, width, height):
    outp = []
    for y in range(int(img.size[1] / height)):
        for x in range(int(img.size[0] / width)):
            outp.append(img.crop(((x * width, y * height, (x+1) * width, (y+1) * height))))
    return outp

def img8x8To1BPP(inp, args):
    img = inp[0]
    simgs = buildSubImages(img.convert("L"), 8, 8)
    outp = bytearray()
    for si in simgs:
        for y in range(8):
            tmp = 0
            for x in range(8):
                pixel = si.getpixel((x,y))
                tmp = tmp << 1
                if pixel > 0x80:
                    tmp = tmp | 1
            outp.append(tmp)
    return (outp, None)

def palLookup(pal, pix, mode):
    return None

def convertPalToSNES(pal):
    # RGB888 to BGR555 conversion
    words = ((int(x[0]/255*31) | int(x[1]/255*31) << 5 | int(x[2]/255*31) << 10) for x in pal)
    ret = []
    for w in words:
        ret.append(w & 0xff)
        ret.append((w>>8) & 0xff)
    return bytearray(ret)

def img8x8ToSNES4BPP(inp, args):
    img = inp[0]
    pal = inp[1]
    simgs = buildSubImages(img, 8, 8)
    imagePaletted = img.mode == 'P'
    if pal == None:
        if imagePaletted:
            maxUsed = max([x[1] for x in img.getcolors()])
            pal = [x for x in itertools.islice(generateCollapsedPalette(img), maxUsed+1)]
            while len(pal) % 16 != 0:
                pal.append((0,0,0))
        else:
            raise ValueError("Non-paletted images not yet supported")
    outp = bytearray()
    for si in simgs:
        tile1 = bytearray()
        tile2 = bytearray()
        for y in range(8):
            tmp1 = 0
            tmp2 = 0
            tmp3 = 0
            tmp4 = 0
            for x in range(8):
                pixel = si.getpixel((x,y))
                col = pixel if imagePaletted else palLookup(pal, pixel)
                tmp1 = tmp1 << 1 | (1 if col & 0x01 != 0 else 0)
                tmp2 = tmp2 << 1 | (1 if col & 0x02 != 0 else 0)
                tmp3 = tmp3 << 1 | (1 if col & 0x04 != 0 else 0)
                tmp4 = tmp4 << 1 | (1 if col & 0x08 != 0 else 0)
            tile1.append(tmp1)
            tile1.append(tmp2)
            tile2.append(tmp3)
            tile2.append(tmp4)
        outp += tile1
        outp += tile2
    return (outp, convertPalToSNES(pal))

def usage(progName):
    print("Usage: {0} <options>".format(progName))
    print("  Read the program for more info")

def main(args):
    # Options are specified like dd: "key=value"
    params = {arg.split("=",1)[0] : arg.split("=",1)[1] for arg in args[1:]}
    # Must have 'chrin' and 'chrout' params -> data in and out respectively
    # Must also have 'module'
    if not 'chrin' in params or not 'chrout' in params or not 'module' in params:
        usage(args[0])
        return 1
    
    img = Image.open(params['chrin'])
    pal = None
    if 'palin' in params:
        pal = Image.open(params['palin'])
    
    processed = None
    if params['module'].lower() == "img8x8to1bpp":
        processed = img8x8To1BPP((img, pal), params)
    if params['module'].lower() == "img8x8tosnes4bpp":
        processed = img8x8ToSNES4BPP((img, pal), params)
    else:
        print("Invalid module.")
        usage(args[0])
        return 1
    
    if processed[0] == None:
        raise ValueError("Programmer error.")
    else:
        with open(params['chrout'], "wb") as out:
            out.write(processed[0])
    
    if 'palout' in params:
        if processed[1] == None:
            print("Algorithm did not output a palette!")
        else:
            with open(params['palout'], "wb") as out:
                out.write(processed[1])
    
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))