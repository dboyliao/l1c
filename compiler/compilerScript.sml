open HolKernel boolLib bossLib l1_to_il1_compilerTheory il1_to_il2_compilerTheory store_creationTheory il1_il2_correctnessTheory l1_il1_correctnessTheory lcsymtacs il2_to_il3_compilerTheory listTheory pairTheory pred_setTheory l1_il1_totalTheory bigstep_il1Theory ast_l1Theory store_equivalenceTheory finite_mapTheory il3_to_vsm0_correctnessTheory il3_store_propertiesTheory il2_il3_correctnessTheory bs_ss_equivalenceTheory smallstep_vsm0_clockedTheory bigstep_il1_clockedTheory;

val _ = new_theory "compiler"

val il2_vsm_correctness_1 = store_thm("il2_vsm_correctness",``
!P pc c stk st.
exec_clocked P (SOME (pc, c, stk, st)) NONE /\ ms_il2 P st ==>

vsm_exec_c (il2_to_il3 P) (SOME (pc, c, astack (il2_to_il3 P) (MAP_KEYS (map_fun (FST (make_loc_map P))) st) stk)) NONE``,

rw []
THEN imp_res_tac IL2_IL3_EQ_1
THEN imp_res_tac vsm_exec_correctness_1_thm

THEN `ms_il2 P st ==> (!l.l ∈ FDOM (MAP_KEYS (map_fun (FST (make_loc_map P))) st) <=> (l < s_uloc (il2_to_il3 P)))` by metis_tac [min_store_imp_all_locs_in_range]

THEN metis_tac []);

val il2_vsm_correctness_2 = store_thm("il2_vsm_correctness",``
!P pc c stk st pc' c' stk' st'.
exec_clocked P (SOME (pc, c, stk, st)) (SOME (pc', c', stk', st')) /\ ms_il2 P st ==>

?n astk.vsm_exec_c (il2_to_il3 P) (SOME (pc, c, astack (il2_to_il3 P) (MAP_KEYS (map_fun (FST (make_loc_map P))) st) stk)) (SOME (pc', c', astk)) /\ (stk' = TAKE n astk)``,

rw []
THEN imp_res_tac IL2_IL3_EQ_2
THEN imp_res_tac vsm_exec_correctness_2_thm

THEN `ms_il2 P st ==> (!l.l ∈ FDOM (MAP_KEYS (map_fun (FST (make_loc_map P))) st) <=> (l < s_uloc (il2_to_il3 P)))` by metis_tac [min_store_imp_all_locs_in_range]

THEN metis_tac []);

val compile_il2_def = Define `compile_il2 e = il1_to_il2 (l1_to_il1 e 0)`;

val compile_def = Define `compile e = il2_to_il3 (compile_il2 e)`;

val create_il2_store_def = Define `
(create_il2_store [] = FEMPTY) /\
(create_il2_store (IL2_Store l::xs) = (create_il2_store xs) |+ (l, 0)) /\
(create_il2_store (IL2_Load l::xs) = (create_il2_store xs) |+ (l, 0)) /\
(create_il2_store (_::xs) = (create_il2_store xs))`;

val ms_il2_st_thm = prove(``!e.ms_il2 e (create_il2_store e)``,

Induct_on `e` THEN rw [ms_il2_def, create_il2_store_def, make_loc_map_def, locs_to_map_def, get_locations_def, FST]

THEN Cases_on `h` THEN fs [create_il2_store_def, get_locations_def] THEN rw [] THEN fs [make_loc_map_def, ms_il2_def]

THEN fs [locs_to_map_def]

THEN `?m n.locs_to_map (get_locations e) = (m, n)` by metis_tac [locs_to_map_total_thm]

THEN rw [LET_DEF]

THEN metis_tac [ABSORPTION_RWT]);

fun btotal f x = f x handle HOL_ERR _ => false;

fun P id tm =
  btotal ((equal id) o fst o dest_var) tm orelse
  P id (snd(listSyntax.dest_cons tm));

fun tac P (g as (asl,w)) =
  let
    val ts = mk_set(List.concat (map (find_terms (btotal P)) (w::asl)))
    val ths = mapfilter (fn tm => map (C SPEC (ASSUME tm)) ts) asl
  in
    map_every assume_tac (List.concat ths)
  end g;


val union_abs_thm = prove(``!x y.x ⊌ y ⊌ x = x ⊌ y``,
Induct_on `x` THEN rw [FUNION_FEMPTY_1, FUNION_FEMPTY_2] THEN rw [FUNION_FUPDATE_1, FUNION_FUPDATE_2]);


val il2_store_etc = prove(``!x y.create_il2_store (x ++ y) = create_il2_store x ⊌ create_il2_store y``, Induct_on `x` THEN 
rw [create_il2_store_def, FUNION_FEMPTY_1] THEN Cases_on `h` THEN rw [create_il2_store_def, FUNION_FUPDATE_1]);

val con_store_etc = prove(``!x y.con_store (x ⊌ y) = (con_store x) ⊌ (con_store y)``, rw [con_store_def]

THEN Induct_on `x` THEN Induct_on `y` THEN rw [FUNION_FEMPTY_1, FUNION_FEMPTY_2] THEN fs [GSYM MAP_APPEND_EQUIV_THM, FUNION_FUPDATE_1, FUNION_FUPDATE_2]);

val zeroed_def = Define `zeroed m = !l.l ∈ FDOM m ==> (m ' l = 0)`;

val equiv_etc = prove(``!a b c d.equiv a b /\ equiv c d ==> equiv (a ⊌ c) (b ⊌ d)``, rw [equiv_def] THEN Cases_on `User k ∈ FDOM a`
THEN metis_tac [FUNION_DEF]);

val il2_store_etc2 = prove(``!l e.l ∈ FDOM (create_il2_store e) ==> ((create_il2_store e) ' l = 0)``,
Induct_on `e`
THEN rw [create_il2_store_def, FDOM_FEMPTY] THEN Cases_on `h` THEN fs [create_il2_store_def] THEN rw [] THEN Cases_on `i = l` THEN rw [FAPPLY_FUPDATE_THM]);


val store_equiv_gen_thm = prove(``!e n.equiv (con_store (create_store e)) (create_il2_store (il1_to_il2 (l1_to_il1 e n)))``,


Induct_on `e` THEN fs [compile_il2_def, il1_to_il2_def, il1e_to_il2_def, l1_to_il1_def, l1_to_il1_pair_def] THEN rw []

THEN1 (
rw [create_store_def]
THEN Cases_on `l` THEN
fs [l1_to_il1_pair_def] THEN rw []
THEN (TRY (Cases_on `b`)) THEN

 rw [il1_to_il2_def, create_il2_store_def, il2_store_etc, il1e_to_il2_def, con_store_def, MAP_KEYS_FEMPTY, EQUIV_REFL_THM])

THEN tac (P "n'")
THEN tac (P "n")
THEN tac (P "lc2")
THEN tac (P "lc3")
THEN tac (P "lc")
THEN rfs [LET_THM]

THEN rw []


THEN fs [il1_to_il2_def, il1e_to_il2_def]

THEN fs [il2_store_etc, create_il2_store_def, FUNION_FEMPTY_1, FUNION_FEMPTY_2, FUNION_FUPDATE_1, FUNION_FUPDATE_2]

THENL [Cases_on `Compiler lc3 ∈ FDOM (create_il2_store (il1_to_il2 sl1))` THEN Cases_on `Compiler lc3 ∈ FDOM (create_il2_store (il1e_to_il2 e1'))`,
Cases_on `Compiler lc3 ∈ FDOM (create_il2_store (il1_to_il2 sl1))` THEN Cases_on `Compiler lc3 ∈ FDOM (create_il2_store (il1e_to_il2 e1'))`,
Cases_on `Compiler lc4 ∈ FDOM (create_il2_store (il1_to_il2 sl1))` THEN Cases_on `Compiler lc4 ∈ FDOM (create_il2_store (il1e_to_il2 e1'))`, Cases_on `User n ∈ FDOM (create_il2_store (il1_to_il2 sl))` THEN (Cases_on `User n ∈ FDOM (create_il2_store (il1e_to_il2 e'))`), all_tac, all_tac, all_tac]

THEN fs [] THEN rw [create_store_def] THEN fs [con_store_etc] THEN fs [equiv_def] THEN rw [] THEN `(create_il2_store (il1_to_il2 sl1) ⊌
 create_il2_store (il1e_to_il2 e1') ⊌
 create_il2_store (il1_to_il2 sl2) ⊌
 create_il2_store (il1e_to_il2 e2') ⊌
 create_il2_store (il1_to_il2 sl1)) = (create_il2_store (il1_to_il2 sl1) ⊌
 create_il2_store (il1e_to_il2 e1') ⊌
 create_il2_store (il1_to_il2 sl2) ⊌
 create_il2_store (il1e_to_il2 e2'))` by metis_tac [FUNION_ASSOC, union_abs_thm]
THEN rw []

THEN rw [GSYM FUNION_ASSOC, FUNION_DEF, FAPPLY_FUPDATE_THM, il2_store_etc2] THEN (TRY (metis_tac [il2_store_etc2])) THEN Cases_on `n=k` THEN rw [] THEN fs [con_store_def, GSYM MAP_APPEND_EQUIV_THM, MAP_KEYS_FEMPTY, FAPPLY_FUPDATE_THM] THEN rw [il2_store_etc2]

THEN rw [DISJ_ASSOC, EQ_IMP_THM] THEN TRY (metis_tac []));

val l1_to_il2_correctness_thm = prove(
``!e v s'.bs_l1 (e, create_store e) v s' ==> ?s''.exec (compile_il2 e) (0, [], con_store (create_store e)) (&LENGTH (compile_il2 e), [(il1_il2_val (l1_il1_val v))], s'')``,
metis_tac [compile_il2_def, L1_TO_IL1_EXISTS_CORRECTNESS_THM, CORRECTNESS_THM]);

val length_prog_thm = prove(``!e.LENGTH (compile e) = LENGTH (compile_il2 e)``, rw [compile_def, compile_il2_def, il2_to_il3_def]);

val make_stack_def = Define `make_stack e = astack (compile e)
            (MAP_KEYS (map_fun (FST (make_loc_map (compile_il2 e))))
               (create_il2_store (compile_il2 e))) []`;

val total_c_lem = prove(``!e v s'.
    bs_l1 (e, create_store e) v s' ==> 
    ?astk.
        vsm_exec (compile e) (0, make_stack e) (&LENGTH (compile e), (il1_il2_val (l1_il1_val v))::astk)``,

rw [make_stack_def]

THEN imp_res_tac l1_to_il2_correctness_thm

THEN `equiv (con_store (create_store e)) (create_il2_store (compile_il2 e))` by metis_tac [compile_il2_def, store_equiv_gen_thm]

THEN `∀st lc1' ex.
        ((st,ex,lc1') = l1_to_il1_pair 0 (FST (e,create_store e))) ⇒
        ∀fs.
          equiv (con_store (SND (e,create_store e))) fs ⇒
          ∃fs'.
            bs_il1 (st,fs) IL1_ESkip fs' ∧
            bs_il1_expr (ex,fs') (l1_il1_val v) ∧
            equiv (con_store s') fs'` by metis_tac [L1_TO_IL1_CORRECTNESS_LEMMA, SND]

THEN fs [FST, SND]
THEN `?st ex lc1.l1_to_il1_pair 0 e = (st, ex, lc1)` by metis_tac [L1_TO_IL1_TOTAL_THM]

THEN fs []
THEN res_tac

THEN `bs_il1 (l1_to_il1 e 0, create_il2_store (compile_il2 e)) (l1_il1_val v) fs'` by (rw [l1_to_il1_def, Once bs_il1_cases] THEN HINT_EXISTS_TAC THEN rw [Once bs_il1_cases])

THEN `exec (il1_to_il2 (l1_to_il1 e 0))
          (0,[],create_il2_store (compile_il2 e))
          (&LENGTH (il1_to_il2 (l1_to_il1 e 0)),
           [il1_il2_val (l1_il1_val v)],fs')` by metis_tac [CORRECTNESS_THM]

THEN `ms_il2 (compile_il2 e) (create_il2_store (compile_il2 e))` by metis_tac [ms_il2_st_thm]

THEN fs [GSYM compile_il2_def]

THEN imp_res_tac il2_vsm_correctness

THEN res_tac

THEN `?atsk.astk' = (il1_il2_val (l1_il1_val v))::atsk` by (Cases_on `astk'` THEN fs [TAKE_def]
THEN Cases_on `n' = 0` THEN fs [])

THEN metis_tac [compile_def, length_prog_thm]);

val L1_TO_VSM0_CORRECTNESS_THM = store_thm("L1_TO_VSM0_CORRECTNESS_THM", ``
!e v s'.
ss_l1^* (e, create_store e) (L1_Value v, s') ==> 
    ?astk.
        vsm_exec (compile e) (0, make_stack e) (&LENGTH (compile e), (il1_il2_val (l1_il1_val v))::astk)``,
metis_tac [total_c_lem, SS_EQ_BS_THM, EQ_IMP_THM]);

val _ = export_theory ();
