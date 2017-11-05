import os
import json
import subprocess
from occam import Occam

# Get information about object
object = Occam.load()

# Gather paths
scripts_path    = os.path.dirname(__file__)
job_path        = os.getcwd()
object_path = "/occam/%s-%s" % (object.id(), object.revision())

dependencies = object.dependencies()
matlab = dependencies[0]
matlab_dir = "/occam/%s-%s"%(matlab.get("id"),matlab.get("revision"))

matlab_app = os.path.join(matlab_dir,"MATLAB","R2014b","bin");

hot_lib_path = os.path.join(object_path, "HOT")
utility_path = os.path.join(object_path, "utility")

#Defining OCCAM expected output file and its path
output_file = object.output_path(type="application/jpeg", output_directory='new_output', output_file="f1.jpeg")
output_generated_file = object.output_generated_path(type="application/jpeg", output_directory='new_output', output_file="f1.jpeg")

print("output_path: %s"%(output_file))

#Loading OCCAM parameters into a configuration file that will be read by the matlab simulation script
sim_config = object.configuration("Simulation configuration")
sim_config_file = object.configuration_file("Simulation configuration")

#Defining Matlab actvation ini file
with open(os.path.join(matlab_app, "matlab2014Activate.ini"),"w") as of:
    of.write("isSilent=true\n")
    of.write("licenseFile=%s/%s\n" %(object_path,"license.lic"))
    of.write("activateCommand=activateOffline\n")
    of.write("activationKey=\n")
    of.write("installLicenseFileDir=\n")
    of.write("installLicenseFileName=\n")

# Setup run command /tmp/aws_root.log
run_sim_command = [
    "cp -f %s %s; "%(sim_config_file,object_path),
    "cd  %s;  "%("/occam"),
    "cd  %s;  "%(matlab_app),
    "cat %s;  "%("matlab2014Activate.ini"),
    "sh  %s;  "%("activate_matlab.sh -propertiesFile matlab2014Activate.ini"),
    "cp -r /root/.matlab /local/.; ",
    "cd  %s;  "%(os.path.join(object_path)),
    "echo  %s;"%("About to run matlab script"),
    "%s -nodisplay -nosplash -r 'try, cd utility; install; cd run SpatialKineticsOpenSourceMain.m; catch e, disp(getReport(e)); end, quit force' | tee matlab_output.log;"%(os.path.join(matlab_app,"matlab")),
    "cat  matlab_output.log;",
    "date;  ",
    "stat f1.jpeg;  ",
    "echo  %s;"%("After matlab script"),
    "echo output path is %s;"%(output_file),
    "cp -f %s %s;"%("f1.jpeg", output_file),
    "cp -f %s %s;"%("f1.jpeg", output_generated_file)
]

command= ' '.join(run_sim_command)

# Pass run command to OCCAM
subprocess.Popen(command, shell=True)
