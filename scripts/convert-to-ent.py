"""Convert Map Spawns Editor Format File to Entity file format"""

import sys

input_file = sys.argv[1]
input_file_name = sys.argv[2]

output_file = input_file_name + ".spawns"

with open(input_file, mode = "r", encoding = "UTF-8") as f:
    fc = f.readlines()

result = ""

for line in fc:
    line = line.strip()

    if line.startswith(r"/* "):
        continue # skip comment

    parts = line.split()

    classname_raw = parts[0]

    if classname_raw == "CT":
        classname = "info_player_start"
    elif classname_raw == "T":
        classname = "info_player_deathmatch"

    origin = "{} {} {}".format(parts[1], parts[2], parts[3])
    angles = "{} {} {}".format(parts[4], parts[5], parts[6])

    iteration_result = "{}\n\"origin\" \"{}\"\n\"angles\" \"{}\"\n\"classname\" \"{}\"\n{}\n".format(
        r"{",
        origin,
        angles,
        classname,
        r"}"
    )

    result += iteration_result

with open(output_file, mode = "wt", encoding = "UTF-8", newline = '') as f:
    f.write(result)
