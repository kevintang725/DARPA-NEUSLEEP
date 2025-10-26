#define PULSE_PIN 9  // Output pin for the pulses
#define PULSE_PERIOD 10  // Pulse period in milliseconds (100Hz)
#define PULSE_DURATION 30 * 1000  // 30 seconds in milliseconds
#define INTERVAL 10 * 60 * 1000  // 10 minutes in milliseconds
#define MAX_PULSE_COUNT 80  // Limit to 80 pulse trains

bool running = false;  // Flag to check if the process has started
unsigned long lastTriggerTime = 0;
unsigned long pulseStartTime = 0;
bool trainActive = false;
bool pulseState = false;
unsigned long lastPulseTime = 0;
int pulseTrainCount = 0;  // Count completed 30s pulse trains

void setup() {
    pinMode(PULSE_PIN, OUTPUT);
    digitalWrite(PULSE_PIN, LOW);
    Serial.begin(9600);
    Serial.println("Enter 'START' to begin the pulse sequence.");
}

void loop() {
    // Check for serial input
    if (Serial.available()) {
        String command = Serial.readStringUntil('\n');
        command.trim();  // Remove leading/trailing whitespace
        if (command.equalsIgnoreCase("START")) {
            running = true;
            lastTriggerTime = millis();  // Initialize the first trigger time
            pulseTrainCount = 0;  // Reset count in case of restart
            Serial.println("Pulse sequence started.");
        }
    }

    if (running && pulseTrainCount < MAX_PULSE_COUNT) {
        unsigned long currentMillis = millis();

        // Check if 10 minutes have passed since the last train
        if (!trainActive && (currentMillis - lastTriggerTime >= INTERVAL)) {
            Serial.print("Starting 30s pulse train #");
            Serial.println(pulseTrainCount + 1);
            trainActive = true;
            pulseStartTime = currentMillis;
            lastPulseTime = currentMillis;
            lastTriggerTime = currentMillis;  // Reset the 10-minute interval
        }

        // If within the 30-second train period, generate pulses at 100Hz
        if (trainActive) {
            if (currentMillis - pulseStartTime < PULSE_DURATION) {
                if (currentMillis - lastPulseTime >= PULSE_PERIOD / 2) {
                    pulseState = !pulseState;
                    digitalWrite(PULSE_PIN, pulseState);
                    lastPulseTime = currentMillis;
                }
            } else {
                // End the pulse train
                digitalWrite(PULSE_PIN, LOW);
                trainActive = false;
                pulseTrainCount++;
                Serial.print("Pulse train #");
                Serial.print(pulseTrainCount);
                Serial.println(" completed.");
                
                // Stop if the limit is reached
                if (pulseTrainCount >= MAX_PULSE_COUNT) {
                    Serial.println("Maximum pulse train count (80) reached. Stopping.");
                    running = false;
                }
            }
        }
    }
}
