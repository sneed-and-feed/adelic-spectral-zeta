import Mathlib

theorem charpoly_similarity {α : Type*} [CommRing α] {n : Type*} [Fintype n] [DecidableEq n]
    (A : Matrix n n α) (S : Matrix n n α) (S_inv : Matrix n n α)
    (h : S_inv * S = 1) :
    (S_inv * A * S).charpoly = A.charpoly := by
  let f : α →+* Polynomial α := Polynomial.C
  let F : Matrix n n α →+* Matrix n n (Polynomial α) := RingHom.mapMatrix f
  have h_map : F (S_inv * S) = F 1 := by rw [h]
  rw [map_mul] at h_map
  have h_one : F 1 = 1 := map_one F
  rw [h_one] at h_map
  have h_map_comm : F S * F S_inv = 1 := by rw [Matrix.mul_eq_one_comm, h_map]
  unfold Matrix.charpoly
  have h_eq : Matrix.charmatrix (S_inv * A * S) = F S_inv * Matrix.charmatrix A * F S := by
    unfold Matrix.charmatrix
    rw [map_mul, map_mul, Matrix.mul_sub, Matrix.sub_mul]
    congr 1
    have h1 : F S_inv * Matrix.scalar n (Polynomial.X : Polynomial α) = Matrix.scalar n (Polynomial.X : Polynomial α) * F S_inv := by
      change F S_inv * algebraMap (Polynomial α) (Matrix n n (Polynomial α)) Polynomial.X = algebraMap (Polynomial α) (Matrix n n (Polynomial α)) Polynomial.X * F S_inv
      exact (Algebra.commutes _ _).symm
    rw [h1, Matrix.mul_assoc, h_map, Matrix.mul_one]
  rw [h_eq, Matrix.det_mul, Matrix.det_mul, mul_comm]
  have h_det : (F S).det * (F S_inv).det = 1 := by
    rw [← Matrix.det_mul, h_map_comm, Matrix.det_one]
  calc (F S).det * ((F S_inv).det * (Matrix.charmatrix A).det)
    _ = ((F S).det * (F S_inv).det) * (Matrix.charmatrix A).det := by rw [mul_assoc]
    _ = 1 * (Matrix.charmatrix A).det := by rw [h_det]
    _ = (Matrix.charmatrix A).det := by rw [one_mul]
