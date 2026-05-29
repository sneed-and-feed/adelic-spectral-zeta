From mathcomp Require Import all_ssreflect all_algebra.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section BassIhara.
Import GRing.Theory.
Variable V : finType.
Variable UEdge : finType.
Variable endpts : UEdge -> V * V.

Definition E_finType := Finite.clone (UEdge * bool)%type _.
Local Notation E := E_finType.
Definition src (e : E) : V := if e.2 then (endpts e.1).1 else (endpts e.1).2.
Definition tgt (e : E) : V := if e.2 then (endpts e.1).2 else (endpts e.1).1.
Definition rev (e : E) : E := (e.1, ~~ e.2).

Lemma revK : involutive rev.
Proof.
  move=> e. destruct e as [u b]. destruct b; reflexivity.
Qed.

Lemma rev_src_tgt : forall e, src (rev e) = tgt e.
Proof.
  move=> e. destruct e as [u b]. destruct b; reflexivity.
Qed.

Lemma rev_tgt_src : forall e, tgt (rev e) = src e.
Proof.
  move=> e. destruct e as [u b]. destruct b; reflexivity.
Qed.

Local Notation n := #|V|.
Local Notation m := #|UEdge|.
Local Notation m2 := #|E|.

Variable R : comRingType.
Variable u : R.
Open Scope ring_scope.

Definition S_mx : 'M[R]_(n, m2) := \matrix_(v, e) (enum_val v == src (enum_val e))%:R.
Definition T_mx : 'M[R]_(n, m2) := \matrix_(v, e) (enum_val v == tgt (enum_val e))%:R.
Definition J_mx : 'M[R]_(m2, m2) := \matrix_(e, f) (enum_val e == rev (enum_val f))%:R.
Definition A_mx : 'M[R]_(n, n) := S_mx *m T_mx^T.
Definition D_mx : 'M[R]_(n, n) := S_mx *m S_mx^T.
Definition B_mx : 'M[R]_(m2, m2) := T_mx^T *m S_mx - J_mx.

Lemma J_sq : J_mx *m J_mx = 1%:M.
Proof.
  apply/matrixP=> e f. rewrite !mxE.
  transitivity (\sum_(j : 'I_m2) ((enum_val e == rev (enum_val j)) && (enum_val j == rev (enum_val f)))%:R : R).
  - apply: eq_bigr=> j _. rewrite !mxE.
    have H : forall b1 b2 : bool, (b1 && b2)%:R = b1%:R * b2%:R :> R.
    { by case; case; rewrite /=; [exact: sym_eq (mulr1 1) | exact: sym_eq (mulr0 1) | exact: sym_eq (mul0r 1) | exact: sym_eq (mul0r 0)]. }
    by rewrite H.
  - rewrite (bigD1 (enum_rank (rev (enum_val e)))) //=.
    + rewrite enum_rankK revK eqxx.
      rewrite big1.
      * by rewrite addr0 /= (inj_eq (inv_inj revK)) (inj_eq enum_val_inj).
      * move=> j neq.
        have neq' : enum_val j != rev (enum_val e).
        { apply: contra neq => /eqP eq. by rewrite -(enum_valK j) eq eqxx. }
        have -> : enum_val e == rev (enum_val j) = false.
        { by rewrite -[enum_val e]revK (inj_eq (inv_inj revK)) eq_sym (negPf neq'). }
        by [].
Qed.

Lemma S_J : S_mx *m J_mx = T_mx.
Proof.
  apply/matrixP=> v e. rewrite !mxE.
  transitivity (\sum_(j : 'I_m2) ((enum_val v == src (enum_val j)) && (enum_val j == rev (enum_val e)))%:R : R).
  - apply: eq_bigr=> j _. rewrite !mxE.
    have H : forall b1 b2 : bool, (b1 && b2)%:R = b1%:R * b2%:R :> R.
    { by case; case; rewrite /=; [exact: sym_eq (mulr1 1) | exact: sym_eq (mulr0 1) | exact: sym_eq (mul0r 1) | exact: sym_eq (mul0r 0)]. }
    by rewrite H.
  - rewrite (bigD1 (enum_rank (rev (enum_val e)))) //=.
    + rewrite enum_rankK eqxx andbT rev_src_tgt.
      rewrite big1.
      * by rewrite addr0.
      * move=> j neq.
        have neq' : enum_val j != rev (enum_val e).
        { apply: contra neq => /eqP eq. by rewrite -(enum_valK j) eq eqxx. }
        by rewrite (negPf neq') andbF.
Qed.

Lemma T_J : T_mx *m J_mx = S_mx.
Proof.
  apply/matrixP=> v e. rewrite !mxE.
  transitivity (\sum_(j : 'I_m2) ((enum_val v == tgt (enum_val j)) && (enum_val j == rev (enum_val e)))%:R : R).
  - apply: eq_bigr=> j _. rewrite !mxE.
    have H : forall b1 b2 : bool, (b1 && b2)%:R = b1%:R * b2%:R :> R.
    { by case; case; rewrite /=; [exact: sym_eq (mulr1 1) | exact: sym_eq (mulr0 1) | exact: sym_eq (mul0r 1) | exact: sym_eq (mul0r 0)]. }
    by rewrite H.
  - rewrite (bigD1 (enum_rank (rev (enum_val e)))) //=.
    + rewrite enum_rankK eqxx andbT rev_tgt_src.
      rewrite big1.
      * by rewrite addr0.
      * move=> j neq.
        have neq' : enum_val j != rev (enum_val e).
        { apply: contra neq => /eqP eq. by rewrite -(enum_valK j) eq eqxx. }
        by rewrite (negPf neq') andbF.
Qed.

Lemma S_S : S_mx *m S_mx^T = D_mx.
Proof. by []. Qed.

Lemma S_T : S_mx *m T_mx^T = A_mx.
Proof. by []. Qed.

Lemma J_T : J_mx *m T_mx^T = S_mx^T.
Proof.
  apply/matrixP=> e v. rewrite !mxE.
  transitivity (\sum_(j : 'I_m2) ((enum_val e == rev (enum_val j)) && (enum_val v == tgt (enum_val j)))%:R : R).
  - apply: eq_bigr=> j _. rewrite !mxE.
    have H_b : forall b1 b2 : bool, (b1 && b2)%:R = b1%:R * b2%:R :> R.
    { by case; case; rewrite /=; [exact: sym_eq (mulr1 1) | exact: sym_eq (mulr0 1) | exact: sym_eq (mul0r 1) | exact: sym_eq (mul0r 0)]. }
    by rewrite H_b.
  - rewrite (bigD1 (enum_rank (rev (enum_val e)))) //=.
    + rewrite enum_rankK revK eqxx rev_tgt_src.
      rewrite big1.
      * by rewrite addr0 eq_sym.
      * move=> j neq.
        have neq' : enum_val j != rev (enum_val e).
        { apply: contra neq => /eqP eq. by rewrite -(enum_valK j) eq eqxx. }
        have -> : enum_val e == rev (enum_val j) = false.
        { by rewrite -[enum_val e]revK (inj_eq (inv_inj revK)) eq_sym (negPf neq'). }
        by [].
Qed.

Lemma T_T : T_mx *m T_mx^T = D_mx.
Proof. by rewrite -{1}S_J -mulmxA J_T S_S. Qed.

Lemma T_S : T_mx^T *m S_mx = B_mx + J_mx.
Proof. rewrite /B_mx. symmetry. apply: subrK. Qed.

Local Notation I_n := (1%:M : 'M[R]_(n, n)).
Local Notation I_m2 := (1%:M : 'M[R]_(m2, m2)).

Lemma bass_ihara :
  \det (I_m2 - u *: B_mx) * \det (I_m2 - u *: J_mx) * (1 - u^+2)^+n =
  (1 - u^+2)^+m2 * \det ((1 - u^+2) *: I_n - u *: A_mx + u^+2 *: D_mx).
Proof.
  pose M := block_mx (I_m2 + u *: J_mx) (u *: T_mx^T) S_mx I_n.
  pose P1 := block_mx I_m2 (- u *: T_mx^T) (0 : 'M_(n, m2)) I_n.
  pose P3 := block_mx (I_m2 - u *: J_mx) (0 : 'M_(m2, n)) (0 : 'M_(n, m2)) I_n.
  pose P5 := block_mx I_m2 (0 : 'M_(m2, n)) (- S_mx) I_n.
  pose P6 := block_mx I_m2 (- (u *: T_mx^T - u^+2 *: S_mx^T)) (0 : 'M_(n, m2)) ((1 - u^+2) *: I_n).

  have H1 : P1 *m M = block_mx (I_m2 - u *: B_mx) (0 : 'M_(m2, n)) S_mx I_n.
  { rewrite /M /P1 mulmx_block ?mul1mx ?mul0mx ?mulmx0 ?mulmx1 ?add0r ?addr0.
    congr block_mx.
    - rewrite -scalemxAl T_S scalerDr !scaleNr addrA addrAC addrK.
      reflexivity.
    - by rewrite scaleNr subrr. }

  have H2 : P5 *m (P3 *m M) *m P6 = block_mx ((1 - u^+2) *: I_m2) (0 : 'M_(m2, n)) (u^+2 *: S_mx) ((1 - u^+2) *: I_n - u *: A_mx + u^+2 *: D_mx).
  { rewrite /M /P3 /P5 /P6.
    rewrite !mulmx_block ?mul1mx ?mul0mx ?mulmx0 ?mulmx1 ?add0r ?addr0.
    (* Key intermediate results *)
    have diff_sq : (I_m2 - u *: J_mx) *m (I_m2 + u *: J_mx) = (1 - u^+2) *: I_m2.
    { rewrite mulmxDl mul1mx mulNmx mulmxDr mulmx1.
      rewrite -scalemxAl -scalemxAr J_sq scalerA -expr2.
      rewrite opprD addrA addrK scalerBl scale1r.
      reflexivity. }
    have expand_12 : (I_m2 - u *: J_mx) *m (u *: T_mx^T) = u *: T_mx^T - u^+2 *: S_mx^T.
    { rewrite mulmxDl mul1mx mulNmx -scalemxAl -scalemxAr J_T scalerA -expr2.
      reflexivity. }
    rewrite diff_sq expand_12.
    congr block_mx.
    - (* (1,2): (1-u²)*I * (-X) + X * (1-u²)*I = 0 *)
      rewrite -scalemxAl mul1mx -scalemxAr mulmx1 -scalerDr addNr scaler0.
      reflexivity.
    - (* (2,1): -((1-u²)*:S) + S = u²*:S *)
      rewrite mulNmx -scalemxAr mulmx1 scalerBl scale1r opprB subrK.
      reflexivity.
    - (* (2,2) *)
      have h21 : - S_mx *m ((1 - u^+2) *: (1%:M : 'M[R]_m2)) + S_mx = u^+2 *: S_mx.
      { rewrite mulNmx -scalemxAr mulmx1 scalerBl scale1r opprB subrK. reflexivity. }
      have h22 : - S_mx *m (u *: T_mx^T - u^+2 *: S_mx^T) + (1%:M : 'M[R]_n) =
                 I_n - u *: A_mx + u^+2 *: D_mx.
      { rewrite mulNmx mulmxBr -!scalemxAr S_T S_S opprB.
        rewrite addrC addrA addrAC. reflexivity. }
      rewrite h21 h22.
      rewrite -scalemxAl mulmxN mulmxBr -!scalemxAr S_T S_S.
      rewrite mulmx1 opprB.
      (* Goal: u²(u²D - uA) + (1-u²)(I - uA + u²D) = (1-u²)I - uA + u²D *)
      set Z := u ^+ 2 *: D_mx - u *: A_mx.
      have eqW : forall (W : 'M[R]_n), W - u *: A_mx + u ^+ 2 *: D_mx = W + Z.
      { move=> W. rewrite /Z addrAC -addrA. done. }
      rewrite !eqW.
      (* Now: u²Z + (1-u²)(I + Z) = (1-u²)I + Z *)
      rewrite [_ *: (1%:M + _)]scalerDr addrCA -scalerDl.
      have -> : u ^+ 2 + (1 - u ^+ 2) = 1 :> R.
      { by rewrite addrC addrNK. }
      by rewrite scale1r. }

  have detH1 : \det P1 * \det M = \det (I_m2 - u *: B_mx).
  { rewrite -det_mulmx H1 det_lblock det1 mulr1. done. }
  have detP1 : \det P1 = 1.
  { by rewrite /P1 det_ublock !det1 mulr1. }

  have detH2 : \det P5 * (\det P3 * \det M) * \det P6 = \det ((1 - u^+2) *: I_m2) * \det ((1 - u^+2) *: I_n - u *: A_mx + u^+2 *: D_mx).
  { rewrite -!det_mulmx H2 det_lblock. done. }

  have detP5 : \det P5 = 1.
  { by rewrite /P5 det_lblock !det1 mulr1. }
  have detP3 : \det P3 = \det (I_m2 - u *: J_mx).
  { by rewrite /P3 det_ublock det1 mulr1. }
  have detP6 : \det P6 = (1 - u^+2)^+n.
  { rewrite /P6 det_ublock det1 mul1r.
    by rewrite detZ det1 mulr1. }

  rewrite detP5 mul1r detP3 detP6 in detH2.
  rewrite detP1 mul1r in detH1.


  rewrite detH1 in detH2.
  rewrite detZ det1 mulr1 in detH2.
  rewrite (mulrC (\det (I_m2 - u *: J_mx))) in detH2.
  exact detH2.
Qed.

End BassIhara.
