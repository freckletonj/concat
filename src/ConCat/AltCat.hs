{-# LANGUAGE CPP                   #-}
{-# LANGUAGE TypeOperators         #-}
{-# LANGUAGE TypeApplications      #-}
{-# LANGUAGE ScopedTypeVariables   #-}

-- For Uncurriable:
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE DefaultSignatures     #-}
{-# LANGUAGE UndecidableInstances  #-}

{-# OPTIONS_GHC -Wall #-}
{-# OPTIONS_GHC -fno-warn-inline-rule-shadowing #-}
{-# OPTIONS_GHC -fno-warn-unused-imports #-} -- TEMP

-- | Alternative interface to the class operations from ConCat.Category, so as
-- not to get inlined too eagerly to optimize.

module ConCat.AltCat
  ( module ConCat.AltCat
  , module C)
  where

{-# LANGUAGE NoMonomorphismRestriction #-}

{-# OPTIONS_GHC -Wall #-}
-- {-# OPTIONS_GHC -fno-warn-unused-imports #-}  -- TEMP

import Prelude hiding (id,(.),curry,uncurry,const,Float,Double)
import qualified Prelude as P
import qualified Data.Tuple as P
-- import qualified Control.Category as A
-- import qualified Control.Arrow as A

import ConCat.Category
  ( Category, Ok,Ok2,Ok3,Ok4,Ok5
  , ProductCat, Prod, twiceP, inLassocP, inRassocP, transposeP, unfork
  , CoproductCat, Coprod, inLassocS, inRassocS, transposeS, unjoin
  , DistribCat, undistl, undistr
  , ClosedCat, Exp
  , TerminalCat, Unit, lunit, runit{-, constFun-}, constFun2, unitFun, unUnitFun
  , ConstCat, ConstObj, lconst, rconst
  , BiCCC
  , BoolCat, BoolOf
  , NumCat, FractionalCat, FloatingCat, FromIntegralCat
  , EqCat, OrdCat, EnumCat, BottomCat, IfCat, UnknownCat, RepCat
  , (:**:)(..)
  --
  , (<+), okProd
  )

import qualified ConCat.Category as C
import ConCat.Rep
import ConCat.Misc ((:*),(:+))
import ConCat.Float

-- | Dummy identity function set up to trigger rewriting of non-inlining
-- operations to inling operations.
reveal :: a -> a
-- reveal f = f
-- reveal f = reveal f
-- {-# INLINE [0] reveal #-}
reveal _f = error "reveal called"
{-# NOINLINE reveal #-}
{-# RULES "reveal = id" [0] reveal = id #-}

#define OPINLINE INLINE [3]
-- #define OPINLINE INLINE CONLIKE [3]
-- #define OPINLINE NOINLINE

#define Op(nm,ty) \
{- | C.nm without the eager inlining -}; \
nm :: ty; \
nm = C.nm ;\
{-# OPINLINE nm #-}

#define OpRule0(nm) {-# RULES "reveal op0" \
  reveal nm = C.nm #-}
#define OpRule1(nm) {-# RULES "reveal op1" forall a1. \
  reveal (nm a1) = C.nm (reveal a1) #-}
#define OpRule2(nm) {-# RULES "reveal op2" forall a1 a2. \
  reveal (nm a1 a2) = C.nm (reveal a1) (reveal a2) #-}

#define IpRule0(nm) {-# RULES "reveal ip0" \
  reveal (nm) = (C.nm) #-}
#define IpRule1(nm) {-# RULES "reveal ip1" forall a1. \
  reveal ((nm) a1) = (C.nm) (reveal a1) #-}
#define IpRule2(nm) {-# RULES "reveal ip2" forall a1 a2. \
  reveal ((nm) a1 a2) = (C.nm) (reveal a1) (reveal a2) #-}

#define Op0(nm,ty) Op(nm,ty); OpRule0(nm)
#define Op1(nm,ty) Op(nm,ty); OpRule1(nm)
#define Op2(nm,ty) Op(nm,ty); OpRule2(nm)

#define Ip(nm,ty) \
{- | (C.nm) without the eager inlining -}; \
(nm) :: ty; \
(nm) = (C.nm) ;\
{-# OPINLINE (nm) #-}

#define Ip1(nm,ty) Ip(nm,ty); IpRule1(nm)
#define Ip2(nm,ty) Ip(nm,ty); IpRule2(nm)

-- I use semicolons and the {- | ... -} style Haddock comment because CPP macros
-- generate a single line. I want to inject single quotes around the C.foo and
-- (C.op) names to form Haddock links, but CPP interprets them as preventing
-- macro argument insertion.

-- Can I get the operation names (nm) into the rule names?

infixr 9 .
Op0(id,(Category k, Ok k a) => a `k` a)
Ip2(.,forall k b c a. (Category k, Ok3 k a b c) => (b `k` c) -> (a `k` b) -> (a `k` c))

infixr 3 ***, &&&
Op0(exl,(ProductCat k, Ok2 k a b) => Prod k a b `k` a)
Op0(exr,(ProductCat k, Ok2 k a b) => Prod k a b `k` b)
Ip2(&&&,forall k a c d. (ProductCat k, Ok3 k a c d) => (a `k` c) -> (a `k` d) -> (a `k` Prod k c d))
Ip2(***,forall k a b c d. (ProductCat k, Ok4 k a b c d) => (a `k` c) -> (b `k` d) -> (Prod k a b `k` Prod k c d))
Op0(dup,forall k a. (ProductCat k, Ok k a) => a `k` Prod k a a)
Op0(swapP,forall k a b. (ProductCat k, Ok2 k a b) => Prod k a b `k` Prod k b a)
Op1(first,forall k a aa b. (ProductCat k, Ok3 k a b aa) => (a `k` aa) -> (Prod k a b `k` Prod k aa b))
Op2(second,forall k a b bb. (ProductCat k, Ok3 k a b bb) => (b `k` bb) -> (Prod k a b `k` Prod k a bb))
Op1(lassocP,forall k a b c. (ProductCat k, Ok3 k a b c) => Prod k a (Prod k b c) `k` Prod k (Prod k a b) c)
Op1(rassocP,forall k a b c. (ProductCat k, Ok3 k a b c) => Prod k (Prod k a b) c `k` Prod k a (Prod k b c))

infixr 2 +++, |||
Op0(inl,(CoproductCat k, Ok2 k a b) => a `k` Coprod k a b)
Op0(inr,(CoproductCat k, Ok2 k a b) => b `k` Coprod k a b)
Ip2(|||,forall k a c d. (CoproductCat k, Ok3 k a c d) => (c `k` a) -> (d `k` a) -> (Coprod k c d `k` a))
Ip2(+++,forall k a b c d. (CoproductCat k, Ok4 k a b c d) => (c `k` a) -> (d `k` b) -> (Coprod k c d `k` Coprod k a b))
Op0(jam,(CoproductCat k, Ok k a) => Coprod k a a `k` a)
Op0(swapS,forall k a b. (CoproductCat k, Ok2 k a b) => Coprod k a b `k` Coprod k b a)
Op1(left ,forall k a aa b. (CoproductCat k, Ok3 k a b aa) => (a `k` aa) -> (Coprod k a b `k` Coprod k aa b))
Op1(right,forall k a b bb. (CoproductCat k, Ok3 k a b bb) => (b `k` bb) -> (Coprod k a b `k` Coprod k a bb))
Op1(lassocS,forall k a b c. (CoproductCat k, Ok3 k a b c) => Coprod k a (Coprod k b c) `k` Coprod k (Coprod k a b) c)
Op1(rassocS,forall k a b c. (CoproductCat k, Ok3 k a b c) => Coprod k (Coprod k a b) c `k` Coprod k a (Coprod k b c))

Op0(apply,forall k a b. (ClosedCat k, Ok2 k a b) => Prod k (Exp k a b) a `k` b)
Op1(curry,(ClosedCat k, Ok3 k a b c) => (Prod k a b `k` c) -> (a `k` Exp k b c))
Op1(uncurry,forall k a b c. (ClosedCat k, Ok3 k a b c) => (a `k` Exp k b c)  -> (Prod k a b `k` c))

Op0(distl,forall k a u v. (DistribCat k, Ok3 k a u v) => Prod k a (Coprod k u v) `k` Coprod k (Prod k a u) (Prod k a v))
Op0(distr,forall k u v b. (DistribCat k, Ok3 k u v b) => Prod k (Coprod k u v) b `k` Coprod k (Prod k u b) (Prod k v b))

Op0(it,(TerminalCat k, Ok k a) => a `k` Unit k)
Op(unitArrow,ConstCat k b => b -> (Unit k `k` ConstObj k b))
Op(const,(ConstCat k b, Ok k a) => b -> (a `k` ConstObj k b))

{-# RULES
"inOp unitArrow" forall b. reveal (unitArrow b) = C.unitArrow b
"inOp const" forall b. reveal (const b) = C.const b
 #-}

Op0(notC,BoolCat k => BoolOf k `k` BoolOf k)
Op0(andC,BoolCat k => Prod k (BoolOf k) (BoolOf k) `k` BoolOf k)
Op0(orC,BoolCat k => Prod k (BoolOf k) (BoolOf k) `k` BoolOf k)
Op0(xorC,BoolCat k => Prod k (BoolOf k) (BoolOf k) `k` BoolOf k)

Op0(negateC,NumCat k a => a `k` a)
Op0(addC,NumCat k a => Prod k a a `k` a)
Op0(subC,NumCat k a => Prod k a a `k` a)
Op0(mulC,NumCat k a => Prod k a a `k` a)
Op0(powIC,NumCat k a => Prod k a Int `k` a)

Op0(recipC,FractionalCat k a => a `k` a)
Op0(divideC,FractionalCat k a => Prod k a a `k` a)

Op0(expC,FloatingCat k a => a `k` a)
Op0(cosC,FloatingCat k a => a `k` a)
Op0(sinC,FloatingCat k a => a `k` a)

Op0(fromIntegralC,FromIntegralCat k a b => a `k` b)

Op0(equal,EqCat k a => Prod k a a `k` BoolOf k)
Op0(notEqual,EqCat k a => Prod k a a `k` BoolOf k)

Op0(lessThan,OrdCat k a => Prod k a a `k` BoolOf k)
Op0(greaterThan,OrdCat k a => Prod k a a `k` BoolOf k)
Op0(lessThanOrEqual,OrdCat k a => Prod k a a `k` BoolOf k)
Op0(greaterThanOrEqual,OrdCat k a => Prod k a a `k` BoolOf k)

Op0(succC,EnumCat k a => a `k` a)
Op0(predC,EnumCat k a => a `k` a)

Op0(bottomC,BottomCat k a => Unit k `k` a)

Op0(ifC,IfCat k a => Prod k (BoolOf k) (Prod k a a) `k` a)

Op0(unknownC,UnknownCat k a b => a `k` b)

Op0(reprC,(RepCat k, HasRep a) => a `k` Rep a)
Op0(abstC,(RepCat k, HasRep a) => Rep a `k` a)

-- Unnecessary but helpful to track NOINLINE choice
-- Op(constFun,forall k p a b. (ClosedCat k, Ok3 k p a b) => (a `k` b) -> (p `k` Exp k a b))

constFun :: forall k p a b. (ClosedCat k, Ok3 k p a b)
         => (a `k` b) -> (p `k` Exp k a b)
constFun f = curry (f . exr) <+ okProd @k @p @a
{-# OPINLINE constFun #-}
OpRule1(constFun)

-- TODO: Consider moving all of the auxiliary functions (like constFun) here.
-- Rename "ConCat.Category" to something like "ConCat.Category.Class" and
-- "ConCat.AltCat" to "ConCat.Category".
-- 
-- Maybe move some of the methods with defaults out of the classes, e.g.,
-- "lassocP" and maybe "dup" and "jam".

pair :: forall k a b. (ClosedCat k, Ok2 k a b) => a `k` Exp k b (Prod k a b)
pair = curry id <+ okProd @k @a @b

{--------------------------------------------------------------------
    Automatic uncurrying
--------------------------------------------------------------------}

-- Note: I'm not using yet. I think it needs to go before ccc.
-- Alternatively, generalize from (->) to ClosedCat.

-- | Repeatedly uncurried version of a -> b
class Uncurriable k a b where
  type UncDom a b
  type UncRan a b
  type UncDom a b = a
  type UncRan a b = b
  uncurries :: (a `k` b) -> (UncDom a b `k` UncRan a b)
  default uncurries :: (a `k` b) -> (a `k` b)
  -- uncurries = id
  -- uncurries = P.id
  uncurries f = f
  -- experiment
  fiddly_foo_unc :: k a b -> ()
  fiddly_foo_unc = const ()
  {-# INLINE uncurries #-}

instance (ClosedCat k, Uncurriable k (a :* b) c, Ok3 k a b c)
      => Uncurriable k a (b -> c) where
  type UncDom a (b -> c) = UncDom (a :* b) c
  type UncRan a (b -> c) = UncRan (a :* b) c
  -- uncurries = uncurries C.. uncurry
  uncurries = uncurries P.. uncurry
  -- uncurries f = uncurries (uncurry f)
  {-# INLINE uncurries #-}

--     • The constraint ‘Uncurriable k (a :* b) c’
--         is no smaller than the instance head
--       (Use UndecidableInstances to permit this)

-- I get better inlining and simplification with explicit uncurries
-- definitions and specific INLINE pragmas.

#define UncId(t) \
instance Uncurriable k a (t) where uncurries f = f ; {-# INLINE uncurries #-}

UncId(())
UncId(Bool)
UncId(Int)
-- UncId(Float)

instance Uncurriable k a Float where uncurries f = f ; {-# INLINE uncurries #-}

UncId(Double)
UncId(c :* d)
UncId(c :+ d)

{--------------------------------------------------------------------
    Rewrite rules
--------------------------------------------------------------------}

{-# RULES

"g . id" forall g. g . id = g
"id . f" forall f. id . f = f

"exl/&&&" forall f g. exl . (f &&& g) = f
"exr/&&&" forall f g. exr . (f &&& g) = g

"exl2/&&&" forall f g h. (h . exl) . (f &&& g) = h . f
"exr2/&&&" forall f g h. (h . exr) . (f &&& g) = h . g

"exl3/&&&" forall f g h k. (h . (k . exl)) . (f &&& g) = h . k . f
"exr3/&&&" forall f g h k. (h . (k . exr)) . (f &&& g) = h . k . g

"f . h &&& g . h" forall (f :: a `k` c) (g :: a `k` d) h.
  f . h &&& g . h = (f &&& g) . h <+ okProd @k @c @d

-- -- Careful with this one, since dup eventually inlines to id &&& id
-- "id &&& id" [~2] id &&& id = dup

-- -- Specializations with f == id and/or g == id
-- "h &&& h    " forall (h :: a `k` b)               . h &&& h     = (id &&& id) . h <+ okProd @k @b @b
-- "h &&& g . h" forall (g :: b `k` d) (h :: a `k` b). h &&& g . h = (id &&& g ) . h <+ okProd @k @b @d
-- "f . h &&& h" forall (f :: b `k` c) (h :: a `k` b). f . h &&& h = (f  &&& id) . h <+ okProd @k @c @b

-- Oops! the h &&& h rule generates id &&& id, which also matches the rule.

"exl &&& exr" exl &&& exr = id

-- "(f &&& const y) . h" forall y f h. (f &&& const y) . h = f . h &&& const y
-- "(const x &&& g) . h" forall x g h. (const x &&& g) . h = const x &&& g . h

-- "(k . (f &&& const y)) . h" forall y f h k. (k . (f &&& const y)) . h = k . (f . h &&& const y)
-- "(k . (const x &&& g)) . h" forall x g h k. (k . (const x &&& g)) . h = k . (const x &&& g . h)

"uncurry (curry f)" forall f. uncurry (curry f) = f
"curry (uncurry g)" forall g. curry (uncurry g) = g

"constFun 0" forall g f. apply . (curry (g . exr) &&& f) = g . f

"constFun 1" forall f. apply . (curry exr &&& f) = f

"constFun 3" forall f x. apply . (curry (const x) &&& f) = const x

-- Experiment: same rules but via constFun

"constFun' 0" forall g f. apply . (constFun g &&& f) = g . f

"foo1" forall (f :: a `k` c) (g :: a `k` d) h.
  apply . (curry h . f &&& g) = h . (f &&& g) <+ okProd @k @c @d

-- The next one leads to a role error when I chain ccc calls. To investigate.
"foo2" forall (g :: a `k` d) h.
  apply . (curry h &&& g) = h . (id &&& g) <+ okProd @k @a @d

-- -- experiment
-- "constFun id" constFun id = curry exr

 #-}

-- -- This rule helps expose some product rewrites.
-- -- Will we want the opposite for coproducts?
-- "(h . g) . f" forall f g h. (h . g) . f = h . (g . f)

-- "constFun 1" forall f. apply . (curry (f . exr) &&& id) = f

-- "constFun 2" apply . (curry exr &&& id) = id

-- "constFun 3" forall x. apply . (curry (const x) &&& id) = const x

-- | Pseudo function to trigger rewriting to CCC form.
ccc :: forall k a b. (a -> b) -> (a `k` b)
ccc _ = error "ccc: not implemented"
{-# NOINLINE ccc #-}

-- Prelude versions of categorical ops
{-# RULES

#if 0

"ccc Prelude id" ccc P.id = ccc id
"ccc Prelude (.)" forall g f. ccc (g P.. f) = ccc (g . f)

"ccc Prelude (,)" ccc (,) = ccc pair
"ccc Prelude fst" ccc fst = ccc exl
"ccc Prelude snd" ccc snd = ccc exr
"ccc Prelude swap" ccc P.swap = ccc swapP

"ccc Prelude Left" ccc Left = ccc inl
"ccc Prelude Right" ccc Right = ccc inl
"ccc Prelude either" ccc either = ccc (|||)

"ccc Prelude curry" forall f. ccc (P.curry f) = ccc (curry f)
"ccc Prelude uncurry" forall f.  ccc (P.uncurry f) = ccc (uncurry f)

"ccc Prelude const" forall x. ccc (P.const x) = ccc (const x)

#endif

-- Use this one for now.
"ccc Prelude const" forall x. ccc (P.const x) = ccc (\ _ -> x)

#if 0

-- I've commented out the class-ops, since they'll get expanded away early via
-- auto-generated built-in rules.

"ccc Control.Category id" ccc A.id = ccc id
"ccc Control.Category (.)" forall g f. ccc (g A.. f) = ccc (g . f)

"ccc Arrow (&&&)" forall f g. ccc (f A.&&& g) = ccc (f &&& g)
"ccc Arrow (***)" forall f g. ccc (f A.*** g) = ccc (f *** g)
"ccc Arrow first" forall f. ccc (A.first f) = ccc (first f)
"ccc Arrow second" forall g. ccc (A.second g) = ccc (second g)

"ccc Arrow (|||)" forall f g. ccc (f A.||| g) = ccc (f ||| g)
"ccc Arrow (+++)" forall f g. ccc (f A.+++ g) = ccc (f +++ g)
"ccc Arrow left" forall f. ccc (A.left f) = ccc (left f)
"ccc Arrow right" forall g. ccc (A.right g) = ccc (right g)

#endif

 #-}