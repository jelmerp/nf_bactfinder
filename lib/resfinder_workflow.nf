include './resfinder/processes' params(params)

workflow resfinder{
  get: raw_fastqs

  main:
    resfinder_outputs = run_resfinder(raw_fastqs)
    all_resfinder_outputs = resfinder_outputs.collect { it }
    resfinder_summary(all_resfinder_outputs)
}