# AGENTS.md

Contexto operativo para trabajar con OpenCode en este proyecto.

## Proyecto

Este repositorio contiene `QualitativeCoder`, un scaffolding mínimo en R para codificación cualitativa de documentos con codificadores LLM especializados.

Objetivo actual: mantener una implementación simple, reproducible y extensible, sin sobrearquitectura.

## Stack Actual

- R
- targets
- tidyverse
- httr2
- jsonlite
- yaml
- dotenv
- digest
- Git/GitHub

No usar por ahora:

- renv activo por defecto
- bases de datos
- dashboards
- APIs
- Parquet/arrow
- gt
- concurrencia future/furrr
- Google Drive

Esos temas están registrados como pendientes en `TODO.md`.

## Estructura Relevante

```text
R/                         Motor general reusable
resources/prompts/          Prompt base
projects/example_project/   Proyecto dummy AulaBot
scripts/                    Wrappers de ejecución
_targets.R                  Pipeline targets
README.md                   Documentación para usuarios
TODO.md                     Backlog técnico
```

## Proyecto Dummy

El proyecto de ejemplo se llama `Opiniones sobre AulaBot`.

Tiene dos dimensiones single-label:

- `attitude`
- `risk_mentioned`

El corpus está en:

```text
projects/example_project/corpora/sample_documents.csv
```

El gold standard opcional está en:

```text
projects/example_project/human_coding/gold_standard.csv
```

## Configuraciones

Config mock por defecto:

```text
projects/example_project/project.yml
```

Config OpenRouter:

```text
projects/example_project/project_openrouter.yml
```

`_targets.R` elige config con `QC_PROJECT_CONFIG`. Si no está seteada, usa el mock:

```r
Sys.getenv("QC_PROJECT_CONFIG", "projects/example_project/project.yml")
```

## Ejecución

Mock local, sin API key:

```r
source("scripts/run_pipeline.R")
```

OpenRouter:

```r
source("scripts/run_openrouter_example.R")
```

Para forzar recálculo completo:

```r
targets::tar_destroy()
source("scripts/run_pipeline.R")
```

## OpenRouter

La API key debe estar en `.env` o en el entorno:

```text
OPENROUTER_API_KEY=...
```

Nunca versionar `.env`.

Provider correcto para modelos consumidos vía OpenRouter:

```yaml
provider: openrouter
model: google/gemini-2.5-flash
```

No usar `provider: google` salvo que se implemente explícitamente un provider Google en `R/llm.R`.

## Outputs

Los outputs generados quedan en:

```text
projects/example_project/outputs/runs/<run_id>/
```

Cada run genera:

```text
manifest.yml
codings.csv
metrics.csv
report.md
raw/*.json
```

Estos outputs están ignorados por Git. Sólo se versiona:

```text
projects/example_project/outputs/runs/.gitkeep
```

## Reporte

El reporte final se genera siempre al correr el pipeline porque el target `report` tiene:

```r
cue = tar_cue(mode = "always")
```

Archivo mock esperado:

```text
projects/example_project/outputs/runs/mock_few_shot_v1/report.md
```

Archivo OpenRouter esperado:

```text
projects/example_project/outputs/runs/openrouter_gemini_flash_v1/report.md
```

## Reinstalar En Otra Máquina

Clonar:

```bash
git clone https://github.com/gastonbecerra/qualitative-coder-example.git
cd qualitative-coder-example
```

Instalar paquetes en R:

```r
install.packages(c("targets", "tidyverse", "httr2", "jsonlite", "yaml", "dotenv", "digest"))
```

Correr mock:

```r
source("scripts/run_pipeline.R")
```

Para OpenRouter, crear `.env` local:

```text
OPENROUTER_API_KEY=...
```

y correr:

```r
source("scripts/run_openrouter_example.R")
```

## Git

Repositorio remoto:

```text
https://github.com/gastonbecerra/qualitative-coder-example
```

Rama principal:

```text
main
```

No versionar:

- `.env`
- `_targets/`
- `_targets.RDS`
- `projects/*/outputs/runs/*`, salvo `.gitkeep`
- `renv/library/`
- `renv/staging/`

## Criterios De Edición

- Mantener cambios chicos y simples.
- No agregar frameworks ni dependencias nuevas sin necesidad clara.
- Si se agregan features, actualizar `README.md` y `TODO.md` cuando corresponda.
- Preservar `project.yml` como mock seguro por defecto.
- Usar `project_openrouter.yml` para llamadas reales a modelos.
- No mover credenciales ni outputs a Git.

## Estado Actual

El pipeline mock ya fue probado localmente.

El backup inicial fue subido a GitHub con commit:

```text
b0cf400 Initial QualitativeCoder scaffold
```
