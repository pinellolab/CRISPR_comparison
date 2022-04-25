# rules to perform comparisons of CRE predictions to CRISPR data

# get pred_config file if specified in config, else create name for default pred_config file
def get_pred_config(wildcards):
  pred_config = config["comparisons"][wildcards.comparison]["pred_config"]
  if pred_config is None:
    comparison = wildcards.comparison
    pred_config = "results/" + comparison + "/pred_config.txt"
  return pred_config

# get cell type mapping files if they are specified in config
def get_cell_type_mappings(wildcards):
  ct_map_config = config["comparisons"][wildcards.comparison]["cell_type_mapping"]
  if ct_map_config is None:
    ct_map = []
  else:
    ct_map = ct_map_config.values()
  return ct_map
  
# get gene features if they are specified in config
def get_gene_features(wildcards):
  feat_config = config["comparisons"][wildcards.comparison]["gene_features"]
  if feat_config is None:
    feat = []
  else:
    feat = feat_config.values()
  return feat

# get annotation features if they are specified in config
def get_enh_features(wildcards):
  feat_config = config["comparisons"][wildcards.comparison]["enh_features"]
  if feat_config is None:
    feat = []
  else:
    feat = feat_config.values()
  return feat
  
# get enhancer assays if they are specified in config
def get_enh_assays(wildcards):
  feat_config = config["comparisons"][wildcards.comparison]["enh_assays"]
  if feat_config is None:
    feat = []
  else:
    feat = feat_config.values()
  return feat

## RULES -------------------------------------------------------------------------------------------

# create pred_config file with default values
rule createPredConfig:
  output:
    "results/{comparison}/pred_config.txt"
  params:
    pred_names = lambda wildcards: config["comparisons"][wildcards.comparison]["pred"].keys()
  conda: "../envs/r_crispr_comparison.yml"
  script:
    "../../workflow/scripts/createPredConfig.R"

# merge predictions with experimental data
rule mergePredictionsWithExperiment:
  input:
    predictions = lambda wildcards: config["comparisons"][wildcards.comparison]["pred"].values(),
    experiment  = lambda wildcards: config["comparisons"][wildcards.comparison]["expt"],
    tss_universe = lambda wildcards: config["comparisons"][wildcards.comparison]["tss_universe"],
    gene_universe = lambda wildcards: config["comparisons"][wildcards.comparison]["gene_universe"],
    pred_config = get_pred_config,
    cell_type_mapping = get_cell_type_mappings
  output:
    merged = temp("results/{comparison}/expt_pred_merged.txt.gz")
  log: "results/{comparison}/logs/mergePredictionsWithExperiment.log"
  conda: "../envs/r_crispr_comparison.yml"
  resources:
    mem = "64G"
  script:
   "../../workflow/scripts/mergePredictionsWithExperiment.R"
   
# annotate enhancers in merged data with overlapping genomic features and assays
rule annotateEnhFeatures:
  input:
    merged = "results/{comparison}/expt_pred_merged.txt.gz",
    gene_features = get_gene_features,
    enh_features = get_enh_features,
    enh_assays = get_enh_assays
  output:
    "results/{comparison}/expt_pred_merged_annot.txt.gz"
  conda: "../envs/r_crispr_comparison.yml"
  resources:
    mem = "48G"
  script:
    "../../workflow/scripts/annotateMergedData.R"
   
# perform comparisons of predictions to experimental data
rule comparePredictionsToExperiment:
  input:
    merged = "results/{comparison}/expt_pred_merged_annot.txt.gz",
    pred_config = get_pred_config
  output:
    "results/{comparison}/{comparison}_crispr_comparison.html"
  params:
     pred_names = lambda wildcards: config["comparisons"][wildcards.comparison]["pred"].keys(),
     include_missing_predictions = True,
     min_sensitivity = 0.7,
     dist_bins_kb = lambda wildcards: config["comparisons"][wildcards.comparison]["dist_bins_kb"]
  conda: "../envs/r_crispr_comparison.yml"
  resources:
    mem = "8G"
  script:
    "../../workflow/scripts/comparePredictionsToExperiment.Rmd"
