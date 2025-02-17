from subprocess import run, CREATE_NEW_CONSOLE
from pathlib import Path
from termcolor import cprint
from zipfile import ZipFile
from os import startfile

onedrive = True

class ArduinoCli:
    
    
    def __init__(self):
        currentdir = Path(Path.cwd())
        pathtofile = currentdir / "Arduino"
        
        if pathtofile.exists():
            pathtoarduinofolder = pathtofile
        else:
            pathtoarduinofolder = currentdir / "_internal" / "Arduino"
            
        self.arduinocli = (pathtoarduinofolder / "arduino-cli.exe")
        self.sketchfolder = pathtoarduinofolder / "sketches"
        self.fbqn = "esp32:esp32:esp32:UploadSpeed=115200,FlashSize=16M,PartitionScheme=app3M_fat9M_16MB"
        self.baudrate = 115200
        self.core = "esp32:esp32@2.0.17"
        
        cprint(f"{self.arduinocli}", 'yellow')
        cprint(f"{self.sketchfolder}", 'yellow')
        
        
    def runCommand(self, command, textout=True, capture=True, newConsole=False):
        cprint(f"{command}", 'green')
        return run(f"{command}", text=textout, capture_output=capture)

    
    def runCommandNewConsole(self, command):
        return run(f"{command}", creationflags=CREATE_NEW_CONSOLE)
    
        
    def createSketch(self, name):
        return self.runCommand(f"\"{self.arduinocli}\" sketch new \"{self.sketchfolder / name}\"")

    
    def compileSketch(self, name):
        return self.runCommand(f"\"{self.arduinocli}\" compile --fqbn {self.fbqn} \"{self.sketchfolder / name}\"")
    
    
    def uploadSketch(self, porta, name):
        return self.runCommand(f"\"{self.arduinocli}\" upload -p {porta} --fqbn {self.fbqn} \"{self.sketchfolder / name}\"")
    
    
    def openSerialComm(self, porta):
        return self.runCommandNewConsole(f"\"{self.arduinocli}\" monitor -p {porta} -b {self.fbqn} --config {self.baudrate} --timestamp")


    def writeCode(self, name, code):
        file = Path(self.sketchfolder, name, f"{name}.ino")
        
        with open(file, "w") as content:
            content.write(code)

    
    def saveBlockly(self, name, data):
        file = Path(self.sketchfolder, name, f"{name}.txt")
        
        with open(file, "w") as content:
            content.write(data)
            
            
    def coreList(self):
        return self.runCommand(f"\"{self.arduinocli}\" core list")
        
    
    def coreInstall(self, core):
        return self.runCommand(f"\"{self.arduinocli}\" core install {core}")
            
    
    def coreUninsatall(self, core):
        return self.runCommand(f"\"{self.arduinocli}\" core uninstall {core}")
    
    
    def libList(self):
        return self.runCommand(f"\"{self.arduinocli}\" lib list")
    
    
    def libInstall(self, library):
        return self.runCommand(f"\"{self.arduinocli}\" lib install {library}")
    
    
    def libUninstall(self, library):
        return self.runCommand(f"\"{self.arduinocli}\" lib uninstall {library}")
    
    
    def coreUninstall(self, core):
        return self.runCommand(f"\"{self.arduinocli}\" core uninstall {core}")
    
    
    def changeIMULib(self):
        home = Path.home()
        self.pathtolibrary = home / "Documents" / "Arduino" / "libraries"
        if not self.pathtolibrary.exists():
            self.pathtolibrary = home / "Documentos" / "Arduino" / "libraries"
            if onedrive and (not self.pathtolibrary.exists()):
                self.pathtolibrary = home / "OneDrive" / "Documentos" / "Arduino" / "libraries"
                
        pathtoimulib = Path(self.pathtolibrary, "SparkFun_9DoF_IMU_Breakout_-_ICM_20948_-_Arduino_Library", "src", "util", "ICM_20948_C.h")
        try:
            with open(pathtoimulib, "r") as file:
                content = file.read()
                content = content.replace("//#define ICM_20948_USE_DMP", "#define ICM_20948_USE_DMP")
            with open(pathtoimulib, "w") as file:
                file.write(content)
        except:
            cprint(f"Não foi possível achar a biblioteca de IMU em {pathtoimulib}", "red")
            
    
    def installDriver(self):
        zippath = Path.cwd() / "_internal" / "driver" / "CP210x_VCP_Windows.zip"
        if not zippath.exists():
            zippath = Path.cwd() / "output" / "EasySTEAM" / "EasySTEAM_IDE" / "_internal" / "driver" / "CP210x_VCP_Windows.zip"
        if zippath.exists():
            with ZipFile(zippath.resolve(), 'r') as zip:
                zip.extractall(zippath.parent)
        else:
            cprint(f"Não foi possível achar a pasta de driver da placa em {zippath}", "red")
            return
        vcppath = zippath.parent / "CP210x_VCP_Windows" / "CP210xVCPInstaller_x64.exe"
        cprint(vcppath, 'yellow')
        startfile(vcppath)
