#!/usr/bin/python
from xml.etree import ElementTree as ET
import sys,os,re
if len(sys.argv) >= 2:
    change_xml_file = sys.argv[1]
else:
    exit(1)

project_name_dict = {}
origin_dict = {}

class change_xml(object):
	def __init__(self):
		global change_xml_file,project_name_dict
		self.tree = ET.parse(change_xml_file)
		self.root = self.tree.getroot()
		self.default_origin = self.root.find('default').get('remote')
		if self.default_origin is None:
			print "default origin is empty"
			exit(1)
		else:
			print "default origin is %s" % self.default_origin
		self.default_revision = self.root.find('default').get('revision')
		if self.default_revision is None:
			print "default revision is empty"
			exit(1)
		else:
			print "default revision is %s" % self.default_revision

		for remote in self.root.findall('remote'):
			origin_url = remote.get('fetch')
			origin_name = remote.get('name')
			origin_dict[origin_name] = origin_url
	def get_project_commit_id(self):
		count=0
		for project in self.root.findall('project'):

			project_origin = project.get('remote')
			if project_origin is None:
				project_origin = self.default_origin

			project_revision = project.get('revision')
			if project_revision is None:
				project_revision = self.default_revision

			project_name = project.get('name')
			if project_name is None:
				print "project name is empty"
				exit(1)
			else:
				a=os.popen("git ls-remote %s/%s" % (origin_dict[project_origin],project_name))
				l = a.readlines()
				for line in iter(l):
					if re.findall(project_revision,line):
						project_commit_id=line.split()[0]
				project_name_dict[project_name] = project_commit_id
				count+=1
				sys.stdout.write(str(count))
				print "ok"
	def modified_xml(self):
		for project in self.root.findall('project'):
			project_name = project.attrib['name']
			
			project_revision = project.get('revision')
			if project_revision is None:
				project_revision = self.default_revision
			project.attrib['revision'] = project_name_dict[project_name] 
			project.attrib['upstream'] = project_revision
			self.tree.write('output1.xml')
cx = change_xml()
cx.get_project_commit_id()
cx.modified_xml()
