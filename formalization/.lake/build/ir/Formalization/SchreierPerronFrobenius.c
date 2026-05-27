// Lean compiler output
// Module: Formalization.SchreierPerronFrobenius
// Imports: Init Formalization.MathlibSpectral Mathlib.Data.Matrix.Basic Mathlib.LinearAlgebra.Matrix.Spectrum Mathlib.Analysis.InnerProductSpace.PiL2 Mathlib.Data.Real.Basic Mathlib.Algebra.Order.Group.Abs Formalization.SchreierConnectivity Formalization.SchreierSpectral SpectralPositivity.Matrix.PerronFrobenius
#include <lean/lean.h>
#if defined(__clang__)
#pragma clang diagnostic ignored "-Wunused-parameter"
#pragma clang diagnostic ignored "-Wunused-label"
#elif defined(__GNUC__) && !defined(__CLANG__)
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-label"
#pragma GCC diagnostic ignored "-Wunused-but-set-variable"
#endif
#ifdef __cplusplus
extern "C" {
#endif
lean_object* initialize_Init(uint8_t builtin, lean_object*);
lean_object* initialize_Formalization_MathlibSpectral(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Data_Matrix_Basic(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_LinearAlgebra_Matrix_Spectrum(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Analysis_InnerProductSpace_PiL2(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Data_Real_Basic(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Algebra_Order_Group_Abs(uint8_t builtin, lean_object*);
lean_object* initialize_Formalization_SchreierConnectivity(uint8_t builtin, lean_object*);
lean_object* initialize_Formalization_SchreierSpectral(uint8_t builtin, lean_object*);
lean_object* initialize_SpectralPositivity_Matrix_PerronFrobenius(uint8_t builtin, lean_object*);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_Formalization_SchreierPerronFrobenius(uint8_t builtin, lean_object* w) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_MathlibSpectral(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Data_Matrix_Basic(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_LinearAlgebra_Matrix_Spectrum(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Analysis_InnerProductSpace_PiL2(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Data_Real_Basic(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Algebra_Order_Group_Abs(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_SchreierConnectivity(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_SchreierSpectral(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_SpectralPositivity_Matrix_PerronFrobenius(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
