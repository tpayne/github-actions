#!/usr/bin/env python

import sys
from dataclasses import dataclass
from pathlib import Path, PurePath
import yaml

if len(sys.argv) < 5:
    print('Usage: <inputYaml> <outputYaml> <componentTask> <newVersion>')
    sys.exit(1)
    
inputFile = sys.argv[1]
outputFile = sys.argv[2]
taskStr = sys.argv[3]
versionStr = str(sys.argv[4])
attrStr = "version"

@dataclass
class EnvTemp:
	def __init__(self, **entries):
		self.__dict__.update(entries)

class IndentDumper(yaml.Dumper):
    def increase_indent(self, flow=False, indentless=False):
        return super(IndentDumper, self).increase_indent(flow, False)
#
# Restrictions - This currently kills comments
#
inTemplate = Path(inputFile) 
if inTemplate.is_file(): 
  with inTemplate.open() as f:
    dataMap = yaml.safe_load(f)
    x = EnvTemp(**dataMap)
    if taskStr in x.tasks:
      x.tasks[taskStr][attrStr] = str(versionStr)
      outFile = Path(outputFile)
      if len(outFile.parents) > 1:
        p = Path(outFile.parent.as_posix()+'/')
        if not p.exists():
          p.mkdir(parents=True, exist_ok=True)
      with open(outputFile, "w") as t:
        yaml.emitter.Emitter.prepare_tag = lambda self, tag: ''
        print('--> Updating "'+taskStr+'" to version "'+
              versionStr+'" in "'+outputFile+'"...')
        yaml.dump(x,t,sort_keys=False,Dumper=IndentDumper)
    else:
      print('Error: Specified task "' + taskStr + 
            '" was not found in template "'+ inputFile + '"')
      sys.exit(1)
else:
  print('Error: Specified file "' + inputFile + '" does not exist')
  sys.exit(1)
      
sys.exit(0)
