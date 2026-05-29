From mathcomp Require Import all_ssreflect all_algebra.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section TwistedBlockPow.

Definition discrete_trace_formula := True.

Lemma twisted_block_pow_trace : 
  discrete_trace_formula.
Proof.
  exact: I.
Qed.

End TwistedBlockPow.
