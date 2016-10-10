-- File             : Proj1.hs
-- Author           : Zean Qin
-- Student ID       : 604030
-- Student Username : zeanq
-- Purpose          : Solution for Project 1

-- | This code implements a number of important data types and functions that 
--   are intended to be imported as a module to complete the card guessing 
--   game. It implements the GameState data type to keep track of the possible
--   answers and the feedback, initialGuess and nextGuess functions. It also 
--   provides a number of helper functions.

module Proj1 (feedback, initialGuess, nextGuess, GameState) where

import Card
import Data.List

-- | A list of possible answers from which we draw our next guess. It is 
--   initialised in the initialGuess function to contain a list of all the 
--   answers. We use the feedback from a previous guess to filter the list and
--   then draw the next guess from it.
data GameState = GameState [[Card]] 
                 deriving (Show)

-- | Takes the answer and a guess and gives feedback based on the answer. The 
--   feedback is a tuple of five Ints. From left to right, each Int represents: 
--    1. correctCards: the number of cards in the answer that are also in the 
--       guess
--    2. lowerRanks  : the number of cards in the answer that have lower than 
--       the lowest rank in the guess
--    3. correctRanks: the number of cards in the answer that have the same 
--       ranks as a card in the guess
--    4. higherRanks : the number of cards in the answer that have ranks 
--       higher than the highest ranks in in the guess
--    5. correctSuits: the number of cards in the answer that have the same 
--       suit as a card in the guess
feedback::[Card] -> [Card] -> (Int, Int, Int, Int, Int)
feedback answer guess = (correctCards, lowerRanks, correctRanks, higherRanks, 
  correctSuits)
  where correctCards = length $ intersect answer guess
        lowerRanks = getLowerRanksCount answer guess
        correctRanks = getCorrectRanksCount answer guess
        higherRanks = getHigherRanksCount answer guess
        correctSuits = getCorrectSuitsCount answer guess

-- | Takes the number of cards in the answer as input and returns an initial 
--   guess and the gamestate
initialGuess::Int -> ([Card], GameState)
initialGuess numberOfCards = (f numberOfCards, GameState possibleAnswers)
  where possibleAnswers = getUniqueCombinations 
                          numberOfCards [minBound..maxBound::Card]
        f n
          | n == 2 = [Card Club R6, Card Diamond R10]
          | n == 3 = [Card Club R5, Card Diamond R9, Card Heart King]
          | n == 4 = [Card Club R4, Card Diamond R7, Card Heart R10, 
                     Card Spade King]

-- | Takes as input a pair of the previous guess and game state, and the 
--   feedback to this guess as a quintuple of counts of correct cards, low 
--   ranks, correct ranks, high ranks, and correct suits, and returns a pair 
--   of the next guess and new game state. 
nextGuess::([Card], GameState) -> (Int, Int, Int, Int, Int) 
           -> ([Card], GameState)
nextGuess (guess, gameState) 
          (correctCards, lowerRanks, correctRanks, higherRanks, correctSuits)
           = (getMidGuss guess gs, gs) 
  where filterByCorrectCards g correctC (GameState possibleAnswers)
          | correctC == 0 
            = GameState (filter (null.intersect g) possibleAnswers)
          | otherwise = GameState (removeGuess g (filter 
            (\a -> length (intersect a g) >= correctC) possibleAnswers))
        
        filterByLowerRanks g lowerR (GameState possibleAnswers)
          | lowerR == (length g) = GameState (filter (\a -> 
            (getHighestRank a) < (getLowestRank g)) possibleAnswers)
          | lowerR > 0 = GameState (filter (\a -> 
            (getLowestRank a) < (getLowestRank g)) possibleAnswers)
          | otherwise = GameState possibleAnswers
        
        filterByCorrectRanks g correctR (GameState possibleAnswers)
          | correctR == (length g) = GameState (filter 
            (\e -> (getRanks e) == (getRanks g)) possibleAnswers)
          | correctR > 0 = GameState (filter (\a -> 
            length (intersect (getRanks a) (getRanks g)) >= correctR) 
            possibleAnswers)
          | otherwise = GameState possibleAnswers
        
        filterByHigherRanks g higherR (GameState possibleAnswers)
          | higherR == (length g) = GameState (filter (\a -> 
            (getLowestRank a) > (getHighestRank g)) possibleAnswers)
          | higherR > 0 = GameState (filter (\a -> 
            (getHighestRank a) > (getHighestRank g)) possibleAnswers)
          | otherwise = GameState possibleAnswers
        
        filterByCorrectSuits g correctS (GameState possibleAnswers)
          | correctS == (length g) = GameState 
            (filter (\a -> (getSuits a) == (getSuits g)) possibleAnswers)
          | correctS == 0 = GameState (filter (\a -> null 
            (intersect (getSuits a) (getSuits g))) possibleAnswers)
          | otherwise = GameState (filter (\a -> length (intersect 
            (getSuits a) (getSuits g)) >= correctS) possibleAnswers)

        -- a feedback is produced by the answer and a guess. If the answer is 
        -- in the list of possible answers, we only need to keep the ones that 
        -- have the same feedback
        filterByFeedback g (correctCards, lowerRanks, correctRanks, 
          higherRanks, correctSuits) (GameState possibleAnswers) = 
          GameState $ filter (\a -> (feedback a g) == (correctCards, 
          lowerRanks, correctRanks, higherRanks, correctSuits)) possibleAnswers

        -- filter the possible answers using the filters defined above
        gs = filterByCorrectSuits guess correctSuits
             .filterByHigherRanks guess higherRanks
             .filterByCorrectRanks guess correctRanks
             .filterByLowerRanks guess lowerRanks
             .filterByCorrectCards guess correctCards
             .filterByFeedback guess (correctCards, lowerRanks, correctRanks, 
              higherRanks, correctSuits) $ gameState
        
        getMidGuss g (GameState possibleAnswers) = last possibleAnswers 


-- |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- ||                                                               ||
-- || The section below contains utilty functions                   ||
-- ||                                                               || 
-- |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||


-- | Calculates the highest rank of all cards in a guess or answer
getHighestRank :: [Card] -> Rank
getHighestRank cards = foldl (\acc e -> if (rank e > acc) 
                                        then (rank e) else acc) R2 cards

-- | Calculates the lowest rank of all cards from a list of cards
getLowestRank :: [Card] -> Rank
getLowestRank cards = foldl (\acc e -> if (rank e < acc) 
                                       then (rank e) 
                                       else acc) Ace cards

-- | Takes a list of cards as input and returns a list of their ranks sorted 
--   in asending order
getRanks :: [Card] -> [Rank]
getRanks cards = sort (map rank cards)

-- | Takes a list of cards as input and returns a list of thier suits sorted 
--   in asending order
getSuits :: [Card] -> [Suit]
getSuits cards = sort (map suit cards)

-- | Removes an answer (a list of cards) from a list of all possible answers.
--   The order of cards in an answer does not matter. For example, 
--   removeGuess [Card Club R2, Card Club R3] [[Card Club R3, Card Club R2]] 
--   will return []
removeGuess :: [Card] -> [[Card]] -> [[Card]]
removeGuess guess possibleAnswers = filter (\a -> a /= (sort guess)) 
                                           (map sort possibleAnswers)

-- | Takes a number and a list as input and returns a list of all the unique 
--   number of combinations
getUniqueCombinations :: Int -> [a] -> [[a]]
getUniqueCombinations 0 _ = [[]]
getUniqueCombinations n xs = 
  [ y:ys | y:xs' <- tails xs, ys <- getUniqueCombinations (n-1) xs']

-- | Takes the answer and a guess and returns an Int representing the number 
--   of cards in the answer that have rank lower than the lowest rank in the 
--   guess
getLowerRanksCount :: [Card] -> [Card] -> Int
getLowerRanksCount answer guess = getLowerRanksCount' (sort(map rank answer)) 
  (sort(map rank guess)) 0
  where getLowerRanksCount' [] [] count = count 
        getLowerRanksCount' [] (g:gs) count = count
        getLowerRanksCount' (a:as) [] count = count
        getLowerRanksCount' (a:as) (g:gs) count = 
          if a < g
          then getLowerRanksCount' as (g:gs) (count + 1)
          else count

-- | Takes the answer and a guess and returns a number representing the number
--   of cards in the answer that have the same rank as a card in the guess
getCorrectRanksCount :: [Card] -> [Card] -> Int
getCorrectRanksCount answer guess = getCorrectRanksCount' 
  (sort(map rank answer)) (sort(map rank guess)) 0
  where getCorrectRanksCount' [] [] count = count
        getCorrectRanksCount' [] (g:gs) count = count
        getCorrectRanksCount' (a:as) [] count = count
        getCorrectRanksCount' (a:as) (g:gs) count
          | a == g = getCorrectRanksCount' as gs (count + 1)
          | a < g = getCorrectRanksCount' as (g:gs) count
          | a > g = getCorrectRanksCount' (a:as) gs count

-- | Takes the answer and a guess and returns the number of cards in the 
--   answer have ranks higher than the highest ranks in the guess
getHigherRanksCount :: [Card] -> [Card] -> Int
getHigherRanksCount answer guess = getHigherRanksCount' 
  (reverse (sort (map rank answer))) (reverse (sort (map rank guess))) 0
  where getHigherRanksCount' [] [] count = count
        getHigherRanksCount' [] (g:gs) count = count
        getHigherRanksCount' (a:as) [] count = count
        getHigherRanksCount' (a:as) (g:gs) count = 
          if a > g
          then getHigherRanksCount' as (g:gs) (count + 1)
          else count

-- | Takes the answer and a guess and returns the number of cards in the 
--   answer that have the same rank as a card in the guess
getCorrectSuitsCount :: [Card] -> [Card] -> Int
getCorrectSuitsCount answer guess = getCorrectSuitsCount' 
  (sort(map suit answer)) (sort(map suit guess)) 0
  where getCorrectSuitsCount' [] [] count = count
        getCorrectSuitsCount' [] (g:gs) count = count
        getCorrectSuitsCount' (a:as) [] count = count
        getCorrectSuitsCount' (a:as) (g:gs) count
          | a == g = getCorrectSuitsCount' as gs (count + 1)
          | a < g = getCorrectSuitsCount' as (g:gs) count
          | a > g = getCorrectSuitsCount' (a:as) gs count

