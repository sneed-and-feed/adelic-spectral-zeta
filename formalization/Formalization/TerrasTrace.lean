import Mathlib.Tactic
import Mathlib.LinearAlgebra.Matrix.GeneralLinearGroup

@[ext]
structure ArtinSchreierExt (F : Type*) [CommRing F] (nu : F) where
  re : F
  im : F

namespace ArtinSchreierExt

variable {F : Type*} [Field F] {nu : F}

def add (a b : ArtinSchreierExt F nu) : ArtinSchreierExt F nu :=
  ⟨a.re + b.re, a.im + b.im⟩

def neg (a : ArtinSchreierExt F nu) : ArtinSchreierExt F nu :=
  ⟨-a.re, -a.im⟩

def sub (a b : ArtinSchreierExt F nu) : ArtinSchreierExt F nu :=
  ⟨a.re - b.re, a.im - b.im⟩

def mul (a b : ArtinSchreierExt F nu) : ArtinSchreierExt F nu :=
  ⟨a.re * b.re - a.im * b.im * nu, a.re * b.im + a.im * b.re - a.im * b.im⟩

def conj (a : ArtinSchreierExt F nu) : ArtinSchreierExt F nu :=
  ⟨a.re - a.im, -a.im⟩

def norm (a : ArtinSchreierExt F nu) : F :=
  a.re * a.re - a.re * a.im + a.im * a.im * nu

def inv (a : ArtinSchreierExt F nu) : ArtinSchreierExt F nu :=
  let n := norm a
  ⟨(a.re - a.im) / n, -a.im / n⟩

def div (a b : ArtinSchreierExt F nu) : ArtinSchreierExt F nu :=
  mul a (inv b)

instance : Add (ArtinSchreierExt F nu) := ⟨add⟩
instance : Neg (ArtinSchreierExt F nu) := ⟨neg⟩
instance : Sub (ArtinSchreierExt F nu) := ⟨sub⟩
instance : Mul (ArtinSchreierExt F nu) := ⟨mul⟩
instance : Div (ArtinSchreierExt F nu) := ⟨div⟩

@[simp] theorem re_add (a b : ArtinSchreierExt F nu) : (a + b).re = a.re + b.re := rfl
@[simp] theorem im_add (a b : ArtinSchreierExt F nu) : (a + b).im = a.im + b.im := rfl
@[simp] theorem re_sub (a b : ArtinSchreierExt F nu) : (a - b).re = a.re - b.re := rfl
@[simp] theorem im_sub (a b : ArtinSchreierExt F nu) : (a - b).im = a.im - b.im := rfl
@[simp] theorem re_mul (a b : ArtinSchreierExt F nu) : (a * b).re = a.re * b.re - a.im * b.im * nu := rfl
@[simp] theorem im_mul (a b : ArtinSchreierExt F nu) : (a * b).im = a.re * b.im + a.im * b.re - a.im * b.im := rfl

theorem norm_eq_mul_conj (a : ArtinSchreierExt F nu) : (a * conj a).re = norm a := by
  dsimp [conj, norm, mul]
  ring

theorem mul_conj_im (a : ArtinSchreierExt F nu) : (a * conj a).im = 0 := by
  dsimp [conj, mul]
  ring

/-- The Finite Upper Half Plane. -/
def Hq (F : Type*) [Field F] (nu : F) :=
  { z : ArtinSchreierExt F nu // z.im ≠ 0 }

def Hq.dist (z w : Hq F nu) : F :=
  norm (z.val - w.val) / (z.val.im * w.val.im)

/-- Matrix action of GL(2, F) on the extension.
  Assuming cz+d is invertible. -/
def action (g : Matrix (Fin 2) (Fin 2) F) (z : ArtinSchreierExt F nu) : ArtinSchreierExt F nu :=
  let a := ArtinSchreierExt.mk (g 0 0) 0
  let b := ArtinSchreierExt.mk (g 0 1) 0
  let c := ArtinSchreierExt.mk (g 1 0) 0
  let d := ArtinSchreierExt.mk (g 1 1) 0
  (a * z + b) / (c * z + d)

end ArtinSchreierExt
