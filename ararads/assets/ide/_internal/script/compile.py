import os
import subprocess
from script.arduino import ArduinoCli


arduinocli = ArduinoCli()


def create_skecth(data, server):
    name = data["name"]
    code = data["code"]

    result = arduinocli.createSketch(name)
    print(result.stdout)
    print(result.stderr)
    
    if "Error creating sketch: Can't create sketch: .ino file already exists" in result.stderr:
        result.stderr = "We writing code to already existent file\n"
        
    server.emit("output", {"data":result.stdout, "error" : result.stderr})
    server.sleep(0)
    
    arduinocli.writeCode(name, code)
    arduinocli.saveBlockly(name, data["blockly"])
    
    server.emit("output", {"data":"Compiling... wait a time\n", "error" : ''})
    server.sleep(0)
    
    compile(name, server)
    

def compile(name, server):
    result = arduinocli.compileSketch(name)
    
    print(result.stdout)
    print(result.stderr)
    
    server.emit("output", {"data":result.stdout, "error" : result.stderr})
    server.sleep(0)


def getCOMport():
    dispositivos = subprocess.run("powershell.exe \"Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match '^USB' }\"", capture_output=True, text=True)    
    result = dispositivos.stdout.lower()
    if "silicon labs cp210x" in result :
        devices = result.split()
        for i in range(devices.__len__()):
            if "com" in devices[i]:
                if any(map(str.isdigit, devices[i])):
                    porta = devices[i].replace("(", "").replace(")", "").upper()
                    return porta
    return "Not COM port found"
    
    
def upload(name, server):
    global outputStream
    porta = getCOMport()
    if porta != "Not COM port found":
        server.emit("output", {"data":"Uploading... Wait a time\n", "error" : ""})
        server.sleep(0)

        result = arduinocli.uploadSketch(porta, name)
        
        print(result.stdout)
        print(result.stderr)
        
        server.emit("output", {"data":result.stdout, "error" : result.stderr})
        server.sleep(0)
    else:
        server.emit("output", {"data":"", "error" : "Not COM port found, check Arara connection!\n"})
        server.sleep(0)


def openSerial():
    arduinocli.openSerialComm(porta=getCOMport())
