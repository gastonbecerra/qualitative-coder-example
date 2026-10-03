# QualitativeCoder

Infraestructura reproducible en R para codificación cualitativa de documentos con codificadores LLM especializados.

Esta primera versión es mínima: usa `targets`, un proyecto de ejemplo, outputs locales en CSV, un provider `mock` para pruebas sin API key y una abstracción simple para OpenRouter.

## Arquitectura

La jerarquía conceptual es:

```text
plataforma -> proyecto -> corpus -> corrida -> codificación
```

El código reutilizable vive en `R/`. Las decisiones de investigación viven en `projects/<project_id>/`.

## Estructura

```text
R/                         Motor general en R
resources/prompts/          Prompt base compartido
projects/example_project/   Proyecto dummy AulaBot
_targets.R                  Pipeline reproducible
TODO.md                     Pendientes técnicos
```

## Configurar OpenRouter

El ejemplo usa `provider: mock`, así que no requiere credenciales.

Para usar OpenRouter, creá un archivo `.env` a partir de `.env.example`:

```text
OPENROUTER_API_KEY=tu_api_key
```

El ejemplo principal usa `provider: mock`. Para probar OpenRouter sin modificar ese archivo, usá:

```r
source("scripts/run_openrouter_example.R")
```

Ese script usa `projects/example_project/project_openrouter.yml`, con:

```yaml
run:
  id: openrouter_few_shot_v1
  provider: openrouter
  model: openai/gpt-4o-mini
```

Los resultados quedan en una carpeta separada para no pisar el run mock:

```text
projects/example_project/outputs/runs/openrouter_few_shot_v1/
```

También podés elegir cualquier config manualmente:

```r
Sys.setenv(QC_PROJECT_CONFIG = "projects/example_project/project_openrouter.yml")
targets::tar_make()
```

## Dependencias

Para esta versión inicial, instalá las dependencias en tu librería normal de R:

```r
install.packages(c("targets", "tidyverse", "httr2", "jsonlite", "yaml", "dotenv", "digest"))
```

`renv` queda como pendiente opcional para una segunda etapa. No está activado por defecto para evitar crear una librería local pesada dentro del proyecto.

## Crear Un Proyecto Nuevo

Copiá `projects/example_project/` y ajustá:

- `project.yml`
- `corpora/sample_documents.csv`
- `codebooks/*.yml`
- `human_coding/gold_standard.csv`, si existe

## Definir Un Codebook

Cada codebook es un YAML con una dimensión de codificación:

```yaml
id: attitude
version: "0.1.0"
type: single_label
question: "¿Cuál es la actitud general del texto?"
labels:
  - id: positive
    description: "Evaluación favorable."
examples:
  - text: "La herramienta ayuda."
    code: positive
    evidence: "ayuda"
```

Por ahora se soporta `single_label`.

## Zero-Shot Y Few-Shot

La estrategia se define en `project.yml`:

```yaml
prompt_strategy: few_shot
```

Con `zero_shot`, el prompt usa sólo el codebook.

Con `few_shot`, también agrega los `examples` del codebook.

## Ejecutar

Desde R:

```r
targets::tar_make()
```

Si querés ocultar los warnings benignos de paquetes compilados con otra versión menor de R:

```r
source("scripts/run_pipeline.R")
```

Si ves `skipped`, significa que `targets` detectó que esos pasos ya estaban actualizados. Para forzar una ejecución desde cero:

```r
targets::tar_destroy()
source("scripts/run_pipeline.R")
```

Sólo codificaciones:

```r
targets::tar_make(c(codings, saved_codings))
```

Sólo métricas:

```r
targets::tar_make(c(metrics, saved_metrics))
```

## Outputs

Los resultados quedan en:

```text
projects/example_project/outputs/runs/<run_id>/
├── manifest.yml
├── codings.csv
├── metrics.csv
├── report.md
└── raw/
```

Si no existe gold standard y `required: false`, no se calculan métricas, pero las codificaciones sí se generan.

## Validar Contra Human Coding

El archivo esperado es:

```text
projects/example_project/human_coding/gold_standard.csv
```

Formato:

```csv
document_id,dimension,gold_code
doc_001,attitude,positive
```

La métrica inicial es `accuracy` por dimensión.

## Reporte Del Run

Al final del pipeline se genera un reporte Markdown:

```text
projects/example_project/outputs/runs/mock_few_shot_v1/report.md
```

Incluye resumen del run, codificaciones, errores y métricas.
