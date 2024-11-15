import 'package:flutter/foundation.dart';
import 'package:xinput_gamepad/xinput_gamepad.dart';
class Joystick {
  List<Controller> availableControllers = List.empty(growable: true);
  List<Map<String, dynamic>> jsonArray = List.empty(growable: true);
  final maxValueJoystick = 32767;
  final maxValueTrigger = 255;

  void initialize() {
    XInputManager.enableXInput();
    XInputManager.inputLag = 5;
    for (int controllerIndex in ControllersManager.getIndexConnectedControllers()) {
      final Controller controller = Controller(index: controllerIndex, buttonMode: ButtonMode.PRESS, 
      leftThumbDeadzone: 0, rightThumbDeadzone: 0, triggersDeadzone: 0);
      jsonArray.add({
        "INDEX": controllerIndex,
        "LY": 0,
        "LX": 0,
        "RX": 0,
        "RY": 0,
        "B": false,
        "X": false,
        "Y": false,
        "A": false,
        "RT": 0,
        "LT": 0
      });
      controller.buttonsMapping = {
        ControllerButton.A_BUTTON: () => {
          updateControllerData(controllerIndex, "A", true)
        },
        ControllerButton.B_BUTTON: () => {
          updateControllerData(controllerIndex, "B", true)
        },
        ControllerButton.X_BUTTON: () => {
          updateControllerData(controllerIndex, "X", true)
        },
        ControllerButton.Y_BUTTON: () => {
          updateControllerData(controllerIndex, "Y", true)
        },
      };
      controller.variableKeysMapping = {
        VariableControllerKey.LEFT_TRIGGER: (value) =>
        updateControllerData(controllerIndex, "LT", normalizeJoystickValue(value, maxValueTrigger)),
        VariableControllerKey.RIGHT_TRIGGER: (value) => 
        updateControllerData(controllerIndex, "RT", normalizeJoystickValue(value, maxValueTrigger)),
        VariableControllerKey.THUMB_LX: (value) => 
        updateControllerData(controllerIndex, "LX", normalizeJoystickValue(value, maxValueJoystick)),
        VariableControllerKey.THUMB_LY: (value) =>
        updateControllerData(controllerIndex, "LY", normalizeJoystickValue(value, maxValueJoystick)),
        VariableControllerKey.THUMB_RX: (value) =>
        updateControllerData(controllerIndex, "RX", normalizeJoystickValue(value, maxValueJoystick)),
        VariableControllerKey.THUMB_RY: (value) =>
        updateControllerData(controllerIndex, "RY", normalizeJoystickValue(value, maxValueJoystick)),
      };
      controller.onReleaseButton = (button) => {
        switch(button.toString()){
          "[ControllerButton.A_BUTTON]" => {
            updateControllerData(controllerIndex, "A", false)
          },
          "[ControllerButton.B_BUTTON]" => {
            updateControllerData(controllerIndex, "B", false)
          },
          "[ControllerButton.X_BUTTON]" => {
            updateControllerData(controllerIndex, "X", false)
          },
          "[ControllerButton.Y_BUTTON]" => {
            updateControllerData(controllerIndex, "Y", false)
          },
          _ => debugPrint("não valido"),
        }
      };

      availableControllers.add(controller);
    }

    print("Available controllers:");
    for (Controller controller in availableControllers) {
      print("Controller ${controller.index}");
    }

    for (Controller controller in availableControllers) {
      controller.listen();
    }
  }

  double normalizeJoystickValue(int value, int maxValue) {
    if (value.abs() > maxValue) {
      value = value.sign * maxValue;
    }
    return applyDeadZoneWithScaling(value / maxValue, 0.25);
  }

  double applyDeadZoneWithScaling(double value, double deadZone) {
    if (value.abs() < deadZone) {
      return 0.0;
    }
    double scale = (value.abs() - deadZone) / (1 - deadZone);
    scale = scale.clamp(0.0, 1.0);
    return value.isNegative ? -scale : scale;
  }

  void updateControllerData(int controllerIndex, String jsonField, var value){
    for (var json in jsonArray) {
      if (json['INDEX'] == controllerIndex) {
        json[jsonField] = value;
      }
    }
  }

  void printjsons(){
    print(jsonArray.toString());
  }
}