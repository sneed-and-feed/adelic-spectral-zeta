import Mathlib.CategoryTheory.Category.Basic
import Mathlib.CategoryTheory.Limits.HasLimits
import Mathlib.CategoryTheory.Limits.Filtered
import Mathlib.CategoryTheory.Limits.IsLimit
import Mathlib.Analysis.NormedSpace.Star.Basic
import Mathlib.Algebra.Star.StarAlgHom
import Mathlib.Analysis.Complex.Basic

open CategoryTheory
open CategoryTheory.Limits

universe u

/-- A finite-dimensional C*-algebra. -/
structure FinCStarAlg where
  carrier : Type u
  [normedRing : NormedRing carrier]
  [starRing : StarRing carrier]
  [cstarRing : CstarRing carrier]
  [normedAlgebra : NormedAlgebra ℂ carrier]
  [starModule : StarModule ℂ carrier]
  [finiteDimensional : FiniteDimensional ℂ carrier]

attribute [instance] FinCStarAlg.normedRing FinCStarAlg.starRing FinCStarAlg.cstarRing
attribute [instance] FinCStarAlg.normedAlgebra FinCStarAlg.starModule FinCStarAlg.finiteDimensional

/-- Morphisms are injective *-algebra homomorphisms. -/
structure FinCStarAlgHom (A B : FinCStarAlg) where
  hom : A.carrier →⋆ₐ[ℂ] B.carrier
  inj : Function.Injective hom

instance : Category FinCStarAlg where
  Hom A B := FinCStarAlgHom A B
  id A := {
    hom := StarAlgHom.id ℂ A.carrier
    inj := Function.injective_id
  }
  comp f g := {
    hom := StarAlgHom.comp g.hom f.hom
    inj := g.inj.comp f.inj
  }

/-- The category of C*-algebras. -/
structure CStarAlgCat where
  carrier : Type u
  [normedRing : NormedRing carrier]
  [starRing : StarRing carrier]
  [cstarRing : CstarRing carrier]
  [normedAlgebra : NormedAlgebra ℂ carrier]
  [starModule : StarModule ℂ carrier]

attribute [instance] CStarAlgCat.normedRing CStarAlgCat.starRing CStarAlgCat.cstarRing
attribute [instance] CStarAlgCat.normedAlgebra CStarAlgCat.starModule

/-- Morphisms are *-algebra homomorphisms. -/
structure CStarAlgHom (A B : CStarAlgCat) where
  hom : A.carrier →⋆ₐ[ℂ] B.carrier

instance : Category CStarAlgCat where
  Hom A B := CStarAlgHom A B
  id A := { hom := StarAlgHom.id ℂ A.carrier }
  comp f g := { hom := StarAlgHom.comp g.hom f.hom }

/-- The fully faithful functor from FinCStarAlg to CStarAlgCat. -/
def FinCStarAlg.toCStarAlgCat : FinCStarAlg ⥤ CStarAlgCat where
  obj A := { carrier := A.carrier }
  map f := { hom := f.hom }

/-- An AF-algebra is defined as a C*-algebra which is the colimit of a directed system of finite-dimensional C*-algebras. -/
class IsAFAlgebra (A : CStarAlgCat.{u}) : Prop where
  out : ∃ (J : Type u) (_ : Preorder J) (_ : IsDirected J (· ≤ ·))
    (F : J ⥤ FinCStarAlg.{u})
    (c : Cocone (F ⋙ FinCStarAlg.toCStarAlgCat.{u})),
    c.pt = A ∧ Nonempty (IsColimit c)
