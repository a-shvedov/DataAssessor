import re
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-i", "--input", help="file path")
args = parser.parse_args()

values = {'m_remaining_time': 0, 'm_duration': 0, 'm_passed_time': 0}
group = []

with open(args.input, "r") as f:
    lines = f.readlines()
    for line in lines:
        if 'STOPED' in line or 'STARTED' in line:
            for l in group:
                print(l)
            print(f"Result: m_remaining_time: {values['m_remaining_time']}; m_duration: {values['m_duration']}; m_passed_time: {values['m_passed_time']};")
            values = {'m_remaining_time': 0, 'm_duration': 0, 'm_passed_time': 0}
            group = []
        elif 'm_remaining_time' in line:
            group.append(line)
            a_value = int(re.search(r'm_remaining_time: (\d+)', line).group(1))
            b_value = int(re.search(r'm_duration: (\d+)', line).group(1))
            c_value = int(re.search(r'm_passed_time: (\d+)', line).group(1))
            values['m_remaining_time'] += a_value
            values['m_duration'] += b_value
            values['m_passed_time'] += c_value
        elif 'm_passed_time' in line:
            group.append(line)
            b_value = int(re.search(r'm_passed_time: (\d+)', line).group(1))
            values['m_passed_time'] += b_value
