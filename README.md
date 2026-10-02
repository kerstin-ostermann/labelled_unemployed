# Replication package

**Ostermann, Kerstin and Sebastian Lang (2026): Labelled unemployed: Neighbourhood composition and the enforcement of employment norms.** *Work, Employment and Society*, 1–25. DOI: [10.1177/09501700261472822](https://doi.org/10.1177/09501700261472822)

Contact: Kerstin Ostermann, Bielefeld University / Institute for Employment Research (IAB), kerstin.ostermann@uni-bielefeld.de

---

## 1. Overview

This package contains the Stata code, log files and output needed to reproduce the results in the article. The article links wave 7 (2013) of the German Panel Study Labour Market and Social Security (PASS) to 1×1 km grid cell data from the IAB (GridAB, reference date 30 June 2012) and to official county unemployment rates. It then estimates three-level linear random-intercept/random-slope models (individuals in grid cells in counties) of stigma consciousness among unemployed respondents (N = 1,841), on 50 multiply imputed data sets.

The code runs all steps in order: data preparation, merging, the missing-data selectivity check, multiple imputation, main models, robustness checks and sample description. You can run it all from one master file.

**Not included:** the PASS microdata, the linked grid cell identifiers and the GridAB data, because data protection law does not allow us to share them (see Section 3). The only data file we provide is the public county-level file.

---

## 2. Folder structure

```
replication/
├── README.md                this file
├── data/                    public county-level data only (see 3.3); restricted data go here too once you have access
├── prog/                    Stata do-files (00–13)
├── log/                     log files from the original run
└── out/                     tables (.tex) and figures (.pdf/.png/.gph)
    ├── gini/                socio-economic coexistence models (H3)
    ├── nested/              alternative nesting levels (robustness)
    └── robustness/          further robustness checks
```

The code also writes intermediate data sets to the data folder (`${data}`). It expects original input files in `${orig}` and `${orig_bef}` (see Section 5).

---

## 3. Data sources and access

### 3.1 PASS survey data (restricted, can be requested)

- **Data set:** Panel Study Labour Market and Social Security (PASS), Scientific Use File, version `PASS_0622_v1` (waves 1–16). The analysis uses **wave 7 (2013)** only.
- **Files used:** `PENDDAT.dta` (person level), `HHENDDAT.dta` (household level), `KINDER.dta` (children), `bio_spells.dta` (biographical spells).
- **Access:** Research Data Centre (FDZ) of the German Federal Employment Agency (BA) at the IAB, https://fdz.iab.de. The Scientific Use File is available to researchers under a data use agreement.
- **Reference:** Trappmann M, Bähr S, Beste J, et al. (2019) Data resource profile: Panel study labour market and social security (PASS). *International Journal of Epidemiology* 48(5): 1411–1411g.

### 3.2 Grid cell identifiers and GridAB (restricted, on-site only)

- **`pass_gridab_w7.dta`**: links PASS respondents (`pnr`) to their 1×1 km grid cell (`geo_grid_cell`), based on the survey address. Only respondents who consented to the linkage are included. Mark Trappmann and Sebastian Bähr (sebastian.baehr@iab.de) provided the link.
- **`GridAB_home_cens.dta`**: GridAB, residence-based grid cell aggregates of IAB register data (employment, unemployment, benefit receipt, wages, income inequality, etc.), 2012. Cells with fewer than ten inhabitants are censored.
- **`GridAB_work_all_cens5.dta`**: workplace-based GridAB. Used for the number of establishment closures in the last five years (`n_est_close_5yrs`).
- **`GridAB_widernh.dta`**: aggregates for the wider neighbourhood (surrounding 3×3 km grid cells). Used for imputation and robustness checks.
- **Access:** These are social data under the confidentiality rules of the German Social Code (SGB I, §35; SGB X). They are not publicly available. They are held by the IAB and can be accessed **on site on reasonable request** (iab@iab.de, +49 911 1790). For background on the grid data, see Ostermann K, Eppelsheimer J, Gläser N, Haller P and Oertel M (2022) Geodata in labor market research: Trends, potentials and perspectives. *Journal for Labour Market Research* 56(5).

### 3.3 County-level data (public, included)

- **File:** `lab_areas2009-2015.dta` and LK_ALQ_2013.dta in `data/`
- **Contents:** county IDs (`kreisnr`, Kreiskennziffer), labour market area IDs (`lab_area`/`amr`) and annual county unemployment rates (`alq`, %) for 2013.
- **Sources:**
  - County unemployment rates: Statistics Department of the Federal Employment Agency (Statistik der Bundesagentur für Arbeit), annual averages, unemployment rate relative to the civilian labour force. 
  - Labour market areas (Arbeitsmarktregionen, 2014 delineation).
- **Used in:** `02_nh.do` (county, labour market area and state unemployment) and `08_merge.do` (labour market area IDs; county unemployment and the `highalq` median split at 8.6%).


### 3.4 Other auxiliary files

- **`Kreiskennziffer_Raumordnungsregion.dta`**: county-to-region-type crosswalk from the Federal Institute for Research on Building, Urban Affairs and Spatial Development (BBSR), *Raumtypen 2010, Lage*. `rtyp3 == 1` defines "urban" (central/very central). Source: https://www.bbsr.bund.de/BBSR/DE/forschung/raumbeobachtung/Raumabgrenzungen/deutschland/gemeinden/Raumtypen2010_vbg/Raumtypen2010_LageSied.html [include in `data/` if redistribution is permitted]

---

## 4. Software requirements

- **Stata** [version used: Stata 17 MP]. The code needs `mi impute chained`, `mi estimate` and `mixed`.
- **User-written packages** (install from SSC):

```stata
ssc install mimrgns      // margins after mi estimate
ssc install estout       // esttab, estpost
ssc install coefplot     // selectivity plot
ssc install grc1leg2     // combined graphs with a shared legend
ssc install blindschemes // graph scheme plotplainblind
```

- **Random seed:** `set seed 564` (in `10_imputation.do`).

---

## 5. Setup

1. Put the restricted input files in the input folders (Section 3).
2. Open `prog/00_master.do` and set the path globals:

| Global       | Contents                                                                |
|--------------|-------------------------------------------------------------------------|
| `path`       | project root (the `replication` folder)                                 |
| `orig_bef`   | PASS Scientific Use File (`PENDDAT`, `HHENDDAT`, `KINDER`, `bio_spells`) |
| `orig`       | GridAB files and crosswalks                                             |
| `widenh`     | folder containing `GridAB_widernh.dta`                                  |
| `data`       | intermediate and analysis data sets; also `pass_gridab_w7.dta` and the county files |
| `prog`, `log`, `out` | code, logs, output (default: subfolders of `path`)             |

3. Create the output subfolders if they are missing: `out/gini`, `out/nested`, `out/robustness`, `out/std`.
4. Run `00_master.do`.

---

## 6. Mapping of results to output files

| Result in article | File in `out/` | Produced by |
|---|---|---|
| Table 1 – Sample descriptives | `Description_individuals.tex` | `13_sampledescription.do` |
| Table 2 – Multilevel results | `NH_short.tex` | `11_main.do` |
| Figure 1 – Neighbourhood unemployment in Berlin | [not produced by this code; GIS map from GridAB, please add script/source] | – |
| Figure 2 – Predicted stigma consciousness | `PREDmarginsplot_ALLq2.pdf` / `.png` | `11_main.do` |
| Figure 3 – Marginal effects (H1) | `marginsplot_ALLq2.pdf` | `11_main.do` |
| Figure 4 – Nesting: county unemployment (H2) | `marginsplot_krsalq.pdf` | `11_main.do` |
| Figure 5 – Coexistence: neighbourhood inequality (H3) | `gini/marginsplot_gini.pdf` | `11_main.do` |
| Online Appendix Figure A.1 – Missing-value selectivity | `Missing_selectivity.pdf` | `09_check_selectivity.do` |
| Online Appendix Figure A.2 – Experienced prejudice (item 6) | `robustness/dstigma6_ALLq2.pdf`, `robustness/stigma6_marginsplot_gini.pdf` | `12_robustness.do` |
| Online Appendix Figure A.3 – Other nesting levels (3×3 km, LLM, states) | `marginsplot_wnhalq.pdf`, `marginsplot_amralq.pdf`, `marginsplot_bulaalq.pdf` | `12_robustness.do` |
| Online Appendix Figure A.4 – Gini median split | `robustness/marginsplot_gini50.pdf` | `12_robustness.do` |
| Online Appendix Figure A.5 – Size, urban, East/West, movers | `R_marginsplot_subgroups_unemp.pdf` | `12_robustness.do` |
| Online Appendix Table A.3 – Standardised coefficients | `std/table_sd_quo.tex` | `11_main.do` |
| Neighbourhood descriptives vs. all grid cells | `Description_nh.tex` | `13_sampledescription.do` |


---

## 8. Notes on the variables

- **Stigma consciousness** (`stig_con`): unweighted sum of items 1–8 of the PASS stigma consciousness battery (Gurr and Jungbauer-Gans 2013). Items are recoded so that higher values mean more stigma consciousness, and the score is normalised to 0–100. Item 9 is excluded because it does not fit the scale.
- **Neighbourhood unemployment** (`unemp_quo`): persons without any employment entry divided by all residents (employed, unemployed and ALMP participants) in the grid cell, 2012 (lagged by one year).
- **Welfare receipt** (`sgb2_quo`): unemployed and employed UB II recipients divided by residents. **Long-term unemployment** (`ltunemp_quo`): persons not employed for ≥ 1 year divided by residents.
- **High-unemployment county** (`highalq`): county unemployment rate above the sample median (8.6%).
- **High-inequality neighbourhood** (`high_gini`): top tercile of the grid cell Gini coefficient (`daily_inc_gini`). Low-inequality neighbourhoods are the bottom tercile.
- **Reported confidence intervals:** `mimrgns` computes 95% CIs with approximate degrees of freedom (see footnote 14 of the article).

---

## 9. Citation

If you use this code, please cite:

> Ostermann K and Lang S (2026) Labelled unemployed: Neighbourhood composition and the enforcement of employment norms. *Work, Employment and Society*. https://doi.org/10.1177/09501700261472822

The authors are happy to help with replications (kerstin.ostermann@uni-bielefeld.de).

## 10. License

[![CC BY-NC 4.0](CC-BY.svg)](LICENSE)

This work is licensed under [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/). The data are subject to the access conditions of the FDZ/IAB described above.
