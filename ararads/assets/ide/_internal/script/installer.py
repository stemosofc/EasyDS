import subprocess
import threading
from zipfile import ZipFile
from script.arduino import ArduinoCli

arduinocli = ArduinoCli()

def checklib():
    install = arduinocli.coreList()
    print(install.stdout)
    print(install.stderr)
    
    core = arduinocli.core.replace("@", " ").split()
    if core[0] and core[1] not in install.stdout.lower().split():
        arduinocli.coreInstall(arduinocli.core)
        
    library = arduinocli.libList()
    
    print(library.stdout)
    print(library.stderr)
    
    result = arduinocli.libInstall("EasySTEAM")
    
    print(result.stdout)
    print(result.stderr)
    
    changeimulib()
    

def changeimulib():
    arduinocli.changeIMULib()
    threading.Thread(target=installESP32Driver, daemon=True).start()
        

def installESP32Driver():
    drivers = subprocess.run("driverquery", capture_output=True, shell=True, text=True)
    if not ("Silicon Labs CP210x" in drivers.stdout):
        arduinocli.installDriver()

# deps = subprocess.run("Arduino\\arduino-cli lib deps Arara", text=True, capture_output=True)
# print(deps.stdout)
# output = deps.stdout.split()
# print(output)
# for i in range(output.__len__()):
#    if "must" in output[i]:
#        library = str(output[i-2]) + "@"
#        version = str(output[i-1].removeprefix(r"\x1b[0m"))
#        preffix = " " + library + version
#        print(preffix)
#       command = "Arduino\\arduino-cli lib install" + preffix
#        subprocess.run(command)

threading.Thread(target=checklib, daemon=True).start()
