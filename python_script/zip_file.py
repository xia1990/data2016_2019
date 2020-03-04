#!/usr/bin/python
import zipfile
import os
def make_zip(source_dir,output_filename):
    zipf=zipfile.ZipFile(output_filename,'w')
    top_dir_len=len(os.path.dirname(source_dir))
    for path,sondir,filenames in os.walk(source_dir):
        if filenames:
            for filename in filenames:
                print filename
                zipf.write(path[top_dir_len:]+os.path.sep+filename)
                #zipf.write(path+os.path.sep+filename)
    zipf.close()


make_zip('test','test.zip')

