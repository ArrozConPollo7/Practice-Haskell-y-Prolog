# Sistema de Registro Universitario

> **Práctica I** — Asignatura ST0244 Lenguajes de Programación · Universidad EAFIT

Sistema para gestionar el **ingreso y salida de estudiantes del campus**, implementado en dos paradigmas distintos: **funcional (Haskell)** y **lógico (Prolog)**.

---

## Especificaciones

| Campo | Detalle |
|---|---|
| **Materia** | ST0244 — Lenguajes de Programación |
| **Docente** | Alexander Narváez Berrío |
| **Valor** | 15% de la nota final |
| **Paradigmas** | Funcional (Haskell) · Lógico (Prolog) |

---

## Haskell — Versión A

### Funcionalidades

| # | Función | Descripción |
|---|---|---|
| 1 | **Check In** | Registra la entrada del estudiante con su ID y hora en formato `HH:MM` |
| 2 | **Search by Student ID** | Muestra ficha detallada del estudiante si está actualmente en campus |
| 3 | **Time Calculation** | Calcula y muestra el tiempo de permanencia de un estudiante ya egresado |
| 4 | **List Students** | Lista todos los registros en memoria con tabla de ID, entrada, salida y estado |
| 5 | **Check Out** | Registra la salida, calcula la duración y actualiza el archivo |

### Análisis Técnico

**1. Modelo de Datos e Inmutabilidad**

Los estudiantes se representan con una estructura `Estudiante` definida con `data`. Para "actualizar" un registro (como en el Check Out), el programa usa `map` para recorrer la lista y generar una **nueva lista** con el dato modificado, sin alterar los datos originales — principio central del paradigma funcional.

**2. Gestión de Tiempo con Validación**

La hora se ingresa en formato `HH:MM` y se convierte a minutos totales desde `00:00` mediante `parsearHora`. La función `pedirHora` valida la entrada y repite la solicitud si el formato es incorrecto.

```
08:30  →  510 minutos
Permanencia = TiempoSalida - TiempoEntrada
```

**3. Persistencia y Lazy Evaluation**

El archivo `University.txt` se carga **una sola vez** al iniciar `main`, y la lista resultante se pasa como argumento al menú en cada iteración. Esto evita lecturas repetidas y los conflictos de acceso propios de la evaluación perezosa de Haskell. Las escrituras se realizan con `writeFile` tras cada operación de Check In o Check Out.

**4. Menú con Recursividad Paramétrica**

El menú recibe la lista actual como argumento (`menu :: [Estudiante] -> IO ()`) y se llama recursivamente con la lista actualizada tras cada operación. Esto reemplaza el estado mutable: el "estado" del programa vive en el argumento de la función.

**5. Salida Formateada**

Los registros se muestran en tabla con columnas alineadas. La función auxiliar `minutosAHora` reconvierte los minutos almacenados al formato `HH:MM` para la visualización.

```
  ID       | Entrada | Salida  | Estado
  ---------+---------+---------+----------
  12345678 | 08:30   | 17:00   | SALIO
  87654321 | 09:15   |   --    | EN CAMPUS
```

### Instrucciones de Ejecución

**Requisitos:** [GHC — Glasgow Haskell Compiler](https://www.haskell.org/ghc/)

1. Coloque `Main.hs` y `University.txt` en la misma carpeta.
2. Abra una terminal en esa carpeta y ejecute:

```bash
runhaskell Main.hs
```

### Formato de Almacenamiento

```haskell
Estudiante {idEst = "12345678", entrada = 510, salida = -1}
```

> Un valor de `-1` en `salida` indica que el estudiante aún permanece en la universidad.

---

## Prolog — Versión B

### Funcionalidades

| # | Predicado | Descripción |
|---|---|---|
| 1 | `registrar_entrada/0` | Check In: solicita ID y hora de entrada, persiste con `assertz` |
| 2 | `buscar_estudiante/0` | Busca por ID si el estudiante está actualmente dentro (`salida = 0`) |
| 3 | `calcular_tiempo/3` | Calcula la permanencia como `Salida - Entrada` en minutos |
| 4 | `listar_estudiantes/0` | Lista todos los registros en memoria con ID, entrada y salida |
| 5 | `registrar_salida/0` | Check Out: retracta el hecho anterior y aserta uno nuevo con hora de salida |

### Análisis Técnico

**1. Base de Conocimiento Dinámica**

Los estudiantes se representan como hechos dinámicos:

```prolog
:- dynamic estudiante/3. % estudiante(Id, Entrada, Salida)
```

Un valor de `0` en `Salida` indica que el estudiante sigue dentro. Prolog permite agregar y retirar hechos en tiempo de ejecución con `assertz/1` y `retract/1`.

**2. Persistencia**

El sistema carga datos desde `University.txt` al iniciar usando `cargar_datos/0`, que lee los términos con `read/2` y los incorpora a la base de conocimiento. Al registrar entradas o salidas, `guardar_datos/0` reescribe el archivo con `format/3`.

```prolog
estudiante(123, 480, 0).
estudiante(456, 510, 620).
```

**3. Menú con `repeat/0`**

A diferencia de Haskell, el menú usa el predicado `repeat/0` combinado con un corte (`!`) al seleccionar la opción de salida, simulando un ciclo imperativo dentro del paradigma lógico.

**4. Gestión de Tiempo**

Los tiempos se almacenan en minutos desde `00:00` y la permanencia se calcula con una resta simple.

```prolog
calcular_tiempo(E, S, T) :- T is S - E.
```

### Instrucciones de Ejecución

**Requisitos:** [SWI-Prolog](https://www.swi-prolog.org/)

1. Coloque `registro.pl` y `University.txt` en la misma carpeta.
2. Abra una terminal en esa carpeta y ejecute:

```bash
swipl registro.pl
```

El sistema arranca automáticamente gracias a la directiva:

```prolog
:- initialization(menu).
```

### Formato de Almacenamiento

```prolog
estudiante(123, 480, 0).
estudiante(456, 510, 620).
```

> Un valor de `0` en el tercer argumento indica que el estudiante aún permanece en la universidad.

---
