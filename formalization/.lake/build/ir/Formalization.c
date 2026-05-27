// Lean compiler output
// Module: Formalization
// Imports: Init Formalization.SpectralGRH Formalization.CollatzGalois Formalization.SchreierConnectivity Formalization.SchreierSpectral Formalization.SchreierTrace Formalization.Partition Formalization.IharaZeta
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
lean_object* initialize_Formalization_SpectralGRH(uint8_t builtin, lean_object*);
lean_object* initialize_Formalization_CollatzGalois(uint8_t builtin, lean_object*);
lean_object* initialize_Formalization_SchreierConnectivity(uint8_t builtin, lean_object*);
lean_object* initialize_Formalization_SchreierSpectral(uint8_t builtin, lean_object*);
lean_object* initialize_Formalization_SchreierTrace(uint8_t builtin, lean_object*);
lean_object* initialize_Formalization_Partition(uint8_t builtin, lean_object*);
lean_object* initialize_Formalization_IharaZeta(uint8_t builtin, lean_object*);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_Formalization(uint8_t builtin, lean_object* w) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_SpectralGRH(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_CollatzGalois(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_SchreierConnectivity(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_SchreierSpectral(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_SchreierTrace(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_Partition(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_IharaZeta(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
