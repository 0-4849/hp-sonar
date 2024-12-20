type Angle = Double

numberOfSignals :: Integer
numberOfSignals = 10

phaseShift :: Angle
phaseShift = 100

clockFrequency = 16000000

waveFrequency = 40000

cyclesPerPeriod = clockFrequency / waveFreqcuency

instructions = cycle $ take (cyclesPerPeriod / 2) [0, 0..] ++ take (cyclesPerPeriod / 2) [1, 1..]


