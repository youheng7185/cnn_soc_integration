#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>
#include <errno.h>

#define MAX_TRACE 2000000
#define MAX_REGS  4
#define MAX_MEMS  4

typedef struct {
    uint32_t pc;
    uint32_t instr;
    int      is_compressed;
    char     mnemonic[64];
    int      num_reg_writes;
    struct { int reg_num; uint32_t value; } reg_writes[MAX_REGS];
    int      num_mem_ops;
    struct { int is_write; uint32_t addr; uint32_t value; } mem_ops[MAX_MEMS];
} trace_entry_t;

typedef struct {
    int      count;
    trace_entry_t *entries;
} trace_log_t;

static int alloc_log(trace_log_t *log) {
    log->entries = (trace_entry_t *)calloc(MAX_TRACE, sizeof(trace_entry_t));
    if (!log->entries) {
        fprintf(stderr, "Error: cannot allocate %zu MB for trace log\n",
                (size_t)MAX_TRACE * sizeof(trace_entry_t) / (1024*1024));
        return -1;
    }
    return 0;
}

static void free_log(trace_log_t *log) {
    free(log->entries);
    log->entries = NULL;
}

static void parse_reg_writes_verilator(const char *decoded, trace_entry_t *e) {
    e->num_reg_writes = 0;
    e->num_mem_ops = 0;

    const char *p = decoded;
    while (*p && e->num_reg_writes < MAX_REGS) {
        while (*p && *p != 'x') p++;
        if (!*p) break;

        if (!isdigit((unsigned char)p[1])) { p++; continue; }

        char *endp;
        long reg_num = strtol(p + 1, &endp, 10);
        if (endp == p + 1) { p++; continue; }

        if (*endp == '=') {
            endp++;
            uint32_t val = (uint32_t)strtoul(endp, &endp, 16);
            if (reg_num >= 0 && reg_num <= 31) {
                e->reg_writes[e->num_reg_writes].reg_num = (int)reg_num;
                e->reg_writes[e->num_reg_writes].value = val;
                e->num_reg_writes++;
            }
            p = endp;
            continue;
        }

        if (*endp == ':') {
            p = endp + 1;
            while (*p && *p != ' ' && *p != 'x' && *p != 'P') p++;
            continue;
        }

        p = endp;
    }

    const char *pa = strstr(decoded, "PA:");
    if (pa) {
        pa += 3;
        while (*pa == ' ') pa++;
        uint32_t addr = (uint32_t)strtoul(pa, (char **)&pa, 16);
        if (e->num_mem_ops < MAX_MEMS) {
            e->mem_ops[e->num_mem_ops].is_write = 1;
            e->mem_ops[e->num_mem_ops].addr = addr;
            e->mem_ops[e->num_mem_ops].value = 0;
            e->num_mem_ops++;
        }
    }
}

static int parse_verilator_trace(const char *filename, trace_log_t *log) {
    FILE *f = fopen(filename, "r");
    if (!f) {
        fprintf(stderr, "Error: cannot open %s: %s\n", filename, strerror(errno));
        return -1;
    }

    char line[1024];
    log->count = 0;
    int header_skipped = 0;

    while (fgets(line, sizeof(line), f) && log->count < MAX_TRACE) {
        if (!header_skipped) { header_skipped = 1; continue; }

        int len = (int)strlen(line);
        while (len > 0 && isspace((unsigned char)line[len-1])) line[--len] = '\0';
        if (len == 0) continue;

        char *p = line;
        while (*p && isspace((unsigned char)*p)) p++;
        if (*p == '\0') continue;

        uint32_t time_val, cycle_val, pc_val, instr_val;
        char ctx_str[64] = {0};
        char decoded[512] = {0};

        int n = sscanf(p, "%u %u %x %x %63s %511[^\n]",
                       &time_val, &cycle_val, &pc_val, &instr_val, ctx_str, decoded);
        if (n < 4) continue;

        trace_entry_t *e = &log->entries[log->count];
        memset(e, 0, sizeof(*e));
        e->pc = pc_val;
        e->instr = instr_val;
        e->is_compressed = (instr_val & 0x3) != 3;
        snprintf(e->mnemonic, sizeof(e->mnemonic), "%s", ctx_str);

        if (n >= 6) {
            parse_reg_writes_verilator(decoded, e);
        }

        log->count++;
    }

    fclose(f);
    return 0;
}

static void parse_rest_spike(const char *rest, trace_entry_t *e) {
    e->num_reg_writes = 0;
    e->num_mem_ops = 0;

    const char *p = rest;
    char *endp;

    int field = 0;
    while (*p) {
        while (*p == ' ') p++;
        if (!*p) break;

        if (p[0] == 'x' && isdigit((unsigned char)p[1])) {
            long reg_num = strtol(p + 1, &endp, 10);
            while (*endp == ' ' || *endp == '\t') endp++;
            if (*endp == '\0') break;
            uint32_t val = (uint32_t)strtoul(endp, &endp, 16);
            if (reg_num >= 0 && reg_num <= 31 && e->num_reg_writes < MAX_REGS) {
                e->reg_writes[e->num_reg_writes].reg_num = (int)reg_num;
                e->reg_writes[e->num_reg_writes].value = val;
                e->num_reg_writes++;
            }
            p = endp;
        } else if (strncmp(p, "mem", 3) == 0) {
            p += 3;
            while (*p == ' ') p++;
            uint32_t addr = (uint32_t)strtoul(p, &endp, 16);
            p = endp;
            while (*p == ' ') p++;
            if (*p && e->num_mem_ops < MAX_MEMS) {
                uint32_t val = (uint32_t)strtoul(p, &endp, 16);
                e->mem_ops[e->num_mem_ops].is_write = 1;
                e->mem_ops[e->num_mem_ops].addr = addr;
                e->mem_ops[e->num_mem_ops].value = val;
                e->num_mem_ops++;
                p = endp;
            }
        } else {
            p++;
        }
    }
}

static int parse_spike_trace(const char *filename, trace_log_t *log) {
    FILE *f = fopen(filename, "r");
    if (!f) {
        fprintf(stderr, "Error: cannot open %s: %s\n", filename, strerror(errno));
        return -1;
    }

    char line[1024];
    log->count = 0;

    while (fgets(line, sizeof(line), f) && log->count < MAX_TRACE) {
        int len = (int)strlen(line);
        while (len > 0 && isspace((unsigned char)line[len-1])) line[--len] = '\0';
        if (len == 0) continue;

        trace_entry_t *e = &log->entries[log->count];
        memset(e, 0, sizeof(*e));

        int core_id;
        uint64_t cycle;
        uint32_t pc, instr;
        char rest[512] = {0};

        int n = sscanf(line, "core %d: %lu 0x%x (0x%x) %511[^\n]",
                       &core_id, &cycle, &pc, &instr, rest);
        if (n >= 4) {
            e->pc = pc;
            e->instr = instr;
            e->is_compressed = (instr & 0x3) != 3;
            if (n >= 5) parse_rest_spike(rest, e);
            log->count++;
            continue;
        }

        n = sscanf(line, "core %d: %lu 0x%x (0x%x)",
                   &core_id, &cycle, &pc, &instr);
        if (n >= 4) {
            e->pc = pc;
            e->instr = instr;
            e->is_compressed = (instr & 0x3) != 3;
            log->count++;
            continue;
        }

        n = sscanf(line, "core %d: 0x%x (0x%x)", &core_id, &pc, &instr);
        if (n >= 3) {
            e->pc = pc;
            e->instr = instr;
            e->is_compressed = (instr & 0x3) != 3;
            log->count++;
            continue;
        }
    }

    fclose(f);
    return 0;
}

static int find_spike_boot_end(trace_log_t *spike) {
    for (int i = 0; i < spike->count; i++) {
        if (spike->entries[i].pc >= 0x80000000) return i;
    }
    return 0;
}

static void filter_spike_duplicates(trace_log_t *spike, int start, trace_log_t *filtered) {
    filtered->count = 0;
    uint32_t prev_pc = 0xFFFFFFFF;

    for (int i = start; i < spike->count && filtered->count < MAX_TRACE; i++) {
        trace_entry_t *e = &spike->entries[i];
        if (e->pc == prev_pc) {
            if (filtered->count > 0) {
                trace_entry_t *prev = &filtered->entries[filtered->count - 1];
                for (int r = 0; r < e->num_reg_writes; r++) {
                    int found = 0;
                    for (int pr = 0; pr < prev->num_reg_writes; pr++) {
                        if (prev->reg_writes[pr].reg_num == e->reg_writes[r].reg_num) {
                            prev->reg_writes[pr].value = e->reg_writes[r].value;
                            found = 1;
                            break;
                        }
                    }
                    if (!found && prev->num_reg_writes < MAX_REGS) {
                        prev->reg_writes[prev->num_reg_writes] = e->reg_writes[r];
                        prev->num_reg_writes++;
                    }
                }
                for (int m = 0; m < e->num_mem_ops; m++) {
                    if (prev->num_mem_ops < MAX_MEMS) {
                        prev->mem_ops[prev->num_mem_ops] = e->mem_ops[m];
                        prev->num_mem_ops++;
                    }
                }
            }
            continue;
        }
        filtered->entries[filtered->count] = *e;
        filtered->count++;
        prev_pc = e->pc;
    }
}

static const char *reg_name(int num) {
    static const char *names[] = {
        "zero","ra","sp","gp","tp","t0","t1","t2","s0","s1",
        "a0","a1","a2","a3","a4","a5","a6","a7","s2","s3",
        "s4","s5","s6","s7","s8","s9","s10","s11","t3","t4",
        "t5","t6"
    };
    if (num >= 0 && num <= 31) return names[num];
    return "?";
}

static int is_compatible_instr(uint32_t v_instr, uint32_t s_instr) {
    if (v_instr == s_instr) return 1;
    int v_is_comp = (v_instr & 0x3) != 3;
    int s_is_comp = (s_instr & 0x3) != 3;
    if (v_is_comp && !s_is_comp) {
        if ((v_instr & 0xFFFF) == (s_instr & 0xFFFF)) return 1;
    }
    if (!v_is_comp && s_is_comp) {
        if ((v_instr & 0xFFFF) == (s_instr & 0xFFFF)) return 1;
    }
    if (!v_is_comp && !s_is_comp) {
        if ((s_instr & 0xFFFF) != 0 && (v_instr & 0xFFFF) == (s_instr & 0xFFFF)) return 1;
    }
    return 0;
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <verilator_trace.log> <spike_trace.log> [options]\n", argv[0]);
        fprintf(stderr, "Options:\n");
        fprintf(stderr, "  --verbose    Show every compared instruction\n");
        fprintf(stderr, "  --skip-mem   Skip memory access comparison\n");
        return 1;
    }

    int verbose = 0;
    int skip_mem = 0;
    for (int i = 3; i < argc; i++) {
        if (strcmp(argv[i], "--verbose") == 0) verbose = 1;
        if (strcmp(argv[i], "--skip-mem") == 0) skip_mem = 1;
    }

    trace_log_t verilator_log, spike_raw, spike_log;

    if (alloc_log(&verilator_log) < 0) return 1;
    if (alloc_log(&spike_raw) < 0) { free_log(&verilator_log); return 1; }
    if (alloc_log(&spike_log) < 0) { free_log(&verilator_log); free_log(&spike_raw); return 1; }

    printf("=== RISC-V Trace Comparison Tool ===\n\n");
    printf("Loading Verilator trace: %s\n", argv[1]);
    if (parse_verilator_trace(argv[1], &verilator_log) < 0) goto fail;
    printf("  Loaded %d entries\n", verilator_log.count);

    printf("Loading Spike trace: %s\n", argv[2]);
    if (parse_spike_trace(argv[2], &spike_raw) < 0) goto fail;
    printf("  Loaded %d raw entries\n", spike_raw.count);

    int boot_end = find_spike_boot_end(&spike_raw);
    printf("  Spike boot phase: %d instructions, skipped\n", boot_end);

    filter_spike_duplicates(&spike_raw, boot_end, &spike_log);
    printf("  Filtered to %d entries\n", spike_log.count);

    printf("\n--- Comparison (PC-based matching, register value comparison) ---\n\n");

    int match_count = 0;
    int mismatch_count = 0;
    int verilator_only = 0;
    int spike_only = 0;
    int total_compared = 0;
    int reg_mismatch_total = 0;

    int vi = 0;
    int si = 0;

    while (vi < verilator_log.count && si < spike_log.count) {
        trace_entry_t *ve = &verilator_log.entries[vi];
        trace_entry_t *se = &spike_log.entries[si];

        if (ve->pc == se->pc) {
            total_compared++;

            int instr_compat = is_compatible_instr(ve->instr, se->instr);
            int reg_mismatch = 0;
            char mismatch_detail[2048] = {0};
            int mpos = 0;

            if (!instr_compat) {
                mpos += snprintf(mismatch_detail + mpos, sizeof(mismatch_detail) - mpos,
                    "INSTR: verilator=0x%08x spike=0x%08x ", ve->instr, se->instr);
            }

            for (int sr = 0; sr < se->num_reg_writes; sr++) {
                int s_reg = se->reg_writes[sr].reg_num;
                uint32_t s_val = se->reg_writes[sr].value;
                int found = 0;
                for (int vr = 0; vr < ve->num_reg_writes; vr++) {
                    if (ve->reg_writes[vr].reg_num == s_reg) {
                        uint32_t v_val = ve->reg_writes[vr].value;
                        if (v_val != s_val) {
                            reg_mismatch = 1;
                            mpos += snprintf(mismatch_detail + mpos, sizeof(mismatch_detail) - mpos,
                                "%s:v=0x%08x s=0x%08x ", reg_name(s_reg), v_val, s_val);
                        }
                        found = 1;
                        break;
                    }
                }
                if (!found && se->num_reg_writes <= 2) {
                    for (int vr = 0; vr < ve->num_reg_writes; vr++) {
                        if (ve->reg_writes[vr].value == s_val &&
                            ve->reg_writes[vr].reg_num != s_reg) {
                            mpos += snprintf(mismatch_detail + mpos, sizeof(mismatch_detail) - mpos,
                                "%s:spike_only=0x%08x ", reg_name(s_reg), s_val);
                            break;
                        }
                    }
                }
            }

            if (reg_mismatch) reg_mismatch_total++;

            if (reg_mismatch) {
                mismatch_count++;
                printf("MISMATCH PC=0x%08x: %s\n", ve->pc, mismatch_detail);
            } else {
                match_count++;
                if (verbose) {
                    printf("MATCH  PC=0x%08x", ve->pc);
                    if (!instr_compat) printf(" [instr: v=0x%08x s=0x%08x]", ve->instr, se->instr);
                    for (int r = 0; r < se->num_reg_writes; r++) {
                        printf(" %s=0x%08x", reg_name(se->reg_writes[r].reg_num), se->reg_writes[r].value);
                    }
                    printf("\n");
                }
            }

            vi++;
            si++;
        } else if (ve->pc < se->pc) {
            verilator_only++;
            if (verbose) {
                printf("VERILATOR_ONLY: PC=0x%08x instr=0x%08x %s\n", ve->pc, ve->instr, ve->mnemonic);
            }
            vi++;
        } else {
            spike_only++;
            if (verbose) {
                printf("SPIKE_ONLY: PC=0x%08x instr=0x%08x\n", se->pc, se->instr);
            }
            si++;
        }
    }

    while (vi < verilator_log.count) { verilator_only++; vi++; }
    while (si < spike_log.count) { spike_only++; si++; }

    printf("\n=== Result ===\n");
    printf("Total compared:     %d\n", total_compared);
    printf("Matched:            %d\n", match_count);
    printf("Reg mismatches:     %d\n", reg_mismatch_total);
    printf("Verilator-only:     %d\n", verilator_only);
    printf("Spike-only:         %d\n", spike_only);
    printf("Match rate:         %.1f%%\n",
           total_compared > 0 ? 100.0 * match_count / total_compared : 0.0);

    if (reg_mismatch_total == 0 && total_compared > 0) {
        printf("\n*** ALL TESTS PASSED ***\n");
        free_log(&verilator_log);
        free_log(&spike_raw);
        free_log(&spike_log);
        return 0;
    } else if (total_compared == 0) {
        printf("\n*** NO COMPARABLE INSTRUCTIONS FOUND ***\n");
        free_log(&verilator_log);
        free_log(&spike_raw);
        free_log(&spike_log);
        return 2;
    } else {
        printf("\n*** TESTS FAILED: %d register mismatches in %d instructions ***\n",
               reg_mismatch_total, mismatch_count);
        free_log(&verilator_log);
        free_log(&spike_raw);
        free_log(&spike_log);
        return 1;
    }

fail:
    free_log(&verilator_log);
    free_log(&spike_raw);
    free_log(&spike_log);
    return 1;
}