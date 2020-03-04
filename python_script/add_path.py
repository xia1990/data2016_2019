#!/usr/bin/python
import sys
import os
from xml.etree import ElementTree as ET
def check_args():
    args_count = len(sys.argv)	
    if args_count >3 or args_count == 1:
        print("USEage:python add_path.py old.xml new.xml")
        sys.exit(1)
    global xml_input_file,xml_output_file
    if args_count == 2:
        xml_input_file = sys.argv[1]
    if args_count == 3:
        xml_output_file = sys.argv[2]
    else:
        xml_output_file = "new_manifest.xml"
    if  not os.path.isfile(xml_input_file):
        print("input xml is not file")
        sys.exit(1)
def add_path():
    tree = ET.parse(xml_input_file)
    root = tree.getroot()
    for project in root.iter('project'):
        if 'path' not in project.attrib:
            project.attrib['path']  = project.attrib['name']
    tree = ET.ElementTree(root)
    tree.write(xml_output_file,encoding="utf-8")
    print("new xml is %s " % xml_output_file)
    os.chmod(xml_output_file,0o777)

if __name__ == "__main__":
    check_args()
    add_path()     
