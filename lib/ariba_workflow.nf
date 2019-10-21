include './ariba/processes' params(params)

workflow ariba {
  get: raw_fastqs

  main:
    database_dir = file(params.ariba_database_dir)
    ariba_reports = run_ariba(raw_fastqs, database_dir)
    all_ariba_reports = ariba_reports.collect { it }

    ariba_summary(all_ariba_reports, params.ariba_database_dir)
}