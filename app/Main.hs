module Main where

-- run by going into main dir and running:
-- cabal run 
-- or, to automaticaly open the generated image:
-- cabal run && cd images && feh $(ls -At | head -n 1) && cd ..

import Data.List (sortBy) 
import Data.Function (on)
import Data.Complex
import Data.Time.Clock.System
import Graphics.Rendering.Chart.Easy hiding ((...))
import Graphics.Rendering.Chart.Backend.Cairo

type Angle = Double
type Power = Double
type TimeStamp = Double
type Signal = [(TimeStamp, Power)]

-- test commit

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
weights = replicate arrayLength 1.0

-- spacing of the array elements in lambda
spacing :: Double
spacing = 0.5

-- the angle the array is steering in
arraySteering :: Angle
arraySteering = (-20/180) * pi

steerings :: [Angle]
steerings = [-1, -0.5, 0, 0.5, 1]

todB :: Power -> Power
todB = (20*) . logBase 10 

-- element factor 
elementFactor :: Angle -> Power
elementFactor theta 
    | theta > -pi/2 && theta < pi/2 = (10**) . (/20) $ (1.473*theta)^4 - (4.87*theta)^2
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
-- where the input is an angle and the output is the distance
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

-- old main function for plotting only the
-- array factor and element factor
afPlot = do
    title <- ((++ ".png") . ("images/array_factor" ++) . show . systemSeconds) <$> getSystemTime
    toFile def title $ do
        layout_title .= "Array Factor"
        layout_x_axis . laxis_title .= "Output Angle (Radians)"
        layout_y_axis . laxis_title .= "Relative Output Power (dB)"
        setColors [opaque blue, opaque green, opaque red]
        plot (line "Array Factor" [zip xs y1s])
        plot (line "Element Factor" [zip xs y2s])
        plot (line "Beam" [zip xs y3s])
            where   xs = [-pi, (0.01-pi)..pi]
                    y1s = map (todB . magnitude . arrayFactor arraySteering) xs
                    y2s = map (todB . elementFactor) xs
                    y3s = map todB $ zipWith (*) 
                        (map (magnitude . arrayFactor arraySteering) xs) 
                        (map elementFactor xs)

-- simulation which only looks at amplitude 
-- of reflections (totally incorrect)
ampSim = do
    title <- ((++ ".png") . ("images/simulation" ++) . show . systemSeconds) <$> getSystemTime
    toFile def title $ do
        layout_title .= "Simulation"
        layout_x_axis . laxis_title .= "Output Angle (Radians)"
        layout_y_axis . laxis_title .= "Distance (cm)"
        setColors [opaque blue, opaque green, opaque red]
        plot (line "Perfect Room Scan" [zip xs y1s])
        plot (line "Perceived Room Scan" [zip xs y6s])
        plot (line "Perceived Room Scan (Magnified)" [zip xs $ map (*5) y6s])
            where   xs = [-pi/2, (0.01-pi/2)..pi/2]
                    -- perfect scan as list 
                    -- y1s :: [Double]
                    y1s = map perfectScan xs
                    -- list of functions with AFs for all angles
                    -- also takes the abs value
                    -- y2s :: [(Angle -> Power)]
                    y4s = map (magnitude ... arrayFactor) xs
                    -- list of lists, where every sublist is 
                    -- an AF pattern (but in list form, not function)
                    -- y5s :: [[Power]]
                    y5s = zipWith ($) (map map y4s) (repeat xs)
                    y6s = zipWith (((/ dataLength) . sum) ... (zipWith (*))) y5s (repeat y1s)
                    dataLength = fromIntegral $ length xs

-- perfect simulation looking at time 
-- it takes for signals to reflect 
-- this assumes: signal don't get weaker
perfectTimeSim = do
    title <- ((++ ".png") . ("images/simulation" ++) . show . systemSeconds) <$> getSystemTime
    toFile def title $ do
        layout_title .= "Simulation"
        layout_x_axis . laxis_title .= "Output Angle (Radians)"
        layout_y_axis . laxis_title .= "Distance (cm)"
        setColors [opaque blue, opaque green, opaque red]
        plot (line "Perfect Room Scan" [zip xs y1s])
        plot (line "Perceived Room Scan" [zip xs y7s])
            where   xs = [-pi/2, (0.01-pi/2)..pi/2]
                    -- perfect scan as list 
                    -- y1s :: [Double]
                    y1s = map perfectScan xs
                    -- list of functions with AFs for all angles
                    -- also takes the abs value
                    -- y2s :: [(Angle -> Power)]
                    y4s = map (magnitude ... arrayFactor) xs
                    -- list of lists, where every sublist is 
                    -- an AF pattern (but in list form, not function)
                    -- y5s :: [[Power]]
                    y5s = zipWith ($) (map map y4s) (repeat xs)

                    -- generate pairings of AFs with delays
                    -- returns a [Signal], a list of Signals
                    -- each corresponding to an AF
                    y6s = map (zip y1s) y5s
                    -- for every signal, get its peek
                    -- and use that timestamp as plotting value
                    y7s = map (fst . signalPeak) y6s

timeSim = do
    title <- ((++ ".png") . ("images/simulation" ++) . show . systemSeconds) <$> getSystemTime
    toFile def title $ do
        layout_title .= "Simulation"
        layout_x_axis . laxis_title .= "Output Angle (Radians)"
        layout_y_axis . laxis_title .= "Distance (cm)"
        setColors [opaque blue, opaque green, opaque red, opaque orange, opaque purple]
        plot (line "Perfect Room Scan" [zip xs perfScan])
        plot (line "Perceived Room Scan (Linear Loss)"      [zip xs reflectionLinear])
        plot (line "Perceived Room Scan (Quadratic Loss)"   [zip xs reflectionQuadratic])
        plot (line "Perceived Room Scan (Cubic Loss)"       [zip xs reflectionCubic])
        plot (line "Perceived Room Scan (Quartic Loss)"     [zip xs reflectionQuartic])
            where   xs = [-pi/2, (0.01-pi/2)..pi/2]
                    -- perfect scan as list 
                    -- y1s :: [Double]
                    perfScan = map perfectScan xs
                    -- list of functions with AFs for all angles
                    -- also takes the abs value
                    -- y2s :: [(Angle -> Power)]
                    afFuncs = map (magnitude ... arrayFactor) xs
                    -- list of lists, where every sublist is 
                    -- an AF pattern (but in list form, not function)
                    -- y5s :: [[Power]]
                    afLists = zipWith ($) (map map afFuncs) (repeat xs)

                    -- the elements of afLists but accounted for signal loss
                    -- signal loss irl is 1/r^4, but we simulate for other powers too
                    reflectedAFsLinear      = map (zipWith (\x y -> (500 * y)/x) perfScan) afLists
                    reflectedAFsQuadratic   = map (zipWith (\x y -> (500 * y)/(x^2)) perfScan) afLists
                    reflectedAFsCubic       = map (zipWith (\x y -> (500 * y)/(x^3)) perfScan) afLists
                    reflectedAFsQuartic     = map (zipWith (\x y -> (500 * y)/(x^4)) perfScan) afLists

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


main = timeSim
