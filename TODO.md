# TODO

## Storage

- Agregar `storage.R` cuando haya necesidad de múltiples backends.
- Evaluar soporte futuro para Google Drive.

## Formatos

- Agregar exportación Parquet con `arrow` si los datasets crecen.

## Validación

- Agregar JSON Schema para validar outputs LLM de manera formal.
- Soportar schemas distintos para single-label y multi-label.

## Métricas

- Agregar métricas multi-label.
- Agregar precision, recall y F1 cuando corresponda.
- Agregar Cohen's kappa para variables nominales.
- Evaluar Krippendorff's alpha cuando haya múltiples anotadores o datos faltantes.

## Pipeline

- Agregar múltiples runs declarados en YAML.
- Agregar comparación sistemática de modelos, prompts y codebooks.
- Mejorar granularidad de targets para recalcular sólo dimensiones modificadas.

## Reproducibilidad

- Evaluar cuándo activar `renv`.
- Si se usa `renv`, documentar claramente que la librería local no debe versionarse y puede ocupar bastante espacio.

## Ejecución

- Agregar concurrencia controlada.
- Agregar retries y rate limits para OpenRouter.

## Outputs

- Agregar gráficos simples si aportan al análisis.
- Agregar reportes o tablas formateadas sólo si hacen falta.

## Providers

- Mantener abstracción para sumar otros proveedores además de OpenRouter.
