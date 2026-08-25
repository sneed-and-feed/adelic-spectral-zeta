pragma circom 2.1.0;

/**
 * ============================================================================
 * P-ADIC TREE LCA ROUTING & NON-INTERFERENCE CIRCOM TEMPLATES
 * ============================================================================
 * 
 * Provides zero-knowledge circuit templates for:
 * 1. DigitRangeCheck: Algebraic polynomial vanishing range proofs for base-p limbs.
 * 2. DigitExtractor: Base-p hierarchical digit expansion on Bruhat-Tits trees.
 * 3. PrefixMatcher: LCA prefix equality matching and cumulative connection routing.
 * 4. PAdicPairLCA: Pairwise p-adic distance and LCA connection indicator.
 * 5. PAdicBlockRouting: Full multi-block / multi-head attention routing matrix generator.
 * 6. NonInterferenceGuard: Algebraic isolation guard enforcing cross-domain safety.
 */

// ============================================================================
// 1. Auxiliary Primitives
// ============================================================================

/**
 * IsZero: Outputs 1 if in == 0, else 0 using rank-1 inverse witness.
 */
template IsZero() {
    signal input in;
    signal output out;
    signal inv;

    inv <-- in != 0 ? 1 / in : 0;
    out <-- in == 0 ? 1 : 0;

    in * out === 0;
    in * inv === 1 - out;
}

/**
 * DigitRangeCheck: Enforces in \in {0, 1, ..., p - 1} via polynomial root vanishing:
 *                  \prod_{j=0}^{p-1} (in - j) === 0
 */
template DigitRangeCheck(p) {
    signal input in;

    if (p <= 1) {
        // Unreachable valid arity
        1 === 0;
    } else if (p == 2) {
        // Boolean check: in * (1 - in) === 0
        in * (1 - in) === 0;
    } else if (p == 3) {
        signal step0;
        step0 <== in * (in - 1);
        step0 * (in - 2) === 0;
    } else {
        signal step[p - 2];
        step[0] <== in * (in - 1);
        for (var j = 2; j < p - 1; j++) {
            step[j - 1] <== step[j - 2] * (in - j);
        }
        step[p - 3] * (in - (p - 1)) === 0;
    }
}


// ============================================================================
// 2. Base-p Digit Extraction
// ============================================================================

/**
 * DigitExtractor: Decomposes integer in \in [0, p^D - 1] into D base-p digits.
 *
 * Digits are arranged MSB-first:
 *   digits[0] is root-level branch (weight p^{D-1})
 *   digits[D-1] is leaf-level branch (weight p^0)
 *
 * Parameters:
 *   p: Tree branching factor (p >= 2)
 *   D: Tree depth (D >= 1)
 */
template DigitExtractor(p, D) {
    signal input in;
    signal output digits[D];

    // Precompute static powers of p
    var p_pow[D];
    p_pow[D - 1] = 1;
    for (var i = D - 2; i >= 0; i--) {
        p_pow[i] = p_pow[i + 1] * p;
    }

    // Unconstrained witness decomposition
    var rem = in;
    for (var i = 0; i < D; i++) {
        digits[i] <-- (rem \ p_pow[i]) % p;
        rem = rem - digits[i] * p_pow[i];
    }

    // Enforce range constraints: digits[i] \in {0, ..., p - 1}
    component range_checks[D];
    for (var i = 0; i < D; i++) {
        range_checks[i] = DigitRangeCheck(p);
        range_checks[i].in <== digits[i];
    }

    // Reconstruct composite value: sum_{i=0}^{D-1} digits[i] * p_pow[i] === in
    signal acc[D];
    acc[0] <== digits[0] * p_pow[0];
    for (var i = 1; i < D; i++) {
        acc[i] <== acc[i - 1] + digits[i] * p_pow[i];
    }

    acc[D - 1] === in;
}


// ============================================================================
// 3. LCA Prefix Matching
// ============================================================================

/**
 * PrefixMatcher: Checks if two p-adic tree paths share a common prefix of length req_depth.
 *
 * Parameters:
 *   D: Total tree depth
 *   req_depth: Prefix depth required for attention / connection (0 <= req_depth <= D)
 *
 * Outputs:
 *   eq[req_depth]: Equality indicator at each prefix level
 *   match: 1 if all req_depth levels match, 0 otherwise
 */
template PrefixMatcher(D, req_depth) {
    signal input u_digits[D];
    signal input v_digits[D];
    signal output eq[req_depth];
    signal output match;

    // Level-by-level zero check
    component is_zero[req_depth];
    for (var k = 0; k < req_depth; k++) {
        is_zero[k] = IsZero();
        is_zero[k].in <== u_digits[k] - v_digits[k];
        eq[k] <== is_zero[k].out;
    }

    // Cumulative product of equality indicators
    if (req_depth == 0) {
        match <== 1;
    } else if (req_depth == 1) {
        match <== eq[0];
    } else {
        signal cum[req_depth - 1];
        cum[0] <== eq[0] * eq[1];
        for (var k = 2; k < req_depth; k++) {
            cum[k - 1] <== cum[k - 2] * eq[k];
        }
        match <== cum[req_depth - 2];
    }
}


// ============================================================================
// 4. Pairwise p-Adic LCA Routing
// ============================================================================

/**
 * PAdicPairLCA: High-level template verifying routing between two scalar node IDs.
 */
template PAdicPairLCA(p, D, req_depth) {
    signal input u;
    signal input v;
    signal output match;

    component ext_u = DigitExtractor(p, D);
    component ext_v = DigitExtractor(p, D);

    ext_u.in <== u;
    ext_v.in <== v;

    component matcher = PrefixMatcher(D, req_depth);
    for (var k = 0; k < D; k++) {
        matcher.u_digits[k] <== ext_u.digits[k];
        matcher.v_digits[k] <== ext_v.digits[k];
    }

    match <== matcher.match;
}


// ============================================================================
// 5. Multi-Block Attention Routing System
// ============================================================================

/**
 * PAdicBlockRouting: Generates the full (num_blocks x num_blocks) attention routing matrix
 *                    based on lowest common ancestor prefix overlap.
 *
 * Parameters:
 *   num_blocks: Number of token / sequence blocks
 *   p: Tree branching arity
 *   D: Tree depth
 *   req_depth: Required common prefix depth
 */
template PAdicBlockRouting(num_blocks, p, D, req_depth) {
    signal input block_ids[num_blocks];
    signal output routing_matrix[num_blocks][num_blocks];

    // Decompose all blocks into digits
    component extractors[num_blocks];
    for (var i = 0; i < num_blocks; i++) {
        extractors[i] = DigitExtractor(p, D);
        extractors[i].in <== block_ids[i];
    }

    // Pairwise prefix matchers
    component matchers[num_blocks][num_blocks];
    for (var i = 0; i < num_blocks; i++) {
        for (var j = 0; j < num_blocks; j++) {
            if (i == j) {
                // Identity self-attention is unconditionally enabled
                routing_matrix[i][j] <== 1;
            } else {
                matchers[i][j] = PrefixMatcher(D, req_depth);
                for (var k = 0; k < D; k++) {
                    matchers[i][j].u_digits[k] <== extractors[i].digits[k];
                    matchers[i][j].v_digits[k] <== extractors[j].digits[k];
                }
                routing_matrix[i][j] <== matchers[i][j].match;
            }
        }
    }
}


// ============================================================================
// 6. Non-Interference Safety Guard
// ============================================================================

/**
 * NonInterferenceGuard: Enforces that forbidden pairs (as designated in forbidden_mask)
 *                       have routing_matrix[i][j] === 0.
 *
 * If forbidden_mask[i][j] == 1, then routing_matrix[i][j] MUST be 0.
 * The algebraic constraint forbidden_mask[i][j] * routing_matrix[i][j] === 0
 * makes cross-tenant or unsafe cross-domain routing mathematically unprovable.
 */
template NonInterferenceGuard(num_blocks) {
    signal input routing_matrix[num_blocks][num_blocks];
    signal input forbidden_mask[num_blocks][num_blocks];
    signal output safety_passed;

    for (var i = 0; i < num_blocks; i++) {
        for (var j = 0; j < num_blocks; j++) {
            forbidden_mask[i][j] * routing_matrix[i][j] === 0;
        }
    }

    safety_passed <== 1;
}
