# == benchmark prototype: one-command closed-loop baseline ===========
# v0.5.0 "基准原型 R 包" (user decision 2026-08-08: R-only baseline,
# Java is the future implementation language; Python is not invested).
#
# Two entry points prove the complete closed loop is usable and
# reproducible, serving as the reference baseline for all later work:
#
#   demo_full_loop()    PAL -> expand -> compute -> closure -> fold-back
#                       -> package -> fresh-process reload
#   benchmark_all()     all 7 Efficiency-gate measurements in one call
#
# Design: pure wrappers over existing frozen functions. No new
# semantics; the prototype is a usability/reproducibility contract.

#' @title Run the full closed-loop demo (benchmark prototype)
#' @description One-command proof of the complete visualR loop:
#'   canonical PAL state -> materialize -> compute -> closure decision ->
#'   fold back -> package -> reload in a fresh process -> reproduce the
#'   same canonical state. Prints every step and returns a named list
#'   with the step results.
#' @param state list with `shells` and `core` (default S4). Pass
#'   \code{NULL} to run the canonical S4 example.
#' @param op single character, operator name passed to compute_jiugong
#'   (default "identity").
#' @return named list with fields: pal, matrix, verdict, folded,
#'   pkg, reload_ok. All reproducible.
#' @examples
#' demo_full_loop()
demo_full_loop <- function(state = NULL, op = "identity") {
  if (is.null(state)) {
    state <- list(shells = c("A", "B", "C", "D"), core = "e")
  }
  cat("==== visualR 基准原型 · 全闭环演示 ====\n")

  # 1. Construct + validate canonical PAL state
  pal <- new_pal_state(state$shells, state$core)
  cat(sprintf("1. 构造PAL状态: %s\n", format_pal(pal)))

  # 2. Materialize the approved compute view (unified dispatch)
  m <- materialize(pal)
  stopifnot(m$ok)
  cat(sprintf("2. 展开九宫载体 [%s]: %d 格\n", m$carrier, length(m$grid)))

  # 3. Compute on CPU (serial reference semantics)
  grid <- compute_jiugong(m$grid, op, mapping_pack_id = pal$mapping_pack_id)
  cat(sprintf("3. CPU计算 (op=%s): 闭合=%s\n", op,
              closure_check(grid, pal$mapping_pack_id)))

  # 4. Closure / transition decision
  verdict <- transition_policy(grid, pal$mapping_pack_id)
  cat(sprintf("4. 过渡决策: %s\n", verdict))

  # 5. Fold back to canonical storage when legal
  folded <- NULL
  if (verdict == "promote") {
    folded <- jiugong_to_pal(
      structure(list(grid = grid, mapping_pack_id = pal$mapping_pack_id),
                class = "visualr_jiugong")
    )
    cat(sprintf("5. 折返存储: %s\n", format_pal(folded)))
  } else {
    cat(sprintf("5. 折返: 跳过 (verdict=%s, 非promote)\n", verdict))
  }

  # 6. Package the canonical state
  pkg <- package_state(pal)
  cat(sprintf("6. 打包: %s (checksum %s)\n", pkg$format,
              substr(pkg$checksum, 1, 12)))

  # 7. Reload in a fresh process and reproduce the same state
  reload_ok <- package_reload_check(pkg)
  cat(sprintf("7. 重载复现: %s\n", if (reload_ok) "OK (同一canonical state)" else "FAILED"))

  invisible(list(pal = pal, matrix = grid, verdict = verdict,
                 folded = folded, pkg = pkg, reload_ok = reload_ok))
}

#' @title Run all 7 Efficiency-gate measurements (benchmark prototype)
#' @description One-command reproducible measurement suite covering the
#'   v0.5.0 Efficiency gate: compact stored size, expanded working set,
#'   transfer size, peak RAM estimate, encode/expand/fold overhead,
#'   serial latency, concurrent throughput. Returns an invisible list
#'   with each data.frame.
#' @param overhead_reps integer, iterations for the overhead timing.
#' @param latency_reps integer, iterations for the latency timing.
#' @param throughput_n integer, batch size for throughput.
#' @return invisible named list of data.frames:
#'   storage, transfer, ram, overhead, latency, throughput.
#' @examples
#' benchmark_all()
benchmark_all <- function(overhead_reps = 100L,
                          latency_reps = 50L,
                          throughput_n = 2000L) {
  cat("==== visualR 基准原型 · Efficiency Gate 全量测量 ====\n")
  out <- list(
    storage    = benchmark_storage(),
    transfer   = benchmark_transfer(),
    ram        = benchmark_peak_ram(),
    overhead   = benchmark_overhead(reps = overhead_reps),
    latency    = benchmark_latency(reps = latency_reps),
    throughput = benchmark_throughput(n = throughput_n)
  )
  cat("\n--- 1. compact stored size (PAL vs matrix bytes) ---\n")
  print(out$storage[, c("dim", "pal_bytes", "matrix_bytes", "reduction")])
  cat("\n--- 2. transfer size ---\n")
  print(out$transfer)
  cat("\n--- 3. peak RAM (object.size estimate) ---\n")
  print(out$ram)
  cat("\n--- 4. encode/expand/fold overhead (ms) ---\n")
  print(out$overhead)
  cat("\n--- 5. serial round-trip latency (ms) ---\n")
  print(out$latency)
  cat("\n--- 6. concurrent throughput ---\n")
  print(out$throughput)
  invisible(out)
}
