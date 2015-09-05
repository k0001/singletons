{-# LANGUAGE DataKinds, PolyKinds, TypeFamilies, GADTs, TypeOperators,
             DefaultSignatures, ScopedTypeVariables, InstanceSigs #-}

module ByHand2 where

import Prelude hiding ( Eq(..), Ord(..) )
import Data.Singletons
import Data.Proxy

data Nat = Zero | Succ Nat

class Eq a where
  (==) :: a -> a -> Bool
  (/=) :: a -> a -> Bool
  infix 4 ==, /=

  x == y = not (x /= y)
  x /= y = not (x == y)

instance Eq Nat where
  Zero == Zero = True
  Zero == Succ _ = False
  Succ _ == Zero = False
  Succ x == Succ y = x == y

data instance Sing (b :: Bool) where
  SFalse :: Sing 'False
  STrue  :: Sing 'True

data instance Sing (n :: Nat) where
  SZero :: Sing 'Zero
  SSucc :: Sing n -> Sing ('Succ n)

type family Not (x :: Bool) :: Bool where
  Not 'True = 'False
  Not 'False = 'True

sNot :: Sing b -> Sing (Not b)
sNot STrue = SFalse
sNot SFalse = STrue

infix 4 :==, :/=
class kproxy ~ 'KProxy => PEq (kproxy :: KProxy a) where
  type (:==) (x :: a) (y :: a) :: Bool
  type (:/=) (x :: a) (y :: a) :: Bool

  type x :== y = Not (x :/= y)
  type x :/= y = Not (x :== y)

instance PEq ('KProxy :: KProxy Nat) where
  type 'Zero :== 'Zero = 'True
  type 'Succ x :== 'Zero = 'False
  type 'Zero :== 'Succ x = 'False
  type 'Succ x :== 'Succ y = x :== y

class kproxy ~ 'KProxy => SEq (kproxy :: KProxy a) where
  (%:==) :: Sing (x :: a) -> Sing (y :: a) -> Sing (x :== y)
  (%:/=) :: Sing (x :: a) -> Sing (y :: a) -> Sing (x :/= y)

  default (%:==) :: ((x :== y) ~ (Not (x :/= y))) => Sing (x :: a) -> Sing (y :: a) -> Sing (x :== y)
  x %:== y = sNot (x %:/= y)

  default (%:/=) :: ((x :/= y) ~ (Not (x :== y))) => Sing (x :: a) -> Sing (y :: a) -> Sing (x :/= y)
  x %:/= y = sNot (x %:== y)

instance SEq ('KProxy :: KProxy Nat) where
  (%:==) :: forall (x :: Nat) (y :: Nat). Sing x -> Sing y -> Sing (x :== y)
  SZero %:== SZero = STrue
  SSucc _ %:== SZero = SFalse
  SZero %:== SSucc _ = SFalse
  SSucc x %:== SSucc y = x %:== y

instance Eq Ordering where
  LT == LT = True
  LT == EQ = False
  LT == GT = False
  EQ == LT = False
  EQ == EQ = True
  EQ == GT = False
  GT == LT = False
  GT == EQ = False
  GT == GT = True

class Eq a => Ord a where
  compare :: a -> a -> Ordering
  (<) :: a -> a -> Bool

  x < y = compare x y == LT

class (PEq kproxy, kproxy ~ 'KProxy) => POrd (kproxy :: KProxy a) where
  type Compare (x :: a) (y :: a) :: Ordering
  type (:<) (x :: a) (y :: a) :: Bool

  type x :< y = Compare x y :== 'LT

instance Ord Nat where
  compare Zero Zero = EQ
  compare Zero (Succ _) = LT
  compare (Succ _) Zero = GT
  compare (Succ a) (Succ b) = compare a b

instance POrd ('KProxy :: KProxy Nat) where
  type Compare 'Zero 'Zero = 'EQ
  type Compare 'Zero ('Succ x) = 'LT
  type Compare ('Succ x) 'Zero = 'GT
  type Compare ('Succ x) ('Succ y) = Compare x y

data instance Sing (o :: Ordering) where
  SLT :: Sing 'LT
  SEQ :: Sing 'EQ
  SGT :: Sing 'GT

instance PEq ('KProxy :: KProxy Ordering) where
  type 'LT :== 'LT = 'True
  type 'LT :== 'EQ = 'False
  type 'LT :== 'GT = 'False
  type 'EQ :== 'LT = 'False
  type 'EQ :== 'EQ = 'True
  type 'EQ :== 'GT = 'False
  type 'GT :== 'LT = 'False
  type 'GT :== 'EQ = 'False
  type 'GT :== 'GT = 'True

instance SEq ('KProxy :: KProxy Ordering) where
  SLT %:== SLT = STrue
  SLT %:== SEQ = SFalse
  SLT %:== SGT = SFalse
  SEQ %:== SLT = SFalse
  SEQ %:== SEQ = STrue
  SEQ %:== SGT = SFalse
  SGT %:== SLT = SFalse
  SGT %:== SEQ = SFalse
  SGT %:== SGT = STrue

class (SEq kproxy, kproxy ~ 'KProxy) => SOrd (kproxy :: KProxy a) where
  sCompare :: Sing (x :: a) -> Sing (y :: a) -> Sing (Compare x y)
  (%:<) :: Sing (x :: a) -> Sing (y :: a) -> Sing (x :< y)

  default (%:<) :: ((x :< y) ~ (Compare x y :== 'LT)) => Sing (x :: a) -> Sing (y :: a) -> Sing (x :< y)
  x %:< y = sCompare x y %:== SLT

instance SOrd ('KProxy :: KProxy Nat) where
  sCompare SZero SZero = SEQ
  sCompare SZero (SSucc _) = SLT
  sCompare (SSucc _) SZero = SGT
  sCompare (SSucc x) (SSucc y) = sCompare x y

class Pointed a where
  point :: a

class kproxy ~ 'KProxy => PPointed (kproxy :: KProxy a) where
  type Point :: a

class kproxy ~ 'KProxy => SPointed (kproxy :: KProxy a) where
  sPoint :: Sing (Point :: a)

instance Pointed Nat where
  point = Zero

instance PPointed ('KProxy :: KProxy Nat) where
  type Point = 'Zero

instance SPointed ('KProxy :: KProxy Nat) where
  sPoint = SZero
