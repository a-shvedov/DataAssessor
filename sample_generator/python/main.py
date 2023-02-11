#the python file dummy-generator

import random
import json
import time

def generate_code():
    with open('grammar.json', 'r') as f:
        grammar = json.load(f)
    with open('values.json', 'r') as f:
        values = json.load(f)
    code = ''
    for i in range(5):
        rule = random.choice(grammar)
        if rule.count('{') == 1:
            code += rule.format(random.choice(values)) + '\n'
        elif rule.count('{') == 2:
            code += rule.format(random.choice(values), random.choice(values)) + '\n'
        elif rule.count('{') == 3:
            code += rule.format(random.choice(values), random.choice(values), random.choice(values[0]), random.choice(values[1])) + '\n'
    return code

epoch_time = str(int(time.time()))
filename = "autogen_" + epoch_time + ".py"
#print(generate_code())
    
with open(filename, 'w') as f:
    f.write(generate_code())

#for i in range(10):
 #   print(generate_code())
