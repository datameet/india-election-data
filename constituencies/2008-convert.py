'''
Converts manually parsed 2008 ECI delimitation order into a CSV file.
'''

import sys
import csv
import re

def parse(chunk):
    '''Parses a chunk like "86-Devarakonda(ST)" and returns the number, name and category'''
    try:
        chunk = chunk.replace(',', '').strip()
        match = re.match(r'(\d+)\W*(.*)', chunk)
        number, name = match.group(1).strip(), match.group(2).strip()
        name = re.sub(r'\s+', ' ', name)
        name = re.sub(r'\.$', '', name)
        match = re.match(r'(.*?)\(([A-Z]+)\)$', name)
        if match:
            name, cat = match.group(1).strip(), match.group(2).strip()
        else:
            cat = ''
        return int(number), name.upper(), cat
    except AttributeError:
        print chunk
        raise

def run(filename):
    '''Create the CSV file from the command line'''
    out = csv.writer(sys.stdout, lineterminator='\n')
    out.writerow(['STATE', 'PC_NO', 'PC_NAME', 'PC_TYPE', 'AC_NO', 'AC_NAME', 'AC_TYPE'])
    for row in open(filename):
        row = row.strip()
        if not row:
            continue

        if row.startswith('STATE'):
            state = row.replace('STATE: ', '')
            continue

        pc_parts = (state,) + parse(row[:30].strip())

        ac_row = row[30:].strip()
        lastpos = 0
        for match in re.finditer(r',', ac_row):
            pos = match.start() + 1
            chunk = ac_row[lastpos:pos].strip()
            if chunk:
                out.writerow(pc_parts + parse(chunk))
            lastpos = pos
        out.writerow(pc_parts + parse(ac_row[lastpos:]))

if __name__ == '__main__':
    run('2008-eci-delimitation.txt')
