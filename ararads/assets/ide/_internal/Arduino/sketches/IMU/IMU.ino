#include<EasySTEAM.h>

void setup() {
  easySTEAM.start();
  imu.init();
  Serial.begin(115200);
}
void loop() {
  Serial.print("Yaw: ");
  Serial.println(imu.getYaw());
}