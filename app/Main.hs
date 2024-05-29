module Main where

-- run by going into main dir and running:
-- cabal run 
-- or, to automaticaly open the generated image:
-- cabal run && cd images && feh $(ls -At | head -n 1) && cd ..

import Data.List (sortBy, transpose) 
import Data.Function (on)
import Data.Complex
import Data.Time.Clock.System
import Graphics.Rendering.Chart.Easy hiding ((...))
import Graphics.Rendering.Chart.Backend.Diagrams

type Angle = Double
type Power = Double
type TimeStamp = Double
type Signal = [(TimeStamp, Power)]

-- convenience function for composing higher-order functions
-- is equivalent to (.).(.) for functions or 
-- fmap fmap fmap for all functors
-- but this is most readable
(...) :: (Functor f1, Functor f2) => (a -> b) -> f1 (f2 a) -> f1 (f2 b)
(...) = fmap . fmap

-- array length
arrayLength :: Int
arrayLength = 10

-- weights/coelementFactorficients/excitation of the element arrays
weights :: [Complex Double]
weights = replicate arrayLength 1.0

-- spacing of the array elements in lambda
spacing :: Double
spacing = 0.5

todB :: Power -> Power
todB = (20*) . logBase 10 

-- element factor 
elementFactor :: Angle -> Power
elementFactor theta 
    | theta > -pi/2 && theta < pi/2 = (10**) . (/20) $ (1.473*theta) ^ (4 :: Integer) - (4.87*theta) ^ (2 :: Integer)
    | otherwise =  10.0 ** (-1.5)


-- array factor as a function
arrayFactor :: Angle -> Angle ->  Complex Power
arrayFactor steering theta = (/ fromIntegral arrayLength)
    . sum 
    . zipWith (*) weights 
    $ map
        ( exp 
        . (0 :+) 
        . (2 * pi * spacing * (sin theta - sin steering) *) 
        . fromIntegral)
    [0..(arrayLength - 1)]

-- a theoretically perfect scan of a room 
-- where the input is an angle and the output is the distance/time
-- between the observer/TX/RX
-- the output has an arbitrary range
perfectScan :: Angle -> Double
perfectScan theta
    | theta < -pi/3 = 8.0
    | theta < -pi/6 = 3.0 
    | theta < pi/6 = 10.0
    | theta < pi/3 = 10 * theta
    | otherwise = 3.0

signalPeak:: Signal -> (TimeStamp, Power)
signalPeak = last . sortBy (compare `on` snd) 

angles :: [Angle]
angles = [-pi/2, (0.01-pi/2)..pi/2]

-- perfect scan as list
perfScan :: [Double]
perfScan = map perfectScan angles

-- list of functions with AFs for all angles
-- also takes the abs value
afFuncs :: [Angle -> Power]
afFuncs = map (magnitude ... arrayFactor) angles

-- list of lists, where every sublist is
-- an AF pattern (but in list form, not function)
afLists :: [[Power]]
afLists = zipWith map afFuncs (repeat angles)


-- function for plotting only the
-- array factor and element factor
afPlot :: IO ()
afPlot = do
    title <- ((++ ".png") . ("images/array_factor" ++) . show . systemSeconds) <$> getSystemTime
    toFile def title $ do
        layout_title .= "Array Factor"
        layout_x_axis . laxis_title .= "Output Angle (Radians)"
        layout_y_axis . laxis_title .= "Relative Output Power (dB)"
        setColors [opaque blue, opaque green, opaque red]
        plot (line "Array Factor" [zip angles y1s])
        plot (line "Element Factor" [zip angles y2s])
        plot (line "Beam" [zip angles y3s])
            where   -- the angle the array is steering in
                    arraySteering :: Angle
                    arraySteering = (-20/180) * pi
                    y1s = map (todB . magnitude . arrayFactor arraySteering) angles
                    y2s = map (todB . elementFactor) angles
                    y3s = map todB $ zipWith (*) 
                        (map (magnitude . arrayFactor arraySteering) angles) 
                        (map elementFactor angles)

-- simulation which only looks at amplitude 
-- of reflections (totally incorrect)
ampSim :: IO ()
ampSim = do
    title <- ((++ ".png") . ("images/simulation" ++) . show . systemSeconds) <$> getSystemTime
    toFile def title $ do
        layout_title .= "Simulation"
        layout_x_axis . laxis_title .= "Output Angle (Radians)"
        layout_y_axis . laxis_title .= "Distance (cm)"
        setColors [opaque blue, opaque green, opaque red]
        plot (line "Perfect Room Scan" [zip angles perfScan])
        plot (line "Perceived Room Scan" [zip angles y6s])
        plot (line "Perceived Room Scan (Magnified)" [zip angles $ map (*5) y6s])
            where   y6s = zipWith (((/ dataLength) . sum) ... (zipWith (*))) afLists (repeat perfScan)
                    dataLength = fromIntegral $ length angles

-- perfect simulation looking at time 
-- it takes for signals to reflect 
-- this assumes: signal don't get weaker
perfectTimeSim :: IO ()
perfectTimeSim = do
    title <- ((++ ".png") . ("images/simulation" ++) . show . systemSeconds) <$> getSystemTime
    toFile def title $ do
        layout_title .= "Simulation"
        layout_x_axis . laxis_title .= "Output Angle (Radians)"
        layout_y_axis . laxis_title .= "Distance (cm)"
        setColors [opaque blue, opaque green, opaque red]
        plot (line "Perfect Room Scan" [zip angles perfScan])
        plot (line "Perceived Room Scan" [zip angles y7s])
            where   -- generate pairings of AFs with delays
                    -- returns a [Signal], a list of Signals
                    -- each corresponding to an AF
                    y6s = map (zip perfScan) afLists
                    -- for every signal, get its peek
                    -- and use that timestamp as plotting value
                    y7s = map (fst . signalPeak) y6s

timeSim :: IO ()
timeSim = do
    title <- ((++ ".png") . ("images/simulation" ++) . show . systemSeconds) <$> getSystemTime
    toFile def title $ do
        layout_title .= "Simulation"
        layout_x_axis . laxis_title .= "Output Angle (Radians)"
        layout_y_axis . laxis_title .= "Distance (cm)"
        setColors [opaque blue, opaque green, opaque red, opaque orange, opaque purple]
        plot (line "Perfect Room Scan" [zip angles perfScan])
        plot (line "Perceived Room Scan (Linear Loss)"      [zip angles reflectionLinear])
        plot (line "Perceived Room Scan (Quadratic Loss)"   [zip angles reflectionQuadratic])
        plot (line "Perceived Room Scan (Cubic Loss)"       [zip angles reflectionCubic])
        plot (line "Perceived Room Scan (Quartic Loss)"     [zip angles reflectionQuartic])
            where   -- the elements of afLists but accounted for signal loss
                    -- signal loss irl is 1/r^4, but we simulate for other powers too
                    reflectedAFsLinear      = map (zipWith (\x y -> (500 * y) / x) perfScan) afLists
                    reflectedAFsQuadratic   = map (zipWith (\x y -> (500 * y) / x^(2 :: Integer)) perfScan) afLists
                    reflectedAFsCubic       = map (zipWith (\x y -> (500 * y) / x^(3 :: Integer)) perfScan) afLists
                    reflectedAFsQuartic     = map (zipWith (\x y -> (500 * y) / x^(4 :: Integer)) perfScan) afLists

                    -- generate pairings of AFs with delays
                    -- returns a [Signal], a list of Signals
                    -- each corresponding to an AF
                    reflectedSignalsLinear      = map (zip perfScan) reflectedAFsLinear
                    reflectedSignalsQuadratic   = map (zip perfScan) reflectedAFsQuadratic
                    reflectedSignalsCubic       = map (zip perfScan) reflectedAFsCubic
                    reflectedSignalsQuartic     = map (zip perfScan) reflectedAFsQuartic

                    -- for every signal, get its peek
                    -- and use that timestamp as plotting value
                    reflectionLinear    = map (fst . signalPeak) reflectedSignalsLinear 
                    reflectionQuadratic = map (fst . signalPeak) reflectedSignalsQuadratic
                    reflectionCubic     = map (fst . signalPeak) reflectedSignalsCubic
                    reflectionQuartic   = map (fst . signalPeak) reflectedSignalsQuartic

timeAmpSim :: IO ()
timeAmpSim = do
    title <- ((++ ".svg") . ("images/simulation" ++) . show . systemSeconds) <$> getSystemTime
    toFile def title $ do
        layout_title .= "Simulation"
        layout_x_axis . laxis_title .= "Output Angle (Radians)"
        layout_y_axis . laxis_title .= "Distance (cm)"
        setColors [opaque blue, opaque green, opaque red, opaque orange, opaque purple]
        plot (line "Perfect Room Scan" [zip angles perfScan])
        plot (line "Perceived Room Scan (Linear Loss)"      [zip angles reflectionLinear])
        plot (line "Perceived Room Scan (Quadratic Loss)"      [zip angles reflectionQuadratic])
        plot (line "Perceived Room Scan (Linear, better analysis)"   [y2s])
        plot (line "Perceived Room Scan (Quadratic, better analysis)"   [y4s])
            where   
                    -- the elements of afLists but accounted for signal loss
                    -- signal loss irl is 1/r^4 (or 1/r^2?), but we simulate for other powers too
                    -- reflectedAFsLinear :: [[Power]]
                    reflectedAFsLinear      = map (zipWith (\x y -> (500 * y) / x) perfScan) afLists
                    reflectedAFsQuadratic   = map (zipWith (\x y -> (500 * y) / x^(2 :: Integer)) perfScan) afLists
                    reflectedAFsCubic       = map (zipWith (\x y -> (500 * y) / x^(3 :: Integer)) perfScan) afLists
                    reflectedAFsQuartic     = map (zipWith (\x y -> (500 * y) / x^(4 :: Integer)) perfScan) afLists

                    -- generate pairings of AFs with delays
                    -- returns a [Signal], a list of Signals
                    -- each corresponding to an AF
                    reflectedSignalsLinear      = map (zip perfScan) reflectedAFsLinear
                    reflectedSignalsQuadratic   = map (zip perfScan) reflectedAFsQuadratic
                    reflectedSignalsCubic       = map (zip perfScan) reflectedAFsCubic
                    reflectedSignalsQuartic     = map (zip perfScan) reflectedAFsQuartic

                    -- use a different signal analysis method for plotting
                    -- on the y-axis which looks at the peak angle
                    -- reflectedAFsLinear has format where the outer index is time, and the inner is angle,
                    -- here we transpose this to obtain a format where we have a lists of amplitudes corresponding to angles, 
                    -- in a list of where index is time
                    y1s = transpose reflectedAFsLinear
                    peak signal 
                        = map fst 
                        . filter ((>0) . snd) 
                        . filter ((>= 1 * maximum signal) . snd) 
                        $ zip angles signal

                    y2s = concat . zipWith (\t -> map (flip (,) t)) perfScan $ map peak y1s

                    y3s = transpose reflectedAFsQuadratic
                    y4s = concat . zipWith (\t -> map (flip (,) t)) perfScan $ map peak y3s



                    reflectionLinear    = map (fst . signalPeak) reflectedSignalsLinear
                    reflectionQuadratic = map (fst . signalPeak) reflectedSignalsQuadratic
                    reflectionCubic     = map (fst . signalPeak) reflectedSignalsCubic
                    reflectionQuartic   = map (fst . signalPeak) reflectedSignalsQuartic

main :: IO ()
main = timeAmpSim
