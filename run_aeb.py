import shutil
import os

from os import listdir
from os.path import isfile, join

try:
    os.remove("./.sconsign.dblite")
    os.remove("./aeb_tb.out")
    os.remove("./hardware.out")
except:
    pass

with open('./aeb.v', "w") as g:

    for chapter in [f'./chapters/{x}' for x in listdir("./chapters/")]:
        with open(chapter, "r") as f:
            v1 = f.readlines()

            for line in v1:
                g.write(line)


os.system('cls')
os.system('apio sim')
